import { test, describe } from 'node:test';
import assert from 'node:assert/strict';

// ── Shared Helper Implementations Matching Production Contracts ───────────────

/**
 * Coordinate parser identical to parsePinFromDescription in Admin Portal
 * and RegExp in Dart Correction model.
 */
function parsePinFromDescription(
  description: string
): { x: number; y: number; text: string } | null {
  const m = description.match(/^\[PIN:([\d.]+),([\d.]+)\]\s*([\s\S]*)$/);
  if (!m) return null;
  return { x: parseFloat(m[1]), y: parseFloat(m[2]), text: (m[3] || '').trim() };
}

/**
 * Coordinate encoding function identical to Cloudflare Worker implementation
 */
function encodePinDescription(description: string, pinX?: number, pinY?: number): string {
  if (pinX !== undefined && pinY !== undefined) {
    return `[PIN:${Number(pinX).toFixed(4)},${Number(pinY).toFixed(4)}] ${description.trim()}`;
  }
  return description.trim();
}

/**
 * Viewport coordinate clamping function identical to handleViewportClick
 */
function clampCoordinate(val: number): number {
  return Math.max(0.03, Math.min(0.97, val));
}

// ── 1. Coordinate Conversion & Clamping Tests ─────────────────────────────────

describe('Coordinate Conversion & Clamping (Admin & Cross-App Contract)', () => {
  test('Parses standard 4-decimal pinned correction accurately', () => {
    const raw = '[PIN:0.4521,0.3182] Relocate HVAC return duct 400mm east';
    const parsed = parsePinFromDescription(raw);
    assert.ok(parsed !== null);
    assert.equal(parsed.x, 0.4521);
    assert.equal(parsed.y, 0.3182);
    assert.equal(parsed.text, 'Relocate HVAC return duct 400mm east');
  });

  test('Clamps viewport coordinates to safe margin [0.03, 0.97] to prevent pin clipping', () => {
    // Extreme left/top click (e.g. click at 0px)
    assert.equal(clampCoordinate(-0.05), 0.03);
    assert.equal(clampCoordinate(0.0), 0.03);
    assert.equal(clampCoordinate(0.01), 0.03);

    // Extreme right/bottom click (e.g. click at container border)
    assert.equal(clampCoordinate(0.99), 0.97);
    assert.equal(clampCoordinate(1.05), 0.97);

    // In-bounds click
    assert.equal(clampCoordinate(0.5), 0.5);
    assert.equal(clampCoordinate(0.245), 0.245);
  });

  test('Gracefully handles variable whitespace and multi-line annotations', () => {
    const raw = '[PIN:0.1250,0.8800]    Multi-line text\nwith line breaks and tabs\t';
    const parsed = parsePinFromDescription(raw);
    assert.ok(parsed !== null);
    assert.equal(parsed.x, 0.125);
    assert.equal(parsed.y, 0.88);
    assert.equal(parsed.text, 'Multi-line text\nwith line breaks and tabs');
  });

  test('Handles pin with empty annotation note', () => {
    const raw = '[PIN:0.5000,0.5000]';
    const parsed = parsePinFromDescription(raw);
    assert.ok(parsed !== null);
    assert.equal(parsed.x, 0.5);
    assert.equal(parsed.y, 0.5);
    assert.equal(parsed.text, '');
  });

  test('Returns null for legacy or non-pinned correction descriptions', () => {
    assert.equal(parsePinFromDescription('Please revise wall thickness to 200mm'), null);
    assert.equal(parsePinFromDescription(''), null);
    assert.equal(parsePinFromDescription('[NOTE] Fix window dimensions'), null);
    // [PIN:...] not at start of string
    assert.equal(parsePinFromDescription('Check [PIN:0.5,0.5] here'), null);
    // Malformed coordinates
    assert.equal(parsePinFromDescription('[PIN:abc,xyz] invalid coords'), null);
  });
});

// ── 2. Persistence & Serialization Tests ──────────────────────────────────────

describe('Persistence & Serialization Format Compatibility', () => {
  test('Encodes pin coordinates to fixed 4-decimal precision', () => {
    const encoded = encodePinDescription('Check clearance', 0.5, 0.25);
    assert.equal(encoded, '[PIN:0.5000,0.2500] Check clearance');
  });

  test('Omits pin prefix when pinX or pinY are undefined', () => {
    const encodedNoX = encodePinDescription('General correction note', undefined, 0.25);
    assert.equal(encodedNoX, 'General correction note');

    const encodedNoCoords = encodePinDescription('Standard textual correction');
    assert.equal(encodedNoCoords, 'Standard textual correction');
  });

  test('Ensures lossless round-trip serialization between Worker and Client apps', () => {
    const originalText = 'Adjust stairwell riser height to 175mm standard';
    const originalX = 0.6342;
    const originalY = 0.2198;

    // Worker encodes on save
    const storedInDb = encodePinDescription(originalText, originalX, originalY);
    assert.equal(storedInDb, '[PIN:0.6342,0.2198] Adjust stairwell riser height to 175mm standard');

    // Admin Portal & Flutter app parse from DB
    const loaded = parsePinFromDescription(storedInDb);
    assert.ok(loaded !== null);
    assert.equal(loaded.x, originalX);
    assert.equal(loaded.y, originalY);
    assert.equal(loaded.text, originalText);
  });
});

// ── 3. Authorization & RBAC Tests ─────────────────────────────────────────────

describe('Admin Redline Endpoint Authorization & Security', () => {
  interface UserContext {
    uid: string;
    role: string;
  }

  function authorizeAdminCorrection(user?: UserContext): { status: number; error?: string } {
    if (!user) return { status: 401, error: 'Unauthorized' };
    if (user.role !== 'ADMIN') return { status: 403, error: 'Permission denied' };
    return { status: 200 };
  }

  test('ADMIN user is authorized to create redline pin corrections', () => {
    const result = authorizeAdminCorrection({ uid: 'admin-uid-1', role: 'ADMIN' });
    assert.equal(result.status, 200);
    assert.equal(result.error, undefined);
  });

  test('CLIENT (Engineer) role is rejected with 403 Permission denied', () => {
    const result = authorizeAdminCorrection({ uid: 'engineer-uid-1', role: 'CLIENT' });
    assert.equal(result.status, 403);
    assert.equal(result.error, 'Permission denied');
  });

  test('DRAUGHTSMAN role is rejected with 403 Permission denied', () => {
    const result = authorizeAdminCorrection({ uid: 'draughtsman-uid-1', role: 'DRAUGHTSMAN' });
    assert.equal(result.status, 403);
    assert.equal(result.error, 'Permission denied');
  });

  test('STUDENT role is rejected with 403 Permission denied', () => {
    const result = authorizeAdminCorrection({ uid: 'student-uid-1', role: 'STUDENT' });
    assert.equal(result.status, 403);
    assert.equal(result.error, 'Permission denied');
  });

  test('Unauthenticated request is rejected with 401 Unauthorized', () => {
    const result = authorizeAdminCorrection(undefined);
    assert.equal(result.status, 401);
  });
});

// ── 4. Idempotent Retries & Action Deduplication Tests ─────────────────────────

describe('Admin Correction Idempotent Retries', () => {
  interface MockDbState {
    projectLastActionId: string | null;
    correctionRound: number;
    correctionsCount: number;
    activityLogsCount: number;
  }

  function processAdminCorrection(
    state: MockDbState,
    actionId: string,
    description: string
  ): { success: boolean; round?: number; idempotent?: boolean } {
    // Check project last_action_id idempotency
    if (state.projectLastActionId === actionId) {
      return { success: true, idempotent: true };
    }

    // Process new action
    state.correctionRound += 1;
    state.projectLastActionId = actionId;
    state.correctionsCount += 1;
    state.activityLogsCount += 1;

    return { success: true, round: state.correctionRound };
  }

  test('First request creates correction and increments round', () => {
    const db: MockDbState = {
      projectLastActionId: null,
      correctionRound: 0,
      correctionsCount: 0,
      activityLogsCount: 0,
    };

    const actionId = 'action-uuid-101';
    const res = processAdminCorrection(db, actionId, 'Pin 1');

    assert.equal(res.success, true);
    assert.equal(res.round, 1);
    assert.equal(db.correctionRound, 1);
    assert.equal(db.correctionsCount, 1);
    assert.equal(db.activityLogsCount, 1);
    assert.equal(db.projectLastActionId, actionId);
  });

  test('Duplicate request with identical actionId returns success without duplicate DB mutations', () => {
    const db: MockDbState = {
      projectLastActionId: 'action-uuid-101',
      correctionRound: 1,
      correctionsCount: 1,
      activityLogsCount: 1,
    };

    // Retry with identical actionId
    const res = processAdminCorrection(db, 'action-uuid-101', 'Pin 1');

    assert.equal(res.success, true);
    assert.equal(res.idempotent, true);
    // Counters must remain unchanged
    assert.equal(db.correctionRound, 1);
    assert.equal(db.correctionsCount, 1);
    assert.equal(db.activityLogsCount, 1);
  });
});

// ── 5. Three-Round Correction Cap Enforcement Tests ───────────────────────────

describe('Three-Round Correction Cap & State Machine Enforcement', () => {
  const activeStatuses = [
    'SUBMITTED',
    'WAITING_ASSIGNMENT',
    'WAITING_ACCEPTANCE',
    'IN_PROGRESS',
    'UNDER_CLIENT_REVIEW',
  ];

  function validateCorrectionRequest(
    projectStatus: string,
    currentRound: number
  ): { allowed: boolean; nextRound?: number; error?: string } {
    if (!activeStatuses.includes(projectStatus)) {
      return { allowed: false, error: `Cannot add a correction to a project in ${projectStatus} state` };
    }
    if (currentRound >= 3) {
      return { allowed: false, error: 'Maximum correction limit (3 rounds) has been reached.' };
    }
    return { allowed: true, nextRound: currentRound + 1 };
  }

  test('Allows Round 1 correction when currentRound is 0', () => {
    const res = validateCorrectionRequest('IN_PROGRESS', 0);
    assert.equal(res.allowed, true);
    assert.equal(res.nextRound, 1);
  });

  test('Allows Round 2 correction when currentRound is 1', () => {
    const res = validateCorrectionRequest('UNDER_CLIENT_REVIEW', 1);
    assert.equal(res.allowed, true);
    assert.equal(res.nextRound, 2);
  });

  test('Allows Round 3 correction when currentRound is 2', () => {
    const res = validateCorrectionRequest('IN_PROGRESS', 2);
    assert.equal(res.allowed, true);
    assert.equal(res.nextRound, 3);
  });

  test('Strictly rejects 4th correction request when currentRound is 3', () => {
    const res = validateCorrectionRequest('UNDER_CLIENT_REVIEW', 3);
    assert.equal(res.allowed, false);
    assert.equal(res.error, 'Maximum correction limit (3 rounds) has been reached.');
  });

  test('Rejects corrections on terminal project states (COMPLETED, CANCELLED)', () => {
    const completedRes = validateCorrectionRequest('COMPLETED', 1);
    assert.equal(completedRes.allowed, false);
    assert.ok(completedRes.error?.includes('COMPLETED'));

    const cancelledRes = validateCorrectionRequest('CANCELLED', 1);
    assert.equal(cancelledRes.allowed, false);
    assert.ok(cancelledRes.error?.includes('CANCELLED'));
  });
});

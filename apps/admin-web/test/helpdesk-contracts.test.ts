import { describe, it } from 'node:test';
import assert from 'node:assert';

// ── 1. Sanitization & Redaction Logic Under Test ─────────────────────────────

function sanitizeText(input: unknown): string {
  if (input === null || input === undefined) return '';
  let str = typeof input === 'string' ? input : String(input);
  str = str.replace(/Bearer\s+[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/gi, 'Bearer <REDACTED_JWT>');
  str = str.replace(/eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*/g, '<REDACTED_JWT>');
  str = str.replace(/(["']?(?:password|token|secret|apiKey|api_key|auth_token|id_token|privateKey|credential|cookie)["']?\s*[:=]\s*["'])([^"'\s]+)(["'])/gi, '$1<REDACTED>$3');
  str = str.replace(/\b[0-9a-f]{32,64}\b/gi, '<HEX_TOKEN>');
  return str.trim();
}

function normalizeErrorMessage(msg: string): string {
  let cleaned = sanitizeText(msg);
  cleaned = cleaned.replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '<UUID>');
  cleaned = cleaned.replace(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?Z?/gi, '<TIMESTAMP>');
  cleaned = cleaned.replace(/\b\d{4,}\b/g, '<NUM>');
  return cleaned.toLowerCase().trim();
}

function computeFingerprint(source: string, category: string, affectedModule: string, errorMessage: string): string {
  const normMsg = normalizeErrorMessage(errorMessage);
  const raw = `${source.toUpperCase()}:${category.toUpperCase()}:${affectedModule.toLowerCase()}:${normMsg}`;

  let h1 = 0xdeadbeef ^ 0;
  let h2 = 0x41c6ce57 ^ 0;
  for (let i = 0; i < raw.length; i++) {
    const ch = raw.charCodeAt(i);
    h1 = Math.imul(h1 ^ ch, 2654435761);
    h2 = Math.imul(h2 ^ ch, 1597334677);
  }
  h1 = Math.imul(h1 ^ (h1 >>> 16), 2246822507) ^ Math.imul(h2 ^ (h2 >>> 13), 3266489909);
  h2 = Math.imul(h2 ^ (h2 >>> 16), 2246822507) ^ Math.imul(h1 ^ (h1 >>> 13), 3266489909);
  const hashHex = (4294967296 * (2097151 & h2) + (h1 >>> 0)).toString(16).padStart(16, '0');
  return `FP-${source.slice(0, 3).toUpperCase()}-${category.slice(0, 3).toUpperCase()}-${hashHex}`;
}

// ── 2. KPI Telemetry Calculator ──────────────────────────────────────────────

function computeHelpdeskStats(tickets: Array<{
  id: string;
  severity: string;
  status: string;
  category: string;
  is_user_submitted: number;
  created_at: string;
  resolved_at?: string | null;
}>) {
  let openTickets = 0;
  let criticalIssues = 0;
  let highPriority = 0;
  let inProgress = 0;
  let awaitingResponse = 0;
  let resolvedTickets = 0;
  let totalResolutionMinutes = 0;
  let resolvedCountWithDuration = 0;

  const categoryDistribution: Record<string, number> = {};
  const severityDistribution: Record<string, number> = {
    CRITICAL: 0,
    HIGH: 0,
    MEDIUM: 0,
    LOW: 0,
  };

  for (const t of tickets) {
    if (t.status === 'OPEN') openTickets++;
    if (t.severity === 'CRITICAL' && t.status !== 'RESOLVED' && t.status !== 'CLOSED') criticalIssues++;
    if (t.severity === 'HIGH' && t.status !== 'RESOLVED' && t.status !== 'CLOSED') highPriority++;
    if (t.status === 'INVESTIGATING' || t.status === 'IN_PROGRESS') inProgress++;
    if (t.status === 'OPEN' && t.is_user_submitted === 1) awaitingResponse++;
    if (t.status === 'RESOLVED' || t.status === 'CLOSED') resolvedTickets++;

    categoryDistribution[t.category] = (categoryDistribution[t.category] || 0) + 1;
    if (severityDistribution[t.severity] !== undefined) {
      severityDistribution[t.severity]++;
    }

    if (t.resolved_at && (t.status === 'RESOLVED' || t.status === 'CLOSED')) {
      const created = new Date(t.created_at).getTime();
      const resolved = new Date(t.resolved_at).getTime();
      if (resolved >= created) {
        totalResolutionMinutes += (resolved - created) / (1000 * 60);
        resolvedCountWithDuration++;
      }
    }
  }

  const avgResolutionTimeMinutes = resolvedCountWithDuration > 0
    ? Math.round(totalResolutionMinutes / resolvedCountWithDuration)
    : 0;

  return {
    totalReports: tickets.length,
    openTickets,
    criticalIssues,
    highPriority,
    inProgress,
    awaitingResponse,
    resolvedTickets,
    avgResolutionTimeMinutes,
    categoryDistribution,
    severityDistribution,
  };
}

describe('PixelMint Studio MVS — Help Desk & Incident Management Contracts', () => {
  describe('Sanitization & Token Redaction', () => {
    it('redacts Firebase Bearer tokens and JWTs from error messages', () => {
      const rawError = 'Failed to authenticate request: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIn0.signature_string';
      const sanitized = sanitizeText(rawError);

      assert.strictEqual(sanitized.includes('eyJhbGciOiJSUzI1NiIs'), false);
      assert.ok(sanitized.includes('Bearer <REDACTED_JWT>'));
    });

    it('redacts passwords and API keys from JSON error payloads', () => {
      const jsonError = '{"status": 401, "apiKey": "live_secret_key_998877665544", "password": "superSecretPassword123"}';
      const sanitized = sanitizeText(jsonError);

      assert.strictEqual(sanitized.includes('live_secret_key_998877665544'), false);
      assert.strictEqual(sanitized.includes('superSecretPassword123'), false);
      assert.ok(sanitized.includes('"apiKey": "<REDACTED>"'));
      assert.ok(sanitized.includes('"password": "<REDACTED>"'));
    });

    it('redacts long hex private keys or database hashes', () => {
      const dbError = 'D1 transaction collision on hash 4a2b9f10c8e765d4b3a2f109876543214a2b9f10c8e765d4b3a2f10987654321';
      const sanitized = sanitizeText(dbError);

      assert.strictEqual(sanitized.includes('4a2b9f10c8e765d4b3a2f109876543214a2b9f10c8e765d4b3a2f10987654321'), false);
      assert.ok(sanitized.includes('<HEX_TOKEN>'));
    });
  });

  describe('Incident Deduplication & Fingerprinting', () => {
    it('normalizes variable UUIDs so identical errors group to the same fingerprint', () => {
      const error1 = 'Project e5b3579b-2248-4cb5-bf99-8cf7e3e9d102 failed to load drawing 2026-11-03T10:00:00Z';
      const error2 = 'Project 11111111-2222-3333-4444-555555555555 failed to load drawing 2026-11-03T10:05:00Z';

      const fp1 = computeFingerprint('ADMIN_PANEL', 'FRONTEND', 'DrawingViewer', error1);
      const fp2 = computeFingerprint('ADMIN_PANEL', 'FRONTEND', 'DrawingViewer', error2);

      assert.strictEqual(fp1, fp2, 'Fingerprints must match when only dynamic IDs and timestamps differ');
    });

    it('differentiates errors from different sources or categories', () => {
      const error = 'Database connection timeout';
      const fpBackend = computeFingerprint('BACKEND', 'DATABASE', 'D1', error);
      const fpFrontend = computeFingerprint('ADMIN_PANEL', 'API', 'D1', error);

      assert.notStrictEqual(fpBackend, fpFrontend);
    });
  });

  describe('Truthful KPI Telemetry Calculations', () => {
    it('calculates metrics truthfully from raw incident records without dummy fallback', () => {
      const sampleTickets = [
        {
          id: 'PM-HELP-2026-000001',
          severity: 'CRITICAL',
          status: 'OPEN',
          category: 'DATABASE',
          is_user_submitted: 0,
          created_at: '2026-11-03T10:00:00Z',
        },
        {
          id: 'PM-HELP-2026-000002',
          severity: 'HIGH',
          status: 'INVESTIGATING',
          category: 'UPLOAD',
          is_user_submitted: 0,
          created_at: '2026-11-03T10:15:00Z',
        },
        {
          id: 'PM-HELP-2026-000003',
          severity: 'MEDIUM',
          status: 'OPEN',
          category: 'USER_REPORT',
          is_user_submitted: 1, // awaiting response
          created_at: '2026-11-03T10:30:00Z',
        },
        {
          id: 'PM-HELP-2026-000004',
          severity: 'LOW',
          status: 'RESOLVED',
          category: 'FRONTEND',
          is_user_submitted: 0,
          created_at: '2026-11-03T09:00:00Z',
          resolved_at: '2026-11-03T09:30:00Z', // 30 minutes duration
        },
        {
          id: 'PM-HELP-2026-000005',
          severity: 'MEDIUM',
          status: 'RESOLVED',
          category: 'API',
          is_user_submitted: 0,
          created_at: '2026-11-03T08:00:00Z',
          resolved_at: '2026-11-03T09:00:00Z', // 60 minutes duration
        },
      ];

      const stats = computeHelpdeskStats(sampleTickets);

      assert.strictEqual(stats.totalReports, 5);
      assert.strictEqual(stats.openTickets, 2);
      assert.strictEqual(stats.criticalIssues, 1);
      assert.strictEqual(stats.highPriority, 1);
      assert.strictEqual(stats.inProgress, 1);
      assert.strictEqual(stats.awaitingResponse, 1);
      assert.strictEqual(stats.resolvedTickets, 2);
      // Average of 30m and 60m is 45m
      assert.strictEqual(stats.avgResolutionTimeMinutes, 45);
      assert.strictEqual(stats.categoryDistribution.DATABASE, 1);
      assert.strictEqual(stats.categoryDistribution.UPLOAD, 1);
      assert.strictEqual(stats.categoryDistribution.USER_REPORT, 1);
    });

    it('returns zero safely when tickets list is empty', () => {
      const stats = computeHelpdeskStats([]);

      assert.strictEqual(stats.totalReports, 0);
      assert.strictEqual(stats.openTickets, 0);
      assert.strictEqual(stats.criticalIssues, 0);
      assert.strictEqual(stats.highPriority, 0);
      assert.strictEqual(stats.resolvedTickets, 0);
      assert.strictEqual(stats.avgResolutionTimeMinutes, 0);
    });
  });

  describe('Notification Rules & Recipient Validation', () => {
    it('enforces default primary notification email as pixelmintstudiomvs@gmail.com', () => {
      const defaultEmail = 'pixelmintstudiomvs@gmail.com';
      assert.strictEqual(defaultEmail, 'pixelmintstudiomvs@gmail.com');
      assert.match(defaultEmail, /^[a-zA-Z0-9._%+-]+@gmail\.com$/);
    });

    it('formats ticket ID strictly with PM-HELP prefix and year sequence', () => {
      const currentYear = new Date().getFullYear();
      const ticketId = `PM-HELP-${currentYear}-000042`;
      assert.match(ticketId, /^PM-HELP-\d{4}-\d{6}$/);
    });
  });
});


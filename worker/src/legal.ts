import { Hono } from 'hono';

type Bindings = {
  DB: D1Database;
  STORAGE: R2Bucket;
};

type Variables = {
  uid: string;
};

// Cryptographic hash helper for SHA-256 strings
export async function hashString(value: string): Promise<string> {
  const data = new TextEncoder().encode(value || 'unknown');
  const digest = await crypto.subtle.digest('SHA-256', data);
  const arr = Array.from(new Uint8Array(digest));
  return arr.map(b => b.toString(16).padStart(2, '0')).join('');
}

// User helper
async function getUser(db: D1Database, uid: string) {
  return await db.prepare('SELECT * FROM users WHERE id = ?').bind(uid).first();
}

/**
 * Server-side gate asserting affirmative acceptance of currently effective platform Terms.
 * Fails closed if mandatory terms are missing from the system (503 TERMS_MAINTENANCE_MODE).
 * Fails closed if the caller has not accepted the exact current effective version (403 TERMS_ACCEPTANCE_REQUIRED).
 * Admin and Studio Admin roles are exempt to ensure recovery and policy management operations.
 */
export async function assertTermsAccepted(
  db: D1Database,
  uid: string,
  userRole?: string,
  options?: {
    environment?: string;
    testModeHeader?: string | null;
  }
): Promise<{ ok: boolean; errorResponse?: any }> {
  // Administrative staff are exempt to ensure recovery and management access
  if (userRole === 'ADMIN' || userRole === 'STUDIO_ADMIN') {
    return { ok: true };
  }

  // STAGING-ONLY TEST-ACCEPTANCE SEAM (Phase D.10.3)
  // Strictly impossible to activate in production:
  // Must fail closed if environment is missing, ambiguous, or not explicitly 'staging'
  const isStaging = options?.environment === 'staging';
  const hasTestHeader = options?.testModeHeader === 'workflow-e2e';
  const STAGING_TEST_UIDS = new Set([
    'KXAR90JgoVYLuOKzkbxpKTC8ATa2', // Staging Engineer (zedsuo125+engineer@gmail.com)
    'TJjtkBm3lgRlpKtcI5u3jpYPH9s1', // Staging Draughtsman (zedsuo125+draughtsman@gmail.com)
    '2iypyxUntQX6djOzwjgPo5xWrGD2', // Staging Student (zedsuo125+student@gmail.com)
    'QBhduHDU1mYUxvtQ89adVnwQYCg1', // Staging Studio Admin (zedsuo125@gmail.com)
  ]);

  if (isStaging && hasTestHeader && STAGING_TEST_UIDS.has(uid)) {
    console.log(`[STAGING_TEST_MODE_ACTIVE] Legal gate test-exemption active for staging test UID: ${uid}`);
    return { ok: true };
  }

  // 1. Fetch currently EFFECTIVE mandatory Terms document from trusted database
  await ensureDefaultLegalDocuments(db);
  const termsDoc = await db.prepare(
    "SELECT id, version, is_mandatory FROM legal_documents WHERE document_type = 'TERMS_AND_CONDITIONS' AND status = 'EFFECTIVE' AND is_mandatory = 1"
  ).first();

  if (!termsDoc) {
    return {
      ok: false,
      errorResponse: {
        error: 'Mandatory platform terms are currently unavailable in maintenance mode',
        code: 'TERMS_MAINTENANCE_MODE',
        status: 503
      }
    };
  }


  // 2. Fetch affirmative acceptance for caller matching this exact version
  const consentState = await db.prepare(
    "SELECT current_status, accepted_version FROM user_consent_state WHERE user_id = ? AND consent_type = 'TERMS' AND purpose_tag = 'DEFAULT'"
  ).bind(uid).first();

  if (!consentState || (consentState as any).current_status !== 'ACCEPTED' || (consentState as any).accepted_version !== (termsDoc as any).version) {
    return {
      ok: false,
      errorResponse: {
        error: 'Affirmative acceptance of current platform Terms and Conditions is required to perform this operation',
        code: 'TERMS_ACCEPTANCE_REQUIRED',
        status: 403,
        requiredVersion: (termsDoc as any).version,
        acceptedVersion: (consentState as any)?.accepted_version || null
      }
    };
  }

  return { ok: true };
}

/**
 * Ensures baseline effective legal documents exist in D1 if the table has not yet been seeded.
 */
export async function ensureDefaultLegalDocuments(db: D1Database): Promise<void> {
  const termsCount = await db.prepare(
    "SELECT COUNT(*) as count FROM legal_documents WHERE document_type = 'TERMS_AND_CONDITIONS'"
  ).first<{ count: number }>();
  if (!termsCount || termsCount.count === 0) {
    await db.prepare(`
      INSERT OR IGNORE INTO legal_documents (
        id, document_type, version, title, content, effective_at, status, is_mandatory, locale
      ) VALUES (
        'doc-terms-v1', 'TERMS_AND_CONDITIONS', '1.0.0', 'Platform Terms and Conditions',
        '# Platform Terms and Conditions\n\nBy accessing and using Archi Draft, you agree to these Terms and Conditions.',
        '2026-10-24 00:00:00', 'EFFECTIVE', 1, 'en-IN'
      )
    `).run();
  }

  const privacyCount = await db.prepare(
    "SELECT COUNT(*) as count FROM legal_documents WHERE document_type = 'PRIVACY_POLICY'"
  ).first<{ count: number }>();
  if (!privacyCount || privacyCount.count === 0) {
    await db.prepare(`
      INSERT OR IGNORE INTO legal_documents (
        id, document_type, version, title, content, effective_at, status, is_mandatory, locale
      ) VALUES (
        'doc-priv-v1', 'PRIVACY_POLICY', '1.0.0', 'Privacy Policy',
        '# Privacy Policy\n\nThis Privacy Policy governs the processing of personal data on the Archi Draft platform under the Digital Personal Data Protection Act, 2023.',
        '2026-10-24 00:00:00', 'EFFECTIVE', 0, 'en-IN'
      )
    `).run();
  }
}

export function registerLegalRoutes(app: Hono<{ Bindings: Bindings; Variables: Variables }>) {

  // =========================================================================
  // PUBLIC LEGAL DOCUMENT READS
  // =========================================================================

  // GET /api/legal/documents/current
  // Returns summary metadata of all active EFFECTIVE documents (Drafts/superseded excluded)
  app.get('/api/legal/documents/current', async (c) => {
    const db = c.env.DB;
    await ensureDefaultLegalDocuments(db);
    const { results } = await db.prepare(`
      SELECT id, document_type, version, title, effective_at, published_at, status, is_mandatory, locale, change_summary 
      FROM legal_documents 
      WHERE status = 'EFFECTIVE' 
      ORDER BY document_type ASC
    `).all();

    return c.json({ documents: results || [] });
  });

  // GET /api/legal/documents/:type/current
  // Returns full markdown content and metadata of the active EFFECTIVE document for a given type
  app.get('/api/legal/documents/:type/current', async (c) => {
    const type = c.req.param('type');
    const locale = c.req.query('locale') || 'en-IN';
    const db = c.env.DB;
    await ensureDefaultLegalDocuments(db);

    const doc = await db.prepare(`
      SELECT id, document_type, version, title, content, effective_at, published_at, status, is_mandatory, locale, change_summary 
      FROM legal_documents 
      WHERE document_type = ? AND locale = ? AND status = 'EFFECTIVE'
    `).bind(type, locale).first();

    if (!doc) {
      return c.json({ 
        error: 'No effective document found for type: ' + type, 
        code: 'NO_EFFECTIVE_VERSION' 
      }, 404);
    }

    return c.json({ document: doc });
  });

  // GET /api/legal/documents/:type/history
  // Returns public version history (EFFECTIVE and SUPERSEDED only; DRAFT is strictly excluded)
  app.get('/api/legal/documents/:type/history', async (c) => {
    const type = c.req.param('type');
    const locale = c.req.query('locale') || 'en-IN';
    const db = c.env.DB;

    const { results } = await db.prepare(`
      SELECT id, document_type, version, title, effective_at, published_at, status, is_mandatory, locale, change_summary 
      FROM legal_documents 
      WHERE document_type = ? AND locale = ? AND status IN ('EFFECTIVE', 'SUPERSEDED')
      ORDER BY effective_at DESC
    `).bind(type, locale).all();

    return c.json({ versions: results || [] });
  });

  // =========================================================================
  // AUTHENTICATED USER LEGAL & CONSENT STATUS
  // =========================================================================

  // GET /api/users/me/legal-status
  // Evaluates caller compliance against active mandatory documents and returns granular consent state
  app.get('/api/users/me/legal-status', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user) {
      return c.json({ error: 'User not found' }, 404);
    }

    await ensureDefaultLegalDocuments(db);

    // 1. Fetch currently EFFECTIVE documents
    const { results: effectiveDocs } = await db.prepare(`
      SELECT id, document_type, version, is_mandatory 
      FROM legal_documents 
      WHERE status = 'EFFECTIVE'
    `).all();

    const termsDoc = (effectiveDocs || []).find((d: any) => d.document_type === 'TERMS_AND_CONDITIONS' && d.is_mandatory === 1);
    const privacyDoc = (effectiveDocs || []).find((d: any) => d.document_type === 'PRIVACY_POLICY');

    // 2. Fetch caller's current consent state records
    const { results: consentStates } = await db.prepare(`
      SELECT consent_type, purpose_tag, current_status, accepted_version, updated_at 
      FROM user_consent_state 
      WHERE user_id = ?
    `).bind(uid).all();

    const states = consentStates || [];

    // Evaluate Terms Acceptance
    const termsState = states.find((s: any) => s.consent_type === 'TERMS' && s.purpose_tag === 'DEFAULT');
    const hasEffectiveTerms = !!termsDoc;
    const termsAccepted = !!termsState && termsState.current_status === 'ACCEPTED' && hasEffectiveTerms && (termsState.accepted_version === termsDoc.version);
    const reacceptanceRequired = hasEffectiveTerms && !!termsState && termsState.current_status === 'ACCEPTED' && (termsState.accepted_version !== termsDoc.version);

    // Evaluate Privacy Policy Acknowledgment
    const privState = states.find((s: any) => s.consent_type === 'PRIVACY_NOTICE' && s.purpose_tag === 'DEFAULT');
    const privacyNoticeAcknowledged = !!privState && privState.current_status === 'ACKNOWLEDGED';

    // Granular Optional Consents (Default to false / OFF)
    const optionalConsents: Record<string, boolean> = {};
    for (const s of (states as any[])) {
      if (s.consent_type === 'OPTIONAL_PURPOSE') {
        const tag = s.purpose_tag as string; if (tag) optionalConsents[tag] = s.current_status === 'GRANTED';
      }
    }

    const requiresAction = !hasEffectiveTerms ? false : (!termsAccepted || reacceptanceRequired);

    return c.json({
      userId: uid,
      termsAccepted,
      reacceptanceRequired,
      acceptedTermsVersion: termsState?.accepted_version || null,
      latestTermsVersion: termsDoc?.version || null,
      privacyNoticeAcknowledged,
      acknowledgedPrivacyVersion: privState?.accepted_version || null,
      latestPrivacyVersion: privacyDoc?.version || null,
      optionalConsents,
      requiresAction,
      hasEffectiveTerms,
      missingMandatoryDocs: !hasEffectiveTerms
    });
  });

  // POST /api/legal/accept-terms
  // Idempotently records affirmative acceptance of mandatory Platform Terms
  app.post('/api/legal/accept-terms', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    await ensureDefaultLegalDocuments(db);

    // Validate target document
    let doc: any = null;
    if (body.documentId) {
      doc = await db.prepare(`
        SELECT id, document_type, version, status, is_mandatory 
        FROM legal_documents 
        WHERE id = ?
      `).bind(body.documentId).first();
    }
    if (!doc && body.version) {
      doc = await db.prepare(`
        SELECT id, document_type, version, status, is_mandatory 
        FROM legal_documents 
        WHERE document_type = 'TERMS_AND_CONDITIONS' AND version = ? AND status = 'EFFECTIVE'
      `).bind(body.version).first();
    }
    if (!doc) {
      doc = await db.prepare(`
        SELECT id, document_type, version, status, is_mandatory 
        FROM legal_documents 
        WHERE document_type = 'TERMS_AND_CONDITIONS' AND status = 'EFFECTIVE'
      `).first();
    }

    if (!doc || doc.status !== 'EFFECTIVE' || doc.document_type !== 'TERMS_AND_CONDITIONS') {
      return c.json({ error: 'Target Terms document is not currently effective or does not exist', code: 'INVALID_DOCUMENT' }, 400);
    }

    if (body.version && body.version !== doc.version) {
      return c.json({ error: 'Version mismatch with active effective Terms', code: 'VERSION_MISMATCH' }, 400);
    }

    // Idempotency check
    const idemKey = body.idempotencyKey || await hashString(`terms_${uid}_${doc.id}_${doc.version}`);
    const existingEvent = await db.prepare('SELECT id FROM legal_consent_events WHERE idempotency_key = ?').bind(idemKey).first();
    if (existingEvent) {
      return c.json({ 
        success: true, 
        idempotent: true, 
        eventId: existingEvent.id, 
        acceptedVersion: doc.version,
        message: 'Terms acceptance already recorded' 
      }, 200);
    }

    const eventId = 'evt-' + crypto.randomUUID();
    const ipRaw = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || '127.0.0.1';
    const ipHash = await hashString(ipRaw + '_archi_salt_2026');
    const userAgent = c.req.header('user-agent') || 'Unknown';
    const source = body.source || 'WEB_APP';

    // Atomic execution: append event and upsert state
    const existingState = await db.prepare(`
      SELECT id FROM user_consent_state 
      WHERE user_id = ? AND consent_type = 'TERMS' AND purpose_tag = 'DEFAULT'
    `).bind(uid).first();

    const batch = [
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, action_type,
          consent_purpose, idempotency_key, ip_hash, user_agent, source, recorded_at
        ) VALUES (?, ?, ?, 'TERMS_AND_CONDITIONS', ?, 'TERMS_ACCEPTED', 'PLATFORM_TERMS', ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `).bind(eventId, uid, doc.id, doc.version, idemKey, ipHash, userAgent, source)
    ];

    if (existingState) {
      batch.push(
        db.prepare(`
          UPDATE user_consent_state 
          SET current_status = 'ACCEPTED', accepted_version = ?, last_event_id = ?, updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `).bind(doc.version, eventId, existingState.id)
      );
    } else {
      const stateId = 'st-' + crypto.randomUUID();
      batch.push(
        db.prepare(`
          INSERT INTO user_consent_state (
            id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at
          ) VALUES (?, ?, 'TERMS', 'DEFAULT', 'ACCEPTED', ?, ?, CURRENT_TIMESTAMP)
        `).bind(stateId, uid, doc.version, eventId)
      );
    }

    await db.batch(batch);

    return c.json({ 
      success: true, 
      eventId, 
      acceptedVersion: doc.version 
    });
  });

  // POST /api/legal/acknowledge-privacy
  // Separately records review and acknowledgment of the Privacy Policy / Notice
  app.post('/api/legal/acknowledge-privacy', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    await ensureDefaultLegalDocuments(db);

    // Validate target privacy notice
    let doc: any = null;
    if (body.documentId) {
      doc = await db.prepare(`
        SELECT id, document_type, version, status 
        FROM legal_documents 
        WHERE id = ?
      `).bind(body.documentId).first();
    }
    if (!doc && body.version) {
      doc = await db.prepare(`
        SELECT id, document_type, version, status
        FROM legal_documents
        WHERE document_type = 'PRIVACY_POLICY' AND version = ? AND status = 'EFFECTIVE'
      `).bind(body.version).first();
    }
    if (!doc) {
      doc = await db.prepare(`
        SELECT id, document_type, version, status 
        FROM legal_documents 
        WHERE document_type = 'PRIVACY_POLICY' AND status = 'EFFECTIVE'
      `).first();
    }

    if (!doc || doc.status !== 'EFFECTIVE' || doc.document_type !== 'PRIVACY_POLICY') {
      return c.json({ error: 'Target Privacy Notice is not currently effective or does not exist', code: 'INVALID_DOCUMENT' }, 400);
    }

    // Idempotency check
    const idemKey = body.idempotencyKey || await hashString(`privacy_${uid}_${doc.id}_${doc.version}`);
    const existingEvent = await db.prepare('SELECT id FROM legal_consent_events WHERE idempotency_key = ?').bind(idemKey).first();
    if (existingEvent) {
      return c.json({ 
        success: true, 
        idempotent: true, 
        eventId: existingEvent.id, 
        acknowledgedVersion: doc.version 
      }, 200);
    }

    const eventId = 'evt-' + crypto.randomUUID();
    const ipRaw = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || '127.0.0.1';
    const ipHash = await hashString(ipRaw + '_archi_salt_2026');
    const userAgent = c.req.header('user-agent') || 'Unknown';
    const source = body.source || 'WEB_APP';

    const existingState = await db.prepare(`
      SELECT id FROM user_consent_state 
      WHERE user_id = ? AND consent_type = 'PRIVACY_NOTICE' AND purpose_tag = 'DEFAULT'
    `).bind(uid).first();

    const batch = [
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, action_type,
          consent_purpose, idempotency_key, ip_hash, user_agent, source, recorded_at
        ) VALUES (?, ?, ?, 'PRIVACY_POLICY', ?, 'NOTICE_ACKNOWLEDGED', 'PRIVACY_NOTICE', ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `).bind(eventId, uid, doc.id, doc.version, idemKey, ipHash, userAgent, source)
    ];

    if (existingState) {
      batch.push(
        db.prepare(`
          UPDATE user_consent_state 
          SET current_status = 'ACKNOWLEDGED', accepted_version = ?, last_event_id = ?, updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `).bind(doc.version, eventId, existingState.id)
      );
    } else {
      const stateId = 'st-' + crypto.randomUUID();
      batch.push(
        db.prepare(`
          INSERT INTO user_consent_state (
            id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at
          ) VALUES (?, ?, 'PRIVACY_NOTICE', 'DEFAULT', 'ACKNOWLEDGED', ?, ?, CURRENT_TIMESTAMP)
        `).bind(stateId, uid, doc.version, eventId)
      );
    }

    await db.batch(batch);

    return c.json({ 
      success: true, 
      eventId, 
      acknowledgedVersion: doc.version 
    });
  });

  // POST /api/legal/consent
  // Grants or withdraws granular, purpose-specific optional consent
  app.post('/api/legal/consent', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { purpose, granted } = body;
    if (!purpose || typeof granted !== 'boolean') {
      return c.json({ error: 'Missing or invalid purpose or granted flag' }, 400);
    }

    await ensureDefaultLegalDocuments(db);

    // Lookup effective privacy document reference
    let doc: any = null;
    if (body.documentId) {
      doc = await db.prepare('SELECT id, version FROM legal_documents WHERE id = ?').bind(body.documentId).first();
    }
    if (!doc && body.version) {
      doc = await db.prepare(`
        SELECT id, version FROM legal_documents
        WHERE document_type = 'PRIVACY_POLICY' AND version = ? AND status = 'EFFECTIVE'
      `).bind(body.version).first();
    }
    if (!doc) {
      doc = await db.prepare(`
        SELECT id, version FROM legal_documents 
        WHERE document_type = 'PRIVACY_POLICY' AND status = 'EFFECTIVE'
      `).first();
    }

    const docId = doc?.id || 'doc-priv-v1';
    const docVer = doc?.version || '1.0.0';

    const actionType = granted ? 'OPTIONAL_CONSENT_GRANTED' : 'OPTIONAL_CONSENT_WITHDRAWN';
    const newStatus = granted ? 'GRANTED' : 'WITHDRAWN';

    const idemKey = body.idempotencyKey || await hashString(`consent_${uid}_${purpose}_${actionType}_${Date.now()}_${Math.random()}`);

    const eventId = 'evt-' + crypto.randomUUID();
    const ipRaw = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || '127.0.0.1';
    const ipHash = await hashString(ipRaw + '_archi_salt_2026');
    const userAgent = c.req.header('user-agent') || 'Unknown';
    const source = body.source || 'WEB_APP';

    const existingState = await db.prepare(`
      SELECT id FROM user_consent_state 
      WHERE user_id = ? AND consent_type = 'OPTIONAL_PURPOSE' AND purpose_tag = ?
    `).bind(uid, purpose).first();

    const batch = [
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, action_type,
          consent_purpose, idempotency_key, ip_hash, user_agent, source, recorded_at
        ) VALUES (?, ?, ?, 'OPTIONAL_CONSENT', ?, ?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `).bind(eventId, uid, docId, docVer, actionType, purpose, idemKey, ipHash, userAgent, source)
    ];

    if (existingState) {
      batch.push(
        db.prepare(`
          UPDATE user_consent_state 
          SET current_status = ?, last_event_id = ?, updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `).bind(newStatus, eventId, existingState.id)
      );
    } else {
      const stateId = 'st-' + crypto.randomUUID();
      batch.push(
        db.prepare(`
          INSERT INTO user_consent_state (
            id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at
          ) VALUES (?, ?, 'OPTIONAL_PURPOSE', ?, ?, ?, ?, CURRENT_TIMESTAMP)
        `).bind(stateId, uid, purpose, newStatus, docVer, eventId)
      );
    }

    await db.batch(batch);

    return c.json({ 
      success: true, 
      purpose, 
      status: newStatus, 
      eventId 
    });
  });

  // =========================================================================
  // PRIVACY REQUESTS & GRIEVANCE REDRESSAL (DPDP SEC 11/12 & IT SPDI RULE 5(9))
  // =========================================================================

  // POST /api/users/me/privacy-requests
  // Submits a data access, correction, erasure, or grievance redressal request
  app.post('/api/users/me/privacy-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { requestType, details } = body;
    const validTypes = ['DATA_ACCESS', 'DATA_CORRECTION', 'DATA_ERASURE', 'GRIEVANCE'];
    if (!requestType || !validTypes.includes(requestType)) {
      return c.json({ error: 'Invalid or missing requestType. Must be one of: ' + validTypes.join(', ') }, 400);
    }

    if (!details || typeof details !== 'string' || details.trim().length < 5) {
      return c.json({ error: 'Details must be at least 5 characters long' }, 400);
    }

    // Determine verified statutory basis and deadlines without guessing unprescribed dates
    let statutoryBasis = 'DPDP_SEC_11';
    let statutoryDeadline: string | null = null;
    let targetDays = 15;

    if (requestType === 'DATA_ACCESS' || requestType === 'DATA_CORRECTION') {
      statutoryBasis = 'DPDP_SEC_11';
      statutoryDeadline = null; // Unprescribed under notified DPDP rules
      targetDays = 15;
    } else if (requestType === 'DATA_ERASURE') {
      statutoryBasis = 'DPDP_SEC_12';
      statutoryDeadline = null;
      targetDays = 30;
    } else if (requestType === 'GRIEVANCE') {
      statutoryBasis = 'IT_SPDI_RULE_5_9';
      // IT SPDI Rule 5(9) explicitly mandates redressal within 1 month (30 days)
      const deadlineDate = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
      statutoryDeadline = deadlineDate.toISOString().replace('T', ' ').slice(0, 19);
      targetDays = 15; // Proactive operational target ahead of statutory deadline
    }

    const targetDate = new Date(Date.now() + targetDays * 24 * 60 * 60 * 1000);
    const operationalTargetDate = targetDate.toISOString().replace('T', ' ').slice(0, 19);

    const ticketId = 'REQ-' + new Date().toISOString().slice(0, 10).replace(/-/g, '') + '-' + Math.floor(1000 + Math.random() * 9000);

    await db.prepare(`
      INSERT INTO privacy_requests (
        id, user_id, request_type, details, status, statutory_basis, statutory_deadline, operational_target_date, created_at
      ) VALUES (?, ?, ?, ?, 'PENDING', ?, ?, ?, CURRENT_TIMESTAMP)
    `).bind(ticketId, uid, requestType, details.trim(), statutoryBasis, statutoryDeadline, operationalTargetDate).run();

    return c.json({
      success: true,
      request: {
        id: ticketId,
        userId: uid,
        requestType,
        details: details.trim(),
        status: 'PENDING',
        statutoryBasis,
        statutoryDeadline,
        operationalTargetDate
      }
    }, 201);
  });

  // GET /api/users/me/privacy-requests
  // Returns caller's own submitted requests (strict user ownership enforced server-side)
  app.get('/api/users/me/privacy-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { results } = await db.prepare(`
      SELECT id, user_id, request_type, details, status, statutory_basis, statutory_deadline, 
             operational_target_date, resolution_notes, created_at, acknowledged_at, resolved_at 
      FROM privacy_requests 
      WHERE user_id = ? 
      ORDER BY created_at DESC
    `).bind(uid).all();

    return c.json({ requests: results || [] });
  });

  // =========================================================================
  // ADMIN LEGAL & PRIVACY OPERATIONS (RESTRICTED TO ADMIN & STUDIO_ADMIN)
  // =========================================================================

  // GET /api/admin/legal/documents
  // Lists all legal documents across all lifecycle statuses (DRAFT, PUBLISHED, EFFECTIVE, SUPERSEDED, ARCHIVED)
  app.get('/api/admin/legal/documents', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const { results } = await db.prepare(`
      SELECT id, document_type, version, title, effective_at, published_at, published_by, 
             status, is_mandatory, locale, change_summary, created_at, updated_at 
      FROM legal_documents 
      ORDER BY created_at DESC
    `).all();

    return c.json({ documents: results || [] });
  });

  // POST /api/admin/legal/documents
  // Creates a new legal policy version draft
  app.post('/api/admin/legal/documents', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const body = await c.req.json().catch(() => ({}));
    const { documentType, version, title, content, effectiveAt, isMandatory, locale, changeSummary } = body;

    if (!documentType || !version || !title || !content) {
      return c.json({ error: 'Missing required document fields (documentType, version, title, content)' }, 400);
    }

    const docId = body.id || 'doc-' + crypto.randomUUID();
    const docLocale = locale || 'en-IN';
    const effectiveDate = effectiveAt || new Date().toISOString().replace('T', ' ').slice(0, 19);
    const mandatoryFlag = isMandatory === false ? 0 : 1;

    try {
      await db.prepare(`
        INSERT INTO legal_documents (
          id, document_type, version, title, content, effective_at, status, is_mandatory, locale, change_summary, created_at, updated_at
        ) VALUES (?, ?, ?, ?, ?, ?, 'DRAFT', ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      `).bind(docId, documentType, version, title, content, effectiveDate, mandatoryFlag, docLocale, changeSummary || null).run();

      return c.json({ success: true, documentId: docId, status: 'DRAFT' }, 201);
    } catch (err: any) {
      if (err.message && err.message.includes('UNIQUE')) {
        return c.json({ error: 'Document version already exists for this type and locale', code: 'DUPLICATE_VERSION' }, 409);
      }
      throw err;
    }
  });

  // POST /api/admin/legal/documents/:id/publish
  // Atomically transitions prior effective document of same type & locale to SUPERSEDED, and promotes target to EFFECTIVE
  app.post('/api/admin/legal/documents/:id/publish', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const docId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const targetDoc = await db.prepare('SELECT id, document_type, locale, status FROM legal_documents WHERE id = ?').bind(docId).first();
    if (!targetDoc) {
      return c.json({ error: 'Document not found' }, 404);
    }

    // Atomic promotion: Supersede existing effective version of same (document_type, locale), then set target to EFFECTIVE
    const batch = [
      db.prepare(`
        UPDATE legal_documents 
        SET status = 'SUPERSEDED', updated_at = CURRENT_TIMESTAMP 
        WHERE document_type = ? AND locale = ? AND status = 'EFFECTIVE' AND id != ?
      `).bind(targetDoc.document_type, targetDoc.locale, docId),
      db.prepare(`
        UPDATE legal_documents 
        SET status = 'EFFECTIVE', published_at = CURRENT_TIMESTAMP, published_by = ?, updated_at = CURRENT_TIMESTAMP 
        WHERE id = ?
      `).bind(uid, docId)
    ];

    await db.batch(batch);

    return c.json({ success: true, documentId: docId, status: 'EFFECTIVE' });
  });

  // GET /api/admin/legal/privacy-requests
  // Lists all privacy and grievance requests across all platform users
  app.get('/api/admin/legal/privacy-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const statusFilter = c.req.query('status');
    let query = `
      SELECT pr.*, u.email as user_email, u.name as user_name, u.role as user_role 
      FROM privacy_requests pr 
      JOIN users u ON pr.user_id = u.id
    `;
    const params: any[] = [];

    if (statusFilter) {
      query += ' WHERE pr.status = ?';
      params.push(statusFilter);
    }

    query += ' ORDER BY pr.created_at DESC';

    const { results } = await db.prepare(query).bind(...params).all();
    return c.json({ requests: results || [] });
  });

  // POST /api/admin/legal/privacy-requests/:id/resolve
  // Updates status and resolution notes of a user's privacy/grievance request
  app.post('/api/admin/legal/privacy-requests/:id/resolve', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const requestId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const body = await c.req.json().catch(() => ({}));
    const { status, resolutionNotes } = body;

    const validStatuses = ['ACKNOWLEDGED', 'RESOLVED', 'REJECTED'];
    if (!status || !validStatuses.includes(status)) {
      return c.json({ error: 'Invalid status. Must be one of: ' + validStatuses.join(', ') }, 400);
    }

    const targetReq = await db.prepare('SELECT id FROM privacy_requests WHERE id = ?').bind(requestId).first();
    if (!targetReq) {
      return c.json({ error: 'Privacy request not found' }, 404);
    }

    let updateSql = 'UPDATE privacy_requests SET status = ?, resolution_notes = ?, resolved_by = ?';
    const params: any[] = [status, resolutionNotes || null, uid];

    if (status === 'ACKNOWLEDGED') {
      updateSql += ', acknowledged_at = CURRENT_TIMESTAMP WHERE id = ?';
    } else {
      updateSql += ', resolved_at = CURRENT_TIMESTAMP WHERE id = ?';
    }
    params.push(requestId);

    await db.prepare(updateSql).bind(...params).run();

    return c.json({ success: true, requestId, status });
  });

  // GET /api/admin/legal/consents
  // Returns paginated immutable consent event ledger for regulatory audit inspections
  app.get('/api/admin/legal/consents', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const limit = Math.min(Number(c.req.query('limit')) || 50, 100);
    const offset = Number(c.req.query('offset')) || 0;

    const { results } = await db.prepare(`
      SELECT id, user_id, document_id, document_type, document_version, action_type, 
             consent_purpose, idempotency_key, ip_hash, user_agent, source, recorded_at 
      FROM legal_consent_events 
      ORDER BY recorded_at DESC 
      LIMIT ? OFFSET ?
    `).bind(limit, offset).all();

    return c.json({ events: results || [], count: (results || []).length });
  });
}

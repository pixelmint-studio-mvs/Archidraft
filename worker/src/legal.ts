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
    "SELECT COUNT(*) as count FROM legal_documents WHERE document_type = 'TERMS_AND_CONDITIONS' AND status = 'EFFECTIVE'"
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
    "SELECT COUNT(*) as count FROM legal_documents WHERE document_type = 'PRIVACY_POLICY' AND status = 'EFFECTIVE'"
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

  // =========================================================================
  // CANONICAL BUSINESS PROFILE
  // =========================================================================

  // GET /api/legal/business-profile
  app.get('/api/legal/business-profile', async (c) => {
    const db = c.env.DB;
    try {
      const profile = await db.prepare(
        "SELECT * FROM legal_business_profile WHERE id = 'current'"
      ).first();
      if (profile) {
        return c.json({ businessProfile: profile });
      }
    } catch (_) {}

    return c.json({
      businessProfile: {
        legal_proprietor: 'MOHAMMED MOSIN S',
        business_structure: 'Sole Proprietorship',
        operating_brand: 'DRAUGHTSMAN STUDIO',
        product_name: 'ARCHI DRAFT',
        application_website: 'https://archidraft.draughtsmanstudio.com',
        business_website: 'https://draughtsmanstudio.com',
        support_email: 'support@draughtsmanstudio.com',
        privacy_email: 'support@draughtsmanstudio.com',
        grievance_email: 'mosin@draughtsmanstudio.com',
        physical_address_status: 'PENDING_VERIFICATION',
        grievance_officer_appointment_status: 'PENDING_VERIFICATION',
        configuration_version: '1.0.0'
      }
    });
  });

  // =========================================================================
  // ACCOUNT DELETION WORKFLOW (USER RIGHTS & ERASURE - DPDP SEC 12)
  // =========================================================================

  // POST /api/legal/account-deletion-requests
  app.post('/api/legal/account-deletion-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const activeReq = await db.prepare(`
      SELECT id, status, submitted_at FROM account_deletion_requests 
      WHERE user_id = ? AND status IN ('SUBMITTED', 'IDENTITY_VERIFICATION_REQUIRED', 'VERIFIED', 'UNDER_REVIEW', 'DELETION_SCHEDULED', 'PROCESSING')
      LIMIT 1
    `).bind(uid).first();

    if (activeReq) {
      return c.json({ 
        error: 'An active account deletion request is already in progress',
        code: 'DELETION_REQUEST_EXISTS',
        request: activeReq 
      }, 409);
    }

    const requestId = 'del-' + crypto.randomUUID();
    const reason = typeof body.reason === 'string' ? body.reason.trim().slice(0, 500) : null;
    const category = body.requestCategory || 'SELF_SERVICE';

    await db.prepare(`
      INSERT INTO account_deletion_requests (
        id, user_id, request_category, status, identity_verification_status, reason, submitted_at
      ) VALUES (?, ?, ?, 'SUBMITTED', 'VERIFIED', ?, CURRENT_TIMESTAMP)
    `).bind(requestId, uid, category, reason).run();

    return c.json({
      success: true,
      request: {
        id: requestId,
        userId: uid,
        status: 'SUBMITTED',
        identityVerificationStatus: 'VERIFIED',
        reason,
        submittedAt: new Date().toISOString()
      }
    }, 201);
  });

  // GET /api/legal/account-deletion-requests/me
  app.get('/api/legal/account-deletion-requests/me', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { results } = await db.prepare(`
      SELECT id, user_id, request_category, status, identity_verification_status,
             reason, review_notes, resolution_status, submitted_at, scheduled_for,
             processed_at, completed_at, cancelled_at, failure_details, retention_hold_reason
      FROM account_deletion_requests
      WHERE user_id = ?
      ORDER BY submitted_at DESC
    `).bind(uid).all();

    return c.json({ requests: results || [] });
  });

  // POST /api/legal/account-deletion-requests/:id/cancel
  app.post('/api/legal/account-deletion-requests/:id/cancel', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const requestId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const req = await db.prepare(`
      SELECT id, status FROM account_deletion_requests WHERE id = ? AND user_id = ?
    `).bind(requestId, uid).first<any>();

    if (!req) {
      return c.json({ error: 'Deletion request not found' }, 404);
    }

    if (['COMPLETED', 'PROCESSING', 'CANCELLED'].includes(req.status)) {
      return c.json({ 
        error: `Request cannot be cancelled in status ${req.status}`,
        code: 'CANNOT_CANCEL_REQUEST'
      }, 400);
    }

    await db.prepare(`
      UPDATE account_deletion_requests 
      SET status = 'CANCELLED', cancelled_at = CURRENT_TIMESTAMP 
      WHERE id = ? AND user_id = ?
    `).bind(requestId, uid).run();

    return c.json({ success: true, requestId, status: 'CANCELLED' });
  });

  // =========================================================================
  // DATA EXPORT WORKFLOW (DPDP SEC 11)
  // =========================================================================

  // POST /api/legal/data-export-requests
  app.post('/api/legal/data-export-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const activeReq = await db.prepare(`
      SELECT id, status FROM data_export_requests 
      WHERE user_id = ? AND status IN ('PENDING', 'PROCESSING')
      LIMIT 1
    `).bind(uid).first();

    if (activeReq) {
      return c.json({ 
        error: 'An active data export request is already pending',
        code: 'EXPORT_REQUEST_EXISTS',
        request: activeReq 
      }, 409);
    }

    const requestId = 'exp-' + crypto.randomUUID();
    const scope = body.exportScope || 'FULL_PERSONAL_DATA';
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString().replace('T', ' ').slice(0, 19);
    const r2Key = `exports/${uid}/${requestId}.json`;

    await db.prepare(`
      INSERT INTO data_export_requests (
        id, user_id, verification_status, export_scope, status, download_r2_key, download_url_expires_at, requested_at
      ) VALUES (?, ?, 'VERIFIED', ?, 'PENDING', ?, ?, CURRENT_TIMESTAMP)
    `).bind(requestId, uid, scope, r2Key, expiresAt).run();

    return c.json({
      success: true,
      request: {
        id: requestId,
        userId: uid,
        exportScope: scope,
        status: 'PENDING',
        downloadR2Key: r2Key,
        expiresAt
      }
    }, 201);
  });

  // GET /api/legal/data-export-requests/me
  app.get('/api/legal/data-export-requests/me', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { results } = await db.prepare(`
      SELECT id, user_id, verification_status, export_scope, status, download_r2_key,
             download_url_expires_at, requested_at, completed_at, failure_details
      FROM data_export_requests
      WHERE user_id = ?
      ORDER BY requested_at DESC
    `).bind(uid).all();

    return c.json({ requests: results || [] });
  });

  // GET /api/legal/data-export-requests/:id/download
  // Authenticated, owner-authorized download endpoint with strict 7-day server-side expiry enforcement
  app.get('/api/legal/data-export-requests/:id/download', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const storage = c.env.STORAGE;
    const requestId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const req = await db.prepare(`SELECT * FROM data_export_requests WHERE id = ?`).bind(requestId).first<any>();
    if (!req) return c.json({ error: 'Data export request not found' }, 404);

    // Strict ownership & authorization check (IDOR prevention)
    if (req.user_id !== uid && user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN') {
      return c.json({ error: 'Forbidden: Access denied to export request' }, 403);
    }

    // Status check
    if (req.status !== 'COMPLETED') {
      return c.json({ 
        error: 'Export archive is not yet ready for download',
        status: req.status 
      }, 409);
    }

    // Strict server-side 7-day token expiration check
    if (req.download_url_expires_at) {
      const expiresAt = new Date(req.download_url_expires_at).getTime();
      if (Date.now() > expiresAt) {
        return c.json({ 
          error: 'Download token has expired. Export links are valid for exactly 7 days. Please request a fresh export.',
          code: 'EXPORT_TOKEN_EXPIRED',
          expiredAt: req.download_url_expires_at 
        }, 410);
      }
    }

    // If R2 storage object exists, retrieve and stream it
    if (storage && req.download_r2_key) {
      try {
        const obj = await storage.get(req.download_r2_key);
        if (obj) {
          return new Response(obj.body, {
            headers: {
              'Content-Type': 'application/json',
              'Content-Disposition': `attachment; filename="archi_draft_export_${uid}_${requestId.slice(-6)}.json"`,
              'Cache-Control': 'no-store, no-cache, must-revalidate, private',
            }
          });
        }
      } catch (_) {}
    }

    // Self-generating structured export JSON if R2 object is not yet populated
    const exportData = {
      archiveMetadata: {
        exportId: req.id,
        userId: req.user_id,
        exportScope: req.export_scope,
        generatedAt: req.completed_at || new Date().toISOString(),
        expiresAt: req.download_url_expires_at,
        platform: 'ARCHI DRAFT / DRAUGHTSMAN STUDIO',
        legalEntity: 'MOHAMMED MOSIN S (Sole Proprietorship)',
      },
      userProfile: {
        id: user.id,
        email: user.email,
        name: user.name,
        role: user.role,
        mobile: user.mobile,
      },
      exportStatus: 'COMPLETED',
    };

    return new Response(JSON.stringify(exportData, null, 2), {
      headers: {
        'Content-Type': 'application/json',
        'Content-Disposition': `attachment; filename="archi_draft_export_${uid}_${requestId.slice(-6)}.json"`,
        'Cache-Control': 'no-store, no-cache, must-revalidate, private',
      }
    });
  });

  // =========================================================================
  // DATA CORRECTION WORKFLOW (DPDP SEC 12)
  // =========================================================================

  // POST /api/legal/data-correction-requests
  app.post('/api/legal/data-correction-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { fieldName, proposedValue, reason } = body;
    const allowedFields = ['name', 'mobile', 'phone', 'college_name', 'specialization', 'qualification', 'professional_qualification', 'company_name', 'address', 'postal_address'];

    if (!fieldName || !allowedFields.includes(fieldName)) {
      return c.json({ 
        error: 'Invalid fieldName for correction. Must be one of: ' + allowedFields.join(', '),
        code: 'INVALID_FIELD' 
      }, 400);
    }

    if (!proposedValue || typeof proposedValue !== 'string' || proposedValue.trim().length === 0) {
      return c.json({ error: 'proposedValue is required', code: 'INVALID_VALUE' }, 400);
    }

    const requestId = 'cor-' + crypto.randomUUID();

    await db.prepare(`
      INSERT INTO data_correction_requests (
        id, user_id, field_name, proposed_value, reason, status, created_at
      ) VALUES (?, ?, ?, ?, ?, 'PENDING', CURRENT_TIMESTAMP)
    `).bind(requestId, uid, fieldName, proposedValue.trim(), reason || null).run();

    return c.json({
      success: true,
      request: {
        id: requestId,
        userId: uid,
        fieldName,
        proposedValue: proposedValue.trim(),
        reason: reason || null,
        status: 'PENDING'
      }
    }, 201);
  });

  // GET /api/legal/data-correction-requests/me
  app.get('/api/legal/data-correction-requests/me', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { results } = await db.prepare(`
      SELECT id, user_id, field_name, proposed_value, reason, status, reviewed_by, review_notes, created_at, resolved_at
      FROM data_correction_requests
      WHERE user_id = ?
      ORDER BY created_at DESC
    `).bind(uid).all();

    return c.json({ requests: results || [] });
  });

  // =========================================================================
  // CONSENT WITHDRAWAL ENDPOINT (DPDP SEC 6(4))
  // =========================================================================

  // POST /api/legal/consents/withdraw
  app.post('/api/legal/consents/withdraw', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { purpose } = body;
    if (!purpose || typeof purpose !== 'string' || purpose.trim().length === 0) {
      return c.json({ error: 'purpose tag is required for consent withdrawal', code: 'INVALID_PURPOSE' }, 400);
    }

    const eventId = 'evt-' + crypto.randomUUID();
    const idemKey = body.idempotencyKey || await hashString(`withdraw_${uid}_${purpose}_${Date.now()}`);
    const ipRaw = c.req.header('cf-connecting-ip') || c.req.header('x-forwarded-for') || '127.0.0.1';
    const ipHash = await hashString(ipRaw + '_archi_salt_2026');
    const userAgent = c.req.header('user-agent') || 'Unknown';
    const source = body.source || 'WEB_APP';

    const existingState = await db.prepare(`
      SELECT id FROM user_consent_state 
      WHERE user_id = ? AND consent_type = 'OPTIONAL_PURPOSE' AND purpose_tag = ?
    `).bind(uid, purpose).first<any>();

    const batch = [
      db.prepare(`
        INSERT INTO legal_consent_events (
          id, user_id, document_id, document_type, document_version, action_type,
          consent_purpose, idempotency_key, ip_hash, user_agent, source, recorded_at
        ) VALUES (?, ?, 'doc-priv-v1', 'OPTIONAL_CONSENT', '1.0.0', 'OPTIONAL_CONSENT_WITHDRAWN', ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
      `).bind(eventId, uid, purpose, idemKey, ipHash, userAgent, source)
    ];

    if (existingState) {
      batch.push(
        db.prepare(`
          UPDATE user_consent_state 
          SET current_status = 'WITHDRAWN', last_event_id = ?, updated_at = CURRENT_TIMESTAMP
          WHERE id = ?
        `).bind(eventId, existingState.id)
      );
    } else {
      const stateId = 'st-' + crypto.randomUUID();
      batch.push(
        db.prepare(`
          INSERT INTO user_consent_state (
            id, user_id, consent_type, purpose_tag, current_status, accepted_version, last_event_id, updated_at
          ) VALUES (?, ?, 'OPTIONAL_PURPOSE', ?, 'WITHDRAWN', '1.0.0', ?, CURRENT_TIMESTAMP)
        `).bind(stateId, uid, purpose, eventId)
      );
    }

    await db.batch(batch);

    return c.json({
      success: true,
      purpose,
      status: 'WITHDRAWN',
      eventId
    });
  });

  // =========================================================================
  // GUARDIAN CONSENTS (DPDP SEC 9 - STUDENT SAFEGUARDS)
  // =========================================================================

  // POST /api/legal/guardian-consents
  app.post('/api/legal/guardian-consents', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { guardianName, guardianEmail, guardianPhone, relationship, consentPolicyVersion } = body;
    if (!guardianName || !guardianEmail || !relationship) {
      return c.json({ error: 'guardianName, guardianEmail, and relationship are required', code: 'INVALID_GUARDIAN_DATA' }, 400);
    }

    const consentId = 'grd-' + crypto.randomUUID();
    const version = consentPolicyVersion || '1.0.0';

    await db.prepare(`
      INSERT INTO guardian_consents (
        id, student_user_id, guardian_name, guardian_email, guardian_phone, relationship,
        consent_policy_version, verification_method, verification_status, created_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, 'MANUAL_OFFICIAL_REVIEW', 'PENDING_VERIFICATION', CURRENT_TIMESTAMP)
    `).bind(consentId, uid, guardianName.trim(), guardianEmail.trim().toLowerCase(), guardianPhone || null, relationship.trim(), version).run();

    return c.json({
      success: true,
      guardianConsent: {
        id: consentId,
        studentUserId: uid,
        guardianName: guardianName.trim(),
        guardianEmail: guardianEmail.trim().toLowerCase(),
        relationship: relationship.trim(),
        verificationStatus: 'PENDING_VERIFICATION'
      }
    }, 201);
  });

  // GET /api/legal/guardian-consents/me
  app.get('/api/legal/guardian-consents/me', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { results } = await db.prepare(`
      SELECT id, student_user_id, guardian_name, guardian_email, guardian_phone, relationship,
             consent_policy_version, verification_method, verification_status, verified_at, withdrawn_at, notes, created_at
      FROM guardian_consents
      WHERE student_user_id = ?
      ORDER BY created_at DESC
    `).bind(uid).all();

    return c.json({ guardianConsents: results || [] });
  });

  // =========================================================================
  // CANCELLATION & REFUND REQUESTS
  // =========================================================================

  // POST /api/legal/cancellation-refund-requests
  app.post('/api/legal/cancellation-refund-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const body = await c.req.json().catch(() => ({}));

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { requestType, referenceId, amountRequested, reason } = body;
    const validTypes = ['PROJECT_CANCELLATION', 'SUBSCRIPTION_CANCELLATION', 'STUDENT_COURSE_REFUND', 'GENERAL_REFUND'];

    if (!requestType || !validTypes.includes(requestType)) {
      return c.json({ error: 'Invalid requestType. Must be one of: ' + validTypes.join(', '), code: 'INVALID_REQUEST_TYPE' }, 400);
    }

    if (!reason || typeof reason !== 'string' || reason.trim().length < 5) {
      return c.json({ error: 'Reason must be at least 5 characters long', code: 'INVALID_REASON' }, 400);
    }

    const requestId = 'ref-' + crypto.randomUUID();
    const amount = typeof amountRequested === 'number' ? amountRequested : null;

    await db.prepare(`
      INSERT INTO cancellation_refund_requests (
        id, user_id, request_type, reference_id, amount_requested, currency, reason, status, created_at
      ) VALUES (?, ?, ?, ?, ?, 'INR', ?, 'PENDING', CURRENT_TIMESTAMP)
    `).bind(requestId, uid, requestType, referenceId || null, amount, reason.trim()).run();

    return c.json({
      success: true,
      refundRequest: {
        id: requestId,
        userId: uid,
        requestType,
        referenceId: referenceId || null,
        amountRequested: amount,
        currency: 'INR',
        reason: reason.trim(),
        status: 'PENDING'
      }
    }, 201);
  });

  // GET /api/legal/cancellation-refund-requests/me
  app.get('/api/legal/cancellation-refund-requests/me', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user) return c.json({ error: 'User not found' }, 404);

    const { results } = await db.prepare(`
      SELECT id, user_id, request_type, reference_id, amount_requested, amount_approved, currency,
             reason, status, review_decision, resolution_notes, refund_transaction_ref, created_at, resolved_at
      FROM cancellation_refund_requests
      WHERE user_id = ?
      ORDER BY created_at DESC
    `).bind(uid).all();

    return c.json({ refundRequests: results || [] });
  });

  // =========================================================================
  // ADMIN COMPLIANCE & REVIEW ENDPOINTS (ADMIN & STUDIO_ADMIN ONLY)
  // =========================================================================

  // GET /api/admin/legal/stats
  // Aggregated KPI counts for the Admin Legal Compliance Dashboard
  app.get('/api/admin/legal/stats', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    try {
      const [
        docStats,
        pendingDeletions,
        pendingExports,
        pendingCorrections,
        pendingGuardians,
        pendingRefunds,
        pendingPrivacy,
        consentTotal,
        retentionTotal
      ] = await Promise.all([
        db.prepare(`
          SELECT 
            COUNT(*) as total,
            SUM(CASE WHEN status = 'EFFECTIVE' OR status = 'PUBLISHED' THEN 1 ELSE 0 END) as published,
            SUM(CASE WHEN status = 'DRAFT' THEN 1 ELSE 0 END) as draft,
            SUM(CASE WHEN status = 'PENDING_LEGAL_REVIEW' OR status = 'UNDER_REVIEW' THEN 1 ELSE 0 END) as pending_review
          FROM legal_documents
        `).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM account_deletion_requests WHERE status IN ('PENDING', 'IDENTITY_VERIFICATION_REQUIRED', 'UNDER_REVIEW', 'DELETION_SCHEDULED')`).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM data_export_requests WHERE status IN ('PENDING', 'PROCESSING')`).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM data_correction_requests WHERE status IN ('PENDING', 'UNDER_REVIEW')`).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM guardian_consents WHERE verification_status = 'PENDING'`).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM cancellation_refund_requests WHERE status IN ('PENDING', 'UNDER_REVIEW')`).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM privacy_requests WHERE status IN ('PENDING', 'ACKNOWLEDGED')`).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM legal_consent_events`).first<any>(),
        db.prepare(`SELECT COUNT(*) as count FROM data_retention_policies`).first<any>(),
      ]);

      return c.json({
        documents: {
          total: Number(docStats?.total || 0),
          published: Number(docStats?.published || 0),
          draft: Number(docStats?.draft || 0),
          pendingReview: Number(docStats?.pending_review || 0),
        },
        queues: {
          pendingDeletions: Number(pendingDeletions?.count || 0),
          pendingExports: Number(pendingExports?.count || 0),
          pendingCorrections: Number(pendingCorrections?.count || 0),
          pendingGuardians: Number(pendingGuardians?.count || 0),
          pendingRefunds: Number(pendingRefunds?.count || 0),
          pendingPrivacyRequests: Number(pendingPrivacy?.count || 0),
          totalPendingAction: 
            Number(pendingDeletions?.count || 0) +
            Number(pendingExports?.count || 0) +
            Number(pendingCorrections?.count || 0) +
            Number(pendingGuardians?.count || 0) +
            Number(pendingRefunds?.count || 0) +
            Number(pendingPrivacy?.count || 0),
        },
        telemetry: {
          totalConsentEvents: Number(consentTotal?.count || 0),
          retentionPoliciesConfigured: Number(retentionTotal?.count || 0),
        }
      });
    } catch (err: any) {
      return c.json({ error: 'Failed to aggregate compliance metrics: ' + err.message }, 500);
    }
  });

  // GET /api/admin/legal/account-deletion-requests
  app.get('/api/admin/legal/account-deletion-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const statusFilter = c.req.query('status');
    let query = `
      SELECT dr.*, u.email as user_email, u.name as user_name, u.role as user_role
      FROM account_deletion_requests dr
      JOIN users u ON dr.user_id = u.id
    `;
    const params: any[] = [];
    if (statusFilter) {
      query += ' WHERE dr.status = ?';
      params.push(statusFilter);
    }
    query += ' ORDER BY dr.submitted_at DESC';

    const { results } = await db.prepare(query).bind(...params).all();
    return c.json({ requests: results || [] });
  });

  // PATCH /api/admin/legal/account-deletion-requests/:id
  app.patch('/api/admin/legal/account-deletion-requests/:id', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const requestId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const body = await c.req.json().catch(() => ({}));
    const { status, reviewNotes, retentionHoldReason, failureDetails } = body;

    const validStatuses = [
      'IDENTITY_VERIFICATION_REQUIRED', 'VERIFIED', 'UNDER_REVIEW', 'DELETION_SCHEDULED',
      'PROCESSING', 'PARTIALLY_COMPLETED', 'COMPLETED', 'REJECTED_WITH_REASON'
    ];
    if (!status || !validStatuses.includes(status)) {
      return c.json({ error: 'Invalid status. Must be one of: ' + validStatuses.join(', ') }, 400);
    }

    const req = await db.prepare(`SELECT * FROM account_deletion_requests WHERE id = ?`).bind(requestId).first<any>();
    if (!req) return c.json({ error: 'Deletion request not found' }, 404);

    let completedAt: string | null = null;
    let systemsProcessed: string | null = req.systems_processed;

    if (status === 'COMPLETED') {
      completedAt = new Date().toISOString().replace('T', ' ').slice(0, 19);
      const targetUserId = req.user_id;

      // 1. Tombstone user profile in D1 (retaining immutable UID for foreign-key integrity, marking SUSPENDED per CHECK constraint)
      await db.prepare(`
        UPDATE users 
        SET name = 'Deleted User', email = ?, mobile = NULL, status = 'SUSPENDED', updated_at = CURRENT_TIMESTAMP
        WHERE id = ?
      `).bind(`deleted_${targetUserId}@archidraft.local`, targetUserId).run();

      // 2. Purge personal AI conversations (chat_messages and chat_sessions)
      try {
        await db.prepare(`DELETE FROM chat_messages WHERE session_id IN (SELECT id FROM chat_sessions WHERE user_id = ?)`).bind(targetUserId).run();
        await db.prepare(`DELETE FROM chat_sessions WHERE user_id = ?`).bind(targetUserId).run();
      } catch (_) {}

      // 3. Mark processed systems
      systemsProcessed = JSON.stringify([
        'D1_PROFILE_ANONYMIZED',
        'PIXMINT_BOT_CONVERSATIONS_PURGED',
        'COLLABORATIVE_PROJECT_CAD_PRESERVED',
        'STATUTORY_CERTIN_LOGS_PRESERVED'
      ]);
    }

    await db.prepare(`
      UPDATE account_deletion_requests
      SET status = ?, review_notes = ?, assigned_admin_id = ?, retention_hold_reason = ?,
          failure_details = ?, completed_at = COALESCE(?, completed_at), systems_processed = COALESCE(?, systems_processed)
      WHERE id = ?
    `).bind(status, reviewNotes || null, uid, retentionHoldReason || null, failureDetails || null, completedAt, systemsProcessed, requestId).run();

    return c.json({ success: true, requestId, status, systemsProcessed });
  });

  // GET /api/admin/legal/data-export-requests
  app.get('/api/admin/legal/data-export-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const { results } = await db.prepare(`
      SELECT er.*, u.email as user_email, u.name as user_name, u.role as user_role
      FROM data_export_requests er
      JOIN users u ON er.user_id = u.id
      ORDER BY er.requested_at DESC
    `).all();

    return c.json({ requests: results || [] });
  });

  // PATCH /api/admin/legal/data-export-requests/:id
  app.patch('/api/admin/legal/data-export-requests/:id', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const requestId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const body = await c.req.json().catch(() => ({}));
    const { status, failureDetails } = body;

    const validStatuses = ['PROCESSING', 'COMPLETED', 'FAILED'];
    if (!status || !validStatuses.includes(status)) {
      return c.json({ error: 'Invalid status. Must be one of: ' + validStatuses.join(', ') }, 400);
    }

    let completedAt: string | null = null;
    if (status === 'COMPLETED') {
      completedAt = new Date().toISOString().replace('T', ' ').slice(0, 19);
    }

    await db.prepare(`
      UPDATE data_export_requests
      SET status = ?, failure_details = ?, completed_at = COALESCE(?, completed_at)
      WHERE id = ?
    `).bind(status, failureDetails || null, completedAt, requestId).run();

    return c.json({ success: true, requestId, status });
  });

  // GET /api/admin/legal/data-correction-requests
  app.get('/api/admin/legal/data-correction-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const { results } = await db.prepare(`
      SELECT cr.*, u.email as user_email, u.name as user_name, u.role as user_role
      FROM data_correction_requests cr
      JOIN users u ON cr.user_id = u.id
      ORDER BY cr.created_at DESC
    `).all();

    return c.json({ requests: results || [] });
  });

  // PATCH /api/admin/legal/data-correction-requests/:id
  app.patch('/api/admin/legal/data-correction-requests/:id', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const requestId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const body = await c.req.json().catch(() => ({}));
    const { status, reviewNotes, applyToUser } = body;

    const validStatuses = ['RESOLVED', 'REJECTED'];
    if (!status || !validStatuses.includes(status)) {
      return c.json({ error: 'Invalid status. Must be one of: ' + validStatuses.join(', ') }, 400);
    }

    const req = await db.prepare(`SELECT * FROM data_correction_requests WHERE id = ?`).bind(requestId).first<any>();
    if (!req) return c.json({ error: 'Correction request not found' }, 404);

    if (status === 'RESOLVED' && applyToUser !== false) {
      const colMap: Record<string, string> = {
        name: 'name',
        mobile: 'mobile',
        phone: 'mobile',
        college_name: 'college_name',
        specialization: 'specialization',
        qualification: 'qualification',
        professional_qualification: 'qualification',
        company_name: 'company_name',
        address: 'address',
        postal_address: 'address',
      };
      const targetCol = colMap[req.field_name];
      if (targetCol) {
        await db.prepare(`UPDATE users SET ${targetCol} = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?`)
          .bind(req.proposed_value, req.user_id).run();
      }
    }

    await db.prepare(`
      UPDATE data_correction_requests
      SET status = ?, review_notes = ?, reviewed_by = ?, resolved_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).bind(status, reviewNotes || null, uid, requestId).run();

    return c.json({ success: true, requestId, status });
  });

  // GET /api/admin/legal/guardian-consents
  app.get('/api/admin/legal/guardian-consents', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const { results } = await db.prepare(`
      SELECT gc.*, u.email as student_email, u.name as student_name
      FROM guardian_consents gc
      JOIN users u ON gc.student_user_id = u.id
      ORDER BY gc.created_at DESC
    `).all();

    return c.json({ guardianConsents: results || [] });
  });

  // PATCH /api/admin/legal/guardian-consents/:id
  app.patch('/api/admin/legal/guardian-consents/:id', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const consentId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const body = await c.req.json().catch(() => ({}));
    const { status, notes } = body;

    const validStatuses = ['VERIFIED', 'REJECTED', 'WITHDRAWN', 'EXPIRED'];
    if (!status || !validStatuses.includes(status)) {
      return c.json({ error: 'Invalid status. Must be one of: ' + validStatuses.join(', ') }, 400);
    }

    let verifiedAt: string | null = null;
    let withdrawnAt: string | null = null;

    if (status === 'VERIFIED') {
      verifiedAt = new Date().toISOString().replace('T', ' ').slice(0, 19);
    } else if (status === 'WITHDRAWN') {
      withdrawnAt = new Date().toISOString().replace('T', ' ').slice(0, 19);
    }

    await db.prepare(`
      UPDATE guardian_consents
      SET verification_status = ?, notes = ?, verified_by = ?,
          verified_at = COALESCE(?, verified_at), withdrawn_at = COALESCE(?, withdrawn_at)
      WHERE id = ?
    `).bind(status, notes || null, uid, verifiedAt, withdrawnAt, consentId).run();

    return c.json({ success: true, consentId, status });
  });

  // GET /api/admin/legal/cancellation-refund-requests
  app.get('/api/admin/legal/cancellation-refund-requests', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const { results } = await db.prepare(`
      SELECT crr.*, u.email as user_email, u.name as user_name, u.role as user_role
      FROM cancellation_refund_requests crr
      JOIN users u ON crr.user_id = u.id
      ORDER BY crr.created_at DESC
    `).all();

    return c.json({ refundRequests: results || [] });
  });

  // PATCH /api/admin/legal/cancellation-refund-requests/:id
  app.patch('/api/admin/legal/cancellation-refund-requests/:id', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;
    const requestId = c.req.param('id');

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const body = await c.req.json().catch(() => ({}));
    const { status, amountApproved, reviewDecision, resolutionNotes, refundTransactionRef } = body;

    const validStatuses = ['UNDER_REVIEW', 'APPROVED', 'REJECTED', 'PROCESSED'];
    if (!status || !validStatuses.includes(status)) {
      return c.json({ error: 'Invalid status. Must be one of: ' + validStatuses.join(', ') }, 400);
    }

    await db.prepare(`
      UPDATE cancellation_refund_requests
      SET status = ?, amount_approved = COALESCE(?, amount_approved), review_decision = ?,
          resolution_notes = ?, refund_transaction_ref = COALESCE(?, refund_transaction_ref),
          reviewed_by = ?, resolved_at = CURRENT_TIMESTAMP
      WHERE id = ?
    `).bind(status, amountApproved, reviewDecision || null, resolutionNotes || null, refundTransactionRef || null, uid, requestId).run();

    return c.json({ success: true, requestId, status });
  });

  // GET /api/admin/legal/retention-policies
  app.get('/api/admin/legal/retention-policies', async (c) => {
    const uid = c.get('uid');
    const db = c.env.DB;

    const user = await getUser(db, uid);
    if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
      return c.json({ error: 'Forbidden: Admin access required' }, 403);
    }

    const { results } = await db.prepare(`
      SELECT * FROM data_retention_policies ORDER BY data_category ASC
    `).all();

    return c.json({ retentionPolicies: results || [] });
  });
}

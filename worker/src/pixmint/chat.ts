/**
 * PIXMINT BOT 2.0 — Chat Controller & Execution Pipeline
 *
 * Implements:
 * 1. Bot status & operational availability check
 * 2. Role-specific prompt suggestions
 * 3. Session lifecycle (create, list, get, archive) with strict ownership
 * 4. Message pipeline (rate limiting, validation, prompt-injection defense,
 *    grounded retrieval, AI generation, persistence, knowledge gap tracking)
 * 5. User feedback collection (+1 / -1)
 */

import { Context } from 'hono';
import { createAiAdapter } from './ai/adapter';
import { getBotConfig, getDeactivatedSources } from './config';
import { retrieveKnowledge } from './knowledge/retriever';
import {
  checkRateLimit,
  detectPromptInjection,
  validateChatInput,
} from './security';
import type {
  ChatMessageRecord,
  ChatSessionRecord,
  ChatSuggestionRecord,
  PixmintBindings,
  PixmintUser,
  PixmintVariables,
} from './types';

// Default role suggestions fallback catalog
export const DEFAULT_SUGGESTIONS_MAP: Record<string, string[]> = {
  engineer: [
    'How do I review a drawing?',
    'How do I add redline annotations?',
    'What should I check during technical review?',
    'How do I identify drawing issues?',
    'How can I coordinate drawing revisions?',
    'What should I do if a drawing fails to load?',
    'How do I resolve a review problem?',
    'What can PIXMINT BOT help me with?',
  ],
  draughtsman: [
    'How do I view my assignments?',
    'How do I accept an assignment?',
    'How do I upload a drawing?',
    'Which drawing formats are supported?',
    'How do I submit a revised drawing?',
    'How do I resolve redline comments?',
    'What should I do if an upload fails?',
    'How do I check my submission status?',
  ],
  student: [
    'How do I access my training modules?',
    'Where can I find my practical exercises?',
    'How do I submit an exercise?',
    'Where can I view my evaluation?',
    'How do I understand mentor feedback?',
    'How can I verify my certificate?',
    'What should I do if a lesson will not open?',
    'What can PIXMINT BOT help me learn?',
  ],
  admin: [
    'How do I manage approved knowledge sources?',
    'How do I update suggested questions?',
    'How do I check bot service status?',
    'How do I review unanswered questions?',
    'How can I review usage and error metrics?',
    'How do I manage bot availability?',
    'How can I review configuration changes?',
  ],
};

// ============================================================================
// 1. STATUS & SUGGESTIONS
// ============================================================================

export async function handleGetStatus(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const config = await getBotConfig(db);
  const provider = (c.env.AI_PROVIDER || 'local_grounded').toLowerCase();

  return c.json({
    status: config.botEnabled ? (config.maintenanceMode ? 'maintenance' : 'online') : 'disabled',
    botEnabled: config.botEnabled,
    maintenanceMode: config.maintenanceMode,
    maintenanceMessage: config.maintenanceMessage,
    enabledPortals: config.enabledPortals,
    activeProvider: provider,
    version: '2.0.0',
    timestamp: Date.now(),
  });
}

export async function handleGetSuggestions(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const user = c.get('pixmintUser') as PixmintUser;
  const requestedRole = (c.req.query('role') || user.role).toLowerCase();
  const targetRole = user.role === 'admin' ? requestedRole : user.role;

  // 1. Try D1 suggested_questions table first
  try {
    const { results } = await db
      .prepare(
        `SELECT id, role, label, prompt, icon, sort_order, is_active
         FROM suggested_questions
         WHERE role = ? AND is_active = 1
         ORDER BY sort_order ASC`
      )
      .bind(targetRole)
      .all<any>();

    if (results && results.length > 0) {
      const suggestions: ChatSuggestionRecord[] = results.map((r) => ({
        id: r.id,
        role: r.role,
        label: r.label,
        prompt: r.prompt,
        icon: r.icon || 'help_outline',
        sortOrder: r.sort_order,
        isActive: Boolean(r.is_active),
      }));
      return c.json(suggestions);
    }
  } catch (err: any) {
    console.warn('[PIXMINT_SUGGESTIONS] D1 lookup failed; falling back to static:', err.message);
  }

  // 2. Fall back to static default catalog
  const questions = DEFAULT_SUGGESTIONS_MAP[targetRole] || DEFAULT_SUGGESTIONS_MAP.engineer;
  const staticSuggestions: ChatSuggestionRecord[] = questions.map((q, idx) => ({
    id: `sug-${targetRole}-${idx + 1}`,
    role: targetRole as any,
    label: q,
    prompt: q,
    icon: 'help_outline',
    sortOrder: idx,
    isActive: true,
  }));

  return c.json(staticSuggestions);
}

// ============================================================================
// 2. CHAT SESSIONS CRUD & TITLE GENERATION
// ============================================================================

export function generateConversationTitle(userQuery: string): string {
  if (!userQuery || typeof userQuery !== 'string') {
    return 'Untitled Conversation';
  }

  const trimmed = userQuery.trim();
  if (trimmed.length < 3) {
    return 'Untitled Conversation';
  }

  // 1. High-accuracy architectural intent matching
  const lower = trimmed.toLowerCase();
  if (lower.includes('redline') || lower.includes('annotation') || lower.includes('markup') || lower.includes('pin')) {
    if (lower.includes('pin')) return 'Redline Pins Placement';
    return 'Redline Annotations & Markups';
  }
  if (lower.includes('revision') || lower.includes('correction') || lower.includes('round')) {
    return 'Drawing Revision Process';
  }
  if (lower.includes('approval') || lower.includes('qc') || lower.includes('review') || lower.includes('approve')) {
    return 'Drawing Approval & QC Review';
  }
  if (lower.includes('title block') || lower.includes('sheet layout') || lower.includes('border') || lower.includes('template')) {
    return 'Title Blocks & Sheet Layouts';
  }
  if (lower.includes('layer') || lower.includes('cad') || lower.includes('dwg') || lower.includes('line weight')) {
    return 'CAD Layers & Standards';
  }
  if (lower.includes('assignment') || lower.includes('lesson') || lower.includes('curriculum') || lower.includes('chapter')) {
    return 'Curriculum & Assignments';
  }
  if (lower.includes('electrical') || lower.includes('schematic') || lower.includes('symbol')) {
    return 'Electrical Schematics & Symbols';
  }
  if (lower.includes('structural') || lower.includes('beam') || lower.includes('column') || lower.includes('rebar')) {
    return 'Structural Detailing & Specs';
  }
  if (lower.includes('deliverable') || lower.includes('submit') || lower.includes('upload') || lower.includes('drawing')) {
    return 'Drawing Deliverables & Submission';
  }
  if (lower.includes('role') || lower.includes('permission') || lower.includes('access') || lower.includes('portal')) {
    return 'Role Permissions & Access';
  }

  // 2. Generic query cleansing: remove conversational preambles
  let cleaned = trimmed
    .replace(/^(hi|hello|hey|greetings|good\s+(morning|afternoon|evening))\b[,.!?:;\s]*/i, '')
    .replace(/^(can\s+you\s+(please\s+)?(help\s+me(\s+with)?|tell\s+me|explain)|could\s+you|please\s+tell\s+me|please\s+explain|i\s+(want|need)\s+to\s+know|how\s+(do\s+i|can\s+i|to)|what\s+(is|are)|where\s+(is|are|can\s+i\s+find))\b[:\s]*/i, '')
    .replace(/[?!.]+$/g, '')
    .trim();

  if (cleaned.length < 3) {
    cleaned = trimmed.replace(/[?!.]+$/g, '').trim();
  }

  // Capitalize into Title Case
  const words = cleaned.split(/\s+/).filter(Boolean);
  const titleWords = words.slice(0, 6).map((w, idx) => {
    const wLower = w.toLowerCase();
    if (idx > 0 && ['a', 'an', 'the', 'and', 'or', 'for', 'to', 'in', 'on', 'at', 'with', 'by'].includes(wLower)) {
      return wLower;
    }
    return w.charAt(0).toUpperCase() + w.slice(1).toLowerCase();
  });

  const generated = titleWords.join(' ').trim();
  if (!generated || generated.length < 3) {
    return 'Untitled Conversation';
  }

  return generated.length > 50 ? generated.slice(0, 47) + '...' : generated;
}

export async function handleCreateSession(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const user = c.get('pixmintUser') as PixmintUser;
  let title = 'New Conversation';
  let forceNew = false;
  let requestedSessionId: string | undefined;

  try {
    const body = await c.req.json().catch(() => ({}));
    if (body?.title && typeof body.title === 'string' && body.title.trim()) {
      title = body.title.trim().slice(0, 100);
    }
    if (body?.newSession === true || body?.forceNew === true) {
      forceNew = true;
    }
    if (body?.sessionId && typeof body.sessionId === 'string' && body.sessionId.trim()) {
      requestedSessionId = body.sessionId.trim();
    }
  } catch {}

  // 1. If an explicit existing session ID was requested, verify ownership and return it
  if (requestedSessionId) {
    const existing = await db
      .prepare(
        'SELECT id, user_id, user_role, title, is_archived, created_at, updated_at FROM chat_sessions WHERE id = ? AND user_id = ? AND is_archived = 0'
      )
      .bind(requestedSessionId, user.uid)
      .first<any>();
    if (existing) {
      return c.json(
        {
          id: existing.id,
          userId: existing.user_id,
          userRole: existing.user_role,
          title: existing.title,
          isArchived: Boolean(existing.is_archived),
          createdAt: existing.created_at,
          updatedAt: existing.updated_at,
        },
        200
      );
    }
  }

  // 2. Unless explicitly requested to create a fresh new session, check for an existing active unarchived session
  if (!forceNew) {
    const active = await db
      .prepare(
        `SELECT id, user_id, user_role, title, is_archived, created_at, updated_at
         FROM chat_sessions
         WHERE user_id = ? AND is_archived = 0
         ORDER BY updated_at DESC
         LIMIT 1`
      )
      .bind(user.uid)
      .first<any>();

    if (active) {
      return c.json(
        {
          id: active.id,
          userId: active.user_id,
          userRole: active.user_role,
          title: active.title,
          isArchived: Boolean(active.is_archived),
          createdAt: active.created_at,
          updatedAt: active.updated_at,
        },
        200
      );
    }
  }

  const now = Date.now();
  const sessionId = 'sess-' + crypto.randomUUID();

  const session: ChatSessionRecord = {
    id: sessionId,
    userId: user.uid,
    userRole: user.role,
    title,
    isArchived: false,
    createdAt: now,
    updatedAt: now,
  };

  await db
    .prepare(
      `INSERT INTO chat_sessions (id, user_id, user_role, title, is_archived, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
    .bind(
      session.id,
      session.userId,
      session.userRole,
      session.title,
      session.isArchived ? 1 : 0,
      session.createdAt,
      session.updatedAt
    )
    .run();

  return c.json(session, 201);
}

export async function handleListSessions(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const user = c.get('pixmintUser') as PixmintUser;

  const { results } = await db
    .prepare(
      `SELECT id, user_id, user_role, title, is_archived, created_at, updated_at
       FROM chat_sessions
       WHERE user_id = ? AND is_archived = 0
       ORDER BY updated_at DESC
       LIMIT 50`
    )
    .bind(user.uid)
    .all<any>();

  const sessions: ChatSessionRecord[] = (results || []).map((r) => ({
    id: r.id,
    userId: r.user_id,
    userRole: r.user_role,
    title: r.title,
    isArchived: Boolean(r.is_archived),
    createdAt: r.created_at,
    updatedAt: r.updated_at,
  }));

  return c.json(sessions);
}

export async function handleGetMessages(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const user = c.get('pixmintUser') as PixmintUser;
  const sessionId = c.req.param('id');

  if (!sessionId) {
    return c.json({ error: 'Missing sessionId.', code: 'INVALID_SESSION_ID' }, 400);
  }

  // Verify session ownership
  const sessionRow = await db
    .prepare('SELECT id, user_id FROM chat_sessions WHERE id = ?')
    .bind(sessionId)
    .first<{ id: string; user_id: string }>();

  if (!sessionRow || sessionRow.user_id !== user.uid) {
    return c.json({ error: 'Chat session not found.', code: 'SESSION_NOT_FOUND' }, 404);
  }

  const { results } = await db
    .prepare(
      `SELECT id, session_id, user_id, sender, content, sources_json, model_name, latency_ms, created_at
       FROM chat_messages
       WHERE session_id = ?
       ORDER BY created_at ASC`
    )
    .bind(sessionId)
    .all<any>();

  const messages: ChatMessageRecord[] = (results || []).map((r) => ({
    id: r.id,
    sessionId: r.session_id,
    userId: r.user_id,
    sender: r.sender,
    content: r.content,
    sources: r.sources_json ? JSON.parse(r.sources_json) : [],
    modelName: r.model_name || undefined,
    latencyMs: r.latency_ms || undefined,
    createdAt: r.created_at,
  }));

  return c.json(messages);
}

export async function handleArchiveSession(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const user = c.get('pixmintUser') as PixmintUser;
  const sessionId = c.req.param('id');

  if (!sessionId) {
    return c.json({ error: 'Missing sessionId.', code: 'INVALID_SESSION_ID' }, 400);
  }

  const now = Date.now();

  const res = await db
    .prepare(
      `UPDATE chat_sessions
       SET is_archived = 1, updated_at = ?
       WHERE id = ? AND user_id = ?`
    )
    .bind(now, sessionId, user.uid)
    .run();

  if (!res.meta.changes) {
    return c.json({ error: 'Chat session not found.', code: 'SESSION_NOT_FOUND' }, 404);
  }

  return c.json({ success: true, message: 'Session archived successfully.' });
}

// ============================================================================
// 3. MESSAGE PIPELINE & KNOWLEDGE GAP TRIAGE
// ============================================================================

export async function handleSendMessage(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const user = c.get('pixmintUser') as PixmintUser;
  const sessionId = c.req.param('id');

  if (!sessionId) {
    return c.json({ error: 'Missing sessionId.', code: 'INVALID_SESSION_ID' }, 400);
  }

  const startTime = Date.now();

  // 1. Authoritative persistent config check
  const config = await getBotConfig(db);

  if (!config.botEnabled) {
    return c.json(
      {
        error: 'PIXMINT BOT is currently offline or disabled by studio administrator.',
        code: 'BOT_DISABLED',
      },
      503
    );
  }

  if (config.maintenanceMode && !config.allowedMaintenanceRoles.includes(user.role)) {
    return c.json(
      {
        error: config.maintenanceMessage,
        code: 'MAINTENANCE_MODE',
      },
      503
    );
  }

  if (config.enabledPortals && config.enabledPortals[user.role] === false) {
    return c.json(
      {
        error: `PIXMINT BOT is currently disabled for the ${user.role} portal.`,
        code: 'PORTAL_DISABLED',
      },
      503
    );
  }

  // 2. Rate limiting enforcement
  const rateLimitCap = config.rateLimitPerMinute || 30;
  const clientIp =
    c.req.header('cf-connecting-ip') ||
    c.req.header('x-forwarded-for')?.split(',')[0].trim() ||
    '127.0.0.1';
  const rateKey = user.isAnonymous ? `guest:${clientIp}` : `user:${user.uid}`;
  const rateCheck = checkRateLimit(rateKey, rateLimitCap);

  if (!rateCheck.allowed) {
    const resetSec = Math.ceil(rateCheck.resetMs / 1000);
    return c.json(
      {
        error: `Rate limit exceeded (${rateLimitCap} req/min). Please wait ${resetSec}s.`,
        code: 'RATE_LIMIT_EXCEEDED',
        retryAfter: resetSec,
      },
      429
    );
  }

  // 3. Request payload validation
  let rawBody: any;
  try {
    rawBody = await c.req.json();
  } catch {
    return c.json({ error: 'Malformed JSON payload.', code: 'INVALID_JSON' }, 400);
  }

  let userContent: string;
  try {
    userContent = validateChatInput(rawBody?.content, config.maxInputChars);
  } catch (err: any) {
    return c.json({ error: err.message, code: 'INVALID_INPUT' }, 400);
  }

  // 4. Prompt injection protection
  const injectionCheck = detectPromptInjection(userContent);
  if (injectionCheck.isSuspicious) {
    return c.json(
      {
        error: 'I am unable to process this request because it contains restricted prompt patterns or commands.',
        code: 'SAFETY_RESTRICTION',
      },
      400
    );
  }

  // 5. Session ownership verification
  const sessionRow = await db
    .prepare('SELECT id, user_id, user_role, title FROM chat_sessions WHERE id = ?')
    .bind(sessionId)
    .first<{ id: string; user_id: string; user_role: string; title?: string }>();

  if (!sessionRow || sessionRow.user_id !== user.uid) {
    return c.json({ error: 'Chat session not found.', code: 'SESSION_NOT_FOUND' }, 404);
  }

  // 6. Knowledge Retrieval (Role-isolated + Deactivated filter)
  const deactivatedSources = await getDeactivatedSources(db);
  const retrieval = retrieveKnowledge(userContent, user.role, 3, deactivatedSources);

  // 7. Recent conversation history for multi-turn coherence
  const history: Array<{ sender: 'user' | 'bot'; content: string }> = [];
  if (Array.isArray(rawBody?.history)) {
    for (const h of rawBody.history.slice(-config.historyLimit)) {
      if (h && typeof h.content === 'string' && (h.sender === 'user' || h.sender === 'bot')) {
        history.push({ sender: h.sender, content: h.content.slice(0, 500) });
      }
    }
  }

  // 8. AI Generation via active adapter
  const adapter = createAiAdapter(c.env);
  let aiResult;
  try {
    aiResult = await adapter.generateResponse({
      role: user.role,
      query: userContent,
      history,
      retrievedChunks: retrieval.chunks,
      clientContext: rawBody?.clientContext,
    });
  } catch (err: any) {
    console.error('[PIXMINT_AI] Adapter error:', err.message);
    // Graceful fallback to local grounded synthesizer
    const fallbackAdapter = createAiAdapter({ ...c.env, AI_PROVIDER: 'local_grounded' });
    aiResult = await fallbackAdapter.generateResponse({
      role: user.role,
      query: userContent,
      history,
      retrievedChunks: retrieval.chunks,
      clientContext: rawBody?.clientContext,
    });
  }

  const now = Date.now();
  const userMsgId = 'msg-' + crypto.randomUUID();
  const botMsgId = 'msg-' + crypto.randomUUID();

  // 9. Persist user message and bot response
  await db
    .prepare(
      `INSERT INTO chat_messages (id, session_id, user_id, sender, content, sources_json, model_name, latency_ms, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .bind(userMsgId, sessionId, user.uid, 'user', userContent, null, null, null, now)
    .run();

  const sourcesJson = aiResult.sources.length > 0 ? JSON.stringify(aiResult.sources) : null;
  const latencyMs = Date.now() - startTime;

  await db
    .prepare(
      `INSERT INTO chat_messages (id, session_id, user_id, sender, content, sources_json, model_name, latency_ms, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`
    )
    .bind(
      botMsgId,
      sessionId,
      user.uid,
      'bot',
      aiResult.content,
      sourcesJson,
      aiResult.modelName,
      latencyMs,
      now + 1
    )
    .run();

  // Update session updated_at and generate meaningful title if currently default/empty
  const needsTitle =
    !sessionRow.title ||
    sessionRow.title === 'New Conversation' ||
    sessionRow.title === 'Untitled Conversation';

  if (needsTitle) {
    const generatedTitle = generateConversationTitle(userContent);
    await db
      .prepare('UPDATE chat_sessions SET title = ?, updated_at = ? WHERE id = ?')
      .bind(generatedTitle, now + 1, sessionId)
      .run();
  } else {
    await db
      .prepare('UPDATE chat_sessions SET updated_at = ? WHERE id = ?')
      .bind(now + 1, sessionId)
      .run();
  }

  // 10. Record knowledge gap if no relevant chunks found and query is domain-specific
  if (retrieval.chunks.length === 0 && userContent.length > 15) {
    const unansweredId = 'uq-' + crypto.randomUUID();
    db.prepare(
      `INSERT INTO unanswered_questions (id, user_id, user_role, query, intent_category, failure_reason, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)`
    )
      .bind(
        unansweredId,
        user.uid,
        user.role,
        userContent.slice(0, 500),
        'general',
        'no_grounding_chunk_found',
        now
      )
      .run()
      .catch((err) => console.warn('[PIXMINT_UNANSWERED] Failed to log:', err.message));
  }

  const responseRecord: ChatMessageRecord = {
    id: botMsgId,
    sessionId,
    userId: user.uid,
    sender: 'bot',
    content: aiResult.content,
    sources: aiResult.sources,
    modelName: aiResult.modelName,
    latencyMs,
    createdAt: now + 1,
  };

  return c.json(responseRecord, 200);
}

// ============================================================================
// 4. USER FEEDBACK
// ============================================================================

export async function handleSubmitFeedback(c: Context<{ Bindings: PixmintBindings; Variables: PixmintVariables }>) {
  const db = c.env.DB;
  const user = c.get('pixmintUser') as PixmintUser;

  let body: any;
  try {
    body = await c.req.json();
  } catch {
    return c.json({ error: 'Malformed JSON payload.', code: 'INVALID_JSON' }, 400);
  }

  const { messageId, rating, feedbackText } = body;

  if (!messageId || typeof messageId !== 'string') {
    return c.json({ error: 'Missing or invalid messageId.', code: 'INVALID_MESSAGE_ID' }, 400);
  }

  if (rating !== 1 && rating !== -1) {
    return c.json({ error: 'Rating must be either 1 (helpful) or -1 (unhelpful).', code: 'INVALID_RATING' }, 400);
  }

  // Verify message exists
  const msgRow = await db
    .prepare('SELECT id, session_id FROM chat_messages WHERE id = ?')
    .bind(messageId)
    .first<{ id: string; session_id: string }>();

  if (!msgRow) {
    return c.json({ error: 'Target message not found.', code: 'MESSAGE_NOT_FOUND' }, 404);
  }

  const feedbackId = 'fb-' + crypto.randomUUID();
  const sanitizedComment = typeof feedbackText === 'string' ? feedbackText.trim().slice(0, 1000) : null;
  const now = Date.now();

  await db
    .prepare(
      `INSERT INTO user_feedback (id, message_id, user_id, rating, feedback_text, created_at)
       VALUES (?, ?, ?, ?, ?, ?)`
    )
    .bind(feedbackId, messageId, user.uid, rating, sanitizedComment, now)
    .run();

  return c.json({
    success: true,
    feedbackId,
    message: 'Thank you for your feedback.',
  });
}

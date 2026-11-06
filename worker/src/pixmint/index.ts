/**
 * PIXMINT BOT 2.0 — Hono Sub-Router & Route Registration
 *
 * Mounts the complete PIXMINT BOT AI Assistant platform into the ARCHI DRAFT
 * Cloudflare Worker Hono application.
 *
 * Routes provided:
 * Chat:
 *   GET    /api/pixmint/chat/status
 *   GET    /api/pixmint/chat/suggestions
 *   POST   /api/pixmint/chat/sessions
 *   GET    /api/pixmint/chat/sessions
 *   GET    /api/pixmint/chat/sessions/:id/messages
 *   POST   /api/pixmint/chat/sessions/:id/messages
 *   PATCH  /api/pixmint/chat/sessions/:id/archive
 *   POST   /api/pixmint/chat/feedback
 *
 * Administration (Server-side Admin RBAC enforced):
 *   GET    /api/pixmint/admin/health
 *   GET    /api/pixmint/admin/analytics
 *   GET    /api/pixmint/admin/config
 *   POST   /api/pixmint/admin/config
 *   PUT    /api/pixmint/admin/config
 *   GET    /api/pixmint/admin/knowledge/sources
 *   POST   /api/pixmint/admin/knowledge/sources/:id/status
 *   PUT    /api/pixmint/admin/knowledge/sources/:id/status
 *   GET    /api/pixmint/admin/audit-logs
 *   GET    /api/pixmint/admin/unanswered
 *   GET    /api/pixmint/admin/feedback
 *   GET    /api/pixmint/admin/conversations
 *   GET    /api/pixmint/admin/conversations/:id/messages
 */

import { Hono } from 'hono';
import {
  handleAdminAnalytics,
  handleAdminHealth,
  handleCreateSuggestion,
  handleDeleteKnowledgeDocument,
  handleDeleteSuggestion,
  handleGetAdminSuggestions,
  handleGetAuditLogs,
  handleGetConfig,
  handleGetConversationMessages,
  handleGetConversations,
  handleGetFeedback,
  handleGetKnowledgeSources,
  handleGetQuestionAnalytics,
  handleGetUnanswered,
  handleUpdateConfig,
  handleUpdateKnowledgeSourceStatus,
  handleUpdateSuggestion,
  handleUploadKnowledgeDocument,
} from './admin';
import {
  handleArchiveSession,
  handleCreateSession,
  handleGetMessages,
  handleGetStatus,
  handleGetSuggestions,
  handleListSessions,
  handleSendMessage,
  handleSubmitFeedback,
} from './chat';
import { resolvePixmintUser } from './security';
import type { PixmintBindings, PixmintUser, PixmintVariables } from './types';

export const pixmintApp = new Hono<{ Bindings: PixmintBindings; Variables: PixmintVariables }>();

// 1. Identity & Role Resolution Middleware
pixmintApp.use('*', async (c, next) => {
  const uid = c.get('uid');
  if (uid && c.env?.DB) {
    const pixmintUser = await resolvePixmintUser(c.env.DB, uid, c.get('tokenPayload'));
    c.set('pixmintUser', pixmintUser);
  } else {
    // Unauthenticated guest context for public status checks
    c.set('pixmintUser', {
      uid: 'guest',
      role: 'guest',
      isAnonymous: true,
    });
  }
  await next();
});

// 2. Admin RBAC Guard Middleware (Protects all /admin/* endpoints)
pixmintApp.use('/admin/*', async (c, next) => {
  const user = c.get('pixmintUser') as PixmintUser | undefined;

  if (!user || user.role !== 'admin') {
    return c.json(
      {
        error: 'Access Denied: Administrator privileges are required to access this endpoint.',
        code: 'FORBIDDEN',
        userRole: user?.role || 'unauthenticated',
      },
      403
    );
  }

  await next();
});

// ============================================================================
// CHAT ROUTES
// ============================================================================

pixmintApp.get('/chat/status', handleGetStatus);
pixmintApp.get('/chat/suggestions', handleGetSuggestions);
pixmintApp.post('/chat/sessions', handleCreateSession);
pixmintApp.get('/chat/sessions', handleListSessions);
pixmintApp.get('/chat/sessions/:id/messages', handleGetMessages);
pixmintApp.post('/chat/sessions/:id/messages', handleSendMessage);
pixmintApp.patch('/chat/sessions/:id/archive', handleArchiveSession);
pixmintApp.post('/chat/feedback', handleSubmitFeedback);

// ============================================================================
// ADMIN ROUTES
// ============================================================================

pixmintApp.get('/admin/health', handleAdminHealth);
pixmintApp.get('/admin/analytics', handleAdminAnalytics);
pixmintApp.get('/admin/config', handleGetConfig);
pixmintApp.post('/admin/config', handleUpdateConfig);
pixmintApp.put('/admin/config', handleUpdateConfig);
pixmintApp.get('/admin/knowledge/sources', handleGetKnowledgeSources);
pixmintApp.post('/admin/knowledge/sources/:id/status', handleUpdateKnowledgeSourceStatus);
pixmintApp.put('/admin/knowledge/sources/:id/status', handleUpdateKnowledgeSourceStatus);
pixmintApp.post('/admin/knowledge/documents', handleUploadKnowledgeDocument);
pixmintApp.delete('/admin/knowledge/documents/:id', handleDeleteKnowledgeDocument);
pixmintApp.get('/admin/suggestions', handleGetAdminSuggestions);
pixmintApp.post('/admin/suggestions', handleCreateSuggestion);
pixmintApp.put('/admin/suggestions/:id', handleUpdateSuggestion);
pixmintApp.delete('/admin/suggestions/:id', handleDeleteSuggestion);
pixmintApp.get('/admin/audit-logs', handleGetAuditLogs);
pixmintApp.get('/admin/unanswered', handleGetUnanswered);
pixmintApp.get('/admin/feedback', handleGetFeedback);
pixmintApp.get('/admin/conversations', handleGetConversations);
pixmintApp.get('/admin/conversations/:id/messages', handleGetConversationMessages);
pixmintApp.get('/admin/question-analytics', handleGetQuestionAnalytics);

// ============================================================================
// HELPER: Mount routes into the parent ARCHI DRAFT app
// ============================================================================

/**
 * Registers PIXMINT BOT routes directly with the main ARCHI DRAFT Hono application.
 * Mounts primary endpoints at `/api/pixmint` and also registers `/api/chat` aliases
 * for backward compatibility with existing standalone bot clients.
 */
export function registerPixmintRoutes(app: Hono<any>): void {
  // 1. Primary sub-router mount at /api/pixmint
  app.route('/api/pixmint', pixmintApp);

  // 2. Direct /api/chat compatibility aliases for standalone Flutter client
  app.get('/api/chat/status', (c) => handleGetStatus(c));
  app.get('/api/chat/suggestions', async (c) => {
    const uid = c.get('uid');
    if (uid && c.env?.DB) {
      c.set('pixmintUser', await resolvePixmintUser(c.env.DB, uid, c.get('tokenPayload')));
    }
    return handleGetSuggestions(c);
  });
  app.post('/api/chat/sessions', async (c) => {
    const uid = c.get('uid');
    if (uid && c.env?.DB) {
      c.set('pixmintUser', await resolvePixmintUser(c.env.DB, uid, c.get('tokenPayload')));
    }
    return handleCreateSession(c);
  });
  app.get('/api/chat/sessions', async (c) => {
    const uid = c.get('uid');
    if (uid && c.env?.DB) {
      c.set('pixmintUser', await resolvePixmintUser(c.env.DB, uid, c.get('tokenPayload')));
    }
    return handleListSessions(c);
  });
  app.get('/api/chat/sessions/:id/messages', async (c) => {
    const uid = c.get('uid');
    if (uid && c.env?.DB) {
      c.set('pixmintUser', await resolvePixmintUser(c.env.DB, uid, c.get('tokenPayload')));
    }
    return handleGetMessages(c);
  });
  app.post('/api/chat/sessions/:id/messages', async (c) => {
    const uid = c.get('uid');
    if (uid && c.env?.DB) {
      c.set('pixmintUser', await resolvePixmintUser(c.env.DB, uid, c.get('tokenPayload')));
    }
    return handleSendMessage(c);
  });
  app.post('/api/chat/feedback', async (c) => {
    const uid = c.get('uid');
    if (uid && c.env?.DB) {
      c.set('pixmintUser', await resolvePixmintUser(c.env.DB, uid, c.get('tokenPayload')));
    }
    return handleSubmitFeedback(c);
  });
}

export { mapToBotUserRole, detectPromptInjection, checkRateLimit } from './security';
export { retrieveKnowledge } from './knowledge/retriever';
export { getBotConfig, updateBotConfig, recordAuditEvent } from './config';
export { createAiAdapter } from './ai/adapter';


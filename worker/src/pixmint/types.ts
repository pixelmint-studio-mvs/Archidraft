/**
 * PIXMINT BOT 2.0 — Shared Domain Types & Interfaces
 *
 * Provides strongly-typed models for role-aware intelligence, chat sessions,
 * message records, knowledge chunks, persistent bot configuration, audit logs,
 * and AI provider communication within ARCHI DRAFT.
 */

export type BotUserRole = 'engineer' | 'draughtsman' | 'student' | 'admin' | 'guest';

export interface PixmintUser {
  uid: string;
  email?: string;
  role: BotUserRole;
  rawRole?: string;
  isAnonymous?: boolean;
}

export interface ChatSource {
  title: string;
  path: string;
  section?: string;
  category: string;
}

export interface ChatMessageRecord {
  id: string;
  sessionId: string;
  userId: string;
  sender: 'user' | 'bot' | 'system';
  content: string;
  sources?: ChatSource[];
  modelName?: string;
  latencyMs?: number;
  createdAt: number;
}

export interface ChatSessionRecord {
  id: string;
  userId: string;
  userRole: BotUserRole;
  title: string;
  isArchived: boolean;
  createdAt: number;
  updatedAt: number;
}

export interface ChatSuggestionRecord {
  id: string;
  role: BotUserRole;
  label: string;
  prompt: string;
  icon: string;
  sortOrder: number;
  isActive: boolean;
  updatedAt?: number;
}

export interface KnowledgeChunk {
  id: string;
  docId: string;
  path: string;
  title: string;
  category: string;
  sectionTitle: string;
  content: string;
  allowedRoles: BotUserRole[];
  keywords: string[];
  updatedAt?: number;
}

export interface RetrievalResult {
  chunks: KnowledgeChunk[];
  sources: ChatSource[];
  relevanceScores: number[];
}

export interface AiGenerationRequest {
  role: BotUserRole;
  query: string;
  history: Array<{ sender: 'user' | 'bot'; content: string }>;
  retrievedChunks: KnowledgeChunk[];
  clientContext?: Record<string, unknown>;
}

export interface AiGenerationResult {
  content: string;
  sources: ChatSource[];
  modelName: string;
  latencyMs: number;
  tokensUsed?: number;
  providerStatus: 'ok' | 'fallback_local' | 'unconfigured' | 'error';
}

export interface BotConfigRecord {
  botEnabled: boolean;
  maintenanceMode: boolean;
  maintenanceMessage: string;
  allowedMaintenanceRoles: BotUserRole[];
  maxInputChars: number;
  rateLimitPerMinute: number;
  historyLimit: number;
  enabledPortals: Record<BotUserRole, boolean>;
  updatedAt: number;
  updatedBy: string;
}

export const DEFAULT_BOT_CONFIG: BotConfigRecord = {
  botEnabled: true,
  maintenanceMode: false,
  maintenanceMessage: 'PIXMINT BOT is currently undergoing scheduled maintenance. Please check back shortly.',
  allowedMaintenanceRoles: ['admin'],
  maxInputChars: 1000,
  rateLimitPerMinute: 30,
  historyLimit: 10,
  enabledPortals: {
    engineer: true,
    draughtsman: true,
    student: true,
    admin: true,
    guest: true,
  },
  updatedAt: 0,
  updatedBy: 'system',
};

export interface AdminConfigUpdateInput {
  botEnabled?: boolean;
  maintenanceMode?: boolean;
  maintenanceMessage?: string;
  allowedMaintenanceRoles?: BotUserRole[];
  maxInputChars?: number;
  rateLimitPerMinute?: number;
  historyLimit?: number;
  enabledPortals?: Partial<Record<BotUserRole, boolean>>;
}

export interface AuditLogRecord {
  id: string;
  adminUserId: string;
  action: string;
  target?: string;
  metadata?: Record<string, unknown>;
  createdAt: number;
}

export interface KnowledgeSourceRecord {
  id: string;
  title: string;
  path: string;
  category: string;
  version: string;
  status: 'approved' | 'deactivated';
  chunkCount: number;
  lastAuditDate?: string;
  verificationAuthority?: string;
  updatedAt: number;
}

export interface UserFeedbackRecord {
  id: string;
  messageId: string;
  userId: string;
  rating: number; // 1 or -1
  feedbackText?: string;
  createdAt: number;
}

export interface UnansweredQuestionRecord {
  id: string;
  userId: string;
  userRole: BotUserRole;
  query: string;
  intentCategory?: string;
  failureReason: string;
  createdAt: number;
}

export interface PixmintBindings {
  DB: D1Database;
  STORAGE?: R2Bucket;
  ENVIRONMENT?: string;
  ALLOWED_ORIGINS?: string;
  FIREBASE_PROJECT_ID?: string;
  AI?: any; // Cloudflare Workers AI binding
  AI_PROVIDER?: string;
  AI_MODEL_NAME?: string;
  AI_PROVIDER_API_KEY?: string;
  MAX_HISTORY_MESSAGES?: string;
  MAX_INPUT_CHARS?: string;
  RATE_LIMIT_PER_MINUTE?: string;
}

export interface PixmintVariables {
  uid: string;
  tokenPayload?: any;
  pixmintUser?: PixmintUser;
}


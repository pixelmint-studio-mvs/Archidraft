import { auth } from '@/lib/firebase';

async function resolveToken(token?: string): Promise<string | undefined> {
  if (token) return token;
  if (typeof window === 'undefined') return undefined;
  try {
    const user = auth.currentUser;
    if (user) {
      return await user.getIdToken();
    }
  } catch (_) {}
  return undefined;
}
/**
 * PIXMINT BOT Admin Control Center API Client
 *
 * Connects the web administration console to authenticated Cloudflare Worker endpoints.
 */

const DEFAULT_API_BASE = process.env.NEXT_PUBLIC_PIXMINT_API_URL || 'http://127.0.0.1:8788';

export interface AdminHealthData {
  status: string;
  botVersion: string;
  activeProvider: string;
  isProviderConfigured: boolean;
  modelName: string;
  d1Connected: boolean;
  workersAiAvailable: boolean;
  botEnabled?: boolean;
  maintenanceMode?: boolean;
  timestamp: number;
}

export interface AdminAnalyticsData {
  metrics: {
    totalSessionsToday: number;
    totalMessagesToday: number;
    avgLatencyMs: number;
    resolutionRatePercent: number;
    unansweredCountToday: number;
  };
  topQueries: Array<{ query: string; count: number }>;
  recentAuditLogs: Array<{ action: string; target: string; timestamp: number }>;
}

export interface RemoteSuggestion {
  id: string;
  role: string;
  label: string;
  prompt: string;
  icon: string;
  sortOrder: number;
  isActive: boolean;
}

export interface BotConfigData {
  botEnabled: boolean;
  maintenanceMode: boolean;
  maintenanceMessage: string;
  allowedMaintenanceRoles: string[];
  maxInputChars: number;
  rateLimitPerMinute: number;
  historyLimit: number;
  enabledPortals: Record<string, boolean>;
  updatedAt: number;
  updatedBy: string;
}

export interface AuditLogItem {
  id: string;
  adminUserId: string;
  action: string;
  target?: string;
  metadata?: Record<string, unknown>;
  createdAt: number;
}

export interface KnowledgeSourceItem {
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

export interface FeedbackItem {
  id: string;
  messageId: string;
  userId: string;
  rating: number;
  feedbackText?: string;
  createdAt: number;
}

export interface UnansweredItem {
  id: string;
  userId: string;
  userRole: string;
  query: string;
  intentCategory?: string;
  failureReason: string;
  createdAt: number;
}

function getHeaders(token?: string): HeadersInit {
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    Accept: 'application/json',
  };
  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }
  return headers;
}

/**
 * Fetches server health, version, and active AI provider status.
 */
export async function getAdminHealth(
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<AdminHealthData | null> {
  try {
    const res = await fetch(`${baseUrl}/api/admin/health`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    return (await res.json()) as AdminHealthData;
  } catch (err) {
    console.warn('Admin health fetch error (offline fallback):', err);
    return null;
  }
}

/**
 * Fetches bot operational analytics and telemetry.
 */
export async function getAdminAnalytics(
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<AdminAnalyticsData | null> {
  try {
    const res = await fetch(`${baseUrl}/api/admin/analytics`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    return (await res.json()) as AdminAnalyticsData;
  } catch (err) {
    console.warn('Admin analytics fetch error (offline fallback):', err);
    return null;
  }
}

/**
 * Fetches role-specific suggested questions.
 */
export async function getRoleSuggestions(
  role: string,
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<RemoteSuggestion[] | null> {
  try {
    const res = await fetch(`${baseUrl}/api/chat/suggestions?role=${encodeURIComponent(role)}`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    return (await res.json()) as RemoteSuggestion[];
  } catch (err) {
    console.warn('Suggestions fetch error (offline fallback):', err);
    return null;
  }
}

/**
 * Reads persistent bot configuration from Cloudflare Worker + D1.
 */
export async function getAdminConfig(
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<BotConfigData | null> {
  try {
    const res = await fetch(`${baseUrl}/api/admin/config`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as { config: BotConfigData };
    return data.config;
  } catch (err) {
    console.warn('Admin config fetch error:', err);
    return null;
  }
}

/**
 * Persists updated bot configuration to Cloudflare Worker + D1.
 */
export async function updateAdminConfig(
  configUpdates: Partial<BotConfigData>,
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<{ success: boolean; config: BotConfigData } | null> {
  try {
    const res = await fetch(`${baseUrl}/api/admin/config`, {
      method: 'POST',
      headers: getHeaders(await resolveToken(token)),
      body: JSON.stringify(configUpdates),
    });
    if (!res.ok) {
      const errBody = await res.json().catch(() => ({}));
      throw new Error(errBody.error || `HTTP ${res.status}`);
    }
    return (await res.json()) as { success: boolean; config: BotConfigData };
  } catch (err) {
    console.error('Failed to update admin config:', err);
    throw err;
  }
}

/**
 * Fetches server-generated audit logs with pagination and action filtering.
 */
export async function getAuditLogs(
  limit: number = 50,
  offset: number = 0,
  action?: string,
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<{ logs: AuditLogItem[]; total: number } | null> {
  try {
    const params = new URLSearchParams({
      limit: String(limit),
      offset: String(offset),
    });
    if (action) params.set('action', action);

    const res = await fetch(`${baseUrl}/api/admin/audit-logs?${params.toString()}`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    return (await res.json()) as { logs: AuditLogItem[]; total: number };
  } catch (err) {
    console.warn('Audit logs fetch error:', err);
    return null;
  }
}

/**
 * Lists registered knowledge sources with approval status and metadata.
 */
export async function getKnowledgeSources(
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<KnowledgeSourceItem[] | null> {
  try {
    const res = await fetch(`${baseUrl}/api/admin/knowledge/sources`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as { sources: KnowledgeSourceItem[] };
    return data.sources;
  } catch (err) {
    console.warn('Knowledge sources fetch error:', err);
    return null;
  }
}

/**
 * Updates approval/deactivation status of a knowledge source.
 */
export async function updateKnowledgeSourceStatus(
  sourceId: string,
  status: 'approved' | 'deactivated',
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<boolean> {
  try {
    const res = await fetch(
      `${baseUrl}/api/admin/knowledge/sources/${encodeURIComponent(sourceId)}/status`,
      {
        method: 'POST',
        headers: getHeaders(await resolveToken(token)),
        body: JSON.stringify({ status }),
      }
    );
    return res.ok;
  } catch (err) {
    console.error(`Error updating knowledge source ${sourceId}:`, err);
    return false;
  }
}

/**
 * Fetches user feedback from database.
 */
export async function getFeedback(
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<FeedbackItem[] | null> {
  try {
    const res = await fetch(`${baseUrl}/api/admin/feedback`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as { feedback: FeedbackItem[] };
    return data.feedback;
  } catch (err) {
    console.warn('Feedback fetch error:', err);
    return null;
  }
}

/**
 * Fetches unanswered questions triage log from database.
 */
export async function getUnansweredQuestions(
  token?: string,
  baseUrl: string = DEFAULT_API_BASE
): Promise<UnansweredItem[] | null> {
  try {
    const res = await fetch(`${baseUrl}/api/admin/unanswered`, {
      method: 'GET',
      headers: getHeaders(await resolveToken(token)),
    });
    if (!res.ok) return null;
    const data = (await res.json()) as { unanswered: UnansweredItem[] };
    return data.unanswered;
  } catch (err) {
    console.warn('Unanswered questions fetch error:', err);
    return null;
  }
}

/**
 * PIXMINT BOT 2.0 — Persistent Configuration & Audit Management
 *
 * Provides:
 * 1. Persistent bot settings via Cloudflare D1 (UPSERT pattern on `bot_config`)
 * 2. Administrative audit trail recording into `pixmint_audit_logs`
 * 3. Knowledge source approval / deactivation persistence
 */

import { sanitizeAuditMetadata } from './security';
import {
  AdminConfigUpdateInput,
  BotConfigRecord,
  DEFAULT_BOT_CONFIG,
} from './types';

/**
 * Loads persistent bot configuration from Cloudflare D1.
 * Falls back to DEFAULT_BOT_CONFIG if no record exists yet.
 */
export async function getBotConfig(db: D1Database): Promise<BotConfigRecord> {
  try {
    const row = await db
      .prepare('SELECT value_json, updated_at, updated_by FROM bot_config WHERE key = ?')
      .bind('main_config')
      .first<{ value_json: string; updated_at: number; updated_by: string }>();

    if (!row || !row.value_json) {
      return { ...DEFAULT_BOT_CONFIG };
    }

    const parsed = JSON.parse(row.value_json);
    return {
      botEnabled: typeof parsed.botEnabled === 'boolean' ? parsed.botEnabled : DEFAULT_BOT_CONFIG.botEnabled,
      maintenanceMode: typeof parsed.maintenanceMode === 'boolean' ? parsed.maintenanceMode : DEFAULT_BOT_CONFIG.maintenanceMode,
      maintenanceMessage: parsed.maintenanceMessage || DEFAULT_BOT_CONFIG.maintenanceMessage,
      allowedMaintenanceRoles: Array.isArray(parsed.allowedMaintenanceRoles)
        ? parsed.allowedMaintenanceRoles
        : DEFAULT_BOT_CONFIG.allowedMaintenanceRoles,
      maxInputChars: typeof parsed.maxInputChars === 'number' ? parsed.maxInputChars : DEFAULT_BOT_CONFIG.maxInputChars,
      rateLimitPerMinute: typeof parsed.rateLimitPerMinute === 'number' ? parsed.rateLimitPerMinute : DEFAULT_BOT_CONFIG.rateLimitPerMinute,
      historyLimit: typeof parsed.historyLimit === 'number' ? parsed.historyLimit : DEFAULT_BOT_CONFIG.historyLimit,
      enabledPortals: {
        ...DEFAULT_BOT_CONFIG.enabledPortals,
        ...(parsed.enabledPortals || {}),
      },
      updatedAt: row.updated_at || Date.now(),
      updatedBy: row.updated_by || 'system',
    };
  } catch (err: any) {
    console.warn('[PIXMINT_CONFIG] Failed to load config from D1; using defaults:', err.message);
    return { ...DEFAULT_BOT_CONFIG };
  }
}

/**
 * Updates persistent bot configuration in D1 using the UPSERT pattern
 * and records an administrative audit event in `pixmint_audit_logs`.
 */
export async function updateBotConfig(
  db: D1Database,
  updates: AdminConfigUpdateInput,
  adminUserId: string
): Promise<BotConfigRecord> {
  const current = await getBotConfig(db);

  // Validate bounds
  const maxInputChars =
    typeof updates.maxInputChars === 'number'
      ? Math.max(100, Math.min(10000, updates.maxInputChars))
      : current.maxInputChars;

  const rateLimitPerMinute =
    typeof updates.rateLimitPerMinute === 'number'
      ? Math.max(5, Math.min(300, updates.rateLimitPerMinute))
      : current.rateLimitPerMinute;

  const historyLimit =
    typeof updates.historyLimit === 'number'
      ? Math.max(1, Math.min(50, updates.historyLimit))
      : current.historyLimit;

  const updatedConfig: BotConfigRecord = {
    botEnabled: typeof updates.botEnabled === 'boolean' ? updates.botEnabled : current.botEnabled,
    maintenanceMode: typeof updates.maintenanceMode === 'boolean' ? updates.maintenanceMode : current.maintenanceMode,
    maintenanceMessage: updates.maintenanceMessage !== undefined ? updates.maintenanceMessage : current.maintenanceMessage,
    allowedMaintenanceRoles: Array.isArray(updates.allowedMaintenanceRoles)
      ? updates.allowedMaintenanceRoles
      : current.allowedMaintenanceRoles,
    maxInputChars,
    rateLimitPerMinute,
    historyLimit,
    enabledPortals: {
      ...current.enabledPortals,
      ...(updates.enabledPortals || {}),
    },
    updatedAt: Date.now(),
    updatedBy: adminUserId,
  };

  const jsonPayload = JSON.stringify({
    botEnabled: updatedConfig.botEnabled,
    maintenanceMode: updatedConfig.maintenanceMode,
    maintenanceMessage: updatedConfig.maintenanceMessage,
    allowedMaintenanceRoles: updatedConfig.allowedMaintenanceRoles,
    maxInputChars: updatedConfig.maxInputChars,
    rateLimitPerMinute: updatedConfig.rateLimitPerMinute,
    historyLimit: updatedConfig.historyLimit,
    enabledPortals: updatedConfig.enabledPortals,
  });

  await db
    .prepare(
      `INSERT INTO bot_config (key, value_json, updated_at, updated_by)
       VALUES ('main_config', ?, ?, ?)
       ON CONFLICT(key) DO UPDATE SET
         value_json = excluded.value_json,
         updated_at = excluded.updated_at,
         updated_by = excluded.updated_by`
    )
    .bind(jsonPayload, updatedConfig.updatedAt, adminUserId)
    .run();

  await recordAuditEvent(db, adminUserId, 'UPDATE_CONFIG', 'bot_config:main_config', {
    botEnabled: updatedConfig.botEnabled,
    maintenanceMode: updatedConfig.maintenanceMode,
    maxInputChars: updatedConfig.maxInputChars,
    rateLimitPerMinute: updatedConfig.rateLimitPerMinute,
  });

  return updatedConfig;
}

/**
 * Loads the set of administratively deactivated knowledge source IDs from D1.
 */
export async function getDeactivatedSources(db: D1Database): Promise<Set<string>> {
  try {
    const row = await db
      .prepare('SELECT value_json FROM bot_config WHERE key = ?')
      .bind('deactivated_sources')
      .first<{ value_json: string }>();

    if (!row || !row.value_json) {
      return new Set();
    }

    const parsed = JSON.parse(row.value_json);
    if (Array.isArray(parsed)) {
      return new Set(parsed);
    }
    return new Set();
  } catch {
    return new Set();
  }
}

/**
 * Persists an immutable administrative audit event into `pixmint_audit_logs`.
 */
export async function recordAuditEvent(
  db: D1Database,
  adminUserId: string,
  action: string,
  target?: string,
  metadata?: Record<string, unknown>
): Promise<void> {
  const auditId = 'aud-' + crypto.randomUUID();
  const sanitizedJson = sanitizeAuditMetadata(metadata);
  const now = Date.now();

  try {
    await db
      .prepare(
        `INSERT INTO pixmint_audit_logs (id, admin_user_id, action, target, metadata_json, created_at)
         VALUES (?, ?, ?, ?, ?, ?)`
      )
      .bind(auditId, adminUserId, action, target || null, sanitizedJson, now)
      .run();
  } catch (err: any) {
    console.error('[PIXMINT_AUDIT] Failed to insert audit log:', err.message);
  }
}


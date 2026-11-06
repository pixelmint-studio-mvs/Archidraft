/**
 * PIXMINT BOT 2.0 — Security, Authentication & Governance Engine
 *
 * Enforces:
 * 1. Server-derived role mapping (ARCHI DRAFT -> PIXMINT BOT RBAC)
 * 2. Sliding-window rate limiting per-user / per-IP
 * 3. Prompt injection and jailbreak protection
 * 4. Input bounds and sanitization
 * 5. Audit metadata sanitization
 */

import type { BotUserRole, PixmintUser } from './types';

// ============================================================================
// 1. ROLE MAPPING & IDENTITY RESOLUTION
// ============================================================================

/**
 * Maps ARCHI DRAFT platform user roles to PIXMINT BOT user roles.
 * Client-supplied roles and email-based heuristic bypasses are strictly prohibited.
 * Admin access is granted exclusively if the authenticated user possesses an
 * authoritative D1 role of STUDIO_ADMIN or ADMIN.
 */
export function mapToBotUserRole(rawRole?: string): BotUserRole {
  const normalizedRole = (rawRole || '').trim().toUpperCase();

  switch (normalizedRole) {
    case 'STUDIO_ADMIN':
    case 'ADMIN':
      return 'admin';
    case 'ENGINEER':
    case 'CLIENT':
      return 'engineer';
    case 'DRAUGHTSMAN':
      return 'draughtsman';
    case 'STUDENT':
      return 'student';
    default:
      return 'guest';
  }
}

/**
 * Resolves authoritative user identity and role strictly from the D1 users table.
 */
export async function resolvePixmintUser(
  db: D1Database,
  uid: string,
  tokenPayload?: any
): Promise<PixmintUser> {
  const userRow = await db
    .prepare('SELECT id, email, role, status FROM users WHERE id = ?')
    .bind(uid)
    .first<{ id: string; email: string; role: string; status?: string }>();

  const email = userRow?.email || tokenPayload?.email || undefined;
  const rawRole = userRow?.role || undefined;
  const botRole = mapToBotUserRole(rawRole);

  return {
    uid,
    email,
    role: botRole,
    rawRole,
    isAnonymous: !userRow && (!email || tokenPayload?.provider_id === 'anonymous'),
  };
}

// ============================================================================
// 2. SLIDING-WINDOW RATE LIMITER
// ============================================================================

interface RateLimitBucket {
  timestamps: number[];
}

const rateLimitStore = new Map<string, RateLimitBucket>();
const MAX_TRACKED_KEYS = 10000;

function pruneStaleRateLimitBuckets(now: number, windowMs: number): void {
  if (rateLimitStore.size <= MAX_TRACKED_KEYS) return;

  for (const [key, bucket] of rateLimitStore.entries()) {
    bucket.timestamps = bucket.timestamps.filter((ts) => now - ts < windowMs);
    if (bucket.timestamps.length === 0) {
      rateLimitStore.delete(key);
    }
  }
}

/**
 * Enforces a sliding-window rate limit per key (UID or Client IP).
 */
export function checkRateLimit(
  key: string,
  limitPerMinute: number = 30
): { allowed: boolean; remaining: number; resetMs: number } {
  const now = Date.now();
  const windowMs = 60 * 1000;
  const safeLimit = Math.max(1, limitPerMinute || 30);

  pruneStaleRateLimitBuckets(now, windowMs);

  let bucket = rateLimitStore.get(key);
  if (!bucket) {
    bucket = { timestamps: [] };
    rateLimitStore.set(key, bucket);
  }

  bucket.timestamps = bucket.timestamps.filter((ts) => now - ts < windowMs);

  if (bucket.timestamps.length >= safeLimit) {
    const oldest = bucket.timestamps[0] || now;
    const resetMs = Math.max(1000, windowMs - (now - oldest));
    return {
      allowed: false,
      remaining: 0,
      resetMs,
    };
  }

  bucket.timestamps.push(now);
  return {
    allowed: true,
    remaining: safeLimit - bucket.timestamps.length,
    resetMs: windowMs,
  };
}

// ============================================================================
// 3. PROMPT INJECTION & SAFETY CHECKS
// ============================================================================

const PROMPT_INJECTION_PATTERNS = [
  /ignore\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/i,
  /disregard\s+(all\s+)?(previous|prior|above)\s+(instructions|prompts|rules)/i,
  /system\s+prompt\s*(override|leak|reveal|show|display)/i,
  /reveal\s+(your\s+)?(system\s+)?(prompt|instructions|initial\s+prompt)/i,
  /repeat\s+(everything|the\s+text)\s+(above|from\s+the\s+beginning)/i,
  /you\s+are\s+now\s+in\s+developer\s+mode/i,
  /dan\s+mode/i,
  /simulate\s+(an?\s+)?admin(istrator)?/i,
  /grant\s+me\s+admin(istrator)?\s+(access|privileges|role)/i,
  /bypass\s+(safety|security|policy|restrictions)/i,
  /<script\b[^>]*>/i,
  /javascript\s*:\s*/i,
  /union\s+select\s+.*\s+from/i,
];

/**
 * Evaluates whether an incoming query contains known adversarial prompt injection patterns.
 */
export function detectPromptInjection(input: string): { isSuspicious: boolean; reason?: string } {
  const normalized = input.trim();

  for (const pattern of PROMPT_INJECTION_PATTERNS) {
    if (pattern.test(normalized)) {
      return {
        isSuspicious: true,
        reason: 'Input contains prohibited instructions or prompt-override sequences.',
      };
    }
  }

  return { isSuspicious: false };
}

// ============================================================================
// 4. INPUT VALIDATION
// ============================================================================

/**
 * Validates message length and content constraints.
 */
export function validateChatInput(content: unknown, maxChars: number = 1000): string {
  if (typeof content !== 'string' || !content.trim()) {
    throw new Error('Message content must be a non-empty string.');
  }

  const trimmed = content.trim();
  if (trimmed.length > maxChars) {
    throw new Error(`Message exceeds maximum permitted length of ${maxChars} characters.`);
  }

  return trimmed;
}

// ============================================================================
// 5. AUDIT SANITIZATION
// ============================================================================

const SENSITIVE_KEY_PATTERNS = [
  /password/i,
  /secret/i,
  /token/i,
  /api[_-]?key/i,
  /authorization/i,
  /bearer/i,
  /credential/i,
];

/**
 * Sanitizes audit metadata to prevent accidental leakage of secrets or credentials.
 */
export function sanitizeAuditMetadata(metadata?: Record<string, unknown>): string | null {
  if (!metadata || typeof metadata !== 'object') return null;

  try {
    const sanitized: Record<string, unknown> = {};
    for (const [key, value] of Object.entries(metadata)) {
      const isSensitive = SENSITIVE_KEY_PATTERNS.some((p) => p.test(key));
      if (isSensitive) {
        sanitized[key] = '[REDACTED]';
      } else if (typeof value === 'object' && value !== null) {
        sanitized[key] = JSON.parse(sanitizeAuditMetadata(value as Record<string, unknown>) || '{}');
      } else {
        sanitized[key] = value;
      }
    }
    return JSON.stringify(sanitized);
  } catch {
    return null;
  }
}


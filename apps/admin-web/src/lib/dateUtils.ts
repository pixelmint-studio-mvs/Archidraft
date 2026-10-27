/**
 * ARCHI DRAFT Date & Time Utilities
 * Provides authoritative UTC date parsing and formatting for Admin Web.
 *
 * SQLite stores timestamps in UTC as 'YYYY-MM-DD HH:MM:SS' (without 'T' or 'Z').
 * Standard JavaScript new Date('YYYY-MM-DD HH:MM:SS') parses non-ISO strings as
 * local time, introducing substantial timezone offsets (e.g. 5h30m in IST).
 *
 * These utilities ensure every database timestamp is explicitly treated as UTC
 * and formatted into user-local display time without artificial skew.
 */

export function parseUtcDate(dateInput: string | Date | null | undefined): Date | null {
  if (!dateInput) return null;
  if (dateInput instanceof Date) {
    return isNaN(dateInput.getTime()) ? null : dateInput;
  }
  if (typeof dateInput !== 'string') return null;
  const trimmed = dateInput.trim();
  if (!trimmed) return null;

  // 1. If already an ISO string with UTC indicator ('Z') or explicit timezone offset (+/-HH:MM)
  if (trimmed.endsWith('Z') || /[+-]\d{2}:\d{2}$/.test(trimmed)) {
    const d = new Date(trimmed);
    return isNaN(d.getTime()) ? null : d;
  }

  // 2. Handle standard SQLite format 'YYYY-MM-DD HH:MM:SS' or 'YYYY-MM-DDTHH:MM:SS' (with optional ms)
  const sqliteMatch = /^(\d{4}-\d{2}-\d{2})[ T](\d{2}:\d{2}(?::\d{2})?(?:\.\d+)?)$/.exec(trimmed);
  if (sqliteMatch) {
    const normalized = `${sqliteMatch[1]}T${sqliteMatch[2]}Z`;
    const d = new Date(normalized);
    if (!isNaN(d.getTime())) return d;
  }

  // 3. Date-only format 'YYYY-MM-DD'
  if (/^\d{4}-\d{2}-\d{2}$/.test(trimmed)) {
    const d = new Date(`${trimmed}T00:00:00Z`);
    if (!isNaN(d.getTime())) return d;
  }

  // 4. Safe fallback for other standard date formats (without blind 'Z' suffixing on non-dates)
  const fallback = new Date(trimmed);
  return isNaN(fallback.getTime()) ? null : fallback;
}

export function formatRelativeTime(dateInput: string | Date | null | undefined): string {
  const d = parseUtcDate(dateInput);
  if (!d) return '—';

  const diff = Date.now() - d.getTime();
  const s = Math.floor(diff / 1000);
  if (s < 0) return 'just now'; // Minor clock skew tolerance
  if (s < 60) return `${s}s ago`;
  const m = Math.floor(s / 60);
  if (m < 60) return `${m}m ago`;
  const h = Math.floor(m / 60);
  if (h < 24) return `${h}h ago`;
  const days = Math.floor(h / 24);
  if (days < 30) return `${days}d ago`;
  return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric' });
}

export function formatDateTime(dateInput: string | Date | null | undefined, fallback: string = 'N/A'): string {
  const d = parseUtcDate(dateInput);
  if (!d) return fallback;
  return d.toLocaleString();
}

export function formatDate(dateInput: string | Date | null | undefined, fallback: string = 'N/A'): string {
  const d = parseUtcDate(dateInput);
  if (!d) return fallback;
  return d.toLocaleDateString();
}

export function formatTime(dateInput: string | Date | null | undefined, fallback: string = 'N/A'): string {
  const d = parseUtcDate(dateInput);
  if (!d) return fallback;
  return d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
}

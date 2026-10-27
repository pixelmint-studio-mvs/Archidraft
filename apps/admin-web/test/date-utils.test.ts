import { describe, it, before } from 'node:test';
import assert from 'node:assert';

describe('Admin Web Date & Time Utilities (dateUtils.ts)', () => {
  let parseUtcDate: (input: string | Date | null | undefined) => Date | null;
  let formatRelativeTime: (input: string | Date | null | undefined) => string;
  let formatDateTime: (input: string | Date | null | undefined, fallback?: string) => string;
  let formatDate: (input: string | Date | null | undefined, fallback?: string) => string;
  let formatTime: (input: string | Date | null | undefined, fallback?: string) => string;

  before(async () => {
    const mod = await import(new URL('../src/lib/dateUtils.ts', import.meta.url).href);
    parseUtcDate = mod.parseUtcDate;
    formatRelativeTime = mod.formatRelativeTime;
    formatDateTime = mod.formatDateTime;
    formatDate = mod.formatDate;
    formatTime = mod.formatTime;
  });

  it('correctly parses SQLite UTC datetime string "YYYY-MM-DD HH:MM:SS" as UTC', () => {
    const rawSqliteUtc = '2026-10-25 14:30:00';
    const parsed = parseUtcDate(rawSqliteUtc);

    assert.ok(parsed instanceof Date, 'Should return a valid Date object');
    assert.strictEqual(parsed.getUTCFullYear(), 2026);
    assert.strictEqual(parsed.getUTCMonth(), 9); // 0-indexed October
    assert.strictEqual(parsed.getUTCDate(), 25);
    assert.strictEqual(parsed.getUTCHours(), 14);
    assert.strictEqual(parsed.getUTCMinutes(), 30);
    assert.strictEqual(parsed.getUTCSeconds(), 0);
  });

  it('correctly preserves ISO 8601 strings with trailing "Z"', () => {
    const isoString = '2026-10-25T14:30:00Z';
    const parsed = parseUtcDate(isoString);

    assert.ok(parsed instanceof Date);
    assert.strictEqual(parsed.toISOString(), '2026-10-25T14:30:00.000Z');
  });

  it('correctly parses ISO 8601 strings with timezone offsets', () => {
    const offsetString = '2026-10-25T20:00:00+05:30';
    const parsed = parseUtcDate(offsetString);

    assert.ok(parsed instanceof Date);
    // 20:00:00 +05:30 is 14:30:00 UTC
    assert.strictEqual(parsed.getUTCHours(), 14);
    assert.strictEqual(parsed.getUTCMinutes(), 30);
  });

  it('correctly handles date-only string "YYYY-MM-DD" without timezone drift', () => {
    const dateOnly = '2026-10-25';
    const parsed = parseUtcDate(dateOnly);

    assert.ok(parsed instanceof Date);
    assert.strictEqual(parsed.getUTCFullYear(), 2026);
    assert.strictEqual(parsed.getUTCMonth(), 9);
    assert.strictEqual(parsed.getUTCDate(), 25);
  });

  it('safely returns null for null, undefined, empty, or whitespace inputs', () => {
    assert.strictEqual(parseUtcDate(null), null);
    assert.strictEqual(parseUtcDate(undefined), null);
    assert.strictEqual(parseUtcDate(''), null);
    assert.strictEqual(parseUtcDate('   '), null);
  });

  it('safely returns null for malformed or invalid string inputs without crashing', () => {
    assert.strictEqual(parseUtcDate('invalid-timestamp-string'), null);
    assert.strictEqual(parseUtcDate('2026-99-99 99:99:99'), null);
    assert.strictEqual(parseUtcDate('not-a-date'), null);
  });

  it('preserves existing valid Date instances and rejects invalid Date instances', () => {
    const validDate = new Date('2026-10-25T14:30:00Z');
    const invalidDate = new Date('invalid');

    assert.strictEqual(parseUtcDate(validDate)?.getTime(), validDate.getTime());
    assert.strictEqual(parseUtcDate(invalidDate), null);
  });

  it('formats relative time accurately', () => {
    const now = Date.now();

    // 10 seconds ago
    const tenSecAgo = new Date(now - 10 * 1000).toISOString();
    assert.ok(formatRelativeTime(tenSecAgo).includes('s ago'));

    // 5 minutes ago
    const fiveMinAgo = new Date(now - 5 * 60 * 1000).toISOString();
    assert.strictEqual(formatRelativeTime(fiveMinAgo), '5m ago');

    // 3 hours ago
    const threeHoursAgo = new Date(now - 3 * 3600 * 1000).toISOString();
    assert.strictEqual(formatRelativeTime(threeHoursAgo), '3h ago');

    // 2 days ago
    const twoDaysAgo = new Date(now - 2 * 86400 * 1000).toISOString();
    assert.strictEqual(formatRelativeTime(twoDaysAgo), '2d ago');

    // Null/invalid fallback
    assert.strictEqual(formatRelativeTime(null), '—');
    assert.strictEqual(formatRelativeTime('invalid'), '—');
  });

  it('formats dates and times with customizable fallbacks', () => {
    assert.strictEqual(formatDateTime(null, 'No Date'), 'No Date');
    assert.strictEqual(formatDate(null, 'Pending'), 'Pending');
    assert.strictEqual(formatTime(null, '—'), '—');

    const testDate = '2026-10-25 14:30:00';
    assert.ok(formatDateTime(testDate).length > 0);
    assert.ok(formatDate(testDate).length > 0);
    assert.ok(formatTime(testDate).length > 0);
  });
});

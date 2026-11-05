/**
 * Safe, idempotent migration script to allocate permanent role-based identification numbers
 * for existing users (ENG_01, DM_01, ST_01, etc.) who do not have one yet.
 */

export function getRolePrefix(role) {
  const normalized = (role || '').toUpperCase();
  if (normalized === 'ENGINEER' || normalized === 'CLIENT') return 'ENG';
  if (normalized === 'DRAUGHTSMAN') return 'DM';
  if (normalized === 'STUDENT') return 'ST';
  return null;
}

export function formatRoleId(prefix, seq) {
  const padded = seq < 100 ? String(seq).padStart(2, '0') : String(seq);
  return `${prefix}_${padded}`;
}

export async function runUserIdsMigration(db) {
  // 1. Ensure table and indices exist
  try {
    await db.prepare('ALTER TABLE users ADD COLUMN identification_number TEXT').run();
  } catch (e) {
    // Column might already exist
  }

  try {
    await db.prepare('CREATE UNIQUE INDEX IF NOT EXISTS idx_users_identification_number ON users(identification_number)').run();
  } catch (e) {}

  await db.prepare(`
    CREATE TABLE IF NOT EXISTS role_id_sequences (
      role_prefix TEXT PRIMARY KEY,
      last_seq INTEGER NOT NULL DEFAULT 0
    )
  `).run();

  await db.prepare("INSERT OR IGNORE INTO role_id_sequences (role_prefix, last_seq) VALUES ('ENG', 0), ('DM', 0), ('ST', 0)").run();

  const prefixes = [
    { prefix: 'ENG', roles: ['ENGINEER', 'CLIENT'], offset: 5 },
    { prefix: 'DM', roles: ['DRAUGHTSMAN'], offset: 4 },
    { prefix: 'ST', roles: ['STUDENT'], offset: 4 },
  ];

  const results = {};

  for (const { prefix, roles, offset } of prefixes) {
    // Sync current max sequence from existing assigned IDs
    const maxRow = await db.prepare(
      `SELECT COALESCE(MAX(CAST(SUBSTR(identification_number, ${offset}) AS INTEGER)), 0) AS max_seq FROM users WHERE identification_number LIKE '${prefix}_%'`
    ).first();
    const currentMax = Number(maxRow?.max_seq || 0);

    const seqRow = await db.prepare('SELECT last_seq FROM role_id_sequences WHERE role_prefix = ?').bind(prefix).first();
    let currentSeq = Math.max(currentMax, Number(seqRow?.last_seq || 0));

    // Get unallocated users
    const placeholders = roles.map(() => '?').join(',');
    const { results: unallocated } = await db.prepare(
      `SELECT id, role, created_at FROM users WHERE role IN (${placeholders}) AND (identification_number IS NULL OR identification_number = '') ORDER BY created_at ASC, id ASC`
    ).bind(...roles).all();

    let assignedCount = 0;
    for (const u of (unallocated || [])) {
      currentSeq += 1;
      const formatted = formatRoleId(prefix, currentSeq);
      await db.prepare('UPDATE users SET identification_number = ? WHERE id = ?').bind(formatted, u.id).run();
      assignedCount++;
    }

    await db.prepare('UPDATE role_id_sequences SET last_seq = ? WHERE role_prefix = ?').bind(currentSeq, prefix).run();
    results[prefix] = { currentSeq, assignedCount };
  }

  return results;
}


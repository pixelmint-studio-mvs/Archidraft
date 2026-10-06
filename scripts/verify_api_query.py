"""
Read-only: simulates the exact GET /api/assignments query to verify the fixture.
"""
import sqlite3

DB_PATH = (
    r'worker\.wrangler\state\v3\d1\miniflare-D1DatabaseObject'
    r'\a6267e2cecd6b9210b94f3d65bc213a83ce9a931398697b21d7001cfc4379237.sqlite'
)
DRAUGHTSMAN_ID = 'MZiLaSRIJkQ92H5gZi51LjL7sjh2'

db = sqlite3.connect(f'file:{DB_PATH}?mode=ro', uri=True)
db.row_factory = sqlite3.Row
cur = db.cursor()

print('=== SIMULATING GET /api/assignments query ===')
print(f'WHERE draughtsman_id = {DRAUGHTSMAN_ID}')
print()

cur.execute('''
    SELECT
      a.id, a.project_id, a.draughtsman_id, a.status, a.created_at, a.updated_at,
      p.project_name, p.project_address, p.drawing_name, p.drawing_type,
      p.project_area, p.status as project_status, p.correction_round,
      p.submitted_at, p.approved_at, p.assigned_at, p.rejected_at, p.cancelled_at
    FROM assignments a
    LEFT JOIN projects p ON a.project_id = p.id
    WHERE a.draughtsman_id = ?
    ORDER BY a.created_at DESC
''', (DRAUGHTSMAN_ID,))

rows = cur.fetchall()
print(f'Results: {len(rows)} assignment(s) returned')
print()
for r in rows:
    d = dict(r)
    print(f'  Assignment ID:     {d["id"]}')
    print(f'  Project Name:      {d["project_name"]}')
    print(f'  Assignment Status: {d["status"]}')
    print(f'  Project Status:    {d["project_status"]}')
    print(f'  Drawing Type:      {d["drawing_type"]}')
    print(f'  Drawing Name:      {d["drawing_name"]}')
    print(f'  Created At:        {d["created_at"]}')
    print()

db.close()
print('API query simulation: PASSED' if rows else 'API query simulation: NO RESULTS (FAIL)')

"""
DEV-ONLY FIXTURE SCRIPT — Archi Draft
======================================
Creates ONE local test project + ONE pending assignment for manual Draughtsman Portal testing.
Simulates Engineer creating a project, Admin approving it, and Admin assigning it.

This script does NOT modify any application code, endpoints, or business logic.
It only writes to the local Miniflare D1 SQLite file used by `wrangler dev`.

DO NOT run in production. Local dev only.
"""

import sqlite3
import uuid
import sys
from datetime import datetime, timezone

# ── Config ───────────────────────────────────────────────────────────────────
DB_PATH = (
    r'worker\.wrangler\state\v3\d1\miniflare-D1DatabaseObject'
    r'\a6267e2cecd6b9210b94f3d65bc213a83ce9a931398697b21d7001cfc4379237.sqlite'
)

# Existing local Draughtsman account (from DB inspection — DO NOT CHANGE)
DRAUGHTSMAN_ID   = 'MZiLaSRIJkQ92H5gZi51LjL7sjh2'
DRAUGHTSMAN_NAME = 'Draughtsman'
DRAUGHTSMAN_EMAIL = 'mohdanas53n@gmail.com'

# Engineer/Admin who "approved" (using existing ENGINEER user)
ENGINEER_ID = 'lN9u4PPtDfOmnn2kyeFQg6dFeBl1'

# Fixture marker — used for cleanup identification and uniqueness
FIXTURE_MARKER = 'ENGINEER_APPROVAL_TEST_2026'

# ── Connect (read-write for fixture creation only) ────────────────────────────
try:
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    cur = db.cursor()
except Exception as e:
    print(f"ERROR: Could not connect to local D1 database at {DB_PATH}.")
    print(f"Exception: {e}")
    sys.exit(1)

PROJECT_NAME = f'ENGINEER APPROVAL TEST - DRAUGHTSMAN - {FIXTURE_MARKER}'

print("=" * 60)
print("ARCHI DRAFT — DEV FIXTURE CREATOR")
print("=" * 60)

# ── Idempotency Check ─────────────────────────────────────────────────────────
cur.execute("SELECT id, status, current_assignment_id FROM projects WHERE project_name = ?", (PROJECT_NAME,))
existing_project = cur.fetchone()

if existing_project:
    print(f"FIXTURE ALREADY EXISTS:")
    print(f"  Project ID:     {existing_project['id']}")
    print(f"  Project Title:  {PROJECT_NAME}")
    print(f"  Project Status: {existing_project['status']}")
    
    if existing_project['current_assignment_id']:
        cur.execute("SELECT id, status FROM assignments WHERE id = ?", (existing_project['current_assignment_id'],))
        existing_assignment = cur.fetchone()
        if existing_assignment:
            print(f"  Assignment ID:  {existing_assignment['id']}")
            print(f"  Assign Status:  {existing_assignment['status']}")
    
    print("\n[OK] Idempotency Check: Leaving existing fixture intact.")
    db.close()
    sys.exit(0)

# ── Generate IDs ──────────────────────────────────────────────────────────────
PROJECT_ID     = str(uuid.uuid4())
ASSIGNMENT_ID  = str(uuid.uuid4())
APPROVE_ACTION = str(uuid.uuid4())
ASSIGN_ACTION  = str(uuid.uuid4())
ACT_LOG_ID_1   = str(uuid.uuid4())
ACT_LOG_ID_2   = str(uuid.uuid4())
NOW            = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

print(f"Creating New Fixture...")
print(f"Project ID     : {PROJECT_ID}")
print(f"Assignment ID  : {ASSIGNMENT_ID}")
print(f"Draughtsman    : {DRAUGHTSMAN_NAME} ({DRAUGHTSMAN_EMAIL})")
print(f"Draughtsman ID : {DRAUGHTSMAN_ID}")
print(f"Timestamp      : {NOW}")
print()

# ── Verify draughtsman exists ─────────────────────────────────────────────────
cur.execute("SELECT id, name, role FROM users WHERE id = ?", (DRAUGHTSMAN_ID,))
dman = cur.fetchone()
if not dman:
    print("ERROR: Draughtsman user not found in DB. Aborting.")
    db.close()
    sys.exit(1)
if dman['role'] != 'DRAUGHTSMAN':
    print(f"ERROR: User {DRAUGHTSMAN_ID} has role '{dman['role']}', not DRAUGHTSMAN. Aborting.")
    db.close()
    sys.exit(1)
print(f"[OK] Draughtsman user verified: {dman['name']} ({dman['role']})")

# ── Step 1: Create the test project ──────────────────────────────────────────
cur.execute("""
    INSERT INTO projects (
        id, client_id, project_name, project_address, drawing_name, drawing_type,
        project_area, status, draughtsman_id, draughtsman_name, current_assignment_id,
        last_action_id, created_at, submitted_at, approved_at, assigned_at,
        correction_round
    ) VALUES (
        ?, ?, ?, ?, ?, ?,
        ?, 'WAITING_ACCEPTANCE', ?, ?, ?,
        ?, ?, ?, ?, ?,
        0
    )
""", (
    PROJECT_ID,
    ENGINEER_ID,                          # client_id (used as project owner/submitter)
    PROJECT_NAME,
    '123 Approval Ave, Dev City',         # project_address
    'Approval Flow Floor Plan',           # drawing_name
    'FLOOR_PLAN',                         # drawing_type
    '1500',                               # project_area
    DRAUGHTSMAN_ID,                       # draughtsman_id
    DRAUGHTSMAN_NAME,                     # draughtsman_name
    ASSIGNMENT_ID,                        # current_assignment_id
    ASSIGN_ACTION,                        # last_action_id
    NOW,                                  # created_at
    NOW,                                  # submitted_at
    NOW,                                  # approved_at
    NOW,                                  # assigned_at
))
print(f"[OK] Project inserted: '{PROJECT_NAME}'")

# ── Step 2: Create the assignment ─────────────────────────────────────────────
cur.execute("""
    INSERT INTO assignments (id, project_id, draughtsman_id, status, created_at, updated_at)
    VALUES (?, ?, ?, 'PENDING', ?, ?)
""", (
    ASSIGNMENT_ID,
    PROJECT_ID,
    DRAUGHTSMAN_ID,
    NOW,
    NOW,
))
print(f"[OK] Assignment inserted (status=PENDING): {ASSIGNMENT_ID}")

# ── Step 3: Activity logs ─────────────────────────────────────────────────────
# Note: Using 'timestamp' column as per current schema, not 'created_at'
cur.execute("""
    INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details, timestamp)
    VALUES (?, ?, 'PROJECT_APPROVED', ?, 'STUDIO_ADMIN', 'Studio Admin approved the project.', ?)
""", (ACT_LOG_ID_1, PROJECT_ID, ENGINEER_ID, NOW))

cur.execute("""
    INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details, timestamp)
    VALUES (?, ?, 'DRAUGHTSMAN_ASSIGNED', ?, 'STUDIO_ADMIN', ?, ?)
""", (ACT_LOG_ID_2, PROJECT_ID, ENGINEER_ID,
      f'Studio Admin assigned draughtsman: {DRAUGHTSMAN_NAME}', NOW))

print(f"[OK] Activity logs inserted (2 entries)")

# ── Commit ────────────────────────────────────────────────────────────────────
db.commit()
print()
print("=" * 60)
print("DATABASE WRITE COMPLETE")
print("=" * 60)

# ── Step 4: Read-only verification ───────────────────────────────────────────
print()
print("=== VERIFICATION (READ-ONLY) ===")

cur.execute("SELECT id, project_name, status, draughtsman_id, draughtsman_name, current_assignment_id FROM projects WHERE id = ?", (PROJECT_ID,))
p = cur.fetchone()
if p:
    print(f"  Project found:         {p['project_name']}")
    print(f"  Project status:        {p['status']}")
    print(f"  draughtsman_id:        {p['draughtsman_id']}")
    print(f"  draughtsman_name:      {p['draughtsman_name']}")
    print(f"  current_assignment_id: {p['current_assignment_id']}")
    assert p['status'] == 'WAITING_ACCEPTANCE', "FAIL: project status mismatch"
    assert p['draughtsman_id'] == DRAUGHTSMAN_ID, "FAIL: draughtsman_id mismatch"
    assert p['current_assignment_id'] == ASSIGNMENT_ID, "FAIL: current_assignment_id mismatch"
    print("  [OK] Project verification PASSED")
else:
    print("  FAIL: project not found!")

cur.execute("SELECT id, project_id, draughtsman_id, status FROM assignments WHERE id = ?", (ASSIGNMENT_ID,))
a = cur.fetchone()
if a:
    print(f"\n  Assignment found:      {a['id']}")
    print(f"  assignment.project_id: {a['project_id']}")
    print(f"  assignment.draughtsman_id: {a['draughtsman_id']}")
    print(f"  assignment.status:     {a['status']}")
    assert a['project_id'] == PROJECT_ID, "FAIL: project_id mismatch"
    assert a['draughtsman_id'] == DRAUGHTSMAN_ID, "FAIL: draughtsman_id mismatch"
    assert a['status'] == 'PENDING', "FAIL: assignment status mismatch"
    print("  [OK] Assignment verification PASSED")
else:
    print("  FAIL: assignment not found!")

# Verify no OTHER projects were changed
cur.execute("SELECT COUNT(*) as c FROM projects WHERE id != ?", (PROJECT_ID,))
other_count = cur.fetchone()['c']
print(f"\n  Other projects count: {other_count}")

db.close()

print()
print("=" * 60)
print("FIXTURE SUMMARY:")
print(f"  Project ID:      {PROJECT_ID}")
print(f"  Project Title:   {PROJECT_NAME}")
print(f"  Assignment ID:   {ASSIGNMENT_ID}")
print(f"  Assignment Status: PENDING")
print(f"  Project Status:  WAITING_ACCEPTANCE")
print(f"  Draughtsman:     {DRAUGHTSMAN_EMAIL} (ID: {DRAUGHTSMAN_ID})")
print("=" * 60)
print("IMPORTANT: The Miniflare D1 Database updates instantly.")
print("Restart wrangler dev if UI doesn't refresh automatically.")

"""
DEV-ONLY FIXTURE SCRIPT — Archi Draft
======================================
Creates ONE local test project + ONE pending assignment for Draughtsman Correction Rounds 2-3.
Simulates a project that has already completed V1 -> Correction R1 -> V2 -> Resubmission of V2.
It leaves the project in UNDER_CLIENT_REVIEW with correction_round = 1.

DO NOT run in production. Local dev only.
"""

import sqlite3
import uuid
import sys
from datetime import datetime, timezone

DB_PATH = (
    r'worker\.wrangler\state\v3\d1\miniflare-D1DatabaseObject'
    r'\a6267e2cecd6b9210b94f3d65bc213a83ce9a931398697b21d7001cfc4379237.sqlite'
)

# Existing local Draughtsman account (from DB inspection)
DRAUGHTSMAN_ID   = 'MZiLaSRIJkQ92H5gZi51LjL7sjh2'
DRAUGHTSMAN_NAME = 'Draughtsman'
DRAUGHTSMAN_EMAIL = 'mohdanas53n@gmail.com'

# Engineer/Admin who "approved"
ENGINEER_ID = 'lN9u4PPtDfOmnn2kyeFQg6dFeBl1'

FIXTURE_MARKER = 'CORRECTION_ROUNDS_2026'

try:
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    cur = db.cursor()
except Exception as e:
    print(f"ERROR: Could not connect to local D1 database at {DB_PATH}.")
    print(f"Exception: {e}")
    sys.exit(1)

PROJECT_NAME = f'DRAUGHTSMAN CORRECTION ROUNDS 2-3 TEST - {FIXTURE_MARKER}'

print("=" * 60)
print("ARCHI DRAFT — DEV FIXTURE CREATOR (ROUNDS 2-3)")
print("=" * 60)

cur.execute("SELECT id FROM projects WHERE project_name = ?", (PROJECT_NAME,))
if cur.fetchone():
    print(f"FIXTURE ALREADY EXISTS: {PROJECT_NAME}")
    print("[OK] Idempotency Check: Leaving existing fixture intact.")
    db.close()
    sys.exit(0)

PROJECT_ID     = str(uuid.uuid4())
ASSIGNMENT_ID  = str(uuid.uuid4())
NOW            = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

# Create the project in UNDER_CLIENT_REVIEW state with correction_round = 1
cur.execute("""
    INSERT INTO projects (
        id, client_id, project_name, project_address, drawing_name, drawing_type,
        project_area, status, draughtsman_id, draughtsman_name, current_assignment_id,
        last_action_id, created_at, submitted_at, approved_at, assigned_at,
        correction_round
    ) VALUES (?, ?, ?, ?, ?, ?, ?, 'UNDER_CLIENT_REVIEW', ?, ?, ?, ?, ?, ?, ?, ?, 1)
""", (
    PROJECT_ID, ENGINEER_ID, PROJECT_NAME, '456 Revision Rd', 'Rounds Testing Plan', 'FLOOR_PLAN',
    '2000', DRAUGHTSMAN_ID, DRAUGHTSMAN_NAME, ASSIGNMENT_ID, str(uuid.uuid4()),
    NOW, NOW, NOW, NOW
))

# Create the assignment as ACCEPTED
cur.execute("""
    INSERT INTO assignments (id, project_id, draughtsman_id, status, created_at, updated_at)
    VALUES (?, ?, ?, 'ACCEPTED', ?, ?)
""", (ASSIGNMENT_ID, PROJECT_ID, DRAUGHTSMAN_ID, NOW, NOW))

# Create Files
F1_ID = str(uuid.uuid4())
F2_ID = str(uuid.uuid4())
cur.execute("""
    INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status, created_at)
    VALUES 
    (?, ?, ?, 'v1_file.pdf', 'v1_file.pdf', 'path/v1', 'application/pdf', 1000, 'draughtsman_version', 'COMPLETED', ?),
    (?, ?, ?, 'v2_file.pdf', 'v2_file.pdf', 'path/v2', 'application/pdf', 1000, 'draughtsman_version', 'COMPLETED', ?)
""", (F1_ID, PROJECT_ID, DRAUGHTSMAN_ID, NOW, F2_ID, PROJECT_ID, DRAUGHTSMAN_ID, NOW))

# Create Versions V1 and V2
V1_ID = str(uuid.uuid4())
V2_ID = str(uuid.uuid4())
cur.execute("""
    INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by)
    VALUES (?, ?, ?, 1, ?)
""", (V1_ID, PROJECT_ID, F1_ID, DRAUGHTSMAN_ID))

# Create Correction 1 (Resolved)
C1_ID = str(uuid.uuid4())
cur.execute("""
    INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status)
    VALUES (?, ?, ?, ?, 1, 'Fix dimensions', 'RESOLVED')
""", (C1_ID, PROJECT_ID, ENGINEER_ID, V1_ID))

cur.execute("""
    INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by, correction_id)
    VALUES (?, ?, ?, 2, ?, ?)
""", (V2_ID, PROJECT_ID, F2_ID, DRAUGHTSMAN_ID, C1_ID))

db.commit()
db.close()
print("[OK] Fixture Created Successfully")

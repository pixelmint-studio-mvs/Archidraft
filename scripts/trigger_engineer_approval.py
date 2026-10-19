"""
DEV-ONLY SCRIPT — Archi Draft
======================================
Simulates an Engineer reviewing a submitted drawing and clicking "Approve Final".
This script finds the most recently submitted project (in UNDER_CLIENT_REVIEW state),
verifies it has a drawing version, and performs the EXACT state transition
implemented by the /api/projects/approve-final API endpoint.

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

# Engineer who approves the drawing
ENGINEER_ID = 'lN9u4PPtDfOmnn2kyeFQg6dFeBl1'

try:
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    cur = db.cursor()
except Exception as e:
    print(f"ERROR: Could not connect to local D1 database at {DB_PATH}.")
    print(f"Exception: {e}")
    sys.exit(1)

print("=" * 60)
print("ARCHI DRAFT — TRIGGER ENGINEER APPROVAL (LOCAL DEV)")
print("=" * 60)

# Find the most recently submitted project
cur.execute("""
    SELECT id, project_name, status
    FROM projects
    WHERE status = 'UNDER_CLIENT_REVIEW'
    ORDER BY submitted_at DESC LIMIT 1
""")
project = cur.fetchone()

if not project:
    print("No projects found in 'UNDER_CLIENT_REVIEW' state.")
    print("Please use the Draughtsman Portal to submit a drawing first.")
    db.close()
    sys.exit(0)

PROJECT_ID = project['id']
print(f"Found Project: {project['project_name']} (ID: {PROJECT_ID})")

# Verify there is a latest submitted drawing version
cur.execute("""
    SELECT id, version_number
    FROM drawing_versions
    WHERE project_id = ?
    ORDER BY version_number DESC LIMIT 1
""", (PROJECT_ID,))
latest_version = cur.fetchone()

if not latest_version:
    print("ERROR: Project has no drawing versions. Cannot approve.")
    db.close()
    sys.exit(1)

print(f"Found Latest Drawing Version: {latest_version['version_number']} (ID: {latest_version['id']})")

action_id = str(uuid.uuid4())
now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')

# Perform the exact state transition used by /api/projects/approve-final
# 1. Update project status to COMPLETED and set last_action_id
cur.execute("""
    UPDATE projects 
    SET status = 'COMPLETED', last_action_id = ? 
    WHERE id = ?
""", (action_id, PROJECT_ID))

# 2. Insert the PROJECT_COMPLETED activity log
cur.execute("""
    INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details, timestamp) 
    VALUES (?, ?, 'PROJECT_COMPLETED', ?, 'ENGINEER', 'Engineer approved the final drawing.', ?)
""", (action_id, PROJECT_ID, ENGINEER_ID, now))

db.commit()
db.close()

print(f"\n[SUCCESS] Engineer Final Approval simulated successfully!")
print("The project status is now 'COMPLETED'.")
print("Check the Draughtsman Portal to verify the completed state and timeline.")

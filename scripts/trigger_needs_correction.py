"""
DEV-ONLY SCRIPT — Archi Draft
======================================
Simulates an Engineer/Client reviewing a submitted drawing and clicking "Needs Correction".
This script finds the most recently submitted project (in UNDER_CLIENT_REVIEW state),
and injects a new Correction round into the local D1 database.

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

# Engineer who "requests" the correction
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
print("ARCHI DRAFT — TRIGGER NEEDS CORRECTION (LOCAL DEV)")
print("=" * 60)

# Find the most recently submitted project
cur.execute("""
    SELECT id, project_name, client_id, draughtsman_id, correction_round
    FROM projects
    WHERE status = 'UNDER_CLIENT_REVIEW'
    ORDER BY submitted_at DESC LIMIT 1
""")
project = cur.fetchone()

if not project:
    print("No projects found in 'UNDER_CLIENT_REVIEW' state.")
    print("Please use the Draughtsman Portal to upload and submit a drawing first.")
    db.close()
    sys.exit(0)

PROJECT_ID = project['id']
print(f"Found Project: {project['project_name']} (ID: {PROJECT_ID})")

# Find the latest drawing version for this project
cur.execute("""
    SELECT id, version_number
    FROM drawing_versions
    WHERE project_id = ?
    ORDER BY version_number DESC LIMIT 1
""", (PROJECT_ID,))
latest_version = cur.fetchone()

if not latest_version:
    print("ERROR: Project has no drawing versions. Cannot request correction.")
    db.close()
    sys.exit(1)

TARGET_VERSION_ID = latest_version['id']
VERSION_NUM = latest_version['version_number']
print(f"Targeting Version: {VERSION_NUM} (ID: {TARGET_VERSION_ID})")

# Check existing correction rounds
current_round = project['correction_round'] or 0
if current_round >= 3:
    print("ERROR: Project has already reached maximum correction rounds (3).")
    db.close()
    sys.exit(1)

next_round = current_round + 1
correction_id = str(uuid.uuid4())
action_id = str(uuid.uuid4())
now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')
description = f"Engineer review feedback for round {next_round}: Please revise the layout based on the updated structural requirements."

# Insert the correction
cur.execute("""
    INSERT INTO corrections (id, project_id, requested_by, target_version_id, round_number, description, status)
    VALUES (?, ?, ?, ?, ?, ?, 'OPEN')
""", (correction_id, PROJECT_ID, ENGINEER_ID, TARGET_VERSION_ID, next_round, description))

# Update project status
cur.execute("""
    UPDATE projects
    SET status = 'IN_PROGRESS', correction_round = ?, last_action_id = ?
    WHERE id = ?
""", (next_round, action_id, PROJECT_ID))

# Log the activity
cur.execute("""
    INSERT INTO activity_logs (id, project_id, action_type, actor_id, actor_role, details, timestamp)
    VALUES (?, ?, 'CORRECTION_REQUESTED', ?, 'ENGINEER', ?, ?)
""", (action_id, PROJECT_ID, ENGINEER_ID, f"Engineer requested correction (Round {next_round}).", now))

db.commit()
db.close()

print(f"\n[SUCCESS] Correction Round {next_round} created!")
print("The project is now back in 'IN_PROGRESS' (Corrections state).")
print("Open the Draughtsman Portal workspace to view and accept the correction.")

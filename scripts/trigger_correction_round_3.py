"""
DEV-ONLY SCRIPT — Archi Draft
======================================
Simulates an Engineer/Client reviewing a submitted drawing and clicking "Needs Correction" for ROUND 3.
This script specifically targets the "DRAUGHTSMAN CORRECTION ROUNDS 2-3 TEST" fixture.
It leaves the project in IN_PROGRESS state for the Draughtsman.

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

ENGINEER_ID = 'lN9u4PPtDfOmnn2kyeFQg6dFeBl1'
TARGET_PROJECT_NAME = 'DRAUGHTSMAN CORRECTION ROUNDS 2-3 TEST - CORRECTION_ROUNDS_2026'

try:
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    cur = db.cursor()
except Exception as e:
    print(f"ERROR: Could not connect to local D1 database at {DB_PATH}.")
    sys.exit(1)

print("=" * 60)
print("ARCHI DRAFT — TRIGGER CORRECTION ROUND 3 (LOCAL DEV)")
print("=" * 60)

cur.execute("""
    SELECT id, project_name, client_id, draughtsman_id, correction_round, status
    FROM projects
    WHERE project_name = ?
""", (TARGET_PROJECT_NAME,))
project = cur.fetchone()

if not project:
    print(f"ERROR: Target project '{TARGET_PROJECT_NAME}' not found.")
    sys.exit(1)

if project['status'] != 'UNDER_CLIENT_REVIEW':
    print(f"ERROR: Project is in '{project['status']}' state, expected UNDER_CLIENT_REVIEW.")
    sys.exit(1)

PROJECT_ID = project['id']
print(f"Found Project: {project['project_name']} (ID: {PROJECT_ID})")

cur.execute("""
    SELECT id, version_number
    FROM drawing_versions
    WHERE project_id = ?
    ORDER BY version_number DESC LIMIT 1
""", (PROJECT_ID,))
latest_version = cur.fetchone()

if not latest_version or latest_version['version_number'] != 3:
    print(f"ERROR: Expected V3 as the latest version, but found: {latest_version['version_number'] if latest_version else 'None'}")
    sys.exit(1)

TARGET_VERSION_ID = latest_version['id']
print(f"Targeting Version: {latest_version['version_number']} (ID: {TARGET_VERSION_ID})")

current_round = project['correction_round']
if current_round != 2:
    print(f"ERROR: Expected project to be at correction round 2, but it is at round {current_round}.")
    sys.exit(1)

next_round = current_round + 1
correction_id = str(uuid.uuid4())
action_id = str(uuid.uuid4())
now = datetime.now(timezone.utc).strftime('%Y-%m-%d %H:%M:%S')
description = f"Engineer review feedback for round {next_round}: Please make the final tweaks requested (Round 3)."

# Check if round 3 already exists to enforce idempotency strictly
cur.execute("""
    SELECT id FROM corrections 
    WHERE project_id = ? AND round_number = ?
""", (PROJECT_ID, next_round))
if cur.fetchone():
    print(f"ERROR: Correction round {next_round} already exists for this project. Aborting to maintain idempotency.")
    db.close()
    sys.exit(0)

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
    VALUES (?, ?, 'CORRECTION_REQUESTED', ?, 'CLIENT', ?, ?)
""", (action_id, PROJECT_ID, ENGINEER_ID, f'Client requested correction (Round {next_round}).', now))

db.commit()
db.close()

print(f"\n[SUCCESS] Correction Round {next_round} Triggered successfully!")
print("The project status is now 'IN_PROGRESS'.")
print("Check the Draughtsman Portal Workspace to view the Round 3 correction.")

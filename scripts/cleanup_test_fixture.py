"""
DEV-ONLY CLEANUP SCRIPT — Archi Draft Test Fixture
====================================================
Removes ONLY the specific test fixture records created by create_test_fixture.py.
Will NOT delete any other projects, assignments, or users.

Usage:
  python scripts/cleanup_test_fixture.py --project-id <pid> --assignment-id <aid>

Safety:
  - Only deletes records matching the exact IDs provided
  - Verifies the project name contains 'TEST_FIXTURE_2026' before deleting
  - Does NOT execute unless --confirm flag is also passed
"""

import argparse
import sqlite3

DB_PATH = (
    r'worker\.wrangler\state\v3\d1\miniflare-D1DatabaseObject'
    r'\a6267e2cecd6b9210b94f3d65bc213a83ce9a931398697b21d7001cfc4379237.sqlite'
)
FIXTURE_MARKER = 'TEST_FIXTURE_2026'

parser = argparse.ArgumentParser(description='Remove Archi Draft test fixture records')
parser.add_argument('--project-id', required=True, help='Project ID to delete')
parser.add_argument('--assignment-id', required=True, help='Assignment ID to delete')
parser.add_argument('--confirm', action='store_true', help='Required: actually execute the deletion')
args = parser.parse_args()

db = sqlite3.connect(DB_PATH)
db.row_factory = sqlite3.Row
cur = db.cursor()

# Safety check: verify the project is a test fixture
cur.execute("SELECT id, project_name, status FROM projects WHERE id = ?", (args.project_id,))
p = cur.fetchone()
if not p:
    print(f"Project {args.project_id} not found. Nothing to delete.")
    db.close()
    exit(0)

if FIXTURE_MARKER not in p['project_name']:
    print(f"SAFETY ABORT: Project '{p['project_name']}' does not contain '{FIXTURE_MARKER}'.")
    print("This script only deletes test fixture records. Aborting.")
    db.close()
    exit(1)

print(f"Found test project: '{p['project_name']}' (status={p['status']})")

# Verify assignment
cur.execute("SELECT id, status FROM assignments WHERE id = ?", (args.assignment_id,))
a = cur.fetchone()
if a:
    print(f"Found test assignment: {a['id']} (status={a['status']})")

if not args.confirm:
    print()
    print("DRY RUN — nothing deleted. Add --confirm to actually delete.")
    print(f"Would delete:")
    print(f"  projects WHERE id = '{args.project_id}'")
    print(f"  assignments WHERE id = '{args.assignment_id}'")
    print(f"  activity_logs WHERE project_id = '{args.project_id}'")
    db.close()
    exit(0)

# Execute deletion (only with --confirm)
cur.execute("DELETE FROM activity_logs WHERE project_id = ?", (args.project_id,))
cur.execute("DELETE FROM assignments WHERE id = ?", (args.assignment_id,))
cur.execute("DELETE FROM projects WHERE id = ?", (args.project_id,))
db.commit()

print("Cleanup complete.")
print(f"  Deleted project:      {args.project_id}")
print(f"  Deleted assignment:   {args.assignment_id}")
print(f"  Deleted activity logs for project {args.project_id}")

db.close()

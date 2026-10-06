"""
Read-only inspection script for the local D1 SQLite database.
Inspects schema and existing data without making any changes.
"""
import sqlite3
import json

DB_PATH = r'worker\.wrangler\state\v3\d1\miniflare-D1DatabaseObject\a6267e2cecd6b9210b94f3d65bc213a83ce9a931398697b21d7001cfc4379237.sqlite'

db = sqlite3.connect(f'file:{DB_PATH}?mode=ro', uri=True)
db.row_factory = sqlite3.Row
cur = db.cursor()

# Tables
cur.execute("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
tables = [r[0] for r in cur.fetchall()]
print("=== TABLES ===")
print(tables)

# Schema for key tables
for table in ['users', 'projects', 'assignments', 'activity_logs', 'notifications']:
    if table in tables:
        cur.execute(f"PRAGMA table_info({table})")
        cols = cur.fetchall()
        print(f"\n=== SCHEMA: {table} ===")
        for c in cols:
            print(f"  {c['name']} {c['type']} {'NOT NULL' if c['notnull'] else ''} {'DEFAULT '+str(c['dflt_value']) if c['dflt_value'] else ''}")

# Existing users (DRAUGHTSMAN role)
print("\n=== DRAUGHTSMAN USERS ===")
cur.execute("SELECT id, name, email, role, created_at FROM users WHERE role = 'DRAUGHTSMAN'")
rows = cur.fetchall()
for r in rows:
    print(dict(r))

# All users
print("\n=== ALL USERS ===")
cur.execute("SELECT id, name, email, role FROM users")
for r in cur.fetchall():
    print(dict(r))

# Existing projects
print("\n=== ALL PROJECTS ===")
cur.execute("SELECT id, project_name, status, draughtsman_id, current_assignment_id, created_at FROM projects ORDER BY created_at DESC LIMIT 10")
for r in cur.fetchall():
    print(dict(r))

# Existing assignments
print("\n=== ALL ASSIGNMENTS ===")
cur.execute("SELECT * FROM assignments ORDER BY created_at DESC LIMIT 10")
for r in cur.fetchall():
    print(dict(r))

db.close()

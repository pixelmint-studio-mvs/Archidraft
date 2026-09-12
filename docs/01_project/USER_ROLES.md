# USER ROLES

ARCHI DRAFT enforces strict Role-Based Access Control (RBAC). 

## 1. CLIENT
The Client is the project owner.

**Can:**
- Register and Login
- Create projects
- Save drafts
- Submit projects
- Upload client reference files
- View assigned project progress
- Review submitted drawings
- Request corrections (Max 3)
- Approve final drawings
- Cancel eligible projects (in DRAFT or SUBMITTED state)
- View activity logs for their projects

**Cannot:**
- Assign Draughtsmen
- Modify another user's projects
- Modify user roles
- Access other clients' projects or files

## 2. DRAUGHTSMAN
The Draughtsman is the professional executing the work.

**Can:**
- Register and Login
- Complete their profile
- View pending assignments directed to them
- Accept assignments
- Reject assignments
- View assigned project details
- View authorized project reference files
- Upload drawing versions
- Submit completed drawings
- Resolve assigned corrections
- View completed assigned projects (historical access)

**Cannot:**
- Access unassigned projects
- Access projects if their assignment was REJECTED or REPLACED
- Modify client personal information
- Assign themselves to projects
- Modify project ownership
- Modify user roles

## 3. ADMIN
The Admin manages the entire platform. Admin authority must remain backend-controlled (e.g., via a Cloudflare D1 `admins` registry or specific unmodifiable User role).

**Can:**
- Review submitted projects
- Approve projects
- Reject projects
- Assign Draughtsmen to approved projects
- Monitor assignment statuses
- Monitor all projects
- Manage authorized users
- View system-wide activity logs

**Cannot:**
- Normal users can never promote themselves or others to Admin. Admin provisioning is strictly controlled.

import { DatabaseSync } from 'node:sqlite';
import path from 'node:path';

const dbPath = path.resolve('worker/.wrangler/state/v3/d1/miniflare-D1DatabaseObject/fdc94e68165493d9beefe9c542c3ccf242c09e8c388eef5ade0878b760405048.sqlite');
const db = new DatabaseSync(dbPath);

console.log('--- 1. FOREIGN KEY CHECK ---');
const fkCheck = db.prepare('PRAGMA foreign_key_check').all();
console.log('FK Violations:', fkCheck.length);

console.log('\n--- 2. USERS BY ROLE ---');
const usersByRole = db.prepare('SELECT role, count(*) as count FROM users GROUP BY role').all();
console.log(usersByRole);

console.log('\n--- 3. PROJECTS BY STATUS ---');
const prjByStatus = db.prepare('SELECT status, count(*) as count FROM projects GROUP BY status').all();
console.log(prjByStatus);

console.log('\n--- 4. DASHBOARD AGGREGATION QUERY ---');
const batchQueries = [
  'SELECT COUNT(*) as c FROM projects',
  "SELECT COUNT(*) as c FROM projects WHERE status IN ('IN_PROGRESS', 'WAITING_ACCEPTANCE', 'UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')",
  "SELECT COUNT(*) as c FROM projects WHERE status = 'WAITING_ASSIGNMENT'",
  "SELECT COUNT(*) as c FROM projects WHERE status IN ('UNDER_ENGINEER_REVIEW', 'UNDER_CLIENT_REVIEW')",
  "SELECT COUNT(*) as c FROM projects WHERE status = 'COMPLETED'",
  "SELECT COUNT(*) as c FROM users WHERE role = 'DRAUGHTSMAN'",
  "SELECT COUNT(*) as c FROM assignments WHERE status = 'PENDING'",
  "SELECT COUNT(DISTINCT id) as c FROM users WHERE role IN ('ENGINEER', 'CLIENT')"
];

const results = batchQueries.map(q => db.prepare(q).get());
console.log({
  totalProjects: results[0].c,
  activeProjects: results[1].c,
  projectsAwaitingAssignment: results[2].c,
  projectsUnderClientReview: results[3].c,
  completedProjects: results[4].c,
  activeDraughtsmen: results[5].c,
  pendingAssignments: results[6].c,
  registeredEngineers: results[7].c,
});

console.log('\n--- 5. ADMIN WEB CARD EXPRESSIONS ---');
const statusMap = {};
prjByStatus.forEach(r => { statusMap[r.status] = r.count; });
const draftCount = statusMap['DRAFT'] || 0;
const submittedCount = statusMap['SUBMITTED'] || 0;
const waitingAssignmentCount = statusMap['WAITING_ASSIGNMENT'] || 0;
const waitingAcceptanceCount = statusMap['WAITING_ACCEPTANCE'] || 0;
const inProgressCount = statusMap['IN_PROGRESS'] || 0;
const adminReviewCount = statusMap['UNDER_ADMIN_REVIEW'] || 0;
const engineerReviewCount = (statusMap['UNDER_CLIENT_REVIEW'] || 0) + (statusMap['UNDER_ENGINEER_REVIEW'] || 0);
const completedCount = statusMap['COMPLETED'] || 0;
const cancelledCount = statusMap['CANCELLED'] || 0;

console.log('Cards Output:');
console.log('- Total projects:', results[0].c);
console.log('- Completed projects:', completedCount);
console.log('- Cancelled projects:', cancelledCount);
console.log('- Requires review (pending admin review):', submittedCount);
console.log('- Needs draughtsman (waiting assignment):', waitingAssignmentCount);
console.log('- Active in drafting (inProgress + waitingAcceptance):', inProgressCount + waitingAcceptanceCount);
console.log('- Registered Engineers:', results[7].c);
console.log('- Certified Draughtsmen:', results[5].c);
console.log('- Enrolled Students:', db.prepare("SELECT count(*) as c FROM users WHERE role = 'STUDENT'").get().c);

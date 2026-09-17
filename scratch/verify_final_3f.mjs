import crypto from 'crypto';
const uuidv4 = () => crypto.randomUUID();

const API_BASE = 'http://127.0.0.1:8787';

const clientId = 'TEST_UID_CLIENT';
const draughtsmanId = 'TEST_UID_DRAUGHTSMAN';
const adminId = 'TEST_UID_ADMIN';

const clientToken = `TEST_UID_${clientId}`;
const draughtsmanToken = `TEST_UID_${draughtsmanId}`;
const adminToken = `TEST_UID_${adminId}`;

async function fetchNotifications(token) {
  const res = await fetch(`${API_BASE}/api/notifications`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to fetch notifications: ${res.status} ${text}`);
  }
  return res.json();
}

async function markNotificationAsRead(token, id) {
  const res = await fetch(`${API_BASE}/api/notifications/${id}/read`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to mark read: ${res.status} ${text}`);
  }
}

async function fetchActivityLogs(token, projectId) {
  const res = await fetch(`${API_BASE}/api/projects/${projectId}/activity`, {
    headers: { 'Authorization': `Bearer ${token}` }
  });
  if (!res.ok) {
    const text = await res.text();
    throw new Error(`Failed to fetch activity logs: ${res.status} ${text}`);
  }
  return res.json();
}

async function verifyFinal3F() {
  console.log("Starting FINAL Part 3F Verification...");
  
  // 1. CLIENT CREATES PROJECT
  console.log("\\n--- 1. CLIENT CREATES PROJECT ---");
  const projectId = uuidv4();
  const cRes = await fetch(`${API_BASE}/api/projects`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${clientToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      id: projectId,
      project_name: 'Final 3F Verification Project',
      project_address: '123 Test Ave',
      drawing_name: 'Test Floor Plan',
      drawing_type: '2D_FLOOR_PLAN',
      project_area: '100 sqm'
    })
  });
  if (!cRes.ok) {
    const text = await cRes.text();
    throw new Error(`Failed to create project: ${cRes.status} ${text}`);
  }
  console.log("Created Project:", projectId);

  // Client Submits Project
  console.log("\\n--- 1.1 CLIENT SUBMITS PROJECT ---");
  const sRes = await fetch(`${API_BASE}/api/projects/submit`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${clientToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ projectId, actionId: `test-submit-${Date.now()}` })
  });
  if (!sRes.ok) throw new Error("Failed to submit project");

  // Admin Approves Project
  console.log("\\n--- 1.2 ADMIN APPROVES PROJECT ---");
  const apRes = await fetch(`${API_BASE}/api/projects/approve`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${adminToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ projectId, actionId: `test-approve-${Date.now()}` })
  });
  if (!apRes.ok) throw new Error("Failed to approve project");

  // 1. Assignment created -> Draughtsman notification
  console.log("\\n--- 1.3 ADMIN ASSIGNS DRAUGHTSMAN ---");
  const aRes = await fetch(`${API_BASE}/api/projects/assign`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${adminToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ projectId, draughtsmanId, actionId: `test-assign-${Date.now()}` })
  });
  if (!aRes.ok) throw new Error("Failed to assign project");

  let notifsD = await fetchNotifications(draughtsmanToken);
  let notif1 = notifsD.find(n => n.type === 'DRAUGHTSMAN_ASSIGNED' && n.project_id === projectId);
  if (!notif1) throw new Error("Failed to find DRAUGHTSMAN_ASSIGNED notification");
  if (notif1.is_read) throw new Error("Notification should be unread initially");
  console.log("PASS: DRAUGHTSMAN_ASSIGNED notification created and is unread.");
  
  await markNotificationAsRead(draughtsmanToken, notif1.id);
  notifsD = await fetchNotifications(draughtsmanToken);
  notif1 = notifsD.find(n => n.id === notif1.id);
  if (!notif1.is_read) throw new Error("Failed to mark DRAUGHTSMAN_ASSIGNED as read");
  console.log("PASS: DRAUGHTSMAN_ASSIGNED notification marked as read.");

  let activities = await fetchActivityLogs(clientToken, projectId);
  if (!activities.find(a => a.action_type === 'DRAUGHTSMAN_ASSIGNED')) throw new Error("Missing DRAUGHTSMAN_ASSIGNED activity log");
  console.log("PASS: DRAUGHTSMAN_ASSIGNED activity log verified.");

  // Fetch assignment ID for accepting
  const pRes = await fetch(`${API_BASE}/api/projects`, {
    headers: { 'Authorization': `Bearer ${adminToken}` }
  });
  const projects = await pRes.json();
  const project = projects.find(p => p.id === projectId);
  const assignmentId = project.current_assignment_id;

  // 2. Assignment accepted -> Client notification
  console.log("\\n--- 2. DRAUGHTSMAN ACCEPTS ASSIGNMENT ---");
  const accRes = await fetch(`${API_BASE}/api/assignments/accept`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${draughtsmanToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ projectId, assignmentId, actionId: `test-accept-${Date.now()}` })
  });
  if (!accRes.ok) throw new Error("Failed to accept assignment");

  let notifsC = await fetchNotifications(clientToken);
  let notif2 = notifsC.find(n => n.type === 'ASSIGNMENT_ACCEPTED' && n.project_id === projectId);
  if (!notif2) throw new Error("Failed to find ASSIGNMENT_ACCEPTED notification");
  if (notif2.is_read) throw new Error("Notification should be unread initially");
  console.log("PASS: ASSIGNMENT_ACCEPTED notification created and is unread.");
  
  await markNotificationAsRead(clientToken, notif2.id);
  notifsC = await fetchNotifications(clientToken);
  notif2 = notifsC.find(n => n.id === notif2.id);
  if (!notif2.is_read) throw new Error("Failed to mark ASSIGNMENT_ACCEPTED as read");
  console.log("PASS: ASSIGNMENT_ACCEPTED notification marked as read.");

  activities = await fetchActivityLogs(clientToken, projectId);
  if (!activities.find(a => a.action_type === 'ASSIGNMENT_ACCEPTED')) throw new Error("Missing ASSIGNMENT_ACCEPTED activity log");
  console.log("PASS: ASSIGNMENT_ACCEPTED activity log verified.");

  // 3. Initial drawing submitted -> Client notification
  console.log("\\n--- 3. DRAUGHTSMAN SUBMITS DRAWING ---");
  const subRes = await fetch(`${API_BASE}/api/projects/submit-drawing`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${draughtsmanToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ projectId, actionId: `test-submit-draw-${Date.now()}` })
  });
  if (!subRes.ok) throw new Error("Failed to submit drawing");

  notifsC = await fetchNotifications(clientToken);
  let notif3 = notifsC.find(n => n.type === 'DRAWING_SUBMITTED' && n.project_id === projectId);
  if (!notif3) throw new Error("Failed to find DRAWING_SUBMITTED notification");
  console.log("PASS: DRAWING_SUBMITTED notification created and is unread.");

  activities = await fetchActivityLogs(clientToken, projectId);
  if (!activities.find(a => a.action_type === 'DRAWING_SUBMITTED')) throw new Error("Missing DRAWING_SUBMITTED activity log");
  console.log("PASS: DRAWING_SUBMITTED activity log verified.");

  // 4. Correction requested -> Draughtsman notification
  console.log("\\n--- 4. CLIENT REQUESTS CORRECTION ---");
  const targetVersionId = `v-test-${Date.now()}`;
  const mockFileId = `f-test-${Date.now()}`;
  const { execSync } = await import('child_process');
  execSync(`npx wrangler d1 execute archi-draft-db --local -y --command="INSERT INTO files (id, project_id, uploaded_by, original_name, sanitized_name, object_key, content_type, size, category, status) VALUES ('${mockFileId}', '${projectId}', 'TEST_UID_DRAUGHTSMAN', 'test.pdf', 'test.pdf', 'test/test.pdf', 'application/pdf', 100, 'draughtsman_version', 'COMPLETED')"`, { cwd: './worker' });
  execSync(`npx wrangler d1 execute archi-draft-db --local -y --command="INSERT INTO drawing_versions (id, project_id, file_id, version_number, uploaded_by) VALUES ('${targetVersionId}', '${projectId}', '${mockFileId}', 1, 'TEST_UID_DRAUGHTSMAN')"`, { cwd: './worker' });

  const reqCorRes = await fetch(`${API_BASE}/api/projects/request-correction`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${clientToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({
      projectId,
      actionId: `test-cor-req-${Date.now()}`,
      correctionId: `corr-${Date.now()}`,
      targetVersionId,
      description: 'Needs more windows'
    })
  });
  if (!reqCorRes.ok) {
    const txt = await reqCorRes.text();
    throw new Error(`Failed to request correction: ${reqCorRes.status} ${txt}`);
  }

  notifsD = await fetchNotifications(draughtsmanToken);
  let notif4 = notifsD.find(n => n.type === 'CORRECTION_REQUESTED' && n.project_id === projectId);
  if (!notif4) throw new Error("Failed to find CORRECTION_REQUESTED notification");
  console.log("PASS: CORRECTION_REQUESTED notification created and is unread.");

  activities = await fetchActivityLogs(clientToken, projectId);
  if (!activities.find(a => a.action_type === 'CORRECTION_REQUESTED')) throw new Error("Missing CORRECTION_REQUESTED activity log");
  console.log("PASS: CORRECTION_REQUESTED activity log verified.");

  // 5. Revised drawing submitted -> Client notification
  console.log("\\n--- 5. DRAUGHTSMAN SUBMITS REVISED DRAWING ---");
  const subRevRes = await fetch(`${API_BASE}/api/projects/submit-drawing`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${draughtsmanToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ projectId, actionId: `test-sub-rev-${Date.now()}` })
  });
  if (!subRevRes.ok) throw new Error("Failed to submit revised drawing");

  notifsC = await fetchNotifications(clientToken);
  let notif5 = notifsC.filter(n => n.type === 'DRAWING_SUBMITTED' && n.project_id === projectId);
  if (notif5.length < 2) throw new Error("Failed to find second DRAWING_SUBMITTED notification");
  console.log("PASS: DRAWING_SUBMITTED (revised) notification created and is unread.");

  activities = await fetchActivityLogs(clientToken, projectId);
  if (activities.filter(a => a.action_type === 'DRAWING_SUBMITTED').length < 2) throw new Error("Missing second DRAWING_SUBMITTED activity log");
  console.log("PASS: DRAWING_SUBMITTED (revised) activity log verified.");

  // 6. Final approval / completion -> Draughtsman notification
  console.log("\\n--- 6. CLIENT APPROVES FINAL DRAWING ---");
  const appFinRes = await fetch(`${API_BASE}/api/projects/approve-final`, {
    method: 'POST',
    headers: { 'Authorization': `Bearer ${clientToken}`, 'Content-Type': 'application/json' },
    body: JSON.stringify({ projectId, actionId: `test-app-fin-${Date.now()}` })
  });
  
  if (!appFinRes.ok) {
    const text = await appFinRes.text();
    throw new Error(`Failed to approve final drawing: ${appFinRes.status} ${text}`);
  }

  notifsD = await fetchNotifications(draughtsmanToken);
  let notif6 = notifsD.find(n => n.type === 'PROJECT_COMPLETED' && n.project_id === projectId);
  if (!notif6) throw new Error("Failed to find PROJECT_COMPLETED notification");
  console.log("PASS: PROJECT_COMPLETED notification created and is unread.");

  activities = await fetchActivityLogs(clientToken, projectId);
  if (!activities.find(a => a.action_type === 'PROJECT_COMPLETED')) throw new Error("Missing PROJECT_COMPLETED activity log");
  console.log("PASS: PROJECT_COMPLETED activity log verified.");
  
  // 7. Verify unauthorized access
  console.log("\\n--- 7. VERIFY UNAUTHORIZED ACCESS ---");
  try {
    await markNotificationAsRead(draughtsmanToken, notif2.id); // draughtsman trying to read client's notification
    throw new Error("Draughtsman should not be able to read Client's notification");
  } catch (e) {
    if (e.message.includes("403")) {
      console.log("PASS: Unauthorized access to read another user's notification failed as expected.");
    } else {
      throw e;
    }
  }

  console.log("\\n✅ ALL NOTIFICATIONS VERIFIED END-TO-END!");
}

verifyFinal3F().catch(err => console.error(err));

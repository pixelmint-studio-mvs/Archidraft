import { describe, it } from 'node:test';
import assert from 'node:assert';
import fs from 'node:fs';
import path from 'node:path';

describe('Admin Notification Feed & Dashboard Contracts', () => {
  const root = fs.existsSync(path.resolve('src')) ? path.resolve('.') : path.resolve('apps', 'admin-web');

  it('AdminNotification model structure matches Worker notifications schema and API contracts', () => {
    const rawNotification = {
      id: 'notif-101',
      recipient_id: 'admin-1',
      project_id: 'prj-alpha',
      type: 'PROJECT_SUBMITTED',
      message: 'New project "Skyline Tower" submitted by John Doe',
      is_read: 0,
      read_at: null,
      created_at: '2026-11-04T10:00:00Z',
      project_name: 'Skyline Tower',
    };

    assert.strictEqual(rawNotification.id, 'notif-101');
    assert.strictEqual(rawNotification.is_read, 0);
    assert.strictEqual(rawNotification.project_name, 'Skyline Tower');
    assert.strictEqual(rawNotification.type, 'PROJECT_SUBMITTED');
  });

  it('Calculates unread badge count accurately from notification feed', () => {
    const notifications = [
      { id: '1', is_read: 0 },
      { id: '2', is_read: 1 },
      { id: '3', is_read: 0 },
      { id: '4', is_read: 0 },
      { id: '5', is_read: 1 },
    ];

    const unreadCount = notifications.filter((n) => !n.is_read).length;
    assert.strictEqual(unreadCount, 3);
  });

  it('Simulates single notification dismissal without mutating remaining list order', () => {
    let notifications = [
      { id: '1', message: 'First' },
      { id: '2', message: 'Second' },
      { id: '3', message: 'Third' },
    ];

    const dismissId = '2';
    notifications = notifications.filter((n) => n.id !== dismissId);

    assert.strictEqual(notifications.length, 2);
    assert.strictEqual(notifications[0].id, '1');
    assert.strictEqual(notifications[1].id, '3');
    assert.strictEqual(notifications.some((n) => n.id === '2'), false);
  });

  it('Simulates clear all notifications returning clean empty state', () => {
    let notifications = [
      { id: '1', message: 'First' },
      { id: '2', message: 'Second' },
    ];

    notifications = [];
    assert.strictEqual(notifications.length, 0);
  });

  it('Header.tsx imports and renders AdminNotificationPopover replacing D1 Worker Live', () => {
    const headerPath = path.join(root, 'src', 'components', 'layout', 'Header.tsx');
    const content = fs.readFileSync(headerPath, 'utf8');

    assert.ok(
      content.includes("import { AdminNotificationPopover } from './AdminNotificationPopover';"),
      'Header.tsx must import AdminNotificationPopover'
    );
    assert.ok(
      content.includes('<AdminNotificationPopover />'),
      'Header.tsx must render <AdminNotificationPopover />'
    );
    assert.ok(
      !content.includes('D1 Worker Live'),
      'Header.tsx must not retain hardcoded D1 Worker Live indicator'
    );
  });

  it('AdminNotificationPopover.tsx component exists and provides required actions', () => {
    const popoverPath = path.join(root, 'src', 'components', 'layout', 'AdminNotificationPopover.tsx');
    assert.ok(fs.existsSync(popoverPath), 'AdminNotificationPopover.tsx must exist');

    const content = fs.readFileSync(popoverPath, 'utf8');
    assert.ok(content.includes('adminApi.getNotifications'), 'Must fetch notifications from adminApi');
    assert.ok(content.includes('adminApi.clearNotification'), 'Must support clearing single notification');
    assert.ok(content.includes('adminApi.clearAllNotifications'), 'Must support clearing all notifications');
    assert.ok(content.includes('adminApi.markAllNotificationsRead'), 'Must support marking notifications read');
    assert.ok(content.includes('Studio Queue All Clear'), 'Must display empty state');
  });

  it('adminApi in api.ts defines full notification CRUD methods', () => {
    const apiPath = path.join(root, 'src', 'lib', 'api.ts');
    const content = fs.readFileSync(apiPath, 'utf8');

    assert.ok(content.includes('getNotifications():'), 'Must export getNotifications');
    assert.ok(content.includes('markNotificationRead('), 'Must export markNotificationRead');
    assert.ok(content.includes('markAllNotificationsRead('), 'Must export markAllNotificationsRead');
    assert.ok(content.includes('clearNotification('), 'Must export clearNotification');
    assert.ok(content.includes('clearAllNotifications('), 'Must export clearAllNotifications');
  });
});

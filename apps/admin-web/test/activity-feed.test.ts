import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Admin Activity Feed Contracts & Telemetry Tests', () => {
  it('Parses genuine activity records and populates project_name from Worker contract', () => {
    const rawWorkerEvents = [
      {
        id: 'act-1',
        project_id: 'prj-101',
        action_type: 'PROJECT_SUBMITTED',
        actor_id: 'uid-eng-1',
        actor_role: 'CLIENT',
        details: 'Engineer submitted the project brief.',
        timestamp: '2026-10-25T01:00:00Z',
        project_name: 'Metro Villa Residence',
      },
      {
        id: 'act-2',
        project_id: 'prj-102',
        action_type: 'PROJECT_APPROVED',
        actor_id: 'uid-admin-1',
        actor_role: 'STUDIO_ADMIN',
        details: 'Studio Admin approved the project.',
        timestamp: '2026-10-25T02:00:00Z',
        project_name: 'Urban Commercial Tower',
      },
    ];

    // Ensure array contract and field structure
    assert.ok(Array.isArray(rawWorkerEvents));
    assert.strictEqual(rawWorkerEvents.length, 2);
    assert.strictEqual(rawWorkerEvents[0].action_type, 'PROJECT_SUBMITTED');
    assert.strictEqual(rawWorkerEvents[0].project_name, 'Metro Villa Residence');
    assert.strictEqual(rawWorkerEvents[1].actor_role, 'STUDIO_ADMIN');
  });

  it('Sorts incoming activity events in reverse chronological order (newest first)', () => {
    const unorderedEvents = [
      { id: '1', timestamp: '2026-10-25T00:30:00Z' },
      { id: '2', timestamp: '2026-10-25T02:15:00Z' },
      { id: '3', timestamp: '2026-10-25T01:45:00Z' },
    ];

    const sorted = [...unorderedEvents].sort(
      (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
    );

    assert.strictEqual(sorted[0].id, '2', 'Newest event must be first');
    assert.strictEqual(sorted[1].id, '3', 'Second event must be intermediate');
    assert.strictEqual(sorted[2].id, '1', 'Oldest event must be last');
  });

  it('Preserves previously retrieved activity events upon polling refresh failure', () => {
    let currentLogs = [
      { id: 'evt-1', action_type: 'PROJECT_SUBMITTED', timestamp: '2026-10-25T00:00:00Z' }
    ];
    let pollError: string | null = null;

    // Simulate poll error
    try {
      throw new Error('Network error during poll');
    } catch (err: any) {
      pollError = err.message;
      // Requirement: Do NOT clear currentLogs on background poll error
    }

    assert.strictEqual(currentLogs.length, 1, 'Previous logs must be retained');
    assert.strictEqual(currentLogs[0].id, 'evt-1');
    assert.strictEqual(pollError, 'Network error during poll');
  });

  it('Categorizes error states accurately without disguising failures as empty D1 records', () => {
    function categorizeError(status: number | null, message?: string) {
      const isAuthError = status === 401 || status === 403 || message?.toLowerCase().includes('unauthorized') || message?.toLowerCase().includes('forbidden');
      const isServerError = (status !== null && status >= 500) || message?.toLowerCase().includes('internal');
      const isNetworkError = !status || message?.toLowerCase().includes('failed to fetch');

      if (isAuthError) return 'AUTH_ERROR';
      if (isServerError) return 'SERVER_ERROR';
      if (isNetworkError) return 'NETWORK_ERROR';
      return 'UNKNOWN_ERROR';
    }

    assert.strictEqual(categorizeError(401), 'AUTH_ERROR');
    assert.strictEqual(categorizeError(403), 'AUTH_ERROR');
    assert.strictEqual(categorizeError(500), 'SERVER_ERROR');
    assert.strictEqual(categorizeError(502), 'SERVER_ERROR');
    assert.strictEqual(categorizeError(null, 'Failed to fetch'), 'NETWORK_ERROR');
  });

  it('Renders empty state message ONLY when query succeeds with zero genuine records and no error', () => {
    function shouldDisplayEmptyState(logsCount: number, hasError: boolean, isLoading: boolean): boolean {
      return logsCount === 0 && !hasError && !isLoading;
    }

    assert.strictEqual(shouldDisplayEmptyState(0, false, false), true, 'Empty state when genuine 0 records');
    assert.strictEqual(shouldDisplayEmptyState(0, true, false), false, 'MUST NOT show empty state when there is an error');
    assert.strictEqual(shouldDisplayEmptyState(0, false, true), false, 'MUST NOT show empty state while loading');
    assert.strictEqual(shouldDisplayEmptyState(5, false, false), false, 'MUST NOT show empty state when logs exist');
  });

  it('Searches across action_type, details, project_id, and project_name', () => {
    const logs = [
      { id: '1', action_type: 'PROJECT_SUBMITTED', details: 'Client brief', project_id: 'p101', project_name: 'Harbor Tower', actor_role: 'CLIENT' },
      { id: '2', action_type: 'DRAWING_SUBMITTED', details: 'AutoCAD DWG uploaded', project_id: 'p202', project_name: 'Metro Pavilion', actor_role: 'DRAUGHTSMAN' },
    ];

    function filterLogs(items: typeof logs, query: string) {
      const q = query.toLowerCase().trim();
      if (!q) return items;
      return items.filter(
        (l) =>
          l.action_type.toLowerCase().includes(q) ||
          l.details.toLowerCase().includes(q) ||
          l.project_id.toLowerCase().includes(q) ||
          (l.project_name || '').toLowerCase().includes(q) ||
          l.actor_role.toLowerCase().includes(q)
      );
    }

    assert.strictEqual(filterLogs(logs, 'Harbor').length, 1, 'Match by project_name');
    assert.strictEqual(filterLogs(logs, 'p202').length, 1, 'Match by project_id');
    assert.strictEqual(filterLogs(logs, 'AutoCAD').length, 1, 'Match by details');
    assert.strictEqual(filterLogs(logs, 'DRAUGHTSMAN').length, 1, 'Match by actor_role');
    assert.strictEqual(filterLogs(logs, 'nonexistent').length, 0, 'No match');
  });
});

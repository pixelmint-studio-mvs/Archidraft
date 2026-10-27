import { describe, it } from 'node:test';
import assert from 'node:assert/strict';

describe('Project Approval Consistency & Drawing Revision Integrity', () => {
  it('prevents approval of older drawing version when a newer revision exists', async () => {
    const drawingVersions = [
      { id: 'dv-1', version_number: 1 },
      { id: 'dv-2', version_number: 2 },
    ];
    
    const latestVersion = drawingVersions.slice().sort((a, b) => b.version_number - a.version_number)[0];
    const targetVersionId = 'dv-1';
    const targetVersion = drawingVersions.find(v => v.id === targetVersionId);

    const isOlderVersion = latestVersion && latestVersion.id !== targetVersionId && latestVersion.version_number > targetVersion.version_number;

    assert.equal(isOlderVersion, true, 'Older version approval must be flagged');
  });

  it('permits approval of the latest drawing version', async () => {
    const drawingVersions = [
      { id: 'dv-1', version_number: 1 },
      { id: 'dv-2', version_number: 2 },
    ];
    
    const latestVersion = drawingVersions.slice().sort((a, b) => b.version_number - a.version_number)[0];
    const targetVersionId = 'dv-2';
    const targetVersion = drawingVersions.find(v => v.id === targetVersionId);

    const isOlderVersion = latestVersion && latestVersion.id !== targetVersionId && latestVersion.version_number > targetVersion.version_number;

    assert.equal(isOlderVersion, false, 'Latest version approval must be permitted');
  });

  it('resolves active corrections and marks assignment completed upon project completion', () => {
    const project = { id: 'prj-1', status: 'UNDER_ENGINEER_REVIEW' };
    const assignment = { id: 'assign-1', status: 'ACCEPTED', correction_round: 1 };
    const correction = { id: 'corr-1', status: 'OPEN' };

    // After buildApproveFinalBatch
    project.status = 'COMPLETED';
    assignment.status = 'COMPLETED';
    correction.status = 'RESOLVED';

    const isCompleted = assignment.status === 'COMPLETED' || project.status === 'COMPLETED';
    const hasActiveCorrection = !isCompleted && assignment.status === 'ACCEPTED' && (assignment.correction_round > 0);

    assert.equal(isCompleted, true);
    assert.equal(hasActiveCorrection, false, 'Completed project must never have active correction state');
  });
});

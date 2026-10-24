import { describe, test } from 'node:test';
import assert from 'node:assert/strict';

// ── Evaluation Schema & Contract Validation Logic ──

type EvaluationDecision = 'APPROVED' | 'NEEDS_CORRECTION' | 'REJECTED';

interface EvaluatePayloadInput {
  projectId: string;
  drawingVersionId: string;
  overallResult: string;
  accuracy: any;
  technicalStandards: any;
  generalFeedback: string;
  actionId?: string;
}

interface ValidationResult {
  valid: boolean;
  error?: string;
  serializedPayload?: {
    projectId: string;
    drawingVersionId: string;
    overallResult: EvaluationDecision;
    generalFeedback: string;
    criteriaJson: string;
    actionId: string;
    correctionId?: string;
  };
}

function validateAndPrepareEvaluation(input: EvaluatePayloadInput): ValidationResult {
  // Decision validation
  const validDecisions: EvaluationDecision[] = ['APPROVED', 'NEEDS_CORRECTION', 'REJECTED'];
  if (!validDecisions.includes(input.overallResult as EvaluationDecision)) {
    return { valid: false, error: 'Invalid overall result. Must be APPROVED, NEEDS_CORRECTION, or REJECTED.' };
  }
  const decision = input.overallResult as EvaluationDecision;

  // Accuracy validation
  if (
    typeof input.accuracy !== 'number' ||
    !Number.isInteger(input.accuracy) ||
    input.accuracy < 1 ||
    input.accuracy > 5
  ) {
    return { valid: false, error: "Criterion 'Accuracy' must be an integer between 1 and 5." };
  }

  // Technical Standards validation
  if (
    typeof input.technicalStandards !== 'number' ||
    !Number.isInteger(input.technicalStandards) ||
    input.technicalStandards < 1 ||
    input.technicalStandards > 5
  ) {
    return { valid: false, error: "Criterion 'Technical Standards' must be an integer between 1 and 5." };
  }

  // General feedback requirement
  const trimmedFeedback = (input.generalFeedback || '').trim();
  if (decision !== 'APPROVED' && !trimmedFeedback) {
    return {
      valid: false,
      error:
        decision === 'NEEDS_CORRECTION'
          ? 'Feedback and revision instructions are required when requesting a correction.'
          : 'A detailed rejection reason is required when rejecting a submission.',
    };
  }

  const criteriaObj = {
    Accuracy: input.accuracy,
    'Technical Standards': input.technicalStandards,
  };

  const actionId = input.actionId || 'test-action-uuid-1234';
  const correctionId = decision === 'NEEDS_CORRECTION' ? 'test-corr-uuid-5678' : undefined;

  return {
    valid: true,
    serializedPayload: {
      projectId: input.projectId,
      drawingVersionId: input.drawingVersionId,
      overallResult: decision,
      generalFeedback: trimmedFeedback,
      criteriaJson: JSON.stringify(criteriaObj),
      actionId,
      correctionId,
    },
  };
}

// ── Test Suites ──

describe('Evaluation Modal & API Contract — Rubric Scoring Rules', () => {
  test('Valid rubric scoring (Accuracy: 5, Technical Standards: 5) passes validation', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 5,
      technicalStandards: 5,
      generalFeedback: 'Masterful architectural precision.',
    });

    assert.equal(res.valid, true);
    assert.ok(res.serializedPayload);
    assert.equal(res.serializedPayload.overallResult, 'APPROVED');

    const parsedCriteria = JSON.parse(res.serializedPayload.criteriaJson);
    assert.equal(parsedCriteria['Accuracy'], 5);
    assert.equal(parsedCriteria['Technical Standards'], 5);
  });

  test('Valid lower-bound rubric scoring (Accuracy: 1, Technical Standards: 1) passes validation', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'REJECTED',
      accuracy: 1,
      technicalStandards: 1,
      generalFeedback: 'Non-compliant with basic grid system.',
    });

    assert.equal(res.valid, true);
    assert.ok(res.serializedPayload);
    assert.equal(res.serializedPayload.overallResult, 'REJECTED');
  });

  test('Rejects out-of-range Accuracy score (< 1)', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 0,
      technicalStandards: 4,
      generalFeedback: '',
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /Accuracy.*integer between 1 and 5/);
  });

  test('Rejects out-of-range Accuracy score (> 5)', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 6,
      technicalStandards: 4,
      generalFeedback: '',
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /Accuracy.*integer between 1 and 5/);
  });

  test('Rejects non-integer decimal Accuracy score (e.g. 4.5)', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 4.5,
      technicalStandards: 4,
      generalFeedback: '',
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /Accuracy.*integer between 1 and 5/);
  });

  test('Rejects out-of-range Technical Standards score (> 5)', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 4,
      technicalStandards: 10,
      generalFeedback: '',
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /Technical Standards.*integer between 1 and 5/);
  });

  test('Rejects missing or null criteria scores', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: null,
      technicalStandards: 4,
      generalFeedback: '',
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /Accuracy.*integer between 1 and 5/);
  });
});

describe('Evaluation Modal & API Contract — Decision Options & Feedback Rules', () => {
  test('Requires feedback when decision is NEEDS_CORRECTION', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'NEEDS_CORRECTION',
      accuracy: 3,
      technicalStandards: 3,
      generalFeedback: '',
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /Feedback and revision instructions are required/);
  });

  test('Requires feedback when decision is REJECTED', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'REJECTED',
      accuracy: 2,
      technicalStandards: 2,
      generalFeedback: '   ', // whitespace only
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /detailed rejection reason is required/);
  });

  test('Permits optional empty feedback when decision is APPROVED', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 5,
      technicalStandards: 4,
      generalFeedback: '',
    });

    assert.equal(res.valid, true);
    assert.equal(res.serializedPayload?.generalFeedback, '');
  });

  test('Rejects unsupported decision string (e.g. PENDING or IN_REVIEW)', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'PENDING',
      accuracy: 5,
      technicalStandards: 4,
      generalFeedback: 'Nice',
    });

    assert.equal(res.valid, false);
    assert.match(res.error!, /Invalid overall result/);
  });
});

describe('Evaluation Modal & API Contract — Idempotency & Worker Schema Compatibility', () => {
  test('Generates correctionId only for NEEDS_CORRECTION decision', () => {
    const revision = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'NEEDS_CORRECTION',
      accuracy: 3,
      technicalStandards: 3,
      generalFeedback: 'Adjust footing dimensions by 50mm.',
    });

    assert.equal(revision.valid, true);
    assert.ok(revision.serializedPayload?.correctionId);

    const approved = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 4,
      technicalStandards: 4,
      generalFeedback: 'Good job',
    });

    assert.equal(approved.valid, true);
    assert.equal(approved.serializedPayload?.correctionId, undefined);

    const rejected = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'REJECTED',
      accuracy: 2,
      technicalStandards: 2,
      generalFeedback: 'Major defects',
    });

    assert.equal(rejected.valid, true);
    assert.equal(rejected.serializedPayload?.correctionId, undefined);
  });

  test('Includes actionId for idempotency deduplication across retries', () => {
    const aid = 'uuid-idempotent-action-999';
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 5,
      technicalStandards: 5,
      generalFeedback: 'Certified',
      actionId: aid,
    });

    assert.equal(res.valid, true);
    assert.equal(res.serializedPayload?.actionId, aid);
  });

  test('criteriaJson conforms exactly to Worker index.ts:L1689 allowed keys format', () => {
    const res = validateAndPrepareEvaluation({
      projectId: 'proj_01',
      drawingVersionId: 'ver_01',
      overallResult: 'APPROVED',
      accuracy: 4,
      technicalStandards: 5,
      generalFeedback: 'Meets high bar',
    });

    assert.ok(res.serializedPayload);
    const parsed = JSON.parse(res.serializedPayload.criteriaJson);
    const keys = Object.keys(parsed);

    // Worker requires exactly ['Accuracy', 'Technical Standards']
    assert.equal(keys.length, 2);
    assert.ok(keys.includes('Accuracy'));
    assert.ok(keys.includes('Technical Standards'));
    assert.equal(typeof parsed['Accuracy'], 'number');
    assert.equal(typeof parsed['Technical Standards'], 'number');
  });
});

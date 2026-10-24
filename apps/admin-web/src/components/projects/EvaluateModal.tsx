'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { EvaluationDecision } from '@/lib/types';
import {
  Award,
  CheckCircle,
  AlertTriangle,
  XCircle,
  FileDown,
  User,
  GraduationCap,
  BookOpen,
  AlertCircle,
  Sparkles,
  Layers,
} from 'lucide-react';

interface EvaluateModalProps {
  isOpen: boolean;
  onClose: () => void;
  projectId: string;
  projectName: string;
  studentName?: string | null;
  studentEmail?: string | null;
  moduleTitle?: string | null;
  drawingVersionId: string;
  versionNumber?: number | null;
  fileId?: string | null;
  correctionRound?: number;
  onSuccess: () => void;
}

const ACCURACY_DESCRIPTIONS: Record<number, string> = {
  1: 'Unsatisfactory (<60%) - Major dimensional discrepancies',
  2: 'Needs Revision (60-70%) - Noticeable drafting inaccuracies',
  3: 'Acceptable (70-80%) - Standard dimensional fidelity',
  4: 'High Precision (80-90%) - Clean alignment & accurate scaling',
  5: 'Flawless Precision (90-100%) - Exact municipal & grid precision',
};

const TECHNICAL_DESCRIPTIONS: Record<number, string> = {
  1: 'Non-Compliant (<60%) - Missing line weights & wrong layers',
  2: 'Minor Standard Adherence (60-70%) - Inconsistent symbology',
  3: 'Standard Compliant (70-80%) - Meets CAD drafting standards',
  4: 'Exceeds Standards (80-90%) - Excellent layer discipline & annotations',
  5: 'Professional Grade (90-100%) - Production-ready studio standards',
};

export function EvaluateModal({
  isOpen,
  onClose,
  projectId,
  projectName,
  studentName,
  studentEmail,
  moduleTitle,
  drawingVersionId,
  versionNumber,
  fileId,
  correctionRound = 0,
  onSuccess,
}: EvaluateModalProps) {
  const [decision, setDecision] = useState<EvaluationDecision>('APPROVED');
  const [accuracy, setAccuracy] = useState<number | null>(null);
  const [technicalStandards, setTechnicalStandards] = useState<number | null>(null);
  const [generalFeedback, setGeneralFeedback] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);

    // Validation
    if (!accuracy || accuracy < 1 || accuracy > 5) {
      setError('Please provide an Accuracy score between 1 and 5.');
      return;
    }
    if (!technicalStandards || technicalStandards < 1 || technicalStandards > 5) {
      setError('Please provide a Technical Standards score between 1 and 5.');
      return;
    }

    if (decision !== 'APPROVED' && !generalFeedback.trim()) {
      setError(
        decision === 'NEEDS_CORRECTION'
          ? 'Feedback and revision instructions are required when requesting a correction.'
          : 'A detailed rejection reason is required when rejecting a submission.'
      );
      return;
    }

    setLoading(true);

    try {
      const criteriaJson = JSON.stringify({
        Accuracy: accuracy,
        'Technical Standards': technicalStandards,
      });

      const actionId = crypto.randomUUID();
      const correctionId = decision === 'NEEDS_CORRECTION' ? crypto.randomUUID() : undefined;

      await adminApi.evaluateProject({
        projectId,
        drawingVersionId,
        overallResult: decision,
        generalFeedback: generalFeedback.trim(),
        criteriaJson,
        actionId,
        correctionId,
      });

      setSuccessMsg(
        decision === 'APPROVED'
          ? 'Drawing submission approved successfully. Module certification updated.'
          : decision === 'NEEDS_CORRECTION'
          ? 'Revision requested. Correction task dispatched to student.'
          : 'Submission rejected and archived.'
      );

      setTimeout(() => {
        onSuccess();
        onClose();
      }, 900);
    } catch (err: any) {
      setError(err.message || 'Failed to submit evaluation');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Evaluate Practical Drawing Submission"
      description={`Practical milestone evaluation for "${projectName}". Review drawing, score rubric, and record authoritative decision.`}
      maxWidth="lg"
    >
      <form onSubmit={handleSubmit} className="space-y-5">
        {/* Submission Context Strip */}
        <div className="bg-slate-50 border border-slate-200 rounded-xl p-3.5 space-y-2 text-xs">
          <div className="flex flex-wrap items-center justify-between gap-2 border-b border-slate-200/60 pb-2">
            <div className="flex items-center gap-2">
              <GraduationCap className="h-4 w-4 text-[#0453cd]" />
              <span className="font-semibold text-slate-800">{projectName}</span>
              {versionNumber != null && (
                <span className="px-2 py-0.5 rounded-full bg-blue-100 text-[#0453cd] font-mono font-bold text-[10px]">
                  v{versionNumber}
                </span>
              )}
              {correctionRound > 0 && (
                <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 font-mono font-semibold text-[10px]">
                  Round {correctionRound}
                </span>
              )}
            </div>

            {fileId && (
              <a
                href={adminApi.getFileDownloadUrl(fileId)}
                target="_blank"
                rel="noopener noreferrer"
                className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg bg-white border border-slate-200 text-slate-700 hover:text-[#0453cd] hover:border-[#0453cd] font-medium text-[11px] shadow-2xs transition-all"
              >
                <FileDown className="h-3.5 w-3.5" />
                <span>Inspect Drawing Deliverable</span>
              </a>
            )}
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-slate-600">
            {studentName && (
              <div className="flex items-center gap-1.5">
                <User className="h-3 w-3 text-slate-400" />
                <span>Student: <strong className="text-slate-800 font-medium">{studentName}</strong> ({studentEmail || 'N/A'})</span>
              </div>
            )}
            {moduleTitle && (
              <div className="flex items-center gap-1.5">
                <BookOpen className="h-3 w-3 text-slate-400" />
                <span>Module: <strong className="text-slate-800 font-medium">{moduleTitle}</strong></span>
              </div>
            )}
          </div>
        </div>

        {/* Error / Success Feedback */}
        {error && (
          <div className="flex items-center gap-2 p-3 text-xs text-rose-700 bg-rose-50 border border-rose-200 rounded-xl">
            <AlertCircle className="h-4 w-4 shrink-0 text-rose-600" />
            <span>{error}</span>
          </div>
        )}

        {successMsg && (
          <div className="flex items-center gap-2 p-3 text-xs text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-xl">
            <CheckCircle className="h-4 w-4 shrink-0 text-emerald-600" />
            <span>{successMsg}</span>
          </div>
        )}

        {/* Decision Selection Cards */}
        <div>
          <label className="block text-xs font-mono font-semibold text-slate-700 uppercase tracking-wider mb-2">
            1. Authoritative Evaluation Decision *
          </label>
          <div className="grid grid-cols-3 gap-2.5">
            {/* APPROVED */}
            <button
              type="button"
              onClick={() => setDecision('APPROVED')}
              className={`flex flex-col items-center justify-center p-3 rounded-xl border text-center transition-all ${
                decision === 'APPROVED'
                  ? 'border-emerald-500 bg-emerald-50/70 text-emerald-900 ring-2 ring-emerald-500/20 shadow-xs'
                  : 'border-slate-200 bg-white hover:border-slate-300 text-slate-700'
              }`}
            >
              <CheckCircle className={`h-5 w-5 mb-1.5 ${decision === 'APPROVED' ? 'text-emerald-600' : 'text-slate-400'}`} />
              <span className="text-xs font-bold leading-tight">Approve</span>
              <span className="text-[10px] text-slate-500 mt-0.5">Certify milestone</span>
            </button>

            {/* NEEDS_CORRECTION */}
            <button
              type="button"
              onClick={() => setDecision('NEEDS_CORRECTION')}
              className={`flex flex-col items-center justify-center p-3 rounded-xl border text-center transition-all ${
                decision === 'NEEDS_CORRECTION'
                  ? 'border-amber-500 bg-amber-50/70 text-amber-900 ring-2 ring-amber-500/20 shadow-xs'
                  : 'border-slate-200 bg-white hover:border-slate-300 text-slate-700'
              }`}
            >
              <AlertTriangle className={`h-5 w-5 mb-1.5 ${decision === 'NEEDS_CORRECTION' ? 'text-amber-600' : 'text-slate-400'}`} />
              <span className="text-xs font-bold leading-tight">Needs Revision</span>
              <span className="text-[10px] text-slate-500 mt-0.5">Request redline</span>
            </button>

            {/* REJECTED */}
            <button
              type="button"
              onClick={() => setDecision('REJECTED')}
              className={`flex flex-col items-center justify-center p-3 rounded-xl border text-center transition-all ${
                decision === 'REJECTED'
                  ? 'border-rose-500 bg-rose-50/70 text-rose-900 ring-2 ring-rose-500/20 shadow-xs'
                  : 'border-slate-200 bg-white hover:border-slate-300 text-slate-700'
              }`}
            >
              <XCircle className={`h-5 w-5 mb-1.5 ${decision === 'REJECTED' ? 'text-rose-600' : 'text-slate-400'}`} />
              <span className="text-xs font-bold leading-tight">Reject</span>
              <span className="text-[10px] text-slate-500 mt-0.5">Archive draft</span>
            </button>
          </div>
        </div>

        {/* Rubric Criteria Section */}
        <div className="space-y-4 pt-1 border-t border-slate-100">
          <div className="flex items-center justify-between">
            <label className="text-xs font-mono font-semibold text-slate-700 uppercase tracking-wider">
              2. Practical Rubric Scoring (1 to 5) *
            </label>
            <span className="text-[11px] font-mono text-slate-400">Strictly 1 (Low) to 5 (Mastery)</span>
          </div>

          {/* Criterion: Accuracy */}
          <div className="bg-slate-50/70 border border-slate-200 rounded-xl p-3 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900">Accuracy</span>
              <span className="text-xs font-mono font-bold text-[#0453cd]">
                {accuracy ? `${accuracy} / 5` : 'Not Scored'}
              </span>
            </div>
            <p className="text-[11px] text-slate-500">
              Dimensional fidelity, scale accuracy, geometry, wall thicknesses, and room layout correctness.
            </p>
            <div className="grid grid-cols-5 gap-1.5 pt-1">
              {[1, 2, 3, 4, 5].map((score) => {
                const isSelected = accuracy === score;
                return (
                  <button
                    key={score}
                    type="button"
                    onClick={() => setAccuracy(score)}
                    className={`py-1.5 rounded-lg border text-xs font-mono font-bold transition-all ${
                      isSelected
                        ? 'bg-[#0d1c32] text-white border-[#0d1c32] shadow-xs'
                        : 'bg-white text-slate-700 border-slate-200 hover:border-slate-300 hover:bg-slate-100'
                    }`}
                  >
                    {score}
                  </button>
                );
              })}
            </div>
            {accuracy && (
              <p className="text-[10px] font-mono text-slate-600 italic pt-0.5">
                ↳ {ACCURACY_DESCRIPTIONS[accuracy]}
              </p>
            )}
          </div>

          {/* Criterion: Technical Standards */}
          <div className="bg-slate-50/70 border border-slate-200 rounded-xl p-3 space-y-2">
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold text-slate-900">Technical Standards</span>
              <span className="text-xs font-mono font-bold text-[#0453cd]">
                {technicalStandards ? `${technicalStandards} / 5` : 'Not Scored'}
              </span>
            </div>
            <p className="text-[11px] text-slate-500">
              Layer naming discipline, line weight hierarchy, hatching, dimension styles, and title block completeness.
            </p>
            <div className="grid grid-cols-5 gap-1.5 pt-1">
              {[1, 2, 3, 4, 5].map((score) => {
                const isSelected = technicalStandards === score;
                return (
                  <button
                    key={score}
                    type="button"
                    onClick={() => setTechnicalStandards(score)}
                    className={`py-1.5 rounded-lg border text-xs font-mono font-bold transition-all ${
                      isSelected
                        ? 'bg-[#0d1c32] text-white border-[#0d1c32] shadow-xs'
                        : 'bg-white text-slate-700 border-slate-200 hover:border-slate-300 hover:bg-slate-100'
                    }`}
                  >
                    {score}
                  </button>
                );
              })}
            </div>
            {technicalStandards && (
              <p className="text-[10px] font-mono text-slate-600 italic pt-0.5">
                ↳ {TECHNICAL_DESCRIPTIONS[technicalStandards]}
              </p>
            )}
          </div>
        </div>

        {/* General Qualitative Feedback Textarea */}
        <div className="pt-1 border-t border-slate-100">
          <label className="block text-xs font-mono font-semibold text-slate-700 uppercase tracking-wider mb-1.5">
            3. Qualitative Feedback & Revision Instructions {decision !== 'APPROVED' ? '*' : '(Optional)'}
          </label>
          <textarea
            rows={3}
            value={generalFeedback}
            onChange={(e) => setGeneralFeedback(e.target.value)}
            placeholder={
              decision === 'APPROVED'
                ? 'Optional commendation or architectural feedback for the student apprentice...'
                : decision === 'NEEDS_CORRECTION'
                ? 'Required: Specify the required revisions, missing dimensions, or standard violations to address...'
                : 'Required: Specify why this drawing does not meet studio criteria...'
            }
            className="w-full px-3.5 py-2.5 rounded-xl bg-slate-50 border border-slate-300 text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] transition-all"
            required={decision !== 'APPROVED'}
          />
        </div>

        {/* Footer Actions */}
        <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
          <Button variant="ghost" size="sm" type="button" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button
            variant={decision === 'APPROVED' ? 'success' : decision === 'NEEDS_CORRECTION' ? 'primary' : 'danger'}
            size="sm"
            type="submit"
            loading={loading}
            icon={
              decision === 'APPROVED' ? (
                <CheckCircle className="h-4 w-4" />
              ) : decision === 'NEEDS_CORRECTION' ? (
                <AlertTriangle className="h-4 w-4" />
              ) : (
                <XCircle className="h-4 w-4" />
              )
            }
          >
            {decision === 'APPROVED'
              ? 'Approve & Certify Milestone'
              : decision === 'NEEDS_CORRECTION'
              ? 'Submit Revision Request'
              : 'Confirm Rejection'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

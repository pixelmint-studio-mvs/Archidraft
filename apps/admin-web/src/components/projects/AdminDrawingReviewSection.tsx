'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { adminApi, ApiError } from '@/lib/api';
import { formatDate, formatDateTime } from '@/lib/dateUtils';
import {
  Project,
  DrawingVersion,
  ProjectFile,
  DrawingVersionReview,
} from '@/lib/types';
import {
  CheckCircle,
  XCircle,
  FileCheck2,
  FileText,
  Download,
  Eye,
  AlertTriangle,
  Clock,
  User,
  History,
  Layers,
  Sparkles,
  ArrowRight,
  ShieldCheck,
  RotateCcw,
  Loader2,
  Check,
} from 'lucide-react';

interface AdminDrawingReviewSectionProps {
  project: Project;
  pendingVersion?: DrawingVersion | null;
  allVersions: DrawingVersion[];
  referenceFiles: ProjectFile[];
  reviews: DrawingVersionReview[];
  onDecisionSuccess: () => void;
  onOpenCadViewer?: (versionNumber: number) => void;
  onDownloadFile: (fileId: string, fileName?: string) => Promise<void>;
  downloadingFileId?: string | null;
}

export function AdminDrawingReviewSection({
  project,
  pendingVersion,
  allVersions,
  referenceFiles,
  reviews,
  onDecisionSuccess,
  onOpenCadViewer,
  onDownloadFile,
  downloadingFileId,
}: AdminDrawingReviewSectionProps) {
  // Decision action state: 'idle' | 'approve' | 'revision'
  const [activeAction, setActiveAction] = useState<'idle' | 'approve' | 'revision'>('idle');
  const [approvalNotes, setApprovalNotes] = useState<string>('');
  const [revisionFeedback, setRevisionFeedback] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [successMessage, setSuccessMessage] = useState<string | null>(null);

  // If no pendingVersion is passed, look for one in allVersions
  const targetVersion = pendingVersion || allVersions.find((v) => v.approval_status === 'PENDING') || (allVersions.length > 0 ? allVersions[allVersions.length - 1] : null);
  const isPendingReview = project.status === 'UNDER_ADMIN_REVIEW' || (targetVersion !== null && targetVersion.approval_status === 'PENDING');

  const formatFileSize = (bytes?: number): string => {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const handleApprove = async () => {
    if (!targetVersion || isSubmitting) return;
    setIsSubmitting(true);
    setErrorMessage(null);
    setSuccessMessage(null);

    try {
      await adminApi.adminApproveDrawing(
        project.id,
        targetVersion.id,
        approvalNotes.trim() || undefined
      );

      setSuccessMessage(
        `Drawing version v${targetVersion.version_number} approved successfully. Deliverable released to Engineer for review.`
      );
      setActiveAction('idle');
      setApprovalNotes('');
      onDecisionSuccess();
    } catch (err: any) {
      console.error('Approve drawing error:', err);
      if (err instanceof ApiError && err.status === 409) {
        setErrorMessage(
          'Conflict: This drawing version or project was already modified concurrently by another administrator. Reloading project data...'
        );
        onDecisionSuccess();
      } else if (err instanceof ApiError && (err.status === 400 || err.message?.includes('status'))) {
        setErrorMessage(
          err.message || 'Project status mismatch. Refreshing project data...'
        );
        onDecisionSuccess();
      } else {
        setErrorMessage(err.message || 'Failed to approve drawing version. Please retry.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  const handleRequestRevision = async () => {
    if (!targetVersion || isSubmitting) return;
    if (!revisionFeedback.trim()) {
      setErrorMessage('Feedback is required when requesting a revision from the draughtsman.');
      return;
    }

    setIsSubmitting(true);
    setErrorMessage(null);
    setSuccessMessage(null);

    try {
      await adminApi.adminRequestRevision(
        project.id,
        targetVersion.id,
        revisionFeedback.trim()
      );

      setSuccessMessage(
        `Revision requested on v${targetVersion.version_number}. Project returned to Draughtsman for rework without consuming Engineer correction rounds.`
      );
      setActiveAction('idle');
      setRevisionFeedback('');
      onDecisionSuccess();
    } catch (err: any) {
      console.error('Request revision error:', err);
      if (err instanceof ApiError && err.status === 409) {
        setErrorMessage(
          'Conflict: This drawing version or project was already modified concurrently by another administrator. Reloading project data...'
        );
        onDecisionSuccess();
      } else if (err instanceof ApiError && (err.status === 400 || err.message?.includes('status'))) {
        setErrorMessage(
          err.message || 'Project status mismatch. Refreshing project data...'
        );
        onDecisionSuccess();
      } else {
        setErrorMessage(err.message || 'Failed to submit revision request. Please retry.');
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  // Preset feedback cues for fast review
  const applyPresetFeedback = (cue: string) => {
    setRevisionFeedback((prev) => {
      if (!prev) return cue;
      return `${prev.trim()}\n- ${cue}`;
    });
  };

  // Filter reference files relevant to the brief
  const filteredReferences = referenceFiles.filter((f) =>
    ['client_upload', 'reference', 'specification', 'brief', 'correction_attachment'].includes(f.category)
  );

  return (
    <div className="space-y-4">
      {/* Success Notification Banner */}
      {successMessage && (
        <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 flex items-center gap-3">
          <CheckCircle className="h-5 w-5 text-emerald-600 shrink-0" />
          <span className="text-xs font-medium">{successMessage}</span>
          <button
            type="button"
            onClick={() => setSuccessMessage(null)}
            className="ml-auto text-xs font-mono text-emerald-700 hover:text-emerald-900 cursor-pointer"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Error Notification Banner */}
      {errorMessage && (
        <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-900 flex items-center gap-3">
          <AlertTriangle className="h-5 w-5 text-rose-600 shrink-0" />
          <span className="text-xs font-medium">{errorMessage}</span>
          <button
            type="button"
            onClick={() => setErrorMessage(null)}
            className="ml-auto text-xs font-mono text-rose-700 hover:text-rose-900 cursor-pointer"
          >
            Dismiss
          </button>
        </div>
      )}

      {/* Primary Studio Quality Review Card */}
      <Card
        technicalCorners
        className={`bg-white border-2 soft-elevation transition-all ${
          isPendingReview
            ? 'border-amber-300 shadow-md ring-4 ring-amber-500/10'
            : 'border-slate-200'
        }`}
      >
        {/* Banner Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-4 border-b border-slate-100">
          <div className="flex items-center gap-2.5">
            <div
              className={`h-9 w-9 rounded-xl flex items-center justify-center shrink-0 ${
                isPendingReview
                  ? 'bg-amber-100 text-amber-900 border border-amber-300'
                  : 'bg-blue-50 text-[#0453cd] border border-blue-200'
              }`}
            >
              <ShieldCheck className="h-5 w-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight">
                  Studio Quality Control & Deliverable Review
                </h3>
                {isPendingReview ? (
                  <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-mono font-bold bg-amber-100 text-amber-900 border border-amber-300 animate-pulse">
                    <Clock className="h-3 w-3" />
                    ACTION REQUIRED
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-mono font-medium bg-slate-100 text-slate-700 border border-slate-200">
                    STATUS: {project.status}
                  </span>
                )}
              </div>
              <p className="text-[11px] text-slate-500 font-mono mt-0.5">
                Every commercial drawing submission requires Studio Admin approval before release to Engineer.
              </p>
            </div>
          </div>

          {targetVersion && (
            <div className="flex items-center gap-2 flex-wrap">
              <span className="text-xs font-mono text-slate-500">Under Review:</span>
              <span className="px-2.5 py-1 rounded-lg bg-blue-50 border border-blue-200 text-[#0453cd] font-mono font-bold text-xs truncate max-w-[260px] sm:max-w-none">
                v{targetVersion.version_number} • {targetVersion.original_name || 'CAD Deliverable'}
              </span>
            </div>
          )}
        </div>

        {/* Content Body */}
        {targetVersion ? (
          <div className="mt-4 space-y-5">
            {/* 1. Submitted Drawing Deliverable Summary */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              {/* Deliverable File Info */}
              <div className="p-3.5 rounded-xl bg-slate-50/80 border border-slate-200 space-y-1">
                <div className="flex items-center justify-between">
                  <span className="text-[10px] font-mono font-semibold uppercase text-slate-500">
                    Drawing Version
                  </span>
                  <Badge status={targetVersion.approval_status || 'PENDING'} />
                </div>
                <p className="text-xs font-bold text-slate-900 truncate" title={targetVersion.original_name || 'Deliverable'}>
                  {targetVersion.original_name || `drawing_v${targetVersion.version_number}.dwg`}
                </p>
                <div className="flex items-center gap-2 text-[10px] font-mono text-slate-500 pt-1">
                  <span>Size: {formatFileSize(targetVersion.size)}</span>
                  <span>•</span>
                  <span>{formatDateTime(targetVersion.created_at)}</span>
                </div>
              </div>

              {/* Draughtsman Details */}
              <div className="p-3.5 rounded-xl bg-slate-50/80 border border-slate-200 space-y-1">
                <span className="text-[10px] font-mono font-semibold uppercase text-slate-500 block">
                  Author / Draughtsman
                </span>
                <p className="text-xs font-bold text-slate-900 truncate">
                  {project.draughtsman_name || 'Assigned Draughtsman'}
                </p>
                <p className="text-[10px] font-mono text-slate-500 truncate">
                  ID: {targetVersion.uploaded_by ? targetVersion.uploaded_by.substring(0, 8) : (project.draughtsman_id?.substring(0, 8) || 'Unknown')}
                </p>
                {project.draughtsman_id && (
                  <Link
                    href={`/draughtsmen/${encodeURIComponent(project.draughtsman_id)}`}
                    className="text-[10px] font-mono text-[#0453cd] hover:underline flex items-center gap-1 pt-0.5"
                  >
                    <span>View Draughtsman Dossier</span>
                    <ArrowRight className="h-2.5 w-2.5" />
                  </Link>
                )}
              </div>

              {/* Workflow & Correction Context */}
              <div className="p-3.5 rounded-xl bg-slate-50/80 border border-slate-200 space-y-1">
                <span className="text-[10px] font-mono font-semibold uppercase text-slate-500 block">
                  Workflow Context
                </span>
                <p className="text-xs font-bold text-slate-900">
                  {targetVersion.version_number === 1 ? 'Initial Brief Submission' : `Revision v${targetVersion.version_number}`}
                </p>
                <p className="text-[10px] font-mono text-slate-500">
                  {project.correction_round > 0
                    ? `Addressing Client Correction Round ${project.correction_round}`
                    : 'Standard Pre-Release Studio Inspection'}
                </p>
                <div className="flex items-center gap-2 pt-1 text-[10px] font-mono text-emerald-700">
                  <Check className="h-3 w-3" />
                  <span>QC rework does not consume client rounds</span>
                </div>
              </div>
            </div>

            {/* Quick Inspection Toolbar */}
            <div className="flex items-center justify-between flex-wrap gap-2 pt-2 border-t border-slate-100">
              <div className="flex items-center gap-2">
                {onOpenCadViewer && (
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => onOpenCadViewer(targetVersion.version_number)}
                    icon={<Eye className="h-3.5 w-3.5" />}
                  >
                    Inspect in CAD Comparison Viewer
                  </Button>
                )}
                {targetVersion.file_id && (
                  <Button
                    variant="outline"
                    size="sm"
                    disabled={downloadingFileId === targetVersion.file_id}
                    onClick={() =>
                      onDownloadFile(
                        targetVersion.file_id!,
                        targetVersion.original_name || `drawing_v${targetVersion.version_number}.dwg`
                      )
                    }
                    icon={
                      downloadingFileId === targetVersion.file_id ? (
                        <Loader2 className="h-3.5 w-3.5 animate-spin" />
                      ) : (
                        <Download className="h-3.5 w-3.5" />
                      )
                    }
                  >
                    {downloadingFileId === targetVersion.file_id ? 'Downloading...' : 'Download File'}
                  </Button>
                )}
              </div>

              {/* Reference Files Pill Count */}
              {filteredReferences.length > 0 && (
                <div className="flex items-center gap-1.5 text-xs text-slate-500 font-mono">
                  <FileText className="h-3.5 w-3.5 text-slate-400" />
                  <span>{filteredReferences.length} Reference File(s) available for cross-check</span>
                </div>
              )}
            </div>

            {/* Reference Files Strip (Collapsible or visible) */}
            {filteredReferences.length > 0 && (
              <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                <span className="text-[10px] font-mono font-semibold uppercase text-slate-500 block mb-2">
                  Client Reference Files & Brief Specifications
                </span>
                <div className="flex flex-wrap gap-2">
                  {filteredReferences.map((f) => (
                    <button
                      key={f.id}
                      type="button"
                      disabled={downloadingFileId === f.id}
                      onClick={() => onDownloadFile(f.id, f.original_name || f.sanitized_name)}
                      className="inline-flex items-center gap-1.5 px-2.5 py-1.5 rounded-lg bg-white border border-slate-200 hover:border-blue-300 text-xs font-mono text-slate-700 hover:text-[#0453cd] shadow-2xs transition-colors cursor-pointer"
                    >
                      <FileText className="h-3 w-3 text-slate-400" />
                      <span className="truncate max-w-[200px]">{f.original_name || f.sanitized_name}</span>
                      <span className="text-[10px] text-slate-400">({formatFileSize(f.size)})</span>
                    </button>
                  ))}
                </div>
              </div>
            )}

            {/* 2. Decision Action Panels */}
            {isPendingReview && (
              <div className="pt-2 border-t border-slate-100">
                {activeAction === 'idle' && (
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-xl bg-slate-50 border border-slate-200">
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <h4 className="text-xs font-bold font-mono text-slate-800 uppercase tracking-wider">
                          Review Decision for Version v{targetVersion.version_number}
                        </h4>
                        <span className="text-[10px] font-mono text-slate-600 font-semibold bg-white px-2 py-0.5 rounded border border-slate-200">
                          {targetVersion.original_name || `drawing_v${targetVersion.version_number}.dwg`}
                        </span>
                      </div>
                      <p className="text-xs text-slate-600 mt-1">
                        Choose whether to approve version v{targetVersion.version_number} for Engineer review or send it back for internal Draughtsman rework.
                      </p>
                    </div>

                    <div className="flex items-center gap-2.5 shrink-0 flex-wrap sm:flex-nowrap w-full sm:w-auto">
                      <Button
                        variant="success"
                        size="md"
                        disabled={isSubmitting}
                        onClick={() => setActiveAction('approve')}
                        icon={<CheckCircle className="h-4 w-4" />}
                        className="w-full sm:w-auto"
                      >
                        Approve v{targetVersion.version_number}
                      </Button>
                      <Button
                        variant="danger"
                        size="md"
                        disabled={isSubmitting}
                        onClick={() => setActiveAction('revision')}
                        icon={<RotateCcw className="h-4 w-4" />}
                        className="w-full sm:w-auto"
                      >
                        Request Revision
                      </Button>
                    </div>
                  </div>
                )}

                {/* Approve Confirmation & Notes Panel */}
                {activeAction === 'approve' && (
                  <div className="p-4 rounded-xl bg-emerald-50/80 border border-emerald-200 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <CheckCircle className="h-4 w-4 text-emerald-700" />
                        <h4 className="text-xs font-bold font-mono text-emerald-900 uppercase">
                          Approve Drawing Deliverable v{targetVersion.version_number} ({targetVersion.original_name || 'CAD Package'})
                        </h4>
                      </div>
                      <button
                        type="button"
                        disabled={isSubmitting}
                        onClick={() => setActiveAction('idle')}
                        className="text-xs text-slate-500 hover:text-slate-800 font-mono cursor-pointer disabled:opacity-50"
                      >
                        Cancel
                      </button>
                    </div>

                    <p className="text-xs text-emerald-800">
                      Approving version <strong>v{targetVersion.version_number}</strong> will transition the project to <strong>Under Engineer Review</strong>. The client will be granted access to inspect and download this exact drawing deliverable.
                    </p>

                    <div>
                      <label className="text-[11px] font-mono font-medium text-emerald-900 block mb-1">
                        Optional Studio Quality Check Notes (Recorded in audit trail):
                      </label>
                      <textarea
                        value={approvalNotes}
                        disabled={isSubmitting}
                        onChange={(e) => setApprovalNotes(e.target.value)}
                        placeholder="e.g. Verified dimensional tolerance, municipal setbacks, and CAD layer standard compliance."
                        rows={2}
                        className="w-full text-xs p-2.5 rounded-lg border border-emerald-200 bg-white text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-emerald-500 disabled:bg-slate-100"
                      />
                    </div>

                    <div className="flex flex-col sm:flex-row items-center justify-end gap-2 pt-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        disabled={isSubmitting}
                        onClick={() => setActiveAction('idle')}
                        className="w-full sm:w-auto"
                      >
                        Back
                      </Button>
                      <Button
                        variant="success"
                        size="sm"
                        loading={isSubmitting}
                        disabled={isSubmitting}
                        onClick={handleApprove}
                        icon={<Check className="h-4 w-4" />}
                        className="w-full sm:w-auto"
                      >
                        {isSubmitting ? `Approving v${targetVersion.version_number}...` : `Approve v${targetVersion.version_number} & Release`}
                      </Button>
                    </div>
                  </div>
                )}

                {/* Request Revision Panel */}
                {activeAction === 'revision' && (
                  <div className="p-4 rounded-xl bg-rose-50/70 border border-rose-200 space-y-3">
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <RotateCcw className="h-4 w-4 text-rose-700" />
                        <h4 className="text-xs font-bold font-mono text-rose-900 uppercase">
                          Request Quality Rework on v{targetVersion.version_number} ({targetVersion.original_name || 'CAD Package'})
                        </h4>
                      </div>
                      <button
                        type="button"
                        disabled={isSubmitting}
                        onClick={() => setActiveAction('idle')}
                        className="text-xs text-slate-500 hover:text-slate-800 font-mono cursor-pointer disabled:opacity-50"
                      >
                        Cancel
                      </button>
                    </div>

                    <p className="text-xs text-rose-800">
                      Drawing version <strong>v{targetVersion.version_number}</strong> will be marked <strong>REJECTED</strong> and returned to Draughtsman in <strong>IN_PROGRESS</strong> state. This internal revision <strong>does NOT</strong> increment the Engineer&apos;s correction round count.
                    </p>

                    <div>
                      <label className="text-[11px] font-mono font-medium text-rose-900 block mb-1">
                        Quality Check Feedback & Required Corrections <span className="text-rose-600">*</span>
                      </label>
                      <textarea
                        value={revisionFeedback}
                        disabled={isSubmitting}
                        onChange={(e) => setRevisionFeedback(e.target.value)}
                        placeholder="Provide clear drafting corrections, layer standards, or missing dimensions required from the draughtsman..."
                        rows={3}
                        className="w-full text-xs p-2.5 rounded-lg border border-rose-200 bg-white text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-rose-500 disabled:bg-slate-100"
                      />
                    </div>

                    {/* Quick Cues */}
                    <div className="space-y-1">
                      <span className="text-[10px] font-mono text-slate-500 block">Quick QC Cues:</span>
                      <div className="flex flex-wrap gap-1.5">
                        {[
                          'Check layer naming standard',
                          'Verify grid dimensions & setbacks',
                          'Fix line weights and hatch scales',
                          'Include title block revision notes',
                          'Correct wall thickness annotations',
                        ].map((cue) => (
                          <button
                            key={cue}
                            type="button"
                            disabled={isSubmitting}
                            onClick={() => applyPresetFeedback(cue)}
                            className="text-[10px] font-mono px-2 py-0.5 rounded bg-white border border-rose-200 text-rose-800 hover:bg-rose-100 transition-colors cursor-pointer disabled:opacity-50"
                          >
                            + {cue}
                          </button>
                        ))}
                      </div>
                    </div>

                    <div className="flex flex-col sm:flex-row items-center justify-end gap-2 pt-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        disabled={isSubmitting}
                        onClick={() => setActiveAction('idle')}
                        className="w-full sm:w-auto"
                      >
                        Back
                      </Button>
                      <Button
                        variant="danger"
                        size="sm"
                        loading={isSubmitting}
                        disabled={isSubmitting || !revisionFeedback.trim()}
                        onClick={handleRequestRevision}
                        icon={<RotateCcw className="h-4 w-4" />}
                        className="w-full sm:w-auto"
                      >
                        {isSubmitting ? `Submitting v${targetVersion.version_number} Revision...` : `Submit v${targetVersion.version_number} Revision Request`}
                      </Button>
                    </div>
                  </div>
                )}
              </div>
            )}
          </div>
        ) : (
          <div className="p-8 text-center space-y-3">
            <div className="mx-auto w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
              <CheckCircle className="h-6 w-6 text-emerald-600" />
            </div>
            <div className="space-y-1">
              <h4 className="text-sm font-bold font-mono text-slate-800 uppercase tracking-wider">
                No Drawings Awaiting Studio QC
              </h4>
              <p className="text-xs text-slate-500 max-w-md mx-auto">
                No deliverables are currently in the Studio QC queue. When the draughtsman submits or resubmits a CAD version, it will appear here for quality inspection.
              </p>
            </div>
            <div className="pt-2">
              <Button
                variant="outline"
                size="sm"
                onClick={onDecisionSuccess}
                icon={<RotateCcw className="h-3.5 w-3.5" />}
              >
                Check for New Submissions
              </Button>
            </div>
          </div>
        )}
      </Card>

      {/* 3. Review History & Audit Trail */}
      {reviews.length > 0 && (
        <Card className="bg-white border-slate-200 soft-elevation">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2">
              <History className="h-4 w-4 text-slate-500" />
              <h4 className="text-xs font-bold font-mono text-slate-900 uppercase tracking-wider">
                Studio Quality Review History ({reviews.length})
              </h4>
            </div>
            <span className="text-[10px] font-mono text-slate-400">
              Immutable audit trail recorded in Cloudflare D1
            </span>
          </div>

          <div className="divide-y divide-slate-100 mt-2">
            {reviews.map((rev) => (
              <div key={rev.id} className="py-3 flex flex-col sm:flex-row sm:items-start justify-between gap-2">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <Badge
                      variant={rev.decision === 'APPROVED' ? 'success' : 'danger'}
                      size="sm"
                    >
                      {rev.decision === 'APPROVED' ? 'APPROVED' : 'REVISION REQUESTED'}
                    </Badge>
                    {rev.version_number && (
                      <span className="text-xs font-mono font-bold text-slate-800">
                        v{rev.version_number}
                      </span>
                    )}
                    {rev.reviewer_name ? (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-mono bg-slate-100 text-slate-700 font-semibold border border-slate-200">
                        <User className="h-2.5 w-2.5 text-slate-500" />
                        Actor: {rev.reviewer_name}{rev.reviewer_role ? ` (${rev.reviewer_role})` : ''}
                      </span>
                    ) : (
                      <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded text-[10px] font-mono bg-slate-100 text-slate-500 font-normal border border-slate-200">
                        <User className="h-2.5 w-2.5 text-slate-400" />
                        Actor unavailable
                      </span>
                    )}
                  </div>
                  {rev.feedback && (
                    <p className="text-xs text-slate-700 bg-slate-50 p-2.5 rounded-lg border border-slate-100 mt-1 whitespace-pre-wrap">
                      {rev.feedback}
                    </p>
                  )}
                </div>

                <span className="text-[10px] font-mono text-slate-400 shrink-0">
                  {formatDateTime(rev.created_at)}
                </span>
              </div>
            ))}
          </div>
        </Card>
      )}
    </div>
  );
}


'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { AlertTriangle, CheckCircle2 } from 'lucide-react';

export type LegalReviewType =
  | 'DELETION'
  | 'EXPORT'
  | 'CORRECTION'
  | 'GUARDIAN'
  | 'REFUND'
  | 'GRIEVANCE';

interface ReviewActionModalProps {
  isOpen: boolean;
  onClose: () => void;
  reviewType: LegalReviewType | null;
  item: any;
  onSubmit: (payload: any) => Promise<void>;
}

export function ReviewActionModal({
  isOpen,
  onClose,
  reviewType,
  item,
  onSubmit,
}: ReviewActionModalProps) {
  const [status, setStatus] = useState<string>('');
  const [reviewNotes, setReviewNotes] = useState<string>('');
  const [retentionHoldReason, setRetentionHoldReason] = useState<string>('');
  const [failureDetails, setFailureDetails] = useState<string>('');
  const [applyToUser, setApplyToUser] = useState<boolean>(true);
  const [amountApproved, setAmountApproved] = useState<string>('');
  const [refundTransactionRef, setRefundTransactionRef] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Initialize status on open
  React.useEffect(() => {
    if (item && isOpen) {
      if (reviewType === 'DELETION') setStatus(item.status || 'UNDER_REVIEW');
      else if (reviewType === 'EXPORT') setStatus(item.status || 'PROCESSING');
      else if (reviewType === 'CORRECTION') setStatus(item.status || 'RESOLVED');
      else if (reviewType === 'GUARDIAN') setStatus(item.verification_status || 'VERIFIED');
      else if (reviewType === 'REFUND') {
        setStatus(item.status || 'APPROVED');
        setAmountApproved(item.amount_requested ? String(item.amount_requested) : '');
      } else if (reviewType === 'GRIEVANCE') setStatus(item.status || 'RESOLVED');
      setReviewNotes('');
      setError(null);
    }
  }, [item, isOpen, reviewType]);

  if (!item || !reviewType) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      let payload: any = { status };

      if (reviewType === 'DELETION') {
        payload = {
          status,
          reviewNotes: reviewNotes.trim() || undefined,
          retentionHoldReason: retentionHoldReason.trim() || undefined,
          failureDetails: failureDetails.trim() || undefined,
        };
      } else if (reviewType === 'EXPORT') {
        payload = {
          status,
          failureDetails: failureDetails.trim() || undefined,
        };
      } else if (reviewType === 'CORRECTION') {
        payload = {
          status,
          reviewNotes: reviewNotes.trim() || undefined,
          applyToUser,
        };
      } else if (reviewType === 'GUARDIAN') {
        payload = {
          status,
          notes: reviewNotes.trim() || undefined,
        };
      } else if (reviewType === 'REFUND') {
        payload = {
          status,
          amountApproved: amountApproved ? Number(amountApproved) : undefined,
          reviewDecision: reviewNotes.trim() || undefined,
          resolutionNotes: reviewNotes.trim() || undefined,
          refundTransactionRef: refundTransactionRef.trim() || undefined,
        };
      } else if (reviewType === 'GRIEVANCE') {
        payload = {
          status,
          resolutionNotes: reviewNotes.trim() || undefined,
        };
      }

      await onSubmit(payload);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to submit review decision.');
    } finally {
      setIsSubmitting(false);
    }
  };

  const getTitle = () => {
    switch (reviewType) {
      case 'DELETION':
        return 'Review Account Deletion Request';
      case 'EXPORT':
        return 'Update Data Export Status';
      case 'CORRECTION':
        return 'Review Profile Data Rectification';
      case 'GUARDIAN':
        return 'Verify Student Guardian Consent';
      case 'REFUND':
        return 'Review Milestone Refund Request';
      case 'GRIEVANCE':
        return 'Resolve Statutory Grievance Ticket';
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={getTitle()}
      description={`Target Request ID: ${item.id} • ${item.user_email || item.student_email || ''}`}
      maxWidth="lg"
    >
      <form onSubmit={handleSubmit} className="space-y-4 text-xs select-none">
        {error && (
          <div className="bg-rose-50 border border-rose-200 text-rose-800 p-3 rounded-lg flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {/* ── Summary Card ── */}
        <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 text-slate-700 space-y-1 font-mono text-[11px]">
          <div><span className="text-slate-400">Target User:</span> <span className="font-bold">{item.user_name || item.student_name || 'Account Holder'}</span></div>
          <div><span className="text-slate-400">Email:</span> <span>{item.user_email || item.student_email || '—'}</span></div>
          {reviewType === 'CORRECTION' && (
            <div>
              <span className="text-slate-400">Field:</span> <span className="font-bold text-amber-800">{item.field_name}</span> &rarr; <span className="font-bold text-emerald-700">{item.proposed_value}</span>
            </div>
          )}
          {reviewType === 'GUARDIAN' && (
            <div>
              <span className="text-slate-400">Guardian:</span> <span className="font-bold">{item.guardian_name}</span> ({item.relationship})
            </div>
          )}
          {reviewType === 'REFUND' && (
            <div>
              <span className="text-slate-400">Requested:</span> <span className="font-bold text-slate-900">₹{item.amount_requested?.toLocaleString('en-IN') || 'Milestone'}</span>
            </div>
          )}
        </div>

        {/* ── Status Dropdown ── */}
        <div>
          <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
            Decision / Target Status
          </label>
          <select
            value={status}
            onChange={(e) => setStatus(e.target.value)}
            className="w-full font-mono bg-slate-50 border border-slate-200 rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          >
            {reviewType === 'DELETION' && (
              <>
                <option value="UNDER_REVIEW">UNDER_REVIEW</option>
                <option value="IDENTITY_VERIFICATION_REQUIRED">IDENTITY_VERIFICATION_REQUIRED</option>
                <option value="VERIFIED">VERIFIED</option>
                <option value="DELETION_SCHEDULED">DELETION_SCHEDULED</option>
                <option value="PROCESSING">PROCESSING</option>
                <option value="PARTIALLY_COMPLETED">PARTIALLY_COMPLETED</option>
                <option value="COMPLETED">COMPLETED (Anonymize & Purge AI Chats)</option>
                <option value="REJECTED_WITH_REASON">REJECTED_WITH_REASON</option>
              </>
            )}
            {reviewType === 'EXPORT' && (
              <>
                <option value="PROCESSING">PROCESSING</option>
                <option value="COMPLETED">COMPLETED</option>
                <option value="FAILED">FAILED</option>
              </>
            )}
            {reviewType === 'CORRECTION' && (
              <>
                <option value="RESOLVED">RESOLVED (Approve Rectification)</option>
                <option value="REJECTED">REJECTED</option>
              </>
            )}
            {reviewType === 'GUARDIAN' && (
              <>
                <option value="VERIFIED">VERIFIED (Approve Parental Declaration)</option>
                <option value="REJECTED">REJECTED</option>
                <option value="WITHDRAWN">WITHDRAWN</option>
                <option value="EXPIRED">EXPIRED</option>
              </>
            )}
            {reviewType === 'REFUND' && (
              <>
                <option value="UNDER_REVIEW">UNDER_REVIEW</option>
                <option value="APPROVED">APPROVED</option>
                <option value="PROCESSED">PROCESSED</option>
                <option value="REJECTED">REJECTED</option>
              </>
            )}
            {reviewType === 'GRIEVANCE' && (
              <>
                <option value="ACKNOWLEDGED">ACKNOWLEDGED (48h Intake)</option>
                <option value="RESOLVED">RESOLVED</option>
                <option value="REJECTED">REJECTED</option>
              </>
            )}
          </select>
        </div>

        {/* ── Type Specific Extra Inputs ── */}
        {reviewType === 'CORRECTION' && status === 'RESOLVED' && (
          <div className="flex items-center gap-2 pt-1">
            <input
              type="checkbox"
              id="applyToUser"
              checked={applyToUser}
              onChange={(e) => setApplyToUser(e.target.checked)}
              className="rounded border-slate-300 text-[#0453cd] focus:ring-[#0453cd]"
            />
            <label htmlFor="applyToUser" className="text-slate-700 font-medium">
              Atomically apply proposed value to user profile record in D1
            </label>
          </div>
        )}

        {reviewType === 'REFUND' && (
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
                Amount Approved (₹)
              </label>
              <input
                type="number"
                value={amountApproved}
                onChange={(e) => setAmountApproved(e.target.value)}
                placeholder="Approved INR"
                className="w-full font-mono bg-slate-50 border border-slate-200 rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>
            <div>
              <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
                Transaction Ref
              </label>
              <input
                type="text"
                value={refundTransactionRef}
                onChange={(e) => setRefundTransactionRef(e.target.value)}
                placeholder="TXN-REF / Offline"
                className="w-full font-mono bg-slate-50 border border-slate-200 rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>
          </div>
        )}

        {reviewType === 'DELETION' && status === 'COMPLETED' && (
          <div className="bg-amber-50 border border-amber-200 p-3 rounded-lg text-amber-900 leading-relaxed text-[11px]">
            <strong className="block mb-0.5">Tombstone & AI Chat Purge Protocol:</strong>
            User profile will be renamed to "Deleted User" and marked SUSPENDED in D1. PIXMINT BOT chats will be wiped. Collaborative CAD files and CERT-In 180-day access logs will be preserved.
          </div>
        )}

        {/* ── Reviewer Notes ── */}
        <div>
          <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
            Reviewer Notes / Justification
          </label>
          <textarea
            rows={3}
            placeholder="Official administrative review justification (persisted for regulatory audit inspection)..."
            value={reviewNotes}
            onChange={(e) => setReviewNotes(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 rounded-lg p-2.5 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>

        <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
          <Button variant="outline" size="sm" type="button" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button variant="primary" size="sm" type="submit" loading={isSubmitting}>
            Submit Decision
          </Button>
        </div>
      </form>
    </Modal>
  );
}

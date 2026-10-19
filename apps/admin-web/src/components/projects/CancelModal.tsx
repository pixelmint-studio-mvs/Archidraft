'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { AlertTriangle, AlertCircle } from 'lucide-react';

interface CancelModalProps {
  isOpen: boolean;
  onClose: () => void;
  projectId: string;
  projectName: string;
  onSuccess: () => void;
}

export function CancelModal({
  isOpen,
  onClose,
  projectId,
  projectName,
  onSuccess,
}: CancelModalProps) {
  const [reason, setReason] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    try {
      await adminApi.cancelProject(projectId, reason.trim() || 'Cancelled by Studio Admin');
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to cancel project');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Cancel Project"
      description={`Are you sure you want to cancel "${projectName}"? This action stops all active drafting assignments.`}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="flex items-center gap-2 p-3 text-xs text-rose-400 bg-rose-500/10 border border-rose-500/20 rounded-lg">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <div className="p-3 bg-amber-500/10 border border-amber-500/20 rounded-xl text-xs text-amber-300 flex items-start gap-2.5">
          <AlertTriangle className="h-4 w-4 text-amber-400 shrink-0 mt-0.5" />
          <span>
            Cancelling will terminate any active assignments and record an immutable cancellation log entry. Completed projects cannot be cancelled.
          </span>
        </div>

        <div>
          <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
            Cancellation Note
          </label>
          <textarea
            rows={3}
            value={reason}
            onChange={(e) => setReason(e.target.value)}
            placeholder="Administrative note or cancellation rationale..."
            className="w-full px-3.5 py-2.5 rounded-xl bg-slate-900 border border-slate-700/80 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-rose-500 focus:border-rose-500 transition-all"
          />
        </div>

        <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
          <Button variant="ghost" size="sm" type="button" onClick={onClose} disabled={loading}>
            Dismiss
          </Button>
          <Button
            variant="danger"
            size="sm"
            type="submit"
            loading={loading}
            icon={<AlertTriangle className="h-4 w-4" />}
          >
            Confirm Project Cancellation
          </Button>
        </div>
      </form>
    </Modal>
  );
}

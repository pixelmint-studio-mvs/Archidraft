'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { LegalDocumentAdmin } from '@/lib/types';
import { CheckCircle2, AlertTriangle, ShieldCheck } from 'lucide-react';

interface PublishDocumentModalProps {
  isOpen: boolean;
  onClose: () => void;
  document: LegalDocumentAdmin | null;
  onConfirmPublish: (id: string) => Promise<void>;
}

export function PublishDocumentModal({
  isOpen,
  onClose,
  document,
  onConfirmPublish,
}: PublishDocumentModalProps) {
  const [isPublishing, setIsPublishing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  if (!document) return null;

  const handlePublish = async () => {
    setError(null);
    setIsPublishing(true);
    try {
      await onConfirmPublish(document.id);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to publish legal document.');
    } finally {
      setIsPublishing(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Confirm Legal Document Publication"
      description="Statutory publication safeguard & atomic promotion protocol"
      maxWidth="md"
    >
      <div className="space-y-4 text-xs select-none">
        {error && (
          <div className="bg-rose-50 border border-rose-200 text-rose-800 p-3 rounded-lg flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <div className="bg-amber-50 border border-amber-200 p-4 rounded-xl text-amber-900 space-y-2">
          <div className="flex items-center gap-2 font-bold font-mono">
            <AlertTriangle className="h-4 w-4 text-amber-700" />
            <span>Atomic State Transition Safeguard</span>
          </div>
          <p className="leading-relaxed">
            Publishing <strong className="font-mono">{document.title} (v{document.version})</strong> will immediately transition its status to <strong className="text-emerald-800 font-mono">EFFECTIVE</strong>.
            Any prior effective version of this category ({document.document_type}) will be atomically marked <strong className="text-slate-800 font-mono">SUPERSEDED</strong>.
          </p>
        </div>

        <div className="bg-slate-50 p-3.5 rounded-xl border border-slate-200 space-y-1 font-mono text-[11px]">
          <div><span className="text-slate-400">ID:</span> <span className="text-slate-800 font-bold">{document.id}</span></div>
          <div><span className="text-slate-400">Category:</span> <span className="text-slate-800 font-bold">{document.document_type}</span></div>
          <div><span className="text-slate-400">Target Version:</span> <span className="text-emerald-700 font-bold">v{document.version}</span></div>
        </div>

        <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
          <Button variant="outline" size="sm" onClick={onClose} disabled={isPublishing}>
            Cancel
          </Button>
          <Button
            variant="secondary"
            size="sm"
            onClick={handlePublish}
            loading={isPublishing}
            className="bg-emerald-600 hover:bg-emerald-700 text-white font-mono"
          >
            <CheckCircle2 className="h-3.5 w-3.5 mr-1" /> Confirm Publication
          </Button>
        </div>
      </div>
    </Modal>
  );
}

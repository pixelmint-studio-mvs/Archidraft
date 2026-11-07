'use client';

import React from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { LegalDocumentAdmin } from '@/lib/types';
import { FileText, CheckCircle2, AlertTriangle, ShieldCheck } from 'lucide-react';

interface DocumentReaderModalProps {
  isOpen: boolean;
  onClose: () => void;
  document: LegalDocumentAdmin | null;
  onPublish?: (doc: LegalDocumentAdmin) => void;
}

export function DocumentReaderModal({
  isOpen,
  onClose,
  document,
  onPublish,
}: DocumentReaderModalProps) {
  if (!document) return null;

  const isDraft = document.status === 'DRAFT' || document.status === 'UNDER_REVIEW' || document.status === 'PENDING_LEGAL_REVIEW';

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={document.title}
      description={`${document.document_type} • Version ${document.version} • Status: ${document.status}`}
      maxWidth="4xl"
    >
      <div className="space-y-4">
        {/* ── Metadata Header ── */}
        <div className="bg-slate-50 p-4 rounded-xl border border-slate-200 grid grid-cols-2 sm:grid-cols-4 gap-3 text-xs">
          <div>
            <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Instrument ID</span>
            <p className="font-mono text-slate-800 font-semibold mt-0.5 truncate">{document.id}</p>
          </div>
          <div>
            <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Version</span>
            <p className="font-mono text-slate-800 font-bold mt-0.5">v{document.version}</p>
          </div>
          <div>
            <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Requirement</span>
            <p className="font-mono text-slate-800 font-semibold mt-0.5">
              {document.is_mandatory ? 'MANDATORY' : 'OPTIONAL'}
            </p>
          </div>
          <div>
            <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Effective Date</span>
            <p className="font-mono text-slate-800 mt-0.5">
              {document.effective_at ? document.effective_at.slice(0, 10) : 'PENDING'}
            </p>
          </div>
        </div>

        {document.change_summary && (
          <div className="bg-blue-50/60 p-3 rounded-lg border border-blue-200/60 text-xs text-blue-900">
            <span className="font-mono font-bold uppercase text-[10px] text-blue-700 block mb-0.5">
              Change Summary
            </span>
            {document.change_summary}
          </div>
        )}

        {/* ── Content Preview ── */}
        <div className="bg-white p-5 rounded-xl border border-slate-200 max-h-[500px] overflow-y-auto font-sans text-xs leading-relaxed text-slate-800 whitespace-pre-wrap font-mono">
          {document.content || (
            <div className="text-center py-10 text-slate-400 italic">
              Full markdown body stored on server / canonical file registry.
            </div>
          )}
        </div>

        {/* ── Actions ── */}
        <div className="flex items-center justify-between pt-3 border-t border-slate-100">
          <Button variant="outline" size="sm" onClick={onClose} className="font-mono text-xs">
            Close
          </Button>
          {isDraft && onPublish && (
            <Button
              variant="secondary"
              size="sm"
              onClick={() => {
                onClose();
                onPublish(document);
              }}
              className="bg-emerald-600 hover:bg-emerald-700 text-white font-mono text-xs"
            >
              <CheckCircle2 className="h-3.5 w-3.5 mr-1" /> Proceed to Publish
            </Button>
          )}
        </div>
      </div>
    </Modal>
  );
}

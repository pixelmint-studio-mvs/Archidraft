'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Plus, AlertTriangle, FileText } from 'lucide-react';

interface DocumentDraftModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSubmit: (payload: {
    documentType: string;
    version: string;
    title: string;
    content: string;
    isMandatory?: boolean;
    changeSummary?: string;
  }) => Promise<void>;
}

export function DocumentDraftModal({ isOpen, onClose, onSubmit }: DocumentDraftModalProps) {
  const [documentType, setDocumentType] = useState<string>('TERMS_AND_CONDITIONS');
  const [version, setVersion] = useState<string>('1.1.0');
  const [title, setTitle] = useState<string>('');
  const [content, setContent] = useState<string>('');
  const [isMandatory, setIsMandatory] = useState<boolean>(true);
  const [changeSummary, setChangeSummary] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!title.trim() || !version.trim() || !content.trim()) {
      setError('Title, version, and content are mandatory.');
      return;
    }
    setError(null);
    setIsSubmitting(true);
    try {
      await onSubmit({
        documentType,
        version: version.trim(),
        title: title.trim(),
        content: content.trim(),
        isMandatory,
        changeSummary: changeSummary.trim() || undefined,
      });
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to create document draft.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Draft New Canonical Policy Version"
      description="Creates an isolated draft version in D1 without affecting current active effective documents"
      maxWidth="2xl"
    >
      <form onSubmit={handleSubmit} className="space-y-4 text-xs select-none">
        {error && (
          <div className="bg-rose-50 border border-rose-200 text-rose-800 p-3 rounded-lg flex items-center gap-2">
            <AlertTriangle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <div>
            <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
              Document Category
            </label>
            <select
              value={documentType}
              onChange={(e) => setDocumentType(e.target.value)}
              className="w-full font-mono bg-slate-50 border border-slate-200 rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            >
              <option value="TERMS_AND_CONDITIONS">Terms and Conditions</option>
              <option value="PRIVACY_POLICY">Privacy Policy</option>
              <option value="AI_USAGE_DISCLAIMER">AI Usage Disclaimer</option>
              <option value="ENGINEERING_DISCLAIMER">Engineering Disclaimer</option>
              <option value="CAD_OWNERSHIP_FRAMEWORK">CAD Ownership Framework</option>
              <option value="REVISION_POLICY">Revision Policy</option>
              <option value="CANCELLATION_REFUND_POLICY">Cancellation & Refund Policy</option>
            </select>
          </div>

          <div>
            <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
              Semantic Version (SemVer)
            </label>
            <input
              type="text"
              placeholder="e.g. 1.1.0"
              value={version}
              onChange={(e) => setVersion(e.target.value)}
              className="w-full font-mono bg-slate-50 border border-slate-200 rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            />
          </div>
        </div>

        <div>
          <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
            Document Title
          </label>
          <input
            type="text"
            placeholder="e.g. Archi Draft Platform Terms & Conditions"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>

        <div>
          <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
            Change Summary
          </label>
          <input
            type="text"
            placeholder="Summary of amendments for regulatory audit trails"
            value={changeSummary}
            onChange={(e) => setChangeSummary(e.target.value)}
            className="w-full bg-slate-50 border border-slate-200 rounded-lg p-2 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>

        <div className="flex items-center gap-2 pt-1">
          <input
            type="checkbox"
            id="isMandatory"
            checked={isMandatory}
            onChange={(e) => setIsMandatory(e.target.checked)}
            className="rounded border-slate-300 text-[#0453cd] focus:ring-[#0453cd]"
          />
          <label htmlFor="isMandatory" className="text-slate-700 font-medium">
            Mandatory unbundled consent required before dashboard access
          </label>
        </div>

        <div>
          <label className="font-mono uppercase text-[10px] text-slate-500 font-semibold block mb-1">
            Full Markdown Content
          </label>
          <textarea
            rows={10}
            placeholder="# Document Heading&#10;&#10;Policy text..."
            value={content}
            onChange={(e) => setContent(e.target.value)}
            className="w-full font-mono text-xs bg-slate-50 border border-slate-200 rounded-lg p-3 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>

        <div className="flex items-center justify-end gap-2 pt-3 border-t border-slate-100">
          <Button variant="outline" size="sm" type="button" onClick={onClose} disabled={isSubmitting}>
            Cancel
          </Button>
          <Button variant="primary" size="sm" type="submit" loading={isSubmitting} icon={<Plus className="h-3.5 w-3.5" />}>
            Create Draft Version
          </Button>
        </div>
      </form>
    </Modal>
  );
}

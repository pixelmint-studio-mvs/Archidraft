'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { LegalDocumentAdmin } from '@/lib/types';
import {
  FileText,
  Plus,
  Eye,
  CheckCircle,
  AlertTriangle,
  Clock,
  Shield,
  Layers,
  Search,
  Filter,
} from 'lucide-react';

interface DocumentRegistryTabProps {
  documents: LegalDocumentAdmin[];
  loading: boolean;
  onViewDoc: (doc: LegalDocumentAdmin) => void;
  onCreateDraft: () => void;
  onPublishDoc: (doc: LegalDocumentAdmin) => void;
}

export function DocumentRegistryTab({
  documents,
  loading,
  onViewDoc,
  onCreateDraft,
  onPublishDoc,
}: DocumentRegistryTabProps) {
  const [filterType, setFilterType] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const filteredDocs = documents.filter((doc) => {
    if (filterType !== 'ALL' && doc.document_type !== filterType) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        doc.title.toLowerCase().includes(q) ||
        doc.document_type.toLowerCase().includes(q) ||
        doc.version.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <div className="space-y-6 select-none">
      {/* ── Header Controls ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-base font-bold text-slate-900 font-mono">Canonical Policy Registry</h3>
          <p className="text-xs text-slate-500">
            Lifecycle governance, publication safeguards, and version manifests across 7 canonical instruments
          </p>
        </div>
        <Button
          variant="primary"
          size="sm"
          onClick={onCreateDraft}
          icon={<Plus className="h-4 w-4" />}
          className="font-mono text-xs shrink-0"
        >
          Draft New Policy Version
        </Button>
      </div>

      {/* ── Filters & Search ── */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white p-3 rounded-xl border border-slate-200">
        <div className="relative w-full sm:w-72">
          <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search instruments, versions..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
          <span className="text-xs text-slate-400 font-mono flex items-center gap-1 shrink-0">
            <Filter className="h-3 w-3" /> Filter:
          </span>
          <select
            value={filterType}
            onChange={(e) => setFilterType(e.target.value)}
            className="text-xs font-mono bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          >
            <option value="ALL">All Categories</option>
            <option value="TERMS_AND_CONDITIONS">Terms & Conditions</option>
            <option value="PRIVACY_POLICY">Privacy Policy</option>
            <option value="AI_USAGE_DISCLAIMER">AI Usage Disclaimer</option>
            <option value="ENGINEERING_DISCLAIMER">Engineering Disclaimer</option>
            <option value="CAD_OWNERSHIP_FRAMEWORK">CAD Ownership</option>
            <option value="REVISION_POLICY">Revision Policy</option>
            <option value="CANCELLATION_REFUND_POLICY">Cancellation & Refund</option>
          </select>
        </div>
      </div>

      {/* ── Document Table ── */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono uppercase text-[10px]">
                <th className="py-3 px-4 font-semibold">Instrument & Title</th>
                <th className="py-3 px-4 font-semibold">Category</th>
                <th className="py-3 px-4 font-semibold">Version</th>
                <th className="py-3 px-4 font-semibold">Status</th>
                <th className="py-3 px-4 font-semibold">Requirement</th>
                <th className="py-3 px-4 font-semibold">Effective Date</th>
                <th className="py-3 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center gap-2">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent" />
                      <span className="font-mono text-xs">Loading legal instruments...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredDocs.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400 font-mono text-xs">
                    No legal documents matching current filter.
                  </td>
                </tr>
              ) : (
                filteredDocs.map((doc) => {
                  const isEffective = doc.status === 'EFFECTIVE' || doc.status === 'PUBLISHED';
                  const isDraft = doc.status === 'DRAFT' || doc.status === 'UNDER_REVIEW' || doc.status === 'PENDING_LEGAL_REVIEW';

                  return (
                    <tr key={doc.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3.5 px-4 font-medium text-slate-900 max-w-xs">
                        <div className="font-bold truncate">{doc.title}</div>
                        {doc.change_summary && (
                          <div className="text-[10px] text-slate-400 truncate mt-0.5 font-normal">
                            {doc.change_summary}
                          </div>
                        )}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-[11px] text-slate-600">
                        {doc.document_type}
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-slate-800">
                        v{doc.version}
                      </td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase ${
                            isEffective
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                              : doc.status === 'SUPERSEDED'
                              ? 'bg-slate-100 text-slate-600 border border-slate-200'
                              : 'bg-amber-100 text-amber-800 border border-amber-300'
                          }`}
                        >
                          {doc.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4">
                        {doc.is_mandatory ? (
                          <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-blue-50 text-blue-700 font-bold border border-blue-200">
                            MANDATORY
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-slate-100 text-slate-600 border border-slate-200">
                            OPTIONAL
                          </span>
                        )}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-600 text-[11px]">
                        {doc.effective_at ? doc.effective_at.slice(0, 10) : 'PENDING'}
                      </td>
                      <td className="py-3.5 px-4 text-right space-x-2">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => onViewDoc(doc)}
                          className="h-7 text-xs font-mono"
                        >
                          <Eye className="h-3.5 w-3.5 mr-1" /> View
                        </Button>
                        {isDraft && (
                          <Button
                            variant="secondary"
                            size="sm"
                            onClick={() => onPublishDoc(doc)}
                            className="h-7 text-xs font-mono bg-emerald-600 hover:bg-emerald-700 text-white"
                          >
                            <CheckCircle className="h-3.5 w-3.5 mr-1" /> Publish
                          </Button>
                        )}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}

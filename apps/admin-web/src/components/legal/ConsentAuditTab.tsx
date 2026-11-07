'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { AdminConsentEvent } from '@/lib/types';
import {
  ShieldCheck,
  Search,
  Filter,
  Calendar,
  AlertCircle,
  CheckCircle2,
  XCircle,
  Hash,
  ChevronLeft,
  ChevronRight,
} from 'lucide-react';

interface ConsentAuditTabProps {
  events: AdminConsentEvent[];
  loading: boolean;
  onRefresh: () => void;
}

export function ConsentAuditTab({ events, loading, onRefresh }: ConsentAuditTabProps) {
  const [filterAction, setFilterAction] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [page, setPage] = useState<number>(0);
  const pageSize = 15;

  const filteredEvents = events.filter((ev) => {
    if (filterAction !== 'ALL' && ev.action_type !== filterAction) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        ev.user_id.toLowerCase().includes(q) ||
        ev.document_type.toLowerCase().includes(q) ||
        ev.document_version.toLowerCase().includes(q) ||
        (ev.ip_hash && ev.ip_hash.toLowerCase().includes(q))
      );
    }
    return true;
  });

  const totalPages = Math.ceil(filteredEvents.length / pageSize) || 1;
  const paginatedEvents = filteredEvents.slice(page * pageSize, (page + 1) * pageSize);

  return (
    <div className="space-y-6 select-none">
      {/* ── Section Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-base font-bold text-slate-900 font-mono">Regulatory Consent Audit Ledger</h3>
          <p className="text-xs text-slate-500">
            Immutable regulatory event ledger tracking affirmative consent and voluntary withdrawals
          </p>
        </div>
        <span className="text-xs font-mono text-slate-500 bg-slate-100 px-3 py-1.5 rounded-lg border border-slate-200">
          Total Logged: <strong className="text-slate-900">{events.length}</strong> Events
        </span>
      </div>

      {/* ── Search & Filters ── */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white p-3 rounded-xl border border-slate-200">
        <div className="relative w-full sm:w-80">
          <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search User ID, IP Hash, Document..."
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setPage(0);
            }}
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
          <span className="text-xs text-slate-400 font-mono flex items-center gap-1 shrink-0">
            <Filter className="h-3 w-3" /> Action:
          </span>
          <select
            value={filterAction}
            onChange={(e) => {
              setFilterAction(e.target.value);
              setPage(0);
            }}
            className="text-xs font-mono bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          >
            <option value="ALL">All Event Types</option>
            <option value="TERMS_ACCEPTED">Terms Accepted</option>
            <option value="PRIVACY_ACKNOWLEDGED">Privacy Acknowledged</option>
            <option value="OPTIONAL_MARKETING_CONSENTED">Marketing Consented</option>
            <option value="OPTIONAL_TELEMETRY_CONSENTED">Telemetry Consented</option>
            <option value="OPTIONAL_CONSENT_WITHDRAWN">Consent Withdrawn</option>
          </select>
        </div>
      </div>

      {/* ── Ledger Table ── */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono uppercase text-[10px]">
                <th className="py-3 px-4 font-semibold">User ID</th>
                <th className="py-3 px-4 font-semibold">Action / Event</th>
                <th className="py-3 px-4 font-semibold">Document & Version</th>
                <th className="py-3 px-4 font-semibold">Purpose</th>
                <th className="py-3 px-4 font-semibold">IP Hash (SHA-256)</th>
                <th className="py-3 px-4 font-semibold">Source</th>
                <th className="py-3 px-4 font-semibold text-right">Timestamp (UTC)</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center gap-2">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent" />
                      <span className="font-mono text-xs">Loading consent events...</span>
                    </div>
                  </td>
                </tr>
              ) : paginatedEvents.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400 font-mono text-xs">
                    No consent events matching criteria.
                  </td>
                </tr>
              ) : (
                paginatedEvents.map((ev) => {
                  const isWithdrawn = ev.action_type.includes('WITHDRAWN');
                  const isTerms = ev.action_type === 'TERMS_ACCEPTED';

                  return (
                    <tr key={ev.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3 px-4 font-mono text-slate-800 text-[11px] truncate max-w-[120px]">
                        {ev.user_id}
                      </td>
                      <td className="py-3 px-4">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase inline-flex items-center gap-1 ${
                            isWithdrawn
                              ? 'bg-rose-100 text-rose-800 border border-rose-300'
                              : isTerms
                              ? 'bg-blue-100 text-blue-800 border border-blue-300'
                              : 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                          }`}
                        >
                          {isWithdrawn ? <XCircle className="h-2.5 w-2.5" /> : <CheckCircle2 className="h-2.5 w-2.5" />}
                          {ev.action_type}
                        </span>
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-700">
                        {ev.document_type} <span className="font-bold">v{ev.document_version}</span>
                      </td>
                      <td className="py-3 px-4 text-slate-600 max-w-xs truncate">
                        {ev.consent_purpose}
                      </td>
                      <td className="py-3 px-4 font-mono text-[10px] text-slate-400 truncate max-w-[120px]">
                        {ev.ip_hash || 'SHA256_ANONYMIZED'}
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-500 uppercase text-[10px]">
                        {ev.source}
                      </td>
                      <td className="py-3 px-4 font-mono text-slate-600 text-[11px] text-right">
                        {ev.recorded_at ? ev.recorded_at.replace('T', ' ').slice(0, 19) : '—'}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>

        {/* ── Pagination ── */}
        <div className="p-3 bg-slate-50/70 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500 font-mono">
          <span>
            Page {page + 1} of {totalPages} ({filteredEvents.length} records)
          </span>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              disabled={page === 0}
              onClick={() => setPage((p) => Math.max(0, p - 1))}
              className="h-7 text-xs font-mono"
            >
              <ChevronLeft className="h-3 w-3 mr-1" /> Previous
            </Button>
            <Button
              variant="outline"
              size="sm"
              disabled={page >= totalPages - 1}
              onClick={() => setPage((p) => p + 1)}
              className="h-7 text-xs font-mono"
            >
              Next <ChevronRight className="h-3 w-3 ml-1" />
            </Button>
          </div>
        </div>
      </div>
    </div>
  );
}

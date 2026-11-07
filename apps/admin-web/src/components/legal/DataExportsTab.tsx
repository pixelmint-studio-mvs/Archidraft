'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { AdminDataExportRequest } from '@/lib/types';
import {
  DownloadCloud,
  Search,
  Filter,
  Clock,
  CheckCircle2,
  XCircle,
  Eye,
  Shield,
  FileArchive,
} from 'lucide-react';

interface DataExportsTabProps {
  requests: AdminDataExportRequest[];
  loading: boolean;
  onReviewRequest: (req: AdminDataExportRequest) => void;
}

export function DataExportsTab({ requests, loading, onReviewRequest }: DataExportsTabProps) {
  const [filterScope, setFilterScope] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const filteredRequests = requests.filter((req) => {
    if (filterScope !== 'ALL' && req.export_scope !== filterScope) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        (req.user_name && req.user_name.toLowerCase().includes(q)) ||
        (req.user_email && req.user_email.toLowerCase().includes(q)) ||
        req.id.toLowerCase().includes(q)
      );
    }
    return true;
  });

  return (
    <div className="space-y-6 select-none">
      {/* ── Section Header ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h3 className="text-base font-bold text-slate-900 font-mono">Personal Data Export Archive Queue</h3>
          <p className="text-xs text-slate-500">
            Section 11 DPDP Act machine-readable archives with strict 7-day download token expiration
          </p>
        </div>
        <span className="text-xs font-mono text-slate-500 bg-slate-100 px-3 py-1.5 rounded-lg border border-slate-200">
          Total Export Requests: <strong className="text-slate-900">{requests.length}</strong>
        </span>
      </div>

      {/* ── Search & Filter ── */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white p-3 rounded-xl border border-slate-200">
        <div className="relative w-full sm:w-80">
          <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search User, Email, Request ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
          <span className="text-xs text-slate-400 font-mono flex items-center gap-1 shrink-0">
            <Filter className="h-3 w-3" /> Scope:
          </span>
          <select
            value={filterScope}
            onChange={(e) => setFilterScope(e.target.value)}
            className="text-xs font-mono bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          >
            <option value="ALL">All Scopes</option>
            <option value="FULL_ARCHIVE">Full Archive</option>
            <option value="PROJECTS_ONLY">Projects & CAD Data</option>
            <option value="CONSENT_AUDIT">Consent Audit Only</option>
          </select>
        </div>
      </div>

      {/* ── Exports Table ── */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono uppercase text-[10px]">
                <th className="py-3 px-4 font-semibold">User Details</th>
                <th className="py-3 px-4 font-semibold">Export Scope</th>
                <th className="py-3 px-4 font-semibold">Status</th>
                <th className="py-3 px-4 font-semibold">Requested At</th>
                <th className="py-3 px-4 font-semibold">Expires At (7d)</th>
                <th className="py-3 px-4 font-semibold">Download Token</th>
                <th className="py-3 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center gap-2">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent" />
                      <span className="font-mono text-xs">Loading export requests...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredRequests.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400 font-mono text-xs">
                    No export requests found.
                  </td>
                </tr>
              ) : (
                filteredRequests.map((req) => {
                  const isCompleted = req.status === 'COMPLETED';
                  const isPending = req.status === 'PENDING' || req.status === 'PROCESSING';

                  return (
                    <tr key={req.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3.5 px-4 font-medium text-slate-900">
                        <div className="font-bold">{req.user_name || 'Account Holder'}</div>
                        <div className="text-[11px] font-mono text-slate-500">{req.user_email}</div>
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-slate-700">
                        <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-800 border border-blue-200">
                          {req.export_scope}
                        </span>
                      </td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase inline-flex items-center gap-1 ${
                            isCompleted
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                              : isPending
                              ? 'bg-amber-100 text-amber-800 border border-amber-300'
                              : 'bg-rose-100 text-rose-800 border border-rose-300'
                          }`}
                        >
                          {req.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-600 text-[11px]">
                        {req.requested_at ? req.requested_at.slice(0, 10) : '—'}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-600 text-[11px]">
                        {req.expires_at ? req.expires_at.slice(0, 10) : '—'}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-400 text-[11px]">
                        {req.download_token ? (
                          <span className="text-emerald-700 font-bold bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                            SECURE_ISSUED
                          </span>
                        ) : (
                          <span className="text-slate-400 italic">NOT_ISSUED</span>
                        )}
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => onReviewRequest(req)}
                          className="h-7 text-xs font-mono"
                        >
                          <Eye className="h-3.5 w-3.5 mr-1" /> Update
                        </Button>
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

'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { AdminAccountDeletionRequest } from '@/lib/types';
import {
  UserX,
  Search,
  Filter,
  Clock,
  AlertTriangle,
  CheckCircle2,
  XCircle,
  Eye,
  ShieldAlert,
} from 'lucide-react';

interface AccountDeletionsTabProps {
  requests: AdminAccountDeletionRequest[];
  loading: boolean;
  onReviewRequest: (req: AdminAccountDeletionRequest) => void;
}

export function AccountDeletionsTab({
  requests,
  loading,
  onReviewRequest,
}: AccountDeletionsTabProps) {
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const filteredRequests = requests.filter((req) => {
    if (filterStatus !== 'ALL' && req.status !== filterStatus) return false;
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
      {/* ── Architecture & Safeguards Banner ── */}
      <div className="bg-slate-900 text-white rounded-xl p-5 border border-slate-800 shadow-sm flex items-start gap-4">
        <ShieldAlert className="h-5 w-5 text-amber-400 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <h4 className="text-sm font-bold font-mono text-white">
            Section 12(3) DPDP Act Erasure & Collaborative CAD Safeguards
          </h4>
          <p className="text-xs text-slate-300 leading-relaxed">
            When approved as <span className="font-semibold text-emerald-400">COMPLETED</span>, user personal profile data is tombstoned/anonymized in D1 and private PIXMINT BOT conversations are purged.
            Collaborative multi-party CAD drawings (`.dwg`, `.dxf`, `.pdf`) and CERT-In 180-day access logs are strictly preserved to maintain project structural integrity and statutory compliance.
          </p>
        </div>
      </div>

      {/* ── Filters & Search ── */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white p-3 rounded-xl border border-slate-200">
        <div className="relative w-full sm:w-80">
          <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search User Email, Name, Request ID..."
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            className="w-full pl-9 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-lg focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          />
        </div>
        <div className="flex items-center gap-2 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0">
          <span className="text-xs text-slate-400 font-mono flex items-center gap-1 shrink-0">
            <Filter className="h-3 w-3" /> Status:
          </span>
          <select
            value={filterStatus}
            onChange={(e) => setFilterStatus(e.target.value)}
            className="text-xs font-mono bg-slate-50 border border-slate-200 rounded-lg px-2.5 py-1.5 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
          >
            <option value="ALL">All Statuses</option>
            <option value="PENDING">Pending (Within Grace Period)</option>
            <option value="UNDER_REVIEW">Under Review</option>
            <option value="DELETION_SCHEDULED">Deletion Scheduled</option>
            <option value="COMPLETED">Completed (Tombstoned)</option>
            <option value="CANCELLED">Cancelled by User</option>
            <option value="REJECTED_WITH_REASON">Rejected with Reason</option>
          </select>
        </div>
      </div>

      {/* ── Requests Table ── */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono uppercase text-[10px]">
                <th className="py-3 px-4 font-semibold">User Details</th>
                <th className="py-3 px-4 font-semibold">Role</th>
                <th className="py-3 px-4 font-semibold">Status</th>
                <th className="py-3 px-4 font-semibold">Submitted At</th>
                <th className="py-3 px-4 font-semibold">Scheduled Purge (Grace 30d)</th>
                <th className="py-3 px-4 font-semibold">Reason</th>
                <th className="py-3 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center gap-2">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent" />
                      <span className="font-mono text-xs">Loading erasure queue...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredRequests.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400 font-mono text-xs">
                    No account deletion requests in queue.
                  </td>
                </tr>
              ) : (
                filteredRequests.map((req) => {
                  const isPending = req.status === 'PENDING' || req.status === 'DELETION_SCHEDULED';
                  const isCompleted = req.status === 'COMPLETED';
                  const isCancelled = req.status === 'CANCELLED';

                  return (
                    <tr key={req.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3.5 px-4 font-medium text-slate-900">
                        <div className="font-bold">{req.user_name || 'Account Holder'}</div>
                        <div className="text-[11px] font-mono text-slate-500">{req.user_email}</div>
                      </td>
                      <td className="py-3.5 px-4 font-mono text-[11px]">
                        <span className="px-2 py-0.5 rounded bg-slate-100 text-slate-700 font-bold border border-slate-200">
                          {req.user_role || 'USER'}
                        </span>
                      </td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase inline-flex items-center gap-1 ${
                            isPending
                              ? 'bg-amber-100 text-amber-800 border border-amber-300'
                              : isCompleted
                              ? 'bg-slate-100 text-slate-700 border border-slate-300'
                              : isCancelled
                              ? 'bg-blue-100 text-blue-800 border border-blue-300'
                              : 'bg-rose-100 text-rose-800 border border-rose-300'
                          }`}
                        >
                          {req.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-600 text-[11px]">
                        {req.submitted_at ? req.submitted_at.slice(0, 10) : '—'}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-amber-700 font-semibold text-[11px]">
                        {req.scheduled_purge_at ? req.scheduled_purge_at.slice(0, 10) : '—'}
                      </td>
                      <td className="py-3.5 px-4 text-slate-600 max-w-xs truncate">
                        {req.reason || 'No departure reason supplied'}
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => onReviewRequest(req)}
                          className="h-7 text-xs font-mono"
                        >
                          <Eye className="h-3.5 w-3.5 mr-1" /> Review
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

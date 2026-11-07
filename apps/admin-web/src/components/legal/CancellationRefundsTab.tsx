'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { AdminCancellationRefundRequest } from '@/lib/types';
import {
  CreditCard,
  Search,
  Filter,
  CheckCircle2,
  XCircle,
  Eye,
  DollarSign,
  AlertCircle,
} from 'lucide-react';

interface CancellationRefundsTabProps {
  requests: AdminCancellationRefundRequest[];
  loading: boolean;
  onReviewRequest: (req: AdminCancellationRefundRequest) => void;
}

export function CancellationRefundsTab({
  requests,
  loading,
  onReviewRequest,
}: CancellationRefundsTabProps) {
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const filteredRequests = requests.filter((req) => {
    if (filterStatus !== 'ALL' && req.status !== filterStatus) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        (req.user_name && req.user_name.toLowerCase().includes(q)) ||
        (req.user_email && req.user_email.toLowerCase().includes(q)) ||
        (req.project_id && req.project_id.toLowerCase().includes(q)) ||
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
          <h3 className="text-base font-bold text-slate-900 font-mono">Milestone Cancellations & Refunds Queue</h3>
          <p className="text-xs text-slate-500">
            Administrative review queue for CAD drafting milestone cancellations, disputes, and fee evaluations
          </p>
        </div>
        <span className="text-xs font-mono text-slate-500 bg-slate-100 px-3 py-1.5 rounded-lg border border-slate-200">
          Total Refund Requests: <strong className="text-slate-900">{requests.length}</strong>
        </span>
      </div>

      {/* ── Search & Filter ── */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white p-3 rounded-xl border border-slate-200">
        <div className="relative w-full sm:w-80">
          <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search User, Project ID, Request ID..."
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
            <option value="PENDING">Pending</option>
            <option value="UNDER_REVIEW">Under Review</option>
            <option value="APPROVED">Approved</option>
            <option value="PROCESSED">Processed</option>
            <option value="REJECTED">Rejected</option>
          </select>
        </div>
      </div>

      {/* ── Table ── */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono uppercase text-[10px]">
                <th className="py-3 px-4 font-semibold">User Details</th>
                <th className="py-3 px-4 font-semibold">Project / Milestone</th>
                <th className="py-3 px-4 font-semibold">Amount Requested</th>
                <th className="py-3 px-4 font-semibold">Amount Approved</th>
                <th className="py-3 px-4 font-semibold">Status</th>
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
                      <span className="font-mono text-xs">Loading refund requests...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredRequests.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400 font-mono text-xs">
                    No cancellation or refund requests found.
                  </td>
                </tr>
              ) : (
                filteredRequests.map((req) => {
                  const isApproved = req.status === 'APPROVED' || req.status === 'PROCESSED';
                  const isPending = req.status === 'PENDING' || req.status === 'UNDER_REVIEW';

                  return (
                    <tr key={req.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3.5 px-4 font-medium text-slate-900">
                        <div className="font-bold">{req.user_name || 'Account Holder'}</div>
                        <div className="text-[11px] font-mono text-slate-500">{req.user_email}</div>
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-700">
                        <div>{req.project_id || 'GENERAL_COMMISSION'}</div>
                        {req.milestone_id && (
                          <div className="text-[10px] text-slate-400">{req.milestone_id}</div>
                        )}
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-slate-800">
                        {req.amount_requested ? `₹${req.amount_requested.toLocaleString('en-IN')}` : 'Full Milestone'}
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-emerald-700">
                        {req.amount_approved ? `₹${req.amount_approved.toLocaleString('en-IN')}` : '—'}
                      </td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase inline-flex items-center gap-1 ${
                            isApproved
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                              : isPending
                              ? 'bg-amber-100 text-amber-800 border border-amber-300'
                              : 'bg-rose-100 text-rose-800 border border-rose-300'
                          }`}
                        >
                          {req.status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-slate-600 max-w-xs truncate">
                        {req.reason}
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

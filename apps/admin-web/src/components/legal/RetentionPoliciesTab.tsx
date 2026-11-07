'use client';

import React from 'react';
import { Card } from '@/components/ui/Card';
import { DataRetentionPolicy } from '@/lib/types';
import {
  Archive,
  ShieldAlert,
  Clock,
  BookOpen,
  CheckCircle2,
  AlertTriangle,
} from 'lucide-react';

interface RetentionPoliciesTabProps {
  policies: DataRetentionPolicy[];
  loading: boolean;
}

export function RetentionPoliciesTab({ policies, loading }: RetentionPoliciesTabProps) {
  return (
    <div className="space-y-6 select-none">
      {/* ── Statutory Guidance Banner ── */}
      <div className="bg-slate-900 text-white rounded-xl p-5 border border-slate-800 shadow-sm flex items-start gap-4">
        <Archive className="h-5 w-5 text-indigo-400 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <h4 className="text-sm font-bold font-mono text-white">
            Statutory Log Retention Schedules vs. Operational CAD Archives
          </h4>
          <p className="text-xs text-slate-300 leading-relaxed">
            Direction No. 20(3)/2022-CERT-In mandates a minimum <span className="font-semibold text-emerald-400">180-day</span> retention of security logs and user consent records within Indian jurisdiction.
            Section 44AA of the Income-tax Act, 1961 mandates <span className="font-semibold text-emerald-400">8 financial years</span> retention for financial transaction records and invoices.
            Operational CAD drawing retention is subject to ongoing business review.
          </p>
        </div>
      </div>

      {/* ── Retention Schedules Table ── */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono uppercase text-[10px]">
                <th className="py-3 px-4 font-semibold">Data Category</th>
                <th className="py-3 px-4 font-semibold">Purpose of Processing</th>
                <th className="py-3 px-4 font-semibold">Retention Period</th>
                <th className="py-3 px-4 font-semibold">Legal / Business Basis</th>
                <th className="py-3 px-4 font-semibold">Policy Authority</th>
                <th className="py-3 px-4 font-semibold">Review Status</th>
                <th className="py-3 px-4 font-semibold text-right">Last Reviewed</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center gap-2">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent" />
                      <span className="font-mono text-xs">Loading retention schedules...</span>
                    </div>
                  </td>
                </tr>
              ) : policies.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400 font-mono text-xs">
                    No retention policies configured.
                  </td>
                </tr>
              ) : (
                policies.map((p) => {
                  const isVerified = p.review_status === 'VERIFIED' || p.review_status === 'APPROVED';

                  return (
                    <tr key={p.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3.5 px-4 font-mono font-bold text-slate-900">
                        {p.data_category}
                      </td>
                      <td className="py-3.5 px-4 text-slate-600 max-w-xs">
                        {p.purpose}
                      </td>
                      <td className="py-3.5 px-4 font-mono font-bold text-indigo-700">
                        <span className="px-2 py-0.5 rounded bg-indigo-50 border border-indigo-200">
                          {p.retention_period}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-slate-700 font-medium">
                        {p.legal_basis}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-[11px] text-slate-500">
                        {p.policy_source}
                      </td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase inline-flex items-center gap-1 ${
                            isVerified
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                              : 'bg-amber-100 text-amber-800 border border-amber-300'
                          }`}
                        >
                          {p.review_status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-600 text-[11px] text-right">
                        {p.last_reviewed_at ? p.last_reviewed_at.slice(0, 10) : 'PENDING'}
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

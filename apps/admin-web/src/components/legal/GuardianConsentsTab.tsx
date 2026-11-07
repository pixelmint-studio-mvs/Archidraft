'use client';

import React, { useState } from 'react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { AdminGuardianConsent } from '@/lib/types';
import {
  ShieldCheck,
  Search,
  Filter,
  CheckCircle2,
  XCircle,
  Eye,
  AlertTriangle,
  UserCheck,
} from 'lucide-react';

interface GuardianConsentsTabProps {
  consents: AdminGuardianConsent[];
  loading: boolean;
  onReviewConsent: (consent: AdminGuardianConsent) => void;
}

export function GuardianConsentsTab({
  consents,
  loading,
  onReviewConsent,
}: GuardianConsentsTabProps) {
  const [filterStatus, setFilterStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  const filteredConsents = consents.filter((gc) => {
    if (filterStatus !== 'ALL' && gc.verification_status !== filterStatus) return false;
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      return (
        gc.guardian_name.toLowerCase().includes(q) ||
        gc.guardian_email.toLowerCase().includes(q) ||
        (gc.student_name && gc.student_name.toLowerCase().includes(q)) ||
        (gc.student_email && gc.student_email.toLowerCase().includes(q))
      );
    }
    return true;
  });

  return (
    <div className="space-y-6 select-none">
      {/* ── Statutory Safeguards Advisory Banner ── */}
      <div className="bg-teal-50 border border-teal-200 rounded-xl p-5 flex items-start gap-4">
        <ShieldCheck className="h-5 w-5 text-teal-700 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <h4 className="text-sm font-bold text-teal-900 font-mono">
            Section 9 DPDP Act 2023 — Verifiable Parental Consent Safeguards
          </h4>
          <p className="text-xs text-teal-800 leading-relaxed">
            Processing personal data of students under 18 years requires verifiable consent of the parent or lawful guardian.
            A declaration submitted by a student is <span className="font-semibold underline">not</span> automatically verified consent.
            Reviewers must verify guardian details and maintain auditable verification notes before certifying accounts.
          </p>
        </div>
      </div>

      {/* ── Search & Filter ── */}
      <div className="flex flex-col sm:flex-row items-center justify-between gap-3 bg-white p-3 rounded-xl border border-slate-200">
        <div className="relative w-full sm:w-80">
          <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-400" />
          <input
            type="text"
            placeholder="Search Student, Guardian Name, Email..."
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
            <option value="ALL">All Verification Statuses</option>
            <option value="PENDING">Pending Verification</option>
            <option value="VERIFIED">Verified (Approved)</option>
            <option value="REJECTED">Rejected</option>
            <option value="WITHDRAWN">Withdrawn</option>
          </select>
        </div>
      </div>

      {/* ── Table ── */}
      <div className="bg-white rounded-xl border border-slate-200 overflow-hidden shadow-sm">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse text-xs">
            <thead>
              <tr className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono uppercase text-[10px]">
                <th className="py-3 px-4 font-semibold">Student Account</th>
                <th className="py-3 px-4 font-semibold">Guardian Name</th>
                <th className="py-3 px-4 font-semibold">Relationship</th>
                <th className="py-3 px-4 font-semibold">Guardian Contacts</th>
                <th className="py-3 px-4 font-semibold">Declaration</th>
                <th className="py-3 px-4 font-semibold">Verification Status</th>
                <th className="py-3 px-4 font-semibold text-right">Actions</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {loading ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400">
                    <div className="flex flex-col items-center gap-2">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent" />
                      <span className="font-mono text-xs">Loading guardian consents...</span>
                    </div>
                  </td>
                </tr>
              ) : filteredConsents.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-slate-400 font-mono text-xs">
                    No student guardian consent records found.
                  </td>
                </tr>
              ) : (
                filteredConsents.map((gc) => {
                  const isVerified = gc.verification_status === 'VERIFIED';
                  const isPending = gc.verification_status === 'PENDING';

                  return (
                    <tr key={gc.id} className="hover:bg-slate-50/70 transition-colors">
                      <td className="py-3.5 px-4 font-medium text-slate-900">
                        <div className="font-bold">{gc.student_name || 'Student Account'}</div>
                        <div className="text-[11px] font-mono text-slate-500">{gc.student_email}</div>
                      </td>
                      <td className="py-3.5 px-4 font-bold text-slate-800">
                        {gc.guardian_name}
                      </td>
                      <td className="py-3.5 px-4 font-mono text-slate-600">
                        <span className="px-2 py-0.5 rounded bg-slate-100 border border-slate-200">
                          {gc.relationship}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 font-mono text-[11px] text-slate-600">
                        <div>{gc.guardian_email}</div>
                        <div className="text-slate-400">{gc.guardian_phone}</div>
                      </td>
                      <td className="py-3.5 px-4 text-slate-600 max-w-xs truncate">
                        {gc.consent_declaration}
                      </td>
                      <td className="py-3.5 px-4">
                        <span
                          className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-bold uppercase inline-flex items-center gap-1 ${
                            isVerified
                              ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                              : isPending
                              ? 'bg-amber-100 text-amber-800 border border-amber-300'
                              : 'bg-rose-100 text-rose-800 border border-rose-300'
                          }`}
                        >
                          {gc.verification_status}
                        </span>
                      </td>
                      <td className="py-3.5 px-4 text-right">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => onReviewConsent(gc)}
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

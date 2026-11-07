'use client';

import React from 'react';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { LegalComplianceStats } from '@/lib/types';
import {
  FileText,
  UserX,
  DownloadCloud,
  Edit3,
  ShieldCheck,
  CreditCard,
  LifeBuoy,
  Archive,
  AlertTriangle,
  CheckCircle2,
  Clock,
  ArrowRight,
  ExternalLink,
} from 'lucide-react';

interface LegalOverviewTabProps {
  stats: LegalComplianceStats | null;
  loading: boolean;
  onNavigateTab: (tab: string) => void;
}

export function LegalOverviewTab({ stats, loading, onNavigateTab }: LegalOverviewTabProps) {
  if (loading && !stats) {
    return (
      <div className="space-y-6">
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-32 bg-white rounded-xl border border-slate-200 p-5 animate-pulse" />
          ))}
        </div>
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <div className="h-64 bg-white rounded-xl border border-slate-200 p-5 animate-pulse lg:col-span-2" />
          <div className="h-64 bg-white rounded-xl border border-slate-200 p-5 animate-pulse" />
        </div>
      </div>
    );
  }

  const docs = stats?.documents || { total: 0, published: 0, draft: 0, pendingReview: 0 };
  const queues = stats?.queues || {
    pendingDeletions: 0,
    pendingExports: 0,
    pendingCorrections: 0,
    pendingGuardians: 0,
    pendingRefunds: 0,
    pendingPrivacyRequests: 0,
    totalPendingAction: 0,
  };
  const telemetry = stats?.telemetry || { totalConsentEvents: 0, retentionPoliciesConfigured: 0 };

  return (
    <div className="space-y-6 select-none">
      {/* ── Governance Verification Advisory Banner ── */}
      <div className="bg-gradient-to-r from-[#0d1c32] to-[#15294a] rounded-2xl p-6 text-white border border-[#22395d] shadow-sm relative overflow-hidden">
        <div className="relative z-10 flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="space-y-1.5">
            <div className="flex items-center gap-2">
              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-mono font-bold tracking-wider uppercase bg-amber-500/20 text-amber-300 border border-amber-400/30">
                Statutory Governance Notice
              </span>
              <span className="text-xs font-mono text-slate-300">DPDP Act 2023 • CERT-In 2022</span>
            </div>
            <h2 className="text-xl font-bold tracking-tight text-white font-mono">
              DRAUGHTSMAN STUDIO Legal Compliance & Data Rights Center
            </h2>
            <p className="text-xs text-slate-300 max-w-2xl leading-relaxed">
              Proprietor: <span className="font-semibold text-white">MOHAMMED MOSIN S</span>. Physical establishment address and formal Grievance Officer appointment remain{' '}
              <span className="text-amber-300 font-semibold underline decoration-amber-400/50">PENDING_VERIFICATION</span>. No legal compliance certification is claimed.
            </p>
          </div>
          <div className="flex items-center gap-2 shrink-0">
            <Button
              variant="outline"
              size="sm"
              onClick={() => onNavigateTab('business')}
              className="bg-white/10 hover:bg-white/20 text-white border-white/20 text-xs font-mono"
            >
              Verify Profile Status
            </Button>
            <Button
              variant="secondary"
              size="sm"
              onClick={() => onNavigateTab('documents')}
              className="text-xs font-mono"
            >
              Document Registry
            </Button>
          </div>
        </div>
      </div>

      {/* ── Primary KPI Cards ── */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Document Registry Status */}
        <Card className="p-5 border-slate-200 hover:border-slate-300 transition-all cursor-pointer group" onClick={() => onNavigateTab('documents')}>
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <span className="text-[11px] font-mono uppercase tracking-wider text-slate-500 font-semibold">
                Canonical Instruments
              </span>
              <div className="flex items-baseline gap-2">
                <span className="text-2xl font-bold font-mono text-[#0d1c32]">{docs.total}</span>
                <span className="text-xs text-emerald-600 font-medium">({docs.published} Published)</span>
              </div>
            </div>
            <div className="h-10 w-10 rounded-xl bg-blue-50 text-[#0453cd] flex items-center justify-center group-hover:scale-105 transition-transform">
              <FileText className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>{docs.pendingReview} Pending Review</span>
            <span className="font-mono text-[#0453cd] flex items-center gap-1 group-hover:translate-x-0.5 transition-transform">
              Manage <ArrowRight className="h-3 w-3" />
            </span>
          </div>
        </Card>

        {/* Pending Actions Total */}
        <Card className="p-5 border-slate-200 hover:border-slate-300 transition-all cursor-pointer group" onClick={() => onNavigateTab('deletions')}>
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <span className="text-[11px] font-mono uppercase tracking-wider text-slate-500 font-semibold">
                Action Required
              </span>
              <div className="flex items-baseline gap-2">
                <span className="text-2xl font-bold font-mono text-amber-600">{queues.totalPendingAction}</span>
                <span className="text-xs text-slate-500 font-medium">Pending Requests</span>
              </div>
            </div>
            <div className="h-10 w-10 rounded-xl bg-amber-50 text-amber-700 flex items-center justify-center group-hover:scale-105 transition-transform">
              <Clock className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>{queues.pendingDeletions} Deletions • {queues.pendingGuardians} Guardians</span>
            <span className="font-mono text-amber-700 flex items-center gap-1 group-hover:translate-x-0.5 transition-transform">
              Review <ArrowRight className="h-3 w-3" />
            </span>
          </div>
        </Card>

        {/* Regulatory Consent Telemetry */}
        <Card className="p-5 border-slate-200 hover:border-slate-300 transition-all cursor-pointer group" onClick={() => onNavigateTab('consents')}>
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <span className="text-[11px] font-mono uppercase tracking-wider text-slate-500 font-semibold">
                Consent Audit Ledger
              </span>
              <div className="flex items-baseline gap-2">
                <span className="text-2xl font-bold font-mono text-[#0d1c32]">{telemetry.totalConsentEvents}</span>
                <span className="text-xs text-slate-500 font-medium">Logged Events</span>
              </div>
            </div>
            <div className="h-10 w-10 rounded-xl bg-emerald-50 text-emerald-700 flex items-center justify-center group-hover:scale-105 transition-transform">
              <ShieldCheck className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>Immutable Regulatory Logs</span>
            <span className="font-mono text-emerald-700 flex items-center gap-1 group-hover:translate-x-0.5 transition-transform">
              Audit <ArrowRight className="h-3 w-3" />
            </span>
          </div>
        </Card>

        {/* Retention Policies */}
        <Card className="p-5 border-slate-200 hover:border-slate-300 transition-all cursor-pointer group" onClick={() => onNavigateTab('retention')}>
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <span className="text-[11px] font-mono uppercase tracking-wider text-slate-500 font-semibold">
                Retention Schedules
              </span>
              <div className="flex items-baseline gap-2">
                <span className="text-2xl font-bold font-mono text-[#0d1c32]">{telemetry.retentionPoliciesConfigured}</span>
                <span className="text-xs text-slate-500 font-medium">Categories</span>
              </div>
            </div>
            <div className="h-10 w-10 rounded-xl bg-purple-50 text-purple-700 flex items-center justify-center group-hover:scale-105 transition-transform">
              <Archive className="h-5 w-5" />
            </div>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
            <span>CERT-In 180d • Tax 8yr</span>
            <span className="font-mono text-purple-700 flex items-center gap-1 group-hover:translate-x-0.5 transition-transform">
              Inspect <ArrowRight className="h-3 w-3" />
            </span>
          </div>
        </Card>
      </div>

      {/* ── Operational Queue Review Tiles ── */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {/* Account Deletions */}
        <div
          onClick={() => onNavigateTab('deletions')}
          className="bg-white p-5 rounded-xl border border-slate-200 hover:border-rose-300 transition-all cursor-pointer group shadow-sm flex flex-col justify-between"
        >
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <UserX className="h-4 w-4 text-rose-600" />
                <h3 className="text-sm font-bold text-slate-900">Account Erasure Requests</h3>
              </div>
              <p className="text-xs text-slate-500">Section 12(3) DPDP Act 30-day grace period queue</p>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-xs font-mono font-bold ${queues.pendingDeletions > 0 ? 'bg-rose-100 text-rose-800' : 'bg-slate-100 text-slate-600'}`}>
              {queues.pendingDeletions}
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-rose-700 font-mono">
            <span>Tombstone & collaborative CAD safeguards</span>
            <ArrowRight className="h-3 w-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Data Exports */}
        <div
          onClick={() => onNavigateTab('exports')}
          className="bg-white p-5 rounded-xl border border-slate-200 hover:border-blue-300 transition-all cursor-pointer group shadow-sm flex flex-col justify-between"
        >
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <DownloadCloud className="h-4 w-4 text-[#0453cd]" />
                <h3 className="text-sm font-bold text-slate-900">Personal Data Exports</h3>
              </div>
              <p className="text-xs text-slate-500">Section 11 DPDP Act machine-readable archives</p>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-xs font-mono font-bold ${queues.pendingExports > 0 ? 'bg-blue-100 text-blue-800' : 'bg-slate-100 text-slate-600'}`}>
              {queues.pendingExports}
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-[#0453cd] font-mono">
            <span>7-day token expiry enforcement</span>
            <ArrowRight className="h-3 w-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Data Corrections */}
        <div
          onClick={() => onNavigateTab('corrections')}
          className="bg-white p-5 rounded-xl border border-slate-200 hover:border-amber-300 transition-all cursor-pointer group shadow-sm flex flex-col justify-between"
        >
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <Edit3 className="h-4 w-4 text-amber-600" />
                <h3 className="text-sm font-bold text-slate-900">Profile Data Rectifications</h3>
              </div>
              <p className="text-xs text-slate-500">Section 12(1) DPDP Act profile field reviews</p>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-xs font-mono font-bold ${queues.pendingCorrections > 0 ? 'bg-amber-100 text-amber-800' : 'bg-slate-100 text-slate-600'}`}>
              {queues.pendingCorrections}
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-amber-700 font-mono">
            <span>Atomic profile update on approval</span>
            <ArrowRight className="h-3 w-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Guardian Consents */}
        <div
          onClick={() => onNavigateTab('guardians')}
          className="bg-white p-5 rounded-xl border border-slate-200 hover:border-teal-300 transition-all cursor-pointer group shadow-sm flex flex-col justify-between"
        >
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <ShieldCheck className="h-4 w-4 text-teal-600" />
                <h3 className="text-sm font-bold text-slate-900">Student Guardian Consents</h3>
              </div>
              <p className="text-xs text-slate-500">Section 9 DPDP Act under-18 student safeguards</p>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-xs font-mono font-bold ${queues.pendingGuardians > 0 ? 'bg-teal-100 text-teal-800' : 'bg-slate-100 text-slate-600'}`}>
              {queues.pendingGuardians}
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-teal-700 font-mono">
            <span>Verifiable parental declaration verification</span>
            <ArrowRight className="h-3 w-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Cancellations & Refunds */}
        <div
          onClick={() => onNavigateTab('refunds')}
          className="bg-white p-5 rounded-xl border border-slate-200 hover:border-purple-300 transition-all cursor-pointer group shadow-sm flex flex-col justify-between"
        >
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <CreditCard className="h-4 w-4 text-purple-600" />
                <h3 className="text-sm font-bold text-slate-900">Milestone Cancellations & Refunds</h3>
              </div>
              <p className="text-xs text-slate-500">Project drafting disputes & fee evaluations</p>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-xs font-mono font-bold ${queues.pendingRefunds > 0 ? 'bg-purple-100 text-purple-800' : 'bg-slate-100 text-slate-600'}`}>
              {queues.pendingRefunds}
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-purple-700 font-mono">
            <span>Milestone progress audit before refund</span>
            <ArrowRight className="h-3 w-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>

        {/* Privacy & Grievances */}
        <div
          onClick={() => onNavigateTab('grievances')}
          className="bg-white p-5 rounded-xl border border-slate-200 hover:border-indigo-300 transition-all cursor-pointer group shadow-sm flex flex-col justify-between"
        >
          <div className="flex items-start justify-between">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <LifeBuoy className="h-4 w-4 text-indigo-600" />
                <h3 className="text-sm font-bold text-slate-900">Privacy & Statutory Grievances</h3>
              </div>
              <p className="text-xs text-slate-500">Section 13 DPDP Act grievance redressal tickets</p>
            </div>
            <span className={`px-2 py-0.5 rounded-full text-xs font-mono font-bold ${queues.pendingPrivacyRequests > 0 ? 'bg-indigo-100 text-indigo-800' : 'bg-slate-100 text-slate-600'}`}>
              {queues.pendingPrivacyRequests}
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs text-indigo-700 font-mono">
            <span>Formal acknowledgment & statutory logs</span>
            <ArrowRight className="h-3 w-3 group-hover:translate-x-1 transition-transform" />
          </div>
        </div>
      </div>
    </div>
  );
}

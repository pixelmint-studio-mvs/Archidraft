'use client';

import React from 'react';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { LegalBusinessProfile } from '@/lib/types';
import {
  Building2,
  UserCheck,
  Globe,
  Mail,
  MapPin,
  ShieldAlert,
  AlertTriangle,
  CheckCircle2,
  Clock,
  Info,
} from 'lucide-react';

interface BusinessProfileTabProps {
  profile: LegalBusinessProfile | null;
  loading: boolean;
}

export function BusinessProfileTab({ profile, loading }: BusinessProfileTabProps) {
  if (loading && !profile) {
    return (
      <div className="space-y-6 animate-pulse">
        <div className="h-40 bg-white rounded-xl border border-slate-200" />
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <div className="h-64 bg-white rounded-xl border border-slate-200" />
          <div className="h-64 bg-white rounded-xl border border-slate-200" />
        </div>
      </div>
    );
  }

  const ver = profile?.verificationStatus || {};

  return (
    <div className="space-y-6 select-none">
      {/* ── Status Banner ── */}
      <div className="bg-amber-50/70 border border-amber-200 rounded-xl p-5 flex items-start gap-4">
        <AlertTriangle className="h-5 w-5 text-amber-600 shrink-0 mt-0.5" />
        <div className="space-y-1">
          <h4 className="text-sm font-bold text-amber-900 font-mono">
            Provisional Sole Proprietorship Configuration & Verification Notice
          </h4>
          <p className="text-xs text-amber-800 leading-relaxed">
            DRAUGHTSMAN STUDIO is configured as a Sole Proprietorship operated by <span className="font-semibold text-amber-950">MOHAMMED MOSIN S</span>.
            Under no circumstances should the platform be represented as a Private Limited, LLP, or registered corporate entity.
            Physical business address and formal statutory Grievance Officer appointment order under IT Rules remain <span className="font-semibold underline">PENDING_VERIFICATION</span>.
          </p>
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* ── Business & Proprietorship Identity ── */}
        <Card className="p-6 border-slate-200 shadow-sm space-y-5">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div className="flex items-center gap-2.5">
              <div className="h-8 w-8 rounded-lg bg-blue-50 text-[#0453cd] flex items-center justify-center">
                <Building2 className="h-4 w-4" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 font-mono">Legal Business Identity</h3>
            </div>
            <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-semibold">
              CONFIRMED
            </span>
          </div>

          <div className="space-y-4 text-xs">
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Legal Structure</span>
              <p className="font-semibold text-slate-800 text-sm mt-0.5">
                {profile?.businessIdentity?.structure || 'Sole Proprietorship'}
              </p>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Legal Proprietor</span>
              <p className="font-semibold text-slate-800 text-sm mt-0.5">
                {profile?.businessIdentity?.legalProprietor || 'MOHAMMED MOSIN S'}
              </p>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Operating Brand</span>
              <p className="font-semibold text-slate-800 text-sm mt-0.5">
                {profile?.businessIdentity?.operatingBrand || 'DRAUGHTSMAN STUDIO'}
              </p>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Legal Representation String</span>
              <p className="font-mono text-slate-600 bg-slate-50 p-2.5 rounded-lg border border-slate-200/60 mt-1 leading-relaxed">
                {profile?.businessIdentity?.legalRepresentation || 'DRAUGHTSMAN STUDIO — a sole proprietorship operated by MOHAMMED MOSIN S.'}
              </p>
            </div>
          </div>
        </Card>

        {/* ── Product & Digital Properties ── */}
        <Card className="p-6 border-slate-200 shadow-sm space-y-5">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div className="flex items-center gap-2.5">
              <div className="h-8 w-8 rounded-lg bg-indigo-50 text-indigo-700 flex items-center justify-center">
                <Globe className="h-4 w-4" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 font-mono">Product & Digital Properties</h3>
            </div>
            <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-semibold">
              CONFIRMED
            </span>
          </div>

          <div className="space-y-4 text-xs">
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Product Name</span>
              <p className="font-semibold text-slate-800 text-sm mt-0.5">
                {profile?.productIdentity?.productName || 'ARCHI DRAFT'}
              </p>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Application Web Portal</span>
              <a
                href={profile?.websiteAddresses?.applicationWebsite || 'https://archidraft.draughtsmanstudio.com'}
                target="_blank"
                rel="noreferrer"
                className="text-[#0453cd] hover:underline flex items-center gap-1 font-mono mt-0.5"
              >
                {profile?.websiteAddresses?.applicationWebsite || 'https://archidraft.draughtsmanstudio.com'}
              </a>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Studio Website</span>
              <a
                href={profile?.websiteAddresses?.businessWebsite || 'https://draughtsmanstudio.com'}
                target="_blank"
                rel="noreferrer"
                className="text-[#0453cd] hover:underline flex items-center gap-1 font-mono mt-0.5"
              >
                {profile?.websiteAddresses?.businessWebsite || 'https://draughtsmanstudio.com'}
              </a>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Product Scope</span>
              <p className="text-slate-600 mt-0.5 leading-relaxed">
                {profile?.productIdentity?.description || 'Professional architectural drafting, workflow coordination, and vocational CAD training platform.'}
              </p>
            </div>
          </div>
        </Card>

        {/* ── Statutory Contact & Grievance Vectors ── */}
        <Card className="p-6 border-slate-200 shadow-sm space-y-5">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div className="flex items-center gap-2.5">
              <div className="h-8 w-8 rounded-lg bg-teal-50 text-teal-700 flex items-center justify-center">
                <Mail className="h-4 w-4" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 font-mono">Contact & Redressal Vectors</h3>
            </div>
            <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200 font-semibold">
              CONFIRMED
            </span>
          </div>

          <div className="space-y-4 text-xs">
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Primary Grievance Redressal</span>
              <p className="font-mono text-slate-800 font-semibold mt-0.5">
                {profile?.contactInformation?.grievanceEmail || 'mosin@draughtsmanstudio.com'}
              </p>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Customer Support</span>
              <p className="font-mono text-slate-800 font-semibold mt-0.5">
                {profile?.contactInformation?.supportEmail || 'support@draughtsmanstudio.com'}
              </p>
            </div>
            <div>
              <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Data Privacy Requests</span>
              <p className="font-mono text-slate-800 font-semibold mt-0.5">
                {profile?.contactInformation?.privacyEmail || 'support@draughtsmanstudio.com'}
              </p>
            </div>
            <div className="bg-slate-50 p-3 rounded-lg border border-slate-200/60 text-slate-500 space-y-1">
              <div className="flex items-center gap-1.5 font-semibold text-slate-700">
                <Clock className="h-3.5 w-3.5 text-[#0453cd]" />
                <span>Statutory Response SLA (Target)</span>
              </div>
              <p className="text-[11px] leading-relaxed">
                Acknowledgment within 48 hours; final resolution target within 30 calendar days pursuant to Section 13 DPDP Act.
              </p>
            </div>
          </div>
        </Card>

        {/* ── Pending Verification Items ── */}
        <Card className="p-6 border-slate-200 shadow-sm space-y-5 bg-gradient-to-b from-white to-amber-50/20">
          <div className="flex items-center justify-between border-b border-slate-100 pb-4">
            <div className="flex items-center gap-2.5">
              <div className="h-8 w-8 rounded-lg bg-amber-50 text-amber-700 flex items-center justify-center">
                <MapPin className="h-4 w-4" />
              </div>
              <h3 className="text-sm font-bold text-slate-900 font-mono">Unresolved Verification Gates</h3>
            </div>
            <span className="text-[10px] font-mono px-2 py-0.5 rounded-full bg-amber-50 text-amber-800 border border-amber-300 font-bold">
              PENDING
            </span>
          </div>

          <div className="space-y-4 text-xs">
            <div className="space-y-1">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Physical Business Address</span>
                <span className="text-[10px] font-mono text-amber-700 font-bold">PENDING_VERIFICATION</span>
              </div>
              <p className="text-slate-600 bg-amber-50/50 p-2.5 rounded-lg border border-amber-200/60 leading-relaxed">
                Official establishment address in India pending formal confirmation. Website URLs must never be published or substituted as a physical address.
              </p>
            </div>

            <div className="space-y-1">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Grievance Officer Appointment</span>
                <span className="text-[10px] font-mono text-amber-700 font-bold">PENDING_VERIFICATION</span>
              </div>
              <p className="text-slate-600 bg-amber-50/50 p-2.5 rounded-lg border border-amber-200/60 leading-relaxed">
                Formal statutory appointment order under Information Technology Rules pending execution. Do not automatically appoint proprietor as Grievance Officer.
              </p>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}

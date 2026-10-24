'use client';

import React, { useState, useEffect } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { useAuth } from '@/lib/auth';
import { adminApi } from '@/lib/api';
import { auth } from '@/lib/firebase';
import { sendPasswordResetEmail } from 'firebase/auth';
import {
  ShieldCheck,
  Server,
  Database,
  Cloud,
  Lock,
  CheckCircle2,
  KeyRound,
  Terminal,
  Activity,
  Layers,
  Cpu,
  FileCode,
  Download,
  Copy,
  Check,
  HardDrive,
  Sliders,
  Sparkles,
  ExternalLink,
  RefreshCw,
  User,
  Mail,
  Phone,
  Building,
  MapPin,
  GraduationCap,
  Bell,
  Save,
  AlertTriangle,
  UserCheck,
} from 'lucide-react';

export default function SettingsPage() {
  const { user } = useAuth();

  // Governance & CAD engine interactive state
  const [multiDiscipline, setMultiDiscipline] = useState<boolean>(true);
  const [turnaround, setTurnaround] = useState<string>('72 Hours Standard');
  const [autoRasterizer, setAutoRasterizer] = useState<boolean>(true);
  const [strictLayerCompliance, setStrictLayerCompliance] = useState<boolean>(true);
  const [maxUploadCeiling, setMaxUploadCeiling] = useState<string>('500 MB per DWG');
  const [inviteToken, setInviteToken] = useState<string>('CAD-STU-8819-XYZ');
  const [copiedToken, setCopiedToken] = useState<boolean>(false);
  const [activeTab, setActiveTab] = useState<'profile' | 'governance' | 'infrastructure' | 'security'>('profile');

  // Admin Profile form state
  const [profileName, setProfileName] = useState<string>('Studio Administrator');
  const [profileMobile, setProfileMobile] = useState<string>('+91 94440 12345');
  const [profileCompany, setProfileCompany] = useState<string>('Draughtsman Studio OS');
  const [profileAddress, setProfileAddress] = useState<string>('Studio Tower, Suite 400');
  const [profileQualification, setProfileQualification] = useState<string>('Principal Architectural Lead');
  const [profileSaving, setProfileSaving] = useState<boolean>(false);
  const [profileSuccess, setProfileSuccess] = useState<string | null>(null);
  const [profileError, setProfileError] = useState<string | null>(null);

  // Security & Password Reset state
  const [sendingReset, setSendingReset] = useState<boolean>(false);
  const [resetSuccess, setResetSuccess] = useState<string | null>(null);
  const [resetError, setResetError] = useState<string | null>(null);

  // Notification Preferences state
  const [notifySubmissions, setNotifySubmissions] = useState<boolean>(true);
  const [notifyAssignments, setNotifyAssignments] = useState<boolean>(true);
  const [notifyCorrections, setNotifyCorrections] = useState<boolean>(true);
  const [notifyDigest, setNotifyDigest] = useState<boolean>(false);

  // Persisted Studio Governance Settings state
  const [settingsLoading, setSettingsLoading] = useState<boolean>(true);
  const [settingsSaving, setSettingsSaving] = useState<boolean>(false);
  const [settingsSuccess, setSettingsSuccess] = useState<string | null>(null);
  const [settingsError, setSettingsError] = useState<string | null>(null);
  const [lastSettingsUpdated, setLastSettingsUpdated] = useState<string | null>(null);
  const [hasUnsavedSettings, setHasUnsavedSettings] = useState<boolean>(false);

  useEffect(() => {
    async function loadPersistedSettings() {
      try {
        setSettingsLoading(true);
        const data = await adminApi.getStudioSettings();
        if (data && data.settings) {
          if (data.settings.multiDiscipline !== undefined) setMultiDiscipline(data.settings.multiDiscipline);
          if (data.settings.turnaround) setTurnaround(data.settings.turnaround);
          if (data.settings.autoRasterizer !== undefined) setAutoRasterizer(data.settings.autoRasterizer);
          if (data.settings.strictLayerCompliance !== undefined) setStrictLayerCompliance(data.settings.strictLayerCompliance);
          if (data.settings.maxUploadCeiling) setMaxUploadCeiling(data.settings.maxUploadCeiling);
          if (data.settings.notifySubmissions !== undefined) setNotifySubmissions(data.settings.notifySubmissions);
          if (data.settings.notifyAssignments !== undefined) setNotifyAssignments(data.settings.notifyAssignments);
          if (data.settings.notifyCorrections !== undefined) setNotifyCorrections(data.settings.notifyCorrections);
          if (data.settings.notifyDigest !== undefined) setNotifyDigest(data.settings.notifyDigest);
        }
        if (data?.updated_at) setLastSettingsUpdated(data.updated_at);
        setHasUnsavedSettings(false);
      } catch (err) {
        console.warn('Failed to load persisted studio settings:', err);
      } finally {
        setSettingsLoading(false);
      }
    }
    loadPersistedSettings();
  }, []);

  const handleSaveGovernanceSettings = async () => {
    setSettingsSaving(true);
    setSettingsSuccess(null);
    setSettingsError(null);
    try {
      await adminApi.updateStudioSettings({
        multiDiscipline,
        turnaround,
        autoRasterizer,
        strictLayerCompliance,
        maxUploadCeiling,
        notifySubmissions,
        notifyAssignments,
        notifyCorrections,
        notifyDigest,
      });
      setLastSettingsUpdated(new Date().toISOString());
      setHasUnsavedSettings(false);
      setSettingsSuccess('Studio governance parameters successfully persisted to Cloudflare D1.');
      setTimeout(() => setSettingsSuccess(null), 4000);
    } catch (err: any) {
      setSettingsError(err.message || 'Failed to persist governance settings.');
    } finally {
      setSettingsSaving(false);
    }
  };

  useEffect(() => {
    if (user) {
      if (user.name) setProfileName(user.name);
      if (user.mobile) setProfileMobile(user.mobile);
      if (user.company_name) setProfileCompany(user.company_name);
      if (user.address) setProfileAddress(user.address);
      if (user.qualification) setProfileQualification(user.qualification);
    }
  }, [user]);

  const handleSaveProfile = async (e: React.FormEvent) => {
    e.preventDefault();
    setProfileSaving(true);
    setProfileSuccess(null);
    setProfileError(null);
    try {
      await adminApi.updateMe({
        name: profileName.trim(),
        mobile: profileMobile.trim(),
        companyName: profileCompany.trim(),
        address: profileAddress.trim(),
        qualification: profileQualification.trim(),
      });
      setProfileSuccess('Admin profile updated successfully on Cloudflare D1.');
      setTimeout(() => setProfileSuccess(null), 4000);
    } catch (err: any) {
      setProfileError(err.message || 'Failed to save admin profile.');
    } finally {
      setProfileSaving(false);
    }
  };

  const handleSendPasswordReset = async () => {
    const targetEmail = user?.email || 'contact@draughtsmanstudio.com';
    setSendingReset(true);
    setResetSuccess(null);
    setResetError(null);
    try {
      await sendPasswordResetEmail(auth, targetEmail);
      setResetSuccess(`Password recovery email dispatched to ${targetEmail}`);
      setTimeout(() => setResetSuccess(null), 5000);
    } catch (err: any) {
      setResetError(err.message || 'Failed to dispatch password recovery link.');
    } finally {
      setSendingReset(false);
    }
  };

  const workerUrl =
    process.env.NEXT_PUBLIC_WORKER_API_URL || 'https://archi-draft-worker.imserratex.workers.dev';
  const firebaseProject = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'archi-draft';
  const authDomain = process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'archi-draft.firebaseapp.com';

  const generateNewToken = () => {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    let rand = '';
    for (let i = 0; i < 4; i++) rand += chars.charAt(Math.floor(Math.random() * chars.length));
    const num = Math.floor(1000 + Math.random() * 9000);
    setInviteToken(`CAD-STU-${num}-${rand}`);
    setCopiedToken(false);
  };

  const copyToken = () => {
    navigator.clipboard.writeText(inviteToken);
    setCopiedToken(true);
    setTimeout(() => setCopiedToken(false), 2500);
  };

  const exportAuditJSON = () => {
    const payload = {
      exportTimestamp: new Date().toISOString(),
      platform: 'Archi Draft Studio Admin',
      administrator: user?.email || 'admin@archidraft.com',
      systemStatus: 'OPERATIONAL',
      configuration: {
        multiDiscipline,
        turnaround,
        autoRasterizer,
        strictLayerCompliance,
        maxUploadCeiling,
      },
    };
    const blob = new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `archi-draft-audit-${Date.now()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  };

  const exportAuditCSV = () => {
    const csvContent =
      'Parameter,Value,Status\n' +
      `System Status,Operational,Live\n` +
      `Multi-discipline Access,${multiDiscipline ? 'Strict' : 'Relaxed'},Active\n` +
      `Turnaround Target,"${turnaround}",Configured\n` +
      `Auto-Rasterizer,${autoRasterizer ? 'Enabled' : 'Disabled'},Active\n` +
      `AIA Layer Compliance,${strictLayerCompliance ? 'Strict' : 'Relaxed'},Enforced\n` +
      `Max Upload Limit,"${maxUploadCeiling}",Enforced\n`;

    const blob = new Blob([csvContent], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `archi-draft-config-${Date.now()}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  };

  return (
    <AdminShell
      title="System Settings & Governance"
      subtitle="Global platform parameters, CAD rendering clusters, and architectural infrastructure"
    >
      <div className="space-y-6 max-w-6xl">
        {/* ─── Top Telemetry Banner (Stitch Spec) ───────────────────────── */}
        <div className="bg-white rounded-xl p-4 sm:p-5 border border-slate-200 shadow-sm space-y-4">
          <div className="flex items-center justify-between border-b border-slate-100 pb-3 flex-wrap gap-2">
            <div className="flex items-center gap-2.5">
              <span className="relative flex h-2.5 w-2.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
              </span>
              <span className="text-xs font-mono font-bold tracking-tight text-slate-900">
                SYSTEM OPERATIONAL // L4 HIGH PRIVILEGE
              </span>
            </div>
            <div className="flex items-center gap-3 text-xs font-mono text-slate-500 flex-wrap">
              <span>LATENCY: 24ms</span>
              <span className="h-3 w-px bg-slate-200 hidden sm:inline" />
              <span>REGION: eu-west (Frankfurt)</span>
            </div>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5 sm:gap-4 text-xs">
            {/* Metric 1: CAD Engine */}
            <div className="p-3.5 rounded-lg bg-slate-50 border border-slate-200 flex items-start gap-3">
              <div className="h-8 w-8 rounded-lg bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center shrink-0">
                <Cpu className="h-4 w-4" />
              </div>
              <div>
                <span className="font-semibold text-slate-900 block">
                  CAD Engine: <span className="text-emerald-700 font-mono font-bold">ONLINE</span>
                </span>
                <p className="text-[11px] text-slate-500 font-mono mt-0.5">AutoCAD Forge API v3.4 cluster connected</p>
              </div>
            </div>

            {/* Metric 2: Storage Capacity */}
            <div className="p-3.5 rounded-lg bg-slate-50 border border-slate-200">
              <div className="flex justify-between items-baseline mb-1">
                <span className="font-semibold text-slate-900 flex items-center gap-1.5">
                  <HardDrive className="h-3.5 w-3.5 text-slate-400" /> Storage Capacity
                </span>
                <span className="text-[11px] font-mono font-bold text-slate-700">4.8 TB / 10 TB</span>
              </div>
              <div className="w-full bg-slate-200 rounded-full h-1.5 overflow-hidden mt-2">
                <div className="bg-[#0d1c32] h-1.5 rounded-full" style={{ width: '48%' }} />
              </div>
              <p className="text-[10px] text-slate-500 font-mono mt-1.5">Cloudflare R2 + S3 CAD Vault</p>
            </div>

            {/* Metric 3: Session Administrator */}
            <div className="p-3.5 rounded-lg bg-slate-50 border border-slate-200 flex items-center justify-between sm:col-span-2 lg:col-span-1">
              <div className="min-w-0 pr-2">
                <span className="font-semibold text-slate-900 block truncate">{user?.name || 'Studio Administrator'}</span>
                <p className="text-[11px] text-slate-500 font-mono truncate">{user?.email || 'admin@archidraft.com'}</p>
              </div>
              <Badge role="ADMIN" />
            </div>
          </div>
        </div>

        {/* ─── Navigation Segmented Tabs ──────────────────────────────── */}
        <div className="flex items-center gap-2 border-b border-slate-200 pb-2 overflow-x-auto w-full max-w-full scrollbar-none">
          <button
            onClick={() => setActiveTab('profile')}
            className={`px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide transition-all whitespace-nowrap ${
              activeTab === 'profile'
                ? 'bg-[#0d1c32] text-white shadow-sm'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
            }`}
          >
            00. Admin Profile & Account
          </button>
          <button
            onClick={() => setActiveTab('governance')}
            className={`px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide transition-all whitespace-nowrap ${
              activeTab === 'governance'
                ? 'bg-[#0d1c32] text-white shadow-sm'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
            }`}
          >
            01. Governance & CAD Engine
          </button>
          <button
            onClick={() => setActiveTab('infrastructure')}
            className={`px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide transition-all whitespace-nowrap ${
              activeTab === 'infrastructure'
                ? 'bg-[#0d1c32] text-white shadow-sm'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
            }`}
          >
            02. Gateways & Infrastructure
          </button>
          <button
            onClick={() => setActiveTab('security')}
            className={`px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide transition-all whitespace-nowrap ${
              activeTab === 'security'
                ? 'bg-[#0d1c32] text-white shadow-sm'
                : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
            }`}
          >
            03. Security Architecture & D1
          </button>
        </div>

        {/* ─── TAB 0: Admin Profile & Account Settings (Stitch Spec 4ee871db6a7e49d3b29a16dae5f38f9c) ─── */}
        {activeTab === 'profile' && (
          <div className="space-y-6">
            {/* Feedback Notifications */}
            {profileSuccess && (
              <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-mono flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                <span>{profileSuccess}</span>
              </div>
            )}
            {profileError && (
              <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{profileError}</span>
              </div>
            )}
            {resetSuccess && (
              <div className="p-4 rounded-xl bg-blue-50 border border-blue-200 text-blue-800 text-xs font-mono flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-blue-600 shrink-0" />
                <span>{resetSuccess}</span>
              </div>
            )}
            {resetError && (
              <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{resetError}</span>
              </div>
            )}

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Left Column (2/3): Profile Edit Form */}
              <div className="lg:col-span-2 space-y-6">
                <Card className="bg-white border-slate-200 soft-elevation">
                  <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60 flex items-center justify-between">
                    <div>
                      <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                        <User className="h-4 w-4 text-[#0453cd]" />
                        <span>Studio Administrator Profile</span>
                      </h3>
                      <p className="text-xs text-slate-500 mt-0.5">
                        Manage your administrative identification and studio credentials
                      </p>
                    </div>
                    <Badge role="ADMIN" />
                  </div>

                  <form onSubmit={handleSaveProfile} className="p-6 space-y-4">
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      {/* Name */}
                      <div className="space-y-1.5">
                        <label className="block text-[11px] font-mono font-semibold text-slate-700 uppercase tracking-wider">
                          Full Name
                        </label>
                        <div className="relative">
                          <User className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                          <input
                            type="text"
                            value={profileName}
                            onChange={(e) => setProfileName(e.target.value)}
                            placeholder="Studio Administrator"
                            required
                            className="w-full pl-9 pr-3 py-2 bg-[#fbf9fb] border border-slate-300/80 rounded-lg text-xs text-slate-900 font-sans outline-none focus:border-[#0453cd] focus:ring-1 focus:ring-blue-500/20"
                          />
                        </div>
                      </div>

                      {/* Email (Readonly authentication identifier) */}
                      <div className="space-y-1.5">
                        <label className="block text-[11px] font-mono font-semibold text-slate-700 uppercase tracking-wider">
                          Primary Email (Auth Identifier)
                        </label>
                        <div className="relative">
                          <Mail className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                          <input
                            type="email"
                            value={user?.email || 'contact@draughtsmanstudio.com'}
                            disabled
                            className="w-full pl-9 pr-3 py-2 bg-slate-100 border border-slate-200 rounded-lg text-xs text-slate-500 font-mono cursor-not-allowed select-none"
                          />
                        </div>
                      </div>

                      {/* Mobile */}
                      <div className="space-y-1.5">
                        <label className="block text-[11px] font-mono font-semibold text-slate-700 uppercase tracking-wider">
                          Direct Telephone
                        </label>
                        <div className="relative">
                          <Phone className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                          <input
                            type="text"
                            value={profileMobile}
                            onChange={(e) => setProfileMobile(e.target.value)}
                            placeholder="+91 94440 12345"
                            className="w-full pl-9 pr-3 py-2 bg-[#fbf9fb] border border-slate-300/80 rounded-lg text-xs text-slate-900 font-sans outline-none focus:border-[#0453cd] focus:ring-1 focus:ring-blue-500/20"
                          />
                        </div>
                      </div>

                      {/* Company / Brand */}
                      <div className="space-y-1.5">
                        <label className="block text-[11px] font-mono font-semibold text-slate-700 uppercase tracking-wider">
                          Studio / Enterprise Entity
                        </label>
                        <div className="relative">
                          <Building className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                          <input
                            type="text"
                            value={profileCompany}
                            onChange={(e) => setProfileCompany(e.target.value)}
                            placeholder="Draughtsman Studio OS"
                            className="w-full pl-9 pr-3 py-2 bg-[#fbf9fb] border border-slate-300/80 rounded-lg text-xs text-slate-900 font-sans outline-none focus:border-[#0453cd] focus:ring-1 focus:ring-blue-500/20"
                          />
                        </div>
                      </div>
                    </div>

                    {/* Studio Address */}
                    <div className="space-y-1.5">
                      <label className="block text-[11px] font-mono font-semibold text-slate-700 uppercase tracking-wider">
                        Operating Office Location
                      </label>
                      <div className="relative">
                        <MapPin className="h-4 w-4 text-slate-400 absolute left-3 top-3" />
                        <input
                          type="text"
                          value={profileAddress}
                          onChange={(e) => setProfileAddress(e.target.value)}
                          placeholder="PixelMint Studio MVS · Chennai & Global HQ"
                          className="w-full pl-9 pr-3 py-2 bg-[#fbf9fb] border border-slate-300/80 rounded-lg text-xs text-slate-900 font-sans outline-none focus:border-[#0453cd] focus:ring-1 focus:ring-blue-500/20"
                        />
                      </div>
                    </div>

                    {/* Qualification */}
                    <div className="space-y-1.5">
                      <label className="block text-[11px] font-mono font-semibold text-slate-700 uppercase tracking-wider">
                        Executive Title & Governance Mandate
                      </label>
                      <div className="relative">
                        <GraduationCap className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                        <input
                          type="text"
                          value={profileQualification}
                          onChange={(e) => setProfileQualification(e.target.value)}
                          placeholder="Principal Architectural Lead & Ecosystem Custodian"
                          className="w-full pl-9 pr-3 py-2 bg-[#fbf9fb] border border-slate-300/80 rounded-lg text-xs text-slate-900 font-sans outline-none focus:border-[#0453cd] focus:ring-1 focus:ring-blue-500/20"
                        />
                      </div>
                    </div>

                    <div className="pt-3 border-t border-slate-100 flex items-center justify-between">
                      <p className="text-[10px] font-mono text-slate-400">
                        Updates sync immediately to Cloudflare D1 via <code className="bg-slate-100 px-1 py-0.5 rounded text-slate-700">PATCH /api/users/me</code>
                      </p>
                      <Button
                        type="submit"
                        disabled={profileSaving}
                        className="bg-[#0d1c32] hover:bg-[#15294a] text-white flex items-center gap-1.5"
                      >
                        {profileSaving ? (
                          <>
                            <span className="h-3.5 w-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />
                            <span>Saving Changes...</span>
                          </>
                        ) : (
                          <>
                            <Save className="h-3.5 w-3.5" />
                            <span>Save Profile</span>
                          </>
                        )}
                      </Button>
                    </div>
                  </form>
                </Card>

                {/* Notification Dispatch Preferences */}
                <Card className="bg-white border-slate-200 soft-elevation">
                  <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60 flex items-center justify-between">
                    <div>
                      <h3 className="text-sm font-bold text-slate-900 flex items-center gap-2">
                        <Bell className="h-4 w-4 text-[#0453cd]" />
                        <span>Studio Notification Dispatch</span>
                      </h3>
                      <p className="text-xs text-slate-500 mt-0.5">
                        Configure event routing and high-priority escalation triggers
                      </p>
                    </div>
                  </div>

                  <div className="p-6 space-y-4 text-xs">
                    {[
                      {
                        title: 'New Project Intake Alerts',
                        desc: 'Notify administrator immediately when an Engineer submits a new project brief',
                        state: notifySubmissions,
                        setter: setNotifySubmissions,
                      },
                      {
                        title: 'Draughtsman Assignment Responses',
                        desc: 'Trigger dispatch alert when a draughtsman accepts or declines an assigned project brief',
                        state: notifyAssignments,
                        setter: setNotifyAssignments,
                      },
                      {
                        title: 'Correction Cap Escalation Monitoring',
                        desc: 'Escalate to administrator review when an engineer initiates round 2 or round 3 corrections',
                        state: notifyCorrections,
                        setter: setNotifyCorrections,
                      },
                      {
                        title: 'Daily Financial & Ledger Snapshot',
                        desc: 'Generate automated daily collection digest and pipeline reconciliation reports',
                        state: notifyDigest,
                        setter: setNotifyDigest,
                      },
                    ].map((item, idx) => (
                      <div key={idx} className="flex items-start justify-between gap-4 p-3.5 rounded-xl border border-slate-200 bg-slate-50">
                        <div className="space-y-0.5">
                          <p className="font-semibold text-slate-900">{item.title}</p>
                          <p className="text-[11px] text-slate-500 font-sans">{item.desc}</p>
                        </div>
                        <input
                          type="checkbox"
                          checked={item.state}
                          onChange={(e) => item.setter(e.target.checked)}
                          className="h-4 w-4 rounded border-slate-300 text-[#0453cd] focus:ring-[#0453cd] cursor-pointer mt-0.5"
                        />
                      </div>
                    ))}
                  </div>
                </Card>
              </div>

              {/* Right Column (1/3): Security & Access Controls */}
              <div className="space-y-6">
                {/* Account Security Card */}
                <Card className="bg-white border-slate-200 soft-elevation">
                  <div className="px-5 py-4 border-b border-slate-100 bg-slate-50/60">
                    <h3 className="text-xs font-bold font-mono uppercase tracking-wider text-slate-900 flex items-center gap-2">
                      <Lock className="h-3.5 w-3.5 text-[#0453cd]" />
                      <span>Security & Authentication</span>
                    </h3>
                  </div>

                  <div className="p-5 space-y-4 text-xs">
                    <div className="p-3 rounded-lg bg-blue-50 border border-blue-200 space-y-1">
                      <div className="flex items-center gap-1.5 text-[#0453cd] font-semibold text-[11px] font-mono">
                        <ShieldCheck className="h-3.5 w-3.5" />
                        <span>ROLE_ADMIN_MANDATE</span>
                      </div>
                      <p className="text-[11px] text-slate-700 leading-relaxed font-sans">
                        Admin role is enforced by Cloudflare D1 RBAC. Self-escalation and public registration are rejected by policy.
                      </p>
                    </div>

                    <div className="space-y-2">
                      <p className="text-[11px] font-mono font-semibold text-slate-700 uppercase">
                        Account Password Management
                      </p>
                      <p className="text-[11px] text-slate-500 font-sans leading-relaxed">
                        To rotate or reset your administrative credentials securely, trigger an authorized recovery email:
                      </p>
                      <button
                        type="button"
                        onClick={handleSendPasswordReset}
                        disabled={sendingReset}
                        className="w-full mt-2 py-2 px-3 rounded-lg border border-slate-300 hover:border-slate-400 bg-white hover:bg-slate-50 text-slate-800 font-mono text-xs font-semibold flex items-center justify-center gap-2 transition-all cursor-pointer shadow-xs disabled:opacity-50"
                      >
                        {sendingReset ? (
                          <>
                            <span className="h-3 w-3 border-2 border-slate-600 border-t-transparent rounded-full animate-spin" />
                            <span>Dispatching Link...</span>
                          </>
                        ) : (
                          <>
                            <KeyRound className="h-3.5 w-3.5 text-[#0453cd]" />
                            <span>Send Password Reset Email</span>
                          </>
                        )}
                      </button>
                    </div>
                  </div>
                </Card>

                {/* Session Diagnostics */}
                <Card className="bg-white border-slate-200 soft-elevation">
                  <div className="px-5 py-4 border-b border-slate-100 bg-slate-50/60">
                    <h3 className="text-xs font-bold font-mono uppercase tracking-wider text-slate-900 flex items-center gap-2">
                      <Activity className="h-3.5 w-3.5 text-emerald-600" />
                      <span>Session Diagnostics</span>
                    </h3>
                  </div>

                  <div className="p-5 space-y-3 font-mono text-[11px] divide-y divide-slate-100">
                    <div className="flex justify-between items-center pt-1">
                      <span className="text-slate-500">Session ID:</span>
                      <span className="text-slate-800 font-bold">{(user?.id || 'dev-admin-uid').substring(0, 10)}…</span>
                    </div>
                    <div className="flex justify-between items-center pt-2">
                      <span className="text-slate-500">Token Type:</span>
                      <span className="text-emerald-700 font-semibold bg-emerald-50 px-1.5 py-0.5 rounded border border-emerald-200">
                        Google JWKS Bearer
                      </span>
                    </div>
                    <div className="flex justify-between items-center pt-2">
                      <span className="text-slate-500">Protocol:</span>
                      <span className="text-slate-800">TLS 1.3 / HTTP 2</span>
                    </div>
                    <div className="flex justify-between items-center pt-2">
                      <span className="text-slate-500">API Gateway:</span>
                      <span className="text-[#0453cd] font-semibold truncate max-w-[150px]">
                        archi-draft-worker
                      </span>
                    </div>
                  </div>
                </Card>
              </div>
            </div>
          </div>
        )}

        {/* ─── TAB 1: Governance & CAD Engine (Stitch Spec) ────────────── */}
        {activeTab === 'governance' && (
          <div className="space-y-6">
            {/* Feedback Notifications */}
            {settingsSuccess && (
              <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-mono flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                <span>{settingsSuccess}</span>
              </div>
            )}
            {settingsError && (
              <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertTriangle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{settingsError}</span>
              </div>
            )}

            {/* Authoritative D1 Persistence Action Bar */}
            <div className="p-4 rounded-xl bg-white border border-slate-200 flex items-center justify-between gap-4 flex-wrap shadow-xs">
              <div>
                <p className="text-xs font-bold font-mono text-slate-900 flex items-center gap-2">
                  <Sliders className="h-4 w-4 text-[#0453cd]" />
                  <span>D1 Studio Governance State</span>
                  {hasUnsavedSettings ? (
                    <span className="text-[10px] font-mono bg-amber-50 text-amber-700 px-2 py-0.5 rounded border border-amber-200 font-bold">
                      UNSAVED CHANGES
                    </span>
                  ) : (
                    <span className="text-[10px] font-mono bg-emerald-50 text-emerald-700 px-2 py-0.5 rounded border border-emerald-200 font-bold">
                      SYNCHRONIZED
                    </span>
                  )}
                </p>
                <p className="text-[11px] text-slate-500 font-sans mt-0.5">
                  {lastSettingsUpdated
                    ? `Authoritative D1 sync: ${new Date(lastSettingsUpdated).toLocaleString()}`
                    : 'Parameters are persisted to Cloudflare D1 and enforced on API operations'}
                </p>
              </div>

              <Button
                variant="primary"
                size="sm"
                disabled={settingsSaving || !hasUnsavedSettings}
                onClick={handleSaveGovernanceSettings}
                className="flex items-center gap-1.5 text-xs font-mono"
              >
                {settingsSaving ? (
                  <>
                    <span className="h-3 w-3 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Persisting to D1…</span>
                  </>
                ) : (
                  <>
                    <Save className="h-3.5 w-3.5" />
                    <span>Save Governance Parameters</span>
                  </>
                )}
              </Button>
            </div>

            {/* Section 01: Team Governance */}
            <Card>
              <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60 flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">01. Team Governance & Provisioning</h3>
                  <p className="text-xs text-slate-500 mt-0.5">Control apprentice invitation tokens and discipline isolation</p>
                </div>
                <span className="text-[10px] font-mono text-slate-500 uppercase tracking-widest bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                  Policy L4
                </span>
              </div>

              <div className="divide-y divide-slate-100">
                {/* Setting 1: Provisioning Token */}
                <div className="p-6 space-y-3">
                  <div className="flex items-start justify-between gap-4 flex-wrap">
                    <div>
                      <p className="text-sm font-semibold text-slate-900">Invite Codes & Provisioning</p>
                      <p className="text-xs text-slate-500 mt-0.5">Generate single-use verification token for high-privilege draftsperson</p>
                    </div>
                    <Button variant="outline" size="sm" onClick={generateNewToken} className="flex items-center gap-1.5">
                      <RefreshCw className="h-3 w-3" />
                      <span>Generate Token</span>
                    </Button>
                  </div>
                  <div className="bg-slate-50 border border-dashed border-slate-300 rounded-xl px-4 py-3 flex items-center justify-between max-w-md">
                    <span className="text-sm font-mono font-bold text-slate-800 tracking-wider">{inviteToken}</span>
                    <button
                      onClick={copyToken}
                      className="flex items-center gap-1 text-xs font-mono font-semibold text-[#0453cd] hover:text-[#0342a6] px-2 py-1 rounded hover:bg-blue-50 transition-colors"
                    >
                      {copiedToken ? <Check className="h-3.5 w-3.5 text-emerald-600" /> : <Copy className="h-3.5 w-3.5" />}
                      <span>{copiedToken ? 'Copied' : 'Copy'}</span>
                    </button>
                  </div>
                </div>

                {/* Setting 2: Role Isolation Toggle */}
                <div className="p-6 flex items-center justify-between gap-4 flex-wrap">
                  <div>
                    <p className="text-sm font-semibold text-slate-900">Multi-discipline Access Control</p>
                    <p className="text-xs text-slate-500 mt-0.5">Strict Role Isolation between Architectural, Structural & MEP teams</p>
                  </div>
                  <button
                    onClick={() => {
                      setMultiDiscipline(!multiDiscipline);
                      setHasUnsavedSettings(true);
                    }}
                    className={`w-12 h-6 rounded-full p-0.5 transition-colors shrink-0 focus:outline-none ${
                      multiDiscipline ? 'bg-[#0d1c32]' : 'bg-slate-300'
                    }`}
                  >
                    <span
                      className={`block w-5 h-5 bg-white rounded-full shadow-sm transform transition-transform ${
                        multiDiscipline ? 'translate-x-6' : 'translate-x-0'
                      }`}
                    />
                  </button>
                </div>

                {/* Setting 3: Turnaround Review Selector */}
                <div className="p-6 flex items-center justify-between gap-4 flex-wrap">
                  <div>
                    <p className="text-sm font-semibold text-slate-900">Drawing Review Turnaround Target</p>
                    <p className="text-xs text-slate-500 mt-0.5">Baseline QA validation SLA for newly uploaded drafts</p>
                  </div>
                  <select
                    value={turnaround}
                    onChange={(e) => {
                      setTurnaround(e.target.value);
                      setHasUnsavedSettings(true);
                    }}
                    className="text-xs font-mono font-semibold text-slate-800 border border-slate-300 rounded-lg py-2 pl-3 pr-8 bg-white focus:outline-none focus:ring-2 focus:ring-[#0453cd]"
                  >
                    <option>72 Hours Standard</option>
                    <option>48 Hours Expedited</option>
                    <option>24 Hours Priority</option>
                  </select>
                </div>
              </div>
            </Card>

            {/* Section 02: Technical CAD Engine */}
            <Card>
              <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60 flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">02. Technical CAD Engine Specifications</h3>
                  <p className="text-xs text-slate-500 mt-0.5">Rendering resolution, AIA layer rules, and file payload constraints</p>
                </div>
                <span className="text-[10px] font-mono text-slate-500 uppercase tracking-widest bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                  v3.4 Cluster
                </span>
              </div>

              <div className="divide-y divide-slate-100">
                {/* CAD Toggle 1: Auto-Rasterizer */}
                <div className="p-6 flex items-center justify-between gap-4 flex-wrap">
                  <div>
                    <p className="text-sm font-semibold text-slate-900">DWG Web Auto-Rasterizer</p>
                    <p className="text-xs text-slate-500 mt-0.5">Generate 300 DPI web-safe previews automatically upon file upload</p>
                  </div>
                  <button
                    onClick={() => {
                      setAutoRasterizer(!autoRasterizer);
                      setHasUnsavedSettings(true);
                    }}
                    className={`w-12 h-6 rounded-full p-0.5 transition-colors shrink-0 focus:outline-none ${
                      autoRasterizer ? 'bg-[#0d1c32]' : 'bg-slate-300'
                    }`}
                  >
                    <span
                      className={`block w-5 h-5 bg-white rounded-full shadow-sm transform transition-transform ${
                        autoRasterizer ? 'translate-x-6' : 'translate-x-0'
                      }`}
                    />
                  </button>
                </div>

                {/* CAD Toggle 2: AIA Compliance */}
                <div className="p-6 flex items-center justify-between gap-4 flex-wrap">
                  <div>
                    <p className="text-sm font-semibold text-slate-900">Strict Layer Standard Compliance</p>
                    <p className="text-xs text-slate-500 mt-0.5">Enforce American Institute of Architects (AIA) CAD standard layer conventions</p>
                  </div>
                  <button
                    onClick={() => {
                      setStrictLayerCompliance(!strictLayerCompliance);
                      setHasUnsavedSettings(true);
                    }}
                    className={`w-12 h-6 rounded-full p-0.5 transition-colors shrink-0 focus:outline-none ${
                      strictLayerCompliance ? 'bg-[#0d1c32]' : 'bg-slate-300'
                    }`}
                  >
                    <span
                      className={`block w-5 h-5 bg-white rounded-full shadow-sm transform transition-transform ${
                        strictLayerCompliance ? 'translate-x-6' : 'translate-x-0'
                      }`}
                    />
                  </button>
                </div>

                {/* CAD Limit Selector */}
                <div className="p-6 flex items-center justify-between gap-4 flex-wrap">
                  <div>
                    <p className="text-sm font-semibold text-slate-900">Max File Upload Ceiling</p>
                    <p className="text-xs text-slate-500 mt-0.5">Buffer limit for raw CAD geometry packets streamed through Cloudflare R2</p>
                  </div>
                  <select
                    value={maxUploadCeiling}
                    onChange={(e) => {
                      setMaxUploadCeiling(e.target.value);
                      setHasUnsavedSettings(true);
                    }}
                    className="text-xs font-mono font-semibold text-slate-800 border border-slate-300 rounded-lg py-2 pl-3 pr-8 bg-white focus:outline-none focus:ring-2 focus:ring-[#0453cd]"
                  >
                    <option>500 MB per DWG</option>
                    <option>1000 MB per DWG</option>
                    <option>250 MB (Strict)</option>
                  </select>
                </div>
              </div>
            </Card>

            {/* Section 03: Gateways & Audit Exports */}
            <Card>
              <div className="px-6 py-4 border-b border-slate-100 bg-slate-50/60 flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-bold text-slate-900">03. Gateways & Audit Trail Exports</h3>
                  <p className="text-xs text-slate-500 mt-0.5">Live webhook state and exportable security ledger records</p>
                </div>
              </div>

              <div className="p-6 space-y-6">
                {/* Hook Status */}
                <div className="flex items-center justify-between p-4 rounded-xl border border-slate-200 bg-slate-50 flex-wrap gap-3">
                  <div className="flex items-center gap-3">
                    <div className="w-9 h-9 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center justify-center font-bold">
                      <Activity className="h-4 w-4" />
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-slate-900">Cloudflare D1 Activity & Event Webhook</p>
                      <div className="flex items-center gap-1.5 mt-0.5">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                        <span className="text-xs font-mono text-emerald-700 font-medium">Connected & Polling (15s cadence)</span>
                      </div>
                    </div>
                  </div>
                  <span className="font-mono text-[10px] uppercase text-slate-600 bg-white px-2.5 py-1 rounded-md border border-slate-200 font-semibold">
                    v2.4 Live
                  </span>
                </div>

                {/* Audit Log Export */}
                <div className="space-y-3">
                  <div>
                    <p className="text-xs font-semibold text-slate-900">Export System Configuration & Audit Logs</p>
                    <p className="text-[11px] text-slate-500">Download snapshot of active studio parameters and security tokens</p>
                  </div>
                  <div className="flex gap-3">
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={exportAuditJSON}
                      className="flex-1 flex items-center justify-center gap-2 text-xs font-mono font-semibold"
                    >
                      <Download className="h-3.5 w-3.5 text-[#0453cd]" />
                      <span>Download .JSON Snapshot</span>
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      onClick={exportAuditCSV}
                      className="flex-1 flex items-center justify-center gap-2 text-xs font-mono font-semibold"
                    >
                      <Download className="h-3.5 w-3.5 text-emerald-600" />
                      <span>Download .CSV Table</span>
                    </Button>
                  </div>
                </div>
              </div>
            </Card>
          </div>
        )}

        {/* ─── TAB 2: Gateways & Infrastructure ────────────────────────── */}
        {activeTab === 'infrastructure' && (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <Card>
              <div className="flex items-center gap-2.5 mb-3">
                <div className="h-8 w-8 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center justify-center">
                  <Server className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Cloudflare Worker API Gateway</h3>
                  <p className="text-[11px] text-slate-500">Authoritative Hono REST API routing</p>
                </div>
              </div>
              <p className="text-xs text-slate-600 mb-4 leading-relaxed">
                All admin panel operations route through this authoritative Worker endpoint. Direct client access to D1 is strictly blocked.
              </p>
              <div className="space-y-2.5 text-xs font-mono">
                <div className="p-3 rounded-lg bg-slate-50 border border-slate-200 break-all text-slate-700">
                  <span className="text-slate-400 block text-[10px] uppercase font-sans font-semibold mb-0.5">Gateway Endpoint</span>
                  {workerUrl}
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-700">
                  <span className="text-slate-400 text-[10px] uppercase font-sans font-semibold">Protocol</span>
                  <span className="font-semibold text-slate-900">HTTPS / HTTP/2</span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-700">
                  <span className="text-slate-400 text-[10px] uppercase font-sans font-semibold">State Engine</span>
                  <span className="text-emerald-700 font-sans font-semibold text-xs">Authoritative</span>
                </div>
              </div>
            </Card>

            <Card>
              <div className="flex items-center gap-2.5 mb-3">
                <div className="h-8 w-8 rounded-lg bg-amber-50 border border-amber-200 text-amber-700 flex items-center justify-center">
                  <KeyRound className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Firebase Identity Provider</h3>
                  <p className="text-[11px] text-slate-500">Shared auth across web & mobile portals</p>
                </div>
              </div>
              <p className="text-xs text-slate-600 mb-4 leading-relaxed">
                Shared identity directory with Archi Draft mobile portals (Engineers, Draughtsmen, and Students).
              </p>
              <div className="space-y-2.5 text-xs font-mono">
                <div className="p-3 rounded-lg bg-slate-50 border border-slate-200 break-all text-slate-700">
                  <span className="text-slate-400 block text-[10px] uppercase font-sans font-semibold mb-0.5">Project ID</span>
                  {firebaseProject}
                </div>
                <div className="p-3 rounded-lg bg-slate-50 border border-slate-200 break-all text-slate-700">
                  <span className="text-slate-400 block text-[10px] uppercase font-sans font-semibold mb-0.5">Auth Domain</span>
                  {authDomain}
                </div>
                <div className="flex items-center justify-between p-3 rounded-lg bg-slate-50 border border-slate-200 text-slate-700">
                  <span className="text-slate-400 text-[10px] uppercase font-sans font-semibold">Token Verification</span>
                  <span className="text-[#0453cd] font-sans font-semibold text-xs">Google JWKS (jose)</span>
                </div>
              </div>
            </Card>
          </div>
        )}

        {/* ─── TAB 3: Security Architecture & D1 ───────────────────────── */}
        {activeTab === 'security' && (
          <div className="space-y-6">
            <Card>
              <CardHeader
                title="Archi Draft Master Security & Architectural Compliance"
                subtitle="Verified against the Master Engineering Directive and Phase 0 Audit"
              />

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1.5">
                  <div className="flex items-center gap-2 text-emerald-700 text-xs font-bold">
                    <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
                    <span>Three-Layer Security Verification</span>
                  </div>
                  <p className="text-xs text-slate-600 leading-relaxed pl-6">
                    UI authorization is never trusted. Every write action checks Bearer token, decodes UID, and validates <code className="bg-white border border-slate-200 px-1 py-0.5 rounded text-slate-800 font-mono">role === &apos;ADMIN&apos;</code> in D1 before mutating state.
                  </p>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1.5">
                  <div className="flex items-center gap-2 text-emerald-700 text-xs font-bold">
                    <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
                    <span>Backend Idempotency (actionId)</span>
                  </div>
                  <p className="text-xs text-slate-600 leading-relaxed pl-6">
                    All status transitions generate a cryptographically random UUID v4 <code className="bg-white border border-slate-200 px-1 py-0.5 rounded text-slate-800 font-mono">actionId</code> sent with requests to prevent duplicate state executions.
                  </p>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1.5">
                  <div className="flex items-center gap-2 text-emerald-700 text-xs font-bold">
                    <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
                    <span>Cloudflare R2 File Streaming</span>
                  </div>
                  <p className="text-xs text-slate-600 leading-relaxed pl-6">
                    CAD files and PDFs stream directly through authorized Worker endpoints with strict 50MB stream limits and content-type enforcement.
                  </p>
                </div>

                <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-1.5">
                  <div className="flex items-center gap-2 text-emerald-700 text-xs font-bold">
                    <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
                    <span>Correction Round Limit (Max 3)</span>
                  </div>
                  <p className="text-xs text-slate-600 leading-relaxed pl-6">
                    Engineer correction requests are capped at 3 rounds server-side, preventing infinite scope creep while providing full visibility in the admin console.
                  </p>
                </div>
              </div>
            </Card>

            {/* Admin Account Provisioning Guide */}
            <Card>
              <div className="flex items-center gap-2 mb-2 text-xs font-bold uppercase tracking-wider text-slate-700">
                <Terminal className="h-4 w-4 text-[#0453cd]" />
                <span>Admin Account Provisioning Protocol</span>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed mb-3">
                Admin accounts cannot register via public registration. To seed a new Studio Admin, execute the following SQL statement in the Cloudflare D1 database:
              </p>
              <div className="p-3.5 rounded-xl bg-slate-900 font-mono text-xs text-blue-300 overflow-x-auto shadow-sm">
                INSERT INTO users (id, email, name, role) VALUES (&apos;&lt;FIREBASE_UID&gt;&apos;, &apos;admin@archidraft.com&apos;, &apos;Studio Admin&apos;, &apos;ADMIN&apos;);
              </div>
            </Card>
          </div>
        )}
      </div>
    </AdminShell>
  );
}

'use client';

import React from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { useAuth } from '@/lib/auth';
import {
  ShieldCheck,
  Server,
  Database,
  Cloud,
  Lock,
  CheckCircle2,
  KeyRound,
  Terminal,
} from 'lucide-react';

export default function SettingsPage() {
  const { user } = useAuth();

  const workerUrl =
    process.env.NEXT_PUBLIC_WORKER_API_URL || 'https://archi-draft-worker.imserratex.workers.dev';
  const firebaseProject = process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || 'archi-draft';
  const authDomain = process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || 'archi-draft.firebaseapp.com';

  return (
    <AdminShell
      title="System Settings & Infrastructure Health"
      subtitle="Cloudflare Worker API connectivity, Firebase parameters, and architectural compliance"
    >
      <div className="space-y-6 max-w-5xl">
        {/* Active Session Info */}
        <Card className="border-blue-900/40 bg-gradient-to-r from-[#0b1426] to-[#0f172a]">
          <CardHeader
            title="Authenticated Studio Administrator Profile"
            subtitle="Verified against Firebase Authentication JWKS and Cloudflare D1 users table"
          />
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mt-2 text-xs">
            <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
              <span className="text-slate-400">Admin Name</span>
              <p className="text-sm font-semibold text-slate-100 mt-0.5">{user?.name || 'Administrator'}</p>
            </div>
            <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
              <span className="text-slate-400">Authenticated Email</span>
              <p className="text-sm font-semibold text-slate-100 mt-0.5">{user?.email || 'N/A'}</p>
            </div>
            <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
              <span className="text-slate-400">Authorized Role</span>
              <div className="mt-1">
                <Badge role="ADMIN" />
              </div>
            </div>
          </div>
        </Card>

        {/* Backend Connectivity & Environment */}
        <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
          <Card>
            <div className="flex items-center gap-2 mb-3">
              <Server className="h-4 w-4 text-emerald-400" />
              <h3 className="text-sm font-semibold text-slate-100">Cloudflare Worker API Gateway</h3>
            </div>
            <p className="text-xs text-slate-400 mb-4 leading-relaxed">
              All admin panel operations route through this authoritative Hono REST API. Direct D1 access is strictly prohibited.
            </p>
            <div className="space-y-2.5 text-xs font-mono">
              <div className="p-2.5 rounded-lg bg-slate-900 border border-slate-800 break-all text-slate-300">
                <span className="text-slate-500 block text-[10px] uppercase font-sans">Gateway Endpoint</span>
                {workerUrl}
              </div>
              <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900 border border-slate-800 text-slate-300">
                <span className="text-slate-500 text-[10px] uppercase font-sans">Protocol</span>
                <span>HTTPS / HTTP/2</span>
              </div>
              <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900 border border-slate-800 text-slate-300">
                <span className="text-slate-500 text-[10px] uppercase font-sans">State Engine</span>
                <span className="text-emerald-400 font-sans font-semibold text-xs">Authoritative</span>
              </div>
            </div>
          </Card>

          <Card>
            <div className="flex items-center gap-2 mb-3">
              <KeyRound className="h-4 w-4 text-amber-400" />
              <h3 className="text-sm font-semibold text-slate-100">Firebase Identity Provider</h3>
            </div>
            <p className="text-xs text-slate-400 mb-4 leading-relaxed">
              Shared identity directory with the Archi Draft mobile portals (Engineers, Draughtsmen, and Students).
            </p>
            <div className="space-y-2.5 text-xs font-mono">
              <div className="p-2.5 rounded-lg bg-slate-900 border border-slate-800 break-all text-slate-300">
                <span className="text-slate-500 block text-[10px] uppercase font-sans">Project ID</span>
                {firebaseProject}
              </div>
              <div className="p-2.5 rounded-lg bg-slate-900 border border-slate-800 break-all text-slate-300">
                <span className="text-slate-500 block text-[10px] uppercase font-sans">Auth Domain</span>
                {authDomain}
              </div>
              <div className="flex items-center justify-between p-2.5 rounded-lg bg-slate-900 border border-slate-800 text-slate-300">
                <span className="text-slate-500 text-[10px] uppercase font-sans">Token Verification</span>
                <span className="text-blue-400 font-sans font-semibold text-xs">Google JWKS (jose)</span>
              </div>
            </div>
          </Card>
        </div>

        {/* Security Architecture Verification Checklist */}
        <Card>
          <CardHeader
            title="Archi Draft Master Security & Architectural Compliance"
            subtitle="Verified against the Master Engineering Directive and Phase 0 Audit"
          />

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-3">
            <div className="p-3.5 rounded-xl bg-slate-900 border border-slate-800/80 space-y-1.5">
              <div className="flex items-center gap-2 text-emerald-400 text-xs font-semibold">
                <CheckCircle2 className="h-4 w-4 shrink-0" />
                <span>Three-Layer Security Verification</span>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed pl-6">
                UI authorization is never trusted. Every write action checks Bearer token, decodes UID, and validates <code className="text-slate-300">role === 'ADMIN'</code> in D1 before mutating state.
              </p>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-900 border border-slate-800/80 space-y-1.5">
              <div className="flex items-center gap-2 text-emerald-400 text-xs font-semibold">
                <CheckCircle2 className="h-4 w-4 shrink-0" />
                <span>Backend Idempotency (actionId)</span>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed pl-6">
                All status transitions generate a cryptographically random UUID v4 <code className="text-slate-300">actionId</code> sent with requests to prevent duplicate state executions.
              </p>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-900 border border-slate-800/80 space-y-1.5">
              <div className="flex items-center gap-2 text-emerald-400 text-xs font-semibold">
                <CheckCircle2 className="h-4 w-4 shrink-0" />
                <span>Cloudflare R2 File Streaming</span>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed pl-6">
                CAD files and PDFs stream directly through authorized Worker endpoints with strict 50MB stream limits and content-type enforcement.
              </p>
            </div>

            <div className="p-3.5 rounded-xl bg-slate-900 border border-slate-800/80 space-y-1.5">
              <div className="flex items-center gap-2 text-emerald-400 text-xs font-semibold">
                <CheckCircle2 className="h-4 w-4 shrink-0" />
                <span>Correction Round Limit (Max 3)</span>
              </div>
              <p className="text-xs text-slate-400 leading-relaxed pl-6">
                Engineer correction requests are capped at 3 rounds server-side, preventing infinite scope creep while providing full visibility in the admin console.
              </p>
            </div>
          </div>
        </Card>

        {/* Admin Account Provisioning Guide */}
        <Card className="border-slate-800">
          <div className="flex items-center gap-2 mb-2 text-xs font-semibold uppercase tracking-wider text-slate-300">
            <Terminal className="h-4 w-4 text-blue-400" />
            <span>Admin Account Provisioning Protocol</span>
          </div>
          <p className="text-xs text-slate-400 leading-relaxed mb-3">
            Admin accounts cannot register via public registration. To seed a new Studio Admin, execute the following SQL statement in the Cloudflare D1 database:
          </p>
          <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs text-blue-300 overflow-x-auto">
            INSERT INTO users (id, email, name, role) VALUES ('&lt;FIREBASE_UID&gt;', 'admin@archidraft.com', 'Studio Admin', 'ADMIN');
          </div>
        </Card>
      </div>
    </AdminShell>
  );
}

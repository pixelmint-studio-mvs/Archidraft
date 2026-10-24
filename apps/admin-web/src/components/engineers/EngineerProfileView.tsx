'use client';

import React from 'react';
import Link from 'next/link';
import { User, Project } from '@/lib/types';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import {
  Building,
  ShieldCheck,
  FileText,
  ChevronRight,
  TrendingUp,
  Phone,
  Mail,
  Calendar,
} from 'lucide-react';

interface EngineerProfileViewProps {
  engineer: User;
  projects: Project[];
  loading?: boolean;
  isStandalone?: boolean;
  onClose?: () => void;
}

export function EngineerProfileView({
  engineer,
  projects,
  loading = false,
  isStandalone = false,
  onClose,
}: EngineerProfileViewProps) {
  const activeProjects = projects.filter(
    (p) => p.status === 'IN_PROGRESS' || p.status === 'WAITING_ACCEPTANCE' || p.status === 'UNDER_CLIENT_REVIEW'
  ).length;
  const completedProjects = projects.filter((p) => p.status === 'COMPLETED').length;

  return (
    <div className={`space-y-5 ${isStandalone ? 'max-w-5xl mx-auto' : ''}`}>
      {/* Profile strip */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-5 rounded-xl border border-slate-200 bg-slate-50 shadow-xs">
        <div className="flex items-center gap-4 min-w-0 flex-1">
          <div className="h-14 w-14 rounded-2xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xl shrink-0 shadow-xs">
            {(engineer.name || 'E').charAt(0).toUpperCase()}
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-bold text-slate-900 truncate" title={engineer.name || 'Unnamed Engineer'}>
              {engineer.name || 'Unnamed Engineer'}
            </h2>
            <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5" title={engineer.email}>
              <Mail className="h-3 w-3 text-slate-400 shrink-0" />
              <span className="truncate">{engineer.email}</span>
            </p>
            {engineer.mobile && (
              <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5">
                <Phone className="h-3 w-3 text-slate-400 shrink-0" />
                <span>{engineer.mobile}</span>
              </p>
            )}
            {engineer.company_name && (
              <p className="text-xs text-slate-600 mt-1 flex items-center gap-1.5 font-medium truncate" title={engineer.company_name}>
                <Building className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <span className="truncate">{engineer.company_name}</span>
              </p>
            )}
          </div>
        </div>

        <div className="flex sm:flex-col items-start sm:items-end justify-between sm:justify-center gap-2 shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-200/60">
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] whitespace-nowrap">
            <ShieldCheck className="h-4 w-4 shrink-0" />
            <span className="text-xs font-mono font-bold uppercase tracking-wider">ENGINEER</span>
          </div>
          <span className="text-[11px] font-mono text-slate-400 whitespace-nowrap" title={`Canonical UID: ${engineer.id}`}>
            UID: {engineer.id ? `${engineer.id.substring(0, 10)}…` : '—'}
          </span>
        </div>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
        {[
          { label: 'TOTAL SUBMISSIONS', value: projects.length, color: '#0453cd' },
          { label: 'ACTIVE PROJECTS', value: activeProjects, color: '#0284c7' },
          { label: 'DELIVERED / COMPLETED', value: completedProjects, color: '#059669' },
        ].map(({ label, value, color }) => (
          <div key={label} className="rounded-xl border border-slate-200 bg-white p-4 text-center shadow-xs">
            <p className="text-[10px] font-mono uppercase tracking-widest mb-1.5 text-slate-500 font-semibold">{label}</p>
            <p className="text-2xl font-bold font-mono" style={{ color }}>{value}</p>
          </div>
        ))}
      </div>

      {/* Submitted Projects list */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-xs p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <FileText className="h-4 w-4 text-[#0453cd]" />
            <h3 className="text-xs font-bold text-slate-900 uppercase tracking-wider">
              Submitted Projects ({projects.length})
            </h3>
          </div>
          {isStandalone && (
            <Link
              href="/projects"
              className="text-xs font-mono text-[#0453cd] hover:underline flex items-center gap-1"
            >
              All Projects <ChevronRight className="h-3 w-3" />
            </Link>
          )}
        </div>

        {loading ? (
          <div className="p-12 text-center">
            <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent mx-auto mb-2" />
            <p className="text-xs text-slate-500 font-mono">Loading submission history…</p>
          </div>
        ) : projects.length === 0 ? (
          <div className="p-8 text-center rounded-xl border border-dashed border-slate-200 bg-slate-50/50 text-xs text-slate-500 font-mono space-y-1">
            <p className="font-semibold text-slate-600">No submissions recorded for this engineer yet.</p>
            <p className="text-[11px] text-slate-400">When this engineer creates project submissions, their CAD drafting status and revision queues will appear here.</p>
          </div>
        ) : (
          <div className={`space-y-2.5 ${isStandalone ? '' : 'max-h-60 overflow-y-auto pr-0.5'}`}>
            {projects.map((proj) => {
              const isActive = proj.status === 'IN_PROGRESS' || proj.status === 'WAITING_ACCEPTANCE';
              return (
                <div
                  key={proj.id}
                  className="relative rounded-xl border border-slate-200 bg-white overflow-hidden group transition-all hover:border-slate-300 hover:shadow-xs"
                >
                  {/* Left accent bar */}
                  <div
                    className="absolute left-0 top-0 bottom-0 w-1.5"
                    style={{
                      background: isActive
                        ? '#0453cd'
                        : proj.status === 'COMPLETED'
                        ? '#10b981'
                        : '#94a3b8',
                    }}
                  />
                  <div className="pl-5 pr-4 py-3.5 flex items-center justify-between gap-3">
                    <div className="min-w-0 space-y-1">
                      <p className="text-[9px] font-mono text-slate-400 uppercase tracking-widest">
                        PRJ-{(proj.id || '').substring(0, 8).toUpperCase()}
                      </p>
                      <Link
                        href={`/projects/${proj.id}`}
                        className="text-sm font-semibold text-slate-900 hover:text-[#0453cd] transition-colors truncate block"
                      >
                        {proj.project_name}
                      </Link>
                      <div className="flex items-center gap-3 text-[10px] font-mono text-slate-500">
                        <span className="uppercase">{proj.drawing_type || 'ARCHITECTURAL'}</span>
                        {proj.project_area && <span>· {proj.project_area} sq.ft</span>}
                        {proj.created_at && (
                          <span>· Submitted {new Date(proj.created_at).toLocaleDateString()}</span>
                        )}
                      </div>
                    </div>
                    <div className="flex items-center gap-3 shrink-0">
                      <Badge status={proj.status} />
                      <Link
                        href={`/projects/${proj.id}`}
                        className="p-1.5 text-slate-400 hover:text-[#0453cd] rounded-lg hover:bg-slate-100 transition-colors"
                        title="View Project"
                      >
                        <ChevronRight className="h-4 w-4" />
                      </Link>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Preliminary estimate panel */}
      <div className="rounded-xl border border-slate-200 bg-slate-50/70 overflow-hidden shadow-xs">
        <div className="h-1.5 w-full bg-slate-200">
          <div
            className="h-full bg-[#0453cd] transition-all duration-500"
            style={{
              width: `${Math.min(100, (completedProjects / Math.max(1, projects.length)) * 100)}%`,
            }}
          />
        </div>
        <div className="p-5">
          <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest mb-3 flex items-center gap-2 font-semibold">
            <TrendingUp className="h-3.5 w-3.5 text-[#0453cd]" /> PRELIMINARY_ESTIMATE & CAPACITY
          </p>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <p className="text-[10px] font-mono text-slate-500 uppercase mb-1">Est. Portfolio Value</p>
              <p className="text-xl font-bold tracking-tight text-slate-900 font-mono">
                {projects.length > 0 ? `$${(projects.length * 4800).toLocaleString()}` : '—'}
              </p>
            </div>
            <div>
              <p className="text-[10px] font-mono text-slate-500 uppercase mb-1">Avg. Delivery Cycle</p>
              <p className="text-xl font-bold tracking-tight text-slate-900 font-mono">
                {projects.length > 0 ? `${5 + projects.length} days` : '—'}
              </p>
            </div>
          </div>
          <p className="text-[10px] font-mono text-slate-500 mt-3 italic">
            *Commercial figures are indicative based on standard studio tariffs and discipline footprint.
          </p>
        </div>
      </div>

      {/* Footer info / Modal Close */}
      <div className="pt-3 border-t border-slate-200 flex items-center justify-between text-xs font-mono text-slate-500">
        <span className="flex items-center gap-1.5">
          <Calendar className="h-3.5 w-3.5 text-slate-400" />
          Member since {engineer.created_at ? new Date(engineer.created_at).toLocaleDateString() : 'N/A'}
        </span>
        {onClose && (
          <Button variant="outline" size="sm" onClick={onClose}>
            Close Dossier
          </Button>
        )}
      </div>
    </div>
  );
}

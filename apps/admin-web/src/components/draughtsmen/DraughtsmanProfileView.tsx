'use client';

import React from 'react';
import Link from 'next/link';
import { User } from '@/lib/types';
import { Button } from '@/components/ui/Button';
import {
  PenTool,
  GraduationCap,
  Layers,
  Phone,
  Mail,
  RotateCcw,
  CheckCircle2,
  PlayCircle,
  Upload,
  ChevronDown,
  Calendar,
  Activity,
  Briefcase,
  ExternalLink,
} from 'lucide-react';

function WorkspaceBadge({ status }: { status?: string }) {
  if (!status) return null;
  let bg = 'bg-slate-100';
  let border = 'border-slate-200';
  let color = 'text-slate-600';
  let label = status;

  if (status === 'IN_PROGRESS') {
    bg = 'bg-blue-50';
    border = 'border-blue-200';
    color = 'text-blue-700';
    label = 'In Progress';
  } else if (status === 'UNDER_CLIENT_REVIEW') {
    bg = 'bg-amber-50';
    border = 'border-amber-200';
    color = 'text-amber-700';
    label = 'Under Review';
  } else if (status === 'COMPLETED') {
    bg = 'bg-emerald-50';
    border = 'border-emerald-200';
    color = 'text-emerald-700';
    label = 'Completed';
  } else if (status === 'WAITING_ACCEPTANCE') {
    bg = 'bg-purple-50';
    border = 'border-purple-200';
    color = 'text-purple-700';
    label = 'Pending Acceptance';
  } else if (status === 'WAITING_ASSIGNMENT') {
    bg = 'bg-indigo-50';
    border = 'border-indigo-200';
    color = 'text-indigo-700';
    label = 'Awaiting Assignment';
  }

  return (
    <span className={`inline-flex items-center gap-1 px-2.5 py-0.5 rounded-full text-[10px] font-mono font-semibold border ${bg} ${border} ${color}`}>
      {label}
    </span>
  );
}

interface DraughtsmanProfileViewProps {
  draughtsman: User;
  assignments: any[];
  loading?: boolean;
  isStandalone?: boolean;
  onClose?: () => void;
}

export function DraughtsmanProfileView({
  draughtsman,
  assignments,
  loading = false,
  isStandalone = false,
  onClose,
}: DraughtsmanProfileViewProps) {
  const activeCount = assignments.filter((a) => {
    const s = a.project_status || a.status;
    return s === 'IN_PROGRESS' || s === 'WAITING_ACCEPTANCE' || s === 'UNDER_CLIENT_REVIEW';
  }).length;
  const completedCount = assignments.filter((a) => (a.project_status || a.status) === 'COMPLETED').length;
  const workloadCapacity = Math.min(100, Math.round((activeCount / 4) * 100));

  return (
    <div className={`space-y-6 ${isStandalone ? 'max-w-5xl mx-auto' : ''}`}>
      {/* Profile header strip */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-5 rounded-xl border border-slate-200 bg-slate-50 shadow-xs">
        <div className="flex items-center gap-4 min-w-0 flex-1">
          <div className="h-14 w-14 rounded-2xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xl shrink-0 shadow-xs">
            {(draughtsman.name || 'D').charAt(0).toUpperCase()}
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-bold text-slate-900 truncate" title={draughtsman.name || 'Unnamed Draughtsman'}>
              {draughtsman.name || 'Unnamed Draughtsman'}
            </h2>
            <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5" title={draughtsman.email}>
              <Mail className="h-3 w-3 text-slate-400 shrink-0" />
              <span className="truncate">{draughtsman.email}</span>
            </p>
            {draughtsman.mobile && (
              <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5">
                <Phone className="h-3 w-3 text-slate-400 shrink-0" />
                <span>{draughtsman.mobile}</span>
              </p>
            )}
            {draughtsman.college_name && (
              <p className="text-xs text-slate-600 truncate flex items-center gap-1.5 mt-1 font-medium" title={draughtsman.college_name}>
                <GraduationCap className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <span className="truncate">{draughtsman.college_name}</span>
              </p>
            )}
          </div>
        </div>

        {/* Role badge, UID & Capacity indicators */}
        <div className="flex flex-wrap sm:flex-col items-start sm:items-end justify-between sm:justify-center gap-2.5 shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-200/60">
          <div className="flex items-center gap-2">
            <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] whitespace-nowrap">
              <PenTool className="h-4 w-4 shrink-0" />
              <span className="text-xs font-mono font-bold uppercase tracking-wider">DRAUGHTSMAN</span>
            </div>
            <span className="text-[11px] font-mono text-slate-400 whitespace-nowrap" title={`Canonical UID: ${draughtsman.id}`}>
              UID: {draughtsman.id ? `${draughtsman.id.substring(0, 10)}…` : '—'}
            </span>
          </div>

          {/* Quick capacity stats */}
          <div className="flex items-center gap-3 p-2.5 rounded-xl bg-white border border-slate-200 shadow-2xs shrink-0">
            <div className="text-center px-2">
              <p className="text-lg font-bold text-purple-700 font-mono">{activeCount}</p>
              <p className="text-[9px] font-mono text-slate-500 uppercase tracking-wider font-semibold">Active</p>
            </div>
            <div className="w-px h-6 bg-slate-200" />
            <div className="text-center px-2">
              <p className="text-lg font-bold text-emerald-700 font-mono">{completedCount}</p>
              <p className="text-[9px] font-mono text-slate-500 uppercase tracking-wider font-semibold">Done</p>
            </div>
            <div className="w-px h-6 bg-slate-200" />
            <div className="text-center px-2">
              <p className="text-lg font-bold text-[#0453cd] font-mono">{workloadCapacity}%</p>
              <p className="text-[9px] font-mono text-slate-500 uppercase tracking-wider font-semibold">Load</p>
            </div>
          </div>
        </div>
      </div>

      {/* Workload Capacity Bar */}
      <div className="rounded-xl border border-slate-200 bg-white p-5 shadow-xs space-y-2">
        <div className="flex items-center justify-between text-xs">
          <span className="font-semibold text-slate-700 flex items-center gap-1.5">
            <Activity className="h-4 w-4 text-[#0453cd]" /> Workload Capacity
          </span>
          <span className="font-mono font-bold text-slate-900">{activeCount} of 4 Max Active Drawings</span>
        </div>
        <div className="w-full h-2.5 rounded-full overflow-hidden bg-slate-100">
          <div
            className={`h-full rounded-full transition-all duration-500 ${
              workloadCapacity > 75
                ? 'bg-rose-500'
                : workloadCapacity > 50
                ? 'bg-amber-500'
                : 'bg-emerald-500'
            }`}
            style={{ width: `${workloadCapacity}%` }}
          />
        </div>
        <p className="text-[11px] font-mono text-slate-400">
          {workloadCapacity < 50
            ? 'Optimal availability for high-priority architectural drafting allocation.'
            : workloadCapacity < 100
            ? 'Moderate workload. Can take 1-2 standard drafting scopes.'
            : 'Capacity limit reached. Avoid additional assignment dispatch.'}
        </p>
      </div>

      {/* Workspace assignments bento grid */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-xs p-5">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <Layers className="h-4 w-4 text-[#0453cd]" />
            <h3 className="text-xs font-bold text-slate-900 uppercase tracking-wider">
              Project Assignments ({assignments.length})
            </h3>
          </div>
          <span className="text-[11px] font-mono text-slate-400">Draughtsman View</span>
        </div>

        {loading ? (
          <div className="p-12 text-center">
            <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent mx-auto mb-2" />
            <p className="text-xs text-slate-500 font-mono">Loading assigned workspace…</p>
          </div>
        ) : assignments.length === 0 ? (
          <div className="p-10 text-center rounded-xl border border-dashed border-slate-200 bg-slate-50/50 text-slate-500 text-xs font-mono">
            <PenTool className="h-8 w-8 mx-auto mb-2 opacity-30 text-slate-400" />
            No projects have been assigned to this draughtsman yet.
          </div>
        ) : (
          <div className={`grid grid-cols-1 md:grid-cols-2 gap-4 ${isStandalone ? '' : 'max-h-[420px] overflow-y-auto pr-1'}`}>
            {assignments.map((item: any, idx: number) => {
              const projectId = item.project_id || item.id;
              const projectName = item.project_name || 'Drawing Project';
              const status = item.project_status || item.status;
              const isCorrection = status === 'UNDER_CLIENT_REVIEW';
              const isCompleted = status === 'COMPLETED';
              const isNew = status === 'WAITING_ACCEPTANCE';

              return (
                <div
                  key={item.id || projectId}
                  className={`relative rounded-xl border p-4 space-y-3 transition-all duration-200 bg-white shadow-2xs ${
                    isCorrection
                      ? 'border-rose-300 bg-rose-50/20'
                      : isCompleted
                      ? 'border-emerald-200 bg-white'
                      : 'border-slate-200 bg-white hover:border-slate-300'
                  }`}
                >
                  {/* Header row */}
                  <div className="flex items-start justify-between gap-2">
                    <span className="text-[10px] font-mono text-slate-500 uppercase tracking-wider">
                      PRJ-{(projectId || '').toString().substring(0, 8).toUpperCase()}
                    </span>
                    <WorkspaceBadge status={status} />
                  </div>

                  {/* Project name */}
                  <div>
                    <Link
                      href={`/projects/${projectId}`}
                      className="font-semibold text-sm text-slate-900 hover:text-[#0453cd] transition-colors line-clamp-2 leading-snug"
                    >
                      {projectName}
                    </Link>
                    <p className="text-[11px] text-slate-500 mt-1 font-mono">
                      {item.drawing_type || 'Architectural Drawing'} · {item.project_area || 'N/A'} sq.ft
                    </p>
                  </div>

                  {/* Version history accordion */}
                  <details className="group/v border-t border-slate-100 pt-2">
                    <summary className="flex items-center justify-between cursor-pointer text-[11px] font-mono text-slate-500 hover:text-slate-800 transition-colors list-none">
                      <span>Version History</span>
                      <ChevronDown className="h-3 w-3 group-open/v:rotate-180 transition-transform" />
                    </summary>
                    <div className="mt-2 pl-2 border-l border-slate-200 space-y-1.5">
                      <div className="flex items-center justify-between">
                        <span className="text-[10px] font-mono font-medium text-slate-700">v{idx + 2}.{idx + 1} (Current)</span>
                        <span className="text-[9px] font-mono text-slate-400">Latest</span>
                      </div>
                      {idx > 0 && (
                        <div className="flex items-center justify-between opacity-70">
                          <span className="text-[10px] font-mono text-slate-500">v{idx + 1}.0</span>
                          <span className="text-[9px] font-mono text-slate-400">Baseline</span>
                        </div>
                      )}
                    </div>
                  </details>

                  {/* Action CTA */}
                  <div className="pt-2 border-t border-slate-100">
                    {isCorrection ? (
                      <Link
                        href={`/projects/${projectId}?tab=corrections`}
                        className="flex items-center justify-center gap-1.5 w-full py-2 rounded-lg text-xs font-semibold border border-rose-300 text-rose-700 bg-rose-50 hover:bg-rose-100 transition-colors"
                      >
                        <RotateCcw className="h-3.5 w-3.5" /> Review Redline Corrections
                      </Link>
                    ) : isCompleted ? (
                      <div className="flex items-center justify-center gap-1.5 w-full py-2 rounded-lg text-xs font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 font-mono">
                        <CheckCircle2 className="h-3.5 w-3.5" /> Delivered & Verified
                      </div>
                    ) : isNew ? (
                      <Link
                        href={`/projects/${projectId}`}
                        className="flex items-center justify-center gap-1.5 w-full py-2 rounded-lg text-xs font-semibold text-white bg-[#0d1c32] hover:bg-[#1a2f4c] transition-colors"
                      >
                        <PlayCircle className="h-3.5 w-3.5" /> Start Drafting
                      </Link>
                    ) : (
                      <Link
                        href={`/projects/${projectId}`}
                        className="flex items-center justify-center gap-1.5 w-full py-2 rounded-lg text-xs font-semibold text-white bg-[#0453cd] hover:bg-[#0342a6] transition-colors"
                      >
                        <Upload className="h-3.5 w-3.5" /> Upload Revision
                      </Link>
                    )}
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* Footer info / Modal Close */}
      <div className="pt-3 border-t border-slate-200 flex items-center justify-between text-xs font-mono text-slate-500">
        <span className="flex items-center gap-1.5">
          <Calendar className="h-3.5 w-3.5 text-slate-400" />
          Member since {draughtsman.created_at ? new Date(draughtsman.created_at).toLocaleDateString() : 'N/A'}
        </span>
        {onClose && (
          <Button variant="outline" size="sm" onClick={onClose}>
            Close Workspace
          </Button>
        )}
      </div>
    </div>
  );
}

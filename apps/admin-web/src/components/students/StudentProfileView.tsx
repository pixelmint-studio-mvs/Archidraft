'use client';

import React from 'react';
import Link from 'next/link';
import { User } from '@/lib/types';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import {
  GraduationCap,
  School,
  Trophy,
  TrendingUp,
  Layers,
  CheckCircle2,
  PlayCircle,
  Lock,
  ChevronRight,
  Star,
  Video,
  FileText,
  Zap,
  ShieldAlert,
  Calendar,
  Mail,
  Phone,
  BookOpen,
  PlusCircle,
} from 'lucide-react';

interface StudentProfileViewProps {
  student: User & { course?: string; modulesCompleted?: number; isFixture?: boolean };
  assignments?: any[];
  loading?: boolean;
  isStandalone?: boolean;
  onAssignProject?: (studentId: string) => void;
  onClose?: () => void;
}

export function StudentProfileView({
  student,
  assignments = [],
  loading = false,
  isStandalone = false,
  onAssignProject,
  onClose,
}: StudentProfileViewProps) {
  const isFixture = !!student.isFixture;
  const modulesCompleted = isFixture ? (student.modulesCompleted || 0) : 0;
  const totalModules = 8;
  const progressPct = Math.round((modulesCompleted / totalModules) * 100);

  const activeAssignments = assignments.filter((a) => {
    const s = a.project_status || a.status;
    return s === 'IN_PROGRESS' || s === 'WAITING_ACCEPTANCE' || s === 'UNDER_CLIENT_REVIEW' || s === 'UNDER_ENGINEER_REVIEW';
  }).length;
  const completedAssignments = assignments.filter((a) => (a.project_status || a.status) === 'COMPLETED').length;

  const MOCK_PROJECTS = [
    { title: 'Residential Pavilion Plan', level: 'Beginner', levelColor: '#475569', status: 'Completed', statusColor: '#16a34a', icon: CheckCircle2 },
    { title: 'Commercial Facade Detailing', level: 'Intermediate', levelColor: '#0453cd', status: 'In Progress', statusColor: '#0453cd', icon: PlayCircle },
    { title: 'Parametric Structural Systems', level: 'Pro Masterclass', levelColor: '#7c3aed', status: 'Locked', statusColor: '#94a3b8', icon: Lock },
  ];

  const MOCK_MODULES = [
    { title: 'Lighting Analysis', meta: '12 mins · Video', icon: Video, done: modulesCompleted >= 2 },
    { title: 'Material Schedules', meta: 'PDF · 4 Pages', icon: FileText, done: modulesCompleted >= 4 },
    { title: 'BIM Coordination', meta: 'Interactive Exercise', icon: Zap, done: modulesCompleted >= 6 },
  ];

  const LEADERBOARD = [
    { rank: '01', name: 'E. Rohe', pts: '9,420', isMe: false },
    { rank: '02', name: 'L. Corbusier', pts: '8,950', isMe: false },
    { rank: '14', name: student.name?.split(' ')[0] || 'Apprentice', pts: `${3000 + modulesCompleted * 400}`, isMe: true },
  ];

  return (
    <div className={`space-y-6 ${isStandalone ? 'max-w-5xl mx-auto' : ''}`}>
      {/* Profile header strip */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-5 rounded-xl border border-slate-200 bg-slate-50 shadow-xs">
        <div className="flex items-center gap-4 min-w-0 flex-1">
          <div className="h-14 w-14 rounded-2xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xl shrink-0 shadow-xs">
            {(student.name || 'S').charAt(0).toUpperCase()}
          </div>
          <div className="min-w-0 flex-1">
            <h2 className="text-lg font-bold text-slate-900 truncate" title={student.name || 'Unnamed Student'}>
              {student.name || 'Unnamed Student'}
            </h2>
            <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5" title={student.email}>
              <Mail className="h-3 w-3 text-slate-400 shrink-0" />
              <span className="truncate">{student.email}</span>
            </p>
            {student.mobile && (
              <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5">
                <Phone className="h-3 w-3 text-slate-400 shrink-0" />
                <span>{student.mobile}</span>
              </p>
            )}
            {student.college_name && (
              <p className="text-xs text-slate-600 mt-1 flex items-center gap-1.5 font-medium truncate" title={student.college_name}>
                <School className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                <span className="truncate">{student.college_name}</span>
              </p>
            )}
          </div>
        </div>

        {/* Role badge, Action & Canonical UID */}
        <div className="flex sm:flex-col items-start sm:items-end justify-between sm:justify-center gap-2 shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-200/60">
          <div className="flex items-center gap-2">
            {isFixture ? (
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-800 whitespace-nowrap">
                <Trophy className="h-4 w-4 text-amber-600 shrink-0" />
                <span className="text-xs font-mono font-bold uppercase tracking-wider">DEMO FIXTURE</span>
              </div>
            ) : (
              <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 whitespace-nowrap">
                <GraduationCap className="h-4 w-4 text-emerald-600 shrink-0" />
                <span className="text-xs font-mono font-bold uppercase tracking-wider">STUDENT</span>
              </div>
            )}
            {onAssignProject && !isFixture && (
              <Button
                size="sm"
                onClick={() => onAssignProject(student.id)}
                className="bg-[#0a192f] hover:bg-slate-800 text-white text-xs font-mono flex items-center gap-1.5 shadow-xs"
              >
                <PlusCircle className="h-3.5 w-3.5 text-emerald-400" />
                <span>Assign Project</span>
              </Button>
            )}
          </div>
          <span className="text-[11px] font-mono text-slate-400 whitespace-nowrap" title={`Canonical UID: ${student.id}`}>
            UID: {student.id ? `${student.id.substring(0, 10)}…` : '—'}
          </span>
        </div>
      </div>

      {/* Fixture preview vs Real Student Data */}
      {isFixture ? (
        <>
          {/* Curriculum Progress (Fixture) */}
          <div className="rounded-xl border border-slate-200 bg-white shadow-xs overflow-hidden">
            <div className="p-4 border-b border-slate-200 flex items-center justify-between">
              <p className="text-xs font-bold text-slate-900 uppercase tracking-wider flex items-center gap-2">
                <TrendingUp className="h-3.5 w-3.5 text-[#0453cd]" /> Architectural Drafting Foundations · Module 4
              </p>
              <p className="text-xs font-mono text-emerald-700 font-semibold">{progressPct}% Complete</p>
            </div>
            <div className="p-5 space-y-3">
              <div className="w-full h-2.5 rounded-full overflow-hidden bg-slate-100">
                <div
                  className="h-full rounded-full transition-all duration-700 bg-emerald-600"
                  style={{ width: `${progressPct}%` }}
                />
              </div>
              <div className="flex justify-between text-[11px] font-mono">
                {['Drafting', 'Modelling', 'Rendering', 'Documentation'].map((s, i) => (
                  <span key={s} className={i === 2 ? 'text-emerald-700 font-bold' : 'text-slate-500'}>
                    {s}
                  </span>
                ))}
              </div>
            </div>
          </div>

          {/* Main two-column layout for Fixture */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
            <div className="md:col-span-2 space-y-3">
              <p className="text-xs font-bold text-slate-900 uppercase tracking-wider flex items-center gap-2">
                <Layers className="h-3.5 w-3.5 text-[#0453cd]" /> Practical Learning Projects
              </p>
              <div className="space-y-2.5">
                {MOCK_PROJECTS.map((proj) => {
                  const ProjIcon = proj.icon;
                  const isLocked = proj.status === 'Locked';
                  return (
                    <div
                      key={proj.title}
                      className={`rounded-xl border p-4 flex items-center gap-3.5 transition-all bg-white shadow-2xs ${
                        isLocked ? 'border-slate-200 opacity-60' : 'border-slate-200 hover:border-slate-300'
                      }`}
                    >
                      <div className="h-10 w-10 rounded-lg flex items-center justify-center shrink-0 bg-slate-50 border border-slate-200">
                        <ProjIcon className="h-5 w-5" style={{ color: proj.statusColor }} />
                      </div>
                      <div className="flex-1 min-w-0">
                        <p className="text-sm font-semibold text-slate-900 truncate leading-tight">{proj.title}</p>
                        <p className="text-[11px] font-mono mt-0.5" style={{ color: proj.levelColor }}>
                          {proj.level}
                        </p>
                      </div>
                      <span className="text-xs font-mono font-semibold shrink-0" style={{ color: proj.statusColor }}>
                        {proj.status}
                      </span>
                    </div>
                  );
                })}
              </div>
            </div>

            <div className="space-y-5">
              <div className="rounded-xl border border-slate-200 bg-white shadow-xs overflow-hidden">
                <div className="px-4 py-3 border-b border-slate-100 flex items-center justify-between bg-slate-50/50">
                  <p className="text-xs font-bold text-slate-900">Current Modules</p>
                  <ChevronRight className="h-3.5 w-3.5 text-slate-400" />
                </div>
                <div className="divide-y divide-slate-100">
                  {MOCK_MODULES.map((mod) => {
                    const ModIcon = mod.icon;
                    return (
                      <div key={mod.title} className="flex items-center gap-3 p-3 hover:bg-slate-50 transition-colors">
                        <div
                          className={`h-8 w-8 rounded-lg flex items-center justify-center shrink-0 ${
                            mod.done
                              ? 'bg-emerald-50 text-emerald-600 border border-emerald-200'
                              : 'bg-slate-100 text-slate-400'
                          }`}
                        >
                          <ModIcon className="h-4 w-4" />
                        </div>
                        <div className="flex-1 min-w-0">
                          <p className="text-xs font-semibold text-slate-900 truncate">{mod.title}</p>
                          <p className="text-[10px] font-mono text-slate-500">{mod.meta}</p>
                        </div>
                        {mod.done && <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />}
                      </div>
                    );
                  })}
                </div>
              </div>

              <div className="rounded-xl border border-slate-200 bg-white shadow-xs overflow-hidden">
                <div className="px-4 py-3 flex items-center gap-2 border-b border-slate-100 bg-slate-50">
                  <Star className="h-3.5 w-3.5 text-amber-500" />
                  <p className="text-xs font-bold text-slate-900">Apprentice Rankings</p>
                </div>
                <div className="divide-y divide-slate-100">
                  {LEADERBOARD.map((entry) => (
                    <div
                      key={entry.rank}
                      className={`flex items-center justify-between px-4 py-2.5 ${
                        entry.isMe ? 'bg-blue-50/60' : ''
                      }`}
                    >
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] font-mono font-medium text-slate-400">
                          {entry.rank}
                        </span>
                        <span className={`text-xs font-semibold ${entry.isMe ? 'text-[#0453cd]' : 'text-slate-800'}`}>
                          {entry.name}
                        </span>
                      </div>
                      <span className="text-xs font-mono font-bold text-slate-900">
                        {entry.pts} pt
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2.5 p-3.5 rounded-xl text-xs font-mono text-amber-800 bg-amber-50 border border-amber-200">
            <ShieldAlert className="h-4 w-4 shrink-0 text-amber-600" />
            <span>Development Fixture — Simulated apprentice progress for design preview.</span>
          </div>
        </>
      ) : (
        <>
          {/* Live Statistics Cards for Real Student */}
          <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
            {[
              { label: 'ASSIGNED PROJECTS', value: assignments.length, color: '#0453cd' },
              { label: 'ACTIVE / UNDER REVIEW', value: activeAssignments, color: '#0284c7' },
              { label: 'COMPLETED & CERTIFIED', value: completedAssignments, color: '#059669' },
            ].map(({ label, value, color }) => (
              <div key={label} className="rounded-xl border border-slate-200 bg-white p-4 text-center shadow-xs">
                <p className="text-[10px] font-mono uppercase tracking-widest mb-1.5 text-slate-500 font-semibold">{label}</p>
                <p className="text-2xl font-bold font-mono" style={{ color }}>{value}</p>
              </div>
            ))}
          </div>

          {/* Real Learning Projects / Submissions */}
          <div className="rounded-xl border border-slate-200 bg-white shadow-xs p-5">
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <BookOpen className="h-4 w-4 text-[#0453cd]" />
                <h3 className="text-xs font-bold text-slate-900 uppercase tracking-wider">
                  Assigned Coursework & Submissions ({assignments.length})
                </h3>
              </div>
              <div className="flex items-center gap-2">
                {onAssignProject && !isFixture && (
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => onAssignProject(student.id)}
                    className="text-xs font-mono text-[#0453cd] border-blue-200 hover:bg-blue-50 flex items-center gap-1.5"
                  >
                    <PlusCircle className="h-3.5 w-3.5 text-[#0453cd]" />
                    <span>Assign Project</span>
                  </Button>
                )}
                {isStandalone && (
                  <Link
                    href="/students/submissions"
                    className="text-xs font-mono text-[#0453cd] hover:underline flex items-center gap-1"
                  >
                    Review Queue <ChevronRight className="h-3 w-3" />
                  </Link>
                )}
              </div>
            </div>

            {loading ? (
              <div className="p-12 text-center">
                <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent mx-auto mb-2" />
                <p className="text-xs text-slate-500 font-mono">Querying student records…</p>
              </div>
            ) : assignments.length === 0 ? (
              <div className="p-8 text-center rounded-xl border border-dashed border-slate-200 bg-slate-50/50 text-xs text-slate-500 font-mono space-y-2">
                <p className="font-semibold text-slate-600">No learning projects or studio assignments recorded for this student yet.</p>
                <p className="text-[11px] text-slate-400">When architectural drafting modules or student submissions are allocated, they will appear here with review milestones.</p>
                {onAssignProject && !isFixture && (
                  <div className="pt-2">
                    <Button
                      size="sm"
                      variant="outline"
                      onClick={() => onAssignProject(student.id)}
                      className="text-xs font-mono text-[#0453cd] border-blue-200 hover:bg-blue-50"
                    >
                      <PlusCircle className="h-3.5 w-3.5 mr-1.5 text-[#0453cd]" />
                      Create & Assign Practical Project
                    </Button>
                  </div>
                )}
              </div>
            ) : (
              <div className={`space-y-2.5 ${isStandalone ? '' : 'max-h-60 overflow-y-auto pr-0.5'}`}>
                {assignments.map((item: any, idx: number) => {
                  const projectId = item.project_id || item.id;
                  const projectName = item.project_name || 'Assigned Drawing Project';
                  const status = item.project_status || item.status;
                  return (
                    <div
                      key={item.id || idx}
                      className="rounded-xl border border-slate-200 bg-white p-4 flex items-center justify-between gap-3 hover:border-slate-300 transition-all shadow-xs"
                    >
                      <div className="min-w-0 space-y-1">
                        <p className="text-[9px] font-mono text-slate-400 uppercase tracking-widest">
                          PRJ-{(projectId || '').substring(0, 8).toUpperCase()}
                        </p>
                        <Link
                          href={`/projects/${projectId}`}
                          className="text-sm font-semibold text-slate-900 hover:text-[#0453cd] transition-colors truncate block"
                        >
                          {projectName}
                        </Link>
                        <div className="flex items-center gap-3 text-[10px] font-mono text-slate-500">
                          {item.assigned_at && (
                            <span>Assigned {new Date(item.assigned_at).toLocaleDateString()}</span>
                          )}
                          {item.correction_round !== undefined && item.correction_round > 0 && (
                            <span>· Round {item.correction_round}</span>
                          )}
                        </div>
                      </div>
                      <div className="flex items-center gap-3 shrink-0">
                        <Badge status={status} />
                        <Link
                          href={`/projects/${projectId}`}
                          className="p-1.5 text-slate-400 hover:text-[#0453cd] rounded-lg hover:bg-slate-100 transition-colors"
                          title="View Submission Details"
                        >
                          <ChevronRight className="h-4 w-4" />
                        </Link>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>
        </>
      )}

      {/* Footer info / Modal Close */}
      <div className="pt-3 border-t border-slate-200 flex items-center justify-between text-xs font-mono text-slate-500">
        <span className="flex items-center gap-1.5">
          <Calendar className="h-3.5 w-3.5 text-slate-400" />
          Member since {student.created_at ? new Date(student.created_at).toLocaleDateString() : 'N/A'}
        </span>
        {onClose && (
          <Button variant="outline" size="sm" onClick={onClose}>
            Close Portal
          </Button>
        )}
      </div>
    </div>
  );
}

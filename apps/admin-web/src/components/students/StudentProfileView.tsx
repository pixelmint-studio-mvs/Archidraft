'use client';

import React from 'react';
import { User } from '@/lib/types';
import { Button } from '@/components/ui/Button';
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
} from 'lucide-react';

interface StudentProfileViewProps {
  student: User & { course?: string; modulesCompleted?: number; isFixture?: boolean };
  isStandalone?: boolean;
  onClose?: () => void;
}

export function StudentProfileView({
  student,
  isStandalone = false,
  onClose,
}: StudentProfileViewProps) {
  const modulesCompleted = student.isFixture ? (student.modulesCompleted || 0) : 0;
  const totalModules = 8;
  const progressPct = Math.round((modulesCompleted / totalModules) * 100);

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
    <div className={`space-y-6 ${isStandalone ? 'max-w-5xl mx-auto' : 'max-h-[80vh] overflow-y-auto pr-1'}`}>
      {/* Profile header strip */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-5 rounded-xl border border-slate-200 bg-slate-50 shadow-xs">
        <div className="flex items-center gap-4">
          <div className="h-14 w-14 rounded-2xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xl shrink-0 shadow-xs">
            {(student.name || 'S').charAt(0).toUpperCase()}
          </div>
          <div className="min-w-0">
            <h2 className="text-lg font-bold text-slate-900 truncate">{student.name || 'Unnamed Student'}</h2>
            <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5">
              <Mail className="h-3 w-3 text-slate-400 shrink-0" />
              {student.email}
            </p>
            {student.mobile && (
              <p className="text-xs font-mono text-slate-500 truncate flex items-center gap-1.5 mt-0.5">
                <Phone className="h-3 w-3 text-slate-400 shrink-0" />
                {student.mobile}
              </p>
            )}
            {student.college_name && (
              <p className="text-xs text-slate-600 mt-1 flex items-center gap-1.5 font-medium">
                <School className="h-3.5 w-3.5 text-slate-400 shrink-0" /> {student.college_name}
              </p>
            )}
          </div>
        </div>

        {/* Rank / Apprentice badge */}
        <div className="flex sm:flex-col items-center sm:items-end justify-between gap-2 shrink-0">
          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-800">
            <Trophy className="h-4 w-4 text-amber-600 shrink-0" />
            <span className="text-xs font-mono font-bold uppercase tracking-wider">Top 15% Rank</span>
          </div>
          <span className="text-[11px] font-mono text-slate-400">
            UID: {student.id.substring(0, 10)}…
          </span>
        </div>
      </div>

      {/* Curriculum Progress */}
      <div className="rounded-xl border border-slate-200 bg-white shadow-xs overflow-hidden">
        <div className="p-4 border-b border-slate-200 flex items-center justify-between">
          <p className="text-xs font-bold text-slate-900 uppercase tracking-wider flex items-center gap-2">
            <TrendingUp className="h-3.5 w-3.5 text-[#0453cd]" /> Architectural Drafting Foundations · Module 4
          </p>
          <p className="text-xs font-mono text-emerald-700 font-semibold">{progressPct}% Complete</p>
        </div>
        <div className="p-5 space-y-3">
          {/* Progress bar */}
          <div className="w-full h-2.5 rounded-full overflow-hidden bg-slate-100">
            <div
              className="h-full rounded-full transition-all duration-700 bg-emerald-600"
              style={{ width: `${progressPct}%` }}
            />
          </div>
          {/* Stage labels */}
          <div className="flex justify-between text-[11px] font-mono">
            {['Drafting', 'Modelling', 'Rendering', 'Documentation'].map((s, i) => (
              <span key={s} className={i === 2 ? 'text-emerald-700 font-bold' : 'text-slate-500'}>
                {s}
              </span>
            ))}
          </div>
        </div>
      </div>

      {/* Main two-column layout */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        {/* Mock projects (left, spans 2 cols) */}
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

        {/* Right column: modules + leaderboard */}
        <div className="space-y-5">
          {/* Current modules */}
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

          {/* Leaderboard */}
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

      {/* Footer info / Modal Close */}
      {student.isFixture && (
        <div className="flex items-center gap-2.5 p-3.5 rounded-xl text-xs font-mono text-amber-800 bg-amber-50 border border-amber-200">
          <ShieldAlert className="h-4 w-4 shrink-0 text-amber-600" />
          <span>Development Fixture — Learning progress shown is simulated for preview purposes.</span>
        </div>
      )}

      <div className="pt-3 border-t border-slate-200 flex items-center justify-between text-xs font-mono text-slate-500">
        <span className="flex items-center gap-1.5">
          <Calendar className="h-3.5 w-3.5 text-slate-400" />
          {modulesCompleted}/{totalModules} modules verified
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

'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { EmptyState } from '@/components/ui/EmptyState';
import { adminApi } from '@/lib/api';
import { AdminStats, Project } from '@/lib/types';
import {
  FolderKanban,
  Clock,
  UserPlus,
  PlayCircle,
  CheckCircle2,
  Users,
  Compass,
  ArrowRight,
  ShieldCheck,
  FileCheck2,
  AlertCircle,
  Activity as ActivityIcon,
  HardHat,
  PenTool,
  GraduationCap,
  ExternalLink,
  ChevronRight,
  Layers,
} from 'lucide-react';

export default function DashboardPage() {
  const [stats, setStats] = useState<AdminStats | null>(null);
  const [pendingProjects, setPendingProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const loadData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [statsData, projectsData] = await Promise.all([
        adminApi.getStats().catch(() => ({
          projects: { total: 0, byStatus: {} },
          users: { total: 1, byRole: { ADMIN: 1 } },
          recentActivity: [],
        })),
        adminApi.getProjects().catch(() => []),
      ]);
      setStats(statsData);
      // Filter projects that need immediate admin action
      const needsAction = (projectsData || []).filter(
        (p) => p.status === 'SUBMITTED' || p.status === 'WAITING_ASSIGNMENT'
      );
      setPendingProjects(needsAction.slice(0, 5));
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load dashboard metrics');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const byStatus = stats?.projects?.byStatus || {};
  const submittedCount = byStatus['SUBMITTED'] || 0;
  const waitingAssignmentCount = byStatus['WAITING_ASSIGNMENT'] || 0;
  const waitingAcceptanceCount = byStatus['WAITING_ACCEPTANCE'] || 0;
  const inProgressCount = byStatus['IN_PROGRESS'] || 0;
  const engineerReviewCount = byStatus['UNDER_CLIENT_REVIEW'] || 0;
  const completedCount = byStatus['COMPLETED'] || 0;
  const cancelledCount = byStatus['CANCELLED'] || 0;

  const usersByRole = stats?.users?.byRole || {};
  const draughtsmanCount = usersByRole['DRAUGHTSMAN'] || 0;
  const engineerCount = usersByRole['CLIENT'] || 0;
  const studentCount = usersByRole['STUDENT'] || 0;
  const adminCount = usersByRole['ADMIN'] || 0;

  return (
    <AdminShell
      title="Studio Operations Dashboard"
      subtitle="Executive platform telemetry & actionable governance queues across all three studio portals"
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-50 border border-rose-200 text-sm text-rose-800 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
          <span className="font-medium">{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadData(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center p-24 bg-white border border-slate-200 rounded-2xl soft-elevation my-6">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs font-mono font-medium text-slate-500 mt-4 uppercase tracking-wider">
            Aggregating platform metrics across all portals...
          </p>
        </div>
      ) : (
        <div className="space-y-8">
          {/* Three Portals Unified Executive Banner */}
          <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4 sm:gap-5">
            {/* 1. Engineer Portal Card */}
            <div className="bg-white border border-slate-200 rounded-2xl p-5 sm:p-6 soft-elevation relative overflow-hidden group hover:border-indigo-300 transition-all border-t-4 border-t-indigo-600">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-indigo-700 uppercase tracking-wider flex items-center gap-2">
                  <div className="p-1.5 rounded-lg bg-indigo-50 text-indigo-600">
                    <HardHat className="h-4 w-4" />
                  </div>
                  <span>Engineer Portal</span>
                </span>
                <span className="h-2 w-2 rounded-full bg-indigo-500 animate-pulse" />
              </div>
              <div className="mt-5 flex items-baseline justify-between">
                <div>
                  <span className="text-3xl font-extrabold font-mono tracking-tight text-slate-900">
                    {engineerCount}
                  </span>
                  <p className="text-xs text-slate-500 mt-0.5">Registered Engineers</p>
                </div>
                <div className="text-right">
                  <span className="text-lg font-bold font-mono text-slate-700">
                    {submittedCount + engineerReviewCount}
                  </span>
                  <p className="text-[10px] text-slate-400 uppercase font-mono">Active Workflow</p>
                </div>
              </div>
              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <Link
                  href="/engineers"
                  className="text-indigo-600 hover:text-indigo-800 font-semibold flex items-center gap-1 group-hover:translate-x-0.5 transition-transform"
                >
                  <span>Manage Engineers</span>
                  <ArrowRight className="h-3 w-3" />
                </Link>
                <span className="text-[11px] font-mono text-slate-400">Structural & Civil</span>
              </div>
            </div>

            {/* 2. Draughtsman Portal Card */}
            <div className="bg-white border border-slate-200 rounded-2xl p-5 sm:p-6 soft-elevation relative overflow-hidden group hover:border-blue-300 transition-all border-t-4 border-t-[#0453cd]">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-[#0453cd] uppercase tracking-wider flex items-center gap-2">
                  <div className="p-1.5 rounded-lg bg-blue-50 text-[#0453cd]">
                    <PenTool className="h-4 w-4" />
                  </div>
                  <span>Draughtsman Portal</span>
                </span>
                <span className="h-2 w-2 rounded-full bg-[#0453cd] animate-pulse" />
              </div>
              <div className="mt-5 flex items-baseline justify-between">
                <div>
                  <span className="text-3xl font-extrabold font-mono tracking-tight text-slate-900">
                    {draughtsmanCount}
                  </span>
                  <p className="text-xs text-slate-500 mt-0.5">Certified Draughtsmen</p>
                </div>
                <div className="text-right">
                  <span className="text-lg font-bold font-mono text-slate-700">
                    {inProgressCount + waitingAcceptanceCount}
                  </span>
                  <p className="text-[10px] text-slate-400 uppercase font-mono">Assigned in Production</p>
                </div>
              </div>
              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <Link
                  href="/draughtsmen"
                  className="text-[#0453cd] hover:text-blue-800 font-semibold flex items-center gap-1 group-hover:translate-x-0.5 transition-transform"
                >
                  <span>Manage Draughtsmen</span>
                  <ArrowRight className="h-3 w-3" />
                </Link>
                <span className="text-[11px] font-mono text-slate-400">CAD & BIM Pool</span>
              </div>
            </div>

            {/* 3. Student Portal Card */}
            <div className="bg-white border border-slate-200 rounded-2xl p-5 sm:p-6 soft-elevation relative overflow-hidden group hover:border-emerald-300 transition-all border-t-4 border-t-emerald-600 md:col-span-2 xl:col-span-1">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-emerald-700 uppercase tracking-wider flex items-center gap-2">
                  <div className="p-1.5 rounded-lg bg-emerald-50 text-emerald-600">
                    <GraduationCap className="h-4 w-4" />
                  </div>
                  <span>Student Portal</span>
                </span>
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              </div>
              <div className="mt-5 flex items-baseline justify-between">
                <div>
                  <span className="text-3xl font-extrabold font-mono tracking-tight text-slate-900">
                    {studentCount}
                  </span>
                  <p className="text-xs text-slate-500 mt-0.5">Enrolled Apprentices</p>
                </div>
                <div className="text-right">
                  <span className="text-xs font-mono font-semibold text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                    Active Track
                  </span>
                  <p className="text-[10px] text-slate-400 mt-1 uppercase font-mono">Curriculum</p>
                </div>
              </div>
              <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between text-xs">
                <Link
                  href="/students"
                  className="text-emerald-700 hover:text-emerald-900 font-semibold flex items-center gap-1 group-hover:translate-x-0.5 transition-transform"
                >
                  <span>Manage Students</span>
                  <ArrowRight className="h-3 w-3" />
                </Link>
                <span className="text-[11px] font-mono text-slate-400">Apprentice Program</span>
              </div>
            </div>
          </div>

          {/* Project Workflow Operations Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-3.5 sm:gap-4">
            {/* Total Projects */}
            <div className="bg-white border border-slate-200 rounded-xl p-5 soft-elevation relative">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-wider">
                  Total Projects
                </span>
                <div className="p-2 rounded-lg bg-slate-50 text-slate-700 border border-slate-200">
                  <FolderKanban className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-extrabold font-mono tracking-tight text-slate-900">
                  {stats?.projects?.total ?? 0}
                </span>
                <span className="text-xs text-slate-500 font-medium font-mono">in D1 database</span>
              </div>
              <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between text-xs font-mono text-slate-500">
                <span>{completedCount} completed</span>
                <span>{cancelledCount} cancelled</span>
              </div>
            </div>

            {/* Requires Review */}
            <div className="bg-white border border-amber-200 rounded-xl p-5 soft-elevation relative bg-gradient-to-b from-amber-50/30 to-white">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-amber-800 uppercase tracking-wider">
                  Requires Review
                </span>
                <div className="p-2 rounded-lg bg-amber-50 text-amber-700 border border-amber-200">
                  <Clock className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-extrabold font-mono tracking-tight text-amber-700">
                  {submittedCount}
                </span>
                <span className="text-xs text-amber-800 font-medium">pending admin review</span>
              </div>
              <div className="mt-4 pt-3 border-t border-amber-100 flex items-center justify-between text-xs">
                <Link
                  href="/projects?status=SUBMITTED"
                  className="text-amber-800 hover:text-amber-900 font-semibold flex items-center gap-1 group"
                >
                  <span>Review Submissions</span>
                  <ArrowRight className="h-3 w-3 group-hover:translate-x-0.5 transition-transform" />
                </Link>
              </div>
            </div>

            {/* Needs Draughtsman Assignment */}
            <div className="bg-white border border-blue-200 rounded-xl p-5 soft-elevation relative bg-gradient-to-b from-blue-50/30 to-white">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-[#0453cd] uppercase tracking-wider">
                  Needs Draughtsman
                </span>
                <div className="p-2 rounded-lg bg-blue-50 text-[#0453cd] border border-blue-200">
                  <UserPlus className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-extrabold font-mono tracking-tight text-[#0453cd]">
                  {waitingAssignmentCount}
                </span>
                <span className="text-xs text-blue-700 font-medium">ready for allocation</span>
              </div>
              <div className="mt-4 pt-3 border-t border-blue-100 flex items-center justify-between text-xs">
                <Link
                  href="/projects?status=WAITING_ASSIGNMENT"
                  className="text-[#0453cd] hover:text-blue-800 font-semibold flex items-center gap-1 group"
                >
                  <span>Assign Draughtsman</span>
                  <ArrowRight className="h-3 w-3 group-hover:translate-x-0.5 transition-transform" />
                </Link>
              </div>
            </div>

            {/* Active in Drafting */}
            <div className="bg-white border border-cyan-200 rounded-xl p-5 soft-elevation relative bg-gradient-to-b from-cyan-50/30 to-white">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-cyan-800 uppercase tracking-wider">
                  Active in Drafting
                </span>
                <div className="p-2 rounded-lg bg-cyan-50 text-cyan-700 border border-cyan-200">
                  <PlayCircle className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-extrabold font-mono tracking-tight text-cyan-800">
                  {inProgressCount + waitingAcceptanceCount}
                </span>
                <span className="text-xs text-cyan-700 font-medium">in drawing phase</span>
              </div>
              <div className="mt-4 pt-3 border-t border-cyan-100 flex items-center justify-between text-xs font-mono text-slate-500">
                <span>{waitingAcceptanceCount} awaiting accept</span>
                <span>{engineerReviewCount} in review</span>
              </div>
            </div>
          </div>

          {/* Platform State Machine Distribution & Queue */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Status Breakdown & Priority Queue */}
            <div className="lg:col-span-2 space-y-6">
              <Card technicalCorners>
                <CardHeader
                  title="Ecosystem State Machine Distribution"
                  subtitle="Live status distribution across all projects in the Cloudflare D1 database"
                />

                <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-4">
                  <div className="p-3 rounded-xl bg-slate-50 border border-slate-200">
                    <p className="text-[11px] font-mono font-semibold text-slate-500 uppercase">1. Drafts</p>
                    <p className="text-2xl font-bold font-mono text-slate-900 mt-1">{byStatus['DRAFT'] || 0}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-amber-50/70 border border-amber-200">
                    <p className="text-[11px] font-mono font-semibold text-amber-800 uppercase">2. Submitted</p>
                    <p className="text-2xl font-bold font-mono text-amber-800 mt-1">{submittedCount}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-blue-50/70 border border-blue-200">
                    <p className="text-[11px] font-mono font-semibold text-[#0453cd] uppercase">3. Awaiting Assign</p>
                    <p className="text-2xl font-bold font-mono text-[#0453cd] mt-1">{waitingAssignmentCount}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-purple-50/70 border border-purple-200">
                    <p className="text-[11px] font-mono font-semibold text-purple-800 uppercase">4. Awaiting Accept</p>
                    <p className="text-2xl font-bold font-mono text-purple-800 mt-1">{waitingAcceptanceCount}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-cyan-50/70 border border-cyan-200">
                    <p className="text-[11px] font-mono font-semibold text-cyan-800 uppercase">5. In Progress</p>
                    <p className="text-2xl font-bold font-mono text-cyan-800 mt-1">{inProgressCount}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-teal-50/70 border border-teal-200">
                    <p className="text-[11px] font-mono font-semibold text-teal-800 uppercase">6. Engineer Review</p>
                    <p className="text-2xl font-bold font-mono text-teal-800 mt-1">{engineerReviewCount}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-emerald-50/70 border border-emerald-200">
                    <p className="text-[11px] font-mono font-semibold text-emerald-800 uppercase">7. Completed</p>
                    <p className="text-2xl font-bold font-mono text-emerald-800 mt-1">{completedCount}</p>
                  </div>
                  <div className="p-3 rounded-xl bg-rose-50/70 border border-rose-200">
                    <p className="text-[11px] font-mono font-semibold text-rose-800 uppercase">8. Cancelled</p>
                    <p className="text-2xl font-bold font-mono text-rose-800 mt-1">{cancelledCount}</p>
                  </div>
                </div>

                {/* Action Required Queue */}
                <div className="mt-8 pt-6 border-t border-slate-100">
                  <div className="flex items-center justify-between mb-4">
                    <div className="flex items-center gap-2">
                      <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
                      <h4 className="text-xs font-mono font-bold uppercase tracking-wider text-slate-800">
                        High Priority Admin Queue
                      </h4>
                    </div>
                    <Link href="/projects" className="text-xs font-semibold text-[#0453cd] hover:underline flex items-center gap-1">
                      <span>View all projects</span>
                      <ChevronRight className="h-3.5 w-3.5" />
                    </Link>
                  </div>

                  {pendingProjects.length === 0 ? (
                    <EmptyState
                      compact
                      title="Admin Action Queue Clear"
                      description="All submitted drawings and draughtsman assignments are fully up to date."
                      primaryAction={{
                        label: "Open Project Catalog",
                        href: "/projects",
                      }}
                    />
                  ) : (
                    <div className="space-y-2.5">
                      {pendingProjects.map((p) => (
                        <div
                          key={p.id}
                          className="p-4 rounded-xl bg-slate-50/70 border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:border-slate-300 transition-colors"
                        >
                          <div className="overflow-hidden">
                            <Link
                              href={`/projects/${p.id}`}
                              className="font-bold text-slate-900 text-sm hover:text-[#0453cd] transition-colors truncate block"
                            >
                              {p.project_name}
                            </Link>
                            <div className="flex items-center gap-3 text-xs text-slate-500 font-mono mt-1">
                              <span>{p.drawing_name || p.drawing_type}</span>
                              <span>&bull;</span>
                              <span>{p.project_area || 'Standard'} sq.ft</span>
                            </div>
                          </div>
                          <div className="flex items-center gap-3 shrink-0">
                            <Badge status={p.status} />
                            <Link
                              href={`/projects/${p.id}`}
                              className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#0d1c32] hover:bg-[#15294a] text-white text-xs font-mono font-semibold transition-all shadow-xs"
                            >
                              <span>Review</span>
                              <ExternalLink className="h-3 w-3" />
                            </Link>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </div>
              </Card>
            </div>

            {/* Studio Talent & Users Column */}
            <div className="space-y-6">
              <Card technicalCorners>
                <CardHeader
                  title="Studio Ecosystem Roster"
                  subtitle="Active roles across the Archi Draft platform"
                />
                <div className="space-y-3 mt-2">
                  {/* Engineers */}
                  <Link
                    href="/engineers"
                    className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-200 hover:border-indigo-300 hover:bg-indigo-50/40 transition-colors group"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-lg bg-indigo-50 text-indigo-700 flex items-center justify-center font-mono font-bold text-xs border border-indigo-200">
                        EN
                      </div>
                      <div>
                        <p className="text-xs font-bold text-slate-900 group-hover:text-indigo-800 transition-colors">
                          Engineers
                        </p>
                        <p className="text-[11px] text-slate-500">Structural, Civil & MEP</p>
                      </div>
                    </div>
                    <span className="text-base font-extrabold font-mono text-indigo-700">{engineerCount}</span>
                  </Link>

                  {/* Draughtsmen */}
                  <Link
                    href="/draughtsmen"
                    className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-200 hover:border-blue-300 hover:bg-blue-50/40 transition-colors group"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-lg bg-blue-50 text-[#0453cd] flex items-center justify-center font-mono font-bold text-xs border border-blue-200">
                        DM
                      </div>
                      <div>
                        <p className="text-xs font-bold text-slate-900 group-hover:text-[#0453cd] transition-colors">
                          Draughtsmen
                        </p>
                        <p className="text-[11px] text-slate-500">Certified CAD & BIM Pool</p>
                      </div>
                    </div>
                    <span className="text-base font-extrabold font-mono text-[#0453cd]">{draughtsmanCount}</span>
                  </Link>

                  {/* Students */}
                  <Link
                    href="/students"
                    className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-200 hover:border-emerald-300 hover:bg-emerald-50/40 transition-colors group"
                  >
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-lg bg-emerald-50 text-emerald-700 flex items-center justify-center font-mono font-bold text-xs border border-emerald-200">
                        ST
                      </div>
                      <div>
                        <p className="text-xs font-bold text-slate-900 group-hover:text-emerald-800 transition-colors">
                          Students
                        </p>
                        <p className="text-[11px] text-slate-500">Apprentice Program</p>
                      </div>
                    </div>
                    <span className="text-base font-extrabold font-mono text-emerald-700">{studentCount}</span>
                  </Link>

                  {/* Studio Admins */}
                  <div className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50 border border-slate-200">
                    <div className="flex items-center gap-3">
                      <div className="h-9 w-9 rounded-lg bg-[#0d1c32] text-white flex items-center justify-center font-mono font-bold text-xs">
                        AD
                      </div>
                      <div>
                        <p className="text-xs font-bold text-slate-900">Studio Admins</p>
                        <p className="text-[11px] text-slate-500">Privileged Console Operators</p>
                      </div>
                    </div>
                    <span className="text-base font-extrabold font-mono text-slate-900">{adminCount}</span>
                  </div>
                </div>

                <div className="mt-5 pt-3 border-t border-slate-100 flex items-center justify-between text-xs font-mono text-slate-500">
                  <span>Total Registered Identities</span>
                  <span className="font-bold text-slate-900">{stats?.users?.total || 0}</span>
                </div>
              </Card>

              {/* Security & Architecture Reminder */}
              <div className="rounded-xl border border-blue-200 bg-blue-50/60 p-5 soft-elevation">
                <div className="flex items-center gap-2 text-xs font-mono font-bold uppercase tracking-wider text-[#0453cd] mb-2">
                  <ShieldCheck className="h-4 w-4" />
                  <span>Immutable Governance</span>
                </div>
                <p className="text-xs text-slate-600 leading-relaxed font-sans">
                  All administrative actions (approvals, rejections, assignments, and cancellations)
                  are verified via Firebase ID tokens and logged into the immutable D1
                  audit trail with unique idempotency action IDs.
                </p>
              </div>
            </div>
          </div>

          {/* Live Recent Activity Feed */}
          <Card technicalCorners>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <ActivityIcon className="h-4 w-4 text-[#0453cd]" />
                <h3 className="text-base font-bold text-slate-900">Live Activity Feed</h3>
              </div>
              <Link href="/activity" className="text-xs font-semibold text-[#0453cd] hover:underline flex items-center gap-1">
                <span>View full audit stream</span>
                <ChevronRight className="h-3.5 w-3.5" />
              </Link>
            </div>

            {(!stats?.recentActivity || stats.recentActivity.length === 0) ? (
              <p className="text-xs font-mono text-slate-400 py-8 text-center">No recent activity recorded yet.</p>
            ) : (
              <div className="divide-y divide-slate-100">
                {stats.recentActivity.slice(0, 6).map((log) => (
                  <div key={log.id} className="py-3 flex items-start justify-between gap-4">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-bold font-mono text-[#0453cd]">
                          {log.action_type}
                        </span>
                        <Badge role={log.actor_role} size="sm" />
                      </div>
                      <p className="text-xs text-slate-600">{log.details}</p>
                    </div>
                    <div className="text-right shrink-0">
                      <p className="text-[10px] text-slate-400 font-mono">
                        {new Date(log.timestamp).toLocaleTimeString()}
                      </p>
                      <Link
                        href={`/projects/${log.project_id}`}
                        className="text-[10px] text-[#0453cd] hover:underline font-mono mt-0.5 block"
                      >
                        Project #{log.project_id.substring(0, 8)}
                      </Link>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </Card>
        </div>
      )}
    </AdminShell>
  );
}

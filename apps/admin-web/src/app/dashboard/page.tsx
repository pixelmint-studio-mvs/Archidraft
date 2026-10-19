'use client';

import React, { useState, useEffect } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
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
  const clientReviewCount = byStatus['UNDER_CLIENT_REVIEW'] || 0;
  const completedCount = byStatus['COMPLETED'] || 0;
  const cancelledCount = byStatus['CANCELLED'] || 0;

  const usersByRole = stats?.users?.byRole || {};
  const draughtsmanCount = usersByRole['DRAUGHTSMAN'] || 0;
  const clientCount = usersByRole['CLIENT'] || 0;
  const adminCount = usersByRole['ADMIN'] || 0;

  return (
    <AdminShell
      title="Studio Operations Dashboard"
      subtitle="Executive platform status & actionable workflow queues"
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-sm text-rose-300 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-400 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadData(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
          <p className="text-xs text-slate-400 mt-3 font-medium">Aggregating platform metrics...</p>
        </div>
      ) : (
        <div className="space-y-8">
          {/* Top KPI Cards Grid */}
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            {/* Total Projects */}
            <Card className="relative overflow-hidden border-blue-900/30">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-slate-400 uppercase tracking-wider">
                  Total Projects
                </span>
                <div className="p-2 rounded-lg bg-blue-500/10 text-blue-400 border border-blue-500/20">
                  <FolderKanban className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-bold tracking-tight text-slate-100">
                  {stats?.projects?.total ?? 0}
                </span>
                <span className="text-xs text-slate-400 font-medium">registered in D1</span>
              </div>
              <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
                <span>{completedCount} completed</span>
                <span>{cancelledCount} cancelled</span>
              </div>
            </Card>

            {/* Pending Admin Review */}
            <Card className="relative overflow-hidden border-amber-900/40 bg-gradient-to-b from-[#17140e] to-[#0f172a]">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-amber-400 uppercase tracking-wider">
                  Requires Review
                </span>
                <div className="p-2 rounded-lg bg-amber-500/10 text-amber-400 border border-amber-500/20">
                  <Clock className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-bold tracking-tight text-amber-300">
                  {submittedCount}
                </span>
                <span className="text-xs text-amber-400/80 font-medium">submitted by clients</span>
              </div>
              <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
                <Link
                  href="/projects?status=SUBMITTED"
                  className="text-amber-400 hover:text-amber-300 font-medium flex items-center gap-1 group"
                >
                  <span>Review Submissions</span>
                  <ArrowRight className="h-3 w-3 group-hover:translate-x-0.5 transition-transform" />
                </Link>
              </div>
            </Card>

            {/* Waiting Draughtsman Assignment */}
            <Card className="relative overflow-hidden border-blue-800/30">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-blue-400 uppercase tracking-wider">
                  Needs Draughtsman
                </span>
                <div className="p-2 rounded-lg bg-blue-500/10 text-blue-400 border border-blue-500/20">
                  <UserPlus className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-bold tracking-tight text-blue-300">
                  {waitingAssignmentCount}
                </span>
                <span className="text-xs text-blue-400/80 font-medium">approved, unassigned</span>
              </div>
              <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs">
                <Link
                  href="/projects?status=WAITING_ASSIGNMENT"
                  className="text-blue-400 hover:text-blue-300 font-medium flex items-center gap-1 group"
                >
                  <span>Assign Draughtsman</span>
                  <ArrowRight className="h-3 w-3 group-hover:translate-x-0.5 transition-transform" />
                </Link>
              </div>
            </Card>

            {/* Active Drafting Work */}
            <Card className="relative overflow-hidden border-cyan-900/30">
              <div className="flex items-center justify-between">
                <span className="text-xs font-semibold text-cyan-400 uppercase tracking-wider">
                  Active in Drafting
                </span>
                <div className="p-2 rounded-lg bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
                  <PlayCircle className="h-4 w-4" />
                </div>
              </div>
              <div className="mt-3 flex items-baseline gap-2">
                <span className="text-3xl font-bold tracking-tight text-cyan-300">
                  {inProgressCount + waitingAcceptanceCount}
                </span>
                <span className="text-xs text-cyan-400/80 font-medium">in production</span>
              </div>
              <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between text-xs text-slate-400">
                <span>{waitingAcceptanceCount} pending acceptance</span>
                <span>{clientReviewCount} in review</span>
              </div>
            </Card>
          </div>

          {/* Platform Status Distribution & Quick Actions */}
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            {/* Status Breakdown */}
            <Card className="lg:col-span-2">
              <CardHeader
                title="Ecosystem State Machine Distribution"
                subtitle="Live status distribution across all projects in the Cloudflare D1 database"
              />

              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mt-4">
                <div className="p-3 rounded-xl bg-slate-900/80 border border-slate-800">
                  <p className="text-[11px] font-semibold text-slate-400 uppercase">1. Drafts</p>
                  <p className="text-xl font-bold text-slate-200 mt-1">{byStatus['DRAFT'] || 0}</p>
                </div>
                <div className="p-3 rounded-xl bg-amber-500/5 border border-amber-500/20">
                  <p className="text-[11px] font-semibold text-amber-400 uppercase">2. Submitted</p>
                  <p className="text-xl font-bold text-amber-300 mt-1">{submittedCount}</p>
                </div>
                <div className="p-3 rounded-xl bg-blue-500/5 border border-blue-500/20">
                  <p className="text-[11px] font-semibold text-blue-400 uppercase">3. Awaiting Assign</p>
                  <p className="text-xl font-bold text-blue-300 mt-1">{waitingAssignmentCount}</p>
                </div>
                <div className="p-3 rounded-xl bg-purple-500/5 border border-purple-500/20">
                  <p className="text-[11px] font-semibold text-purple-400 uppercase">4. Awaiting Accept</p>
                  <p className="text-xl font-bold text-purple-300 mt-1">{waitingAcceptanceCount}</p>
                </div>
                <div className="p-3 rounded-xl bg-cyan-500/5 border border-cyan-500/20">
                  <p className="text-[11px] font-semibold text-cyan-400 uppercase">5. In Progress</p>
                  <p className="text-xl font-bold text-cyan-300 mt-1">{inProgressCount}</p>
                </div>
                <div className="p-3 rounded-xl bg-teal-500/5 border border-teal-500/20">
                  <p className="text-[11px] font-semibold text-teal-400 uppercase">6. Client Review</p>
                  <p className="text-xl font-bold text-teal-300 mt-1">{clientReviewCount}</p>
                </div>
                <div className="p-3 rounded-xl bg-emerald-500/5 border border-emerald-500/20">
                  <p className="text-[11px] font-semibold text-emerald-400 uppercase">7. Completed</p>
                  <p className="text-xl font-bold text-emerald-300 mt-1">{completedCount}</p>
                </div>
                <div className="p-3 rounded-xl bg-rose-500/5 border border-rose-500/20">
                  <p className="text-[11px] font-semibold text-rose-400 uppercase">8. Cancelled</p>
                  <p className="text-xl font-bold text-rose-300 mt-1">{cancelledCount}</p>
                </div>
              </div>

              {/* Action Required Queue */}
              <div className="mt-6 pt-5 border-t border-slate-800">
                <div className="flex items-center justify-between mb-3">
                  <h4 className="text-sm font-semibold text-slate-200">
                    Priority Workflow Action Queue
                  </h4>
                  <Link
                    href="/projects"
                    className="text-xs text-blue-400 hover:text-blue-300 flex items-center gap-1"
                  >
                    <span>View all projects</span>
                    <ArrowRight className="h-3 w-3" />
                  </Link>
                </div>

                {pendingProjects.length === 0 ? (
                  <div className="p-4 text-center text-xs text-slate-400 bg-slate-900/40 rounded-xl border border-slate-800">
                    All submitted projects have been processed. No pending admin approvals or assignments.
                  </div>
                ) : (
                  <div className="space-y-2">
                    {pendingProjects.map((p) => (
                      <div
                        key={p.id}
                        className="flex items-center justify-between p-3 rounded-xl bg-slate-900/60 border border-slate-800 hover:border-slate-700 transition-colors"
                      >
                        <div className="flex items-center gap-3 overflow-hidden">
                          <Badge status={p.status} />
                          <div className="overflow-hidden">
                            <p className="text-sm font-semibold text-slate-100 truncate">
                              {p.project_name || 'Untitled Project'}
                            </p>
                            <p className="text-xs text-slate-400 truncate">
                              {p.drawing_type} &bull; {p.project_area || 'Standard'} sq.ft &bull;{' '}
                              {p.project_address}
                            </p>
                          </div>
                        </div>
                        <Link href={`/projects/${p.id}`}>
                          <Button variant="outline" size="sm">
                            Manage
                          </Button>
                        </Link>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </Card>

            {/* User Breakdown & Studio Overview */}
            <div className="space-y-6">
              <Card>
                <CardHeader
                  title="Studio Talent & Users"
                  subtitle="Active roles across the Archi Draft platform"
                />
                <div className="space-y-3 mt-2">
                  <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900 border border-slate-800">
                    <div className="flex items-center gap-2.5">
                      <div className="h-8 w-8 rounded-lg bg-cyan-500/10 text-cyan-400 flex items-center justify-center font-bold text-xs border border-cyan-500/20">
                        DM
                      </div>
                      <div>
                        <p className="text-xs font-semibold text-slate-200">Draughtsmen</p>
                        <p className="text-[10px] text-slate-400">Assigned drafting professionals</p>
                      </div>
                    </div>
                    <span className="text-base font-bold text-cyan-400">{draughtsmanCount}</span>
                  </div>

                  <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900 border border-slate-800">
                    <div className="flex items-center gap-2.5">
                      <div className="h-8 w-8 rounded-lg bg-indigo-500/10 text-indigo-400 flex items-center justify-center font-bold text-xs border border-indigo-500/20">
                        CL
                      </div>
                      <div>
                        <p className="text-xs font-semibold text-slate-200">Clients</p>
                        <p className="text-[10px] text-slate-400">Homeowners & builders</p>
                      </div>
                    </div>
                    <span className="text-base font-bold text-indigo-400">{clientCount}</span>
                  </div>

                  <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900 border border-slate-800">
                    <div className="flex items-center gap-2.5">
                      <div className="h-8 w-8 rounded-lg bg-rose-500/10 text-rose-400 flex items-center justify-center font-bold text-xs border border-rose-500/20">
                        AD
                      </div>
                      <div>
                        <p className="text-xs font-semibold text-slate-200">Studio Admins</p>
                        <p className="text-[10px] text-slate-400">Privileged operators</p>
                      </div>
                    </div>
                    <span className="text-base font-bold text-rose-400">{adminCount}</span>
                  </div>
                </div>

                <div className="mt-4 pt-3 border-t border-slate-800 flex items-center justify-between text-xs">
                  <span className="text-slate-400">Total Registered</span>
                  <span className="font-bold text-slate-100">{stats?.users?.total || 0}</span>
                </div>
              </Card>

              {/* Security & Architecture Reminder */}
              <Card className="border-blue-900/40 bg-gradient-to-br from-[#0b1426] to-[#0f172a]">
                <div className="flex items-center gap-2 text-xs font-semibold uppercase tracking-wider text-blue-400 mb-2">
                  <ShieldCheck className="h-4 w-4" />
                  <span>Immutable Governance</span>
                </div>
                <p className="text-xs text-slate-300 leading-relaxed">
                  All administrative actions (approvals, rejections, assignments, and cancellations)
                  are cryptographically verified via Firebase ID tokens and logged into the immutable D1
                  audit trail with unique action IDs.
                </p>
              </Card>
            </div>
          </div>

          {/* Live Recent Activity Feed */}
          <Card>
            <div className="flex items-center justify-between mb-4">
              <div className="flex items-center gap-2">
                <ActivityIcon className="h-4 w-4 text-blue-400" />
                <h3 className="text-base font-semibold text-slate-100">Live Activity Feed</h3>
              </div>
              <Link href="/activity" className="text-xs text-blue-400 hover:text-blue-300">
                View all logs &rarr;
              </Link>
            </div>

            {(!stats?.recentActivity || stats.recentActivity.length === 0) ? (
              <p className="text-xs text-slate-400 py-6 text-center">No recent activity recorded yet.</p>
            ) : (
              <div className="divide-y divide-slate-800/80">
                {stats.recentActivity.slice(0, 8).map((log) => (
                  <div key={log.id} className="py-3 flex items-start justify-between gap-4">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="text-xs font-semibold font-mono text-blue-400">
                          {log.action_type}
                        </span>
                        <Badge role={log.actor_role} size="sm" />
                      </div>
                      <p className="text-xs text-slate-300">{log.details}</p>
                    </div>
                    <div className="text-right shrink-0">
                      <p className="text-[10px] text-slate-500 font-mono">
                        {new Date(log.timestamp).toLocaleString()}
                      </p>
                      <Link
                        href={`/projects/${log.project_id}`}
                        className="text-[10px] text-slate-400 hover:text-slate-200 font-mono mt-0.5 block"
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

'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import { User, Project } from '@/lib/types';
import { DraughtsmanProfileView } from '@/components/draughtsmen/DraughtsmanProfileView';
import {
  Search,
  PenTool,
  Mail,
  Phone,
  GraduationCap,
  Calendar,
  AlertCircle,
  ExternalLink,
  Layers,
  Clock,
  Eye,
  CheckCircle2,
  Briefcase,
  Activity,
  Upload,
  TrendingUp,
  ChevronDown,
  ChevronUp,
  RotateCcw,
  PlayCircle,
  BarChart3,
} from 'lucide-react';

// Maps project status to a compact workspace-style badge
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
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[10px] font-mono font-semibold border ${bg} ${border} ${color}`}>
      {label}
    </span>
  );
}

export default function DraughtsmenPage() {
  const [draughtsmen, setDraughtsmen] = useState<User[]>([]);
  const [projects, setProjects] = useState<Project[]>([]);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Detail Modal State
  const [selectedDraughtsman, setSelectedDraughtsman] = useState<User | null>(null);
  const [assignments, setAssignments] = useState<any[]>([]);
  const [loadingDetails, setLoadingDetails] = useState<boolean>(false);

  const loadData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [usersData, projectsData] = await Promise.all([
        adminApi.getUsers('DRAUGHTSMAN'),
        adminApi.getProjects(),
      ]);
      setDraughtsmen(usersData || []);
      setProjects(projectsData || []);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load Draughtsman talent pool');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const openDraughtsmanDetails = async (draughtsman: User) => {
    setSelectedDraughtsman(draughtsman);
    setLoadingDetails(true);
    try {
      const details = await adminApi.getUserDetails(draughtsman.id);
      if (details.user) {
        setSelectedDraughtsman(details.user);
      }
      setAssignments(details.projects || []);
    } catch {
      // Fallback: match by draughtsman_id in project list
      const matched = projects.filter((p) => p.draughtsman_id === draughtsman.id);
      setAssignments(matched);
    } finally {
      setLoadingDetails(false);
    }
  };

  // Pre-calculate active vs completed projects per draughtsman
  const statsByDraughtsman = useMemo(() => {
    const stats: Record<string, { active: number; completed: number }> = {};
    projects.forEach((p) => {
      if (p.draughtsman_id) {
        if (!stats[p.draughtsman_id]) {
          stats[p.draughtsman_id] = { active: 0, completed: 0 };
        }
        if (p.status === 'COMPLETED') {
          stats[p.draughtsman_id].completed += 1;
        } else if (
          p.status === 'WAITING_ACCEPTANCE' ||
          p.status === 'IN_PROGRESS' ||
          p.status === 'UNDER_CLIENT_REVIEW'
        ) {
          stats[p.draughtsman_id].active += 1;
        }
      }
    });
    return stats;
  }, [projects]);

  const filteredDraughtsmen = useMemo(() => {
    return draughtsmen.filter((dm) => {
      if (!searchQuery.trim()) return true;
      const q = searchQuery.toLowerCase();
      const nameMatch = (dm.name || '').toLowerCase().includes(q);
      const emailMatch = (dm.email || '').toLowerCase().includes(q);
      const qualMatch = (dm.qualification || '').toLowerCase().includes(q);
      const collegeMatch = (dm.college_name || '').toLowerCase().includes(q);
      const mobileMatch = (dm.mobile || '').toLowerCase().includes(q);
      return nameMatch || emailMatch || qualMatch || collegeMatch || mobileMatch;
    });
  }, [draughtsmen, searchQuery]);

  const totalDraughtsmen = draughtsmen.length;
  const currentlyAssignedCount = draughtsmen.filter(
    (dm) => (statsByDraughtsman[dm.id]?.active || 0) > 0
  ).length;
  const availableCount = totalDraughtsmen - currentlyAssignedCount;

  return (
    <AdminShell
      title="Draughtsman Management"
      subtitle="Technical drawing talent pool, workload allocation, and assignment history"
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

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5 sm:gap-4 mb-6">
        <Card technicalCorners className="p-4 sm:p-5 bg-white border-slate-200 soft-elevation">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Total Draughtsmen</p>
            <PenTool className="h-4 w-4 text-[#0453cd]" />
          </div>
          <p className="text-2xl font-bold font-mono text-slate-900 mt-2">{totalDraughtsmen}</p>
          <p className="text-[11px] text-slate-500 mt-1 font-mono">Certified CAD / BIM specialists</p>
        </Card>

        <Card technicalCorners className="p-4 sm:p-5 bg-white border-slate-200 soft-elevation">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Currently Assigned</p>
            <Briefcase className="h-4 w-4 text-[#0453cd]" />
          </div>
          <p className="text-2xl font-bold font-mono text-slate-900 mt-2">{currentlyAssignedCount}</p>
          <p className="text-[11px] text-slate-500 mt-1 font-mono">Executing live drawing drafting</p>
        </Card>

        <Card technicalCorners className="p-4 sm:p-5 bg-white border-slate-200 soft-elevation sm:col-span-2 lg:col-span-1">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Available For Workload</p>
            <CheckCircle2 className="h-4 w-4 text-emerald-600" />
          </div>
          <p className="text-2xl font-bold font-mono text-slate-900 mt-2">{availableCount}</p>
          <p className="text-[11px] text-slate-500 mt-1 font-mono">Ready for assignment to approved projects</p>
        </Card>
      </div>

      {/* Search Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
        <div className="relative w-full sm:max-w-md flex-1">
          <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by name, qualification, college, or email..."
            className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd] focus:border-[#0453cd] shadow-xs transition-all"
          />
        </div>
        <p className="text-xs text-slate-500 font-mono whitespace-nowrap">
          Showing <span className="text-slate-900 font-bold">{filteredDraughtsmen.length}</span> of {totalDraughtsmen} Draughtsmen
        </p>
      </div>

      {/* Directory Table */}
      <Card technicalCorners className="bg-white border-slate-200 soft-elevation">
        {loading ? (
          <div className="flex flex-col items-center justify-center p-20">
            <div className="h-7 w-7 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
            <p className="text-xs text-slate-500 mt-3 font-mono">Loading Draughtsman directory...</p>
          </div>
        ) : filteredDraughtsmen.length === 0 ? (
          <div className="p-16 text-center">
            <PenTool className="h-10 w-10 text-slate-300 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-700">No Draughtsmen Found</p>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto font-mono">
              {searchQuery
                ? `No draughtsmen match "${searchQuery}". Try a different search term.`
                : 'No draughtsmen are registered in the talent pool.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto w-full max-w-full">
            <table className="w-full text-left text-xs min-w-[740px]">
              <thead className="bg-slate-50 text-slate-500 font-mono font-semibold uppercase tracking-wider border-b border-slate-200 text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Draughtsman</th>
                  <th className="px-5 py-3.5">Qualification & Institution</th>
                  <th className="px-5 py-3.5">Contact</th>
                  <th className="px-5 py-3.5">Registered</th>
                  <th className="px-5 py-3.5">Workload Status</th>
                  <th className="px-5 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredDraughtsmen.map((dm) => {
                  const stat = statsByDraughtsman[dm.id] || { active: 0, completed: 0 };
                  const isBusy = stat.active > 0;
                  return (
                    <tr key={dm.id} className="hover:bg-slate-50/80 transition-colors">
                      {/* Name & ID */}
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xs shrink-0">
                            {dm.name ? dm.name.charAt(0).toUpperCase() : 'D'}
                          </div>
                          <div>
                            <p className="font-semibold text-slate-900 text-sm">{dm.name || 'Unnamed Draughtsman'}</p>
                            <p className="text-[10px] font-mono text-slate-400 mt-0.5">
                              UID: {dm.id.substring(0, 8)}...
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Qualification & College */}
                      <td className="px-5 py-4 space-y-1">
                        <p className="text-slate-900 font-medium">{dm.qualification || 'Civil Draughtsman'}</p>
                        {dm.college_name && (
                          <div className="flex items-center gap-1.5 text-slate-600 text-[11px]">
                            <GraduationCap className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                            <span className="truncate max-w-[200px]">{dm.college_name}</span>
                          </div>
                        )}
                      </td>

                      {/* Contact */}
                      <td className="px-5 py-4 space-y-1">
                        <div className="flex items-center gap-1.5 text-slate-700">
                          <Mail className="h-3 w-3 text-slate-400 shrink-0" />
                          <span className="truncate max-w-[180px] font-mono text-[11px]">{dm.email}</span>
                        </div>
                        {dm.mobile && (
                          <div className="flex items-center gap-1.5 text-slate-500 font-mono text-[11px]">
                            <Phone className="h-3 w-3 text-slate-400 shrink-0" />
                            <span>{dm.mobile}</span>
                          </div>
                        )}
                      </td>

                      {/* Registration Date */}
                      <td className="px-5 py-4 text-slate-600 font-mono text-[11px]">
                        <div className="flex items-center gap-1.5">
                          <Calendar className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                          <span>{dm.created_at ? new Date(dm.created_at).toLocaleDateString() : '—'}</span>
                        </div>
                      </td>

                      {/* Workload Status */}
                      <td className="px-5 py-4">
                        {isBusy ? (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-mono font-semibold bg-purple-50 text-purple-700 border border-purple-200">
                            <span className="h-1.5 w-1.5 rounded-full bg-purple-500 animate-pulse" />
                            <span>{stat.active} Active Assignment{stat.active > 1 ? 's' : ''}</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-mono font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" />
                            <span>Available ({stat.completed} completed)</span>
                          </span>
                        )}
                      </td>

                      {/* Actions */}
                      <td className="px-5 py-4 text-right">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => openDraughtsmanDetails(dm)}
                          className="flex items-center gap-1.5 ml-auto"
                        >
                          <Eye className="h-3.5 w-3.5 text-[#0453cd]" />
                          <span>Workload & History</span>
                        </Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* ─── Draughtsman Workspace Preview Modal ─────────────────────────── */}
      {selectedDraughtsman && (
        <Modal
          isOpen={!!selectedDraughtsman}
          onClose={() => setSelectedDraughtsman(null)}
          title={`Workspace: ${selectedDraughtsman.name || 'Unnamed Draughtsman'}`}
          description={`UID ${selectedDraughtsman.id.substring(0, 12)}… • ${selectedDraughtsman.qualification || 'Certified Draughtsman'}`}
          maxWidth="2xl"
        >
          <div className="mb-3 flex justify-end">
            <Link
              href={`/draughtsmen/${selectedDraughtsman.id}`}
              className="text-xs font-mono text-[#0453cd] hover:underline flex items-center gap-1 bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-md"
            >
              <span>Open Full Page Workspace</span>
              <ExternalLink className="h-3 w-3" />
            </Link>
          </div>
          <DraughtsmanProfileView
            draughtsman={selectedDraughtsman}
            assignments={assignments}
            loading={loadingDetails}
            onClose={() => setSelectedDraughtsman(null)}
          />
        </Modal>
      )}
    </AdminShell>
  );
}

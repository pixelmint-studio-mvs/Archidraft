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
} from 'lucide-react';

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
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <Card className="p-4 border-cyan-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[11px] font-semibold uppercase text-cyan-400">Total Draughtsmen</p>
            <PenTool className="h-4 w-4 text-cyan-400" />
          </div>
          <p className="text-2xl font-bold text-cyan-300 mt-2">{totalDraughtsmen}</p>
          <p className="text-[11px] text-slate-500 mt-1">Certified CAD / BIM specialists</p>
        </Card>

        <Card className="p-4 border-purple-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[11px] font-semibold uppercase text-purple-400">Currently Assigned</p>
            <Briefcase className="h-4 w-4 text-purple-400" />
          </div>
          <p className="text-2xl font-bold text-purple-300 mt-2">{currentlyAssignedCount}</p>
          <p className="text-[11px] text-slate-500 mt-1">Executing live drawing drafting</p>
        </Card>

        <Card className="p-4 border-emerald-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[11px] font-semibold uppercase text-emerald-400">Available For Workload</p>
            <CheckCircle2 className="h-4 w-4 text-emerald-400" />
          </div>
          <p className="text-2xl font-bold text-emerald-300 mt-2">{availableCount}</p>
          <p className="text-[11px] text-slate-500 mt-1">Ready for assignment to approved projects</p>
        </Card>
      </div>

      {/* Search Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div className="relative flex-1 max-w-md">
          <Search className="h-4 w-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by name, qualification, college, or email..."
            className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-700/80 rounded-xl text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-cyan-500 focus:border-cyan-500 transition-all"
          />
        </div>
        <p className="text-xs text-slate-400 font-mono">
          Showing <span className="text-slate-200 font-bold">{filteredDraughtsmen.length}</span> of {totalDraughtsmen} Draughtsmen
        </p>
      </div>

      {/* Directory Table */}
      <Card>
        {loading ? (
          <div className="flex flex-col items-center justify-center p-20">
            <div className="h-7 w-7 animate-spin rounded-full border-4 border-cyan-500 border-t-transparent" />
            <p className="text-xs text-slate-400 mt-3 font-medium">Loading Draughtsman directory...</p>
          </div>
        ) : filteredDraughtsmen.length === 0 ? (
          <div className="p-16 text-center">
            <PenTool className="h-10 w-10 text-slate-600 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-300">No Draughtsmen Found</p>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
              {searchQuery
                ? `No draughtsmen match "${searchQuery}". Try a different search term.`
                : 'No draughtsmen are registered in the talent pool.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-900/90 text-slate-400 font-semibold uppercase tracking-wider border-b border-slate-800 text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Draughtsman</th>
                  <th className="px-5 py-3.5">Qualification & Institution</th>
                  <th className="px-5 py-3.5">Contact</th>
                  <th className="px-5 py-3.5">Registered</th>
                  <th className="px-5 py-3.5">Workload Status</th>
                  <th className="px-5 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/80">
                {filteredDraughtsmen.map((dm) => {
                  const stat = statsByDraughtsman[dm.id] || { active: 0, completed: 0 };
                  const isBusy = stat.active > 0;
                  return (
                    <tr key={dm.id} className="hover:bg-slate-800/30 transition-colors">
                      {/* Name & ID */}
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-cyan-500/10 border border-cyan-500/20 text-cyan-400 flex items-center justify-center font-bold text-xs shrink-0">
                            {dm.name ? dm.name.charAt(0).toUpperCase() : 'D'}
                          </div>
                          <div>
                            <p className="font-semibold text-slate-200 text-sm">{dm.name || 'Unnamed Draughtsman'}</p>
                            <p className="text-[10px] font-mono text-slate-500 mt-0.5">
                              UID: {dm.id.substring(0, 8)}...
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Qualification & College */}
                      <td className="px-5 py-4 space-y-1">
                        <p className="text-slate-200 font-medium">{dm.qualification || 'Civil Draughtsman'}</p>
                        {dm.college_name && (
                          <div className="flex items-center gap-1.5 text-slate-400 text-[11px]">
                            <GraduationCap className="h-3 w-3 text-slate-500 shrink-0" />
                            <span className="truncate max-w-[200px]">{dm.college_name}</span>
                          </div>
                        )}
                      </td>

                      {/* Contact */}
                      <td className="px-5 py-4 space-y-1">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <Mail className="h-3 w-3 text-slate-500 shrink-0" />
                          <span className="truncate max-w-[180px]">{dm.email}</span>
                        </div>
                        {dm.mobile && (
                          <div className="flex items-center gap-1.5 text-slate-400 font-mono text-[11px]">
                            <Phone className="h-3 w-3 text-slate-500 shrink-0" />
                            <span>{dm.mobile}</span>
                          </div>
                        )}
                      </td>

                      {/* Registration Date */}
                      <td className="px-5 py-4 text-slate-400">
                        <div className="flex items-center gap-1.5">
                          <Calendar className="h-3.5 w-3.5 text-slate-500 shrink-0" />
                          <span>{dm.created_at ? new Date(dm.created_at).toLocaleDateString() : '—'}</span>
                        </div>
                      </td>

                      {/* Workload Status */}
                      <td className="px-5 py-4">
                        {isBusy ? (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-purple-500/10 text-purple-400 border border-purple-500/20">
                            <span className="h-1.5 w-1.5 rounded-full bg-purple-400 animate-pulse" />
                            <span>{stat.active} Active Assignment{stat.active > 1 ? 's' : ''}</span>
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
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
                          <Eye className="h-3.5 w-3.5 text-cyan-400" />
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

      {/* Draughtsman Details Modal */}
      {selectedDraughtsman && (
        <Modal
          isOpen={!!selectedDraughtsman}
          onClose={() => setSelectedDraughtsman(null)}
          title={`Draughtsman Profile: ${selectedDraughtsman.name || 'Unnamed'}`}
          description={`Firebase UID: ${selectedDraughtsman.id} • Professional Talent Dossier`}
        >
          <div className="space-y-6">
            {/* Profile Overview */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 p-4 rounded-xl bg-slate-900 border border-slate-800 text-xs">
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Full Name</span>
                <span className="font-semibold text-slate-200 text-sm mt-0.5 block">{selectedDraughtsman.name || '—'}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Email Address</span>
                <span className="font-mono text-slate-300 mt-0.5 block">{selectedDraughtsman.email}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Qualification</span>
                <span className="text-slate-200 font-medium mt-0.5 block">{selectedDraughtsman.qualification || 'Certified Draughtsman'}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">College / Institution</span>
                <span className="text-slate-300 mt-0.5 block">{selectedDraughtsman.college_name || '—'}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Mobile Phone</span>
                <span className="font-mono text-slate-300 mt-0.5 block">{selectedDraughtsman.mobile || '—'}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Portal Authorization</span>
                <Badge role="DRAUGHTSMAN" />
              </div>
            </div>

            {/* Assignments & Drawing Workflow */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-300 flex items-center gap-2">
                  <Layers className="h-4 w-4 text-cyan-400" />
                  <span>Assigned Projects & Workflow History ({assignments.length})</span>
                </h4>
              </div>

              {loadingDetails ? (
                <div className="p-8 text-center text-xs text-slate-400">
                  <div className="h-5 w-5 animate-spin rounded-full border-2 border-cyan-500 border-t-transparent mx-auto mb-2" />
                  Loading assignment workflow history...
                </div>
              ) : assignments.length === 0 ? (
                <div className="p-6 text-center text-xs text-slate-500 bg-slate-900/50 rounded-xl border border-slate-800">
                  No project assignments have been dispatched to this draughtsman yet.
                </div>
              ) : (
                <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
                  {assignments.map((item: any) => {
                    const projectId = item.project_id || item.id;
                    const projectName = item.project_name || 'Drawing Project';
                    const status = item.project_status || item.status;
                    return (
                      <div
                        key={item.id || projectId}
                        className="p-3 rounded-lg bg-slate-900 border border-slate-800 hover:border-slate-700 transition-colors flex items-center justify-between gap-3 text-xs"
                      >
                        <div className="overflow-hidden">
                          <Link
                            href={`/projects/${projectId}`}
                            className="font-semibold text-slate-200 hover:text-cyan-400 transition-colors block truncate"
                          >
                            {projectName}
                          </Link>
                          <p className="text-[10px] text-slate-400 mt-0.5">
                            Drawing: {item.drawing_type || 'Architectural CAD'} &bull; Area: {item.project_area || 'Standard'} sq.ft
                          </p>
                        </div>
                        <div className="flex items-center gap-2 shrink-0">
                          <Badge status={status} />
                          <Link
                            href={`/projects/${projectId}`}
                            className="p-1.5 text-slate-400 hover:text-cyan-400 rounded-lg hover:bg-slate-800 transition-colors"
                            title="Open Project Workspace"
                          >
                            <ExternalLink className="h-3.5 w-3.5" />
                          </Link>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            <div className="pt-4 border-t border-slate-800 flex justify-end">
              <Button variant="outline" size="sm" onClick={() => setSelectedDraughtsman(null)}>
                Close
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </AdminShell>
  );
}

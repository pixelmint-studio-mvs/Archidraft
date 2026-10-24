'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import { Project, User, GlobalAssignment } from '@/lib/types';
import {
  FolderKanban,
  PenTool,
  Clock,
  CheckCircle2,
  AlertCircle,
  Search,
  History,
  Building,
  UserCheck,
  ChevronRight,
  RefreshCw,
  ExternalLink,
  Layers,
  ArrowRight,
  Filter,
  Check,
  BarChart3,
} from 'lucide-react';

const MAX_DRAUGHTSMAN_CAPACITY = 4;

export default function AssignmentsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [draughtsmen, setDraughtsmen] = useState<User[]>([]);
  const [assignments, setAssignments] = useState<GlobalAssignment[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Filters & selection
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [drawingTypeFilter, setDrawingTypeFilter] = useState<string>('ALL');
  const [selectedProject, setSelectedProject] = useState<Project | null>(null);

  // Draughtsman filter in dispatch panel
  const [draughtsmanSearch, setDraughtsmanSearch] = useState<string>('');

  // Confirmation Modal state
  const [confirmModalOpen, setConfirmModalOpen] = useState<boolean>(false);
  const [selectedDraughtsman, setSelectedDraughtsman] = useState<User | null>(null);
  const [assigning, setAssigning] = useState<boolean>(false);
  const [assignSuccess, setAssignSuccess] = useState<string | null>(null);
  const [assignError, setAssignError] = useState<string | null>(null);

  const loadData = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [allProjects, allUsers, allAssignments] = await Promise.all([
        adminApi.getProjects(),
        adminApi.getUsers('DRAUGHTSMAN'),
        adminApi.getAdminAssignments(),
      ]);

      // Filter only projects that are in WAITING_ASSIGNMENT or active queue
      setProjects(allProjects.filter((p) => p.status === 'WAITING_ASSIGNMENT'));
      setDraughtsmen(allUsers.filter((u) => u.role === 'DRAUGHTSMAN'));
      setAssignments(allAssignments);

      // Auto-select first project in queue if none selected
      const queue = allProjects.filter((p) => p.status === 'WAITING_ASSIGNMENT');
      if (queue.length > 0 && !selectedProject) {
        setSelectedProject(queue[0]);
      } else if (queue.length === 0) {
        setSelectedProject(null);
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load assignment queue and draughtsman data.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Calculate workload per draughtsman based on active assignments
  // Active assignments are PENDING or ACCEPTED
  const draughtsmanWorkloadMap = useMemo(() => {
    const map: Record<string, number> = {};
    for (const a of assignments) {
      if (a.status === 'PENDING' || a.status === 'ACCEPTED') {
        map[a.draughtsman_id] = (map[a.draughtsman_id] || 0) + 1;
      }
    }
    return map;
  }, [assignments]);

  // Filter projects queue
  const filteredQueue = useMemo(() => {
    return projects.filter((p) => {
      const matchesSearch =
        p.project_name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
        p.project_address?.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesType =
        drawingTypeFilter === 'ALL' || p.drawing_type.toUpperCase() === drawingTypeFilter.toUpperCase();
      return matchesSearch && matchesType;
    });
  }, [projects, searchQuery, drawingTypeFilter]);

  // Filter draughtsmen
  const filteredDraughtsmen = useMemo(() => {
    return draughtsmen.filter((d) => {
      const matchesSearch =
        d.name.toLowerCase().includes(draughtsmanSearch.toLowerCase()) ||
        d.email.toLowerCase().includes(draughtsmanSearch.toLowerCase()) ||
        d.qualification?.toLowerCase().includes(draughtsmanSearch.toLowerCase());
      return matchesSearch;
    });
  }, [draughtsmen, draughtsmanSearch]);

  // Open confirmation modal
  const handleInitiateAssignment = (dMan: User) => {
    if (!selectedProject) return;
    setSelectedDraughtsman(dMan);
    setAssignError(null);
    setAssignSuccess(null);
    setConfirmModalOpen(true);
  };

  // Perform assignment via shared authorized API
  const handleConfirmAssignment = async () => {
    if (!selectedProject || !selectedDraughtsman) return;
    setAssigning(true);
    setAssignError(null);

    try {
      await adminApi.assignProject(selectedProject.id, selectedDraughtsman.id);
      setAssignSuccess(
        `Successfully dispatched project "${selectedProject.project_name}" to Draughtsman ${selectedDraughtsman.name}.`
      );

      // Close modal after brief feedback and reload queue
      setTimeout(() => {
        setConfirmModalOpen(false);
        setSelectedDraughtsman(null);
        setAssignSuccess(null);
        loadData(true);
      }, 1500);
    } catch (err: any) {
      setAssignError(err.message || 'Failed to dispatch project assignment. Please retry.');
    } finally {
      setAssigning(false);
    }
  };

  const availableCount = draughtsmen.filter(
    (d) => (draughtsmanWorkloadMap[d.id] || 0) < MAX_DRAUGHTSMAN_CAPACITY
  ).length;

  return (
    <AdminShell
      title="Assignment Dispatch Console"
      subtitle="Allocate architectural project scopes to verified draughtsmen based on specialization, capacity, and active workload."
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      <div className="space-y-6">
        {/* ── Top Telemetry & Navigation Tabs (Stitch Spec) ── */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-3">
          <div className="flex items-center gap-2">
            <Link
              href="/assignments"
              className="px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide bg-[#0d1c32] text-white shadow-xs flex items-center gap-2"
            >
              <UserCheck className="h-3.5 w-3.5 text-[#0453cd]" />
              <span>01. Live Queue & Dispatch</span>
              <span className="bg-[#0453cd] text-white text-[10px] px-1.5 py-0.2 rounded-full font-bold ml-1">
                {projects.length}
              </span>
            </Link>
            <Link
              href="/assignments/history"
              className="px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-all flex items-center gap-2"
            >
              <History className="h-3.5 w-3.5 text-slate-400" />
              <span>02. Global Assignment History</span>
            </Link>
          </div>

          <div className="flex items-center gap-3 text-xs font-mono text-slate-500">
            <span className="flex items-center gap-1.5">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
              <span>DISPATCH ENGINE ACTIVE</span>
            </span>
            <span className="h-3 w-px bg-slate-200" />
            <span>MAX CAP: 4 PRJ/TALENT</span>
          </div>
        </div>

        {/* ── Stats Strip ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Waiting Assignment
              </p>
              <Clock className="h-4 w-4 text-amber-500" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{projects.length}</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Pending Studio allocation</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Talent Pool
              </p>
              <PenTool className="h-4 w-4 text-[#0453cd]" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{draughtsmen.length}</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Verified CAD practitioners</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Available Capacity
              </p>
              <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{availableCount}</p>
            <p className="text-[11px] text-emerald-700 font-mono mt-1">Ready for immediate dispatch</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                SLA Target
              </p>
              <BarChart3 className="h-4 w-4 text-purple-600" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">48h</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Standard review SLA</p>
          </div>
        </div>

        {error && (
          <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-3">
            <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
            <span className="flex-1">{error}</span>
            <Button variant="outline" size="sm" onClick={() => loadData(true)}>
              Retry
            </Button>
          </div>
        )}

        {/* ── Main Two-Column Workflow Bento ── */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* ── Left Column: Assignment Queue (7 cols) ── */}
          <div className="lg:col-span-7 space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
              <div>
                <h3 className="text-sm font-bold font-mono text-slate-900 flex items-center gap-2">
                  <FolderKanban className="h-4 w-4 text-[#0453cd]" />
                  <span>Pending Assignment Queue ({filteredQueue.length})</span>
                </h3>
                <p className="text-xs text-slate-500 font-sans mt-0.5">
                  Select a project brief to inspect requirements and assign an architect
                </p>
              </div>

              {/* Filters */}
              <div className="flex items-center gap-2 flex-wrap">
                <div className="relative">
                  <Search className="h-3.5 w-3.5 text-slate-400 absolute left-2.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    placeholder="Search queue…"
                    className="pl-8 pr-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd] w-36 sm:w-44"
                  />
                </div>
                <select
                  value={drawingTypeFilter}
                  onChange={(e) => setDrawingTypeFilter(e.target.value)}
                  className="px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                >
                  <option value="ALL">All Disciplines</option>
                  <option value="FLOOR_PLAN">Floor Plan</option>
                  <option value="STRUCTURAL">Structural</option>
                  <option value="MEP">MEP</option>
                  <option value="ELEVATION">Elevation</option>
                  <option value="SECTION">Section</option>
                </select>
              </div>
            </div>

            {loading ? (
              <Card className="p-16 text-center bg-white border-slate-200">
                <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent mx-auto mb-3" />
                <p className="text-xs font-mono text-slate-500">Querying Cloudflare D1 project queue…</p>
              </Card>
            ) : filteredQueue.length === 0 ? (
              <Card className="p-16 text-center bg-white border-slate-200">
                <CheckCircle2 className="h-10 w-10 text-emerald-500 mx-auto mb-3" />
                <p className="text-sm font-semibold text-slate-800">Queue is Clear</p>
                <p className="text-xs text-slate-500 font-mono mt-1">
                  {searchQuery || drawingTypeFilter !== 'ALL'
                    ? 'No projects match your search criteria.'
                    : 'All submitted projects have been allocated to draughtsmen.'}
                </p>
              </Card>
            ) : (
              <div className="space-y-3">
                {filteredQueue.map((proj) => {
                  const isSelected = selectedProject?.id === proj.id;
                  return (
                    <div
                      key={proj.id}
                      onClick={() => setSelectedProject(proj)}
                      className={`p-4 rounded-xl border transition-all cursor-pointer relative bg-white ${
                        isSelected
                          ? 'border-[#0453cd] ring-2 ring-[#0453cd]/20 shadow-md'
                          : 'border-slate-200 hover:border-slate-300 hover:shadow-xs'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-3">
                        <div className="space-y-1 min-w-0 flex-1">
                          <div className="flex items-center gap-2 flex-wrap">
                            <span className="text-[10px] font-mono font-bold bg-blue-50 text-[#0453cd] px-2 py-0.5 rounded border border-blue-200">
                              {proj.id}
                            </span>
                            <Badge status={proj.status} size="sm" />
                            <span className="text-[11px] font-mono text-slate-500">
                              {proj.drawing_type} · {proj.project_area} sq.ft
                            </span>
                          </div>
                          <h4 className="text-sm font-bold text-slate-900 truncate">
                            {proj.project_name}
                          </h4>
                          <p className="text-xs text-slate-500 truncate flex items-center gap-1 font-sans">
                            <Building className="h-3 w-3 text-slate-400 shrink-0" />
                            <span>{proj.project_address || 'Studio Blueprint Scope'}</span>
                          </p>
                        </div>

                        <div className="shrink-0 text-right flex flex-col items-end justify-between self-stretch">
                          <span className="text-[10px] font-mono text-slate-400 flex items-center gap-1">
                            <Clock className="h-3 w-3" />
                            {proj.created_at ? new Date(proj.created_at).toLocaleDateString() : 'Recent'}
                          </span>
                          <Link
                            href={`/projects/${proj.id}`}
                            onClick={(e) => e.stopPropagation()}
                            className="p-1 rounded hover:bg-slate-100 text-slate-400 hover:text-[#0453cd] transition-colors"
                            title="Inspect Project Dossier"
                          >
                            <ExternalLink className="h-3.5 w-3.5" />
                          </Link>
                        </div>
                      </div>

                      {/* Card Selection Footer */}
                      <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-[11px] font-mono">
                        <span className={isSelected ? 'text-[#0453cd] font-semibold' : 'text-slate-500'}>
                          {isSelected ? '● Target Project Selected' : '○ Click to select for dispatch'}
                        </span>
                        <span className="text-slate-400">
                          Waiting since {proj.submitted_at ? new Date(proj.submitted_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : 'submission'}
                        </span>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* ── Right Column: Draughtsman Dispatch Hub (5 cols) ── */}
          <div className="lg:col-span-5 space-y-4">
            <div className="bg-slate-900 text-white rounded-xl p-5 border border-slate-800 soft-elevation space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-[10px] font-mono uppercase tracking-widest text-blue-400 font-semibold">
                  DISPATCH CONTEXT
                </span>
                <span className="text-[10px] font-mono bg-blue-900/60 text-blue-200 px-2 py-0.5 rounded border border-blue-700/60">
                  {selectedProject ? 'TARGET ARMED' : 'NO PROJECT SELECTED'}
                </span>
              </div>

              {selectedProject ? (
                <div className="space-y-2">
                  <h4 className="text-base font-bold text-white tracking-tight truncate">
                    {selectedProject.project_name}
                  </h4>
                  <div className="grid grid-cols-2 gap-2 text-[11px] font-mono text-slate-300">
                    <div>
                      <span className="text-slate-400 block text-[9px]">DISCIPLINE</span>
                      <span>{selectedProject.drawing_type}</span>
                    </div>
                    <div>
                      <span className="text-slate-400 block text-[9px]">SURFACE AREA</span>
                      <span>{selectedProject.project_area} sq.ft</span>
                    </div>
                  </div>
                </div>
              ) : (
                <p className="text-xs text-slate-400 font-sans">
                  Select a project from the left queue to view and match eligible draughtsmen.
                </p>
              )}
            </div>

            {/* Draughtsman Talent Pool */}
            <Card className="bg-white border-slate-200 soft-elevation">
              <div className="px-5 py-3.5 border-b border-slate-100 bg-slate-50/60 flex items-center justify-between gap-3">
                <h4 className="text-xs font-bold font-mono uppercase tracking-wider text-slate-900 flex items-center gap-1.5">
                  <PenTool className="h-3.5 w-3.5 text-[#0453cd]" />
                  <span>Draughtsmen Pool ({filteredDraughtsmen.length})</span>
                </h4>
                <div className="relative w-36">
                  <Search className="h-3 w-3 text-slate-400 absolute left-2 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={draughtsmanSearch}
                    onChange={(e) => setDraughtsmanSearch(e.target.value)}
                    placeholder="Search talent…"
                    className="w-full pl-6 pr-2 py-1 bg-white border border-slate-200 rounded text-[11px] font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                  />
                </div>
              </div>

              <div className="divide-y divide-slate-100 max-h-[520px] overflow-y-auto">
                {filteredDraughtsmen.length === 0 ? (
                  <div className="p-8 text-center text-xs text-slate-500 font-mono">
                    No draughtsmen found.
                  </div>
                ) : (
                  filteredDraughtsmen.map((dm) => {
                    const currentLoad = draughtsmanWorkloadMap[dm.id] || 0;
                    const isAtCapacity = currentLoad >= MAX_DRAUGHTSMAN_CAPACITY;
                    const capacityPercent = Math.min(100, Math.round((currentLoad / MAX_DRAUGHTSMAN_CAPACITY) * 100));

                    return (
                      <div
                        key={dm.id}
                        className="p-4 hover:bg-slate-50/80 transition-colors space-y-2.5"
                      >
                        <div className="flex items-start justify-between gap-2">
                          <div className="min-w-0 flex-1">
                            <div className="flex items-center gap-2">
                              <p className="text-xs font-bold text-slate-900 truncate">{dm.name}</p>
                              {isAtCapacity ? (
                                <span className="text-[9px] font-mono font-bold bg-rose-50 text-rose-700 px-1.5 py-0.2 rounded border border-rose-200">
                                  FULL
                                </span>
                              ) : (
                                <span className="text-[9px] font-mono font-bold bg-emerald-50 text-emerald-700 px-1.5 py-0.2 rounded border border-emerald-200">
                                  AVAILABLE
                                </span>
                              )}
                            </div>
                            <p className="text-[10px] font-mono text-slate-500 truncate">{dm.email}</p>
                            {dm.qualification && (
                              <p className="text-[10px] text-slate-600 truncate mt-0.5">
                                Spec: {dm.qualification}
                              </p>
                            )}
                          </div>

                          <Button
                            variant={isAtCapacity ? 'outline' : 'primary'}
                            size="sm"
                            disabled={!selectedProject || isAtCapacity}
                            onClick={() => handleInitiateAssignment(dm)}
                            className="shrink-0 text-xs flex items-center gap-1"
                          >
                            <span>Assign</span>
                            <ArrowRight className="h-3 w-3" />
                          </Button>
                        </div>

                        {/* Workload Meter */}
                        <div className="space-y-1">
                          <div className="flex items-center justify-between text-[10px] font-mono text-slate-500">
                            <span>Active Workload</span>
                            <span className="font-semibold text-slate-800">
                              {currentLoad} / {MAX_DRAUGHTSMAN_CAPACITY} projects
                            </span>
                          </div>
                          <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                            <div
                              className={`h-1.5 rounded-full transition-all ${
                                isAtCapacity ? 'bg-rose-500' : currentLoad >= 2 ? 'bg-amber-500' : 'bg-[#0453cd]'
                              }`}
                              style={{ width: `${capacityPercent}%` }}
                            />
                          </div>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </Card>
          </div>
        </div>
      </div>

      {/* ── Confirmation Modal ── */}
      {confirmModalOpen && selectedProject && selectedDraughtsman && (
        <Modal
          isOpen={confirmModalOpen}
          onClose={() => !assigning && setConfirmModalOpen(false)}
          title="Confirm Project Assignment"
        >
          <div className="space-y-4">
            {assignSuccess && (
              <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-mono flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                <span>{assignSuccess}</span>
              </div>
            )}
            {assignError && (
              <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{assignError}</span>
              </div>
            )}

            <p className="text-xs text-slate-600 leading-relaxed font-sans">
              You are dispatching this architectural drawing package to the draughtsman below. The project status will advance to{' '}
              <strong className="text-slate-900 font-mono">WAITING_ACCEPTANCE</strong> and an activity log entry will be permanently recorded.
            </p>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 p-4 rounded-xl bg-slate-50 border border-slate-200 text-xs">
              <div className="space-y-1">
                <span className="text-[10px] font-mono text-slate-400 uppercase tracking-wider block">
                  Project Brief
                </span>
                <p className="font-bold text-slate-900">{selectedProject.project_name}</p>
                <p className="font-mono text-[11px] text-slate-500">{selectedProject.id}</p>
                <p className="text-slate-600 text-[11px]">{selectedProject.drawing_type} ({selectedProject.project_area} sq.ft)</p>
              </div>

              <div className="space-y-1 sm:border-l sm:border-slate-200 sm:pl-3">
                <span className="text-[10px] font-mono text-slate-400 uppercase tracking-wider block">
                  Assigned Draughtsman
                </span>
                <p className="font-bold text-slate-900">{selectedDraughtsman.name}</p>
                <p className="font-mono text-[11px] text-slate-500">{selectedDraughtsman.email}</p>
                <p className="text-slate-600 text-[11px]">{selectedDraughtsman.qualification || 'CAD Specialist'}</p>
              </div>
            </div>

            <div className="pt-3 border-t border-slate-200 flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={assigning}
                onClick={() => setConfirmModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                disabled={assigning || !!assignSuccess}
                onClick={handleConfirmAssignment}
                className="flex items-center gap-1.5"
              >
                {assigning ? (
                  <>
                    <span className="h-3 w-3 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Dispatching…</span>
                  </>
                ) : (
                  <>
                    <Check className="h-3.5 w-3.5" />
                    <span>Authorize & Dispatch</span>
                  </>
                )}
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </AdminShell>
  );
}

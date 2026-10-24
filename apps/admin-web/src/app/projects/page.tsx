'use client';

import React, { useState, useEffect, useMemo, Suspense } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { EmptyState } from '@/components/ui/EmptyState';
import { AssignModal } from '@/components/projects/AssignModal';
import { RejectModal } from '@/components/projects/RejectModal';
import { CancelModal } from '@/components/projects/CancelModal';
import { NewProjectModal } from '@/components/projects/NewProjectModal';
import { adminApi } from '@/lib/api';
import { Project, ProjectStatus } from '@/lib/types';
import {
  Search,
  CheckCircle,
  XCircle,
  UserPlus,
  RefreshCw,
  ExternalLink,
  AlertCircle,
  Ban,
  Building2,
  Calendar,
  PlusCircle,
  FolderKanban,
  FileText,
  User,
} from 'lucide-react';

const STATUS_FILTERS: { label: string; value: string }[] = [
  { label: 'All Projects', value: 'ALL' },
  { label: 'Needs Review', value: 'SUBMITTED' },
  { label: 'Needs Draughtsman', value: 'WAITING_ASSIGNMENT' },
  { label: 'Awaiting Accept', value: 'WAITING_ACCEPTANCE' },
  { label: 'In Progress', value: 'IN_PROGRESS' },
  { label: 'Engineer Review', value: 'UNDER_CLIENT_REVIEW' },
  { label: 'Completed', value: 'COMPLETED' },
  { label: 'Cancelled', value: 'CANCELLED' },
  { label: 'Drafts', value: 'DRAFT' },
];

function ProjectsContent() {
  const searchParams = useSearchParams();
  const initialStatus = searchParams.get('status') || 'ALL';

  const [projects, setProjects] = useState<Project[]>([]);
  const [selectedStatus, setSelectedStatus] = useState<string>(initialStatus);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Modal States
  const [assignTarget, setAssignTarget] = useState<{ project: Project; isReassign: boolean } | null>(null);
  const [rejectTarget, setRejectTarget] = useState<Project | null>(null);
  const [cancelTarget, setCancelTarget] = useState<Project | null>(null);
  const [isNewProjectModalOpen, setIsNewProjectModalOpen] = useState<boolean>(false);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  const loadProjects = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getProjects();
      setProjects(data || []);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load projects');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadProjects();
  }, []);

  const handleQuickApprove = async (projectId: string) => {
    setActionLoadingId(projectId);
    setError(null);
    try {
      await adminApi.approveProject(projectId);
      await loadProjects(true);
    } catch (err: any) {
      setError(err.message || 'Failed to approve project');
    } finally {
      setActionLoadingId(null);
    }
  };

  const filteredProjects = useMemo(() => {
    return projects.filter((p) => {
      // Status filter
      if (selectedStatus !== 'ALL' && p.status !== selectedStatus) {
        return false;
      }
      // Search filter
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase();
        const nameMatch = (p.project_name || '').toLowerCase().includes(query);
        const addressMatch = (p.project_address || '').toLowerCase().includes(query);
        const typeMatch = (p.drawing_type || '').toLowerCase().includes(query);
        const draughtsmanMatch = (p.draughtsman_name || '').toLowerCase().includes(query);
        const idMatch = p.id.toLowerCase().includes(query);
        return nameMatch || addressMatch || typeMatch || draughtsmanMatch || idMatch;
      }
      return true;
    });
  }, [projects, selectedStatus, searchQuery]);

  return (
    <AdminShell
      title="Project Governance & Pipeline"
      subtitle="Complete project catalog with lifecycle approval, assignment actions & CAD repository"
      onRefresh={() => loadProjects(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-50 border border-rose-200 text-sm text-rose-800 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
          <span className="font-medium">{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadProjects(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {/* Control Toolbar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 mb-6">
        {/* Search Input */}
        <div className="relative w-full md:max-w-md flex-1">
          <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search project name, address, drawing type, or ID..."
            className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-white border border-slate-300/80 text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-4 focus:ring-blue-500/10 focus:border-[#0453cd] transition-all shadow-xs"
          />
        </div>

        {/* Action Button & Metric */}
        <div className="flex items-center flex-wrap gap-2.5">
          <button
            onClick={() => setIsNewProjectModalOpen(true)}
            className="inline-flex items-center gap-2 px-3.5 sm:px-4 py-2.5 rounded-xl bg-[#0d1c32] hover:bg-[#15294a] text-white text-xs font-mono font-semibold transition-all shadow-sm cursor-pointer active:scale-[0.98]"
          >
            <PlusCircle className="h-4 w-4 text-emerald-400" />
            <span>INITIATE PROJECT</span>
          </button>

          <div className="text-xs font-mono text-slate-500 bg-white border border-slate-200 px-3 py-2 rounded-xl shadow-xs whitespace-nowrap">
            <span>SHOWING: </span>
            <span className="font-bold text-slate-900">{filteredProjects.length}</span>
            <span className="text-slate-400"> / </span>
            <span className="font-bold text-slate-900">{projects.length}</span>
          </div>
        </div>
      </div>

      {/* Status Filter Tabs */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-3 mb-6 scrollbar-none border-b border-slate-200 w-full max-w-full">
        {STATUS_FILTERS.map((tab) => {
          const isSelected = selectedStatus === tab.value;
          const count =
            tab.value === 'ALL'
              ? projects.length
              : projects.filter((p) => p.status === tab.value).length;

          return (
            <button
              key={tab.value}
              onClick={() => setSelectedStatus(tab.value)}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-mono font-semibold whitespace-nowrap transition-all cursor-pointer ${
                isSelected
                  ? 'bg-[#0d1c32] text-white shadow-xs'
                  : 'bg-white text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-slate-200'
              }`}
            >
              <span>{tab.label}</span>
              <span
                className={`px-1.5 py-0.5 rounded-full text-[10px] ${
                  isSelected ? 'bg-white/20 text-white' : 'bg-slate-100 text-slate-600'
                }`}
              >
                {count}
              </span>
            </button>
          );
        })}
      </div>

      {/* Projects Table */}
      {loading ? (
        <div className="flex flex-col items-center justify-center p-24 bg-white border border-slate-200 rounded-2xl soft-elevation my-6">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs font-mono font-medium text-slate-500 mt-3 uppercase tracking-wider">
            Loading project catalog from Cloudflare D1...
          </p>
        </div>
      ) : filteredProjects.length === 0 ? (
        <EmptyState
          title={searchQuery ? 'No Projects Matched Search' : `No Projects in "${selectedStatus}" State`}
          description={
            searchQuery
              ? `No projects matching "${searchQuery}" found in the repository.`
              : 'Initialize your first architectural package or clear filters to view active projects.'
          }
          primaryAction={{
            label: 'Initiate Project Brief',
            onClick: () => setIsNewProjectModalOpen(true),
          }}
          secondaryAction={
            searchQuery || selectedStatus !== 'ALL'
              ? {
                  label: 'Clear Filters',
                  onClick: () => {
                    setSearchQuery('');
                    setSelectedStatus('ALL');
                  },
                }
              : undefined
          }
        />
      ) : (
        <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden soft-elevation shadow-xs">
          <div className="overflow-x-auto w-full max-w-full">
            <table className="w-full text-left text-xs min-w-[780px]">
              <thead className="bg-slate-50/80 border-b border-slate-200 text-slate-500 font-mono font-semibold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Project Details</th>
                  <th className="px-5 py-3.5">Discipline & Area</th>
                  <th className="px-5 py-3.5">Lifecycle State</th>
                  <th className="px-5 py-3.5">Draughtsman</th>
                  <th className="px-5 py-3.5">Registered</th>
                  <th className="px-5 py-3.5 text-right whitespace-nowrap">Administrative Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredProjects.map((p) => {
                  const isActionLoading = actionLoadingId === p.id;

                  return (
                    <tr
                      key={p.id}
                      className="hover:bg-slate-50/60 transition-colors group"
                    >
                      {/* Project Details */}
                      <td className="px-5 py-4">
                        <Link
                          href={`/projects/${p.id}`}
                          className="font-bold text-slate-900 hover:text-[#0453cd] transition-colors flex items-center gap-1.5"
                        >
                          <span>{p.project_name || 'Untitled Project'}</span>
                          <ExternalLink className="h-3 w-3 opacity-0 group-hover:opacity-100 transition-opacity text-slate-400" />
                        </Link>
                        <p className="text-slate-500 mt-0.5 truncate max-w-xs">{p.project_address}</p>
                        <p className="text-[10px] font-mono text-slate-400 mt-0.5">ID: {p.id.substring(0, 8)}</p>
                      </td>

                      {/* Type & Area */}
                      <td className="px-5 py-4">
                        <span className="font-semibold text-slate-800 font-mono block">
                          {p.drawing_type || 'Architectural'}
                        </span>
                        <span className="text-slate-500 font-mono text-[11px]">
                          {p.project_area ? `${p.project_area.toLocaleString()} sq.ft` : 'Standard Scope'}
                        </span>
                      </td>

                      {/* Lifecycle State */}
                      <td className="px-5 py-4">
                        <Badge status={p.status} />
                      </td>

                      {/* Draughtsman */}
                      <td className="px-5 py-4">
                        {p.draughtsman_id ? (
                          <div className="flex items-center gap-2">
                            <div className="h-7 w-7 rounded-lg bg-blue-50 border border-blue-200 text-[#0453cd] font-mono font-bold flex items-center justify-center text-xs">
                              {(p.draughtsman_name || 'D').charAt(0).toUpperCase()}
                            </div>
                            <div>
                              <span className="font-semibold text-slate-800 text-xs block">
                                {p.draughtsman_name || 'Assigned Draughtsman'}
                              </span>
                              <span className="text-[10px] font-mono text-slate-400">ID: {p.draughtsman_id.substring(0, 6)}</span>
                            </div>
                          </div>
                        ) : (
                          <span className="text-slate-400 font-mono text-xs italic">Unassigned</span>
                        )}
                      </td>

                      {/* Registered Date */}
                      <td className="px-5 py-4 font-mono text-slate-500">
                        {p.created_at ? new Date(p.created_at).toLocaleDateString() : 'N/A'}
                      </td>

                      {/* Administrative Actions */}
                      <td className="px-5 py-4 text-right whitespace-nowrap">
                        <div className="flex items-center justify-end gap-1.5 flex-wrap">
                          {/* 1. Quick Approve button (for SUBMITTED) */}
                          {p.status === 'SUBMITTED' && (
                            <button
                              onClick={() => handleQuickApprove(p.id)}
                              disabled={isActionLoading}
                              title="Approve submission & move to assignment queue"
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-200 text-xs font-mono font-semibold transition-all cursor-pointer disabled:opacity-50"
                            >
                              {isActionLoading ? (
                                <RefreshCw className="h-3 w-3 animate-spin" />
                              ) : (
                                <CheckCircle className="h-3 w-3" />
                              )}
                              <span>Approve</span>
                            </button>
                          )}

                          {/* 2. Assign Draughtsman button (for WAITING_ASSIGNMENT) */}
                          {p.status === 'WAITING_ASSIGNMENT' && (
                            <button
                              onClick={() => setAssignTarget({ project: p, isReassign: false })}
                              title="Assign draughtsman to this project"
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-[#0d1c32] text-white hover:bg-[#15294a] text-xs font-mono font-semibold transition-all shadow-xs cursor-pointer"
                            >
                              <UserPlus className="h-3 w-3 text-blue-300" />
                              <span>Assign</span>
                            </button>
                          )}

                          {/* 3. Reassign Draughtsman (for WAITING_ACCEPTANCE / IN_PROGRESS) */}
                          {(p.status === 'WAITING_ACCEPTANCE' || p.status === 'IN_PROGRESS') && (
                            <button
                              onClick={() => setAssignTarget({ project: p, isReassign: true })}
                              title="Reassign to a different draughtsman"
                              className="inline-flex items-center gap-1 px-2.5 py-1.5 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200 text-xs font-mono transition-all cursor-pointer"
                            >
                              <UserPlus className="h-3 w-3 text-slate-500" />
                              <span>Reassign</span>
                            </button>
                          )}

                          {/* 4. Reject button (only for SUBMITTED) */}
                          {p.status === 'SUBMITTED' && (
                            <button
                              onClick={() => setRejectTarget(p)}
                              title="Reject submission"
                              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 border border-transparent hover:border-rose-200 transition-colors cursor-pointer"
                            >
                              <XCircle className="h-4 w-4" />
                            </button>
                          )}

                          {/* 5. Cancel button (for non-completed, non-cancelled) */}
                          {p.status !== 'COMPLETED' && p.status !== 'CANCELLED' && (
                            <button
                              onClick={() => setCancelTarget(p)}
                              title="Cancel project"
                              className="p-1.5 rounded-lg text-slate-400 hover:text-rose-600 hover:bg-rose-50 border border-transparent hover:border-rose-200 transition-colors cursor-pointer"
                            >
                              <Ban className="h-4 w-4" />
                            </button>
                          )}

                          {/* 6. View Details link */}
                          <Link
                            href={`/projects/${p.id}`}
                            className="p-1.5 text-slate-400 hover:text-[#0453cd] hover:bg-blue-50 rounded-lg transition-colors"
                            title="Open project details workspace"
                          >
                            <ExternalLink className="h-4 w-4" />
                          </Link>
                        </div>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Action Modals */}
      {assignTarget && (
        <AssignModal
          isOpen={true}
          onClose={() => setAssignTarget(null)}
          projectId={assignTarget.project.id}
          projectName={assignTarget.project.project_name || 'Project'}
          isReassign={assignTarget.isReassign}
          onSuccess={() => loadProjects(true)}
        />
      )}

      {rejectTarget && (
        <RejectModal
          isOpen={true}
          onClose={() => setRejectTarget(null)}
          projectId={rejectTarget.id}
          projectName={rejectTarget.project_name || 'Project'}
          onSuccess={() => loadProjects(true)}
        />
      )}

      {cancelTarget && (
        <CancelModal
          isOpen={true}
          onClose={() => setCancelTarget(null)}
          projectId={cancelTarget.id}
          projectName={cancelTarget.project_name || 'Project'}
          onSuccess={() => loadProjects(true)}
        />
      )}

      <NewProjectModal
        isOpen={isNewProjectModalOpen}
        onClose={() => setIsNewProjectModalOpen(false)}
        onSuccess={() => loadProjects(true)}
      />
    </AdminShell>
  );
}

export default function ProjectsPage() {
  return (
    <Suspense fallback={
      <div className="flex flex-col items-center justify-center p-24">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
      </div>
    }>
      <ProjectsContent />
    </Suspense>
  );
}

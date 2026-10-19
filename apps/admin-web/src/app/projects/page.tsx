'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { useSearchParams } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { AssignModal } from '@/components/projects/AssignModal';
import { RejectModal } from '@/components/projects/RejectModal';
import { CancelModal } from '@/components/projects/CancelModal';
import { adminApi } from '@/lib/api';
import { Project, ProjectStatus } from '@/lib/types';
import {
  Search,
  Filter,
  CheckCircle,
  XCircle,
  UserPlus,
  RefreshCw,
  ExternalLink,
  AlertCircle,
  Ban,
  Building2,
  Calendar,
} from 'lucide-react';

const STATUS_FILTERS: { label: string; value: string }[] = [
  { label: 'All Projects', value: 'ALL' },
  { label: 'Needs Review', value: 'SUBMITTED' },
  { label: 'Needs Draughtsman', value: 'WAITING_ASSIGNMENT' },
  { label: 'Awaiting Accept', value: 'WAITING_ACCEPTANCE' },
  { label: 'In Progress', value: 'IN_PROGRESS' },
  { label: 'Client Review', value: 'UNDER_CLIENT_REVIEW' },
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
      subtitle="Complete project catalog with lifecycle approval & assignment actions"
      onRefresh={() => loadProjects(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-sm text-rose-300 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-400 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadProjects(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {/* Control Toolbar */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 mb-6">
        {/* Search */}
        <div className="relative flex-1 max-w-md">
          <Search className="h-4 w-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by project name, address, drawing type, or ID..."
            className="w-full pl-10 pr-4 py-2 rounded-xl bg-slate-900 border border-slate-700/80 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
          />
        </div>

        {/* Status Count Summary */}
        <div className="text-xs text-slate-400 flex items-center gap-2">
          <span>Showing</span>
          <span className="font-bold text-slate-200">{filteredProjects.length}</span>
          <span>of</span>
          <span className="font-bold text-slate-200">{projects.length}</span>
          <span>total projects</span>
        </div>
      </div>

      {/* Status Filter Tabs */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-3 mb-6 scrollbar-none border-b border-slate-800">
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
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
                isSelected
                  ? 'bg-blue-600 text-white shadow-sm'
                  : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 border border-slate-800'
              }`}
            >
              <span>{tab.label}</span>
              <span
                className={`px-1.5 py-0.5 rounded-full text-[10px] ${
                  isSelected ? 'bg-blue-800/80 text-blue-100' : 'bg-slate-800 text-slate-400'
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
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
          <p className="text-xs text-slate-400 mt-3 font-medium">Loading project catalog...</p>
        </div>
      ) : filteredProjects.length === 0 ? (
        <Card className="text-center py-16">
          <Building2 className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <h3 className="text-sm font-semibold text-slate-300">No projects found</h3>
          <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
            {searchQuery
              ? `No projects matched "${searchQuery}". Try adjusting your search query.`
              : `No projects in "${selectedStatus}" status.`}
          </p>
          {(searchQuery || selectedStatus !== 'ALL') && (
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                setSearchQuery('');
                setSelectedStatus('ALL');
              }}
              className="mt-4"
            >
              Clear filters
            </Button>
          )}
        </Card>
      ) : (
        <div className="bg-[#0f172a] border border-slate-800 rounded-xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#0b1120] border-b border-slate-800 text-slate-400 font-semibold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Project Details</th>
                  <th className="px-5 py-3.5">Type & Area</th>
                  <th className="px-5 py-3.5">Lifecycle State</th>
                  <th className="px-5 py-3.5">Draughtsman</th>
                  <th className="px-5 py-3.5">Timeline</th>
                  <th className="px-5 py-3.5 text-right">Administrative Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/80">
                {filteredProjects.map((p) => {
                  const isActionLoading = actionLoadingId === p.id;

                  return (
                    <tr
                      key={p.id}
                      className="hover:bg-slate-800/30 transition-colors group"
                    >
                      {/* Project Details */}
                      <td className="px-5 py-4">
                        <Link
                          href={`/projects/${p.id}`}
                          className="font-semibold text-slate-100 hover:text-blue-400 transition-colors flex items-center gap-1.5"
                        >
                          <span>{p.project_name || 'Untitled Project'}</span>
                          <ExternalLink className="h-3 w-3 opacity-0 group-hover:opacity-100 transition-opacity" />
                        </Link>
                        <p className="text-slate-400 mt-0.5 truncate max-w-xs">{p.project_address}</p>
                        <p className="text-[10px] font-mono text-slate-500 mt-0.5">ID: {p.id.substring(0, 8)}</p>
                      </td>

                      {/* Type & Area */}
                      <td className="px-5 py-4">
                        <p className="text-slate-200 font-medium">{p.drawing_type || 'Architectural'}</p>
                        <p className="text-slate-400 mt-0.5">{p.project_area ? `${p.project_area} sq.ft` : 'N/A'}</p>
                      </td>

                      {/* Lifecycle Status */}
                      <td className="px-5 py-4">
                        <Badge status={p.status} />
                        {p.correction_round > 0 && (
                          <span className="block text-[10px] text-teal-400 mt-1 font-medium">
                            Round {p.correction_round}/3
                          </span>
                        )}
                      </td>

                      {/* Draughtsman */}
                      <td className="px-5 py-4">
                        {p.draughtsman_name ? (
                          <div>
                            <p className="text-slate-200 font-medium">{p.draughtsman_name}</p>
                            <span className="text-[10px] text-slate-400 font-mono">Assigned</span>
                          </div>
                        ) : (
                          <span className="text-slate-500 italic text-[11px]">Unassigned</span>
                        )}
                      </td>

                      {/* Timeline */}
                      <td className="px-5 py-4 text-slate-400">
                        <div className="flex items-center gap-1 text-[11px]">
                          <Calendar className="h-3 w-3 text-slate-500" />
                          <span>{new Date(p.created_at).toLocaleDateString()}</span>
                        </div>
                        {p.submitted_at && (
                          <span className="text-[10px] text-slate-500 block mt-0.5">
                            Sub: {new Date(p.submitted_at).toLocaleDateString()}
                          </span>
                        )}
                      </td>

                      {/* Actions */}
                      <td className="px-5 py-4 text-right">
                        <div className="flex items-center justify-end gap-1.5">
                          {/* SUBMITTED State: Approve or Reject */}
                          {p.status === 'SUBMITTED' && (
                            <>
                              <Button
                                variant="success"
                                size="sm"
                                loading={isActionLoading}
                                onClick={() => handleQuickApprove(p.id)}
                                title="Approve Submission"
                                icon={<CheckCircle className="h-3.5 w-3.5" />}
                              >
                                Approve
                              </Button>
                              <Button
                                variant="danger"
                                size="sm"
                                onClick={() => setRejectTarget(p)}
                                title="Reject Submission"
                                icon={<XCircle className="h-3.5 w-3.5" />}
                              >
                                Reject
                              </Button>
                            </>
                          )}

                          {/* WAITING_ASSIGNMENT State: Assign Draughtsman */}
                          {p.status === 'WAITING_ASSIGNMENT' && (
                            <Button
                              variant="primary"
                              size="sm"
                              onClick={() => setAssignTarget({ project: p, isReassign: false })}
                              icon={<UserPlus className="h-3.5 w-3.5" />}
                            >
                              Assign
                            </Button>
                          )}

                          {/* IN_PROGRESS or WAITING_ACCEPTANCE: Reassign */}
                          {(p.status === 'WAITING_ACCEPTANCE' || p.status === 'IN_PROGRESS') && (
                            <Button
                              variant="outline"
                              size="sm"
                              onClick={() => setAssignTarget({ project: p, isReassign: true })}
                            >
                              Reassign
                            </Button>
                          )}

                          {/* Active projects can be cancelled */}
                          {p.status !== 'COMPLETED' && p.status !== 'CANCELLED' && p.status !== 'DRAFT' && (
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setCancelTarget(p)}
                              title="Cancel Project"
                              className="text-rose-400 hover:text-rose-300 hover:bg-rose-500/10"
                            >
                              <Ban className="h-3.5 w-3.5" />
                            </Button>
                          )}

                          {/* View details */}
                          <Link href={`/projects/${p.id}`}>
                            <Button variant="outline" size="sm">
                              Details
                            </Button>
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
          projectName={assignTarget.project.project_name}
          isReassign={assignTarget.isReassign}
          onSuccess={() => loadProjects(true)}
        />
      )}

      {rejectTarget && (
        <RejectModal
          isOpen={true}
          onClose={() => setRejectTarget(null)}
          projectId={rejectTarget.id}
          projectName={rejectTarget.project_name}
          onSuccess={() => loadProjects(true)}
        />
      )}

      {cancelTarget && (
        <CancelModal
          isOpen={true}
          onClose={() => setCancelTarget(null)}
          projectId={cancelTarget.id}
          projectName={cancelTarget.project_name}
          onSuccess={() => loadProjects(true)}
        />
      )}
    </AdminShell>
  );
}

export default function ProjectsPage() {
  return (
    <React.Suspense
      fallback={
        <div className="min-h-screen flex items-center justify-center bg-[#090d16]">
          <div className="flex flex-col items-center gap-3">
            <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
            <p className="text-xs text-slate-400 font-medium">Loading project catalog...</p>
          </div>
        </div>
      }
    >
      <ProjectsContent />
    </React.Suspense>
  );
}

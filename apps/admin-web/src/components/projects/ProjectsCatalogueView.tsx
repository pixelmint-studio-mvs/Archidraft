'use client';

import React, { useState, useEffect, useMemo, useRef } from 'react';
import Link from 'next/link';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { EmptyState } from '@/components/ui/EmptyState';
import { AssignModal } from '@/components/projects/AssignModal';
import { RejectModal } from '@/components/projects/RejectModal';
import { CancelModal } from '@/components/projects/CancelModal';
import { NewProjectModal } from '@/components/projects/NewProjectModal';
import { RemoveProjectModal } from '@/components/projects/RemoveProjectModal';
import { adminApi } from '@/lib/api';
import { formatDate, formatTime } from '@/lib/dateUtils';
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
  FolderKanban,
  FileText,
  User,
  Trash2,
  MoreHorizontal,
  Eye,
  Download,
  Activity,
  Clock,
  FileCheck,
} from 'lucide-react';

export const STATUS_FILTERS: { label: string; value: string }[] = [
  { label: 'All Projects', value: 'ALL' },
  { label: 'Needs Review', value: 'SUBMITTED' },
  { label: 'Needs Draughtsman', value: 'WAITING_ASSIGNMENT' },
  { label: 'Awaiting Accept', value: 'WAITING_ACCEPTANCE' },
  { label: 'In Progress', value: 'IN_PROGRESS' },
  { label: 'Studio Review', value: 'UNDER_ADMIN_REVIEW' },
  { label: 'Engineer Review', value: 'UNDER_CLIENT_REVIEW' },
  { label: 'Completed', value: 'COMPLETED' },
  { label: 'Cancelled', value: 'CANCELLED' },
  { label: 'Drafts', value: 'DRAFT' },
];

// ── Cancellation Details Modal ───────────────────────────────────────────────

interface CancellationModalProps {
  isOpen: boolean;
  onClose: () => void;
  project: Project | null;
}

function CancellationDetailsModal({ isOpen, onClose, project }: CancellationModalProps) {
  if (!project) return null;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Project Cancellation Dossier"
      description={`Lifecycle Audit for ${project.project_name || 'Project'} • ID: ${project.id}`}
      maxWidth="lg"
    >
      <div className="space-y-4 py-1">
        {/* State Banner */}
        <div className="p-3.5 bg-rose-50 border border-rose-200/80 rounded-xl flex items-start gap-3">
          <AlertCircle className="h-5 w-5 text-rose-600 shrink-0 mt-0.5" />
          <div className="space-y-1">
            <h4 className="text-xs font-mono font-bold text-rose-900 uppercase tracking-wider">
              Project Lifecycle State: {project.status}
            </h4>
            <p className="text-xs font-mono text-rose-700">
              {project.rejection_reason
                ? project.rejection_reason
                : 'Project drafting terminated and marked cancelled by administrator.'}
            </p>
          </div>
        </div>

        {/* Project Metadata Details */}
        <div className="grid grid-cols-2 gap-3 text-xs font-mono bg-slate-50 p-4 rounded-xl border border-slate-200">
          <div>
            <span className="text-[10px] uppercase tracking-wider text-slate-400 block font-semibold">Submitting Engineer</span>
            <span className="text-slate-800 font-medium truncate block mt-0.5">
              {project.client_name || project.client_email || 'Structural Engineer'}
            </span>
          </div>
          <div>
            <span className="text-[10px] uppercase tracking-wider text-slate-400 block font-semibold">Assigned Draughtsman</span>
            <span className="text-slate-800 font-medium truncate block mt-0.5">
              {project.draughtsman_name || 'Unassigned / Released'}
            </span>
          </div>
          <div>
            <span className="text-[10px] uppercase tracking-wider text-slate-400 block font-semibold">Discipline</span>
            <span className="text-slate-800 font-medium mt-0.5 block">
              {project.drawing_type || 'Architectural / Structural'}
            </span>
          </div>
          <div>
            <span className="text-[10px] uppercase tracking-wider text-slate-400 block font-semibold">Registered Date</span>
            <span className="text-slate-800 font-medium mt-0.5 block">
              {formatDate(project.created_at)}
            </span>
          </div>
          {project.cancelled_at && (
            <div className="col-span-2">
              <span className="text-[10px] uppercase tracking-wider text-slate-400 block font-semibold">Cancelled Timestamp</span>
              <span className="text-slate-800 font-medium mt-0.5 block">
                {formatDate(project.cancelled_at)}
              </span>
            </div>
          )}
        </div>

        {/* Footer actions */}
        <div className="flex items-center justify-between pt-2">
          <Link
            href={`/projects/${project.id}`}
            className="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-mono text-[#0453cd] hover:bg-blue-50 border border-blue-200 rounded-lg transition-colors"
          >
            <ExternalLink className="h-3.5 w-3.5" />
            <span>Open Complete Project Workspace</span>
          </Link>
          <Button variant="outline" size="sm" onClick={onClose} className="font-mono text-xs">
            Dismiss
          </Button>
        </div>
      </div>
    </Modal>
  );
}

// ── Dropdown Action Menu ─────────────────────────────────────────────────────

interface ActionDropdownProps {
  project: Project;
  isOpen: boolean;
  onToggle: (e: React.MouseEvent) => void;
  onClose: () => void;
  onAssign: () => void;
  onReject: () => void;
  onCancel: () => void;
  onRemove: () => void;
}

function ActionDropdown({
  project,
  isOpen,
  onToggle,
  onClose,
  onAssign,
  onReject,
  onCancel,
  onRemove,
}: ActionDropdownProps) {
  const p = project;
  const canReassign =
    p.status === 'WAITING_ACCEPTANCE' ||
    p.status === 'IN_PROGRESS' ||
    p.status === 'UNDER_ADMIN_REVIEW' ||
    p.status === 'UNDER_CLIENT_REVIEW' ||
    p.status === 'UNDER_ENGINEER_REVIEW';
  const canReject = p.status === 'SUBMITTED';
  const canCancel = p.status !== 'COMPLETED' && p.status !== 'CANCELLED';

  return (
    <div className="relative inline-block text-left">
      <button
        type="button"
        onClick={onToggle}
        title="More administrative actions"
        className={`p-1.5 rounded-lg border transition-all cursor-pointer ${
          isOpen
            ? 'bg-slate-200 text-slate-900 border-slate-300'
            : 'text-slate-400 hover:text-slate-700 hover:bg-slate-100 border-transparent hover:border-slate-200'
        }`}
      >
        <MoreHorizontal className="h-4 w-4" />
      </button>

      {isOpen && (
        <div
          onClick={(e) => e.stopPropagation()}
          className="absolute right-0 top-full mt-1.5 w-52 bg-white rounded-xl shadow-xl border border-slate-200 py-1.5 z-50 text-left font-mono text-xs divide-y divide-slate-100 animate-in fade-in zoom-in-95 duration-100"
        >
          <div className="py-1">
            <Link
              href={`/projects/${p.id}`}
              onClick={onClose}
              className="flex items-center gap-2 px-3.5 py-2 text-slate-700 hover:bg-slate-50 transition-colors"
            >
              <Eye className="h-3.5 w-3.5 text-slate-400" />
              <span>View Project Details</span>
            </Link>
            <Link
              href="/activity"
              onClick={onClose}
              className="flex items-center gap-2 px-3.5 py-2 text-slate-700 hover:bg-slate-50 transition-colors"
            >
              <Activity className="h-3.5 w-3.5 text-slate-400" />
              <span>View Activity History</span>
            </Link>
          </div>

          {(canReassign || canReject || canCancel) && (
            <div className="py-1">
              {canReassign && (
                <button
                  type="button"
                  onClick={() => {
                    onClose();
                    onAssign();
                  }}
                  className="w-full flex items-center gap-2 px-3.5 py-2 text-amber-700 hover:bg-amber-50 transition-colors text-left cursor-pointer"
                >
                  <UserPlus className="h-3.5 w-3.5 text-amber-500" />
                  <span>Reassign Draughtsman</span>
                </button>
              )}
              {canReject && (
                <button
                  type="button"
                  onClick={() => {
                    onClose();
                    onReject();
                  }}
                  className="w-full flex items-center gap-2 px-3.5 py-2 text-rose-600 hover:bg-rose-50 transition-colors text-left cursor-pointer"
                >
                  <XCircle className="h-3.5 w-3.5 text-rose-500" />
                  <span>Reject Submission</span>
                </button>
              )}
              {canCancel && (
                <button
                  type="button"
                  onClick={() => {
                    onClose();
                    onCancel();
                  }}
                  className="w-full flex items-center gap-2 px-3.5 py-2 text-rose-600 hover:bg-rose-50 transition-colors text-left cursor-pointer"
                >
                  <Ban className="h-3.5 w-3.5 text-rose-500" />
                  <span>Cancel Project</span>
                </button>
              )}
            </div>
          )}

          <div className="py-1">
            <button
              type="button"
              onClick={() => {
                onClose();
                onRemove();
              }}
              className="w-full flex items-center gap-2 px-3.5 py-2 text-rose-700 hover:bg-rose-50 transition-colors text-left cursor-pointer"
            >
              <Trash2 className="h-3.5 w-3.5 text-rose-600" />
              <span>Remove Project</span>
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Primary Contextual Button Component ──────────────────────────────────────

interface PrimaryActionProps {
  project: Project;
  isActionLoading: boolean;
  onApprove: (id: string) => void;
  onAssign: (p: Project, isReassign: boolean) => void;
  onShowCancellation: (p: Project) => void;
}

function PrimaryActionButton({
  project,
  isActionLoading,
  onApprove,
  onAssign,
  onShowCancellation,
}: PrimaryActionProps) {
  const p = project;

  switch (p.status) {
    case 'SUBMITTED':
      return (
        <button
          onClick={() => onApprove(p.id)}
          disabled={isActionLoading}
          title="Approve submission & move to assignment queue"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-50 text-emerald-700 hover:bg-emerald-100 border border-emerald-300 text-xs font-mono font-semibold transition-all cursor-pointer disabled:opacity-50 shadow-2xs"
        >
          {isActionLoading ? (
            <RefreshCw className="h-3.5 w-3.5 animate-spin" />
          ) : (
            <CheckCircle className="h-3.5 w-3.5 text-emerald-600" />
          )}
          <span>Approve & Prepare Assignment</span>
        </button>
      );

    case 'WAITING_ASSIGNMENT':
      return (
        <button
          onClick={() => onAssign(p, false)}
          title="Assign draughtsman to this project"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#0d1c32] text-white hover:bg-[#15294a] text-xs font-mono font-semibold transition-all shadow-xs cursor-pointer"
        >
          <UserPlus className="h-3.5 w-3.5 text-blue-300" />
          <span>Assign Draughtsman</span>
        </button>
      );

    case 'WAITING_ACCEPTANCE':
      return (
        <button
          onClick={() => onAssign(p, true)}
          title="Reassign to a different draughtsman"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-amber-50 text-amber-800 hover:bg-amber-100 border border-amber-300 text-xs font-mono font-semibold transition-all shadow-2xs cursor-pointer"
        >
          <UserPlus className="h-3.5 w-3.5 text-amber-600" />
          <span>Reassign</span>
        </button>
      );

    case 'IN_PROGRESS':
      return (
        <Link
          href={`/projects/${p.id}`}
          title="Inspect live drawing workspace"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-50 text-[#0453cd] hover:bg-blue-100 border border-blue-200 text-xs font-mono font-semibold transition-all shadow-2xs"
        >
          <Eye className="h-3.5 w-3.5 text-[#0453cd]" />
          <span>View Workspace</span>
        </Link>
      );

    case 'UNDER_ADMIN_REVIEW':
      return (
        <Link
          href={`/projects/${p.id}`}
          title="Review submitted drawing and decide approval"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-purple-50 text-purple-700 hover:bg-purple-100 border border-purple-300 text-xs font-mono font-semibold transition-all shadow-2xs"
        >
          <FileCheck className="h-3.5 w-3.5 text-purple-600" />
          <span>Review Drawing</span>
        </Link>
      );

    case 'UNDER_CLIENT_REVIEW':
    case 'UNDER_ENGINEER_REVIEW':
      return (
        <Link
          href={`/projects/${p.id}`}
          title="View engineer review status"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-indigo-50 text-indigo-700 hover:bg-indigo-100 border border-indigo-300 text-xs font-mono font-semibold transition-all shadow-2xs"
        >
          <Clock className="h-3.5 w-3.5 text-indigo-600" />
          <span>View Review Status</span>
        </Link>
      );

    case 'COMPLETED':
      return (
        <Link
          href={`/projects/${p.id}`}
          title="Download approved drawings and deliverables"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-50 text-emerald-800 hover:bg-emerald-100 border border-emerald-300 text-xs font-mono font-semibold transition-all shadow-2xs"
        >
          <Download className="h-3.5 w-3.5 text-emerald-600" />
          <span>Download Approved Package</span>
        </Link>
      );

    case 'CANCELLED':
      return (
        <button
          onClick={() => onShowCancellation(p)}
          title="View cancellation rationale and timeline"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-rose-50 text-rose-700 hover:bg-rose-100 border border-rose-200 text-xs font-mono font-semibold transition-all shadow-2xs cursor-pointer"
        >
          <AlertCircle className="h-3.5 w-3.5 text-rose-500" />
          <span>View Cancellation Details</span>
        </button>
      );

    default:
      return (
        <Link
          href={`/projects/${p.id}`}
          title="Open project details workspace"
          className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-100 text-slate-700 hover:bg-slate-200 border border-slate-200 text-xs font-mono font-semibold transition-all shadow-2xs"
        >
          <ExternalLink className="h-3.5 w-3.5 text-slate-500" />
          <span>View Details</span>
        </Link>
      );
  }
}

// ── Main ProjectsCatalogueView Component ─────────────────────────────────────

export interface ProjectsCatalogueViewProps {
  isEmbedded?: boolean;
  initialStatus?: string;
  onProjectsLoaded?: (projects: Project[]) => void;
}

export function ProjectsCatalogueView({
  isEmbedded = false,
  initialStatus = 'ALL',
  onProjectsLoaded,
}: ProjectsCatalogueViewProps) {
  const [projects, setProjects] = useState<Project[]>([]);
  const [selectedStatus, setSelectedStatus] = useState<string>(initialStatus);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [lastSyncedAt, setLastSyncedAt] = useState<Date | null>(null);

  // Modal States
  const [assignTarget, setAssignTarget] = useState<{ project: Project; isReassign: boolean } | null>(null);
  const [rejectTarget, setRejectTarget] = useState<Project | null>(null);
  const [cancelTarget, setCancelTarget] = useState<Project | null>(null);
  const [removeTarget, setRemoveTarget] = useState<Project | null>(null);
  const [cancellationDetailTarget, setCancellationDetailTarget] = useState<Project | null>(null);
  const [isNewProjectModalOpen, setIsNewProjectModalOpen] = useState<boolean>(false);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  // 3-dot dropdown menu state
  const [activeMenuId, setActiveMenuId] = useState<string | null>(null);

  // Close 3-dot menu on click away
  useEffect(() => {
    const handleDocumentClick = () => {
      setActiveMenuId(null);
    };
    if (activeMenuId) {
      document.addEventListener('click', handleDocumentClick);
    }
    return () => {
      document.removeEventListener('click', handleDocumentClick);
    };
  }, [activeMenuId]);

  // Sync initialStatus when prop changes
  useEffect(() => {
    if (initialStatus && initialStatus !== selectedStatus) {
      setSelectedStatus(initialStatus);
    }
  }, [initialStatus]);

  const loadProjects = async (isManual = false, isSilent = false) => {
    if (isManual) setRefreshing(true);
    else if (!isSilent) setLoading(true);
    if (!isSilent) setError(null);

    try {
      const data = await adminApi.getProjects(
        selectedStatus === 'ALL' ? undefined : (selectedStatus as ProjectStatus)
      );
      const list = data || [];
      setProjects(list);
      setLastSyncedAt(new Date());
      if (onProjectsLoaded) {
        onProjectsLoaded(list);
      }
    } catch (err: any) {
      console.error(err);
      if (!isSilent) setError(err.message || 'Failed to load projects');
    } finally {
      if (!isSilent) {
        setLoading(false);
        setRefreshing(false);
      }
    }
  };

  useEffect(() => {
    loadProjects();
    const interval = setInterval(() => {
      loadProjects(false, true);
    }, 6000);
    return () => clearInterval(interval);
  }, [selectedStatus]);

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
    <div className="space-y-6">
      {error && (
        <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-sm text-rose-800 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
          <span className="font-medium">{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadProjects(true)} className="ml-auto font-mono text-xs">
            Retry
          </Button>
        </div>
      )}

      {/* Control Toolbar */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-3">
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

        {/* Metric & Sync Controls (Improvement 1) */}
        <div className="flex items-center gap-2 flex-wrap">
          {lastSyncedAt && (
            <div className="hidden sm:inline-flex items-center gap-1.5 text-xs font-mono text-slate-500 bg-white border border-slate-200 px-3 py-2 rounded-xl shadow-xs whitespace-nowrap">
              <Clock className="h-3.5 w-3.5 text-slate-400" />
              <span>Last synced: {formatTime(lastSyncedAt)}</span>
            </div>
          )}
          <div className="text-xs font-mono text-slate-500 bg-white border border-slate-200 px-3 py-2 rounded-xl shadow-xs whitespace-nowrap">
            <span>SHOWING: </span>
            <span className="font-bold text-slate-900">{filteredProjects.length}</span>
            <span className="text-slate-400"> / </span>
            <span className="font-bold text-slate-900">{projects.length}</span>
          </div>
          <button
            type="button"
            onClick={() => loadProjects(true)}
            disabled={refreshing}
            className="inline-flex items-center gap-1.5 px-3 py-2 text-xs font-mono font-semibold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200 rounded-xl transition-all shadow-xs cursor-pointer disabled:opacity-50"
            title="Refresh catalogue"
          >
            <RefreshCw className={`h-3.5 w-3.5 text-slate-500 ${refreshing ? 'animate-spin text-[#0453cd]' : ''}`} />
            <span className="hidden sm:inline">{refreshing ? 'Syncing...' : 'Sync'}</span>
          </button>
        </div>
      </div>

      {/* Status Filter Tabs */}
      <div className="flex items-center gap-1.5 overflow-x-auto pb-3 scrollbar-none border-b border-slate-200 w-full max-w-full">
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
        <div className="bg-white border border-slate-200 rounded-2xl soft-elevation shadow-xs overflow-visible">
          <div className="overflow-x-auto w-full max-w-full overflow-y-visible">
            <table className="w-full text-left text-xs min-w-[840px]">
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
                  const isDropdownOpen = activeMenuId === p.id;

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
                        {formatDate(p.created_at)}
                      </td>

                      {/* Administrative Actions */}
                      <td className="px-5 py-4 text-right whitespace-nowrap">
                        <div className="flex items-center justify-end gap-2">
                          {/* Contextual Primary Action Button */}
                          <PrimaryActionButton
                            project={p}
                            isActionLoading={isActionLoading}
                            onApprove={handleQuickApprove}
                            onAssign={(target, isReassign) =>
                              setAssignTarget({ project: target, isReassign })
                            }
                            onShowCancellation={(target) =>
                              setCancellationDetailTarget(target)
                            }
                          />

                          {/* Secondary Actions 3-Dot Dropdown */}
                          <ActionDropdown
                            project={p}
                            isOpen={isDropdownOpen}
                            onToggle={(e) => {
                              e.stopPropagation();
                              setActiveMenuId(isDropdownOpen ? null : p.id);
                            }}
                            onClose={() => setActiveMenuId(null)}
                            onAssign={() => setAssignTarget({ project: p, isReassign: true })}
                            onReject={() => setRejectTarget(p)}
                            onCancel={() => setCancelTarget(p)}
                            onRemove={() => setRemoveTarget(p)}
                          />
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
          isTrainingProject={assignTarget.project.is_training_project === 1}
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

      {cancellationDetailTarget && (
        <CancellationDetailsModal
          isOpen={true}
          onClose={() => setCancellationDetailTarget(null)}
          project={cancellationDetailTarget}
        />
      )}

      {removeTarget && (
        <RemoveProjectModal
          isOpen={true}
          onClose={() => setRemoveTarget(null)}
          project={removeTarget}
          onSuccess={(removedId) => {
            setProjects((prev) => prev.filter((p) => p.id !== removedId));
            loadProjects(true);
          }}
        />
      )}

      <NewProjectModal
        isOpen={isNewProjectModalOpen}
        onClose={() => setIsNewProjectModalOpen(false)}
        onSuccess={() => loadProjects(true)}
      />
    </div>
  );
}


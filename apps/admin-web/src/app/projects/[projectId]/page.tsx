'use client';
/* eslint-disable @next/next/no-img-element */

import React, { useState, useEffect, use, useRef } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { AssignModal } from '@/components/projects/AssignModal';
import { RejectModal } from '@/components/projects/RejectModal';
import { CancelModal } from '@/components/projects/CancelModal';
import { EvaluateModal } from '@/components/projects/EvaluateModal';
import { adminApi } from '@/lib/api';
import { formatDateTime, formatDate, formatTime, parseUtcDate } from '@/lib/dateUtils';
import {
  Project,
  ProjectFile,
  DrawingVersion,
  Correction,
  Assignment,
  ActivityLog,
  ProjectComment,
} from '@/lib/types';
import {
  ArrowLeft,
  CheckCircle,
  XCircle,
  UserPlus,
  Ban,
  Download,
  FileText,
  Layers,
  History,
  Activity,
  AlertTriangle,
  Clock,
  Compass,
  FileCheck2,
  Calendar,
  User,
  Shield,
  FileBadge,
  GitMerge,
  SplitSquareVertical,
  ZoomIn,
  ZoomOut,
  Maximize2,
  Minimize2,
  Contrast,
  Layers3,
  ChevronDown,
  Move,
  MessageSquare,
  Send,
  Paperclip,
  Mic,
  AtSign,
  Filter,
  MoreVertical,
  FileArchive,
  Volume2,
  MapPin,
  Target,
  X,
  Loader2,
  AlertCircle,
} from 'lucide-react';

type TabKey = 'overview' | 'timeline' | 'cad' | 'collab' | 'files' | 'drawings' | 'corrections' | 'assignments' | 'activity';
type CADViewMode = 'split' | 'overlay';

// ─── Redline pin ──────────────────────────────────────────────────────────────

interface RedlinePin {
  /** Stable unique key for this pin in React state */
  id: string;
  /** Normalised 0-1 coordinate relative to the viewport width */
  x: number;
  /** Normalised 0-1 coordinate relative to the viewport height */
  y: number;
  /** User-authored annotation text (without the [PIN:x,y] prefix) */
  note: string;
  /** draft = placed but not submitted; submitting = API in-flight; committed = persisted to D1 */
  status: 'draft' | 'submitting' | 'committed';
  /** Correction round number returned by the API after commit */
  round?: number;
  /** Correction record ID returned by the API after commit */
  correctionId?: string;
}

/** Parses the [PIN:x,y] prefix from a correction description, returns null if absent. */
function parsePinFromDescription(
  description: string
): { x: number; y: number; text: string } | null {
  const m = description.match(/^\[PIN:([\d.]+),([\d.]+)\]\s*([\s\S]*)$/);
  if (!m) return null;
  return { x: parseFloat(m[1]), y: parseFloat(m[2]), text: (m[3] || '').trim() };
}

interface CollabMessage {
  id: string;
  author: string;
  role: 'ADMIN' | 'DRAUGHTSMAN' | 'ENGINEER' | 'STUDENT' | string;
  content: string;
  timestamp: Date;
  attachment?: {
    name: string;
    size: string;
    type: 'pdf' | 'dwg' | 'image' | 'audio' | 'zip' | 'file';
    fileId?: string;
    downloadUrl?: string;
  };
  isVoice?: boolean;
  replyCount?: number;
}

function toCollabMessage(c: ProjectComment): CollabMessage {
  const name = c.attachment_name || '';
  const mime = c.attachment_type || '';
  const isAudio =
    mime.startsWith('audio/') ||
    /\.(webm|m4a|mp3|wav|aac|ogg)$/i.test(name);
  const isImage =
    mime.startsWith('image/') ||
    /\.(png|jpg|jpeg|webp|svg)$/i.test(name);
  const isDwg =
    mime.includes('acad') ||
    mime.includes('dxf') ||
    /\.(dwg|dxf)$/i.test(name);
  const isPdf =
    mime.includes('pdf') ||
    /\.pdf$/i.test(name);
  const isZip =
    mime.includes('zip') ||
    /\.zip$/i.test(name);

  let type: 'pdf' | 'dwg' | 'image' | 'audio' | 'zip' | 'file' = 'file';
  if (isAudio) type = 'audio';
  else if (isImage) type = 'image';
  else if (isDwg) type = 'dwg';
  else if (isPdf) type = 'pdf';
  else if (isZip) type = 'zip';

  let formattedSize = c.attachment_size || 'Attached file';
  if (c.attachment_size && !isNaN(Number(c.attachment_size))) {
    const bytes = Number(c.attachment_size);
    formattedSize = bytes > 1024 * 1024
      ? `${(bytes / (1024 * 1024)).toFixed(2)} MB`
      : `${(bytes / 1024).toFixed(1)} KB`;
  }

  const downloadUrl = c.attachment_file_id
    ? adminApi.getFileDownloadUrl(c.attachment_file_id)
    : undefined;

  const rawRole = (c.author_role || '').toUpperCase();
  let normalizedRole: 'ADMIN' | 'DRAUGHTSMAN' | 'ENGINEER' | 'STUDENT' | string = 'ENGINEER';
  let defaultAuthor = 'Participant';

  if (rawRole === 'ADMIN' || rawRole === 'STUDIO_ADMIN') {
    normalizedRole = 'ADMIN';
    defaultAuthor = 'Admin';
  } else if (rawRole === 'DRAUGHTSMAN') {
    normalizedRole = 'DRAUGHTSMAN';
    defaultAuthor = 'Draughtsman';
  } else if (rawRole === 'ENGINEER' || rawRole === 'CLIENT') {
    normalizedRole = 'ENGINEER';
    defaultAuthor = 'Engineer';
  } else if (rawRole === 'STUDENT') {
    normalizedRole = 'STUDENT';
    defaultAuthor = 'Student';
  }

  return {
    id: c.id,
    author: c.author_name || defaultAuthor,
    role: normalizedRole,
    content: c.content,
    timestamp: parseUtcDate(c.created_at) || new Date(),
    attachment: c.attachment_name ? {
      name: c.attachment_name,
      size: formattedSize,
      type,
      fileId: c.attachment_file_id || undefined,
      downloadUrl,
    } : undefined,
    isVoice: isAudio,
  };
}

// ─── Workflow Timeline helpers ────────────────────────────────────────────────

const WORKFLOW_STAGES = [
  {
    key: 'SUBMITTED',
    label: '1. Request Submitted',
    desc: 'Engineer uploaded files and defined requirements.',
    detail: 'Source files accepted and stored securely in Cloudflare R2.',
  },
  {
    key: 'WAITING_ASSIGNMENT',
    label: '2. Admin Review',
    desc: 'Scope reviewed and approved by Studio Admin.',
    detail: 'Project approved — now awaiting draughtsman allocation.',
  },
  {
    key: 'WAITING_ACCEPTANCE',
    label: '3. Draughtsman Assigned',
    desc: 'Project dispatched to draughtsman for acceptance.',
    detail: 'Assignment created. Awaiting draughtsman confirmation.',
  },
  {
    key: 'IN_PROGRESS',
    label: '4. Drawing Creation',
    desc: 'Draughtsman is actively drafting deliverables.',
    detail: 'CAD work in progress. Correction rounds still available.',
  },
  {
    key: 'UNDER_CLIENT_REVIEW',
    label: '5. Engineer Review',
    desc: 'Drawings submitted for engineer approval.',
    detail: 'Engineer reviewing final deliverables. Corrections possible.',
  },
  {
    key: 'COMPLETED',
    label: '6. Project Delivered',
    desc: 'All drawings accepted. Project closed.',
    detail: 'Final CAD package delivered and acknowledged.',
  },
];

const STATUS_ORDER = [
  'DRAFT',
  'SUBMITTED',
  'WAITING_ASSIGNMENT',
  'WAITING_ACCEPTANCE',
  'IN_PROGRESS',
  'UNDER_CLIENT_REVIEW',
  'COMPLETED',
];

function getStageState(
  stageKey: string,
  currentStatus: string,
  isCancelled: boolean
): 'completed' | 'active' | 'pending' | 'cancelled' {
  if (isCancelled) return 'cancelled';
  const stageIdx = STATUS_ORDER.indexOf(stageKey);
  const currentIdx = STATUS_ORDER.indexOf(currentStatus);
  if (currentIdx > stageIdx) return 'completed';
  if (currentIdx === stageIdx) return 'active';
  return 'pending';
}

function getProgressPercent(status: string, isCancelled: boolean): number {
  if (isCancelled) return 0;
  const idx = STATUS_ORDER.indexOf(status);
  if (idx <= 0) return 0;
  return Math.round(((idx - 1) / (WORKFLOW_STAGES.length - 1)) * 100);
}

export default function ProjectDetailPage({
  params,
}: {
  params: Promise<{ projectId: string }>;
}) {
  const { projectId } = use(params);
  const router = useRouter();

  const [project, setProject] = useState<Project | null>(null);
  const [files, setFiles] = useState<ProjectFile[]>([]);
  const [drawingVersions, setDrawingVersions] = useState<DrawingVersion[]>([]);
  const [corrections, setCorrections] = useState<Correction[]>([]);
  const [assignments, setAssignments] = useState<Assignment[]>([]);
  const [activity, setActivity] = useState<ActivityLog[]>([]);

  const [activeTab, setActiveTab] = useState<TabKey>('overview');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // CAD Comparison state
  const [cadViewMode, setCadViewMode] = useState<CADViewMode>('split');
  const [cadZoom, setCadZoom] = useState<number>(100);
  const [cadVersionA, setCadVersionA] = useState<number>(0);
  const [cadVersionB, setCadVersionB] = useState<number>(1);
  const [cadSliderPos, setCadSliderPos] = useState<number>(50);
  const [cadFullscreen, setCadFullscreen] = useState<boolean>(false);
  const [cadContrast, setCadContrast] = useState<'normal' | 'high' | 'invert'>('normal');

  // Redline pinning state
  const [redlineMode, setRedlineMode] = useState<boolean>(false);
  const [redlinePins, setRedlinePins] = useState<RedlinePin[]>([]);
  const [activeDraftPinId, setActiveDraftPinId] = useState<string | null>(null);
  const [pinNoteInput, setPinNoteInput] = useState<string>('');
  const [pinSubmitting, setPinSubmitting] = useState<boolean>(false);
  const [pinError, setPinError] = useState<string | null>(null);

  // Collaboration Hub state
  const [collabMessages, setCollabMessages] = useState<CollabMessage[]>([]);
  const [collabInput, setCollabInput] = useState<string>('');
  const [collabSending, setCollabSending] = useState<boolean>(false);
  const [collabError, setCollabError] = useState<string | null>(null);
  const [collabAttachment, setCollabAttachment] = useState<File | null>(null);
  const collabFileInputRef = useRef<HTMLInputElement | null>(null);

  // Modal states
  const [isAssignOpen, setIsAssignOpen] = useState<boolean>(false);
  const [isReassign, setIsReassign] = useState<boolean>(false);
  const [isRejectOpen, setIsRejectOpen] = useState<boolean>(false);
  const [isCancelOpen, setIsCancelOpen] = useState<boolean>(false);
  const [isEvaluateOpen, setIsEvaluateOpen] = useState<boolean>(false);
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  // Authenticated file download state
  const [downloadingFileId, setDownloadingFileId] = useState<string | null>(null);
  const [downloadError, setDownloadError] = useState<string | null>(null);

  const handleDownloadFile = async (fileId: string, fallbackFileName?: string) => {
    try {
      setDownloadingFileId(fileId);
      setDownloadError(null);
      await adminApi.downloadAndSaveFile(fileId, fallbackFileName);
    } catch (err: any) {
      console.error('File download error:', err);
      setDownloadError(err.message || 'Failed to download file. Please verify permissions.');
    } finally {
      setDownloadingFileId(null);
    }
  };

  const fetchProjectData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [proj, fileList, dvList, corrList, assignList, actList, commentList] = await Promise.all([
        adminApi.getProject(projectId),
        adminApi.getProjectFiles(projectId).catch(() => []),
        adminApi.getProjectDrawingVersions(projectId).catch(() => []),
        adminApi.getProjectCorrections(projectId).catch(() => []),
        adminApi.getProjectAssignments(projectId).catch(() => []),
        adminApi.getProjectActivity(projectId).catch(() => []),
        adminApi.getProjectComments(projectId).catch(() => []),
      ]);

      setProject(proj);
      setFiles(fileList || []);
      setDrawingVersions(dvList || []);
      setCorrections(corrList || []);
      setAssignments(assignList || []);
      setActivity(actList || []);
      setCollabMessages((commentList || []).map(toCollabMessage));
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load project details');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchProjectData();
  }, [projectId]);

  // Keyboard navigation for CAD comparison workspace
  useEffect(() => {
    if (activeTab !== 'cad') return;
    const handleKeyDown = (e: KeyboardEvent) => {
      if (['INPUT', 'TEXTAREA', 'SELECT'].includes((e.target as HTMLElement)?.tagName)) return;
      if (e.key === 'f' || e.key === 'F') {
        e.preventDefault();
        setCadFullscreen(prev => !prev);
      } else if (e.key === 'Escape') {
        if (cadFullscreen) setCadFullscreen(false);
        if (redlineMode) {
          setRedlineMode(false);
          setActiveDraftPinId(null);
        }
      } else if (e.key === '+' || e.key === '=') {
        e.preventDefault();
        setCadZoom(z => Math.min(300, z + 25));
      } else if (e.key === '-' || e.key === '_') {
        e.preventDefault();
        setCadZoom(z => Math.max(25, z - 25));
      } else if (e.key === '0') {
        e.preventDefault();
        setCadZoom(100);
      } else if (e.key === 'r' || e.key === 'R') {
        e.preventDefault();
        setRedlineMode(m => !m);
        setActiveDraftPinId(null);
      } else if (e.key === 'c' || e.key === 'C') {
        e.preventDefault();
        setCadContrast(c => c === 'normal' ? 'high' : c === 'high' ? 'invert' : 'normal');
      } else if (e.key === 'm' || e.key === 'M') {
        e.preventDefault();
        setCadViewMode(m => m === 'split' ? 'overlay' : 'split');
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [activeTab, cadFullscreen, redlineMode]);

  const handleApprove = async () => {
    if (!project) return;
    setActionLoading(true);
    setError(null);
    try {
      await adminApi.approveProject(project.id);
      await fetchProjectData(true);
    } catch (err: any) {
      setError(err.message || 'Failed to approve project');
    } finally {
      setActionLoading(false);
    }
  };

  const formatFileSize = (bytes: number): string => {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  return (
    <AdminShell
      title={project ? (project.project_name || 'Project Details') : 'Project Details'}
      subtitle={project ? `ID: ${project.id}` : 'Loading...'}
      onRefresh={() => fetchProjectData(true)}
      isRefreshing={refreshing}
    >
      {/* Back button */}
      <div className="mb-6">
        <Link
          href="/projects"
          className="inline-flex items-center gap-2 text-xs font-semibold text-slate-500 hover:text-slate-900 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          <span>Back to Projects Catalog</span>
        </Link>
      </div>

      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-50 border border-rose-200 text-sm text-rose-800 flex items-center gap-3">
          <AlertTriangle className="h-5 w-5 text-rose-600 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => fetchProjectData(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center p-24 bg-white border border-slate-200 rounded-2xl soft-elevation">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500 mt-3 font-mono font-medium">Loading project specifications...</p>
        </div>
      ) : !project ? (
        <Card className="text-center py-16 bg-white border-slate-200">
          <h3 className="text-base font-semibold text-slate-900">Project Not Found</h3>
          <p className="text-xs text-slate-500 mt-1 font-mono">The requested project ID does not exist in D1.</p>
        </Card>
      ) : (
        <div className="space-y-6">
          {/* Rejection Notice Banner */}
          {project.status === 'CANCELLED' && project.rejection_reason && (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-900 flex items-start gap-3">
              <XCircle className="h-5 w-5 text-rose-600 shrink-0 mt-0.5" />
              <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-rose-700 font-mono">
                  Project Rejected / Cancelled
                </p>
                <p className="text-sm mt-1 text-rose-800">{project.rejection_reason}</p>
                {project.cancelled_at && (
                  <p className="text-[11px] text-rose-600 font-mono mt-1">
                    Recorded at: {formatDateTime(project.cancelled_at)}
                  </p>
                )}
              </div>
            </div>
          )}

          {/* Project Header Card & Administrative Action Bar */}
          <Card technicalCorners className="bg-white border-slate-200 soft-elevation p-4 sm:p-6">
            <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-4 sm:gap-6">
              <div className="space-y-2 min-w-0 flex-1">
                <div className="flex items-center gap-2.5 sm:gap-3 flex-wrap">
                  <h1 className="text-xl sm:text-2xl font-bold text-slate-900 tracking-tight break-words">
                    {project.project_name || 'Untitled Project'}
                  </h1>
                  <Badge status={project.status} size="md" />
                  {project.correction_round > 0 && (
                    <span className="text-xs px-2.5 py-1 rounded-full bg-blue-50 text-blue-700 border border-blue-200 font-mono font-semibold">
                      Correction Round {project.correction_round} of 3
                    </span>
                  )}
                </div>

                <p className="text-xs sm:text-sm text-slate-600 max-w-2xl break-words">{project.project_address}</p>

                <div className="flex items-center gap-3 sm:gap-5 text-xs text-slate-500 pt-1 flex-wrap">
                  <div className="flex items-center gap-1.5">
                    <Layers className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                    <span>Drawing: <strong className="text-slate-800 font-medium">{project.drawing_name || project.drawing_type}</strong></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Compass className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                    <span>Area: <strong className="text-slate-800 font-medium">{project.project_area || 'Standard'} sq.ft</strong></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <User className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                    <span>
                      Engineer:{' '}
                      <Link
                        href={`/engineers/${encodeURIComponent(project.client_id)}`}
                        className="font-medium text-[#0453cd] hover:underline"
                        title="View Engineer Dossier"
                      >
                        {project.client_name ? `${project.client_name} (${project.client_id.substring(0, 8)})` : `ID: ${project.client_id.substring(0, 8)}`}
                      </Link>
                    </span>
                  </div>
                  {project.draughtsman_id && (
                    <div className="flex items-center gap-1.5">
                      <User className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                      <span>
                        Draughtsman:{' '}
                        <Link
                          href={`/draughtsmen/${encodeURIComponent(project.draughtsman_id)}`}
                          className="font-medium text-[#0453cd] hover:underline"
                          title="View Draughtsman Dossier"
                        >
                          {project.draughtsman_name || `ID: ${project.draughtsman_id.substring(0, 8)}`}
                        </Link>
                      </span>
                    </div>
                  )}
                  <div className="flex items-center gap-1.5">
                    <Calendar className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                    <span>Created: <span className="text-slate-800 font-medium">{formatDate(project.created_at)}</span></span>
                  </div>
                </div>
              </div>

              {/* Administrative Action Bar (Governed by State Machine) */}
              <div className="flex items-center gap-2 sm:gap-2.5 flex-wrap shrink-0 pt-2 lg:pt-0 border-t lg:border-t-0 border-slate-100">
                {/* SUBMITTED State */}
                {project.status === 'SUBMITTED' && (
                  <>
                    <Button
                      variant="success"
                      loading={actionLoading}
                      onClick={handleApprove}
                      icon={<CheckCircle className="h-4 w-4" />}
                    >
                      Approve Project
                    </Button>
                    <Button
                      variant="danger"
                      onClick={() => setIsRejectOpen(true)}
                      icon={<XCircle className="h-4 w-4" />}
                    >
                      Reject Submission
                    </Button>
                  </>
                )}

                {/* WAITING_ASSIGNMENT State */}
                {project.status === 'WAITING_ASSIGNMENT' && (
                  <Button
                    variant="primary"
                    onClick={() => {
                      setIsReassign(false);
                      setIsAssignOpen(true);
                    }}
                    icon={<UserPlus className="h-4 w-4" />}
                  >
                    Assign Draughtsman
                  </Button>
                )}

                {/* WAITING_ACCEPTANCE or IN_PROGRESS State: Reassign */}
                {(project.status === 'WAITING_ACCEPTANCE' || project.status === 'IN_PROGRESS') && (
                  <Button
                    variant="outline"
                    onClick={() => {
                      setIsReassign(true);
                      setIsAssignOpen(true);
                    }}
                    icon={<UserPlus className="h-4 w-4" />}
                  >
                    Reassign Draughtsman
                  </Button>
                )}

                {/* Review States: Interactive Evaluation Modal Trigger */}
                {(project.status === 'UNDER_ENGINEER_REVIEW' || project.status === 'UNDER_CLIENT_REVIEW') &&
                  drawingVersions.length > 0 && (
                    <Button
                      variant="primary"
                      onClick={() => setIsEvaluateOpen(true)}
                      icon={<FileCheck2 className="h-4 w-4" />}
                    >
                      Evaluate Submission
                    </Button>
                  )}

                {/* Active States: Cancel Project */}
                {project.status !== 'COMPLETED' &&
                  project.status !== 'CANCELLED' &&
                  project.status !== 'DRAFT' && (
                    <Button
                      variant="ghost"
                      onClick={() => setIsCancelOpen(true)}
                      className="text-rose-600 hover:text-rose-700 hover:bg-rose-50"
                      icon={<Ban className="h-4 w-4" />}
                    >
                      Cancel Project
                    </Button>
                  )}
              </div>
            </div>
          </Card>

          {/* Navigation Tabs */}
          <div className="flex items-center gap-2 border-b border-slate-200 pb-2 overflow-x-auto w-full max-w-full scrollbar-none">
            {[
              { key: 'overview', label: 'Specifications & Info', count: null },
              { key: 'timeline', label: 'Workflow Timeline', count: null },
              { key: 'cad', label: 'CAD Comparison', count: drawingVersions.length > 0 ? drawingVersions.length : null },
              { key: 'collab', label: 'Collaboration Hub', count: collabMessages.length },
              { key: 'files', label: 'Reference Files', count: files.length },
              { key: 'drawings', label: 'Drawing Versions', count: drawingVersions.length },
              { key: 'corrections', label: 'Corrections', count: corrections.length },
              { key: 'assignments', label: 'Assignment History', count: assignments.length },
              { key: 'activity', label: 'Audit Trail', count: activity.length },
            ].map((tab) => {
              const isSelected = activeTab === tab.key;
              return (
                <button
                  key={tab.key}
                  onClick={() => setActiveTab(tab.key as TabKey)}
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-mono font-semibold whitespace-nowrap transition-all ${
                    isSelected
                      ? 'bg-[#0d1c32] text-white shadow-xs'
                      : 'bg-white text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-slate-200'
                  }`}
                >
                  <span>{tab.label}</span>
                  {tab.count !== null && (
                    <span
                      className={`px-1.5 py-0.5 rounded-full text-[10px] font-mono ${
                        isSelected ? 'bg-white/20 text-white' : 'bg-slate-100 text-slate-600 border border-slate-200'
                      }`}
                    >
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          {/* Tab: Workflow Timeline */}
          {activeTab === 'timeline' && (() => {
            const isCancelled = project.status === 'CANCELLED';
            const progressPct = getProgressPercent(project.status, isCancelled);
            return (
              <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                {/* Timeline card */}
                <div className="lg:col-span-2">
                  <Card technicalCorners className="bg-white border-slate-200 soft-elevation">
                    <div className="flex items-center gap-2 mb-6 pb-3 border-b border-slate-200">
                      <GitMerge className="h-4 w-4 text-[#0453cd]" />
                      <h3 className="text-xs font-semibold text-slate-900 uppercase tracking-wider font-mono">Project Workflow Lifecycle</h3>
                    </div>

                    {isCancelled && (
                      <div className="mb-6 p-3 rounded-xl bg-rose-50 border border-rose-200 text-xs text-rose-800 flex items-center gap-2 font-mono">
                        <XCircle className="h-4 w-4 text-rose-600 shrink-0" />
                        This project was cancelled. Workflow halted.
                      </div>
                    )}

                    <div className="relative pl-2">
                      {/* Background line */}
                      <div className="absolute left-5 top-5 bottom-5 w-[2px] bg-slate-200" />
                      {/* Progress line */}
                      <div
                        className="absolute left-5 top-5 w-[2px] bg-[#0453cd] transition-all duration-700"
                        style={{ height: `${progressPct}%` }}
                      />

                      <div className="space-y-8 relative">
                        {WORKFLOW_STAGES.map((stage) => {
                          const state = getStageState(stage.key, project.status, isCancelled);
                          const isCompleted = state === 'completed';
                          const isActive = state === 'active';
                          const isPending = state === 'pending' || state === 'cancelled';

                          return (
                            <div key={stage.key} className={`flex gap-4 ${isPending ? 'opacity-40' : ''}`}>
                              {/* Node */}
                              <div className="shrink-0 relative z-10">
                                {isCompleted && (
                                  <div className="w-10 h-10 rounded-full bg-[#0453cd] flex items-center justify-center border-4 border-slate-50 shadow-xs">
                                    <CheckCircle className="h-4 w-4 text-white" />
                                  </div>
                                )}
                                {isActive && (
                                  <div className="w-10 h-10 rounded-full bg-white border-2 border-[#0453cd] flex items-center justify-center shadow-md">
                                    <div className="w-3 h-3 rounded-full bg-[#0453cd] animate-pulse" />
                                  </div>
                                )}
                                {isPending && (
                                  <div className="w-10 h-10 rounded-full bg-white border-2 border-slate-300 flex items-center justify-center" />
                                )}
                              </div>

                              {/* Content */}
                              <div className="pt-2 flex-1 pb-2">
                                <h4 className={`text-xs font-semibold ${isActive ? 'text-[#0453cd] font-bold' : isCompleted ? 'text-slate-900' : 'text-slate-500'}`}>
                                  {stage.label}
                                </h4>
                                <p className="text-[11px] text-slate-500 mt-1">{stage.desc}</p>
                                {(isCompleted || isActive) && (
                                  <div className={`mt-3 p-3 rounded-lg text-[11px] border ${
                                    isActive
                                      ? 'bg-blue-50/70 border-blue-200 text-blue-950 font-medium'
                                      : 'bg-slate-50 border-slate-200 text-slate-700'
                                  }`}>
                                    {stage.detail}
                                  </div>
                                )}
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  </Card>
                </div>

                {/* Summary sidebar */}
                <div className="space-y-4">
                  <Card className="bg-white border-slate-200 soft-elevation">
                    <CardHeader title="Current Stage" />
                    <div className="space-y-3 text-xs">
                      <div className="flex justify-between pt-2">
                        <span className="text-slate-500 font-mono">Status</span>
                        <Badge status={project.status} size="sm" />
                      </div>
                      <div className="flex justify-between">
                        <span className="text-slate-500 font-mono">Progress</span>
                        <span className="font-semibold text-[#0453cd] font-mono">{progressPct}%</span>
                      </div>
                      <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                        <div
                          className="h-1.5 rounded-full bg-gradient-to-r from-blue-700 to-blue-500 transition-all duration-700"
                          style={{ width: `${progressPct}%` }}
                        />
                      </div>
                      {project.draughtsman_name && (
                        <div className="flex justify-between">
                          <span className="text-slate-500 font-mono">Draughtsman</span>
                          <span className="font-semibold text-slate-900 truncate max-w-[120px]">{project.draughtsman_name}</span>
                        </div>
                      )}
                      <div className="flex justify-between">
                        <span className="text-slate-500 font-mono">Corrections</span>
                        <span className="font-semibold text-slate-900 font-mono">{project.correction_round} / 3</span>
                      </div>
                      {project.submitted_at && (
                        <div className="flex justify-between">
                          <span className="text-slate-500 font-mono">Submitted</span>
                          <span className="text-slate-700 font-mono">{formatDate(project.submitted_at)}</span>
                        </div>
                      )}
                    </div>
                  </Card>

                  {activity.length > 0 && (
                    <Card className="bg-white border-slate-200 soft-elevation">
                      <CardHeader title="Recent Events" />
                      <div className="space-y-3">
                        {activity.slice(0, 4).map((log) => (
                          <div key={log.id} className="flex items-start gap-2">
                            <div className="h-1.5 w-1.5 rounded-full bg-[#0453cd] mt-1.5 shrink-0" />
                            <div>
                              <p className="text-[10px] font-mono text-[#0453cd] font-semibold">{log.action_type}</p>
                              <p className="text-[10px] text-slate-500 font-mono">{formatDateTime(log.timestamp)}</p>
                            </div>
                          </div>
                        ))}
                      </div>
                    </Card>
                  )}
                </div>
              </div>
            );
          })()}

          {/* ─── Tab: CAD Comparison Viewer ─────────────────────────────────── */}
          {activeTab === 'cad' && (() => {
            if (drawingVersions.length === 0) {
              return (
                <div className="flex flex-col items-center justify-center py-24 text-center bg-white rounded-2xl border border-slate-200 soft-elevation">
                  <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 mb-3 border border-slate-200">
                    <SplitSquareVertical className="h-6 w-6 text-slate-400" />
                  </div>
                  <p className="text-xs font-semibold text-slate-800">No CAD drawing deliverables submitted yet</p>
                  <p className="text-[11px] font-mono text-slate-500 max-w-sm mt-1">
                    Once drawings are uploaded by the assigned draughtsman, they will appear here for architectural comparison and redline pinning.
                  </p>
                </div>
              );
            }

            const versionList = drawingVersions;
            const vA = versionList[Math.min(cadVersionA, versionList.length - 1)];
            const vB = versionList[Math.min(cadVersionB, versionList.length - 1)];

            // SVG blueprint mock thumbnails inline (no external image dependency)
            const BlueprintMockA = () => (
              <svg width="100%" height="100%" viewBox="0 0 400 300" xmlns="http://www.w3.org/2000/svg"
                className="w-full h-full">
                <rect width="400" height="300" fill="#0d1929" />
                {/* Grid lines */}
                {Array.from({ length: 10 }).map((_, i) => (
                  <line key={`hA${i}`} x1="0" y1={i * 30} x2="400" y2={i * 30} stroke="#1e3a5f" strokeWidth="0.5" />
                ))}
                {Array.from({ length: 14 }).map((_, i) => (
                  <line key={`vA${i}`} x1={i * 30} y1="0" x2={i * 30} y2="300" stroke="#1e3a5f" strokeWidth="0.5" />
                ))}
                {/* Floor plan v1 - outer walls */}
                <rect x="40" y="40" width="320" height="220" fill="none" stroke="#60a5fa" strokeWidth="2" />
                {/* Rooms */}
                <line x1="180" y1="40" x2="180" y2="260" stroke="#60a5fa" strokeWidth="1.5" />
                <line x1="40" y1="150" x2="180" y2="150" stroke="#60a5fa" strokeWidth="1.5" />
                <line x1="280" y1="40" x2="280" y2="160" stroke="#60a5fa" strokeWidth="1.5" />
                {/* Doors */}
                <path d="M180 100 Q200 100 200 120" fill="none" stroke="#93c5fd" strokeWidth="1" />
                {/* Windows */}
                <line x1="80" y1="40" x2="120" y2="40" stroke="#bfdbfe" strokeWidth="3" />
                <line x1="220" y1="40" x2="260" y2="40" stroke="#bfdbfe" strokeWidth="3" />
                {/* Dimension lines */}
                <line x1="40" y1="280" x2="360" y2="280" stroke="#6b7280" strokeWidth="0.5" strokeDasharray="4 2" />
                <text x="200" y="295" textAnchor="middle" fill="#9ca3af" fontSize="8" fontFamily="monospace">320px</text>
                {/* Label */}
                <text x="8" y="15" fill="#60a5fa" fontSize="9" fontFamily="monospace" fontWeight="500">v{vA?.version_number ?? 1} · FLOOR PLAN</text>
              </svg>
            );

            const BlueprintMockB = () => (
              <svg width="100%" height="100%" viewBox="0 0 400 300" xmlns="http://www.w3.org/2000/svg"
                className="w-full h-full">
                <rect width="400" height="300" fill="#0d1929" />
                {Array.from({ length: 10 }).map((_, i) => (
                  <line key={`hB${i}`} x1="0" y1={i * 30} x2="400" y2={i * 30} stroke="#1e3a5f" strokeWidth="0.5" />
                ))}
                {Array.from({ length: 14 }).map((_, i) => (
                  <line key={`vB${i}`} x1={i * 30} y1="0" x2={i * 30} y2="300" stroke="#1e3a5f" strokeWidth="0.5" />
                ))}
                {/* Updated floor plan v2 - same outer, moved wall */}
                <rect x="40" y="40" width="320" height="220" fill="none" stroke="#60a5fa" strokeWidth="2" />
                <line x1="200" y1="40" x2="200" y2="260" stroke="#34d399" strokeWidth="1.5" />{/* moved wall - highlighted */}
                <line x1="40" y1="150" x2="200" y2="150" stroke="#60a5fa" strokeWidth="1.5" />
                <line x1="280" y1="40" x2="280" y2="160" stroke="#60a5fa" strokeWidth="1.5" />
                {/* New element: additional room */}
                <line x1="200" y1="180" x2="360" y2="180" stroke="#34d399" strokeWidth="1.5" strokeDasharray="none" />
                <path d="M200 110 Q220 110 220 130" fill="none" stroke="#93c5fd" strokeWidth="1" />
                <line x1="80" y1="40" x2="120" y2="40" stroke="#bfdbfe" strokeWidth="3" />
                <line x1="240" y1="40" x2="280" y2="40" stroke="#bfdbfe" strokeWidth="3" />
                {/* Change highlight overlay */}
                <rect x="195" y="40" width="10" height="220" fill="#34d399" fillOpacity="0.12" />
                <rect x="200" y="175" width="160" height="10" fill="#34d399" fillOpacity="0.12" />
                <line x1="40" y1="280" x2="360" y2="280" stroke="#6b7280" strokeWidth="0.5" strokeDasharray="4 2" />
                <text x="200" y="295" textAnchor="middle" fill="#9ca3af" fontSize="8" fontFamily="monospace">320px</text>
                <text x="8" y="15" fill="#34d399" fontSize="9" fontFamily="monospace" fontWeight="500">v{vB?.version_number ?? 2} · FLOOR PLAN (REVISED)</text>
              </svg>
            );

            // ── Redline pinning handlers (closures — access vB + component-level state setters) ─

            const handleViewportClick = (e: React.MouseEvent<HTMLDivElement>) => {
              if (!redlineMode) return;
              const rect = e.currentTarget.getBoundingClientRect();
              const x = Math.max(0.03, Math.min(0.97, (e.clientX - rect.left) / rect.width));
              const y = Math.max(0.03, Math.min(0.97, (e.clientY - rect.top) / rect.height));
              const newPin: RedlinePin = { id: crypto.randomUUID(), x, y, note: '', status: 'draft' };
              setRedlinePins(prev => [...prev, newPin]);
              setActiveDraftPinId(newPin.id);
              setPinNoteInput('');
              setPinError(null);
            };

            const handlePinSubmit = async (pin: RedlinePin) => {
              const note = pinNoteInput.trim();
              if (!note || pinSubmitting) return;
              const targetVersionId = vB?.id;
              if (!targetVersionId || targetVersionId.startsWith('mock-')) {
                setPinError('Upload a real drawing version before pinning corrections.');
                return;
              }
              setPinError(null);
              setPinSubmitting(true);
              setRedlinePins(prev => prev.map(p => p.id === pin.id ? { ...p, status: 'submitting' } : p));
              try {
                const result = await adminApi.createAdminCorrection(projectId, {
                  description: note,
                  targetVersionId,
                  pinX: pin.x,
                  pinY: pin.y,
                });
                setRedlinePins(prev => prev.map(p =>
                  p.id === pin.id
                    ? { ...p, status: 'committed', note, correctionId: result.correctionId, round: result.round }
                    : p
                ));
                setActiveDraftPinId(null);
                setPinNoteInput('');
                await fetchProjectData(true);
                setRedlinePins(prev => prev.filter(p => p.id !== pin.id));
              } catch (err: any) {
                setPinError(err?.message || 'Failed to pin correction. Retry.');
                setRedlinePins(prev => prev.map(p => p.id === pin.id ? { ...p, status: 'draft' } : p));
              } finally {
                setPinSubmitting(false);
              }
            };

            // Historical pins parsed from saved corrections (have [PIN:x,y] prefix)
            const historicalPins = (corrections as any[]).flatMap((corr: any) => {
              const parsed = parsePinFromDescription(corr.description || '');
              if (!parsed) return [];
              return [{ id: corr.id as string, x: parsed.x, y: parsed.y, note: parsed.text,
                status: 'committed' as const, round: corr.round_number as number, correctionId: corr.id as string }];
            });

            const allPins: RedlinePin[] = [
              ...historicalPins,
              ...redlinePins.filter(p => !historicalPins.find((h: any) => h.correctionId === p.correctionId)),
            ];

            return (
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                {/* Main Viewer */}
                <div className={cadFullscreen ? 'fixed inset-0 z-50 bg-[#07101f] p-4 flex flex-col overflow-auto' : 'lg:col-span-8'}>
                  {/* Architectural blueprint card */}
                  <div
                    className="rounded-2xl border border-slate-700/60 overflow-hidden flex flex-col flex-1"
                    style={{
                      background: '#0b1423',
                      boxShadow: '0 0 0 1px rgba(0,0,0,0.12), 0 20px 40px -8px rgba(0,0,0,0.4)',
                    }}
                  >
                    {/* Toolbar */}
                    <div
                      className="px-5 py-3 flex items-center justify-between gap-4 shrink-0"
                      style={{
                        background: 'rgba(255,255,255,0.03)',
                        borderBottom: '0.5px solid rgba(255,255,255,0.08)',
                        backdropFilter: 'blur(20px)',
                      }}
                    >
                      {/* Left: Project label & shortcut hints */}
                      <div className="flex items-center gap-3">
                        <SplitSquareVertical className="h-4 w-4 text-blue-400" />
                        <div>
                          <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest flex items-center gap-2">
                            <span>CAD COMPARISON</span>
                            {cadFullscreen && (
                              <span className="text-[9px] font-mono px-1.5 py-0.2 rounded bg-blue-500/20 text-blue-300 border border-blue-500/30">
                                FULLSCREEN
                              </span>
                            )}
                          </p>
                          <p className="text-xs font-semibold text-slate-200 truncate max-w-[200px]">
                            {project.project_name}
                          </p>
                        </div>
                      </div>

                      {/* Center: View mode toggle */}
                      <div className="flex items-center bg-slate-900/80 border border-slate-700/60 rounded-lg p-1 gap-1">
                        <button
                          onClick={() => setCadViewMode('split')}
                          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-[10px] font-mono font-medium tracking-wide transition-all ${
                            cadViewMode === 'split'
                              ? 'bg-blue-600 text-white shadow-sm'
                              : 'text-slate-400 hover:text-slate-200'
                          }`}
                        >
                          <SplitSquareVertical className="h-3 w-3" />
                          SPLIT
                        </button>
                        <button
                          onClick={() => setCadViewMode('overlay')}
                          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-md text-[10px] font-mono font-medium tracking-wide transition-all ${
                            cadViewMode === 'overlay'
                              ? 'bg-blue-600 text-white shadow-sm'
                              : 'text-slate-400 hover:text-slate-200'
                          }`}
                        >
                          <Layers3 className="h-3 w-3" />
                          OVERLAY
                        </button>
                      </div>

                      {/* Right: Contrast + Zoom + Fullscreen + Redline controls */}
                      <div className="flex items-center gap-1">
                        {/* Contrast Toggle */}
                        <button
                          onClick={() => setCadContrast(c => c === 'normal' ? 'high' : c === 'high' ? 'invert' : 'normal')}
                          className="px-2 py-1.5 rounded-md text-slate-400 hover:text-slate-200 hover:bg-slate-800/80 transition-colors flex items-center gap-1.5 text-[10px] font-mono border border-slate-700/60"
                          title={`Contrast filter: ${cadContrast.toUpperCase()} (Shortcut: C)`}
                        >
                          <Contrast className="h-3.5 w-3.5 text-blue-400" />
                          <span className="hidden sm:inline uppercase text-[9px]">{cadContrast}</span>
                        </button>

                        <div className="w-px h-4 bg-slate-700 mx-1" />

                        {/* Zoom Out */}
                        <button
                          onClick={() => setCadZoom(z => Math.max(25, z - 25))}
                          className="p-1.5 rounded-md text-slate-400 hover:text-slate-200 hover:bg-slate-800/80 transition-colors"
                          title="Zoom Out (Shortcut: -)"
                        >
                          <ZoomOut className="h-4 w-4" />
                        </button>
                        <button
                          onClick={() => setCadZoom(100)}
                          className="text-[10px] font-mono text-slate-300 hover:text-white px-1.5 py-0.5 rounded hover:bg-slate-800 transition-colors"
                          title="Reset to 100% (Shortcut: 0)"
                        >
                          {cadZoom}%
                        </button>
                        {/* Zoom In */}
                        <button
                          onClick={() => setCadZoom(z => Math.min(300, z + 25))}
                          className="p-1.5 rounded-md text-slate-400 hover:text-slate-200 hover:bg-slate-800/80 transition-colors"
                          title="Zoom In (Shortcut: +)"
                        >
                          <ZoomIn className="h-4 w-4" />
                        </button>

                        <div className="w-px h-4 bg-slate-700 mx-1" />

                        {/* Fullscreen Toggle */}
                        <button
                          onClick={() => setCadFullscreen(f => !f)}
                          className={`p-1.5 rounded-md transition-colors ${
                            cadFullscreen
                              ? 'bg-blue-600 text-white shadow-sm'
                              : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/80'
                          }`}
                          title={cadFullscreen ? 'Exit Fullscreen (Esc or F)' : 'Fullscreen CAD View (Shortcut: F)'}
                        >
                          {cadFullscreen ? <Minimize2 className="h-4 w-4" /> : <Maximize2 className="h-4 w-4" />}
                        </button>

                        {/* Redline Mode Toggle */}
                        <div className="w-px h-4 bg-slate-700 mx-1" />
                        <button
                          id="btn-redline-toggle"
                          onClick={() => {
                            setRedlineMode(m => !m);
                            if (redlineMode) setActiveDraftPinId(null);
                          }}
                          title={redlineMode ? 'Exit Redline Mode (Esc or R)' : 'Activate Redline Mode — click drawing to place annotation pins (Shortcut: R)'}
                          className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-[10px] font-mono font-semibold tracking-wide border transition-all ${
                            redlineMode
                              ? 'bg-amber-500/20 text-amber-300 border-amber-500/50 shadow-[0_0_12px_rgba(245,158,11,0.25)] animate-pulse'
                              : 'text-slate-400 border-slate-700/60 hover:text-amber-300 hover:border-amber-500/40 hover:bg-amber-500/10'
                          }`}
                        >
                          {redlineMode ? (
                            <><Target className="h-3.5 w-3.5" /> EXIT REDLINE</>
                          ) : (
                            <><MapPin className="h-3.5 w-3.5" /> REDLINE</>
                          )}
                        </button>
                      </div>
                    </div>

                    {/* Version selectors row */}
                    <div
                      className="px-5 py-2.5 flex items-center gap-4 shrink-0"
                      style={{ borderBottom: '0.5px solid rgba(255,255,255,0.06)' }}
                    >
                      {/* Version A selector */}
                      <div className="flex items-center gap-2 flex-1">
                        <span
                          className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold"
                          style={{ background: 'rgba(96,165,250,0.15)', color: '#93c5fd', border: '1px solid rgba(96,165,250,0.3)' }}
                        >
                          PREV
                        </span>
                        <select
                          value={cadVersionA}
                          onChange={e => setCadVersionA(Number(e.target.value))}
                          className="flex-1 bg-slate-900/80 border border-slate-700/60 text-slate-200 text-[11px] font-mono rounded-lg px-3 py-1.5 outline-none focus:border-blue-500/60 focus:ring-1 focus:ring-blue-500/20 cursor-pointer appearance-none"
                        >
                          {versionList.map((v, idx) => (
                            <option key={v.id} value={idx}>
                              v{v.version_number} — {v.original_name || `Drawing v${v.version_number}`}
                            </option>
                          ))}
                        </select>
                      </div>

                      <Move className="h-4 w-4 text-slate-600 shrink-0" />

                      {/* Version B selector */}
                      <div className="flex items-center gap-2 flex-1">
                        <span
                          className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold"
                          style={{ background: 'rgba(52,211,153,0.15)', color: '#6ee7b7', border: '1px solid rgba(52,211,153,0.3)' }}
                        >
                          CURR
                        </span>
                        <select
                          value={cadVersionB}
                          onChange={e => setCadVersionB(Number(e.target.value))}
                          className="flex-1 bg-slate-900/80 border border-slate-700/60 text-slate-200 text-[11px] font-mono rounded-lg px-3 py-1.5 outline-none focus:border-emerald-500/60 focus:ring-1 focus:ring-emerald-500/20 cursor-pointer appearance-none"
                        >
                          {versionList.map((v, idx) => (
                            <option key={v.id} value={idx}>
                              v{v.version_number} — {v.original_name || `Drawing v${v.version_number}`}
                            </option>
                          ))}
                        </select>
                      </div>
                    </div>

                    {/* Comparison Viewport — click in redline mode to place pins */}
                    <div
                      className="relative overflow-hidden flex-1"
                      style={{
                        minHeight: cadFullscreen ? 'calc(100vh - 220px)' : '480px',
                        cursor: redlineMode ? 'crosshair' : 'default',
                        backgroundImage: `
                          linear-gradient(to right, rgba(255,255,255,0.025) 1px, transparent 1px),
                          linear-gradient(to bottom, rgba(255,255,255,0.025) 1px, transparent 1px)
                        `,
                        backgroundSize: '40px 40px',
                        backgroundColor: '#07101f',
                      }}
                      onClick={handleViewportClick}
                    >
                      {/* Redline mode hint banner */}
                      {redlineMode && (
                        <div
                          className="absolute top-3 left-1/2 -translate-x-1/2 z-40 flex items-center gap-2 px-4 py-2 rounded-full text-[10px] font-mono font-semibold text-amber-200 pointer-events-none"
                          style={{
                            background: 'rgba(120,60,0,0.88)',
                            backdropFilter: 'blur(12px)',
                            border: '1px solid rgba(245,158,11,0.45)',
                            boxShadow: '0 0 24px rgba(245,158,11,0.2)',
                          }}
                        >
                          <Target className="h-3 w-3" />
                          REDLINE MODE · Click anywhere on the drawing to place an annotation pin
                        </div>
                      )}

                      {/* Scaled drawing content */}
                      <div
                        style={{
                          transform: `scale(${cadZoom / 100})`,
                          transformOrigin: 'top left',
                          transition: 'transform 0.2s ease',
                          width: `${10000 / cadZoom}%`,
                          height: cadFullscreen ? 'calc(100vh - 220px)' : '480px',
                          filter: cadContrast === 'high'
                            ? 'contrast(1.6) brightness(1.15)'
                            : cadContrast === 'invert'
                            ? 'invert(0.9) hue-rotate(180deg) contrast(1.2)'
                            : 'none',
                        }}
                      >
                        {cadViewMode === 'split' ? (
                          // ── Split View ──────────────────────────────────
                          <div className="flex h-full gap-0.5">
                            {/* Version A panel */}
                            <div className="flex-1 relative border border-slate-700/40 rounded-l-xl overflow-hidden">
                              <div
                                className="absolute top-3 left-3 z-10 px-2 py-1 rounded text-[10px] font-mono font-semibold"
                                style={{
                                  background: 'rgba(15,23,42,0.85)',
                                  backdropFilter: 'blur(8px)',
                                  color: '#93c5fd',
                                  border: '1px solid rgba(96,165,250,0.4)',
                                }}
                              >
                                PREV · v{vA?.version_number ?? 1}
                              </div>
                              <BlueprintMockA />
                            </div>

                            {/* Drag handle */}
                            <div
                              className="w-1.5 bg-blue-500/40 flex items-center justify-center cursor-ew-resize flex-shrink-0 relative group"
                              style={{ background: 'rgba(59,130,246,0.3)' }}
                            >
                              <div
                                className="absolute w-7 h-12 bg-slate-800 border border-slate-600/60 rounded-lg flex items-center justify-center shadow-xl group-hover:border-blue-500/60 transition-colors"
                              >
                                <Move className="h-3.5 w-3.5 text-slate-400 rotate-90" />
                              </div>
                            </div>

                            {/* Version B panel */}
                            <div className="flex-1 relative border border-slate-700/40 rounded-r-xl overflow-hidden">
                              <div
                                className="absolute top-3 left-3 z-10 px-2 py-1 rounded text-[10px] font-mono font-semibold"
                                style={{
                                  background: 'rgba(2,44,34,0.85)',
                                  backdropFilter: 'blur(8px)',
                                  color: '#6ee7b7',
                                  border: '1px solid rgba(52,211,153,0.4)',
                                }}
                              >
                                CURR · v{vB?.version_number ?? 2}
                              </div>
                              {/* Change indicators */}
                              <div
                                className="absolute top-3 right-3 z-10 flex items-center gap-1 px-2 py-1 rounded text-[9px] font-mono"
                                style={{
                                  background: 'rgba(2,44,34,0.85)',
                                  color: '#34d399',
                                  border: '1px solid rgba(52,211,153,0.3)',
                                }}
                              >
                                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 inline-block" />
                                CHANGES DETECTED
                              </div>
                              <BlueprintMockB />
                            </div>
                          </div>
                        ) : (
                          // ── Overlay View ────────────────────────────────
                          <div className="relative h-full w-full overflow-hidden rounded-xl">
                            {/* Base layer (A) */}
                            <div className="absolute inset-0">
                              <BlueprintMockA />
                            </div>
                            {/* Top layer (B) — clipped by slider */}
                            <div
                              className="absolute inset-0 overflow-hidden"
                              style={{ width: `${cadSliderPos}%` }}
                            >
                              <div className="absolute inset-0" style={{ width: `${10000 / cadSliderPos}%` }}>
                                <BlueprintMockB />
                              </div>
                            </div>
                            {/* Slider line */}
                            <div
                              className="absolute top-0 bottom-0 w-0.5 bg-blue-400 cursor-ew-resize"
                              style={{ left: `${cadSliderPos}%` }}
                            >
                              <div className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 w-7 h-10 bg-slate-800 border border-blue-500/60 rounded-lg flex items-center justify-center shadow-xl">
                                <Move className="h-3.5 w-3.5 text-blue-400 rotate-90" />
                              </div>
                            </div>
                            {/* Slider input */}
                            <input
                              type="range" min="10" max="90" value={cadSliderPos}
                              onChange={e => setCadSliderPos(Number(e.target.value))}
                              className="absolute inset-0 w-full h-full opacity-0 cursor-ew-resize"
                            />
                            {/* Labels */}
                            <div
                              className="absolute top-3 left-3 z-10 px-2 py-1 rounded text-[10px] font-mono font-semibold"
                              style={{ background: 'rgba(15,23,42,0.85)', color: '#93c5fd', border: '1px solid rgba(96,165,250,0.4)' }}
                            >
                              PREV · v{vA?.version_number ?? 1}
                            </div>
                            <div
                              className="absolute top-3 right-3 z-10 px-2 py-1 rounded text-[10px] font-mono font-semibold"
                              style={{ background: 'rgba(2,44,34,0.85)', color: '#6ee7b7', border: '1px solid rgba(52,211,153,0.4)' }}
                            >
                              CURR · v{vB?.version_number ?? 2}
                            </div>
                          </div>
                        )}
                      </div>

                      {/* ── Pin Overlay — absolute, unaffected by zoom, above scaled content ── */}
                      <div className="absolute inset-0 z-30 pointer-events-none">
                        {/* Historical pins from saved corrections with [PIN:x,y] prefix */}
                        {historicalPins.map((pin: any, idx: number) => (
                          <div
                            key={pin.id}
                            className="absolute pointer-events-auto"
                            style={{ left: `${pin.x * 100}%`, top: `${pin.y * 100}%`, transform: 'translate(-50%, -100%)' }}
                            onClick={e => e.stopPropagation()}
                            title={`Round ${pin.round ?? '?'}: ${pin.note}`}
                          >
                            <div className="relative flex flex-col items-center">
                              <div
                                className="w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-bold text-white"
                                style={{ background: 'rgba(59,130,246,0.92)', border: '2px solid rgba(147,197,253,0.7)', boxShadow: '0 0 8px rgba(59,130,246,0.5)' }}
                              >
                                {pin.round ?? idx + 1}
                              </div>
                              <div className="w-0 h-0" style={{ borderLeft: '4px solid transparent', borderRight: '4px solid transparent', borderTop: '6px solid rgba(59,130,246,0.7)' }} />
                            </div>
                          </div>
                        ))}

                        {/* Session draft / in-flight / committed pins (filtered against historical to avoid duplicate render) */}
                        {redlinePins
                          .filter(p => !p.correctionId || !historicalPins.some((h: any) => h.correctionId === p.correctionId))
                          .map((pin, idx) => {
                          const isDraft = pin.status === 'draft';
                          const isSubmitting = pin.status === 'submitting';
                          const isActive = pin.id === activeDraftPinId;
                          const pinColor = isDraft || isSubmitting ? 'rgba(245,158,11,0.92)' : 'rgba(244,63,94,0.92)';
                          const pinBorder = isDraft || isSubmitting ? 'rgba(253,230,138,0.7)' : 'rgba(253,164,175,0.7)';
                          const pinGlow = isDraft || isSubmitting ? 'rgba(245,158,11,0.45)' : 'rgba(244,63,94,0.4)';
                          return (
                            <div
                              key={pin.id}
                              className="absolute pointer-events-auto"
                              style={{ left: `${pin.x * 100}%`, top: `${pin.y * 100}%`, transform: 'translate(-50%, -100%)' }}
                              onClick={e => e.stopPropagation()}
                            >
                              <div className="relative flex flex-col items-center">
                                <div
                                  className={`w-6 h-6 rounded-full flex items-center justify-center text-[9px] font-bold text-white cursor-pointer ${isSubmitting ? 'animate-pulse' : ''}`}
                                  style={{ background: pinColor, border: `2px solid ${pinBorder}`, boxShadow: `0 0 8px ${pinGlow}` }}
                                  onClick={() => {
                                    if (isDraft && !isSubmitting) {
                                      setActiveDraftPinId(isActive ? null : pin.id);
                                      setPinNoteInput(pin.note);
                                    }
                                  }}
                                >
                                  {pin.status === 'committed' ? (pin.round ?? '✓') : (isSubmitting ? '…' : idx + 1)}
                                </div>
                                <div className="w-0 h-0" style={{ borderLeft: '4px solid transparent', borderRight: '4px solid transparent', borderTop: `6px solid ${pinColor}` }} />

                                {/* Annotation popup for the active draft pin */}
                                {isActive && isDraft && (
                                  <div
                                    className="absolute bottom-full mb-2 left-1/2 -translate-x-1/2 w-64 rounded-xl p-3"
                                    style={{ background: '#0d1c32', border: '1px solid rgba(245,158,11,0.35)', boxShadow: '0 8px 32px rgba(0,0,0,0.55)', zIndex: 50 }}
                                  >
                                    <div className="flex items-center justify-between mb-2">
                                      <span className="text-[9px] font-mono font-semibold text-amber-400 uppercase tracking-widest">Redline Annotation</span>
                                      <button
                                        onClick={() => { setRedlinePins(prev => prev.filter(p => p.id !== pin.id)); setActiveDraftPinId(null); setPinNoteInput(''); setPinError(null); }}
                                        className="text-slate-500 hover:text-rose-400 transition-colors"
                                      ><X className="h-3 w-3" /></button>
                                    </div>
                                    <textarea
                                      id={`pin-note-${pin.id}`}
                                      value={pinNoteInput}
                                      onChange={e => { setPinNoteInput(e.target.value); setPinError(null); }}
                                      onKeyDown={e => { if (e.key === 'Enter' && (e.metaKey || e.ctrlKey)) handlePinSubmit(pin); }}
                                      placeholder="Describe the correction needed…"
                                      rows={3}
                                      autoFocus
                                      className="w-full bg-slate-900 text-slate-200 text-xs border border-slate-600/60 rounded-lg p-2 resize-none outline-none focus:border-amber-400/60 focus:ring-1 focus:ring-amber-400/20 placeholder:text-slate-600 font-mono"
                                    />
                                    {pinError && <p className="text-[9px] text-rose-400 font-mono mt-1">{pinError}</p>}
                                    <div className="flex items-center gap-2 mt-2">
                                      <button
                                        id="btn-pin-submit"
                                        onClick={() => handlePinSubmit(pin)}
                                        disabled={!pinNoteInput.trim() || pinSubmitting}
                                        className="flex-1 py-1.5 rounded-lg text-[10px] font-mono font-semibold disabled:opacity-40 disabled:cursor-not-allowed bg-amber-500/80 text-white hover:bg-amber-500 transition-colors"
                                      >
                                        {pinSubmitting ? 'Pinning…' : 'Pin Correction'}
                                      </button>
                                    </div>
                                    <p className="text-[8px] font-mono text-slate-600 mt-1.5 text-center">⌘↵ to submit · × to remove</p>
                                  </div>
                                )}
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    </div>

                    {/* Status bar */}
                    <div
                      className="px-5 py-2 flex items-center justify-between"
                      style={{
                        borderTop: '0.5px solid rgba(255,255,255,0.06)',
                        background: 'rgba(255,255,255,0.02)',
                      }}
                    >
                      <div className="flex items-center gap-4">
                        <span className="text-[10px] font-mono text-slate-500">
                          ZOOM: <span className="text-slate-300">{cadZoom}%</span>
                        </span>
                        <span className="text-[10px] font-mono text-slate-500">
                          MODE: <span className="text-slate-300 uppercase">{cadViewMode}</span>
                        </span>
                        <span className="text-[10px] font-mono text-slate-500">
                          VERSIONS: <span className="text-blue-400">v{vA?.version_number ?? 1}</span>
                          <span className="text-slate-600 mx-1">→</span>
                          <span className="text-emerald-400">v{vB?.version_number ?? 2}</span>
                        </span>
                      </div>
                      <span className="text-[9px] font-mono text-slate-600 tracking-wider">
                        UI/UX Design & Product Experience crafted by PixelMint Studio MVS
                      </span>
                    </div>
                  </div>

                  {/* ── Redline Annotations Card ── */}
                  <div
                    className="rounded-2xl border overflow-hidden mt-0"
                    style={{
                      background: allPins.length > 0 ? 'rgba(13,28,50,0.97)' : 'rgba(15,23,42,0.5)',
                      borderColor: allPins.length > 0 ? 'rgba(245,158,11,0.3)' : 'rgba(100,116,139,0.25)',
                      boxShadow: allPins.length > 0 ? '0 0 20px rgba(245,158,11,0.07)' : 'none',
                    }}
                  >
                    {/* Header */}
                    <div
                      className="px-4 py-3 flex items-center justify-between"
                      style={{ borderBottom: '1px solid rgba(255,255,255,0.06)' }}
                    >
                      <div className="flex items-center gap-2">
                        <MapPin className="h-3.5 w-3.5 text-amber-400" />
                        <p className="text-[10px] font-mono font-semibold text-slate-400 uppercase tracking-widest">REDLINE ANNOTATIONS</p>
                        {allPins.length > 0 && (
                          <span
                            className="px-1.5 py-0.5 rounded text-[9px] font-mono font-bold"
                            style={{ background: 'rgba(245,158,11,0.18)', color: '#fcd34d', border: '1px solid rgba(245,158,11,0.35)' }}
                          >
                            {allPins.length}
                          </span>
                        )}
                      </div>
                      {!redlineMode && (
                        <button onClick={() => setRedlineMode(true)} className="text-[9px] font-mono text-amber-400 hover:text-amber-300 transition-colors">
                          + Add Pin
                        </button>
                      )}
                    </div>

                    <div className="p-4">
                      {allPins.length === 0 ? (
                        <div className="text-center py-5">
                          <MapPin className="h-7 w-7 text-slate-700 mx-auto mb-2" />
                          <p className="text-[10px] font-mono text-slate-600">No redline annotations yet</p>
                          <p className="text-[9px] font-mono text-slate-700 mt-1">Toggle REDLINE above and click the drawing</p>
                        </div>
                      ) : (
                        <div className="space-y-2">
                          {allPins.map((pin, idx) => {
                            const isHistorical = !!pin.correctionId && pin.status === 'committed' && historicalPins.find((h: any) => h.id === pin.id);
                            const isDraftPin = pin.status === 'draft';
                            return (
                              <div
                                key={pin.id}
                                className="flex items-start gap-2.5 p-2.5 rounded-lg"
                                style={{
                                  background: isDraftPin ? 'rgba(245,158,11,0.08)' : isHistorical ? 'rgba(59,130,246,0.08)' : 'rgba(244,63,94,0.08)',
                                  border: `1px solid ${isDraftPin ? 'rgba(245,158,11,0.2)' : isHistorical ? 'rgba(59,130,246,0.2)' : 'rgba(244,63,94,0.18)'}`,
                                }}
                              >
                                {/* Round badge */}
                                <div
                                  className="w-5 h-5 rounded-full flex items-center justify-center text-[8px] font-bold text-white shrink-0 mt-0.5"
                                  style={{ background: isDraftPin ? 'rgba(245,158,11,0.8)' : isHistorical ? 'rgba(59,130,246,0.8)' : 'rgba(244,63,94,0.8)' }}
                                >
                                  {pin.round ?? idx + 1}
                                </div>
                                {/* Note text */}
                                <div className="flex-1 min-w-0">
                                  <p className="text-[10px] text-slate-300 font-mono leading-relaxed break-words">
                                    {pin.note || <span className="text-slate-600 italic">awaiting annotation…</span>}
                                  </p>
                                  <div className="flex items-center gap-2 mt-1">
                                    <span
                                      className="text-[8px] font-mono px-1 py-0.5 rounded"
                                      style={{ background: isDraftPin ? 'rgba(245,158,11,0.15)' : 'rgba(255,255,255,0.06)', color: isDraftPin ? '#fcd34d' : '#94a3b8' }}
                                    >
                                      {isDraftPin ? 'DRAFT' : pin.status === 'submitting' ? 'SAVING…' : 'SAVED'}
                                    </span>
                                    {pin.round && <span className="text-[8px] font-mono text-slate-600">Round {pin.round}</span>}
                                    <span className="text-[8px] font-mono text-slate-700">({(pin.x * 100).toFixed(0)}%, {(pin.y * 100).toFixed(0)}%)</span>
                                  </div>
                                </div>
                                {/* Dismiss draft */}
                                {isDraftPin && (
                                  <button
                                    onClick={() => { setRedlinePins(prev => prev.filter(p => p.id !== pin.id)); if (activeDraftPinId === pin.id) setActiveDraftPinId(null); }}
                                    className="text-slate-600 hover:text-rose-400 transition-colors shrink-0"
                                  ><X className="h-3 w-3" /></button>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="mt-4 flex items-center gap-6 px-1">
                    <div className="flex items-center gap-2">
                      <div className="w-3 h-3 rounded-sm" style={{ background: 'rgba(96,165,250,0.2)', border: '1px solid rgba(96,165,250,0.5)' }} />
                      <span className="text-[10px] font-mono text-slate-500">UNCHANGED ELEMENTS</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-3 h-3 rounded-sm" style={{ background: 'rgba(52,211,153,0.2)', border: '1px solid rgba(52,211,153,0.5)' }} />
                      <span className="text-[10px] font-mono text-slate-500">MODIFIED / ADDED</span>
                    </div>
                    <div className="flex items-center gap-2">
                      <div className="w-3 h-3 rounded-sm" style={{ background: 'rgba(251,113,133,0.2)', border: '1px solid rgba(251,113,133,0.5)' }} />
                      <span className="text-[10px] font-mono text-slate-500">REMOVED</span>
                    </div>
                  </div>
                </div>

                {/* Side Panel */}
                <div className="lg:col-span-4 flex flex-col gap-4">
                  {/* Metadata Card */}
                  <div className="bg-white border border-slate-200 rounded-2xl p-6 soft-elevation">
                    <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest mb-4">DRAWING DETAILS</p>
                    <div className="space-y-3">
                      <div>
                        <p className="text-[10px] font-mono text-slate-500 mb-1">PROJECT</p>
                        <p className="text-xs font-semibold text-slate-900 truncate">{project.project_name}</p>
                      </div>
                      <div className="border-t border-slate-100 pt-3">
                        <p className="text-[10px] font-mono text-slate-500 mb-1">DRAWING TYPE</p>
                        <p className="text-xs text-slate-700 font-medium">{project.drawing_type || 'Floor Plan'}</p>
                      </div>
                      <div className="border-t border-slate-100 pt-3">
                        <p className="text-[10px] font-mono text-slate-500 mb-1">TOTAL VERSIONS</p>
                        <p className="text-xs font-semibold text-[#0453cd] font-mono">{versionList.length} version{versionList.length !== 1 ? 's' : ''}</p>
                      </div>
                      <div className="border-t border-slate-100 pt-3">
                        <p className="text-[10px] font-mono text-slate-500 mb-1">COMPARING</p>
                        <div className="flex items-center gap-2">
                          <span className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold" style={{ background: 'rgba(96,165,250,0.15)', color: '#1d4ed8', border: '1px solid rgba(96,165,250,0.3)' }}>
                            v{vA?.version_number ?? 1}
                          </span>
                          <span className="text-slate-400 text-xs">→</span>
                          <span className="px-2 py-0.5 rounded text-[10px] font-mono font-semibold" style={{ background: 'rgba(52,211,153,0.15)', color: '#047857', border: '1px solid rgba(52,211,153,0.3)' }}>
                            v{vB?.version_number ?? 2}
                          </span>
                        </div>
                      </div>
                      {project.draughtsman_name && (
                        <div className="border-t border-slate-100 pt-3">
                          <p className="text-[10px] font-mono text-slate-500 mb-1">DRAUGHTSMAN</p>
                          <p className="text-xs font-semibold text-slate-900">{project.draughtsman_name}</p>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Activity log */}
                  <div className="bg-white border border-slate-200 rounded-2xl p-6 soft-elevation flex-1">
                    <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest mb-4">VERSION AUDIT LOG</p>
                    {versionList.length === 0 ? (
                      <p className="text-xs text-slate-400 text-center py-6 font-mono">No drawing versions yet</p>
                    ) : (
                      <div className="relative pl-4 space-y-5" style={{ borderLeft: '1px solid #e2e8f0' }}>
                        {versionList.slice().reverse().map((v, i) => (
                          <div key={v.id} className="relative">
                            <div
                              className="absolute -left-[21px] top-1 w-2.5 h-2.5 rounded-full"
                              style={{
                                background: i === 0 ? '#0453cd' : '#94a3b8',
                                boxShadow: i === 0 ? '0 0 0 3px rgba(4,83,205,0.2)' : 'none',
                                border: '2px solid #ffffff',
                              }}
                            />
                            <p className="text-[10px] font-mono text-slate-400 mb-0.5">
                              {formatDateTime(v.created_at)}
                            </p>
                            <p className="text-xs font-semibold text-slate-900">
                              Version {v.version_number} {i === 0 ? 'Committed' : 'Archived'}
                            </p>
                            <p className="text-[10px] text-slate-500 mt-0.5 truncate font-mono">
                              {v.original_name || `CAD Drawing v${v.version_number}`}
                            </p>
                            {i === 0 && (
                              <div
                                className="mt-2 px-2 py-0.5 rounded text-[9px] font-mono font-semibold w-fit"
                                style={{ background: '#eff6ff', color: '#1d4ed8', border: '1px solid #bfdbfe' }}
                              >
                                CURRENT VERSION
                              </div>
                            )}
                          </div>
                        ))}
                      </div>
                    )}
                  </div>

                  {/* Download CTA */}
                  {vB?.file_id && (
                    <button
                      type="button"
                      onClick={() => handleDownloadFile(vB.file_id!, vB.original_name || vB.sanitized_name || `drawing_v${vB.version_number}.dwg`)}
                      disabled={downloadingFileId === vB.file_id}
                      className="flex items-center justify-center gap-2 w-full py-3 rounded-xl text-xs font-semibold font-mono text-white transition-all bg-[#0d1c32] hover:bg-[#1a2d4b] disabled:opacity-50 shadow-xs cursor-pointer"
                    >
                      {downloadingFileId === vB.file_id ? (
                        <Loader2 className="h-4 w-4 animate-spin" />
                      ) : (
                        <Download className="h-4 w-4" />
                      )}
                      <span>
                        {downloadingFileId === vB.file_id
                          ? 'Downloading...'
                          : `Download Current Version (v${vB.version_number})`}
                      </span>
                    </button>
                  )}
                </div>
              </div>
            );
          })()}

          {/* ─── Tab: Collaboration Hub ──────────────────────────────────────── */}
          {activeTab === 'collab' && (() => {
            const getRoleColor = (role?: string) => {
              const r = (role || '').toUpperCase();
              switch (r) {
                case 'ADMIN':
                case 'STUDIO_ADMIN':
                  return { bg: 'rgba(139,92,246,0.15)', text: '#7c3aed', border: 'rgba(139,92,246,0.3)', label: 'Admin' };
                case 'DRAUGHTSMAN':
                  return { bg: 'rgba(6,182,212,0.15)', text: '#0891b2', border: 'rgba(6,182,212,0.3)', label: 'Draughtsman' };
                case 'CLIENT':
                case 'ENGINEER':
                  return { bg: 'rgba(59,130,246,0.15)', text: '#2563eb', border: 'rgba(59,130,246,0.3)', label: 'Engineer' };
                case 'STUDENT':
                  return { bg: 'rgba(16,185,129,0.15)', text: '#059669', border: 'rgba(16,185,129,0.3)', label: 'Student' };
                default:
                  return { bg: 'rgba(148,163,184,0.15)', text: '#64748b', border: 'rgba(148,163,184,0.3)', label: r || 'User' };
              }
            };

            const getInitial = (name: string) => name.charAt(0).toUpperCase();

            const handleSend = async () => {
              if ((!collabInput.trim() && !collabAttachment) || collabSending) return;
              setCollabSending(true);
              setCollabError(null);
              try {
                let attachmentFileId: string | undefined;

                if (collabAttachment) {
                  // Upload reference document or voice attachment to Cloudflare R2 via shared file service
                  const uploaded = await adminApi.uploadProjectFile(projectId, collabAttachment, 'chat_attachment');
                  attachmentFileId = uploaded.id;
                }

                const res = await adminApi.createProjectComment(projectId, {
                  content: collabInput.trim() || (collabAttachment ? `[Attachment] ${collabAttachment.name}` : ''),
                  attachmentFileId,
                });
                setCollabMessages(prev => [...prev, toCollabMessage(res.comment)]);
                setCollabInput('');
                setCollabAttachment(null);
              } catch (err: any) {
                setCollabError(err.message || 'Failed to post message to persistent collaboration hub');
              } finally {
                setCollabSending(false);
              }
            };

            return (
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6" style={{ height: '680px' }}>
                {/* Main chat panel */}
                <div className="lg:col-span-8 flex flex-col rounded-2xl border border-slate-200 overflow-hidden bg-white soft-elevation">
                  {/* Panel header */}
                  <div className="px-5 py-3.5 flex items-center justify-between gap-4 shrink-0 bg-slate-50/80 border-b border-slate-200">
                    <div className="flex items-center gap-3">
                      <MessageSquare className="h-4 w-4 text-[#0453cd]" />
                      <div>
                        <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest">COLLABORATION HUB</p>
                        <p className="text-xs font-semibold text-slate-900 truncate max-w-[240px]">
                          {project.project_name}
                          <span className="ml-2 text-[10px] font-mono text-slate-500">#{project.id.substring(0, 8)}</span>
                        </p>
                      </div>
                    </div>
                    <div className="flex items-center gap-2">
                      {/* Online indicator */}
                      <div className="flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-emerald-50 border border-emerald-200">
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
                        <span className="text-[9px] font-mono text-emerald-700 font-semibold">LIVE WORKSPACE</span>
                      </div>
                      <button className="p-1.5 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors">
                        <Filter className="h-3.5 w-3.5" />
                      </button>
                      <button className="p-1.5 rounded-md text-slate-400 hover:text-slate-700 hover:bg-slate-100 transition-colors">
                        <MoreVertical className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>

                  {/* Messages area */}
                  <div className="flex-1 overflow-y-auto p-5 space-y-6 bg-[#fbf9fb]"
                    style={{
                      backgroundImage: `
                        linear-gradient(to right, rgba(0,0,0,0.02) 1px, transparent 1px),
                        linear-gradient(to bottom, rgba(0,0,0,0.02) 1px, transparent 1px)
                      `,
                      backgroundSize: '40px 40px',
                    }}
                  >
                    {collabMessages.length === 0 ? (
                      <div className="flex flex-col items-center justify-center py-24 text-center">
                        <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center text-slate-400 mb-3 border border-slate-200">
                          <MessageSquare className="h-6 w-6 text-slate-400" />
                        </div>
                        <p className="text-xs font-semibold text-slate-800">No project comments yet</p>
                        <p className="text-[11px] font-mono text-slate-500 max-w-sm mt-1">
                          Persistent project discussions between Studio Admin, Draughtsman, and Engineer are recorded here and logged to the project audit trail.
                        </p>
                      </div>
                    ) : (
                      <>
                        {/* Date divider */}
                        <div className="flex items-center gap-4">
                          <div className="h-px flex-1 bg-slate-200" />
                          <span className="text-[10px] font-mono text-slate-400 uppercase tracking-wider font-semibold">Discussion History</span>
                          <div className="h-px flex-1 bg-slate-200" />
                        </div>

                        {/* Messages */}
                        {collabMessages.map((msg) => {
                          const rc = getRoleColor(msg.role);
                          const timeStr = formatTime(msg.timestamp);
                          const isAdmin = msg.role === 'ADMIN';
                          return (
                            <div key={msg.id} className="flex gap-3 group">
                              {/* Avatar */}
                              <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold shrink-0 mt-0.5"
                                style={{ background: rc.bg, color: rc.text, border: `1px solid ${rc.border}` }}
                              >
                                {getInitial(msg.author)}
                              </div>

                              <div className="flex-1 space-y-1.5">
                                {/* Author + time */}
                                <div className="flex items-baseline gap-2">
                                  <span className="text-xs font-semibold text-slate-900">{msg.author}</span>
                                  <span className="text-[9px] font-mono px-1.5 py-0.5 rounded font-semibold"
                                    style={{ background: rc.bg, color: rc.text, border: `1px solid ${rc.border}` }}
                                  >
                                    {rc.label}
                                  </span>
                                  <span className="text-[10px] font-mono text-slate-400">{timeStr}</span>
                                </div>

                                {/* Message bubble */}
                                <div className={`p-3.5 rounded-xl rounded-tl-sm text-xs leading-relaxed ${
                                  isAdmin
                                    ? 'bg-blue-50/70 border border-blue-200 text-slate-800'
                                    : 'bg-white border border-slate-200 text-slate-800 shadow-xs'
                                }`}>
                                  {/* Render @mentions */}
                                  {msg.content.split(/(@\w[\w.]*)/g).map((part, i) =>
                                    part.startsWith('@') ? (
                                      <span key={i} className="text-[#0453cd] font-semibold">{part}</span>
                                    ) : (
                                      <span key={i}>{part}</span>
                                    )
                                  )}

                                  {/* Voice note / audio playback */}
                                  {msg.isVoice && (
                                    <div className="mt-3 flex flex-col gap-1.5 p-2.5 rounded-xl max-w-xs bg-slate-100 border border-slate-200">
                                      <div className="flex items-center gap-2">
                                        <Volume2 className="h-4 w-4 text-[#0453cd] shrink-0" />
                                        <span className="text-[10px] font-mono font-semibold text-slate-700">Audio Note</span>
                                        {msg.attachment?.size && (
                                          <span className="text-[9px] font-mono text-slate-400 ml-auto">{msg.attachment.size}</span>
                                        )}
                                      </div>
                                      {msg.attachment?.downloadUrl ? (
                                        <audio
                                          controls
                                          preload="metadata"
                                          src={msg.attachment.downloadUrl}
                                          className="w-full h-8 mt-1"
                                        />
                                      ) : (
                                        <p className="text-[9px] font-mono text-slate-500 italic">Audio recording unavailable</p>
                                      )}
                                    </div>
                                  )}

                                  {/* File attachment */}
                                  {msg.attachment && !msg.isVoice && (
                                    <button
                                      type="button"
                                      onClick={() => {
                                        if (msg.attachment?.fileId) {
                                          handleDownloadFile(msg.attachment.fileId, msg.attachment.name);
                                        }
                                      }}
                                      disabled={msg.attachment?.fileId ? downloadingFileId === msg.attachment.fileId : false}
                                      className="mt-3 flex items-center gap-3 p-2.5 rounded-lg w-fit pr-4 bg-slate-50 border border-slate-200 hover:bg-slate-100 disabled:opacity-50 transition-colors text-inherit no-underline group/att cursor-pointer text-left"
                                    >
                                      <div className="p-1.5 rounded-md"
                                        style={{
                                          background: msg.attachment.type === 'pdf' ? '#fee2e2' : '#dbeafe',
                                        }}
                                      >
                                        <FileArchive className="h-4 w-4"
                                          style={{ color: msg.attachment.type === 'pdf' ? '#dc2626' : '#1d4ed8' }}
                                        />
                                      </div>
                                      <div className="min-w-0">
                                        <p className="text-[10px] font-mono text-slate-900 font-semibold group-hover/att:text-[#0453cd] transition-colors truncate max-w-[200px]">
                                          {msg.attachment.name}
                                        </p>
                                        <p className="text-[9px] font-mono text-slate-500">{msg.attachment.size}</p>
                                      </div>
                                      {msg.attachment?.fileId && downloadingFileId === msg.attachment.fileId ? (
                                        <Loader2 className="h-3.5 w-3.5 text-[#0453cd] animate-spin ml-2 shrink-0" />
                                      ) : (
                                        <Download className="h-3.5 w-3.5 text-slate-400 group-hover/att:text-slate-700 transition-colors ml-2 shrink-0" />
                                      )}
                                    </button>
                                  )}
                                </div>

                                {/* Thread reply indicator */}
                                {msg.replyCount && msg.replyCount > 0 ? (
                                  <button className="flex items-center gap-1.5 text-[10px] font-mono text-[#0453cd] hover:text-blue-800 transition-colors pl-1 font-semibold">
                                    <div className="w-4 h-px bg-blue-300" />
                                    {msg.replyCount} {msg.replyCount === 1 ? 'reply' : 'replies'}
                                  </button>
                                ) : null}
                              </div>
                            </div>
                          );
                        })}
                      </>
                    )}
                  </div>

                    {/* Message input */}
                  <div className="p-4 shrink-0 border-t border-slate-200 bg-slate-50/70">
                    {collabError && (
                      <div className="mb-3 p-2.5 rounded-xl bg-rose-50 border border-rose-200 flex items-center justify-between text-xs text-rose-800">
                        <div className="flex items-center gap-2">
                          <AlertTriangle className="h-4 w-4 text-rose-600 shrink-0" />
                          <span>{collabError}</span>
                        </div>
                        <button
                          onClick={() => setCollabError(null)}
                          className="text-[10px] font-mono font-semibold text-rose-600 hover:text-rose-800 underline ml-2"
                        >
                          Dismiss
                        </button>
                      </div>
                    )}

                    {/* Pending Attachment Chip */}
                    {collabAttachment && (
                      <div className="mb-2 px-3 py-1.5 rounded-lg bg-blue-50 border border-blue-200 flex items-center justify-between text-xs text-blue-900">
                        <div className="flex items-center gap-2 truncate">
                          <Paperclip className="h-3.5 w-3.5 text-blue-600 shrink-0" />
                          <span className="font-semibold truncate">{collabAttachment.name}</span>
                          <span className="text-[10px] text-blue-600 font-mono shrink-0">
                            ({(collabAttachment.size / (1024 * 1024)).toFixed(2)} MB)
                          </span>
                        </div>
                        <button
                          type="button"
                          onClick={() => setCollabAttachment(null)}
                          className="text-slate-400 hover:text-rose-500 p-1"
                        >
                          <X className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    )}

                    <div className="flex items-end gap-2 rounded-xl p-2 bg-white border border-slate-200 shadow-xs focus-within:border-[#0453cd]">
                      <input
                        type="file"
                        ref={collabFileInputRef}
                        className="hidden"
                        accept=".pdf,.dwg,.dxf,.png,.jpg,.jpeg,.zip,.webm,.m4a,.mp3,.wav,.aac,.ogg"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            if (file.size > 50 * 1024 * 1024) {
                              setCollabError('Attached file exceeds 50MB limit');
                              return;
                            }
                            setCollabAttachment(file);
                            setCollabError(null);
                          }
                          e.target.value = '';
                        }}
                      />
                      <button
                        type="button"
                        onClick={() => collabFileInputRef.current?.click()}
                        title="Attach reference document (PDF, DWG, DXF, images up to 50MB)"
                        className={`p-2 transition-colors rounded-lg ${collabAttachment ? 'text-[#0453cd] bg-blue-50 hover:bg-blue-100' : 'text-slate-400 hover:text-slate-600 hover:bg-slate-100'}`}
                      >
                        <Paperclip className="h-4 w-4" />
                      </button>
                      <textarea
                        value={collabInput}
                        onChange={e => setCollabInput(e.target.value)}
                        onKeyDown={e => { if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); handleSend(); } }}
                        placeholder={collabAttachment ? "Add a note with this file (optional)..." : "Type a message or use @ to mention..."}
                        rows={1}
                        className="flex-1 bg-transparent border-none outline-none resize-none text-xs text-slate-900 placeholder:text-slate-400 font-mono py-2 leading-relaxed"
                        style={{ maxHeight: '120px', minHeight: '36px' }}
                      />
                      <div className="flex items-center gap-1 pb-1">
                        <button
                          onClick={handleSend}
                          disabled={(!collabInput.trim() && !collabAttachment) || collabSending}
                          className="p-2 rounded-lg text-white transition-all disabled:opacity-40 bg-[#0d1c32] hover:bg-[#1a2d4b] flex items-center justify-center"
                        >
                          {collabSending ? (
                            <div className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                          ) : (
                            <Send className="h-4 w-4" />
                          )}
                        </button>
                      </div>
                    </div>
                    <p className="text-[9px] font-mono text-slate-400 mt-1.5 pl-1">
                      <span className="text-slate-600 font-semibold">↵ Send</span> · <span className="text-slate-600 font-semibold">Shift+↵ Newline</span> · Messages are logged to the immutable audit trail
                    </p>
                  </div>
                </div>

                {/* Right panel */}
                <div className="lg:col-span-4 flex flex-col gap-4">
                  {/* Participants card */}
                  <div className="bg-white border border-slate-200 rounded-2xl p-5 soft-elevation">
                    <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest mb-4">PARTICIPANTS</p>
                    <div className="space-y-3">
                      {(
                        [
                          { label: 'Studio Admin', role: 'ADMIN', status: 'online', note: 'You', href: undefined },
                          {
                            label: project.draughtsman_name || 'Draughtsman',
                            role: 'DRAUGHTSMAN',
                            status: project.draughtsman_name ? 'online' : 'unassigned',
                            note: undefined,
                            href: project.draughtsman_id ? `/draughtsmen/${encodeURIComponent(project.draughtsman_id)}` : undefined,
                          },
                          {
                            label: project.client_name || 'Engineer',
                            role: 'ENGINEER',
                            status: 'online',
                            note: undefined,
                            href: project.client_id ? `/engineers/${encodeURIComponent(project.client_id)}` : undefined,
                          },
                        ] as Array<{ label: string; role: any; status: string; note?: string; href?: string }>
                      ).map((p) => {
                        const rc = getRoleColor(p.role);
                        return (
                          <div key={p.label} className="flex items-center gap-3">
                            <div className="relative">
                              <div className="w-8 h-8 rounded-full flex items-center justify-center text-xs font-bold"
                                style={{ background: rc.bg, color: rc.text, border: `1px solid ${rc.border}` }}
                              >
                                {getInitial(p.label)}
                              </div>
                              {p.status === 'online' && (
                                <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-emerald-500 border-2 border-white" />
                              )}
                            </div>
                            <div className="flex-1 min-w-0">
                              {p.href ? (
                                <Link
                                  href={p.href}
                                  className="text-xs font-semibold text-slate-900 truncate hover:text-[#0453cd] hover:underline block"
                                  title={`View ${p.label} profile`}
                                >
                                  {p.label}
                                  {p.note && <span className="ml-1 text-[9px] text-slate-500 font-normal">({p.note})</span>}
                                </Link>
                              ) : (
                                <p className="text-xs font-semibold text-slate-900 truncate">
                                  {p.label}
                                  {p.note && <span className="ml-1 text-[9px] text-slate-500 font-normal">({p.note})</span>}
                                </p>
                              )}
                              <p className="text-[9px] font-mono font-semibold" style={{ color: rc.text }}>{rc.label}</p>
                            </div>
                            <span className={`text-[9px] font-mono font-semibold ${p.status === 'online' ? 'text-emerald-600' : 'text-slate-400'}`}>
                              {p.status === 'unassigned' ? 'UNASSIGNED' : p.status === 'online' ? '● ONLINE' : '○ OFFLINE'}
                            </span>
                          </div>
                        );
                      })}
                    </div>
                  </div>

                  {/* Project context card */}
                  <div className="bg-white border border-slate-200 rounded-2xl p-5 soft-elevation">
                    <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest mb-4">PROJECT CONTEXT</p>
                    <div className="space-y-3">
                      <div>
                        <p className="text-[10px] font-mono text-slate-500 mb-0.5">PROJECT</p>
                        <p className="text-xs font-semibold text-slate-900 truncate">{project.project_name}</p>
                      </div>
                      <div className="border-t border-slate-100 pt-3">
                        <p className="text-[10px] font-mono text-slate-500 mb-0.5">STATUS</p>
                        <Badge status={project.status} size="sm" />
                      </div>
                      <div className="border-t border-slate-100 pt-3">
                        <p className="text-[10px] font-mono text-slate-500 mb-0.5">DRAWING TYPE</p>
                        <p className="text-xs text-slate-800 font-medium">{project.drawing_type || 'N/A'}</p>
                      </div>
                      {project.correction_round > 0 && (
                        <div className="border-t border-slate-100 pt-3">
                          <p className="text-[10px] font-mono text-slate-500 mb-0.5">CORRECTION ROUND</p>
                          <p className="text-xs font-semibold text-[#0453cd] font-mono">{project.correction_round} / 3</p>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Message count summary */}
                  <div className="bg-white border border-slate-200 rounded-2xl p-5 soft-elevation flex-1">
                    <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest mb-4">MESSAGE SUMMARY</p>
                    <div className="space-y-3">
                      {(['ADMIN', 'DRAUGHTSMAN', 'ENGINEER', 'STUDENT'] as const).map(role => {
                        const rc = getRoleColor(role);
                        const count = collabMessages.filter(m => m.role === role || (role === 'ENGINEER' && m.role === 'CLIENT')).length;
                        return (
                          <div key={role} className="flex items-center gap-3">
                            <div className="flex-1">
                              <div className="flex items-center justify-between mb-1">
                                <span className="text-[10px] font-mono font-semibold" style={{ color: rc.text }}>{rc.label}</span>
                                <span className="text-[10px] font-mono text-slate-500">{count} msg{count !== 1 ? 's' : ''}</span>
                              </div>
                              <div className="h-1.5 rounded-full bg-slate-100 overflow-hidden">
                                <div className="h-full rounded-full transition-all duration-500"
                                  style={{
                                    width: `${collabMessages.length > 0 ? (count / collabMessages.length) * 100 : 0}%`,
                                    background: rc.text,
                                  }}
                                />
                              </div>
                            </div>
                          </div>
                        );
                      })}
                      <div className="border-t border-slate-100 pt-3 flex justify-between">
                        <span className="text-[10px] font-mono text-slate-500">TOTAL MESSAGES</span>
                        <span className="text-[10px] font-mono text-slate-900 font-bold">{collabMessages.length}</span>
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })()}

          {/* Tab 1: Overview */}
          {activeTab === 'overview' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Card className="bg-white border-slate-200 soft-elevation">
                <CardHeader title="Project Metadata & Specifications" />
                <div className="space-y-3 text-xs divide-y divide-slate-100">
                  <div className="pt-2 flex justify-between items-center">
                    <span className="text-slate-500 font-mono">Project ID</span>
                    <span className="font-mono bg-slate-100 text-slate-800 px-2 py-0.5 rounded border border-slate-200">{project.id}</span>
                  </div>
                  <div className="pt-2 flex justify-between items-center">
                    <span className="text-slate-500 font-mono">Ordering Engineer</span>
                    <Link
                      href={`/engineers/${encodeURIComponent(project.client_id)}`}
                      className="font-semibold text-[#0453cd] hover:underline"
                    >
                      {project.client_name ? `${project.client_name} (${project.client_id.substring(0, 8)})` : project.client_id}
                    </Link>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Project Name</span>
                    <span className="font-semibold text-slate-900">{project.project_name || 'N/A'}</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Drawing Name</span>
                    <span className="text-slate-800 font-medium">{project.drawing_name || 'N/A'}</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Drawing Type</span>
                    <span className="text-slate-800 font-medium">{project.drawing_type || 'N/A'}</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Project Area</span>
                    <span className="text-slate-800 font-mono">{project.project_area || 'Standard'} sq.ft</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Project Address</span>
                    <span className="text-slate-800 text-right max-w-xs">{project.project_address || 'N/A'}</span>
                  </div>
                </div>
              </Card>

              <Card className="bg-white border-slate-200 soft-elevation">
                <CardHeader title="Operational Lifecycle & Timestamps" />
                <div className="space-y-3 text-xs divide-y divide-slate-100">
                  <div className="pt-2 flex justify-between items-center">
                    <span className="text-slate-500 font-mono">Assigned Draughtsman</span>
                    {project.draughtsman_id ? (
                      <Link
                        href={`/draughtsmen/${encodeURIComponent(project.draughtsman_id)}`}
                        className="font-semibold text-[#0453cd] hover:underline"
                      >
                        {project.draughtsman_name || project.draughtsman_id}
                      </Link>
                    ) : (
                      <span className="font-semibold text-slate-400 italic">None Assigned</span>
                    )}
                  </div>
                  <div className="pt-2 flex justify-between items-center">
                    <span className="text-slate-500 font-mono">Draughtsman ID</span>
                    {project.draughtsman_id ? (
                      <Link
                        href={`/draughtsmen/${encodeURIComponent(project.draughtsman_id)}`}
                        className="font-mono bg-blue-50 text-[#0453cd] px-1.5 py-0.5 rounded border border-blue-200 hover:underline"
                      >
                        {project.draughtsman_id}
                      </Link>
                    ) : (
                      <span className="font-mono bg-slate-100 text-slate-400 px-1.5 py-0.5 rounded border border-slate-200">
                        N/A
                      </span>
                    )}
                  </div>
                  <div className="pt-2 flex justify-between items-center">
                    <span className="text-slate-500 font-mono">Current Assignment ID</span>
                    <span className="font-mono bg-slate-100 text-slate-700 px-1.5 py-0.5 rounded border border-slate-200">
                      {project.current_assignment_id || 'N/A'}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Correction Round</span>
                    <span className="font-semibold font-mono text-[#0453cd]">{project.correction_round} of 3</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Submitted At</span>
                    <span className="text-slate-800 font-mono">
                      {formatDateTime(project.submitted_at)}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-500 font-mono">Approved At</span>
                    <span className="text-slate-800 font-mono">
                      {formatDateTime(project.approved_at)}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between items-center">
                    <span className="text-slate-500 font-mono">Last Action ID</span>
                    <span className="font-mono text-slate-400 text-[11px]">{project.last_action_id || 'N/A'}</span>
                  </div>
                </div>
              </Card>
            </div>
          )}

          {/* Tab 2: Reference Files */}
          {activeTab === 'files' && (
            <Card className="bg-white border-slate-200 soft-elevation">
              <CardHeader
                title="Engineer Reference Materials & Uploads"
                subtitle="Documents, sketches, and reference files stored securely in Cloudflare R2"
              />

              {downloadError && (
                <div className="mx-6 mt-4 p-3 bg-red-50 border border-red-200 text-red-700 text-xs rounded-lg flex items-center justify-between font-mono">
                  <div className="flex items-center gap-2">
                    <AlertCircle className="h-4 w-4 shrink-0 text-red-600" />
                    <span>{downloadError}</span>
                  </div>
                  <button onClick={() => setDownloadError(null)} className="text-red-500 hover:text-red-700 font-bold ml-2">×</button>
                </div>
              )}

              {files.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400 font-mono">
                  No reference files uploaded by engineer yet.
                </div>
              ) : (
                <div className="divide-y divide-slate-100">
                  {files.map((file) => (
                    <div
                      key={file.id}
                      className="py-3.5 flex items-center justify-between gap-4 hover:bg-slate-50 px-2 rounded-xl transition-colors"
                    >
                      <div className="flex items-center gap-3 overflow-hidden">
                        <div className="p-2 rounded-lg bg-blue-50 text-[#0453cd] border border-blue-200 shrink-0">
                          <FileText className="h-4 w-4" />
                        </div>
                        <div className="overflow-hidden">
                          <p className="text-xs font-semibold text-slate-900 truncate">
                            {file.original_name || file.sanitized_name}
                          </p>
                          <p className="text-[10px] text-slate-500 font-mono">
                            {formatFileSize(file.size)} &bull; {file.content_type} &bull; Category:{' '}
                            <span className="font-mono text-slate-700 font-semibold">{file.category}</span>
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 shrink-0">
                        <span className="text-[10px] text-slate-400 font-mono">
                          {formatDate(file.created_at)}
                        </span>
                        <button
                          type="button"
                          onClick={() => handleDownloadFile(file.id, file.original_name || file.sanitized_name)}
                          disabled={downloadingFileId === file.id}
                          className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-mono font-medium text-[#0453cd] hover:text-blue-800 bg-blue-50 hover:bg-blue-100 disabled:opacity-50 border border-blue-200 rounded-lg transition-colors cursor-pointer"
                        >
                          {downloadingFileId === file.id ? (
                            <Loader2 className="h-3 w-3 animate-spin" />
                          ) : (
                            <Download className="h-3 w-3" />
                          )}
                          <span>{downloadingFileId === file.id ? 'Downloading...' : 'Download'}</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          )}

          {/* Tab 3: Drawing Versions */}
          {activeTab === 'drawings' && (
            <Card className="bg-white border-slate-200 soft-elevation">
              <CardHeader
                title="Draughtsman Drawing Deliverables"
                subtitle="CAD / PDF versions submitted by assigned draughtsmen"
              />

              {drawingVersions.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400 font-mono">
                  No drawing versions submitted yet. Once the assigned draughtsman submits drawings, they appear here.
                </div>
              ) : (
                <div className="divide-y divide-slate-100">
                  {drawingVersions.map((dv) => (
                    <div
                      key={dv.id}
                      className="py-4 flex items-center justify-between gap-4 hover:bg-slate-50 px-2 rounded-xl transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className="h-9 w-9 rounded-xl bg-blue-50 text-[#0453cd] border border-blue-200 flex items-center justify-center font-bold text-xs font-mono shrink-0">
                          v{dv.version_number}
                        </div>
                        <div>
                          <p className="text-xs font-semibold text-slate-900">
                            Version {dv.version_number}: {dv.original_name || 'CAD Drawing Deliverable'}
                          </p>
                          <p className="text-[10px] text-slate-500 mt-0.5 font-mono">
                            Uploaded by Draughtsman ID: <code className="font-mono bg-slate-100 px-1 py-0.5 rounded border border-slate-200">{dv.uploaded_by.substring(0, 8)}</code>
                            {dv.size ? ` • ${formatFileSize(dv.size)}` : ''}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 shrink-0">
                        <span className="text-[10px] text-slate-400 font-mono">
                          {formatDateTime(dv.created_at)}
                        </span>
                        {dv.file_id && (
                          <button
                            type="button"
                            onClick={() => handleDownloadFile(dv.file_id!, dv.original_name || dv.sanitized_name || `drawing_v${dv.version_number}.dwg`)}
                            disabled={downloadingFileId === dv.file_id}
                            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-mono font-medium text-[#0453cd] hover:text-blue-800 bg-blue-50 hover:bg-blue-100 disabled:opacity-50 border border-blue-200 rounded-lg transition-colors cursor-pointer"
                          >
                            {downloadingFileId === dv.file_id ? (
                              <Loader2 className="h-3 w-3 animate-spin" />
                            ) : (
                              <Download className="h-3 w-3" />
                            )}
                            <span>{downloadingFileId === dv.file_id ? 'Downloading...' : `Download v${dv.version_number}`}</span>
                          </button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          )}

          {/* Tab 4: Corrections */}
          {activeTab === 'corrections' && (
            <Card className="bg-white border-slate-200 soft-elevation">
              <CardHeader
                title="Engineer Revision & Correction Rounds"
                subtitle="Maximum limit of 3 rounds enforced strictly by the Cloudflare Worker"
              />

              {corrections.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400 font-mono">
                  No correction rounds requested for this project.
                </div>
              ) : (
                <div className="space-y-4">
                  {corrections.map((corr) => (
                    <div
                      key={corr.id}
                      className="p-4 rounded-xl bg-slate-50 border border-slate-200 space-y-2"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold font-mono text-[#0453cd]">
                            Round {corr.round_number} of 3
                          </span>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-semibold border ${
                              corr.status === 'RESOLVED'
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                : corr.status === 'IN_PROGRESS'
                                ? 'bg-blue-50 text-blue-700 border-blue-200'
                                : 'bg-amber-50 text-amber-700 border-amber-200'
                            }`}
                          >
                            {corr.status}
                          </span>
                        </div>
                        <span className="text-[10px] text-slate-400 font-mono">
                          {formatDateTime(corr.created_at)}
                        </span>
                      </div>
                      <p className="text-xs text-slate-800 leading-relaxed bg-white p-3 rounded-lg border border-slate-200 font-mono">
                        {corr.description}
                      </p>
                      {corr.resolved_at && (
                        <p className="text-[10px] text-emerald-700 font-mono font-medium">
                          Resolved on: {formatDateTime(corr.resolved_at)}
                        </p>
                      )}
                    </div>
                  ))}
                </div>
              )}
            </Card>
          )}

          {/* Tab 5: Assignment History */}
          {activeTab === 'assignments' && (
            <Card className="bg-white border-slate-200 soft-elevation">
              <CardHeader
                title="Assignment Lifecycle History"
                subtitle="All draughtsman allocations and acceptance/rejection responses"
              />

              {assignments.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400 font-mono">
                  No assignments created for this project yet.
                </div>
              ) : (
                <div className="divide-y divide-slate-100">
                  {assignments.map((a) => (
                    <div
                      key={a.id}
                      className="py-3.5 flex items-center justify-between gap-4 hover:bg-slate-50 px-2 rounded-xl transition-colors"
                    >
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <Link
                            href={`/draughtsmen/${encodeURIComponent(a.draughtsman_id)}`}
                            className="text-xs font-semibold text-slate-900 hover:text-[#0453cd] hover:underline"
                            title="View Draughtsman Profile"
                          >
                            {a.draughtsman_name || `Draughtsman ID: ${a.draughtsman_id.substring(0, 8)}`}
                          </Link>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-mono font-semibold border ${
                              a.status === 'ACCEPTED'
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                : a.status === 'PENDING'
                                ? 'bg-amber-50 text-amber-700 border-amber-200'
                                : a.status === 'REJECTED'
                                ? 'bg-rose-50 text-rose-700 border-rose-200'
                                : 'bg-slate-100 text-slate-600 border-slate-200'
                            }`}
                          >
                            {a.status}
                          </span>
                        </div>
                        {a.draughtsman_email && (
                          <p className="text-[10px] text-slate-500 font-mono">{a.draughtsman_email}</p>
                        )}
                      </div>

                      <div className="text-right text-[10px] text-slate-400 font-mono">
                        <p>Assigned: {formatDateTime(a.created_at)}</p>
                        {a.updated_at && a.updated_at !== a.created_at && (
                          <p className="mt-0.5">Updated: {formatDateTime(a.updated_at)}</p>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          )}

          {/* Tab 6: Activity Audit Trail */}
          {activeTab === 'activity' && (
            <Card className="bg-white border-slate-200 soft-elevation">
              <CardHeader
                title="Immutable Activity Audit Trail"
                subtitle="Cryptographically verified server logs stored directly in Cloudflare D1"
              />

              {activity.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400 font-mono">
                  No activity logs recorded for this project yet.
                </div>
              ) : (
                <div className="divide-y divide-slate-100">
                  {activity.map((log) => (
                    <div key={log.id} className="py-3 flex items-start justify-between gap-4 hover:bg-slate-50 px-2 rounded-xl transition-colors">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-semibold font-mono text-[#0453cd]">
                            {log.action_type}
                          </span>
                          <Badge role={log.actor_role} size="sm" />
                          <span className="text-[10px] font-mono text-slate-400">
                            Actor: {log.actor_id.substring(0, 8)}
                          </span>
                        </div>
                        <p className="text-xs text-slate-700">{log.details}</p>
                      </div>
                      <div className="text-right shrink-0">
                        <p className="text-[10px] text-slate-400 font-mono">
                          {formatDateTime(log.timestamp)}
                        </p>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          )}
        </div>
      )}

      {/* Action Modals */}
      {project && isAssignOpen && (
        <AssignModal
          isOpen={isAssignOpen}
          onClose={() => setIsAssignOpen(false)}
          projectId={project.id}
          projectName={project.project_name}
          isReassign={isReassign}
          onSuccess={() => fetchProjectData(true)}
        />
      )}

      {project && isRejectOpen && (
        <RejectModal
          isOpen={isRejectOpen}
          onClose={() => setIsRejectOpen(false)}
          projectId={project.id}
          projectName={project.project_name}
          onSuccess={() => fetchProjectData(true)}
        />
      )}

      {project && isCancelOpen && (
        <CancelModal
          isOpen={isCancelOpen}
          onClose={() => setIsCancelOpen(false)}
          projectId={project.id}
          projectName={project.project_name}
          onSuccess={() => fetchProjectData(true)}
        />
      )}

      {project && isEvaluateOpen && drawingVersions.length > 0 && (
        <EvaluateModal
          isOpen={isEvaluateOpen}
          onClose={() => setIsEvaluateOpen(false)}
          projectId={project.id}
          projectName={project.project_name}
          studentName={project.client_name || null}
          drawingVersionId={drawingVersions[drawingVersions.length - 1].id}
          versionNumber={drawingVersions[drawingVersions.length - 1].version_number}
          fileId={drawingVersions[drawingVersions.length - 1].file_id}
          correctionRound={project.correction_round}
          onSuccess={() => fetchProjectData(true)}
        />
      )}
    </AdminShell>
  );
}

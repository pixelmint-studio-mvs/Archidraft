'use client';

import React, { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { AssignModal } from '@/components/projects/AssignModal';
import { RejectModal } from '@/components/projects/RejectModal';
import { CancelModal } from '@/components/projects/CancelModal';
import { adminApi } from '@/lib/api';
import {
  Project,
  ProjectFile,
  DrawingVersion,
  Correction,
  Assignment,
  ActivityLog,
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
} from 'lucide-react';

type TabKey = 'overview' | 'files' | 'drawings' | 'corrections' | 'assignments' | 'activity';

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

  // Modal states
  const [isAssignOpen, setIsAssignOpen] = useState<boolean>(false);
  const [isReassign, setIsReassign] = useState<boolean>(false);
  const [isRejectOpen, setIsRejectOpen] = useState<boolean>(false);
  const [isCancelOpen, setIsCancelOpen] = useState<boolean>(false);
  const [actionLoading, setActionLoading] = useState<boolean>(false);

  const fetchProjectData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [proj, fileList, dvList, corrList, assignList, actList] = await Promise.all([
        adminApi.getProject(projectId),
        adminApi.getProjectFiles(projectId).catch(() => []),
        adminApi.getProjectDrawingVersions(projectId).catch(() => []),
        adminApi.getProjectCorrections(projectId).catch(() => []),
        adminApi.getProjectAssignments(projectId).catch(() => []),
        adminApi.getProjectActivity(projectId).catch(() => []),
      ]);

      setProject(proj);
      setFiles(fileList || []);
      setDrawingVersions(dvList || []);
      setCorrections(corrList || []);
      setAssignments(assignList || []);
      setActivity(actList || []);
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
          className="inline-flex items-center gap-2 text-xs font-semibold text-slate-400 hover:text-slate-200 transition-colors"
        >
          <ArrowLeft className="h-4 w-4" />
          <span>Back to Projects Catalog</span>
        </Link>
      </div>

      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-sm text-rose-300 flex items-center gap-3">
          <AlertTriangle className="h-5 w-5 text-rose-400 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => fetchProjectData(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
          <p className="text-xs text-slate-400 mt-3 font-medium">Loading project specifications...</p>
        </div>
      ) : !project ? (
        <Card className="text-center py-16">
          <h3 className="text-base font-semibold text-slate-300">Project Not Found</h3>
          <p className="text-xs text-slate-500 mt-1">The requested project ID does not exist in D1.</p>
        </Card>
      ) : (
        <div className="space-y-6">
          {/* Rejection Notice Banner */}
          {project.status === 'CANCELLED' && project.rejection_reason && (
            <div className="p-4 rounded-xl bg-rose-500/10 border border-rose-500/30 text-rose-200 flex items-start gap-3">
              <XCircle className="h-5 w-5 text-rose-400 shrink-0 mt-0.5" />
              <div>
                <p className="text-xs font-semibold uppercase tracking-wider text-rose-400">
                  Project Rejected / Cancelled
                </p>
                <p className="text-sm mt-1">{project.rejection_reason}</p>
                {project.cancelled_at && (
                  <p className="text-[11px] text-rose-400/80 font-mono mt-1">
                    Recorded at: {new Date(project.cancelled_at).toLocaleString()}
                  </p>
                )}
              </div>
            </div>
          )}

          {/* Project Header Card & Administrative Action Bar */}
          <Card className="bg-gradient-to-r from-[#0f172a] to-[#121c33] border-slate-800">
            <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
              <div className="space-y-2">
                <div className="flex items-center gap-3 flex-wrap">
                  <h1 className="text-2xl font-bold text-slate-100">
                    {project.project_name || 'Untitled Project'}
                  </h1>
                  <Badge status={project.status} size="md" />
                  {project.correction_round > 0 && (
                    <span className="text-xs px-2.5 py-1 rounded-full bg-teal-500/10 text-teal-300 border border-teal-500/30 font-medium">
                      Correction Round {project.correction_round} of 3
                    </span>
                  )}
                </div>

                <p className="text-sm text-slate-300 max-w-2xl">{project.project_address}</p>

                <div className="flex items-center gap-6 text-xs text-slate-400 pt-1 flex-wrap">
                  <div className="flex items-center gap-1.5">
                    <Layers className="h-3.5 w-3.5 text-slate-500" />
                    <span>Drawing: <strong className="text-slate-200">{project.drawing_name || project.drawing_type}</strong></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Compass className="h-3.5 w-3.5 text-slate-500" />
                    <span>Area: <strong className="text-slate-200">{project.project_area || 'Standard'} sq.ft</strong></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <User className="h-3.5 w-3.5 text-slate-500" />
                    <span>Client ID: <code className="text-slate-300 font-mono">{project.client_id.substring(0, 8)}</code></span>
                  </div>
                  <div className="flex items-center gap-1.5">
                    <Calendar className="h-3.5 w-3.5 text-slate-500" />
                    <span>Created: <span className="text-slate-200">{new Date(project.created_at).toLocaleDateString()}</span></span>
                  </div>
                </div>
              </div>

              {/* Administrative Action Bar (Governed by State Machine) */}
              <div className="flex items-center gap-2.5 flex-wrap shrink-0">
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

                {/* Active States: Cancel Project */}
                {project.status !== 'COMPLETED' &&
                  project.status !== 'CANCELLED' &&
                  project.status !== 'DRAFT' && (
                    <Button
                      variant="ghost"
                      onClick={() => setIsCancelOpen(true)}
                      className="text-rose-400 hover:text-rose-300 hover:bg-rose-500/10"
                      icon={<Ban className="h-4 w-4" />}
                    >
                      Cancel Project
                    </Button>
                  )}
              </div>
            </div>
          </Card>

          {/* Navigation Tabs */}
          <div className="flex items-center gap-2 border-b border-slate-800 pb-2 overflow-x-auto scrollbar-none">
            {[
              { key: 'overview', label: 'Specifications & Info', count: null },
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
                  className={`flex items-center gap-2 px-4 py-2 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
                    isSelected
                      ? 'bg-blue-600 text-white shadow-sm'
                      : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 border border-slate-800'
                  }`}
                >
                  <span>{tab.label}</span>
                  {tab.count !== null && (
                    <span
                      className={`px-1.5 py-0.5 rounded-full text-[10px] ${
                        isSelected ? 'bg-blue-800/80 text-blue-100' : 'bg-slate-800 text-slate-400'
                      }`}
                    >
                      {tab.count}
                    </span>
                  )}
                </button>
              );
            })}
          </div>

          {/* Tab 1: Overview */}
          {activeTab === 'overview' && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <Card>
                <CardHeader title="Project Metadata & Specifications" />
                <div className="space-y-3 text-xs divide-y divide-slate-800/80">
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Project ID</span>
                    <span className="font-mono text-slate-200">{project.id}</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Project Name</span>
                    <span className="font-semibold text-slate-200">{project.project_name || 'N/A'}</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Drawing Name</span>
                    <span className="text-slate-200">{project.drawing_name || 'N/A'}</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Drawing Type</span>
                    <span className="text-slate-200">{project.drawing_type || 'N/A'}</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Project Area</span>
                    <span className="text-slate-200">{project.project_area || 'Standard'} sq.ft</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Project Address</span>
                    <span className="text-slate-200 text-right max-w-xs">{project.project_address || 'N/A'}</span>
                  </div>
                </div>
              </Card>

              <Card>
                <CardHeader title="Operational Lifecycle & Timestamps" />
                <div className="space-y-3 text-xs divide-y divide-slate-800/80">
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Assigned Draughtsman</span>
                    <span className="font-semibold text-slate-200">
                      {project.draughtsman_name || 'None Assigned'}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Draughtsman ID</span>
                    <span className="font-mono text-slate-200">
                      {project.draughtsman_id || 'N/A'}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Current Assignment ID</span>
                    <span className="font-mono text-slate-200">
                      {project.current_assignment_id || 'N/A'}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Correction Round</span>
                    <span className="font-semibold text-teal-400">{project.correction_round} of 3</span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Submitted At</span>
                    <span className="text-slate-200">
                      {project.submitted_at ? new Date(project.submitted_at).toLocaleString() : 'N/A'}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Approved At</span>
                    <span className="text-slate-200">
                      {project.approved_at ? new Date(project.approved_at).toLocaleString() : 'N/A'}
                    </span>
                  </div>
                  <div className="pt-2 flex justify-between">
                    <span className="text-slate-400">Last Action ID</span>
                    <span className="font-mono text-slate-400">{project.last_action_id || 'N/A'}</span>
                  </div>
                </div>
              </Card>
            </div>
          )}

          {/* Tab 2: Reference Files */}
          {activeTab === 'files' && (
            <Card>
              <CardHeader
                title="Client Reference Materials & Uploads"
                subtitle="Documents, sketches, and reference files stored securely in Cloudflare R2"
              />

              {files.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400">
                  No reference files uploaded by client yet.
                </div>
              ) : (
                <div className="divide-y divide-slate-800">
                  {files.map((file) => (
                    <div
                      key={file.id}
                      className="py-3.5 flex items-center justify-between gap-4 hover:bg-slate-850/40 px-2 rounded-lg transition-colors"
                    >
                      <div className="flex items-center gap-3 overflow-hidden">
                        <div className="p-2 rounded-lg bg-blue-500/10 text-blue-400 border border-blue-500/20 shrink-0">
                          <FileText className="h-4 w-4" />
                        </div>
                        <div className="overflow-hidden">
                          <p className="text-xs font-semibold text-slate-200 truncate">
                            {file.original_name || file.sanitized_name}
                          </p>
                          <p className="text-[10px] text-slate-400">
                            {formatFileSize(file.size)} &bull; {file.content_type} &bull; Category:{' '}
                            <span className="font-mono text-slate-300">{file.category}</span>
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 shrink-0">
                        <span className="text-[10px] text-slate-500 font-mono">
                          {new Date(file.created_at).toLocaleDateString()}
                        </span>
                        <a
                          href={adminApi.getFileDownloadUrl(file.id)}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex items-center gap-1.5 px-3 py-1 text-xs font-medium text-blue-400 hover:text-blue-300 bg-blue-500/10 hover:bg-blue-500/20 border border-blue-500/30 rounded-lg transition-colors"
                        >
                          <Download className="h-3 w-3" />
                          <span>Download</span>
                        </a>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>
          )}

          {/* Tab 3: Drawing Versions */}
          {activeTab === 'drawings' && (
            <Card>
              <CardHeader
                title="Draughtsman Drawing Deliverables"
                subtitle="CAD / PDF versions submitted by assigned draughtsmen"
              />

              {drawingVersions.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400">
                  No drawing versions submitted yet. Once the assigned draughtsman submits drawings, they appear here.
                </div>
              ) : (
                <div className="divide-y divide-slate-800">
                  {drawingVersions.map((dv) => (
                    <div
                      key={dv.id}
                      className="py-4 flex items-center justify-between gap-4 hover:bg-slate-850/40 px-2 rounded-lg transition-colors"
                    >
                      <div className="flex items-center gap-3">
                        <div className="h-9 w-9 rounded-xl bg-cyan-500/10 text-cyan-400 border border-cyan-500/20 flex items-center justify-center font-bold text-xs shrink-0">
                          v{dv.version_number}
                        </div>
                        <div>
                          <p className="text-xs font-semibold text-slate-200">
                            Version {dv.version_number}: {dv.original_name || 'CAD Drawing Deliverable'}
                          </p>
                          <p className="text-[10px] text-slate-400 mt-0.5">
                            Uploaded by Draughtsman ID: <code className="font-mono">{dv.uploaded_by.substring(0, 8)}</code>
                            {dv.size ? ` • ${formatFileSize(dv.size)}` : ''}
                          </p>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 shrink-0">
                        <span className="text-[10px] text-slate-500 font-mono">
                          {new Date(dv.created_at).toLocaleString()}
                        </span>
                        {dv.file_id && (
                          <a
                            href={adminApi.getFileDownloadUrl(dv.file_id)}
                            target="_blank"
                            rel="noopener noreferrer"
                            className="flex items-center gap-1.5 px-3 py-1 text-xs font-medium text-cyan-400 hover:text-cyan-300 bg-cyan-500/10 hover:bg-cyan-500/20 border border-cyan-500/30 rounded-lg transition-colors"
                          >
                            <Download className="h-3 w-3" />
                            <span>Download v{dv.version_number}</span>
                          </a>
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
            <Card>
              <CardHeader
                title="Client Revision & Correction Rounds"
                subtitle="Maximum limit of 3 rounds enforced strictly by the Cloudflare Worker"
              />

              {corrections.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400">
                  No correction rounds requested for this project.
                </div>
              ) : (
                <div className="space-y-4">
                  {corrections.map((corr) => (
                    <div
                      key={corr.id}
                      className="p-4 rounded-xl bg-slate-900 border border-slate-800 space-y-2"
                    >
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-bold text-teal-400">
                            Round {corr.round_number} of 3
                          </span>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-semibold border ${
                              corr.status === 'RESOLVED'
                                ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30'
                                : corr.status === 'IN_PROGRESS'
                                ? 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30'
                                : 'bg-amber-500/10 text-amber-400 border-amber-500/30'
                            }`}
                          >
                            {corr.status}
                          </span>
                        </div>
                        <span className="text-[10px] text-slate-500 font-mono">
                          {new Date(corr.created_at).toLocaleString()}
                        </span>
                      </div>
                      <p className="text-xs text-slate-200 leading-relaxed bg-slate-950 p-3 rounded-lg border border-slate-850">
                        {corr.description}
                      </p>
                      {corr.resolved_at && (
                        <p className="text-[10px] text-emerald-400 font-mono">
                          Resolved on: {new Date(corr.resolved_at).toLocaleString()}
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
            <Card>
              <CardHeader
                title="Assignment Lifecycle History"
                subtitle="All draughtsman allocations and acceptance/rejection responses"
              />

              {assignments.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400">
                  No assignments created for this project yet.
                </div>
              ) : (
                <div className="divide-y divide-slate-800">
                  {assignments.map((a) => (
                    <div
                      key={a.id}
                      className="py-3.5 flex items-center justify-between gap-4 hover:bg-slate-850/40 px-2 rounded-lg transition-colors"
                    >
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <p className="text-xs font-semibold text-slate-200">
                            {a.draughtsman_name || `Draughtsman ID: ${a.draughtsman_id.substring(0, 8)}`}
                          </p>
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-semibold border ${
                              a.status === 'ACCEPTED'
                                ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30'
                                : a.status === 'PENDING'
                                ? 'bg-amber-500/10 text-amber-400 border-amber-500/30'
                                : a.status === 'REJECTED'
                                ? 'bg-rose-500/10 text-rose-400 border-rose-500/30'
                                : 'bg-slate-800 text-slate-400 border-slate-700'
                            }`}
                          >
                            {a.status}
                          </span>
                        </div>
                        {a.draughtsman_email && (
                          <p className="text-[10px] text-slate-400 font-mono">{a.draughtsman_email}</p>
                        )}
                      </div>

                      <div className="text-right text-[10px] text-slate-500 font-mono">
                        <p>Assigned: {new Date(a.created_at).toLocaleString()}</p>
                        {a.updated_at && a.updated_at !== a.created_at && (
                          <p className="mt-0.5">Updated: {new Date(a.updated_at).toLocaleString()}</p>
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
            <Card>
              <CardHeader
                title="Immutable Activity Audit Trail"
                subtitle="Cryptographically verified server logs stored directly in Cloudflare D1"
              />

              {activity.length === 0 ? (
                <div className="p-8 text-center text-xs text-slate-400">
                  No activity logs recorded for this project yet.
                </div>
              ) : (
                <div className="divide-y divide-slate-800/80">
                  {activity.map((log) => (
                    <div key={log.id} className="py-3 flex items-start justify-between gap-4">
                      <div className="space-y-1">
                        <div className="flex items-center gap-2">
                          <span className="text-xs font-semibold font-mono text-blue-400">
                            {log.action_type}
                          </span>
                          <Badge role={log.actor_role} size="sm" />
                          <span className="text-[10px] font-mono text-slate-500">
                            Actor: {log.actor_id.substring(0, 8)}
                          </span>
                        </div>
                        <p className="text-xs text-slate-300">{log.details}</p>
                      </div>
                      <div className="text-right shrink-0">
                        <p className="text-[10px] text-slate-500 font-mono">
                          {new Date(log.timestamp).toLocaleString()}
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
    </AdminShell>
  );
}

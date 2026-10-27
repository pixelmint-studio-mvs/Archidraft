'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { StudentSubmission } from '@/lib/types';
import { EvaluateModal } from '@/components/projects/EvaluateModal';
import {
  Search,
  ClipboardCheck,
  GraduationCap,
  FileText,
  Clock,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  ExternalLink,
  ChevronRight,
  RefreshCw,
  AlertCircle,
  FileDown,
  User,
  BookOpen,
  Filter,
  Loader2,
} from 'lucide-react';

type FilterStatus = 'ALL' | 'UNDER_REVIEW' | 'IN_PROGRESS' | 'COMPLETED' | 'CANCELLED';

export default function StudentSubmissionsPage() {
  const [submissions, setSubmissions] = useState<StudentSubmission[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [downloadingId, setDownloadingId] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  // Search & Filter
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<FilterStatus>('ALL');

  // Pagination
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 10;

  // Evaluation Modal Target
  const [evaluatingSubmission, setEvaluatingSubmission] = useState<StudentSubmission | null>(null);

  const fetchSubmissions = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getStudentSubmissions();
      setSubmissions(data || []);
    } catch (err: any) {
      console.error('Failed to fetch student submissions:', err);
      setError(err.message || 'Failed to load practical submissions queue.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchSubmissions();
  }, []);

  // Filtered dataset
  const filteredSubmissions = useMemo(() => {
    return submissions.filter((sub) => {
      // Status filtering
      if (statusFilter === 'UNDER_REVIEW') {
        const isReview =
          sub.status === 'UNDER_ENGINEER_REVIEW' || sub.status === 'UNDER_CLIENT_REVIEW';
        if (!isReview) return false;
      } else if (statusFilter === 'IN_PROGRESS') {
        if (sub.status !== 'IN_PROGRESS') return false;
      } else if (statusFilter === 'COMPLETED') {
        if (sub.status !== 'COMPLETED') return false;
      } else if (statusFilter === 'CANCELLED') {
        if (sub.status !== 'CANCELLED') return false;
      }

      // Search query filtering
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        const matchesProject = sub.project_name?.toLowerCase().includes(q);
        const matchesDrawing = sub.drawing_name?.toLowerCase().includes(q);
        const matchesStudent = sub.student_name?.toLowerCase().includes(q);
        const matchesEmail = sub.student_email?.toLowerCase().includes(q);
        const matchesModule = sub.module_title?.toLowerCase().includes(q);
        if (!matchesProject && !matchesDrawing && !matchesStudent && !matchesEmail && !matchesModule) {
          return false;
        }
      }

      return true;
    });
  }, [submissions, statusFilter, searchQuery]);

  // Pagination calculations
  const totalItems = filteredSubmissions.length;
  const totalPages = Math.ceil(totalItems / pageSize) || 1;
  const paginatedSubmissions = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredSubmissions.slice(start, start + pageSize);
  }, [filteredSubmissions, currentPage, pageSize]);

  // Reset page when filter or search changes
  useEffect(() => {
    setCurrentPage(1);
  }, [searchQuery, statusFilter]);

  // Live KPI counts
  const kpiCounts = useMemo(() => {
    const total = submissions.length;
    const awaitingReview = submissions.filter(
      (s) => s.status === 'UNDER_ENGINEER_REVIEW' || s.status === 'UNDER_CLIENT_REVIEW'
    ).length;
    const inRevision = submissions.filter((s) => s.status === 'IN_PROGRESS').length;
    const completed = submissions.filter((s) => s.status === 'COMPLETED').length;
    return { total, awaitingReview, inRevision, completed };
  }, [submissions]);

  return (
    <AdminShell
      title="Student Submissions Queue"
      subtitle="Authoritative review and rubric evaluation queue for apprentice practical drafting milestones"
      onRefresh={() => fetchSubmissions(true)}
      isRefreshing={refreshing}
    >
      <div className="space-y-6 max-w-7xl mx-auto pb-12">
        {/* Page Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-5">
          <div>
            <div className="flex items-center gap-2.5">
              <div className="h-9 w-9 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center shadow-xs">
                <ClipboardCheck className="h-5 w-5" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-slate-900 tracking-tight">
                  Student Practical Submissions Queue
                </h1>
                <p className="text-xs text-slate-500 font-mono mt-0.5">
                  Authoritative review and rubric evaluation queue for apprentice practical drafting milestones
                </p>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <Button
              variant="outline"
              size="sm"
              onClick={() => fetchSubmissions(true)}
              loading={refreshing}
              icon={<RefreshCw className={`h-3.5 w-3.5 ${refreshing ? 'animate-spin' : ''}`} />}
            >
              Refresh Queue
            </Button>
          </div>
        </div>

        {/* Operational KPI Metric Strip */}
        <div className="grid grid-cols-2 lg:grid-cols-4 gap-3.5">
          <Card className="p-4 bg-white border-slate-200">
            <div className="flex items-center justify-between text-slate-500 text-xs font-mono mb-1">
              <span>Total Submissions</span>
              <FileText className="h-4 w-4 text-slate-400" />
            </div>
            <div className="text-2xl font-bold font-mono text-slate-900">{kpiCounts.total}</div>
            <div className="text-[10px] text-slate-400 mt-1 font-mono">Enrolled training milestones</div>
          </Card>

          <Card className="p-4 bg-teal-50/50 border-teal-200">
            <div className="flex items-center justify-between text-teal-700 text-xs font-mono mb-1">
              <span>Awaiting Review</span>
              <Clock className="h-4 w-4 text-teal-600" />
            </div>
            <div className="text-2xl font-bold font-mono text-teal-900">{kpiCounts.awaitingReview}</div>
            <div className="text-[10px] text-teal-600 mt-1 font-mono">Ready for Studio Admin scoring</div>
          </Card>

          <Card className="p-4 bg-amber-50/50 border-amber-200">
            <div className="flex items-center justify-between text-amber-700 text-xs font-mono mb-1">
              <span>In Revision</span>
              <AlertTriangle className="h-4 w-4 text-amber-600" />
            </div>
            <div className="text-2xl font-bold font-mono text-amber-900">{kpiCounts.inRevision}</div>
            <div className="text-[10px] text-amber-600 mt-1 font-mono">Awaiting student redline updates</div>
          </Card>

          <Card className="p-4 bg-emerald-50/50 border-emerald-200">
            <div className="flex items-center justify-between text-emerald-700 text-xs font-mono mb-1">
              <span>Approved / Certified</span>
              <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            </div>
            <div className="text-2xl font-bold font-mono text-emerald-900">{kpiCounts.completed}</div>
            <div className="text-[10px] text-emerald-600 mt-1 font-mono">Successfully certified milestones</div>
          </Card>
        </div>

        {/* Error Notification */}
        {error && (
          <div className="flex items-center justify-between p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs">
            <div className="flex items-center gap-2.5">
              <AlertCircle className="h-4 w-4 text-rose-600 shrink-0" />
              <span>{error}</span>
            </div>
            <Button variant="outline" size="sm" onClick={() => fetchSubmissions(true)}>
              Retry
            </Button>
          </div>
        )}

        {/* Search & Filter Toolbar */}
        <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 bg-white p-3.5 rounded-xl border border-slate-200 shadow-2xs">
          {/* Status Tabs */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 md:pb-0 scrollbar-none">
            {[
              { id: 'ALL', label: 'All Submissions', count: kpiCounts.total },
              { id: 'UNDER_REVIEW', label: 'Awaiting Review', count: kpiCounts.awaitingReview },
              { id: 'IN_PROGRESS', label: 'In Revision', count: kpiCounts.inRevision },
              { id: 'COMPLETED', label: 'Approved', count: kpiCounts.completed },
              { id: 'CANCELLED', label: 'Rejected', count: submissions.filter((s) => s.status === 'CANCELLED').length },
            ].map((tab) => {
              const isSelected = statusFilter === tab.id;
              return (
                <button
                  key={tab.id}
                  onClick={() => setStatusFilter(tab.id as FilterStatus)}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-mono font-medium transition-all whitespace-nowrap ${
                    isSelected
                      ? 'bg-[#0d1c32] text-white shadow-2xs font-bold'
                      : 'bg-slate-100 text-slate-600 hover:text-slate-900 hover:bg-slate-200/70'
                  }`}
                >
                  <span>{tab.label}</span>
                  <span
                    className={`px-1.5 py-0.2 rounded-full text-[10px] font-mono ${
                      isSelected ? 'bg-white/20 text-white' : 'bg-slate-200 text-slate-600'
                    }`}
                  >
                    {tab.count}
                  </span>
                </button>
              );
            })}
          </div>

          {/* Search Field */}
          <div className="relative min-w-[260px] md:w-72">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-3.5 w-3.5 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by student, project, or module..."
              className="w-full pl-9 pr-3.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] transition-all"
            />
          </div>
        </div>

        {/* Submissions Table / Queue */}
        <Card className="overflow-hidden border-slate-200 bg-white">
          {loading ? (
            <div className="p-8 text-center space-y-3">
              <RefreshCw className="h-6 w-6 animate-spin text-[#0453cd] mx-auto" />
              <p className="text-xs font-mono text-slate-500">Hydrating student submissions from Cloudflare D1...</p>
            </div>
          ) : paginatedSubmissions.length === 0 ? (
            <div className="p-12 text-center space-y-2">
              <ClipboardCheck className="h-8 w-8 text-slate-300 mx-auto" />
              <h3 className="text-sm font-bold text-slate-800">No Submissions Found</h3>
              <p className="text-xs text-slate-500 max-w-sm mx-auto">
                {searchQuery || statusFilter !== 'ALL'
                  ? 'No practical milestones match your current filter criteria.'
                  : 'No apprentice practical milestones are currently submitted for review.'}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="border-b border-slate-200 bg-slate-50/70 text-[11px] font-mono text-slate-500 uppercase tracking-wider">
                    <th className="py-3 px-4 font-semibold">Practical Milestone & Target</th>
                    <th className="py-3 px-4 font-semibold">Student Apprentice</th>
                    <th className="py-3 px-4 font-semibold">Version & Cycle</th>
                    <th className="py-3 px-4 font-semibold">Submitted Date</th>
                    <th className="py-3 px-4 font-semibold">Workflow Status</th>
                    <th className="py-3 px-4 font-semibold text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 text-xs">
                  {paginatedSubmissions.map((sub) => {
                    const isReviewable =
                      sub.status === 'UNDER_ENGINEER_REVIEW' || sub.status === 'UNDER_CLIENT_REVIEW';

                    return (
                      <tr key={sub.id} className="hover:bg-slate-50/70 transition-colors">
                        {/* Project & Drawing */}
                        <td className="py-3 px-4 max-w-[260px]">
                          <div className="font-semibold text-slate-900 truncate">
                            {sub.project_name}
                          </div>
                          <div className="text-[11px] text-slate-500 flex items-center gap-1.5 mt-0.5 truncate">
                            <GraduationCap className="h-3 w-3 text-[#0453cd] shrink-0" />
                            <span className="truncate">{sub.module_title || sub.drawing_name || sub.drawing_type}</span>
                          </div>
                        </td>

                        {/* Student Info */}
                        <td className="py-3 px-4">
                          <Link
                            href={`/students/${sub.student_id}`}
                            className="font-medium text-slate-800 hover:text-[#0453cd] hover:underline flex items-center gap-1.5 truncate"
                          >
                            <User className="h-3 w-3 text-slate-400 shrink-0" />
                            <span className="truncate">{sub.student_name || 'Apprentice'}</span>
                          </Link>
                          <div className="text-[11px] font-mono text-slate-400 truncate mt-0.5">
                            {sub.student_email || 'No email registered'}
                          </div>
                        </td>

                        {/* Version & Cycle */}
                        <td className="py-3 px-4">
                          <div className="flex items-center gap-1.5">
                            <span className="px-2 py-0.5 rounded-full bg-blue-50 text-[#0453cd] border border-blue-200 font-mono font-bold text-[10px]">
                              {sub.latest_version_number != null ? `v${sub.latest_version_number}` : 'Draft'}
                            </span>
                            {sub.correction_round > 0 && (
                              <span className="px-2 py-0.5 rounded-full bg-amber-50 text-amber-800 border border-amber-200 font-mono text-[10px]">
                                Round {sub.correction_round}
                              </span>
                            )}
                          </div>
                        </td>

                        {/* Submitted Date */}
                        <td className="py-3 px-4 font-mono text-slate-500 text-[11px]">
                          {sub.submitted_at
                            ? new Date(sub.submitted_at).toLocaleDateString()
                            : new Date(sub.created_at).toLocaleDateString()}
                        </td>

                        {/* Status */}
                        <td className="py-3 px-4">
                          <Badge status={sub.status} size="sm" />
                          {sub.rejection_reason && sub.status === 'CANCELLED' && (
                            <p className="text-[10px] text-rose-600 truncate max-w-[180px] mt-1 font-mono italic">
                              Rejection: {sub.rejection_reason}
                            </p>
                          )}
                        </td>

                        {/* Actions */}
                        <td className="py-3 px-4 text-right">
                          <div className="flex items-center justify-end gap-1.5">
                            {/* Primary Review CTA if awaiting review */}
                            {isReviewable && sub.latest_drawing_version_id && (
                              <Button
                                variant="primary"
                                size="sm"
                                onClick={() => setEvaluatingSubmission(sub)}
                                icon={<ClipboardCheck className="h-3.5 w-3.5" />}
                              >
                                Review & Score
                              </Button>
                            )}

                            {/* Inspect File direct download */}
                            {sub.latest_file_id && (
                              <button
                                type="button"
                                onClick={async () => {
                                  try {
                                    setDownloadingId(sub.latest_file_id!);
                                    await adminApi.downloadAndSaveFile(sub.latest_file_id!, `submission_${sub.student_name || 'student'}.dwg`);
                                  } catch (err: any) {
                                    alert(err.message || 'Download failed');
                                  } finally {
                                    setDownloadingId(null);
                                  }
                                }}
                                disabled={downloadingId === sub.latest_file_id}
                                title="Download and inspect CAD drawing"
                                className="p-1.5 rounded-lg border border-slate-200 text-slate-600 hover:text-[#0453cd] hover:border-[#0453cd] hover:bg-blue-50/50 disabled:opacity-50 transition-all cursor-pointer"
                              >
                                {downloadingId === sub.latest_file_id ? (
                                  <Loader2 className="h-3.5 w-3.5 animate-spin text-[#0453cd]" />
                                ) : (
                                  <FileDown className="h-3.5 w-3.5" />
                                )}
                              </button>
                            )}

                            {/* Link to Full Project detail */}
                            <Link
                              href={`/projects/${sub.id}`}
                              title="View Project Workspace"
                              className="p-1.5 rounded-lg border border-slate-200 text-slate-600 hover:text-[#0453cd] hover:border-[#0453cd] hover:bg-blue-50/50 transition-all"
                            >
                              <ExternalLink className="h-3.5 w-3.5" />
                            </Link>

                            {/* Link to Student Dossier */}
                            <Link
                              href={`/students/${sub.student_id}`}
                              title="View Student Dossier"
                              className="p-1.5 rounded-lg border border-slate-200 text-slate-600 hover:text-[#0453cd] hover:border-[#0453cd] hover:bg-blue-50/50 transition-all"
                            >
                              <GraduationCap className="h-3.5 w-3.5" />
                            </Link>
                          </div>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination Controls */}
          {totalPages > 1 && (
            <div className="flex items-center justify-between px-4 py-3 border-t border-slate-200 bg-slate-50/50 text-xs font-mono text-slate-500">
              <div>
                Showing {(currentPage - 1) * pageSize + 1} to{' '}
                {Math.min(currentPage * pageSize, totalItems)} of {totalItems} practical milestones
              </div>
              <div className="flex items-center gap-1">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                >
                  Previous
                </Button>
                <span className="px-3 py-1 font-bold text-slate-800">
                  {currentPage} / {totalPages}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={currentPage === totalPages}
                  onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </Card>
      </div>

      {/* Interactive Evaluation Modal */}
      {evaluatingSubmission && evaluatingSubmission.latest_drawing_version_id && (
        <EvaluateModal
          isOpen={!!evaluatingSubmission}
          onClose={() => setEvaluatingSubmission(null)}
          projectId={evaluatingSubmission.id}
          projectName={evaluatingSubmission.project_name}
          studentName={evaluatingSubmission.student_name}
          studentEmail={evaluatingSubmission.student_email}
          moduleTitle={evaluatingSubmission.module_title}
          drawingVersionId={evaluatingSubmission.latest_drawing_version_id}
          versionNumber={evaluatingSubmission.latest_version_number}
          fileId={evaluatingSubmission.latest_file_id}
          correctionRound={evaluatingSubmission.correction_round}
          onSuccess={() => {
            fetchSubmissions(true);
          }}
        />
      )}
    </AdminShell>
  );
}

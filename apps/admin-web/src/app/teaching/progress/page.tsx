'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { Badge } from '@/components/ui/Badge';
import { adminApi } from '@/lib/api';
import {
  StudentProgressSummary,
  StudentProgressDetail,
} from '@/lib/types';
import {
  TrendingUp,
  GraduationCap,
  Search,
  CheckCircle2,
  Clock,
  AlertTriangle,
  Award,
  Layers,
  FileText,
  Calendar,
  Building,
  ArrowRight,
  ExternalLink,
  Filter,
  Check,
  XCircle,
  FileCheck,
  AlertCircle,
  FolderKanban,
  BookOpen,
} from 'lucide-react';

export default function StudentProgressDashboardPage() {
  const [summaries, setSummaries] = useState<StudentProgressSummary[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Search & Filter
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // Detail Modal State
  const [detailModalOpen, setDetailModalOpen] = useState<boolean>(false);
  const [selectedStudentId, setSelectedStudentId] = useState<string | null>(null);
  const [detailData, setDetailData] = useState<StudentProgressDetail | null>(null);
  const [loadingDetail, setLoadingDetail] = useState<boolean>(false);
  const [detailError, setDetailError] = useState<string | null>(null);

  const loadData = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getStudentsProgress({
        search: searchQuery.trim() || undefined,
        status: statusFilter !== 'ALL' ? statusFilter : undefined,
      });
      setSummaries(data || []);
    } catch (err: any) {
      setError(err.message || 'Failed to load student progress telemetry.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [statusFilter]);

  const handleOpenDetail = async (studentId: string) => {
    setSelectedStudentId(studentId);
    setDetailModalOpen(true);
    setLoadingDetail(true);
    setDetailError(null);
    setDetailData(null);

    try {
      const detail = await adminApi.getStudentProgressDetail(studentId);
      setDetailData(detail);
    } catch (err: any) {
      setDetailError(err.message || 'Failed to load detailed progress breakdown.');
    } finally {
      setLoadingDetail(false);
    }
  };

  // In-memory instant search
  const filteredSummaries = useMemo(() => {
    return summaries.filter((st) => {
      const name = st.student_name || st.name || '';
      const email = st.student_email || st.email || '';
      const college = st.college_name || '';
      const matchesSearch =
        !searchQuery ||
        name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        college.toLowerCase().includes(searchQuery.toLowerCase());
      return matchesSearch;
    });
  }, [summaries, searchQuery]);

  // Telemetry Aggregates
  const stats = useMemo(() => {
    const totalStudents = summaries.length;
    const completedStudents = summaries.filter(
      (s) =>
        ((s.assigned_plans_count ?? s.assigned_modules_count ?? 0) > 0) &&
        (s.overall_completion_percentage ?? 0) === 100
    ).length;
    const overdueCount = summaries.filter((s) => s.has_overdue || (s.overdue_count ?? 0) > 0).length;

    let totalPct = 0;
    let studentsWithPlans = 0;
    for (const s of summaries) {
      const planCount = s.assigned_plans_count ?? s.assigned_modules_count ?? 0;
      if (planCount > 0) {
        totalPct += s.overall_completion_percentage ?? 0;
        studentsWithPlans++;
      }
    }
    const avgPct = studentsWithPlans > 0 ? Math.round(totalPct / studentsWithPlans) : 0;

    return { totalStudents, completedStudents, overdueCount, avgPct };
  }, [summaries]);

  return (
    <AdminShell
      title="Student Progress"
      subtitle="Monitor individual student training completion, lesson outcomes, practical drawing evaluations, and curriculum milestones."
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      <div className="space-y-6">
        {/* ── Top Telemetry ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Enrolled Students
              </p>
              <GraduationCap className="h-4 w-4 text-[#0453cd]" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.totalStudents}</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Under active monitoring</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Average Completion
              </p>
              <TrendingUp className="h-4 w-4 text-blue-600" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.avgPct}%</p>
            <p className="text-[11px] text-blue-700 font-mono mt-1">Across assigned required lessons</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Curriculum Fulfilled
              </p>
              <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.completedStudents}</p>
            <p className="text-[11px] text-emerald-700 font-mono mt-1">100% required lessons done</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Overdue Trainees
              </p>
              <AlertTriangle className="h-4 w-4 text-amber-500" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.overdueCount}</p>
            <p className="text-[11px] text-amber-700 font-mono mt-1">Past target completion date</p>
          </div>
        </div>

        {/* ── Filters & Search ── */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white p-4 rounded-xl border border-slate-200">
          <div className="relative flex-1 max-w-md">
            <Search className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search students by name, email, college…"
              className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            />
          </div>

          <div className="flex items-center gap-2 text-xs font-mono">
            <select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              className="px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            >
              <option value="ALL">All Progress States</option>
              <option value="COMPLETED">Completed (100%)</option>
              <option value="IN_PROGRESS">In Progress (1-99%)</option>
              <option value="NOT_STARTED">Not Started (0%)</option>
              <option value="OVERDUE">Overdue Work</option>
              <option value="UNASSIGNED">Unassigned (0 Modules)</option>
            </select>
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

        {/* ── Progress Overview Table ── */}
        {loading ? (
          <Card className="p-16 text-center bg-white border-slate-200">
            <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent mx-auto mb-3" />
            <p className="text-xs font-mono text-slate-500">Calculating student completion telemetry…</p>
          </Card>
        ) : filteredSummaries.length === 0 ? (
          <Card className="p-16 text-center bg-white border-slate-200">
            <GraduationCap className="h-10 w-10 text-slate-400 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-800">No Student Records Found</p>
            <p className="text-xs text-slate-500 font-mono mt-1">
              {searchQuery || statusFilter !== 'ALL'
                ? 'No students match your filter criteria.'
                : 'Enrolled students and their learning progress will appear here.'}
            </p>
          </Card>
        ) : (
          <div className="rounded-2xl border border-slate-200 bg-white overflow-hidden shadow-xs">
            <div className="overflow-x-auto">
              <table className="w-full text-left text-xs font-mono border-collapse">
                <thead>
                  <tr className="bg-slate-50/90 border-b border-slate-200 text-slate-500 font-bold uppercase text-[10px] tracking-wider">
                    <th className="py-3 px-4">Student</th>
                    <th className="py-3 px-4">Assigned Modules</th>
                    <th className="py-3 px-4">Required Lessons Progress</th>
                    <th className="py-3 px-4">Practical Projects</th>
                    <th className="py-3 px-4">Deadlines</th>
                    <th className="py-3 px-4 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {filteredSummaries.map((st) => {
                    const planCount = st.assigned_plans_count ?? st.assigned_modules_count ?? st.total_assigned_modules ?? 0;
                    const hasPlans = planCount > 0;
                    const overallPct = st.overall_completion_percentage ?? 0;
                    const is100 = hasPlans && overallPct === 100;
                    const studentDisplayName = st.student_name || st.name || 'Unnamed Student';
                    const studentDisplayEmail = st.student_email || st.email || '';

                    // Determine training status badge
                    let statusLabel = 'UNASSIGNED';
                    let statusBadgeClass = 'bg-slate-100 text-slate-600 border border-slate-200';
                    if (hasPlans) {
                      if (is100) {
                        statusLabel = 'COMPLETED';
                        statusBadgeClass = 'bg-emerald-50 text-emerald-700 border border-emerald-200';
                      } else if ((st.completed_required_lessons ?? 0) > 0 || (st.in_progress_plans_count ?? 0) > 0) {
                        statusLabel = 'IN PROGRESS';
                        statusBadgeClass = 'bg-blue-50 text-blue-700 border border-blue-200';
                      } else {
                        statusLabel = 'NOT STARTED';
                        statusBadgeClass = 'bg-amber-50 text-amber-700 border border-amber-200';
                      }
                    }

                    return (
                      <tr key={st.student_id} className="hover:bg-slate-50/70 transition-colors">
                        <td className="py-3.5 px-4 min-w-[200px]">
                          <div className="space-y-0.5">
                            <p className="font-bold text-slate-900 font-sans text-xs">{studentDisplayName}</p>
                            <p className="text-[11px] text-slate-500">{studentDisplayEmail}</p>
                            {st.college_name && (
                              <p className="text-[10px] text-slate-400 truncate max-w-xs">{st.college_name}</p>
                            )}
                          </div>
                        </td>

                        <td className="py-3.5 px-4">
                          {hasPlans ? (
                            <div className="space-y-1">
                              <div className="flex items-center gap-2">
                                <span className="text-xs font-bold text-slate-900">{planCount} assigned</span>
                                <span className={`text-[9px] font-mono px-1.5 py-0.2 rounded font-bold ${statusBadgeClass}`}>
                                  {statusLabel}
                                </span>
                              </div>
                              <div className="flex items-center gap-1.5 text-[10px] text-slate-500">
                                <span className="text-emerald-700">{st.completed_plans_count ?? st.completed_modules ?? 0} done</span>
                                <span>•</span>
                                <span>{st.in_progress_plans_count ?? st.in_progress_modules ?? 0} in prog</span>
                              </div>
                            </div>
                          ) : (
                            <div className="space-y-0.5">
                              <span className="text-[11px] text-slate-400 italic">No plans assigned</span>
                              <div>
                                <span className="text-[9px] font-mono px-1.5 py-0.2 rounded bg-slate-100 text-slate-500 border border-slate-200">
                                  UNASSIGNED
                                </span>
                              </div>
                            </div>
                          )}
                        </td>

                        <td className="py-3.5 px-4 min-w-[180px]">
                          {hasPlans ? (
                            <div className="space-y-1.5">
                              <div className="flex items-center justify-between text-[11px]">
                                <span className="font-bold text-slate-900">
                                  {overallPct}%
                                </span>
                                <span className="text-slate-500 text-[10px]">
                                  {st.completed_required_lessons ?? 0} / {st.total_required_lessons ?? 0} lessons
                                </span>
                              </div>
                              <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                                <div
                                  className={`h-1.5 rounded-full transition-all ${
                                    is100 ? 'bg-emerald-500' : 'bg-[#0453cd]'
                                  }`}
                                  style={{ width: `${overallPct}%` }}
                                />
                              </div>
                            </div>
                          ) : (
                            <span className="text-[11px] text-slate-400">0% (Unassigned)</span>
                          )}
                        </td>

                        <td className="py-3.5 px-4">
                          {(st.practical_projects_count ?? 0) > 0 ? (
                            <div className="space-y-0.5">
                              <span className="font-bold text-slate-900 text-xs">
                                {st.practical_projects_count} projects
                              </span>
                              <p className="text-[10px] text-emerald-700">
                                {st.practical_approved_count ?? 0} approved
                              </p>
                            </div>
                          ) : (
                            <span className="text-[11px] text-slate-400">None</span>
                          )}
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="space-y-0.5">
                            {st.has_overdue || (st.overdue_count ?? 0) > 0 ? (
                              <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-rose-50 text-rose-700 border border-rose-200 inline-flex items-center gap-1">
                                <AlertTriangle className="h-2.5 w-2.5" />
                                <span>Overdue</span>
                              </span>
                            ) : hasPlans ? (
                              <span className="text-[10px] text-emerald-700 font-semibold flex items-center gap-1">
                                <Check className="h-3 w-3" />
                                <span>On Track</span>
                              </span>
                            ) : (
                              <span className="text-[10px] text-slate-400">—</span>
                            )}
                            {st.earliest_target_date && (
                              <p className="text-[10px] text-slate-500 font-mono">
                                Target: {new Date(st.earliest_target_date).toLocaleDateString()}
                              </p>
                            )}
                          </div>
                        </td>

                        <td className="py-3.5 px-4 text-right">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => handleOpenDetail(st.student_id)}
                            className="text-xs font-mono h-7 px-2.5 inline-flex items-center gap-1"
                          >
                            <span>Inspect Progress</span>
                            <ArrowRight className="h-3 w-3" />
                          </Button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </div>

      {/* ── Student Detailed Progress Modal ── */}
      {detailModalOpen && (
        <Modal
          isOpen={detailModalOpen}
          onClose={() => setDetailModalOpen(false)}
          title={detailData ? `Learning Outcomes: ${detailData.student.name}` : 'Student Progress Detail'}
          maxWidth="4xl"
        >
          {loadingDetail ? (
            <div className="p-16 text-center">
              <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent mx-auto mb-3" />
              <p className="text-xs font-mono text-slate-500">Querying detailed completion records…</p>
            </div>
          ) : detailError ? (
            <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
              <AlertCircle className="h-4 w-4 text-rose-600 shrink-0" />
              <span>{detailError}</span>
            </div>
          ) : detailData ? (
            <div className="space-y-6 max-h-[75vh] overflow-y-auto pr-1">
              {/* Student Summary Bar (Section 5 A) */}
              <div className="p-4 bg-slate-50 rounded-2xl border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div className="space-y-1">
                  <div className="flex items-center gap-2">
                    <span className="text-[10px] font-mono font-bold bg-blue-50 text-[#0453cd] px-2 py-0.5 rounded border border-blue-200">
                      ENROLLED STUDENT
                    </span>
                    <span className="text-[10px] font-mono text-slate-400">ID: {detailData.student.id}</span>
                    {detailData.overallSummary.has_overdue && (
                      <span className="text-[10px] font-mono font-bold bg-rose-50 text-rose-700 px-2 py-0.5 rounded border border-rose-200 flex items-center gap-1">
                        <AlertTriangle className="h-3 w-3" />
                        OVERDUE
                      </span>
                    )}
                  </div>
                  <h3 className="text-base font-bold text-slate-900 font-sans">{detailData.student.name}</h3>
                  <p className="text-xs text-slate-500 font-mono">{detailData.student.email}</p>
                  {detailData.student.college_name && (
                    <p className="text-[11px] text-slate-500 font-mono flex items-center gap-1">
                      <Building className="h-3 w-3 text-slate-400" />
                      <span>{detailData.student.college_name}</span>
                      {detailData.student.qualification && <span>({detailData.student.qualification})</span>}
                    </p>
                  )}
                  <div className="flex items-center gap-3 pt-1 text-[11px] font-mono text-slate-600">
                    <span>
                      <strong>{detailData.overallSummary.total_assigned_modules}</strong> modules assigned
                    </span>
                    <span>•</span>
                    <span className="text-emerald-700 font-semibold">
                      {detailData.overallSummary.completed_modules} completed
                    </span>
                    <span>•</span>
                    <span className="text-blue-700">
                      {detailData.overallSummary.in_progress_modules} in progress
                    </span>
                    <span>•</span>
                    <span className="text-slate-500">
                      {detailData.overallSummary.not_started_modules} not started
                    </span>
                  </div>
                </div>

                <div className="p-3 bg-white rounded-xl border border-slate-200 min-w-[220px] text-right">
                  <span className="text-[10px] font-mono uppercase tracking-wider text-slate-400 block font-semibold">
                    Overall Curriculum Completion
                  </span>
                  <div className="flex items-center justify-end gap-2 mt-1">
                    <span className="text-xl font-bold font-mono text-[#0453cd]">
                      {detailData.overallSummary.overall_completion_percentage}%
                    </span>
                    <span className="text-xs font-mono text-slate-500">
                      ({detailData.overallSummary.completed_required_lessons}/
                      {detailData.overallSummary.total_required_lessons} req.)
                    </span>
                  </div>
                  <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden mt-1.5">
                    <div
                      className="h-1.5 rounded-full bg-[#0453cd]"
                      style={{ width: `${detailData.overallSummary.overall_completion_percentage}%` }}
                    />
                  </div>
                  <p className="text-[10px] font-mono text-slate-400 mt-1">
                    {Math.max(
                      0,
                      detailData.overallSummary.total_required_lessons -
                        detailData.overallSummary.completed_required_lessons
                    )}{' '}
                    required lessons remaining
                  </p>
                </div>
              </div>

              {/* Section 1: Assigned Training Modules & Lesson Checklist (Section 5 B) */}
              <div className="space-y-4">
                <div className="flex items-center justify-between border-b border-slate-200 pb-2">
                  <h4 className="text-xs font-mono font-bold text-slate-800 uppercase tracking-wider flex items-center gap-2">
                    <BookOpen className="h-4 w-4 text-[#0453cd]" />
                    <span>Assigned Modules & Lesson Checklist ({detailData.modules.length})</span>
                  </h4>
                  <span className="text-[10px] font-mono text-slate-400">Accredited Completion Records</span>
                </div>

                {detailData.modules.length === 0 ? (
                  <div className="p-8 text-center text-xs font-mono text-slate-400 border border-dashed border-slate-200 rounded-xl">
                    No modules currently assigned to this student.
                  </div>
                ) : (
                  <div className="space-y-4">
                    {detailData.modules.map((mObj) => {
                      const mod = mObj.module;
                      const prog = mObj.progress || {
                        total_required_lessons: 0,
                        completed_required_lessons: 0,
                        total_lessons: 0,
                        completed_lessons: 0,
                        completion_percentage: 0,
                        status: 'Not Started',
                      };
                      const isMod100 = (prog.completion_percentage ?? 0) === 100;
                      const remainingReqLessons = Math.max(
                        0,
                        prog.total_required_lessons - prog.completed_required_lessons
                      );

                      return (
                        <div
                          key={mod.id}
                          className="rounded-xl border border-slate-200 bg-white overflow-hidden shadow-xs"
                        >
                          {/* Module Header */}
                          <div className="p-3.5 bg-slate-50/80 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                            <div>
                              <div className="flex items-center gap-2">
                                <span className="text-[10px] font-mono font-bold bg-blue-50 text-[#0453cd] px-1.5 py-0.2 rounded border border-blue-200">
                                  {mod.category}
                                </span>
                                {mod.level && (
                                  <span className="text-[10px] font-mono bg-slate-100 text-slate-600 px-1.5 py-0.2 rounded">
                                    {mod.level}
                                  </span>
                                )}
                                <h5 className="text-xs font-bold text-slate-900 font-sans">{mod.title}</h5>
                              </div>
                              <div className="flex flex-wrap items-center gap-3 text-[10px] font-mono text-slate-500 mt-1">
                                {mObj.plan?.assigned_at && (
                                  <span>
                                    Assigned: {new Date(mObj.plan.assigned_at).toLocaleDateString()}
                                  </span>
                                )}
                                {mObj.plan?.target_completion_date && (
                                  <span className="text-blue-700 font-semibold">
                                    Target: {new Date(mObj.plan.target_completion_date).toLocaleDateString()}
                                  </span>
                                )}
                                {mObj.plan?.instructions && (
                                  <span className="italic text-slate-600">
                                    Note: &quot;{mObj.plan.instructions}&quot;
                                  </span>
                                )}
                              </div>
                            </div>

                            <div className="flex items-center gap-3">
                              <span
                                className={`text-[10px] font-mono font-bold px-2 py-0.5 rounded-full ${
                                  isMod100
                                    ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                    : 'bg-blue-50 text-blue-700 border border-blue-200'
                                }`}
                              >
                                {prog.completion_percentage}% COMPLETE
                              </span>
                              <span className="text-xs font-mono text-slate-500">
                                {prog.completed_required_lessons} / {prog.total_required_lessons} req.
                                {remainingReqLessons > 0 && ` (${remainingReqLessons} left)`}
                              </span>
                            </div>
                          </div>

                          {/* Chapters and Lessons */}
                          <div className="p-3 space-y-3">
                            {(mObj.chapters || []).map((chObj) => (
                              <div key={chObj.chapter.id} className="space-y-1.5">
                                <p className="text-[11px] font-mono font-bold text-slate-700 flex items-center gap-1.5">
                                  <Layers className="h-3 w-3 text-slate-400" />
                                  <span>{chObj.chapter.title}</span>
                                </p>

                                <div className="space-y-1 pl-4">
                                  {(chObj.lessons || []).map((les) => (
                                    <div
                                      key={les.id}
                                      className="flex items-center justify-between p-2 rounded-lg bg-slate-50 border border-slate-100 text-xs font-mono"
                                    >
                                      <div className="flex items-center gap-2 min-w-0">
                                        {les.is_completed ? (
                                          <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                                        ) : (
                                          <div className="h-4 w-4 rounded-full border-2 border-slate-300 shrink-0" />
                                        )}
                                        <span
                                          className={`truncate font-sans ${
                                            les.is_completed ? 'text-slate-800 font-semibold' : 'text-slate-500'
                                          }`}
                                        >
                                          {les.title}
                                        </span>
                                        <span
                                          className={`text-[9px] px-1 py-0.2 rounded font-mono font-bold ${
                                            les.is_required
                                              ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                              : 'bg-slate-200/60 text-slate-600'
                                          }`}
                                        >
                                          {les.is_required ? 'REQ' : 'OPT'}
                                        </span>
                                      </div>

                                      <span className="text-[10px] text-slate-400 shrink-0 ml-2 font-mono">
                                        {les.is_completed && les.completed_at
                                          ? `Completed ${new Date(les.completed_at).toLocaleDateString()}`
                                          : 'Pending completion'}
                                      </span>
                                    </div>
                                  ))}
                                </div>
                              </div>
                            ))}

                            {/* Standalone Lessons */}
                            {(mObj.standaloneLessons || []).length > 0 && (
                              <div className="space-y-1 pl-2 pt-1 border-t border-slate-100">
                                <span className="text-[10px] font-mono text-slate-400 uppercase font-semibold">
                                  Additional Lessons
                                </span>
                                {(mObj.standaloneLessons || []).map((les) => (
                                  <div
                                    key={les.id}
                                    className="flex items-center justify-between p-2 rounded-lg bg-slate-50 border border-slate-100 text-xs font-mono"
                                  >
                                    <div className="flex items-center gap-2 min-w-0">
                                      {les.is_completed ? (
                                        <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                                      ) : (
                                        <div className="h-4 w-4 rounded-full border-2 border-slate-300 shrink-0" />
                                      )}
                                      <span className="truncate">{les.title}</span>
                                      <span
                                        className={`text-[9px] px-1 py-0.2 rounded font-mono font-bold ${
                                          les.is_required
                                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                            : 'bg-slate-200/60 text-slate-600'
                                        }`}
                                      >
                                        {les.is_required ? 'REQ' : 'OPT'}
                                      </span>
                                    </div>
                                    <span className="text-[10px] text-slate-400">
                                      {les.is_completed ? 'Completed' : 'Pending'}
                                    </span>
                                  </div>
                                ))}
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                )}
              </div>

              {/* Section 2: Practical Drawing Assignments & Evaluations (Section 5 C) */}
              <div className="space-y-3 pt-2">
                <div className="flex items-center justify-between border-b border-slate-200 pb-2">
                  <h4 className="text-xs font-mono font-bold text-slate-800 uppercase tracking-wider flex items-center gap-2">
                    <FolderKanban className="h-4 w-4 text-[#0453cd]" />
                    <span>Practical Drawing Projects & Studio Evaluations ({(detailData.practicalProjects || []).length})</span>
                  </h4>
                  <span className="text-[10px] font-mono text-slate-400">Accredited CAD Submissions</span>
                </div>

                {(detailData.practicalProjects || []).length === 0 ? (
                  <div className="p-8 text-center text-xs font-mono text-slate-400 border border-dashed border-slate-200 rounded-xl">
                    No practical assignments recorded yet for this student.
                  </div>
                ) : (
                  <div className="space-y-3">
                    {(detailData.practicalProjects || []).map((prj) => (
                      <div
                        key={prj.id}
                        className="p-4 rounded-xl border border-slate-200 bg-white hover:border-slate-300 transition-all space-y-2 text-xs"
                      >
                        <div className="flex items-start justify-between gap-3">
                          <div className="space-y-1">
                            <div className="flex items-center gap-2">
                              <span className="text-[10px] font-mono font-bold bg-blue-50 text-[#0453cd] px-1.5 py-0.2 rounded border border-blue-200">
                                {prj.id}
                              </span>
                              <Badge status={prj.status as any} size="sm" />
                              <span className="text-[11px] font-mono text-slate-500">
                                {prj.drawing_type} • Round {prj.correction_round}
                              </span>
                            </div>
                            <h5 className="text-sm font-bold text-slate-900 font-sans">{prj.project_name}</h5>
                          </div>

                          <Link
                            href={`/projects/${prj.id}`}
                            target="_blank"
                            className="text-[11px] font-mono text-[#0453cd] hover:underline flex items-center gap-1"
                          >
                            <span>Inspect Workspace</span>
                            <ExternalLink className="h-3 w-3" />
                          </Link>
                        </div>

                        {/* Evaluation Details */}
                        {prj.evaluation ? (
                          <div className="p-3 bg-slate-50 rounded-lg border border-slate-200 space-y-1 text-xs">
                            <div className="flex items-center justify-between">
                              <span className="font-mono text-[10px] uppercase font-bold text-slate-500">
                                Admin Evaluation
                              </span>
                              <span
                                className={`font-mono text-[10px] font-bold px-2 py-0.5 rounded ${
                                  prj.evaluation.overall_result === 'APPROVED'
                                    ? 'bg-emerald-100 text-emerald-800 border border-emerald-200'
                                    : 'bg-amber-100 text-amber-800 border border-amber-200'
                                }`}
                              >
                                {prj.evaluation.overall_result}
                              </span>
                            </div>
                            {prj.evaluation.score !== null && (
                              <p className="font-mono text-slate-700">
                                Score: <strong className="text-slate-900">{prj.evaluation.score}/100</strong>
                              </p>
                            )}
                            {prj.evaluation.general_feedback && (
                              <p className="font-sans text-slate-600 mt-1 italic">
                                &quot;{prj.evaluation.general_feedback}&quot;
                              </p>
                            )}
                          </div>
                        ) : (
                          <div className="text-[11px] font-mono text-slate-400 italic">
                            Awaiting drawing submission & review.
                          </div>
                        )}
                      </div>
                    ))}
                  </div>
                )}
              </div>

              {/* Section 3: Completion History (Section 5 D) */}
              <div className="space-y-3 pt-2">
                <div className="flex items-center justify-between border-b border-slate-200 pb-2">
                  <h4 className="text-xs font-mono font-bold text-slate-800 uppercase tracking-wider flex items-center gap-2">
                    <Clock className="h-4 w-4 text-[#0453cd]" />
                    <span>Completion & Activity Timeline ({(detailData.completionHistory || []).length})</span>
                  </h4>
                  <span className="text-[10px] font-mono text-slate-400">Chronological Milestones</span>
                </div>

                {(detailData.completionHistory || []).length === 0 ? (
                  <div className="p-8 text-center text-xs font-mono text-slate-400 border border-dashed border-slate-200 rounded-xl">
                    No completion milestones recorded yet for this student.
                  </div>
                ) : (
                  <div className="space-y-2">
                    {(detailData.completionHistory || []).map((item) => (
                      <div
                        key={item.id}
                        className="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs font-mono"
                      >
                        <div className="flex items-center gap-2.5 min-w-0">
                          {item.type === 'LESSON_COMPLETED' ? (
                            <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                          ) : item.type === 'PROJECT_EVALUATED' ? (
                            <Award className="h-4 w-4 text-[#0453cd] shrink-0" />
                          ) : (
                            <FileCheck className="h-4 w-4 text-blue-600 shrink-0" />
                          )}
                          <div className="min-w-0">
                            <p className="font-bold text-slate-900 font-sans truncate">{item.title}</p>
                            <p className="text-[10px] text-slate-500 font-mono truncate">{item.subtitle}</p>
                          </div>
                        </div>

                        <div className="flex items-center gap-2 shrink-0 ml-3">
                          <span className="text-[9px] font-mono font-bold px-1.5 py-0.5 rounded bg-white text-slate-600 border border-slate-200">
                            {item.badge || item.type}
                          </span>
                          <span className="text-[10px] text-slate-400">
                            {new Date(item.timestamp).toLocaleString()}
                          </span>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          ) : null}
        </Modal>
      )}
    </AdminShell>
  );
}

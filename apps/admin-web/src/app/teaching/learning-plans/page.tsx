'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { Badge } from '@/components/ui/Badge';
import { adminApi } from '@/lib/api';
import { User, TrainingModule, StudentLearningPlan } from '@/lib/types';
import {
  Compass,
  GraduationCap,
  PlusCircle,
  Search,
  BookOpen,
  Calendar,
  Clock,
  CheckCircle2,
  AlertCircle,
  Trash2,
  UserCheck,
  Building,
  Check,
  ChevronRight,
  Filter,
  FileText,
  AlertTriangle,
} from 'lucide-react';

export default function StudentLearningPlansPage() {
  const [students, setStudents] = useState<User[]>([]);
  const [modules, setModules] = useState<TrainingModule[]>([]);
  const [plans, setPlans] = useState<StudentLearningPlan[]>([]);
  const [selectedStudent, setSelectedStudent] = useState<User | null>(null);

  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Search & filter
  const [studentSearch, setStudentSearch] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // Assign Plan Modal
  const [assignModalOpen, setAssignModalOpen] = useState<boolean>(false);
  const [selectedModuleIds, setSelectedModuleIds] = useState<string[]>([]);
  const [targetDate, setTargetDate] = useState<string>('');
  const [instructions, setInstructions] = useState<string>('');
  const [assigning, setAssigning] = useState<boolean>(false);
  const [assignError, setAssignError] = useState<string | null>(null);

  const loadData = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [allStudents, allModules, allPlans] = await Promise.all([
        adminApi.getUsers('STUDENT'),
        adminApi.getTrainingModules({ status: 'PUBLISHED' }),
        adminApi.getAllLearningPlans(),
      ]);

      setStudents(allStudents.filter((u) => u.role === 'STUDENT'));
      setModules(allModules || []);
      setPlans(allPlans || []);

      // Auto-select first student if none selected
      if (allStudents.length > 0 && !selectedStudent) {
        setSelectedStudent(allStudents[0]);
      }
    } catch (err: any) {
      setError(err.message || 'Failed to load students and learning plans.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Filter students based on search
  const filteredStudents = useMemo(() => {
    return students.filter((s) => {
      const matchesSearch =
        s.name.toLowerCase().includes(studentSearch.toLowerCase()) ||
        s.email.toLowerCase().includes(studentSearch.toLowerCase()) ||
        s.college_name?.toLowerCase().includes(studentSearch.toLowerCase());
      return matchesSearch;
    });
  }, [students, studentSearch]);

  // Plans belonging to the selected student
  const studentPlans = useMemo(() => {
    if (!selectedStudent) return [];
    return plans.filter((p) => p.student_id === selectedStudent.id);
  }, [plans, selectedStudent]);

  // Overall Plan Telemetry
  const stats = useMemo(() => {
    const totalStudents = students.length;
    const totalPlans = plans.length;
    const completed = plans.filter((p) => p.status === 'COMPLETED').length;
    const inProgress = plans.filter((p) => p.status === 'IN_PROGRESS' || p.status === 'ASSIGNED').length;

    const now = new Date();
    const overdue = plans.filter((p) => {
      if (!p.target_completion_date) return false;
      return new Date(p.target_completion_date) < now && p.status !== 'COMPLETED';
    }).length;

    return { totalStudents, totalPlans, completed, inProgress, overdue };
  }, [students, plans]);

  // Module toggle in Assign Modal
  const handleToggleModule = (modId: string) => {
    setSelectedModuleIds((prev) =>
      prev.includes(modId) ? prev.filter((id) => id !== modId) : [...prev, modId]
    );
  };

  const handleOpenAssignModal = () => {
    setSelectedModuleIds([]);
    setTargetDate('');
    setInstructions('');
    setAssignError(null);
    setAssignModalOpen(true);
  };

  const handleSavePlan = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStudent) return;
    if (selectedModuleIds.length === 0) {
      setAssignError('Please select at least one training module.');
      return;
    }

    setAssigning(true);
    setAssignError(null);

    try {
      await adminApi.assignLearningPlan(selectedStudent.id, {
        moduleIds: selectedModuleIds,
        targetCompletionDate: targetDate || null,
        instructions: instructions.trim() || undefined,
      });

      setAssignModalOpen(false);
      loadData(true);
    } catch (err: any) {
      setAssignError(err.message || 'Failed to assign learning plan.');
    } finally {
      setAssigning(false);
    }
  };

  const handleRevokePlan = async (planId: string) => {
    if (!confirm('Revoke this learning plan? The student will no longer see this module in their training hub.')) return;
    try {
      await adminApi.revokeLearningPlan(planId);
      loadData(true);
    } catch (err: any) {
      alert(err.message || 'Failed to revoke learning plan.');
    }
  };

  return (
    <AdminShell
      title="Student Learning Plans"
      subtitle="Assign individualized training modules, curriculum paths, and target completion dates to specific students."
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
            <p className="text-[11px] text-slate-500 font-mono mt-1">Total active apprentices</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Active Learning Plans
              </p>
              <Compass className="h-4 w-4 text-blue-600" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.inProgress}</p>
            <p className="text-[11px] text-blue-700 font-mono mt-1">Individualized tracks</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Completed Tracks
              </p>
              <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.completed}</p>
            <p className="text-[11px] text-emerald-700 font-mono mt-1">Curriculum fulfilled</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Overdue Deadlines
              </p>
              <AlertTriangle className="h-4 w-4 text-amber-500" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.overdue}</p>
            <p className="text-[11px] text-amber-700 font-mono mt-1">Requires follow-up</p>
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

        {/* ── Two-Column Student Directory + Plan Inspector ── */}
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          {/* Left Column: Student Directory (5 cols) */}
          <div className="lg:col-span-5 space-y-4">
            <div className="flex items-center justify-between">
              <h3 className="text-sm font-bold font-mono text-slate-900 flex items-center gap-2">
                <GraduationCap className="h-4 w-4 text-[#0453cd]" />
                <span>Student Directory ({filteredStudents.length})</span>
              </h3>
            </div>

            <div className="relative">
              <Search className="h-3.5 w-3.5 text-slate-400 absolute left-2.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={studentSearch}
                onChange={(e) => setStudentSearch(e.target.value)}
                placeholder="Search students by name, email, college…"
                className="w-full pl-8 pr-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            {loading ? (
              <Card className="p-12 text-center bg-white border-slate-200">
                <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent mx-auto mb-3" />
                <p className="text-xs font-mono text-slate-500">Querying student directory…</p>
              </Card>
            ) : filteredStudents.length === 0 ? (
              <Card className="p-12 text-center bg-white border-slate-200">
                <p className="text-xs font-mono text-slate-500">No students found.</p>
              </Card>
            ) : (
              <div className="space-y-2 max-h-[580px] overflow-y-auto pr-1">
                {filteredStudents.map((st) => {
                  const isSelected = selectedStudent?.id === st.id;
                  const stPlans = plans.filter((p) => p.student_id === st.id);

                  return (
                    <div
                      key={st.id}
                      onClick={() => setSelectedStudent(st)}
                      className={`p-3.5 rounded-xl border transition-all cursor-pointer relative bg-white ${
                        isSelected
                          ? 'border-[#0453cd] ring-2 ring-[#0453cd]/20 shadow-md'
                          : 'border-slate-200 hover:border-slate-300 hover:shadow-xs'
                      }`}
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div className="min-w-0 flex-1 space-y-0.5">
                          <p className="font-bold text-xs text-slate-900 truncate">{st.name}</p>
                          <p className="text-[11px] font-mono text-slate-500 truncate">{st.email}</p>
                          {st.college_name && (
                            <p className="text-[10px] text-slate-600 truncate flex items-center gap-1">
                              <Building className="h-3 w-3 text-slate-400 shrink-0" />
                              <span>{st.college_name}</span>
                            </p>
                          )}
                        </div>

                        <div className="flex flex-col items-end gap-1.5 shrink-0">
                          <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded-full bg-blue-50 text-[#0453cd] border border-blue-200">
                            {stPlans.length} plans
                          </span>
                          <ChevronRight
                            className={`h-3.5 w-3.5 transition-colors ${
                              isSelected ? 'text-[#0453cd]' : 'text-slate-300'
                            }`}
                          />
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>
            )}
          </div>

          {/* Right Column: Selected Student's Assigned Training Plans (7 cols) */}
          <div className="lg:col-span-7 space-y-4">
            {selectedStudent ? (
              <Card className="p-5 bg-white border-slate-200 space-y-5">
                {/* Student Header Strip */}
                <div className="border-b border-slate-200 pb-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div className="space-y-1">
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-mono font-bold bg-purple-50 text-purple-700 px-2 py-0.5 rounded border border-purple-200">
                        STUDENT APPRENTICE
                      </span>
                      <span className="text-[10px] font-mono text-slate-400">ID: {selectedStudent.id}</span>
                    </div>
                    <h3 className="text-base font-bold text-slate-900">{selectedStudent.name}</h3>
                    <p className="text-xs text-slate-500 font-mono">{selectedStudent.email}</p>
                  </div>
                  <div>
                    <Button
                      variant="primary"
                      size="sm"
                      onClick={handleOpenAssignModal}
                      className="flex items-center gap-1.5 shadow-sm"
                    >
                      <PlusCircle className="h-4 w-4" />
                      <span>Assign New Plan</span>
                    </Button>
                  </div>

                  <Button
                    variant="primary"
                    size="sm"
                    onClick={handleOpenAssignModal}
                    className="flex items-center gap-1.5 text-xs font-mono self-start sm:self-auto"
                  >
                    <PlusCircle className="h-3.5 w-3.5" />
                    <span>Assign Module</span>
                  </Button>
                </div>

                {/* Plans List */}
                <div className="space-y-3">
                  <div className="flex items-center justify-between">
                    <h4 className="text-xs font-mono font-bold text-slate-800 uppercase tracking-wider">
                      Assigned Modules & Tracks ({studentPlans.length})
                    </h4>
                    <span className="text-[11px] font-mono text-slate-400">
                      Enforced via Backend Access Control
                    </span>
                  </div>

                  {studentPlans.length === 0 ? (
                    <div className="p-12 text-center border border-dashed border-slate-200 rounded-2xl bg-slate-50/50 space-y-2">
                      <Compass className="h-8 w-8 text-slate-400 mx-auto" />
                      <p className="text-xs font-bold text-slate-700">No Learning Plans Assigned</p>
                      <p className="text-[11px] text-slate-500 font-sans max-w-sm mx-auto">
                        This student currently cannot access any training modules. Assign customized modules and chapters to activate their learning hub.
                      </p>
                      <div className="pt-2">
                        <Button variant="outline" size="sm" onClick={handleOpenAssignModal}>
                          <PlusCircle className="h-3.5 w-3.5 mr-1 text-[#0453cd]" />
                          <span>Assign Training Plan</span>
                        </Button>
                      </div>
                    </div>
                  ) : (
                    <div className="space-y-3">
                      {studentPlans.map((plan) => {
                        const isOverdue =
                          plan.target_completion_date &&
                          new Date(plan.target_completion_date) < new Date() &&
                          plan.status !== 'COMPLETED';

                        return (
                          <div
                            key={plan.id}
                            className="p-4 rounded-xl border border-slate-200 bg-white hover:border-slate-300 transition-all space-y-3"
                          >
                            <div className="flex items-start justify-between gap-3">
                              <div className="space-y-1 min-w-0 flex-1">
                                <div className="flex items-center gap-2 flex-wrap">
                                  <span className="text-[10px] font-mono font-bold bg-blue-50 text-[#0453cd] px-2 py-0.5 rounded border border-blue-200">
                                    {plan.module_category || 'Training Module'}
                                  </span>
                                  <span
                                    className={`text-[10px] font-mono font-bold px-2 py-0.5 rounded-full ${
                                      plan.status === 'COMPLETED'
                                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                        : 'bg-blue-50 text-blue-700 border border-blue-200'
                                    }`}
                                  >
                                    {plan.status}
                                  </span>
                                  {isOverdue && (
                                    <span className="text-[10px] font-mono font-bold px-2 py-0.5 rounded bg-rose-50 text-rose-700 border border-rose-200 flex items-center gap-1">
                                      <AlertTriangle className="h-2.5 w-2.5" />
                                      <span>OVERDUE</span>
                                    </span>
                                  )}
                                </div>

                                <h5 className="text-sm font-bold text-slate-900 truncate">
                                  {plan.module_title || plan.module_id}
                                </h5>

                                <div className="flex items-center gap-3 text-[11px] font-mono text-slate-500 flex-wrap">
                                  <span>Assigned: {new Date(plan.assigned_at).toLocaleDateString()}</span>
                                  {plan.target_completion_date && (
                                    <>
                                      <span>•</span>
                                      <span className={isOverdue ? 'text-rose-600 font-bold' : ''}>
                                        Target: {new Date(plan.target_completion_date).toLocaleDateString()}
                                      </span>
                                    </>
                                  )}
                                </div>
                              </div>

                              <button
                                onClick={() => handleRevokePlan(plan.id)}
                                title="Revoke assignment"
                                className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer shrink-0"
                              >
                                <Trash2 className="h-4 w-4" />
                              </button>
                            </div>

                            {plan.instructions && (
                              <div className="p-2.5 bg-slate-50 rounded-lg border border-slate-100 text-xs font-sans text-slate-700">
                                <span className="font-mono text-[10px] uppercase tracking-wider text-slate-400 block mb-0.5">
                                  Admin Instructions:
                                </span>
                                <p>{plan.instructions}</p>
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              </Card>
            ) : (
              <Card className="p-16 text-center bg-white border-slate-200">
                <p className="text-xs font-mono text-slate-400">Select a student from the directory to manage their learning plans.</p>
              </Card>
            )}
          </div>
        </div>
      </div>

      {/* ── Assign Plan Modal ── */}
      {assignModalOpen && selectedStudent && (
        <Modal
          isOpen={assignModalOpen}
          onClose={() => !assigning && setAssignModalOpen(false)}
          title={`Assign Training Plan to ${selectedStudent.name}`}
          maxWidth="2xl"
        >
          <form onSubmit={handleSavePlan} className="space-y-4">
            {assignError && (
              <div className="p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{assignError}</span>
              </div>
            )}

            <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 text-xs font-mono space-y-1">
              <span className="text-[10px] uppercase text-slate-400 font-bold block">Target Student</span>
              <p className="font-bold text-slate-900">{selectedStudent.name} ({selectedStudent.email})</p>
              <p className="text-slate-500 text-[11px]">{selectedStudent.college_name || 'Student Apprentice'}</p>
            </div>

            {/* Module Multi-Selection */}
            <div>
              <div className="flex items-center justify-between mb-1.5">
                <label className="text-xs font-mono font-bold text-slate-800">
                  Select Published Modules * ({selectedModuleIds.length} selected)
                </label>
                <span className="text-[10px] font-mono text-slate-400">Only authorized modules will be visible to student</span>
              </div>

              {modules.length === 0 ? (
                <div className="p-6 text-center border border-dashed border-slate-200 rounded-xl text-xs font-mono text-slate-400">
                  No published training modules available. Please publish modules in Training Modules first.
                </div>
              ) : (
                <div className="space-y-2 max-h-56 overflow-y-auto border border-slate-200 rounded-xl p-2 bg-slate-50/50">
                  {modules.map((mod) => {
                    const isChecked = selectedModuleIds.includes(mod.id);
                    return (
                      <div
                        key={mod.id}
                        onClick={() => handleToggleModule(mod.id)}
                        className={`p-3 rounded-xl border transition-all cursor-pointer flex items-center justify-between text-xs ${
                          isChecked
                            ? 'bg-blue-50/70 border-[#0453cd] shadow-xs'
                            : 'bg-white border-slate-200 hover:border-slate-300'
                        }`}
                      >
                        <div className="min-w-0 flex-1 space-y-0.5">
                          <div className="flex items-center gap-2">
                            <span className="text-[10px] font-mono font-bold bg-white text-[#0453cd] px-1.5 py-0.2 rounded border border-blue-200">
                              {mod.category}
                            </span>
                            <span className="font-bold text-slate-900 truncate">{mod.title}</span>
                          </div>
                          <p className="text-[11px] text-slate-500 font-sans line-clamp-1">
                            {mod.description || 'Architectural training module'}
                          </p>
                        </div>

                        <div className="h-5 w-5 rounded-md border flex items-center justify-center shrink-0 ml-3 transition-colors">
                          {isChecked && <Check className="h-3.5 w-3.5 text-[#0453cd]" />}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Target Completion Date */}
            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Target Completion Date (Optional)
              </label>
              <input
                type="date"
                value={targetDate}
                onChange={(e) => setTargetDate(e.target.value)}
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            {/* Instructions */}
            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Student-Specific Instructions & Learning Goals
              </label>
              <textarea
                rows={3}
                value={instructions}
                onChange={(e) => setInstructions(e.target.value)}
                placeholder="e.g. Focus specifically on municipal setback calculation and structural drawings before your review deadline…"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div className="pt-3 border-t border-slate-200 flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={assigning}
                onClick={() => setAssignModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                disabled={assigning || selectedModuleIds.length === 0}
                type="submit"
                className="flex items-center gap-1.5"
              >
                {assigning ? (
                  <>
                    <span className="h-3 w-3 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Assigning…</span>
                  </>
                ) : (
                  <>
                    <Check className="h-3.5 w-3.5" />
                    <span>Confirm & Authorize</span>
                  </>
                )}
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </AdminShell>
  );
}

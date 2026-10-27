'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import { TrainingModule, ModulePublicationStatus, User } from '@/lib/types';
import {
  BookOpen,
  PlusCircle,
  Search,
  Layers,
  GraduationCap,
  Clock,
  CheckCircle2,
  AlertCircle,
  Edit3,
  Archive,
  ArrowRight,
  ExternalLink,
  Eye,
  Filter,
  Check,
  FileText,
  Sparkles,
  UserCheck,
} from 'lucide-react';

const CATEGORIES = ['ALL', 'Architectural', 'Structural', 'Interior', 'Approval'];
const LEVELS = ['ALL', 'Beginner', 'Intermediate', 'Advanced'];
const STATUSES: Array<'ALL' | ModulePublicationStatus> = ['ALL', 'PUBLISHED', 'DRAFT', 'ARCHIVED'];

export default function TeachingModulesPage() {
  const router = useRouter();
  const [modules, setModules] = useState<TrainingModule[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedCategory, setSelectedCategory] = useState<string>('ALL');
  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');
  const [selectedLevel, setSelectedLevel] = useState<string>('ALL');

  // Modal State for Create / Edit Module Details
  const [modalOpen, setModalOpen] = useState<boolean>(false);
  const [editingModule, setEditingModule] = useState<TrainingModule | null>(null);
  const [saving, setSaving] = useState<boolean>(false);
  const [formError, setFormError] = useState<string | null>(null);

  // Form Fields
  const [formTitle, setFormTitle] = useState<string>('');
  const [formCategory, setFormCategory] = useState<string>('Architectural');
  const [formLevel, setFormLevel] = useState<string>('Beginner');
  const [formStatus, setFormStatus] = useState<ModulePublicationStatus>('PUBLISHED');
  const [formDescription, setFormDescription] = useState<string>('');
  const [formObjectives, setFormObjectives] = useState<string>('');
  const [formThumbnail, setFormThumbnail] = useState<string>('');

  // Student Assignment State (Create Modal)
  const [students, setStudents] = useState<User[]>([]);
  const [loadingStudents, setLoadingStudents] = useState<boolean>(false);
  const [assignToStudent, setAssignToStudent] = useState<boolean>(false);
  const [selectedStudentId, setSelectedStudentId] = useState<string>('');
  const [targetCompletionDate, setTargetCompletionDate] = useState<string>('');
  const [assignmentInstructions, setAssignmentInstructions] = useState<string>('');
  const [createdModuleId, setCreatedModuleId] = useState<string | null>(null);

  const loadStudents = async () => {
    if (students.length > 0) return;
    try {
      setLoadingStudents(true);
      const data = await adminApi.getUsers('STUDENT');
      setStudents(data || []);
    } catch (e) {
      console.warn('Failed to load student directory for assignment:', e);
    } finally {
      setLoadingStudents(false);
    }
  };

  const loadData = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getTrainingModules({
        category: selectedCategory !== 'ALL' ? selectedCategory : undefined,
        status: selectedStatus !== 'ALL' ? selectedStatus : undefined,
        search: searchQuery.trim() || undefined,
      });
      setModules(data || []);
    } catch (err: any) {
      setError(err.message || 'Failed to load persistent training modules.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [selectedCategory, selectedStatus]);

  const handleOpenCreateModal = () => {
    setEditingModule(null);
    setFormTitle('');
    setFormCategory('Architectural');
    setFormLevel('Beginner');
    setFormStatus('PUBLISHED');
    setFormDescription('');
    setFormObjectives('');
    setFormThumbnail('');
    setAssignToStudent(false);
    setSelectedStudentId('');
    setTargetCompletionDate('');
    setAssignmentInstructions('');
    setCreatedModuleId(null);
    setFormError(null);
    setModalOpen(true);
    loadStudents();
  };

  const handleOpenEditModal = (mod: TrainingModule) => {
    setEditingModule(mod);
    setFormTitle(mod.title);
    setFormCategory(mod.category);
    setFormLevel(mod.level || 'Beginner');
    setFormStatus(mod.publication_status);
    setFormDescription(mod.description || '');
    setFormObjectives(mod.learning_objectives || '');
    setFormThumbnail(mod.thumbnail_url || '');
    setCreatedModuleId(null);
    setFormError(null);
    setModalOpen(true);
  };

  const handleSaveModule = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!formTitle.trim()) {
      setFormError('Module title is required.');
      return;
    }

    if (!editingModule && assignToStudent && !selectedStudentId) {
      setFormError('Please select a student apprentice from the directory, or uncheck the assignment option.');
      return;
    }

    setSaving(true);
    setFormError(null);

    try {
      if (editingModule) {
        await adminApi.updateTrainingModule(editingModule.id, {
          title: formTitle.trim(),
          category: formCategory,
          level: formLevel,
          publication_status: formStatus,
          description: formDescription.trim(),
          learning_objectives: formObjectives.trim(),
          thumbnail_url: formThumbnail.trim() || undefined,
        });
        setModalOpen(false);
        loadData(true);
      } else {
        const res = await adminApi.createTrainingModule({
          id: createdModuleId || undefined,
          title: formTitle.trim(),
          category: formCategory,
          level: formLevel,
          publication_status: formStatus,
          description: formDescription.trim(),
          learning_objectives: formObjectives.trim(),
          thumbnail_url: formThumbnail.trim() || undefined,
          assign_to_student_id: assignToStudent ? selectedStudentId : undefined,
          target_completion_date: assignToStudent && targetCompletionDate ? targetCompletionDate : undefined,
          assignment_instructions: assignToStudent && assignmentInstructions.trim() ? assignmentInstructions.trim() : undefined,
        });

        if (res.id) {
          setCreatedModuleId(res.id);
          setModalOpen(false);
          router.push(`/teaching/modules/${res.id}`);
          return;
        }
      }
    } catch (err: any) {
      const existingId = err.data?.id || err.data?.moduleId;
      if (existingId) {
        setCreatedModuleId(existingId);
        setFormError(`${err.message || 'Module created, but assigning student failed.'} The module is saved (ID: ${existingId}). You can select another student and retry, or cancel to open the curriculum.`);
      } else {
        setFormError(err.message || 'Failed to save module.');
      }
    } finally {
      setSaving(false);
    }
  };

  const handleArchiveModule = async (moduleId: string) => {
    if (!confirm('Archive this training module? Existing student progress will be preserved.')) return;
    try {
      await adminApi.deleteTrainingModule(moduleId);
      loadData(true);
    } catch (err: any) {
      alert(err.message || 'Failed to archive module.');
    }
  };

  // Filtered in-memory for instant search and level
  const filteredModules = useMemo(() => {
    return modules.filter((m) => {
      const matchesSearch =
        !searchQuery ||
        m.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        m.description?.toLowerCase().includes(searchQuery.toLowerCase()) ||
        m.id.toLowerCase().includes(searchQuery.toLowerCase());
      const matchesLevel = selectedLevel === 'ALL' || m.level === selectedLevel;
      return matchesSearch && matchesLevel;
    });
  }, [modules, searchQuery, selectedLevel]);

  // Counts
  const stats = useMemo(() => {
    const total = modules.length;
    const published = modules.filter((m) => m.publication_status === 'PUBLISHED').length;
    const draft = modules.filter((m) => m.publication_status === 'DRAFT').length;
    const archived = modules.filter((m) => m.publication_status === 'ARCHIVED').length;
    return { total, published, draft, archived };
  }, [modules]);

  return (
    <AdminShell
      title="Training Modules"
      subtitle="Author, configure, publish, and manage architectural training modules and curriculum."
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      <div className="space-y-6">
        {/* ── Stats Strip ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Total Modules
              </p>
              <BookOpen className="h-4 w-4 text-[#0453cd]" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.total}</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Curriculum catalogue</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Published & Active
              </p>
              <CheckCircle2 className="h-4 w-4 text-emerald-600" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.published}</p>
            <p className="text-[11px] text-emerald-700 font-mono mt-1">Ready for student assignment</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Drafts
              </p>
              <Clock className="h-4 w-4 text-amber-500" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.draft}</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Under admin preparation</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <div className="flex items-center justify-between mb-1">
              <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold">
                Archived
              </p>
              <Archive className="h-4 w-4 text-slate-400" />
            </div>
            <p className="text-2xl font-bold font-mono text-slate-900">{stats.archived}</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Preserving historical progress</p>
          </div>
        </div>

        {/* ── Filters & Search ── */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-3 bg-white p-4 rounded-xl border border-slate-200">
          <div className="relative flex-1 max-w-md">
            <Search className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search module title, objectives, ID…"
              className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            />
          </div>

          <div className="flex items-center gap-2 flex-wrap text-xs font-mono">
            {/* Category Filter */}
            <select
              value={selectedCategory}
              onChange={(e) => setSelectedCategory(e.target.value)}
              className="px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            >
              {CATEGORIES.map((c) => (
                <option key={c} value={c}>
                  {c === 'ALL' ? 'All Disciplines' : c}
                </option>
              ))}
            </select>

            {/* Status Filter */}
            <select
              value={selectedStatus}
              onChange={(e) => setSelectedStatus(e.target.value)}
              className="px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            >
              {STATUSES.map((s) => (
                <option key={s} value={s}>
                  {s === 'ALL' ? 'All Statuses' : s}
                </option>
              ))}
            </select>

            {/* Level Filter */}
            <select
              value={selectedLevel}
              onChange={(e) => setSelectedLevel(e.target.value)}
              className="px-2.5 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            >
              {LEVELS.map((lvl) => (
                <option key={lvl} value={lvl}>
                  {lvl === 'ALL' ? 'All Difficulty' : lvl}
                </option>
              ))}
            </select>

            <Button
              variant="primary"
              size="sm"
              onClick={handleOpenCreateModal}
              className="flex items-center gap-1.5 shadow-sm ml-auto"
            >
              <PlusCircle className="h-4 w-4" />
              <span>New Training Module</span>
            </Button>
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

        {/* ── Modules Grid ── */}
        {loading ? (
          <Card className="p-16 text-center bg-white border-slate-200">
            <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent mx-auto mb-3" />
            <p className="text-xs font-mono text-slate-500">Querying D1 persistent modules…</p>
          </Card>
        ) : filteredModules.length === 0 ? (
          <Card className="p-16 text-center bg-white border-slate-200">
            <BookOpen className="h-10 w-10 text-slate-400 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-800">No Training Modules Found</p>
            <p className="text-xs text-slate-500 font-mono mt-1">
              {searchQuery || selectedCategory !== 'ALL' || selectedStatus !== 'ALL'
                ? 'No modules match your current filter parameters.'
                : 'Create your first persistent training module to begin building student curriculum.'}
            </p>
            <div className="mt-4">
              <Button variant="primary" size="sm" onClick={handleOpenCreateModal}>
                <PlusCircle className="h-3.5 w-3.5 mr-1.5" />
                <span>Create New Module</span>
              </Button>
            </div>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {filteredModules.map((mod) => {
              const isPublished = mod.publication_status === 'PUBLISHED';
              const isDraft = mod.publication_status === 'DRAFT';
              const isArchived = mod.publication_status === 'ARCHIVED';

              return (
                <div
                  key={mod.id}
                  className="rounded-2xl border border-slate-200 bg-white hover:border-slate-300 hover:shadow-md transition-all flex flex-col overflow-hidden"
                >
                  {/* Top Header Strip */}
                  <div className="p-4 bg-slate-50/70 border-b border-slate-100 flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-mono font-bold bg-blue-50 text-[#0453cd] px-2 py-0.5 rounded border border-blue-200">
                        {mod.category}
                      </span>
                      <span className="text-[10px] font-mono text-slate-500 bg-white px-2 py-0.5 rounded border border-slate-200">
                        {mod.level || 'Beginner'}
                      </span>
                    </div>

                    {/* Status Pill */}
                    <span
                      className={`text-[10px] font-mono font-bold px-2 py-0.5 rounded-full flex items-center gap-1 ${
                        isPublished
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : isDraft
                          ? 'bg-amber-50 text-amber-700 border border-amber-200'
                          : 'bg-slate-100 text-slate-600 border border-slate-200'
                      }`}
                    >
                      <span
                        className={`h-1.5 w-1.5 rounded-full ${
                          isPublished ? 'bg-emerald-500' : isDraft ? 'bg-amber-500' : 'bg-slate-400'
                        }`}
                      />
                      <span>{mod.publication_status}</span>
                    </span>
                  </div>

                  {/* Body Content */}
                  <div className="p-5 flex-1 flex flex-col space-y-3">
                    <div>
                      <h4 className="text-sm font-bold text-slate-900 line-clamp-1">{mod.title}</h4>
                      <p className="text-xs text-slate-500 font-sans mt-1 line-clamp-2 leading-relaxed">
                        {mod.description || 'No description provided.'}
                      </p>
                    </div>

                    {mod.learning_objectives && (
                      <div className="p-2.5 bg-slate-50 rounded-xl border border-slate-100 text-[11px] text-slate-600">
                        <span className="font-mono text-[10px] uppercase tracking-wider text-slate-400 block mb-0.5">
                          Objectives:
                        </span>
                        <p className="line-clamp-2">{mod.learning_objectives}</p>
                      </div>
                    )}

                    {/* Curriculum Counts */}
                    <div className="mt-auto pt-3 border-t border-slate-100 flex items-center justify-between text-xs font-mono text-slate-500">
                      <div className="flex items-center gap-3">
                        <span className="flex items-center gap-1">
                          <Layers className="h-3.5 w-3.5 text-slate-400" />
                          <span>{mod.chapters_count || 0} Ch.</span>
                        </span>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <FileText className="h-3.5 w-3.5 text-slate-400" />
                          <span>{mod.lessons_count || 0} Lessons</span>
                        </span>
                      </div>

                      <span className="flex items-center gap-1 text-[#0453cd]">
                        <GraduationCap className="h-3.5 w-3.5" />
                        <span>{mod.enrolled_students_count || 0} Enrolled</span>
                      </span>
                    </div>
                  </div>

                  {/* Bottom Action Footer */}
                  <div className="p-3 bg-slate-50 border-t border-slate-100 flex items-center justify-between gap-2">
                    <button
                      onClick={() => handleOpenEditModal(mod)}
                      className="px-2.5 py-1 text-slate-600 hover:text-slate-900 hover:bg-slate-200/60 rounded-lg text-xs font-mono transition-all flex items-center gap-1 cursor-pointer"
                    >
                      <Edit3 className="h-3 w-3" />
                      <span>Edit</span>
                    </button>

                    <div className="flex items-center gap-2">
                      {!isArchived && (
                        <button
                          onClick={() => handleArchiveModule(mod.id)}
                          title="Archive module"
                          className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-lg transition-colors cursor-pointer"
                        >
                          <Archive className="h-3.5 w-3.5" />
                        </button>
                      )}

                      <Link
                        href={`/teaching/modules/${mod.id}`}
                        className="px-3 py-1 bg-[#0453cd] hover:bg-blue-600 text-white rounded-lg text-xs font-mono font-semibold transition-all flex items-center gap-1 shadow-xs"
                      >
                        <span>Curriculum Editor</span>
                        <ArrowRight className="h-3 w-3" />
                      </Link>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </div>

      {/* ── Create / Edit Module Details Modal ── */}
      {modalOpen && (
        <Modal
          isOpen={modalOpen}
          onClose={() => !saving && setModalOpen(false)}
          title={editingModule ? 'Edit Module Details' : 'Create New Training Module'}
        >
          <form onSubmit={handleSaveModule} className="space-y-4">
            {formError && (
              <div className="p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{formError}</span>
              </div>
            )}

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Module Title *
              </label>
              <input
                type="text"
                required
                value={formTitle}
                onChange={(e) => setFormTitle(e.target.value)}
                placeholder="e.g. Advanced Architectural Layout & Space Planning"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Discipline Category
                </label>
                <select
                  value={formCategory}
                  onChange={(e) => setFormCategory(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                >
                  <option value="Architectural">Architectural</option>
                  <option value="Structural">Structural</option>
                  <option value="Interior">Interior</option>
                  <option value="Approval">Approval</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Difficulty Level
                </label>
                <select
                  value={formLevel}
                  onChange={(e) => setFormLevel(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                >
                  <option value="Beginner">Beginner</option>
                  <option value="Intermediate">Intermediate</option>
                  <option value="Advanced">Advanced</option>
                </select>
              </div>

              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Publication Status
                </label>
                <select
                  value={formStatus}
                  onChange={(e) => setFormStatus(e.target.value as ModulePublicationStatus)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                >
                  <option value="PUBLISHED">PUBLISHED (Visible)</option>
                  <option value="DRAFT">DRAFT (Hidden)</option>
                  <option value="ARCHIVED">ARCHIVED (Archived)</option>
                </select>
              </div>
            </div>

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Description & Overview
              </label>
              <textarea
                rows={3}
                value={formDescription}
                onChange={(e) => setFormDescription(e.target.value)}
                placeholder="Comprehensive summary of what this module covers and CAD drafting competencies taught…"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Learning Objectives
              </label>
              <textarea
                rows={2}
                value={formObjectives}
                onChange={(e) => setFormObjectives(e.target.value)}
                placeholder="• Master layer standards (A-WALL, A-DOOR)&#10;• Produce certified municipal submission drawings"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Cover / Thumbnail URL (Optional)
              </label>
              <input
                type="text"
                value={formThumbnail}
                onChange={(e) => setFormThumbnail(e.target.value)}
                placeholder="https://example.com/thumbnails/blueprint.png"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            {/* Student Assignment Section (New Module Creation Only) */}
            {!editingModule && (
              <div className="p-3.5 bg-slate-50 border border-slate-200 rounded-xl space-y-3">
                <div className="flex items-center justify-between">
                  <label className="flex items-center gap-2 cursor-pointer select-none">
                    <input
                      type="checkbox"
                      checked={assignToStudent}
                      onChange={(e) => setAssignToStudent(e.target.checked)}
                      className="h-4 w-4 rounded border-slate-300 text-[#0453cd] focus:ring-[#0453cd]"
                    />
                    <span className="text-xs font-mono font-bold text-slate-800">
                      Assign to a Student immediately (Optional)
                    </span>
                  </label>
                  {assignToStudent && (
                    <span className="text-[10px] font-mono text-[#0453cd] bg-blue-50 px-2 py-0.5 rounded border border-blue-200 font-bold">
                      Individual Plan
                    </span>
                  )}
                </div>

                {assignToStudent && (
                  <div className="space-y-3 pt-2 border-t border-slate-200">
                    <div>
                      <label className="block text-[11px] font-mono font-semibold text-slate-700 mb-1">
                        Select Student Apprentice *
                      </label>
                      {loadingStudents ? (
                        <div className="text-xs font-mono text-slate-400 py-1.5 flex items-center gap-2">
                          <span className="h-3 w-3 border-2 border-[#0453cd] border-t-transparent rounded-full animate-spin" />
                          <span>Loading student directory…</span>
                        </div>
                      ) : (
                        <select
                          value={selectedStudentId}
                          onChange={(e) => setSelectedStudentId(e.target.value)}
                          className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                        >
                          <option value="">-- Choose a Student --</option>
                          {students.map((st) => (
                            <option key={st.id} value={st.id}>
                              {st.name || 'Unnamed Student'} ({st.email}){st.college_name ? ` • ${st.college_name}` : ''}
                            </option>
                          ))}
                        </select>
                      )}
                    </div>

                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                      <div>
                        <label className="block text-[11px] font-mono font-semibold text-slate-700 mb-1">
                          Target Completion Date
                        </label>
                        <input
                          type="date"
                          value={targetCompletionDate}
                          onChange={(e) => setTargetCompletionDate(e.target.value)}
                          className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                        />
                      </div>

                      <div>
                        <label className="block text-[11px] font-mono font-semibold text-slate-700 mb-1">
                          Student Instructions / Guidance
                        </label>
                        <input
                          type="text"
                          value={assignmentInstructions}
                          onChange={(e) => setAssignmentInstructions(e.target.value)}
                          placeholder="e.g. Focus on municipal layers first"
                          className="w-full px-3 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                        />
                      </div>
                    </div>

                    {/* Clarification banner regarding Publication Status vs Assignment */}
                    <div className="text-[11px] font-mono p-2.5 rounded-lg border flex items-start gap-2 bg-white border-slate-200 text-slate-600">
                      <AlertCircle className="h-4 w-4 text-[#0453cd] shrink-0 mt-0.5" />
                      <span>
                        {formStatus === 'DRAFT'
                          ? 'Note: This module is currently configured as DRAFT. It will be assigned to the student, but remains inaccessible until published.'
                          : 'This module is PUBLISHED. The student will immediately see this training module in their Training Hub.'}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            )}

            <div className="pt-3 border-t border-slate-200 flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={saving}
                onClick={() => setModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                disabled={saving}
                type="submit"
                className="flex items-center gap-1.5"
              >
                {saving ? (
                  <>
                    <span className="h-3 w-3 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Saving…</span>
                  </>
                ) : (
                  <>
                    <Check className="h-3.5 w-3.5" />
                    <span>{editingModule ? 'Save Changes' : 'Create & Open Curriculum'}</span>
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

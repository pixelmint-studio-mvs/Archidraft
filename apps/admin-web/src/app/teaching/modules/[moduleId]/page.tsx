'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { useParams, useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import {
  TrainingModule,
  TrainingChapter,
  TrainingLesson,
  LessonResource,
  ModulePublicationStatus,
} from '@/lib/types';
import {
  BookOpen,
  ArrowLeft,
  PlusCircle,
  Layers,
  FileText,
  Video,
  Paperclip,
  CheckCircle2,
  AlertCircle,
  Edit3,
  Trash2,
  Eye,
  Check,
  Clock,
  Sparkles,
  ExternalLink,
  ChevronDown,
  ChevronRight,
  HelpCircle,
  FileDown,
  FolderPlus,
  Play,
} from 'lucide-react';

export default function ModuleCurriculumPage() {
  const params = useParams();
  const router = useRouter();
  const moduleId = params?.moduleId as string;

  const [module, setModule] = useState<TrainingModule | null>(null);
  const [chapters, setChapters] = useState<TrainingChapter[]>([]);
  const [lessons, setLessons] = useState<TrainingLesson[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Status updating state
  const [updatingStatus, setUpdatingStatus] = useState<boolean>(false);

  // Chapter Modal State
  const [chapterModalOpen, setChapterModalOpen] = useState<boolean>(false);
  const [editingChapter, setEditingChapter] = useState<TrainingChapter | null>(null);
  const [chapterTitle, setChapterTitle] = useState<string>('');
  const [chapterDescription, setChapterDescription] = useState<string>('');
  const [chapterOrder, setChapterOrder] = useState<number>(1);
  const [savingChapter, setSavingChapter] = useState<boolean>(false);

  // Lesson Modal State
  const [lessonModalOpen, setLessonModalOpen] = useState<boolean>(false);
  const [editingLesson, setEditingLesson] = useState<TrainingLesson | null>(null);
  const [lessonTitle, setLessonTitle] = useState<string>('');
  const [lessonChapterId, setLessonChapterId] = useState<string>('');
  const [lessonContent, setLessonContent] = useState<string>('');
  const [lessonVideoUrl, setLessonVideoUrl] = useState<string>('');
  const [lessonDuration, setLessonDuration] = useState<string>('20 mins');
  const [lessonIsRequired, setLessonIsRequired] = useState<boolean>(true);
  const [lessonOrder, setLessonOrder] = useState<number>(1);
  const [lessonResources, setLessonResources] = useState<LessonResource[]>([]);
  const [savingLesson, setSavingLesson] = useState<boolean>(false);
  const [lessonError, setLessonError] = useState<string | null>(null);

  // Resource input state inside Lesson modal
  const [resName, setResName] = useState<string>('');
  const [resUrl, setResUrl] = useState<string>('');
  const [resType, setResType] = useState<string>('PDF');
  const [resPreviewable, setResPreviewable] = useState<boolean>(true);

  // Preview Modal State (Student Perspective Simulation)
  const [previewModalOpen, setPreviewModalOpen] = useState<boolean>(false);
  const [previewSelectedLesson, setPreviewSelectedLesson] = useState<TrainingLesson | null>(null);

  const loadData = async (isRefresh = false) => {
    if (!moduleId) return;
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const res = await adminApi.getTrainingModule(moduleId);
      setModule(res.module);
      setChapters(res.chapters || []);
      setLessons(res.lessons || []);
    } catch (err: any) {
      setError(err.message || 'Failed to load module curriculum details.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [moduleId]);

  // Status Change Handler
  const handleUpdateStatus = async (newStatus: ModulePublicationStatus) => {
    if (!module) return;
    setUpdatingStatus(true);
    try {
      await adminApi.updateTrainingModule(module.id, { publication_status: newStatus });
      setModule((prev) => (prev ? { ...prev, publication_status: newStatus } : null));
    } catch (err: any) {
      alert(err.message || 'Failed to update publication status.');
    } finally {
      setUpdatingStatus(false);
    }
  };

  // Chapter Handlers
  const handleOpenAddChapter = () => {
    setEditingChapter(null);
    setChapterTitle('');
    setChapterDescription('');
    setChapterOrder(chapters.length + 1);
    setChapterModalOpen(true);
  };

  const handleOpenEditChapter = (ch: TrainingChapter) => {
    setEditingChapter(ch);
    setChapterTitle(ch.title);
    setChapterDescription(ch.description || '');
    setChapterOrder(ch.chapter_order);
    setChapterModalOpen(true);
  };

  const handleSaveChapter = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!chapterTitle.trim() || !module) return;
    setSavingChapter(true);

    try {
      if (editingChapter) {
        await adminApi.updateTrainingChapter(editingChapter.id, {
          title: chapterTitle.trim(),
          description: chapterDescription.trim(),
          chapter_order: Number(chapterOrder),
        });
      } else {
        await adminApi.createTrainingChapter(module.id, {
          title: chapterTitle.trim(),
          description: chapterDescription.trim(),
          chapter_order: Number(chapterOrder),
        });
      }
      setChapterModalOpen(false);
      loadData(true);
    } catch (err: any) {
      alert(err.message || 'Failed to save chapter.');
    } finally {
      setSavingChapter(false);
    }
  };

  const handleDeleteChapter = async (chapterId: string) => {
    if (!confirm('Delete this chapter? Lessons in this chapter will become unassigned.')) return;
    try {
      await adminApi.deleteTrainingChapter(chapterId);
      loadData(true);
    } catch (err: any) {
      alert(err.message || 'Failed to delete chapter.');
    }
  };

  // Lesson Handlers
  const handleOpenAddLesson = (chapterId?: string) => {
    setEditingLesson(null);
    setLessonTitle('');
    setLessonChapterId(chapterId || (chapters.length > 0 ? chapters[0].id : ''));
    setLessonContent('');
    setLessonVideoUrl('');
    setLessonDuration('20 mins');
    setLessonIsRequired(true);
    setLessonOrder(lessons.length + 1);
    setLessonResources([]);
    setLessonError(null);
    setLessonModalOpen(true);
  };

  const handleOpenEditLesson = (les: TrainingLesson) => {
    setEditingLesson(les);
    setLessonTitle(les.title);
    setLessonChapterId(les.chapter_id || '');
    setLessonContent(les.content || '');
    setLessonVideoUrl(les.video_url || '');
    setLessonDuration(les.estimated_duration || '20 mins');
    setLessonIsRequired(les.is_required === 1 || les.is_required === true);
    setLessonOrder(les.lesson_order || 1);

    // Parse resources
    let parsed: LessonResource[] = [];
    if (Array.isArray(les.resources)) {
      parsed = les.resources;
    } else if (typeof les.resources_json === 'string') {
      try {
        parsed = JSON.parse(les.resources_json);
      } catch {}
    } else if (typeof les.resources === 'string') {
      try {
        parsed = JSON.parse(les.resources);
      } catch {}
    }
    setLessonResources(parsed);
    setLessonError(null);
    setLessonModalOpen(true);
  };

  const handleAddResource = () => {
    if (!resName.trim() || !resUrl.trim()) return;
    const newRes: LessonResource = {
      id: crypto.randomUUID(),
      name: resName.trim(),
      url: resUrl.trim(),
      type: resType,
      previewable: resPreviewable,
    };
    setLessonResources((prev) => [...prev, newRes]);
    setResName('');
    setResUrl('');
  };

  const handleRemoveResource = (id: string) => {
    setLessonResources((prev) => prev.filter((r) => r.id !== id));
  };

  const handleSaveLesson = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!lessonTitle.trim() || !module) {
      setLessonError('Lesson title is required.');
      return;
    }
    setSavingLesson(true);
    setLessonError(null);

    try {
      const payload = {
        title: lessonTitle.trim(),
        chapter_id: lessonChapterId || null,
        content: lessonContent.trim(),
        video_url: lessonVideoUrl.trim() || null,
        estimated_duration: lessonDuration.trim(),
        is_required: lessonIsRequired,
        lesson_order: Number(lessonOrder),
        resources: lessonResources,
      };

      if (editingLesson) {
        await adminApi.updateTrainingLesson(editingLesson.id, payload);
      } else {
        await adminApi.createTrainingLesson(module.id, payload);
      }

      setLessonModalOpen(false);
      loadData(true);
    } catch (err: any) {
      setLessonError(err.message || 'Failed to save lesson.');
    } finally {
      setSavingLesson(false);
    }
  };

  const handleDeleteLesson = async (lessonId: string) => {
    if (!confirm('Permanently remove this lesson?')) return;
    try {
      await adminApi.deleteTrainingLesson(lessonId);
      loadData(true);
    } catch (err: any) {
      alert(err.message || 'Failed to delete lesson.');
    }
  };

  // Organize Lessons by Chapter
  const chapterLessonMap = useMemo(() => {
    const map = new Map<string, TrainingLesson[]>();
    const standalone: TrainingLesson[] = [];

    for (const les of lessons) {
      if (les.chapter_id) {
        const arr = map.get(les.chapter_id) || [];
        arr.push(les);
        map.set(les.chapter_id, arr);
      } else {
        standalone.push(les);
      }
    }

    return { chapterMap: map, standalone };
  }, [lessons]);

  const requiredCount = lessons.filter((l) => l.is_required === 1 || l.is_required === true).length;
  const optionalCount = lessons.length - requiredCount;

  return (
    <AdminShell
      title={module?.title || 'Module Curriculum Editor'}
      subtitle="Organize chapters, create lesson content, attach reference drawings & documents, and publish learning materials."
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      <div className="space-y-6">
        {/* ── Top Navigation & Quick Actions ── */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-200 pb-3">
          <Link
            href="/teaching/modules"
            className="px-3 py-1.5 border border-slate-200 rounded-lg text-xs font-mono text-slate-700 hover:bg-slate-50 transition-all flex items-center gap-1.5 w-fit"
          >
            <ArrowLeft className="h-3.5 w-3.5" />
            <span>All Modules</span>
          </Link>
          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => {
                if (lessons.length > 0) {
                  setPreviewSelectedLesson(lessons[0]);
                }
                setPreviewModalOpen(true);
              }}
              className="flex items-center gap-1.5"
            >
              <Eye className="h-3.5 w-3.5 text-blue-600" />
              <span>Student Preview</span>
            </Button>
            <Button
              variant="primary"
              size="sm"
              onClick={() => handleOpenAddLesson()}
              className="flex items-center gap-1.5 shadow-sm"
            >
              <PlusCircle className="h-4 w-4" />
              <span>Add Lesson</span>
            </Button>
          </div>
        </div>
        {/* ── Top Info & Publication Control Bar ── */}
        {module && (
          <div className="p-4 bg-white rounded-2xl border border-slate-200 shadow-xs flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2 flex-wrap">
                <span className="text-[10px] font-mono font-bold bg-blue-50 text-[#0453cd] px-2 py-0.5 rounded border border-blue-200">
                  {module.category}
                </span>
                <span className="text-[10px] font-mono text-slate-500 bg-slate-100 px-2 py-0.5 rounded border border-slate-200">
                  {module.level || 'Beginner'}
                </span>
                <span className="text-[10px] font-mono text-slate-400">ID: {module.id}</span>
              </div>
              <h2 className="text-base font-bold text-slate-900">{module.title}</h2>
              {module.description && (
                <p className="text-xs text-slate-600 max-w-3xl line-clamp-2">{module.description}</p>
              )}
            </div>

            {/* Publication Status Selector */}
            <div className="flex items-center gap-3 shrink-0">
              <div className="text-right">
                <span className="text-[10px] font-mono uppercase text-slate-400 block font-semibold">
                  Publication Status
                </span>
                <select
                  disabled={updatingStatus}
                  value={module.publication_status}
                  onChange={(e) => handleUpdateStatus(e.target.value as ModulePublicationStatus)}
                  className={`mt-0.5 px-3 py-1 rounded-lg text-xs font-mono font-bold border focus:outline-none transition-all ${
                    module.publication_status === 'PUBLISHED'
                      ? 'bg-emerald-50 text-emerald-800 border-emerald-300'
                      : module.publication_status === 'DRAFT'
                      ? 'bg-amber-50 text-amber-800 border-amber-300'
                      : 'bg-slate-100 text-slate-700 border-slate-300'
                  }`}
                >
                  <option value="PUBLISHED">PUBLISHED (Live)</option>
                  <option value="DRAFT">DRAFT (Unpublished)</option>
                  <option value="ARCHIVED">ARCHIVED (Archived)</option>
                </select>
              </div>

              <Button
                variant="outline"
                size="sm"
                onClick={handleOpenAddChapter}
                className="flex items-center gap-1.5 text-xs font-mono"
              >
                <FolderPlus className="h-3.5 w-3.5 text-[#0453cd]" />
                <span>New Chapter</span>
              </Button>
            </div>
          </div>
        )}

        {/* ── Curriculum Metrics Strip ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-3.5 rounded-xl border border-slate-200 bg-white">
            <p className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Total Chapters</p>
            <p className="text-xl font-bold font-mono text-slate-900 mt-0.5">{chapters.length}</p>
          </div>
          <div className="p-3.5 rounded-xl border border-slate-200 bg-white">
            <p className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Total Lessons</p>
            <p className="text-xl font-bold font-mono text-slate-900 mt-0.5">{lessons.length}</p>
          </div>
          <div className="p-3.5 rounded-xl border border-slate-200 bg-white">
            <p className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Required Lessons</p>
            <p className="text-xl font-bold font-mono text-emerald-700 mt-0.5">{requiredCount}</p>
            <p className="text-[10px] font-mono text-slate-400">Used for completion %</p>
          </div>
          <div className="p-3.5 rounded-xl border border-slate-200 bg-white">
            <p className="text-[10px] font-mono uppercase text-slate-400 font-semibold">Optional Lessons</p>
            <p className="text-xl font-bold font-mono text-slate-600 mt-0.5">{optionalCount}</p>
            <p className="text-[10px] font-mono text-slate-400">Enrichment units</p>
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

        {/* ── Main Curriculum Tree ── */}
        {loading ? (
          <Card className="p-16 text-center bg-white border-slate-200">
            <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent mx-auto mb-3" />
            <p className="text-xs font-mono text-slate-500">Loading curriculum hierarchy…</p>
          </Card>
        ) : (
          <div className="space-y-6">
            {/* Chapters & Attached Lessons */}
            {chapters.map((ch, idx) => {
              const chLessons = chapterLessonMap.chapterMap.get(ch.id) || [];

              return (
                <div
                  key={ch.id}
                  className="rounded-2xl border border-slate-200 bg-white overflow-hidden shadow-xs"
                >
                  {/* Chapter Header */}
                  <div className="p-4 bg-slate-50/90 border-b border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div className="flex items-start gap-3">
                      <div className="h-8 w-8 rounded-lg bg-[#0d1c32] text-white flex items-center justify-center font-mono text-xs font-bold shrink-0">
                        {String(idx + 1).padStart(2, '0')}
                      </div>
                      <div>
                        <div className="flex items-center gap-2">
                          <h3 className="text-sm font-bold text-slate-900">{ch.title}</h3>
                          <span className="text-[10px] font-mono bg-white text-slate-600 px-2 py-0.5 rounded border border-slate-200">
                            {chLessons.length} lessons
                          </span>
                        </div>
                        {ch.description && (
                          <p className="text-xs text-slate-500 mt-0.5">{ch.description}</p>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-2 self-end sm:self-center">
                      <Button
                        variant="outline"
                        size="sm"
                        onClick={() => handleOpenAddLesson(ch.id)}
                        className="text-xs font-mono h-7"
                      >
                        <PlusCircle className="h-3 w-3 mr-1 text-[#0453cd]" />
                        <span>Add Lesson</span>
                      </Button>
                      <button
                        onClick={() => handleOpenEditChapter(ch)}
                        title="Edit Chapter"
                        className="p-1.5 text-slate-400 hover:text-slate-700 hover:bg-slate-200 rounded-md transition-colors cursor-pointer"
                      >
                        <Edit3 className="h-3.5 w-3.5" />
                      </button>
                      <button
                        onClick={() => handleDeleteChapter(ch.id)}
                        title="Delete Chapter"
                        className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-md transition-colors cursor-pointer"
                      >
                        <Trash2 className="h-3.5 w-3.5" />
                      </button>
                    </div>
                  </div>

                  {/* Lessons List in Chapter */}
                  {chLessons.length === 0 ? (
                    <div className="p-8 text-center text-xs text-slate-400 font-mono">
                      No lessons added to this chapter yet. Click "Add Lesson" to create learning content.
                    </div>
                  ) : (
                    <div className="divide-y divide-slate-100">
                      {chLessons.map((les, lIdx) => {
                        const isReq = les.is_required === 1 || les.is_required === true;
                        let resCount = 0;
                        try {
                          if (Array.isArray(les.resources)) resCount = les.resources.length;
                          else if (les.resources_json) resCount = JSON.parse(les.resources_json).length;
                        } catch {}

                        return (
                          <div
                            key={les.id}
                            className="p-4 hover:bg-slate-50/70 transition-colors flex items-center justify-between gap-4"
                          >
                            <div className="flex items-center gap-3 min-w-0 flex-1">
                              <span className="text-xs font-mono text-slate-400 w-6 text-right shrink-0">
                                {idx + 1}.{lIdx + 1}
                              </span>

                              <div className="space-y-1 min-w-0 flex-1">
                                <div className="flex items-center gap-2 flex-wrap">
                                  <h4 className="text-xs font-bold text-slate-900 truncate">
                                    {les.title}
                                  </h4>
                                  <span
                                    className={`text-[9px] font-mono font-bold px-1.5 py-0.2 rounded uppercase ${
                                      isReq
                                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                        : 'bg-slate-100 text-slate-600 border border-slate-200'
                                    }`}
                                  >
                                    {isReq ? 'Required' : 'Optional'}
                                  </span>
                                  {les.video_url && (
                                    <span className="text-[10px] text-purple-700 bg-purple-50 border border-purple-200 px-1.5 py-0.2 rounded flex items-center gap-1 font-mono">
                                      <Video className="h-2.5 w-2.5" />
                                      <span>Video</span>
                                    </span>
                                  )}
                                  {resCount > 0 && (
                                    <span className="text-[10px] text-blue-700 bg-blue-50 border border-blue-200 px-1.5 py-0.2 rounded flex items-center gap-1 font-mono">
                                      <Paperclip className="h-2.5 w-2.5" />
                                      <span>{resCount} files</span>
                                    </span>
                                  )}
                                </div>
                                <div className="flex items-center gap-3 text-[11px] font-mono text-slate-400">
                                  <span>Duration: {les.estimated_duration || '20 mins'}</span>
                                  <span>•</span>
                                  <span className="truncate max-w-md">
                                    {les.content?.substring(0, 80) || 'No text content'}…
                                  </span>
                                </div>
                              </div>
                            </div>

                            <div className="flex items-center gap-1 shrink-0">
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => handleOpenEditLesson(les)}
                                className="text-xs font-mono h-7 px-2.5"
                              >
                                <Edit3 className="h-3 w-3 mr-1" />
                                <span>Edit</span>
                              </Button>
                              <button
                                onClick={() => handleDeleteLesson(les.id)}
                                title="Delete Lesson"
                                className="p-1.5 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded-md transition-colors cursor-pointer"
                              >
                                <Trash2 className="h-3.5 w-3.5" />
                              </button>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              );
            })}

            {/* Standalone Lessons (If any) */}
            {chapterLessonMap.standalone.length > 0 && (
              <div className="rounded-2xl border border-slate-200 bg-white overflow-hidden shadow-xs">
                <div className="p-4 bg-slate-50 border-b border-slate-200 flex items-center justify-between">
                  <h3 className="text-sm font-bold text-slate-800 flex items-center gap-2">
                    <FileText className="h-4 w-4 text-slate-500" />
                    <span>Standalone Lessons ({chapterLessonMap.standalone.length})</span>
                  </h3>
                  <Button
                    variant="outline"
                    size="sm"
                    onClick={() => handleOpenAddLesson()}
                    className="text-xs font-mono h-7"
                  >
                    <PlusCircle className="h-3 w-3 mr-1" />
                    <span>Add Lesson</span>
                  </Button>
                </div>

                <div className="divide-y divide-slate-100">
                  {chapterLessonMap.standalone.map((les, idx) => (
                    <div
                      key={les.id}
                      className="p-4 hover:bg-slate-50/70 transition-colors flex items-center justify-between gap-4"
                    >
                      <div className="flex items-center gap-3 min-w-0 flex-1">
                        <span className="text-xs font-mono text-slate-400 w-6 text-right shrink-0">
                          {idx + 1}
                        </span>
                        <div className="space-y-1 min-w-0 flex-1">
                          <h4 className="text-xs font-bold text-slate-900 truncate">{les.title}</h4>
                          <p className="text-[11px] font-mono text-slate-400">
                            {les.estimated_duration || '20 mins'}
                          </p>
                        </div>
                      </div>
                      <div className="flex items-center gap-1 shrink-0">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => handleOpenEditLesson(les)}
                          className="text-xs font-mono h-7 px-2.5"
                        >
                          <Edit3 className="h-3 w-3 mr-1" />
                          <span>Edit</span>
                        </Button>
                        <button
                          onClick={() => handleDeleteLesson(les.id)}
                          className="p-1.5 text-slate-400 hover:text-rose-600 rounded-md cursor-pointer"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Empty State */}
            {chapters.length === 0 && lessons.length === 0 && (
              <Card className="p-16 text-center bg-white border-slate-200">
                <Layers className="h-10 w-10 text-slate-400 mx-auto mb-3" />
                <p className="text-sm font-semibold text-slate-800">Curriculum is Empty</p>
                <p className="text-xs text-slate-500 font-mono mt-1">
                  Start by adding your first chapter to structure lessons, or add lessons directly.
                </p>
                <div className="mt-4 flex items-center justify-center gap-3">
                  <Button variant="primary" size="sm" onClick={handleOpenAddChapter}>
                    <FolderPlus className="h-3.5 w-3.5 mr-1.5" />
                    <span>Create Chapter</span>
                  </Button>
                  <Button variant="outline" size="sm" onClick={() => handleOpenAddLesson()}>
                    <PlusCircle className="h-3.5 w-3.5 mr-1.5" />
                    <span>Create Lesson</span>
                  </Button>
                </div>
              </Card>
            )}
          </div>
        )}
      </div>

      {/* ── Chapter Modal ── */}
      {chapterModalOpen && (
        <Modal
          isOpen={chapterModalOpen}
          onClose={() => !savingChapter && setChapterModalOpen(false)}
          title={editingChapter ? 'Edit Chapter' : 'Add New Chapter'}
        >
          <form onSubmit={handleSaveChapter} className="space-y-4">
            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Chapter Title *
              </label>
              <input
                type="text"
                required
                value={chapterTitle}
                onChange={(e) => setChapterTitle(e.target.value)}
                placeholder="e.g. Chapter 01: Municipal Regulations & Permitting Foundations"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Chapter Summary & Scope
              </label>
              <textarea
                rows={2}
                value={chapterDescription}
                onChange={(e) => setChapterDescription(e.target.value)}
                placeholder="What this chapter covers and drafting standards demonstrated…"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Display Order Sequence
              </label>
              <input
                type="number"
                min="1"
                value={chapterOrder}
                onChange={(e) => setChapterOrder(Number(e.target.value))}
                className="w-24 px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div className="pt-3 border-t border-slate-200 flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={savingChapter}
                onClick={() => setChapterModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                disabled={savingChapter}
                type="submit"
                className="flex items-center gap-1.5"
              >
                {savingChapter ? 'Saving…' : 'Save Chapter'}
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {/* ── Lesson Modal ── */}
      {lessonModalOpen && (
        <Modal
          isOpen={lessonModalOpen}
          onClose={() => !savingLesson && setLessonModalOpen(false)}
          title={editingLesson ? 'Edit Lesson' : 'Add New Lesson'}
          maxWidth="3xl"
        >
          <form onSubmit={handleSaveLesson} className="space-y-4">
            {lessonError && (
              <div className="p-3 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{lessonError}</span>
              </div>
            )}

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Lesson Title *
                </label>
                <input
                  type="text"
                  required
                  value={lessonTitle}
                  onChange={(e) => setLessonTitle(e.target.value)}
                  placeholder="e.g. Setback Rules & FAR Calculation"
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-sans text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                />
              </div>

              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Belongs to Chapter
                </label>
                <select
                  value={lessonChapterId}
                  onChange={(e) => setLessonChapterId(e.target.value)}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                >
                  <option value="">-- Standalone (No Chapter) --</option>
                  {chapters.map((ch) => (
                    <option key={ch.id} value={ch.id}>
                      {ch.title}
                    </option>
                  ))}
                </select>
              </div>
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Estimated Duration
                </label>
                <input
                  type="text"
                  value={lessonDuration}
                  onChange={(e) => setLessonDuration(e.target.value)}
                  placeholder="e.g. 25 mins"
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                />
              </div>

              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Sequence Order
                </label>
                <input
                  type="number"
                  min="1"
                  value={lessonOrder}
                  onChange={(e) => setLessonOrder(Number(e.target.value))}
                  className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                />
              </div>

              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                  Completion Requirement
                </label>
                <label className="flex items-center gap-2 mt-2 cursor-pointer text-xs font-mono text-slate-700">
                  <input
                    type="checkbox"
                    checked={lessonIsRequired}
                    onChange={(e) => setLessonIsRequired(e.target.checked)}
                    className="rounded text-[#0453cd] focus:ring-[#0453cd]"
                  />
                  <span>Mandatory for 100%</span>
                </label>
              </div>
            </div>

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Video Lesson URL (Optional MP4, YouTube, Vimeo)
              </label>
              <input
                type="text"
                value={lessonVideoUrl}
                onChange={(e) => setLessonVideoUrl(e.target.value)}
                placeholder="https://youtu.be/xyz or https://vimeo.com/xyz"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 mb-1">
                Written Learning Material & Instructions
              </label>
              <textarea
                rows={6}
                value={lessonContent}
                onChange={(e) => setLessonContent(e.target.value)}
                placeholder="Detailed architectural instruction, technical drafting standards, formulas, and submission criteria…"
                className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              />
            </div>

            {/* Lesson Resources Management */}
            <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-xs font-mono font-bold text-slate-800 flex items-center gap-1.5">
                  <Paperclip className="h-3.5 w-3.5 text-[#0453cd]" />
                  <span>Attach Lesson Resources ({lessonResources.length})</span>
                </span>
                <span className="text-[10px] font-mono text-slate-400">PDFs, DWG blueprints, images</span>
              </div>

              {/* Add Resource Row */}
              <div className="grid grid-cols-1 sm:grid-cols-12 gap-2 text-xs font-mono">
                <div className="sm:col-span-4">
                  <input
                    type="text"
                    value={resName}
                    onChange={(e) => setResName(e.target.value)}
                    placeholder="Document Title (e.g. Sample DWG)"
                    className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                  />
                </div>
                <div className="sm:col-span-5">
                  <input
                    type="text"
                    value={resUrl}
                    onChange={(e) => setResUrl(e.target.value)}
                    placeholder="Resource URL (https://…)"
                    className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                  />
                </div>
                <div className="sm:col-span-2">
                  <select
                    value={resType}
                    onChange={(e) => setResType(e.target.value)}
                    className="w-full px-2 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-700"
                  >
                    <option value="PDF">PDF</option>
                    <option value="DRAWING">CAD DWG</option>
                    <option value="IMAGE">Image</option>
                    <option value="DOC">Document</option>
                  </select>
                </div>
                <div className="sm:col-span-1">
                  <Button
                    type="button"
                    variant="outline"
                    size="sm"
                    onClick={handleAddResource}
                    disabled={!resName.trim() || !resUrl.trim()}
                    className="w-full h-8"
                  >
                    Add
                  </Button>
                </div>
              </div>

              {/* Resources List */}
              {lessonResources.length > 0 && (
                <div className="space-y-1.5 pt-2">
                  {lessonResources.map((res) => (
                    <div
                      key={res.id}
                      className="flex items-center justify-between p-2 bg-white rounded-lg border border-slate-200 text-xs font-mono"
                    >
                      <div className="flex items-center gap-2 min-w-0">
                        <span className="text-[10px] font-bold bg-blue-50 text-[#0453cd] px-1.5 py-0.2 rounded border border-blue-200">
                          {res.type || 'PDF'}
                        </span>
                        <span className="font-semibold text-slate-900 truncate">{res.name}</span>
                        <span className="text-slate-400 text-[10px] truncate max-w-xs">{res.url}</span>
                      </div>
                      <button
                        type="button"
                        onClick={() => handleRemoveResource(res.id)}
                        className="text-slate-400 hover:text-rose-600 p-1"
                      >
                        <Trash2 className="h-3 w-3" />
                      </button>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="pt-3 border-t border-slate-200 flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={savingLesson}
                onClick={() => setLessonModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                disabled={savingLesson}
                type="submit"
                className="flex items-center gap-1.5"
              >
                {savingLesson ? 'Saving…' : 'Save Lesson'}
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {/* ── Student Perspective Simulation Preview Modal ── */}
      {previewModalOpen && module && (
        <Modal
          isOpen={previewModalOpen}
          onClose={() => setPreviewModalOpen(false)}
          title={`Student Preview: ${module.title}`}
          maxWidth="4xl"
        >
          <div className="grid grid-cols-1 md:grid-cols-12 gap-6 min-h-[460px]">
            {/* Sidebar list of lessons */}
            <div className="md:col-span-4 border-r border-slate-200 pr-4 space-y-3">
              <div className="p-3 bg-slate-50 rounded-xl border border-slate-200">
                <span className="text-[10px] font-mono uppercase tracking-wider text-slate-400 block font-semibold">
                  Module Syllabus
                </span>
                <p className="text-xs font-bold text-slate-900">{module.title}</p>
                <div className="flex items-center gap-2 mt-2 text-[10px] font-mono text-slate-500">
                  <span>{lessons.length} lessons</span>
                  <span>•</span>
                  <span>{requiredCount} required</span>
                </div>
              </div>

              <div className="space-y-1.5 max-h-[380px] overflow-y-auto">
                {lessons.map((les, idx) => {
                  const isSelected = previewSelectedLesson?.id === les.id;
                  return (
                    <button
                      key={les.id}
                      onClick={() => setPreviewSelectedLesson(les)}
                      className={`w-full text-left p-2.5 rounded-xl text-xs font-mono transition-all flex items-center justify-between cursor-pointer ${
                        isSelected
                          ? 'bg-[#0453cd] text-white shadow-xs font-semibold'
                          : 'bg-slate-50 text-slate-700 hover:bg-slate-100'
                      }`}
                    >
                      <span className="truncate flex-1">
                        {idx + 1}. {les.title}
                      </span>
                      {les.is_required ? (
                        <span
                          className={`text-[9px] px-1.5 py-0.2 rounded ml-1 shrink-0 ${
                            isSelected ? 'bg-white/20 text-white' : 'bg-emerald-100 text-emerald-800'
                          }`}
                        >
                          REQ
                        </span>
                      ) : null}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Lesson Content View */}
            <div className="md:col-span-8 space-y-4">
              {previewSelectedLesson ? (
                <div className="space-y-4">
                  <div className="border-b border-slate-100 pb-3">
                    <div className="flex items-center gap-2">
                      <span className="text-[10px] font-mono text-slate-400">
                        Lesson Duration: {previewSelectedLesson.estimated_duration || '20 mins'}
                      </span>
                      <span
                        className={`text-[9px] font-mono font-bold px-1.5 py-0.2 rounded ${
                          previewSelectedLesson.is_required
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : 'bg-slate-100 text-slate-600'
                        }`}
                      >
                        {previewSelectedLesson.is_required ? 'Required for Completion' : 'Optional'}
                      </span>
                    </div>
                    <h3 className="text-base font-bold text-slate-900 mt-1">
                      {previewSelectedLesson.title}
                    </h3>
                  </div>

                  {previewSelectedLesson.video_url && (
                    <div className="p-4 bg-purple-50 rounded-xl border border-purple-200 text-xs font-mono text-purple-900 flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <Play className="h-4 w-4 text-purple-600" />
                        <span>Interactive Video Lesson Attached</span>
                      </div>
                      <a
                        href={previewSelectedLesson.video_url}
                        target="_blank"
                        rel="noreferrer"
                        className="text-purple-700 font-bold hover:underline flex items-center gap-1"
                      >
                        <span>Open Video</span>
                        <ExternalLink className="h-3 w-3" />
                      </a>
                    </div>
                  )}

                  <div className="p-4 bg-slate-50 rounded-xl border border-slate-200 text-xs font-sans text-slate-800 leading-relaxed whitespace-pre-wrap min-h-[160px]">
                    {previewSelectedLesson.content || 'No text content authoring has been provided.'}
                  </div>

                  {/* Attached resources preview */}
                  {(() => {
                    let resList: LessonResource[] = [];
                    try {
                      if (Array.isArray(previewSelectedLesson.resources)) {
                        resList = previewSelectedLesson.resources;
                      } else if (previewSelectedLesson.resources_json) {
                        resList = JSON.parse(previewSelectedLesson.resources_json);
                      }
                    } catch {}

                    if (resList.length === 0) return null;

                    return (
                      <div className="space-y-2 pt-2 border-t border-slate-100">
                        <span className="text-[10px] font-mono uppercase tracking-wider text-slate-400 font-bold block">
                          Downloadable Drawing & Reference Assets
                        </span>
                        <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                          {resList.map((r) => (
                            <a
                              key={r.id}
                              href={r.url}
                              target="_blank"
                              rel="noreferrer"
                              className="p-2.5 rounded-lg border border-slate-200 bg-white hover:border-slate-300 transition-all flex items-center justify-between text-xs font-mono text-slate-700 group"
                            >
                              <div className="flex items-center gap-2 truncate">
                                <FileDown className="h-4 w-4 text-[#0453cd] shrink-0" />
                                <span className="truncate group-hover:text-[#0453cd] font-semibold">
                                  {r.name}
                                </span>
                              </div>
                              <span className="text-[10px] text-slate-400 shrink-0 uppercase">
                                {r.previewable ? 'Preview' : 'Download'}
                              </span>
                            </a>
                          ))}
                        </div>
                      </div>
                    );
                  })()}
                </div>
              ) : (
                <div className="p-16 text-center text-xs font-mono text-slate-400">
                  Select a lesson to preview its student presentation.
                </div>
              )}
            </div>
          </div>
        </Modal>
      )}
    </AdminShell>
  );
}

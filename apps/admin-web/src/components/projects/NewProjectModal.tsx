'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { useRouter } from 'next/navigation';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { User } from '@/lib/types';
import {
  Building2,
  MapPin,
  UploadCloud,
  CheckCircle2,
  AlertCircle,
  X,
  ArrowRight,
  ArrowLeft,
  Sparkles,
  GraduationCap,
} from 'lucide-react';

interface NewProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (projectId?: string) => void;
  initialAssigneeType?: 'STUDENT';
  initialStudentId?: string;
}

// ── Discipline Categories & Scale Options ─────────────────────────────────────

interface DisciplineOption {
  id: string;
  label: string;
  rateKey: string;
  desc: string;
}

const DISCIPLINES: DisciplineOption[] = [
  { id: 'Architectural Layout', label: 'Architectural Layout', rateKey: 'FLOOR_PLAN', desc: 'Standard architectural layout & space planning' },
  { id: 'Structural Framing', label: 'Structural Framing', rateKey: 'STRUCTURAL', desc: 'Load-bearing columns, beams & reinforcement' },
  { id: 'MEP & HVAC Plan', label: 'MEP & HVAC Plan', rateKey: 'ELECTRICAL', desc: 'Mechanical, electrical, plumbing & ductwork' },
  { id: 'Interior Blueprint', label: 'Interior Blueprint', rateKey: 'SECTION', desc: 'Detailed architectural sections, millwork & fit-out' },
  { id: 'Municipal / Permit', label: 'Municipal / Permit', rateKey: 'SITE_PLAN', desc: 'Permit packages, boundary surveys & zoning' },
];

const DRAWING_SCALES = [
  { value: '1:50', label: '1:50 (Detailed / Fit-out)' },
  { value: '1:100', label: '1:100 (Standard Commercial)' },
  { value: '1:200', label: '1:200 (Site & Campus Plan)' },
];

export function NewProjectModal({
  isOpen,
  onClose,
  onSuccess,
  initialAssigneeType,
  initialStudentId,
}: NewProjectModalProps) {
  const router = useRouter();

  // Wizard Step: 1 = Metadata/Identity, 2 = Specs & Files, 3 = Review & Dispatch
  const [step, setStep] = useState<1 | 2 | 3>(1);

  // Assignment Target: Student Apprentice (Academic Training Curriculum)
  const assigneeType = 'STUDENT' as const;

  // Students list
  const [students, setStudents] = useState<User[]>([]);
  const [fetchingStudents, setFetchingStudents] = useState<boolean>(false);

  // Step 1: Identity Form State
  const [selectedStudentId, setSelectedStudentId] = useState<string>(initialStudentId || '');
  const [projectName, setProjectName] = useState<string>('');
  const [projectAddress, setProjectAddress] = useState<string>('');
  const [instructions, setInstructions] = useState<string>('');
  const [clientRefCode, setClientRefCode] = useState<string>('');

  // Step 2: Scope & Files Form State
  const [selectedDiscipline, setSelectedDiscipline] = useState<string>(DISCIPLINES[0].id);
  const [drawingScale, setDrawingScale] = useState<string>('1:100');
  const [areaFootprint, setAreaFootprint] = useState<string>('1500');
  const [selectedFiles, setSelectedFiles] = useState<File[]>([]);

  // Step 3: Submission & Progress State
  const [submissionStage, setSubmissionStage] = useState<'idle' | 'creating_project' | 'uploading_files' | 'completed' | 'error'>('idle');
  const [createdProjectId, setCreatedProjectId] = useState<string | null>(null);
  const [uploadedFileCount, setUploadedFileCount] = useState<number>(0);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [projectActionId, setProjectActionId] = useState<string>('');

  // Reset and initialize when modal opens
  useEffect(() => {
    if (isOpen) {
      setStep(1);
      setSubmissionStage('idle');
      setCreatedProjectId(null);
      setUploadedFileCount(0);
      setErrorMessage(null);
      setProjectActionId(crypto.randomUUID());
      setProjectName('');
      setProjectAddress('');
      setAreaFootprint('1500');
      setSelectedFiles([]);
      setSelectedDiscipline(DISCIPLINES[0].id);
      setInstructions('');

      // Generate randomized student curriculum reference code
      const randNum = Math.floor(10000 + Math.random() * 90000);
      setClientRefCode(`STU-PRAC-${randNum}`);

      // Load registered students (role: STUDENT)
      setFetchingStudents(true);
      adminApi
        .getUsers('STUDENT')
        .then((list) => {
          const studentList = (list || []).filter((u) => u.role === 'STUDENT');
          setStudents(studentList);
          if (initialStudentId && studentList.some((s) => s.id === initialStudentId)) {
            setSelectedStudentId(initialStudentId);
          } else if (studentList.length > 0) {
            setSelectedStudentId(studentList[0].id);
          }
        })
        .catch((err) => {
          console.error('Failed to load students:', err);
        })
        .finally(() => setFetchingStudents(false));
    }
  }, [isOpen, initialAssigneeType, initialStudentId]);

  const selectedStudent = useMemo(() => {
    return students.find((s) => s.id === selectedStudentId);
  }, [students, selectedStudentId]);

  // File selection handler
  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    if (e.target.files) {
      const filesArray = Array.from(e.target.files);
      const allowed = ['pdf', 'dwg', 'dxf', 'png', 'jpg', 'jpeg', 'zip'];
      const validFiles = filesArray.filter((file) => {
        const ext = file.name.split('.').pop()?.toLowerCase();
        return ext && allowed.includes(ext) && file.size <= 50 * 1024 * 1024;
      });
      setSelectedFiles((prev) => [...prev, ...validFiles]);
    }
  };

  const removeFile = (idx: number) => {
    setSelectedFiles((prev) => prev.filter((_, i) => i !== idx));
  };

  // Step 1 validation
  const validateStep1 = () => {
    if (!projectName.trim()) {
      setErrorMessage('Assignment title is required.');
      return false;
    }
    if (!selectedStudentId) {
      setErrorMessage('Please select an enrolled Student Apprentice for this assignment.');
      return false;
    }
    setErrorMessage(null);
    return true;
  };

  // Step 2 validation
  const validateStep2 = () => {
    const area = parseFloat(areaFootprint);
    if (isNaN(area) || area <= 0) {
      setErrorMessage('Please enter a valid area footprint in square feet.');
      return false;
    }
    setErrorMessage(null);
    return true;
  };

  // Dispatch Project Execution
  const handleDispatchProject = async () => {
    setErrorMessage(null);
    let currentProjectId = createdProjectId;

    try {
      // 1. Create Student Practical Assignment Brief if not already created (idempotent retry safe)
      if (!currentProjectId) {
        setSubmissionStage('creating_project');
        const disciplineObj = DISCIPLINES.find((d) => d.id === selectedDiscipline) || DISCIPLINES[0];

        const res = await adminApi.createProject({
          studentId: selectedStudentId,
          isTrainingProject: true,
          projectName: projectName.trim(),
          projectAddress: projectAddress.trim() || 'Academic Studio Campus',
          drawingName: `${disciplineObj.label} Practical Assignment (${drawingScale})`,
          drawingType: disciplineObj.rateKey,
          projectArea: Number(areaFootprint) || 1500,
          instructions: instructions.trim() || undefined,
          actionId: projectActionId,
        });

        currentProjectId = res.id;
        setCreatedProjectId(currentProjectId);
      }

      // 2. Stream reference files to R2
      if (selectedFiles.length > 0 && currentProjectId) {
        setSubmissionStage('uploading_files');
        let uploaded = uploadedFileCount;
        const uploadCategory = 'reference';
        const remainingFiles = selectedFiles.slice(uploaded);
        for (const file of remainingFiles) {
          try {
            await adminApi.uploadProjectFile(currentProjectId, file, uploadCategory);
            uploaded++;
            setUploadedFileCount(uploaded);
          } catch (fileErr: any) {
            console.error(`Failed to upload ${file.name}:`, fileErr);
            throw new Error(`Failed to upload reference file "${file.name}" (${fileErr.message || 'Upload failed'}). Click retry to resume upload.`);
          }
        }
      }

      setSubmissionStage('completed');
    } catch (err: any) {
      console.error('Project initiation error:', err);
      setSubmissionStage('error');
      setErrorMessage(err.message || 'Failed to dispatch practical assignment. Please check inputs and retry.');
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={() => {
        if (submissionStage === 'completed') {
          onSuccess(createdProjectId || undefined);
        }
        onClose();
      }}
      title=""
      description=""
      maxWidth="xl"
    >
      <div className="bg-[#fbf9fb] -m-6 rounded-2xl overflow-hidden font-sans border border-slate-200/80">
        {/* ── Stitch Precision Header ── */}
        <div className="px-6 py-4 bg-[#0a192f] text-white border-b border-slate-800">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
              <span className="text-[10px] font-mono tracking-widest text-slate-400 uppercase">
                STUDIO ACADEMY // PRACTICAL ASSIGNMENT
              </span>
            </div>
            <div className="bg-white/10 border border-white/20 text-slate-200 font-mono text-[9px] font-semibold tracking-wider px-2 py-0.5 rounded">
              REV 1.0 · D1 SYNC
            </div>
          </div>
          <h2 className="text-lg font-bold tracking-tight text-white mt-1">
            Assign Practical Project to Student
          </h2>
          <p className="text-xs text-slate-400 mt-0.5">
            Create a training project with instructions & reference files, and assign directly to an apprentice.
          </p>

          {/* ── 3-Step Breadcrumb Progress Tracker ── */}
          <div className="mt-4 pt-3 border-t border-slate-800/80 flex items-center justify-between relative">
            <div className="absolute left-6 right-6 top-6 h-[1.5px] bg-slate-800 -z-0" />

            {/* Step 1 */}
            <div
              onClick={() => submissionStage === 'idle' && setStep(1)}
              className={`flex items-center gap-2 relative z-10 cursor-pointer ${step === 1 ? 'opacity-100' : 'opacity-70'}`}
            >
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-mono font-bold transition-all ${
                  step === 1
                    ? 'bg-[#0453cd] text-white ring-4 ring-blue-500/20'
                    : step > 1
                    ? 'bg-emerald-500 text-white'
                    : 'bg-slate-800 text-slate-400'
                }`}
              >
                {step > 1 ? '✓' : '01'}
              </div>
              <span className="text-xs font-mono font-semibold text-slate-200">Metadata</span>
            </div>

            {/* Step 2 */}
            <div
              onClick={() => submissionStage === 'idle' && validateStep1() && setStep(2)}
              className={`flex items-center gap-2 relative z-10 cursor-pointer ${step === 2 ? 'opacity-100' : 'opacity-70'}`}
            >
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-mono font-bold transition-all ${
                  step === 2
                    ? 'bg-[#0453cd] text-white ring-4 ring-blue-500/20'
                    : step > 2
                    ? 'bg-emerald-500 text-white'
                    : 'bg-slate-800 text-slate-400'
                }`}
              >
                {step > 2 ? '✓' : '02'}
              </div>
              <span className="text-xs font-mono font-semibold text-slate-200">Scope & CAD</span>
            </div>

            {/* Step 3 */}
            <div
              onClick={() => submissionStage === 'idle' && validateStep1() && validateStep2() && setStep(3)}
              className={`flex items-center gap-2 relative z-10 cursor-pointer ${step === 3 ? 'opacity-100' : 'opacity-70'}`}
            >
              <div
                className={`w-6 h-6 rounded-full flex items-center justify-center text-[10px] font-mono font-bold transition-all ${
                  step === 3
                    ? 'bg-[#0453cd] text-white ring-4 ring-blue-500/20'
                    : 'bg-slate-800 text-slate-400'
                }`}
              >
                03
              </div>
              <span className="text-xs font-mono font-semibold text-slate-200">Dispatch</span>
            </div>
          </div>
        </div>

        {/* ── Error Banner ── */}
        {errorMessage && (
          <div className="mx-6 mt-4 p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-start gap-2.5 text-xs text-rose-800">
            <AlertCircle className="h-4 w-4 shrink-0 text-rose-600 mt-0.5" />
            <div className="flex-1">
              <p className="font-semibold">Action Required</p>
              <p className="mt-0.5 text-rose-700">{errorMessage}</p>
              {createdProjectId && (
                <div className="mt-2 pt-2 border-t border-rose-200/60 flex items-center gap-3">
                  <button
                    type="button"
                    onClick={() => {
                      setErrorMessage(null);
                      setSubmissionStage('completed');
                    }}
                    className="font-mono font-semibold text-rose-900 hover:text-rose-950 underline flex items-center gap-1"
                  >
                    Proceed to Project Console without remaining files →
                  </button>
                  <span className="text-rose-400">·</span>
                  <span className="text-[11px] text-rose-600">
                    Project is registered in D1. You can upload references later from the workspace.
                  </span>
                </div>
              )}
            </div>
            <button onClick={() => setErrorMessage(null)} className="text-rose-400 hover:text-rose-600">
              <X className="h-4 w-4" />
            </button>
          </div>
        )}

        {/* ── Wizard Body ── */}
        <div className="p-6 space-y-5 max-h-[65vh] overflow-y-auto">
          {/* ══════════════════ STEP 1: IDENTITY ══════════════════ */}
          {step === 1 && (
            <div className="space-y-4">
              {/* Section Header */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-200">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-3.5 bg-[#0a192f] rounded-xs" />
                  <h3 className="text-xs font-bold font-mono tracking-wider uppercase text-slate-800">
                    Section A // Assignment Identity & Student Selection
                  </h3>
                </div>
                <span className="text-[10px] font-mono text-amber-700 bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                  [MANDATORY]
                </span>
              </div>

              {/* Assignment Target Display */}
              <div className="space-y-1.5">
                <div className="flex items-center justify-between">
                  <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                    Assignment Target <span className="text-rose-500">*</span>
                  </label>
                  <span className="text-[10px] font-mono text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                    CURRICULUM ASSIGNMENT
                  </span>
                </div>
                <div className="p-1 bg-slate-100 rounded-xl border border-slate-200">
                  <div className="py-2 px-3 rounded-lg text-xs font-bold bg-[#0a192f] text-white shadow-xs flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <GraduationCap className="w-3.5 h-3.5 text-emerald-400" />
                      <span>Student Apprentice</span>
                    </div>
                    <span className="text-[9px] font-mono text-emerald-400 bg-emerald-950/60 px-1.5 py-0.5 rounded border border-emerald-800">
                      ACTIVE TARGET
                    </span>
                  </div>
                </div>
              </div>

              {/* Student Selection */}
              <div className="space-y-1.5">
                <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                  Enrolled Student Apprentice <span className="text-rose-500">*</span>
                </label>
                {fetchingStudents ? (
                  <div className="p-3 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-500">
                    Loading enrolled students...
                  </div>
                ) : students.length === 0 ? (
                  <div className="p-3 bg-amber-50 border border-amber-200 rounded-xl text-xs text-amber-800 font-mono">
                    No registered students found in database. Trainees must register via the Student Portal.
                  </div>
                ) : (
                  <div className="relative">
                    <select
                      value={selectedStudentId}
                      onChange={(e) => setSelectedStudentId(e.target.value)}
                      className="w-full text-xs font-medium text-slate-900 bg-white border border-slate-200 rounded-xl px-3.5 py-2.5 focus:border-[#0453cd] focus:ring-1 focus:ring-[#0453cd] outline-none shadow-xs"
                    >
                      {students.map((stu) => (
                        <option key={stu.id} value={stu.id}>
                          {stu.name} ({stu.email}) {stu.college_name ? `· ${stu.college_name}` : ''}
                        </option>
                      ))}
                    </select>
                  </div>
                )}
                <p className="text-[10px] font-mono text-slate-500">
                  Select the student apprentice who will receive this practical assignment directly in their learning portal.
                </p>
              </div>

              {/* Assignment Title */}
              <div className="space-y-1.5">
                <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                  Assignment Title / Project Designation <span className="text-rose-500">*</span>
                </label>
                <div className="relative">
                  <Building2 className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                  <input
                    type="text"
                    value={projectName}
                    onChange={(e) => setProjectName(e.target.value)}
                    placeholder="e.g. AutoCAD Floor Plan & Section Detailing Practical"
                    className="w-full text-xs font-medium text-slate-900 bg-white border border-slate-200 rounded-xl pl-10 pr-3.5 py-2.5 focus:border-[#0453cd] focus:ring-1 focus:ring-[#0453cd] outline-none shadow-xs"
                  />
                </div>
              </div>

              {/* Campus / Studio Lab Location */}
              <div className="space-y-1.5">
                <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                  Campus / Studio Lab Location
                </label>
                <div className="relative">
                  <MapPin className="w-4 h-4 text-slate-400 absolute left-3.5 top-3" />
                  <input
                    type="text"
                    value={projectAddress}
                    onChange={(e) => setProjectAddress(e.target.value)}
                    placeholder="e.g. CAD Design Lab, Semester 4 Practical"
                    className="w-full text-xs font-medium text-slate-900 bg-white border border-slate-200 rounded-xl pl-10 pr-3.5 py-2.5 focus:border-[#0453cd] focus:ring-1 focus:ring-[#0453cd] outline-none shadow-xs"
                  />
                </div>
              </div>

              {/* Practical Instructions & Brief */}
              <div className="space-y-1.5">
                <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                  Assignment Instructions & Student Brief
                </label>
                <textarea
                  rows={3}
                  value={instructions}
                  onChange={(e) => setInstructions(e.target.value)}
                  placeholder="Provide drafting requirements, required layers/lineweights, submission deliverables (DWG/PDF), or rubric notes for the student..."
                  className="w-full text-xs font-medium text-slate-900 bg-white border border-slate-200 rounded-xl p-3 focus:border-[#0453cd] focus:ring-1 focus:ring-[#0453cd] outline-none shadow-xs resize-y"
                />
                <p className="text-[10px] font-mono text-slate-500">
                  These instructions will be displayed directly inside the student's project workspace in their portal.
                </p>
              </div>

              {/* Reference Code [AUTOGEN] */}
              <div className="space-y-1.5">
                <div className="flex justify-between items-center">
                  <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                    Curriculum Reference Code
                  </label>
                  <span className="text-[10px] font-mono text-slate-400">[AUTOGEN]</span>
                </div>
                <input
                  type="text"
                  readOnly
                  value={clientRefCode}
                  className="w-full font-mono text-xs tracking-wider font-semibold text-slate-700 bg-slate-100 border border-slate-200 rounded-xl px-3.5 py-2 select-all"
                />
              </div>
            </div>
          )}

          {/* ══════════════════ STEP 2: SCOPE & CAD ══════════════════ */}
          {step === 2 && (
            <div className="space-y-5">
              {/* Scope Section Header */}
              <div className="flex items-center justify-between pb-2 border-b border-slate-200">
                <div className="flex items-center gap-2">
                  <span className="w-1.5 h-3.5 bg-[#0a192f] rounded-xs" />
                  <h3 className="text-xs font-bold font-mono tracking-wider uppercase text-slate-800">
                    Section B // Scope, Scale & Discipline
                  </h3>
                </div>
                <span className="text-[10px] font-mono text-amber-700 bg-amber-50 px-2 py-0.5 rounded border border-amber-200">
                  [REQUIRED]
                </span>
              </div>

              {/* Discipline Grid */}
              <div className="space-y-2">
                <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                  Discipline Category
                </label>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {DISCIPLINES.map((d) => {
                    const isSelected = selectedDiscipline === d.id;
                    return (
                      <button
                        key={d.id}
                        type="button"
                        onClick={() => setSelectedDiscipline(d.id)}
                        className={`p-3 rounded-xl border text-left transition-all flex flex-col justify-between ${
                          isSelected
                            ? 'bg-[#0a192f] text-white border-[#0a192f] shadow-sm'
                            : 'bg-white text-slate-700 border-slate-200 hover:border-slate-300'
                        }`}
                      >
                        <div className="flex items-center justify-between w-full">
                          <span className="text-xs font-semibold">{d.label}</span>
                          <span
                            className={`w-2 h-2 rounded-full ${
                              isSelected ? 'bg-emerald-400' : 'border border-slate-300'
                            }`}
                          />
                        </div>
                        <p className={`text-[10px] mt-1 line-clamp-1 ${isSelected ? 'text-slate-300' : 'text-slate-500'}`}>
                          {d.desc}
                        </p>
                      </button>
                    );
                  })}
                </div>
              </div>

              {/* Scale & Area Row */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 pt-1">
                <div className="space-y-1.5">
                  <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                    Drawing Scale
                  </label>
                  <select
                    value={drawingScale}
                    onChange={(e) => setDrawingScale(e.target.value)}
                    className="w-full text-xs font-medium text-slate-900 bg-white border border-slate-200 rounded-xl px-3 py-2.5 focus:border-[#0453cd] focus:ring-1 focus:ring-[#0453cd] outline-none"
                  >
                    {DRAWING_SCALES.map((s) => (
                      <option key={s.value} value={s.value}>
                        {s.label}
                      </option>
                    ))}
                  </select>
                </div>

                <div className="space-y-1.5">
                  <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                    Area Footprint (sq.ft) <span className="text-rose-500">*</span>
                  </label>
                  <div className="relative">
                    <input
                      type="number"
                      min="100"
                      step="50"
                      value={areaFootprint}
                      onChange={(e) => setAreaFootprint(e.target.value)}
                      className="w-full text-xs font-medium text-slate-900 bg-white border border-slate-200 rounded-xl px-3 py-2.5 focus:border-[#0453cd] focus:ring-1 focus:ring-[#0453cd] outline-none"
                    />
                    <span className="absolute right-3 top-2.5 text-[11px] font-mono text-slate-400">sq.ft</span>
                  </div>
                </div>
              </div>

              {/* Academic Training Schedule */}
              <div className="space-y-2 pt-2">
                <div className="flex items-center justify-between">
                  <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                    Section C // Academic Training Schedule
                  </label>
                  <span className="text-[10px] font-mono text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200">
                    CURRICULUM
                  </span>
                </div>
                <div className="p-4 bg-emerald-50/70 border border-emerald-200 rounded-xl flex items-start gap-3">
                  <div className="p-2 bg-emerald-100 rounded-lg text-emerald-700 shrink-0 mt-0.5">
                    <GraduationCap className="w-5 h-5" />
                  </div>
                  <div className="text-xs font-mono">
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-slate-900">Apprentice Studio Training Schedule</span>
                      <span className="bg-emerald-600 text-white text-[9px] px-1.5 py-0.5 rounded font-bold uppercase tracking-wider">
                        ZERO SURCHARGE
                      </span>
                    </div>
                    <p className="text-slate-600 mt-1 leading-relaxed">
                      This practical training assignment follows the student apprentice curriculum workflow with revision cycles. No commercial delivery surcharge applies.
                    </p>
                  </div>
                </div>
              </div>

              {/* CAD & Blueprint File Upload Dropzone */}
              <div className="space-y-2 pt-2">
                <div className="flex items-center justify-between">
                  <label className="block text-[11px] font-mono uppercase tracking-wider text-slate-600">
                    Section D // Reference Blueprints & Practical Assignment Materials
                  </label>
                  <span className="text-[10px] font-mono text-slate-500">[DWG/DXF/PDF/RVT · MAX 50MB]</span>
                </div>

                <div className="border-2 border-dashed border-sky-400/60 hover:border-[#0a192f] bg-sky-50/40 rounded-xl p-5 text-center transition-colors">
                  <UploadCloud className="w-8 h-8 text-[#0453cd] mx-auto mb-2" />
                  <p className="text-xs font-semibold text-slate-900">
                    Upload Assignment Reference Files for Student
                  </p>
                  <p className="text-[11px] text-slate-500 mt-0.5">Supports DWG, DXF, RVT, PDF, PNG, JPG, or ZIP</p>

                  <label className="mt-3 inline-flex items-center gap-1.5 px-4 py-1.5 rounded-full bg-[#0a192f] text-white text-xs font-mono font-medium shadow-xs cursor-pointer hover:bg-slate-800 active:scale-95 transition-all">
                    <span>Select Files</span>
                    <input
                      type="file"
                      multiple
                      accept=".pdf,.dwg,.dxf,.png,.jpg,.jpeg,.zip"
                      onChange={handleFileChange}
                      className="hidden"
                    />
                  </label>
                </div>

                {/* Selected Files List */}
                {selectedFiles.length > 0 && (
                  <div className="space-y-1.5 pt-1">
                    {selectedFiles.map((file, idx) => (
                      <div
                        key={`${file.name}-${idx}`}
                        className="p-2.5 rounded-lg border border-slate-200 bg-white flex items-center justify-between"
                      >
                        <div className="flex items-center gap-2.5 overflow-hidden">
                          <div className="w-7 h-7 rounded bg-blue-900 text-blue-200 font-mono text-[9px] font-bold flex items-center justify-center shrink-0">
                            {file.name.split('.').pop()?.toUpperCase() || 'FILE'}
                          </div>
                          <div className="truncate">
                            <p className="text-xs font-medium text-slate-900 truncate">{file.name}</p>
                            <p className="text-[10px] font-mono text-slate-400">
                              {(file.size / (1024 * 1024)).toFixed(2)} MB · Ready for R2 upload
                            </p>
                          </div>
                        </div>
                        <button
                          type="button"
                          onClick={() => removeFile(idx)}
                          className="text-slate-400 hover:text-rose-500 p-1 transition-colors"
                        >
                          <X className="w-4 h-4" />
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            </div>
          )}

          {/* ══════════════════ STEP 3: DISPATCH & REVIEW ══════════════════ */}
          {step === 3 && (
            <div className="space-y-5">
              {/* Completed State */}
              {submissionStage === 'completed' ? (
                <div className="text-center py-6 space-y-4">
                  <div className="w-14 h-14 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto shadow-sm">
                    <CheckCircle2 className="w-8 h-8" />
                  </div>
                  <div>
                    <h3 className="text-base font-bold text-slate-900">
                      Practical Assignment Successfully Dispatched!
                    </h3>
                    <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
                      The practical assignment has been registered in D1 and is immediately visible to the student in their learning portal.
                    </p>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-xl p-4 text-left font-mono text-xs space-y-2 max-w-md mx-auto">
                    <div className="flex justify-between">
                      <span className="text-slate-500">Project ID:</span>
                      <span className="font-bold text-slate-900">{createdProjectId}</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Assigned Student:</span>
                      <span className="text-slate-900">{selectedStudent?.name} ({selectedStudent?.email})</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Files Uploaded:</span>
                      <span className="text-slate-900">{uploadedFileCount} of {selectedFiles.length} files</span>
                    </div>
                    <div className="flex justify-between">
                      <span className="text-slate-500">Service Status:</span>
                      <span className="text-blue-600 font-bold">
                        WAITING_ACCEPTANCE (Student Assigned)
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center justify-center gap-3 pt-3">
                    <Button
                      variant="outline"
                      onClick={() => {
                        onSuccess(createdProjectId || undefined);
                        onClose();
                      }}
                    >
                      Done
                    </Button>
                    <Button
                      onClick={() => {
                        onSuccess(createdProjectId || undefined);
                        onClose();
                        if (createdProjectId) {
                          router.push(`/projects/${createdProjectId}`);
                        }
                      }}
                      className="bg-[#0453cd] hover:bg-blue-700 text-white"
                    >
                      View in Project Console
                    </Button>
                  </div>
                </div>
              ) : (
                /* Review Form & Live Estimate */
                <div className="space-y-4">
                  {/* Parameter Review Card */}
                  <div className="bg-white border border-slate-200 rounded-xl p-4 space-y-3">
                    <div className="flex items-center justify-between border-b border-slate-100 pb-2">
                      <h4 className="text-xs font-mono font-bold uppercase tracking-wider text-slate-800">
                        Practical Assignment Summary
                      </h4>
                      <span className="text-[10px] font-mono text-slate-500">{clientRefCode}</span>
                    </div>

                    <div className="grid grid-cols-2 gap-y-2.5 gap-x-4 text-xs font-mono">
                      <div>
                        <span className="text-[10px] text-slate-500 block uppercase">Project Title</span>
                        <span className="font-semibold text-slate-900 truncate block">{projectName}</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-500 block uppercase">Assigned Student</span>
                        <span className="font-semibold text-slate-900 truncate block">
                          {selectedStudent?.name || 'Student Apprentice'}
                        </span>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-500 block uppercase">Discipline & Scale</span>
                        <span className="text-slate-800">{selectedDiscipline} · {drawingScale}</span>
                      </div>
                      <div>
                        <span className="text-[10px] text-slate-500 block uppercase">Footprint Area</span>
                        <span className="text-slate-800">{areaFootprint} sq.ft</span>
                      </div>
                      <div className="col-span-2">
                        <span className="text-[10px] text-slate-500 block uppercase">Program Track</span>
                        <span className="text-emerald-700 font-semibold">
                          Academic Architectural Practical Training
                        </span>
                      </div>
                      {instructions && (
                        <div className="col-span-2">
                          <span className="text-[10px] text-slate-500 block uppercase">Student Instructions</span>
                          <span className="text-slate-800 line-clamp-3">{instructions}</span>
                        </div>
                      )}
                      {selectedFiles.length > 0 && (
                        <div className="col-span-2">
                          <span className="text-[10px] text-slate-500 block uppercase">Reference Files</span>
                          <span className="text-slate-700">
                            {selectedFiles.length} file{selectedFiles.length !== 1 ? 's' : ''} ({selectedFiles.map((f) => f.name).join(', ')})
                          </span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Pricing / Training Estimate Card */}
                  <div className="bg-[#0a192f] text-white rounded-xl p-4 border border-slate-800 space-y-3">
                    <div className="flex items-center justify-between border-b border-slate-800 pb-2">
                      <div className="flex items-center gap-2">
                        <GraduationCap className="w-4 h-4 text-emerald-400" />
                        <h4 className="text-xs font-mono font-bold uppercase tracking-wider text-slate-200">
                          Academic Curriculum Assignment
                        </h4>
                      </div>
                      <span className="text-[10px] font-mono text-emerald-400 bg-emerald-950/60 px-2 py-0.5 rounded border border-emerald-800">
                        APPRENTICE TRACK
                      </span>
                    </div>

                    <div className="space-y-2 text-xs font-mono">
                      <div className="flex justify-between text-slate-300">
                        <span>Curriculum Module Fee:</span>
                        <span className="font-semibold text-emerald-400">$0.00 (Academic Practical Training)</span>
                      </div>
                      <div className="flex justify-between text-slate-300">
                        <span>Target Apprentice:</span>
                        <span className="font-semibold text-slate-200">{selectedStudent?.name || 'Selected Student'}</span>
                      </div>
                      <div className="flex justify-between text-sm font-bold text-white pt-2 border-t border-slate-700">
                        <span>Total Student Billing:</span>
                        <span className="text-emerald-400">$0.00 USD</span>
                      </div>
                    </div>
                  </div>

                  {/* Disclaimer */}
                  <div className="p-3 bg-emerald-500/10 border border-emerald-500/30 rounded-xl text-emerald-200 text-[11px] font-mono leading-relaxed flex items-start gap-2.5">
                    <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0 mt-0.5" />
                    <div>
                      <span className="font-bold text-emerald-300">Direct Student Assignment:</span> This assignment will be immediately dispatched to the student's learning portal under their coursework queue. The student can review requirements, access reference files, and submit CAD deliverables for review.
                    </div>
                  </div>

                  {/* Progress Indicator when submitting */}
                  {(submissionStage === 'creating_project' || submissionStage === 'uploading_files') && (
                    <div className="p-4 bg-blue-50 border border-blue-200 rounded-xl space-y-2 text-xs font-mono">
                      <div className="flex items-center justify-between text-blue-900 font-semibold">
                        <span>
                          {submissionStage === 'creating_project'
                            ? '1/2: Registering project brief in D1 SQLite...'
                            : `2/2: Uploading reference files to R2 (${uploadedFileCount}/${selectedFiles.length})...`}
                        </span>
                        <span className="animate-spin">⏳</span>
                      </div>
                      <div className="w-full bg-blue-200 h-1.5 rounded-full overflow-hidden">
                        <div
                          className="bg-[#0453cd] h-full transition-all duration-300"
                          style={{
                            width:
                              submissionStage === 'creating_project'
                                ? '50%'
                                : `${50 + (uploadedFileCount / Math.max(1, selectedFiles.length)) * 50}%`,
                          }}
                        />
                      </div>
                    </div>
                  )}
                </div>
              )}
            </div>
          )}
        </div>

        {/* ── Wizard Sticky Footer Bar ── */}
        {submissionStage !== 'completed' && (
          <div className="px-6 py-4 bg-white border-t border-slate-200 flex items-center justify-between">
            {/* Step Navigation Back */}
            {step > 1 ? (
              <Button
                variant="outline"
                type="button"
                onClick={() => setStep((s) => (s - 1) as 1 | 2)}
                disabled={submissionStage === 'creating_project' || submissionStage === 'uploading_files'}
                className="text-xs font-mono"
              >
                <ArrowLeft className="w-3.5 h-3.5 mr-1" /> Back
              </Button>
            ) : (
              <Button variant="ghost" type="button" onClick={onClose} className="text-xs font-mono">
                Cancel
              </Button>
            )}

            {/* Step Navigation Forward / Dispatch */}
            {step === 1 && (
              <Button
                type="button"
                onClick={() => {
                  if (validateStep1()) setStep(2);
                }}
                className="bg-[#0a192f] hover:bg-slate-800 text-white text-xs font-mono"
              >
                Continue to Scope <ArrowRight className="w-3.5 h-3.5 ml-1" />
              </Button>
            )}

            {step === 2 && (
              <Button
                type="button"
                onClick={() => {
                  if (validateStep2()) setStep(3);
                }}
                className="bg-[#0a192f] hover:bg-slate-800 text-white text-xs font-mono"
              >
                Review & Estimate <ArrowRight className="w-3.5 h-3.5 ml-1" />
              </Button>
            )}

            {step === 3 && (
              <Button
                type="button"
                onClick={handleDispatchProject}
                disabled={submissionStage === 'creating_project' || submissionStage === 'uploading_files'}
                className="bg-[#0453cd] hover:bg-blue-700 text-white text-xs font-mono font-bold shadow-md shadow-blue-900/20 px-5"
              >
                {submissionStage === 'error'
                  ? uploadedFileCount > 0
                    ? `Retry Upload (${uploadedFileCount}/${selectedFiles.length} uploaded)`
                    : 'Retry Dispatching'
                  : 'Dispatch Practical Assignment'}
                <Sparkles className="w-3.5 h-3.5 ml-1.5 text-amber-300" />
              </Button>
            )}
          </div>
        )}
      </div>
    </Modal>
  );
}

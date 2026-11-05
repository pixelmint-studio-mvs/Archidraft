'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { adminApi } from '@/lib/api';
import { User, Project } from '@/lib/types';
import {
  HardHat,
  Search,
  CheckCircle2,
  AlertCircle,
  FolderKanban,
  Building,
  Mail,
  Phone,
  ArrowRight,
  ArrowLeft,
  Layers,
  Sparkles,
  MapPin,
  Calendar,
  PlusCircle,
  FileText,
  UserCheck,
  Check,
  RefreshCw,
  FolderPlus,
} from 'lucide-react';

export interface AssignEngineerProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess: (projectId: string, engineerId: string) => void;
  preSelectedEngineer?: User | null;
  engineers?: User[];
  projects?: Project[];
}

const DRAWING_DISCIPLINES = [
  { id: 'Architectural Layout', label: 'Architectural Layout', rateKey: 'FLOOR_PLAN', desc: 'Standard architectural layout & space planning' },
  { id: 'Structural Framing', label: 'Structural Framing', rateKey: 'STRUCTURAL', desc: 'Load-bearing columns, beams & reinforcement' },
  { id: 'MEP & HVAC Plan', label: 'MEP & HVAC Plan', rateKey: 'ELECTRICAL', desc: 'Mechanical, electrical, plumbing & ductwork' },
  { id: 'Interior Blueprint', label: 'Interior Blueprint', rateKey: 'SECTION', desc: 'Detailed architectural sections & fit-out' },
  { id: 'Municipal / Permit', label: 'Municipal / Permit', rateKey: 'SITE_PLAN', desc: 'Permit packages, surveys & zoning' },
];

export function AssignEngineerProjectModal({
  isOpen,
  onClose,
  onSuccess,
  preSelectedEngineer,
  engineers: initialEngineers,
  projects: initialProjects,
}: AssignEngineerProjectModalProps) {
  // Stepper: 1 = Select Engineer, 2 = Select Project, 3 = Review & Confirm
  const [step, setStep] = useState<1 | 2 | 3>(1);

  // Data sets
  const [engineersList, setEngineersList] = useState<User[]>(initialEngineers || []);
  const [projectsList, setProjectsList] = useState<Project[]>(initialProjects || []);
  const [loadingData, setLoadingData] = useState<boolean>(false);

  // Step 1: Selected Engineer
  const [selectedEngineerId, setSelectedEngineerId] = useState<string>('');
  const [engineerSearch, setEngineerSearch] = useState<string>('');

  // Step 2: Selected Project (Existing or New)
  const [projectMode, setProjectMode] = useState<'existing' | 'new'>('existing');
  const [selectedProjectId, setSelectedProjectId] = useState<string>('');
  const [projectSearch, setProjectSearch] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // Step 2: New Project Fields (if admin chooses to create on behalf of engineer)
  const [newProjectName, setNewProjectName] = useState<string>('');
  const [newProjectAddress, setNewProjectAddress] = useState<string>('');
  const [newDrawingType, setNewDrawingType] = useState<string>('Architectural Layout');
  const [newProjectArea, setNewProjectArea] = useState<string>('1500');
  const [newInstructions, setNewInstructions] = useState<string>('');

  // Step 3 / Submission State
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [isSuccess, setIsSuccess] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const [stepError, setStepError] = useState<string | null>(null);
  const [completedAssignmentDetails, setCompletedAssignmentDetails] = useState<{
    projectId: string;
    projectName: string;
    engineerId: string;
    engineerName: string;
  } | null>(null);

  // Initialize and load data on open
  useEffect(() => {
    if (isOpen) {
      setStep(1);
      setIsSuccess(false);
      setIsSubmitting(false);
      setErrorMessage(null);
      setStepError(null);
      setCompletedAssignmentDetails(null);
      setProjectMode('existing');
      setSelectedProjectId('');
      setProjectSearch('');
      setStatusFilter('ALL');
      setNewProjectName('');
      setNewProjectAddress('');
      setNewDrawingType('Architectural Layout');
      setNewProjectArea('1500');
      setNewInstructions('');

      // Pre-select engineer if provided
      if (preSelectedEngineer?.id) {
        setSelectedEngineerId(preSelectedEngineer.id);
      } else {
        setSelectedEngineerId('');
      }

      // Fetch latest engineers and projects if not provided or to ensure fresh data
      const fetchFreshData = async () => {
        setLoadingData(true);
        try {
          const [engs, prjs] = await Promise.all([
            adminApi.getUsers('CLIENT'),
            adminApi.getProjects(),
          ]);
          setEngineersList(engs || []);
          setProjectsList(prjs || []);
        } catch (err: any) {
          console.warn('Failed to load fresh data for assign modal, using provided props:', err);
          if (initialEngineers) setEngineersList(initialEngineers);
          if (initialProjects) setProjectsList(initialProjects);
        } finally {
          setLoadingData(false);
        }
      };

      fetchFreshData();
    }
  }, [isOpen, preSelectedEngineer, initialEngineers, initialProjects]);

  // Selected engineer object
  const selectedEngineer = useMemo(() => {
    return engineersList.find((e) => e.id === selectedEngineerId) || null;
  }, [engineersList, selectedEngineerId]);

  // Selected project object
  const selectedProject = useMemo(() => {
    return projectsList.find((p) => p.id === selectedProjectId) || null;
  }, [projectsList, selectedProjectId]);

  // Project count per engineer
  const projectCountByEngineer = useMemo(() => {
    const counts: Record<string, number> = {};
    projectsList.forEach((p) => {
      counts[p.client_id] = (counts[p.client_id] || 0) + 1;
    });
    return counts;
  }, [projectsList]);

  // Filtered engineers list
  const filteredEngineers = useMemo(() => {
    return engineersList.filter((eng) => {
      if (!engineerSearch.trim()) return true;
      const q = engineerSearch.toLowerCase();
      const idNum = (eng.identification_number || '').toLowerCase();
      const name = (eng.name || '').toLowerCase();
      const email = (eng.email || '').toLowerCase();
      const company = (eng.company_name || '').toLowerCase();
      const mobile = (eng.mobile || '').toLowerCase();
      const uid = (eng.id || '').toLowerCase();
      return idNum.includes(q) || name.includes(q) || email.includes(q) || company.includes(q) || mobile.includes(q) || uid.includes(q);
    });
  }, [engineersList, engineerSearch]);

  // Filtered projects list
  const filteredProjects = useMemo(() => {
    return projectsList.filter((prj) => {
      // Status filter
      if (statusFilter !== 'ALL' && prj.status !== statusFilter) return false;

      // Text search
      if (!projectSearch.trim()) return true;
      const q = projectSearch.toLowerCase();
      const name = (prj.project_name || '').toLowerCase();
      const type = (prj.drawing_type || '').toLowerCase();
      const id = (prj.id || '').toLowerCase();
      const addr = (prj.project_address || '').toLowerCase();
      const client = (prj.client_name || '').toLowerCase();
      return name.includes(q) || type.includes(q) || id.includes(q) || addr.includes(q) || client.includes(q);
    });
  }, [projectsList, projectSearch, statusFilter]);

  // Step 1 Validation & Proceed
  const handleProceedToStep2 = () => {
    setStepError(null);
    if (!selectedEngineerId || !selectedEngineer) {
      setStepError('Please select a registered Engineer/Architect to proceed.');
      return;
    }
    setStep(2);
  };

  // Step 2 Validation & Proceed
  const handleProceedToStep3 = () => {
    setStepError(null);
    if (projectMode === 'existing') {
      if (!selectedProjectId || !selectedProject) {
        setStepError('Please select a project to assign.');
        return;
      }
    } else {
      if (!newProjectName.trim()) {
        setStepError('Project name is required for new project creation.');
        return;
      }
      if (!newDrawingType.trim()) {
        setStepError('Drawing type is required.');
        return;
      }
    }
    setStep(3);
  };

  // Step 3: Confirm Assignment
  const handleConfirmAssignment = async () => {
    if (!selectedEngineer) return;
    setIsSubmitting(true);
    setErrorMessage(null);

    try {
      if (projectMode === 'existing') {
        if (!selectedProject) throw new Error('No project selected.');

        const result = await adminApi.assignProjectToEngineer(selectedProject.id, selectedEngineer.id);
        if (!result || result.success === false) {
          throw new Error(result?.message || 'Failed to assign project to Engineer/Architect');
        }

        const details = {
          projectId: selectedProject.id,
          projectName: selectedProject.project_name,
          engineerId: selectedEngineer.id,
          engineerName: selectedEngineer.name || selectedEngineer.email,
        };
        setCompletedAssignmentDetails(details);
        setIsSuccess(true);
        onSuccess(selectedProject.id, selectedEngineer.id);
      } else {
        // Create and assign new project for engineer
        const result = await adminApi.createProject({
          clientId: selectedEngineer.id,
          projectName: newProjectName.trim(),
          projectAddress: newProjectAddress.trim() || 'Client Site Scope',
          drawingType: newDrawingType,
          drawingName: `${newDrawingType} Package`,
          projectArea: Number(newProjectArea) || 1500,
          instructions: newInstructions.trim() || undefined,
        });

        if (!result || !result.id) {
          throw new Error('Failed to create and assign project to Engineer/Architect');
        }

        const details = {
          projectId: result.id,
          projectName: newProjectName.trim(),
          engineerId: selectedEngineer.id,
          engineerName: selectedEngineer.name || selectedEngineer.email,
        };
        setCompletedAssignmentDetails(details);
        setIsSuccess(true);
        onSuccess(result.id, selectedEngineer.id);
      }
    } catch (err: any) {
      console.error('Assignment submission error:', err);
      setErrorMessage(err.message || 'An error occurred while assigning project to Engineer/Architect. Please try again.');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Engineer/Architect Project Assignment"
      description="Assign and commission architectural drafting projects to verified structural, civil, and consulting engineers and architects"
      maxWidth="3xl"
    >
      {/* ─── Success Confirmation Screen ─────────────────────────────── */}
      {isSuccess && completedAssignmentDetails ? (
        <div className="py-8 px-4 text-center space-y-6">
          <div className="h-16 w-16 rounded-full bg-emerald-50 border border-emerald-200 text-emerald-600 flex items-center justify-center mx-auto shadow-xs">
            <CheckCircle2 className="h-9 w-9 text-emerald-600" />
          </div>

          <div className="space-y-2">
            <h3 className="text-xl font-bold text-slate-900 font-mono">Project Successfully Assigned!</h3>
            <p className="text-xs text-slate-500 font-mono max-w-md mx-auto">
              Project <span className="font-semibold text-slate-800">"{completedAssignmentDetails.projectName}"</span> has
              been assigned to Engineer/Architect <span className="font-semibold text-[#0453cd]">{completedAssignmentDetails.engineerName}</span>.
            </p>
          </div>

          <Card technicalCorners className="p-4 bg-slate-50 border-slate-200 text-left max-w-lg mx-auto space-y-3">
            <div className="flex items-center justify-between text-xs font-mono border-b border-slate-200/80 pb-2">
              <span className="text-slate-500">Project Identifier</span>
              <span className="font-bold text-slate-900">{completedAssignmentDetails.projectId}</span>
            </div>
            <div className="flex items-center justify-between text-xs font-mono border-b border-slate-200/80 pb-2">
              <span className="text-slate-500">Assigned Engineer/Architect</span>
              <span className="font-bold text-[#0453cd]">{completedAssignmentDetails.engineerName}</span>
            </div>
            <div className="flex items-center justify-between text-xs font-mono border-b border-slate-200/80 pb-2">
              <span className="text-slate-500">Engineer/Architect UID</span>
              <span className="text-slate-600">{completedAssignmentDetails.engineerId.substring(0, 16)}...</span>
            </div>
            <div className="flex items-center justify-between text-xs font-mono">
              <span className="text-slate-500">Live Status</span>
              <span className="inline-flex items-center gap-1.5 text-emerald-600 font-bold">
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                <span>Active in Engineer/Architect Directory</span>
              </span>
            </div>
          </Card>

          <div className="flex justify-center pt-2">
            <Button
              variant="primary"
              onClick={onClose}
              className="bg-[#0453cd] hover:bg-blue-700 text-white font-mono text-xs px-8 py-2.5 rounded-xl shadow-xs"
            >
              Done & Return to Directory
            </Button>
          </div>
        </div>
      ) : (
        <div className="space-y-6">
          {/* ─── Step Indicator Progress Bar ──────────────────────────── */}
          <div className="border-b border-slate-200 pb-4">
            <div className="flex items-center justify-between mb-2">
              <div className="flex items-center gap-2">
                <span className="h-6 w-6 rounded-full bg-[#0453cd] text-white flex items-center justify-center text-xs font-mono font-bold">
                  {step}
                </span>
                <span className="text-xs font-bold font-mono text-slate-900">
                  {step === 1 && 'Step 1: Select Registered Engineer/Architect'}
                  {step === 2 && 'Step 2: Select Project to Assign'}
                  {step === 3 && 'Step 3: Review & Confirm Assignment'}
                </span>
              </div>
              <span className="text-[11px] font-mono text-slate-400">Step {step} of 3</span>
            </div>

            {/* Visual Step Bar */}
            <div className="grid grid-cols-3 gap-2">
              <div className={`h-1.5 rounded-full transition-all ${step >= 1 ? 'bg-[#0453cd]' : 'bg-slate-200'}`} />
              <div className={`h-1.5 rounded-full transition-all ${step >= 2 ? 'bg-[#0453cd]' : 'bg-slate-200'}`} />
              <div className={`h-1.5 rounded-full transition-all ${step >= 3 ? 'bg-[#0453cd]' : 'bg-slate-200'}`} />
            </div>
          </div>

          {/* Validation or Error Alert */}
          {(stepError || errorMessage) && (
            <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-mono flex items-center gap-2.5">
              <AlertCircle className="h-4 w-4 shrink-0 text-rose-600" />
              <span>{stepError || errorMessage}</span>
            </div>
          )}

          {/* ─── STEP 1: Select Engineer ─────────────────────────────── */}
          {step === 1 && (
            <div className="space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div className="relative flex-1">
                  <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    value={engineerSearch}
                    onChange={(e) => setEngineerSearch(e.target.value)}
                    placeholder="Search engineers/architects by ID number, name, email, company, or UID..."
                    className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd] focus:border-[#0453cd]"
                  />
                </div>
                <span className="text-xs text-slate-500 font-mono whitespace-nowrap">
                  {filteredEngineers.length} {filteredEngineers.length === 1 ? 'engineer/architect' : 'engineers/architects'} available
                </span>
              </div>

              {loadingData ? (
                <div className="p-12 text-center">
                  <RefreshCw className="h-6 w-6 text-[#0453cd] animate-spin mx-auto mb-2" />
                  <p className="text-xs text-slate-500 font-mono">Loading registered engineers/architects...</p>
                </div>
              ) : filteredEngineers.length === 0 ? (
                <div className="p-12 text-center border border-dashed border-slate-200 rounded-xl">
                  <HardHat className="h-8 w-8 text-slate-300 mx-auto mb-2" />
                  <p className="text-xs font-bold text-slate-700">No matching Engineers/Architects found</p>
                  <p className="text-[11px] text-slate-400 font-mono mt-1">Try adjusting your search criteria</p>
                </div>
              ) : (
                <div className="max-h-[340px] overflow-y-auto space-y-2 pr-1">
                  {filteredEngineers.map((engineer) => {
                    const isSelected = selectedEngineerId === engineer.id;
                    const pCount = projectCountByEngineer[engineer.id] || 0;

                    return (
                        <div
                        key={engineer.id}
                        onClick={() => {
                          setSelectedEngineerId(engineer.id);
                          setStepError(null);
                        }}
                        className={`p-3.5 rounded-xl border transition-all cursor-pointer flex items-center justify-between gap-3 ${
                          isSelected
                            ? 'bg-blue-50/70 border-[#0453cd] ring-1 ring-[#0453cd] shadow-xs'
                            : 'bg-white border-slate-200 hover:border-slate-300 hover:bg-slate-50/60'
                        }`}
                      >
                        <div className="flex items-center gap-3 min-w-0 flex-1">
                          <div
                            className={`h-10 w-10 rounded-xl flex items-center justify-center font-bold text-sm shrink-0 border ${
                              isSelected
                                ? 'bg-[#0453cd] text-white border-[#0453cd]'
                                : 'bg-blue-50 text-[#0453cd] border-blue-200'
                            }`}
                          >
                            {(engineer.name || 'E').charAt(0).toUpperCase()}
                          </div>
                          <div className="min-w-0 flex-1">
                            <div className="flex items-center gap-2 flex-wrap">
                              {engineer.identification_number && (
                                <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-blue-100/80 text-[#0453cd] font-bold border border-blue-200">
                                  {engineer.identification_number}
                                </span>
                              )}
                              <p className="font-bold text-slate-900 text-xs truncate">{engineer.name || 'Unnamed Engineer/Architect'}</p>
                              <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-blue-100/80 text-[#0453cd] font-semibold">
                                ENGINEER/ARCHITECT
                              </span>
                            </div>
                            <div className="flex items-center gap-3 text-[11px] text-slate-500 font-mono mt-0.5 truncate">
                              <span className="flex items-center gap-1 truncate">
                                <Mail className="h-3 w-3 text-slate-400 shrink-0" />
                                {engineer.email}
                              </span>
                              {engineer.company_name && (
                                <span className="flex items-center gap-1 truncate border-l border-slate-200 pl-3">
                                  <Building className="h-3 w-3 text-slate-400 shrink-0" />
                                  {engineer.company_name}
                                </span>
                              )}
                            </div>
                          </div>
                        </div>

                        <div className="flex items-center gap-3 shrink-0">
                          <span className="text-[11px] font-mono px-2 py-0.5 rounded-full bg-slate-100 border border-slate-200 text-slate-600">
                            {pCount} {pCount === 1 ? 'project' : 'projects'}
                          </span>
                          <div
                            className={`h-5 w-5 rounded-full border flex items-center justify-center ${
                              isSelected
                                ? 'bg-[#0453cd] border-[#0453cd] text-white'
                                : 'border-slate-300 bg-white'
                            }`}
                          >
                            {isSelected && <Check className="h-3 w-3 stroke-[3]" />}
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}

              {/* Step 1 Actions */}
              <div className="flex items-center justify-between pt-4 border-t border-slate-100">
                <Button variant="ghost" size="sm" onClick={onClose} className="text-slate-500 font-mono text-xs">
                  Cancel
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleProceedToStep2}
                  disabled={!selectedEngineerId}
                  className="bg-[#0453cd] hover:bg-blue-700 text-white font-mono text-xs flex items-center gap-1.5 px-4"
                >
                  <span>Next: Select Project</span>
                  <ArrowRight className="h-3.5 w-3.5" />
                </Button>
              </div>
            </div>
          )}

          {/* ─── STEP 2: Select Project ──────────────────────────────── */}
          {step === 2 && (
            <div className="space-y-4">
              {/* Selected Engineer Reminder Pill */}
              {selectedEngineer && (
                <div className="p-2.5 rounded-xl bg-blue-50/60 border border-blue-200/80 flex items-center justify-between text-xs font-mono">
                  <div className="flex items-center gap-2">
                    <span className="text-slate-500">Target Engineer/Architect:</span>
                    <strong className="text-slate-900">{selectedEngineer.name || selectedEngineer.email}</strong>
                    {selectedEngineer.company_name && (
                      <span className="text-slate-500">({selectedEngineer.company_name})</span>
                    )}
                  </div>
                  <button
                    onClick={() => setStep(1)}
                    className="text-[#0453cd] hover:underline text-[11px] font-semibold"
                  >
                    Change Engineer/Architect
                  </button>
                </div>
              )}

              {/* Mode Switcher Tabs */}
              <div className="flex items-center gap-2 border-b border-slate-200 pb-2">
                <button
                  type="button"
                  onClick={() => {
                    setProjectMode('existing');
                    setStepError(null);
                  }}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-mono font-semibold transition-all ${
                    projectMode === 'existing'
                      ? 'bg-[#0453cd] text-white shadow-xs'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  Select Existing Project ({projectsList.length})
                </button>
                <button
                  type="button"
                  onClick={() => {
                    setProjectMode('new');
                    setStepError(null);
                  }}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-mono font-semibold transition-all flex items-center gap-1.5 ${
                    projectMode === 'new'
                      ? 'bg-[#0453cd] text-white shadow-xs'
                      : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                  }`}
                >
                  <PlusCircle className="h-3.5 w-3.5" />
                  <span>New Project</span>
                </button>
              </div>

              {/* Mode A: Select Existing Project */}
              {projectMode === 'existing' && (
                <div className="space-y-3">
                  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                    <div className="relative flex-1">
                      <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                      <input
                        type="text"
                        value={projectSearch}
                        onChange={(e) => setProjectSearch(e.target.value)}
                        placeholder="Search projects by name, discipline, or ID..."
                        className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd] focus:border-[#0453cd]"
                      />
                    </div>
                    <select
                      value={statusFilter}
                      onChange={(e) => setStatusFilter(e.target.value)}
                      className="px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                    >
                      <option value="ALL">All Statuses</option>
                      <option value="DRAFT">DRAFT</option>
                      <option value="SUBMITTED">SUBMITTED</option>
                      <option value="WAITING_ASSIGNMENT">WAITING_ASSIGNMENT</option>
                      <option value="WAITING_ACCEPTANCE">WAITING_ACCEPTANCE</option>
                      <option value="IN_PROGRESS">IN_PROGRESS</option>
                      <option value="UNDER_CLIENT_REVIEW">UNDER_CLIENT_REVIEW</option>
                      <option value="COMPLETED">COMPLETED</option>
                    </select>
                  </div>

                  {filteredProjects.length === 0 ? (
                    <div className="p-10 text-center border border-dashed border-slate-200 rounded-xl">
                      <FolderKanban className="h-8 w-8 text-slate-300 mx-auto mb-2" />
                      <p className="text-xs font-bold text-slate-700">No matching projects found</p>
                      <p className="text-[11px] text-slate-400 font-mono mt-1">
                        Try clearing search terms or switch to "New Project"
                      </p>
                    </div>
                  ) : (
                    <div className="max-h-[300px] overflow-y-auto space-y-2 pr-1">
                      {filteredProjects.map((project) => {
                        const isSelected = selectedProjectId === project.id;
                        const isCurrentlyAssignedToThis = project.client_id === selectedEngineerId;

                        return (
                          <div
                            key={project.id}
                            onClick={() => {
                              setSelectedProjectId(project.id);
                              setStepError(null);
                            }}
                            className={`p-3 rounded-xl border transition-all cursor-pointer flex items-center justify-between gap-3 ${
                              isSelected
                                ? 'bg-blue-50/70 border-[#0453cd] ring-1 ring-[#0453cd] shadow-xs'
                                : 'bg-white border-slate-200 hover:border-slate-300 hover:bg-slate-50/60'
                            }`}
                          >
                            <div className="min-w-0 flex-1">
                              <div className="flex items-center gap-2">
                                <p className="font-bold text-slate-900 text-xs truncate">{project.project_name}</p>
                                <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-slate-100 border border-slate-200 text-slate-600 font-semibold">
                                  {project.drawing_type || 'CAD'}
                                </span>
                                {isCurrentlyAssignedToThis && (
                                  <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-emerald-50 border border-emerald-200 text-emerald-700 font-semibold">
                                    Currently Assigned
                                  </span>
                                )}
                              </div>
                              <div className="flex items-center gap-3 text-[10px] text-slate-400 font-mono mt-1 truncate">
                                <span>ID: {project.id}</span>
                                {project.project_area && <span>• {project.project_area} sq.ft</span>}
                                {project.project_address && <span className="truncate">• {project.project_address}</span>}
                              </div>
                            </div>

                            <div className="flex items-center gap-3 shrink-0">
                              <span
                                className={`text-[10px] font-mono px-2 py-0.5 rounded-full border font-semibold ${
                                  project.status === 'COMPLETED'
                                    ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                    : project.status === 'IN_PROGRESS'
                                    ? 'bg-blue-50 text-blue-700 border-blue-200'
                                    : 'bg-amber-50 text-amber-700 border-amber-200'
                                }`}
                              >
                                {project.status}
                              </span>
                              <div
                                className={`h-5 w-5 rounded-full border flex items-center justify-center ${
                                  isSelected
                                    ? 'bg-[#0453cd] border-[#0453cd] text-white'
                                    : 'border-slate-300 bg-white'
                                }`}
                              >
                                {isSelected && <Check className="h-3 w-3 stroke-[3]" />}
                              </div>
                            </div>
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              )}

              {/* Mode B: New Project for Engineer */}
              {projectMode === 'new' && (
                <div className="space-y-3.5 bg-slate-50/70 p-4 rounded-xl border border-slate-200">
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    <div className="sm:col-span-2">
                      <label className="block text-[11px] font-mono font-bold text-slate-700 mb-1">
                        Project Name / Title <span className="text-rose-500">*</span>
                      </label>
                      <input
                        type="text"
                        value={newProjectName}
                        onChange={(e) => setNewProjectName(e.target.value)}
                        placeholder="e.g. Skyline Tower Structural Framing"
                        className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                      />
                    </div>

                    <div>
                      <label className="block text-[11px] font-mono font-bold text-slate-700 mb-1">
                        Discipline / Drawing Type <span className="text-rose-500">*</span>
                      </label>
                      <select
                        value={newDrawingType}
                        onChange={(e) => setNewDrawingType(e.target.value)}
                        className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                      >
                        {DRAWING_DISCIPLINES.map((d) => (
                          <option key={d.id} value={d.id}>
                            {d.label}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className="block text-[11px] font-mono font-bold text-slate-700 mb-1">
                        Estimated Area (sq. ft)
                      </label>
                      <input
                        type="number"
                        value={newProjectArea}
                        onChange={(e) => setNewProjectArea(e.target.value)}
                        placeholder="1500"
                        className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                      />
                    </div>

                    <div className="sm:col-span-2">
                      <label className="block text-[11px] font-mono font-bold text-slate-700 mb-1">
                        Project Location / Address
                      </label>
                      <input
                        type="text"
                        value={newProjectAddress}
                        onChange={(e) => setNewProjectAddress(e.target.value)}
                        placeholder="e.g. Plot 42, Industrial Development Zone"
                        className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                      />
                    </div>

                    <div className="sm:col-span-2">
                      <label className="block text-[11px] font-mono font-bold text-slate-700 mb-1">
                        Special Commissioning Instructions
                      </label>
                      <textarea
                        rows={2}
                        value={newInstructions}
                        onChange={(e) => setNewInstructions(e.target.value)}
                        placeholder="Optional notes or engineering specifications..."
                        className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                      />
                    </div>
                  </div>
                </div>
              )}

              {/* Step 2 Actions */}
              <div className="flex items-center justify-between pt-4 border-t border-slate-100">
                <Button
                  variant="outline"
                  size="sm"
                  onClick={() => {
                    setStep(1);
                    setStepError(null);
                  }}
                  className="font-mono text-xs flex items-center gap-1.5"
                >
                  <ArrowLeft className="h-3.5 w-3.5" />
                  <span>Back to Engineers/Architects</span>
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  onClick={handleProceedToStep3}
                  disabled={projectMode === 'existing' ? !selectedProjectId : !newProjectName.trim()}
                  className="bg-[#0453cd] hover:bg-blue-700 text-white font-mono text-xs flex items-center gap-1.5 px-4"
                >
                  <span>Next: Review Details</span>
                  <ArrowRight className="h-3.5 w-3.5" />
                </Button>
              </div>
            </div>
          )}

          {/* ─── STEP 3: Review & Confirm ────────────────────────────── */}
          {step === 3 && selectedEngineer && (
            <div className="space-y-4">
              <p className="text-xs text-slate-500 font-mono">
                Review the engineer/architect and project assignment details before confirming.
              </p>

              {/* Review Cards Grid */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3.5">
                {/* Engineer Card */}
                <Card technicalCorners className="p-4 bg-slate-50/80 border-slate-200 space-y-2.5">
                  <div className="flex items-center justify-between border-b border-slate-200/70 pb-2">
                    <span className="text-[10px] font-mono font-bold uppercase tracking-wider text-slate-500">
                      Assigned Engineer/Architect
                    </span>
                    <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-blue-100 text-[#0453cd] font-bold">
                      ENGINEER/ARCHITECT
                    </span>
                  </div>

                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-sm shrink-0">
                      {(selectedEngineer.name || 'E').charAt(0).toUpperCase()}
                    </div>
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        {selectedEngineer.identification_number && (
                          <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-blue-100 text-[#0453cd] font-bold border border-blue-200">
                            {selectedEngineer.identification_number}
                          </span>
                        )}
                        <p className="font-bold text-slate-900 text-xs truncate">
                          {selectedEngineer.name || 'Unnamed Engineer/Architect'}
                        </p>
                      </div>
                      <p className="text-[11px] font-mono text-slate-500 truncate mt-0.5">
                        {selectedEngineer.email}
                      </p>
                    </div>
                  </div>

                  <div className="text-[11px] font-mono text-slate-600 space-y-1 pt-1 border-t border-slate-200/50">
                    {selectedEngineer.company_name && (
                      <p className="truncate flex items-center gap-1.5">
                        <Building className="h-3 w-3 text-slate-400 shrink-0" />
                        <span>{selectedEngineer.company_name}</span>
                      </p>
                    )}
                    <p className="text-slate-400 text-[10px]">UID: {selectedEngineer.id}</p>
                  </div>
                </Card>

                {/* Project Card */}
                <Card technicalCorners className="p-4 bg-slate-50/80 border-slate-200 space-y-2.5">
                  <div className="flex items-center justify-between border-b border-slate-200/70 pb-2">
                    <span className="text-[10px] font-mono font-bold uppercase tracking-wider text-slate-500">
                      Assigned Project
                    </span>
                    <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-slate-200 text-slate-700 font-bold">
                      {projectMode === 'existing' ? 'EXISTING' : 'NEW CREATION'}
                    </span>
                  </div>

                  {projectMode === 'existing' && selectedProject ? (
                    <div>
                      <p className="font-bold text-slate-900 text-xs truncate">{selectedProject.project_name}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-blue-50 border border-blue-200 text-[#0453cd] font-semibold">
                          {selectedProject.drawing_type || 'CAD'}
                        </span>
                        <span className="text-[10px] font-mono text-slate-500">
                          {selectedProject.status}
                        </span>
                      </div>
                      <div className="text-[11px] font-mono text-slate-500 space-y-0.5 mt-2 pt-1 border-t border-slate-200/50">
                        <p className="truncate">ID: {selectedProject.id}</p>
                        {selectedProject.project_address && (
                          <p className="truncate">{selectedProject.project_address}</p>
                        )}
                      </div>
                    </div>
                  ) : (
                    <div>
                      <p className="font-bold text-slate-900 text-xs truncate">{newProjectName}</p>
                      <div className="flex items-center gap-2 mt-1">
                        <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-blue-50 border border-blue-200 text-[#0453cd] font-semibold">
                          {newDrawingType}
                        </span>
                        <span className="text-[10px] font-mono text-slate-500">
                          {newProjectArea} sq.ft
                        </span>
                      </div>
                      <div className="text-[11px] font-mono text-slate-500 space-y-0.5 mt-2 pt-1 border-t border-slate-200/50">
                        <p className="truncate">{newProjectAddress || 'Client Site Scope'}</p>
                        {newInstructions && <p className="truncate italic">"{newInstructions}"</p>}
                      </div>
                    </div>
                  )}
                </Card>
              </div>

              {/* Scope & Isolation Notice */}
              <div className="p-3.5 rounded-xl bg-blue-50/70 border border-blue-200/90 text-xs font-mono space-y-1.5">
                <div className="flex items-center gap-2 text-[#0453cd] font-bold">
                  <UserCheck className="h-4 w-4 shrink-0" />
                  <span>Engineer/Architect Assignment Scope & Verification</span>
                </div>
                <ul className="text-[11px] text-slate-600 space-y-1 list-disc pl-4">
                  <li>Project ownership is persisted with Engineer/Architect UID association (<code className="text-slate-800">client_id</code>).</li>
                  <li>The assigned project will immediately appear in this Engineer/Architect's active submission queue.</li>
                  <li>An administrative activity log and in-app notification will be issued.</li>
                  <li>Student portals, apprentice curriculums, and student records remain strictly untouched.</li>
                </ul>
              </div>

              {/* Step 3 Actions */}
              <div className="flex items-center justify-between pt-4 border-t border-slate-100">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={isSubmitting}
                  onClick={() => {
                    setStep(2);
                    setErrorMessage(null);
                  }}
                  className="font-mono text-xs flex items-center gap-1.5"
                >
                  <ArrowLeft className="h-3.5 w-3.5" />
                  <span>Back to Project Selection</span>
                </Button>
                <Button
                  variant="primary"
                  size="sm"
                  disabled={isSubmitting}
                  onClick={handleConfirmAssignment}
                  className="bg-[#0453cd] hover:bg-blue-700 text-white font-mono text-xs flex items-center gap-2 px-5 py-2 shadow-xs"
                >
                  {isSubmitting ? (
                    <>
                      <RefreshCw className="h-3.5 w-3.5 animate-spin" />
                      <span>Confirming Assignment...</span>
                    </>
                  ) : (
                    <>
                      <CheckCircle2 className="h-3.5 w-3.5" />
                      <span>Confirm Assignment</span>
                    </>
                  )}
                </Button>
              </div>
            </div>
          )}
        </div>
      )}
    </Modal>
  );
}


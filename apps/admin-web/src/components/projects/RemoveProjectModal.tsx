'use client';

import React, { useState } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { Project } from '@/lib/types';
import { AlertCircle, Trash2, ShieldAlert } from 'lucide-react';

interface RemoveProjectModalProps {
  isOpen: boolean;
  onClose: () => void;
  project: Project | null;
  onSuccess: (removedProjectId: string) => void;
}

export function RemoveProjectModal({
  isOpen,
  onClose,
  project,
  onSuccess,
}: RemoveProjectModalProps) {
  const [loading, setLoading] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  if (!project) return null;

  const handleConfirmRemove = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);

    try {
      await adminApi.removeProject(project.id);
      onSuccess(project.id);
      onClose();
    } catch (err: any) {
      setError(err.message || 'Failed to remove project. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Remove Project from Database"
      description={`You are about to permanently remove project "${project.project_name || 'Untitled'}" (ID: ${project.id}) from the database.`}
    >
      <form onSubmit={handleConfirmRemove} className="space-y-4">
        {error && (
          <div className="flex items-center gap-2 p-3 text-xs text-rose-700 bg-rose-50 border border-rose-200 rounded-xl">
            <AlertCircle className="h-4 w-4 shrink-0 text-rose-600" />
            <span>{error}</span>
          </div>
        )}

        <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-xl text-xs text-rose-800 space-y-2">
          <div className="flex items-center gap-2 font-semibold font-mono text-rose-900">
            <ShieldAlert className="h-4 w-4 text-rose-600 shrink-0" />
            <span>Permanent Removal Warning</span>
          </div>
          <p className="leading-relaxed">
            This will permanently remove project record <span className="font-mono font-bold">{project.id}</span> and its associated assignments, deliverables, and revision history. Other projects will remain untouched.
          </p>
        </div>

        <div className="bg-slate-50 border border-slate-200 rounded-xl p-3 text-xs space-y-1 font-mono">
          <div className="flex justify-between text-slate-600">
            <span>Project Name:</span>
            <span className="font-semibold text-slate-900">{project.project_name || 'Untitled'}</span>
          </div>
          <div className="flex justify-between text-slate-600">
            <span>Discipline / Type:</span>
            <span className="text-slate-800">{project.drawing_type || 'Architectural'}</span>
          </div>
          <div className="flex justify-between text-slate-600">
            <span>Lifecycle Status:</span>
            <span className="font-semibold text-slate-800">{project.status}</span>
          </div>
          <div className="flex justify-between text-slate-600">
            <span>Target Project ID:</span>
            <span className="font-bold text-rose-600">{project.id}</span>
          </div>
        </div>

        <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
          <Button
            variant="ghost"
            size="sm"
            type="button"
            onClick={onClose}
            disabled={loading}
          >
            Cancel
          </Button>
          <Button
            variant="danger"
            size="sm"
            type="submit"
            loading={loading}
            icon={<Trash2 className="h-4 w-4" />}
          >
            Permanently Remove Project
          </Button>
        </div>
      </form>
    </Modal>
  );
}

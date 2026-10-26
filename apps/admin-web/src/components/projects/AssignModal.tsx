'use client';

import React, { useState, useEffect } from 'react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { User } from '@/lib/types';
import { UserCheck, AlertCircle } from 'lucide-react';

interface AssignModalProps {
  isOpen: boolean;
  onClose: () => void;
  projectId: string;
  projectName: string;
  onSuccess: () => void;
  isReassign?: boolean;
  isTrainingProject?: boolean;
}

export function AssignModal({
  isOpen,
  onClose,
  projectId,
  projectName,
  onSuccess,
  isReassign = false,
  isTrainingProject = false,
}: AssignModalProps) {
  const [candidates, setCandidates] = useState<User[]>([]);
  const [selectedId, setSelectedId] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [fetchingList, setFetchingList] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const roleLabel = isTrainingProject ? 'Student Apprentice' : 'Draughtsman';
  const roleType = isTrainingProject ? 'STUDENT' : 'DRAUGHTSMAN';

  useEffect(() => {
    if (isOpen) {
      setFetchingList(true);
      setError(null);
      setSelectedId('');
      adminApi
        .getUsers(roleType)
        .then((list) => {
          setCandidates(list || []);
        })
        .catch((err) => {
          console.error(err);
          setError(`Failed to load registered ${roleLabel.toLowerCase()}s list.`);
        })
        .finally(() => setFetchingList(false));
    }
  }, [isOpen, roleType, roleLabel]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedId) {
      setError(`Please select a ${roleLabel.toLowerCase()} to assign.`);
      return;
    }

    setLoading(true);
    setError(null);
    try {
      if (isReassign) {
        await adminApi.reassignProject(projectId, selectedId);
      } else {
        await adminApi.assignProject(projectId, selectedId);
      }
      onSuccess();
      onClose();
    } catch (err: any) {
      setError(err.message || `Failed to assign ${roleLabel.toLowerCase()}`);
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isReassign ? `Reassign ${roleLabel}` : `Assign ${roleLabel}`}
      description={`Project: "${projectName}" (ID: ${projectId.substring(0, 8)}...)`}
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {error && (
          <div className="flex items-center gap-2 p-3 text-xs text-rose-400 bg-rose-500/10 border border-rose-500/20 rounded-lg">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <div>
          <label className="block text-xs font-mono font-semibold text-slate-700 uppercase tracking-wider mb-2">
            Select {roleLabel}
          </label>

          {fetchingList ? (
            <div className="flex items-center justify-center p-8 bg-slate-50 border border-slate-200 rounded-xl">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent" />
            </div>
          ) : candidates.length === 0 ? (
            <div className="p-4 text-center text-sm text-slate-500 bg-slate-50 border border-slate-200 rounded-xl font-mono">
              No registered {roleLabel.toLowerCase()}s found in the studio database.
            </div>
          ) : (
            <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
              {candidates.map((d) => (
                <label
                  key={d.id}
                  className={`flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all ${
                    selectedId === d.id
                      ? 'bg-blue-50/80 border-[#0453cd] text-[#0453cd]'
                      : 'bg-slate-50 border-slate-200 hover:border-slate-300 text-slate-700'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <input
                      type="radio"
                      name="assignee"
                      value={d.id}
                      checked={selectedId === d.id}
                      onChange={(e) => setSelectedId(e.target.value)}
                      className="text-[#0453cd] focus:ring-[#0453cd] border-slate-300"
                    />
                    <div>
                      <p className="text-sm font-semibold text-slate-900">{d.name}</p>
                      <p className="text-xs text-slate-500 font-mono">{d.email}</p>
                    </div>
                  </div>
                  {d.college_name && (
                    <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-white text-slate-600 border border-slate-200">
                      {d.college_name}
                    </span>
                  )}
                </label>
              ))}
            </div>
          )}
        </div>

        <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-100">
          <Button variant="ghost" size="sm" type="button" onClick={onClose} disabled={loading}>
            Cancel
          </Button>
          <Button
            variant="primary"
            size="sm"
            type="submit"
            loading={loading}
            disabled={!selectedId || fetchingList}
            icon={<UserCheck className="h-4 w-4" />}
          >
            {isReassign ? 'Confirm Reassignment' : isTrainingProject ? 'Assign Practical Project' : 'Assign Project'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

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
}

export function AssignModal({
  isOpen,
  onClose,
  projectId,
  projectName,
  onSuccess,
  isReassign = false,
}: AssignModalProps) {
  const [draughtsmen, setDraughtsmen] = useState<User[]>([]);
  const [selectedId, setSelectedId] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(false);
  const [fetchingList, setFetchingList] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (isOpen) {
      setFetchingList(true);
      setError(null);
      setSelectedId('');
      adminApi
        .getUsers('DRAUGHTSMAN')
        .then((list) => {
          setDraughtsmen(list || []);
        })
        .catch((err) => {
          console.error(err);
          setError('Failed to load registered draughtsmen list.');
        })
        .finally(() => setFetchingList(false));
    }
  }, [isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedId) {
      setError('Please select a draughtsman to assign.');
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
      setError(err.message || 'Failed to assign draughtsman');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={isReassign ? 'Reassign Draughtsman' : 'Assign Draughtsman'}
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
          <label className="block text-xs font-semibold text-slate-300 uppercase tracking-wider mb-2">
            Select Draughtsman
          </label>

          {fetchingList ? (
            <div className="flex items-center justify-center p-8 bg-slate-900 border border-slate-800 rounded-xl">
              <div className="h-6 w-6 animate-spin rounded-full border-2 border-blue-500 border-t-transparent" />
            </div>
          ) : draughtsmen.length === 0 ? (
            <div className="p-4 text-center text-sm text-slate-400 bg-slate-900 border border-slate-800 rounded-xl">
              No registered draughtsmen found in the studio database.
            </div>
          ) : (
            <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
              {draughtsmen.map((d) => (
                <label
                  key={d.id}
                  className={`flex items-center justify-between p-3 rounded-xl border cursor-pointer transition-all ${
                    selectedId === d.id
                      ? 'bg-blue-600/10 border-blue-500 text-blue-200'
                      : 'bg-slate-900/60 border-slate-800 hover:border-slate-700 text-slate-300'
                  }`}
                >
                  <div className="flex items-center gap-3">
                    <input
                      type="radio"
                      name="draughtsman"
                      value={d.id}
                      checked={selectedId === d.id}
                      onChange={(e) => setSelectedId(e.target.value)}
                      className="text-blue-600 focus:ring-blue-500 bg-slate-800 border-slate-700"
                    />
                    <div>
                      <p className="text-sm font-semibold text-slate-100">{d.name}</p>
                      <p className="text-xs text-slate-400">{d.email}</p>
                    </div>
                  </div>
                  {d.college_name && (
                    <span className="text-[10px] px-2 py-0.5 rounded bg-slate-800 text-slate-400 border border-slate-700">
                      {d.college_name}
                    </span>
                  )}
                </label>
              ))}
            </div>
          )}
        </div>

        <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
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
            {isReassign ? 'Confirm Reassignment' : 'Assign Project'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}

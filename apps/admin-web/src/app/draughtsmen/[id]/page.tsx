'use client';

import React, { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { DraughtsmanProfileView } from '@/components/draughtsmen/DraughtsmanProfileView';
import { adminApi } from '@/lib/api';
import { User } from '@/lib/types';
import { ArrowLeft, AlertCircle, RefreshCw, ShieldAlert, Lock } from 'lucide-react';
import { Button } from '@/components/ui/Button';

export default function DraughtsmanDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id: rawId } = use(params);
  const id = decodeURIComponent(rawId);
  const router = useRouter();

  const [draughtsman, setDraughtsman] = useState<User | null>(null);
  const [assignments, setAssignments] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);

  const fetchDraughtsmanData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);
    setErrorStatus(null);

    try {
      const details = await adminApi.getUserDetails(id);
      if (!details || !details.user) {
        const notFoundErr: any = new Error(`Draughtsman profile not found for UID ${id}`);
        notFoundErr.status = 404;
        throw notFoundErr;
      }
      setDraughtsman(details.user);
      setAssignments(details.projects || []);
    } catch (err: any) {
      console.error('Failed to load draughtsman profile:', err);
      const status = err.status || (err.message?.includes('404') ? 404 : err.message?.includes('401') ? 401 : err.message?.includes('403') ? 403 : null);
      setErrorStatus(status);
      setError(err.message || 'Failed to retrieve draughtsman workspace');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    if (id) {
      fetchDraughtsmanData();
    }
  }, [id]);

  const isNotFound = errorStatus === 404 || error?.toLowerCase().includes('not found');
  const isAuthError = errorStatus === 401 || errorStatus === 403 || error?.toLowerCase().includes('unauthorized') || error?.toLowerCase().includes('forbidden');

  return (
    <AdminShell
      title={draughtsman ? `Draughtsman Workspace: ${draughtsman.name || 'Unnamed'}` : 'Draughtsman Profile'}
      subtitle="Capacity metrics, active project assignments, and technical drafting work history"
      onRefresh={() => fetchDraughtsmanData(true)}
      isRefreshing={refreshing}
    >
      {/* Back Navigation Bar */}
      <div className="mb-6 flex items-center justify-between">
        <Link
          href="/draughtsmen"
          className="inline-flex items-center gap-2 text-xs font-mono font-medium text-slate-600 hover:text-[#0453cd] transition-colors bg-white px-3 py-1.5 rounded-lg border border-slate-200 shadow-2xs hover:border-slate-300"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          <span>Back to Draughtsman Talent Pool</span>
        </Link>
        {draughtsman && (
          <span className="text-[11px] font-mono text-slate-400">
            Role: <strong className="text-slate-600">{draughtsman.role}</strong>
          </span>
        )}
      </div>

      {error ? (
        <div className="p-8 rounded-xl bg-white border border-slate-200 shadow-xs text-center max-w-xl mx-auto space-y-4">
          <div className={`h-12 w-12 rounded-full flex items-center justify-center mx-auto ${
            isAuthError ? 'bg-amber-50 text-amber-600' : isNotFound ? 'bg-slate-100 text-slate-600' : 'bg-rose-50 text-rose-600'
          }`}>
            {isAuthError ? <Lock className="h-6 w-6" /> : isNotFound ? <ShieldAlert className="h-6 w-6" /> : <AlertCircle className="h-6 w-6" />}
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900">
              {isAuthError ? 'Administrative Access Required' : isNotFound ? 'Draughtsman Profile Not Found' : 'Draughtsman Workspace Temporarily Unavailable'}
            </h3>
            <p className="text-xs text-slate-500 mt-1 font-mono max-w-md mx-auto">
              {isNotFound
                ? `No draughtsman record exists matching identifier "${id}". The record may have been deleted or the link is invalid.`
                : error}
            </p>
          </div>
          <div className="flex items-center justify-center gap-3 pt-2">
            <Button variant="outline" size="sm" onClick={() => router.push('/draughtsmen')}>
              Return to Talent Pool
            </Button>
            {!isNotFound && (
              <Button size="sm" onClick={() => fetchDraughtsmanData(true)}>
                <RefreshCw className="h-3.5 w-3.5 mr-1.5" /> Try Again
              </Button>
            )}
          </div>
        </div>
      ) : loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500 mt-3 font-mono">Loading draughtsman workspace…</p>
        </div>
      ) : draughtsman ? (
        <DraughtsmanProfileView
          draughtsman={draughtsman}
          assignments={assignments}
          loading={loading}
          isStandalone={true}
        />
      ) : null}
    </AdminShell>
  );
}

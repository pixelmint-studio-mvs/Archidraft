'use client';

import React, { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { EngineerProfileView } from '@/components/engineers/EngineerProfileView';
import { adminApi } from '@/lib/api';
import { User, Project } from '@/lib/types';
import { ArrowLeft, AlertCircle, RefreshCw } from 'lucide-react';
import { Button } from '@/components/ui/Button';

export default function EngineerDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id } = use(params);
  const router = useRouter();

  const [engineer, setEngineer] = useState<User | null>(null);
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const fetchEngineerData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const details = await adminApi.getUserDetails(id);
      if (!details || !details.user) {
        throw new Error('Engineer profile not found');
      }
      setEngineer(details.user);
      setProjects(details.projects || []);
    } catch (err: any) {
      console.error('Failed to load engineer dossier:', err);
      setError(err.message || 'Failed to retrieve engineer information');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    if (id) {
      fetchEngineerData();
    }
  }, [id]);

  return (
    <AdminShell
      title={engineer ? `Engineer Dossier: ${engineer.name || 'Unnamed'}` : 'Engineer Profile'}
      subtitle="Comprehensive submission history, active CAD drafting queues, and performance metrics"
      onRefresh={() => fetchEngineerData(true)}
      isRefreshing={refreshing}
    >
      {/* Back Navigation Bar */}
      <div className="mb-6 flex items-center justify-between">
        <Link
          href="/engineers"
          className="inline-flex items-center gap-2 text-xs font-mono font-medium text-slate-600 hover:text-[#0453cd] transition-colors bg-white px-3 py-1.5 rounded-lg border border-slate-200 shadow-2xs hover:border-slate-300"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          <span>Back to Engineer Directory</span>
        </Link>
        {engineer && (
          <span className="text-[11px] font-mono text-slate-400">
            Role: <strong className="text-slate-600">CLIENT (Engineer)</strong>
          </span>
        )}
      </div>

      {error ? (
        <div className="p-8 rounded-xl bg-white border border-rose-200 shadow-xs text-center max-w-xl mx-auto space-y-4">
          <div className="h-12 w-12 rounded-full bg-rose-50 text-rose-600 flex items-center justify-center mx-auto">
            <AlertCircle className="h-6 w-6" />
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900">Engineer Profile Unavailable</h3>
            <p className="text-xs text-slate-500 mt-1 font-mono">{error}</p>
          </div>
          <div className="flex items-center justify-center gap-3 pt-2">
            <Button variant="outline" size="sm" onClick={() => router.push('/engineers')}>
              Return to Directory
            </Button>
            <Button size="sm" onClick={() => fetchEngineerData(true)}>
              <RefreshCw className="h-3.5 w-3.5 mr-1.5" /> Try Again
            </Button>
          </div>
        </div>
      ) : loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500 mt-3 font-mono">Loading engineer dossier…</p>
        </div>
      ) : engineer ? (
        <EngineerProfileView
          engineer={engineer}
          projects={projects}
          loading={loading}
          isStandalone={true}
        />
      ) : null}
    </AdminShell>
  );
}

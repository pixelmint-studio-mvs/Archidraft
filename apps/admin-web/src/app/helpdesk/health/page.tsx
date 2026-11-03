'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { adminApi } from '@/lib/api';
import { HelpdeskHealthReport } from '@/lib/types';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import {
  Activity,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  RefreshCw,
  Server,
  Database,
  HardDrive,
  Mail,
  ShieldCheck,
  Clock,
  ArrowLeft,
} from 'lucide-react';

export default function SystemHealthPage() {
  const [report, setReport] = useState<HelpdeskHealthReport | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [runningDiagnostics, setRunningDiagnostics] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const fetchHealth = async (isManual = false) => {
    if (isManual) setRunningDiagnostics(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getHelpdeskHealth();
      setReport(data);
    } catch (err: any) {
      console.error('Failed to run diagnostics:', err);
      setError(err?.message || 'Failed to communicate with diagnostic service.');
    } finally {
      setLoading(false);
      setRunningDiagnostics(false);
    }
  };

  useEffect(() => {
    fetchHealth();
  }, []);

  const getServiceIcon = (name: string) => {
    switch (name) {
      case 'WORKER_API':
        return <Server className="h-5 w-5 text-[#0453cd]" />;
      case 'D1_DATABASE':
        return <Database className="h-5 w-5 text-indigo-600" />;
      case 'R2_STORAGE':
        return <HardDrive className="h-5 w-5 text-purple-600" />;
      case 'EMAIL_DISPATCHER':
        return <Mail className="h-5 w-5 text-amber-600" />;
      default:
        return <Activity className="h-5 w-5 text-slate-600" />;
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'OPERATIONAL':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
            <span>OPERATIONAL</span>
          </span>
        );
      case 'DEGRADED':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
            <AlertTriangle className="h-3.5 w-3.5 text-amber-600" />
            <span>DEGRADED</span>
          </span>
        );
      case 'DOWN':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-200">
            <XCircle className="h-3.5 w-3.5 text-rose-600" />
            <span>DOWN</span>
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-600">
            <span>UNKNOWN</span>
          </span>
        );
    }
  };

  return (
    <AdminShell
      title="System Health & Diagnostics"
      subtitle="Real-time telemetry and availability verification across PixelMint Studio MVS core infrastructure"
      backHref="/helpdesk"
      backLabel="Back to Help Desk"
      onRefresh={() => fetchHealth(true)}
      isRefreshing={runningDiagnostics}
    >
      {/* ── Top Status Banner ── */}
      <Card className="p-6 bg-white border-slate-200 mb-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div
              className={`h-12 w-12 rounded-2xl flex items-center justify-center ${
                report?.status === 'OPERATIONAL'
                  ? 'bg-emerald-50 text-emerald-600 border border-emerald-200'
                  : report?.status === 'DEGRADED'
                  ? 'bg-amber-50 text-amber-600 border border-amber-200'
                  : 'bg-rose-50 text-rose-600 border border-rose-200'
              }`}
            >
              <Activity className="h-6 w-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-base font-bold text-slate-900">Infrastructure Operational Status</h2>
                {report && getStatusBadge(report.status)}
              </div>
              <p className="text-xs text-slate-500 mt-1">
                Last verified: {report?.timestamp ? new Date(report.timestamp).toLocaleString() : '—'}
              </p>
            </div>
          </div>

          <Button
            variant="primary"
            onClick={() => fetchHealth(true)}
            disabled={runningDiagnostics}
            className="flex items-center gap-2 bg-[#0453cd] hover:bg-blue-700 text-white font-medium text-xs px-4 py-2"
          >
            <RefreshCw className={`h-4 w-4 ${runningDiagnostics ? 'animate-spin' : ''}`} />
            <span>{runningDiagnostics ? 'Testing...' : 'Run Diagnostics'}</span>
          </Button>
        </div>
      </Card>

      {/* ── Services Grid ── */}
      {loading ? (
        <div className="py-20 flex flex-col items-center justify-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-3 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500">Checking system health...</p>
        </div>
      ) : error ? (
        <Card className="p-8 text-center bg-white border-slate-200 space-y-3">
          <AlertTriangle className="h-8 w-8 text-rose-500 mx-auto" />
          <p className="text-sm font-semibold text-slate-900">{error}</p>
          <Button variant="outline" size="sm" onClick={() => fetchHealth(true)}>
            Retry Diagnostics
          </Button>
        </Card>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {report &&
            Object.entries(report.checks).map(([name, check]) => (
              <Card key={name} className="p-5 bg-white border-slate-200">
                <div className="flex items-start justify-between mb-3">
                  <div className="flex items-center gap-3">
                    <div className="h-10 w-10 rounded-xl bg-slate-50 border border-slate-200 flex items-center justify-center">
                      {getServiceIcon(name)}
                    </div>
                    <div>
                      <h3 className="text-sm font-semibold text-slate-900">
                        {name.replace(/_/g, ' ')}
                      </h3>
                      <span className="text-[11px] text-slate-400">
                        Response Latency: <strong>{check.latencyMs}ms</strong>
                      </span>
                    </div>
                  </div>
                  <div>{getStatusBadge(check.status)}</div>
                </div>

                <div className="p-3 bg-slate-50 rounded-xl border border-slate-100 text-xs text-slate-600">
                  {check.details || 'Service operational with zero active anomalies.'}
                </div>
              </Card>
            ))}
        </div>
      )}
    </AdminShell>
  );
}


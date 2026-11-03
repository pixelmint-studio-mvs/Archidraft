'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { adminApi } from '@/lib/api';
import { HelpdeskEmailLog } from '@/lib/types';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import {
  Mail,
  CheckCircle2,
  AlertTriangle,
  RotateCcw,
  Clock,
  ArrowLeft,
  X,
  Send,
} from 'lucide-react';

export default function EmailLogsPage() {
  const [logs, setLogs] = useState<HelpdeskEmailLog[]>([]);
  const [total, setTotal] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [statusFilter, setStatusFilter] = useState<string>('ALL');

  // Friendly inline feedback state (replaces jarring browser alerts)
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);
  const [retryingLogId, setRetryingLogId] = useState<string | null>(null);

  const loadLogs = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);

    try {
      const res = await adminApi.getHelpdeskEmailLogs({
        limit: 50,
        status: statusFilter === 'ALL' ? undefined : statusFilter,
      });
      setLogs(res.logs || []);
      setTotal(res.total || 0);
    } catch (err: any) {
      console.error('Failed to load email logs:', err);
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadLogs();
  }, [statusFilter]);

  const handleRetry = async (logId: string) => {
    setRetryingLogId(logId);
    setFeedback(null);

    try {
      const res = await adminApi.retryHelpdeskEmail(logId);
      if (res.success) {
        setFeedback({
          type: 'success',
          message: 'Notification email successfully delivered to recipient!',
        });
        await loadLogs(true);
      } else {
        setFeedback({
          type: 'error',
          message: res.error || `Email dispatch failed (${res.status || 'Error'}). Please verify your Resend key in Settings.`,
        });
      }
    } catch (err: any) {
      setFeedback({
        type: 'error',
        message: err?.message || 'Failed to retry email dispatch. Network error.',
      });
    } finally {
      setRetryingLogId(null);
    }
  };

  const getStatusBadge = (status: string) => {
    switch (status) {
      case 'SENT':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="h-3.5 w-3.5 text-emerald-600" />
            <span>Delivered</span>
          </span>
        );
      case 'SUPPRESSED_DUPLICATE':
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium bg-slate-100 text-slate-600 border border-slate-200">
            <Clock className="h-3 w-3 text-slate-500" />
            <span>Suppressed (15m window)</span>
          </span>
        );
      case 'FAILED':
      default:
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-50 text-rose-700 border border-rose-200">
            <AlertTriangle className="h-3.5 w-3.5 text-rose-600" />
            <span>Failed</span>
          </span>
        );
    }
  };

  return (
    <AdminShell
      title="Email Notification History"
      subtitle="Delivery ledger of automatic incident alerts dispatched to pixelmintstudiomvs@gmail.com"
      backHref="/helpdesk"
      backLabel="Back to Help Desk"
      onRefresh={() => loadLogs(true)}
      isRefreshing={refreshing}
    >
      {/* ── Status Feedback Banner ── */}
      {feedback && (
        <div
          className={`mb-4 p-4 rounded-2xl border text-xs flex items-start justify-between gap-3 shadow-xs animate-in fade-in ${
            feedback.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
              : 'bg-rose-50 border-rose-200 text-rose-800'
          }`}
        >
          <div className="flex items-center gap-2">
            {feedback.type === 'success' ? (
              <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
            ) : (
              <AlertTriangle className="h-4 w-4 shrink-0 text-rose-600" />
            )}
            <span className="font-semibold">{feedback.message}</span>
          </div>
          <button
            onClick={() => setFeedback(null)}
            className="text-slate-400 hover:text-slate-600 p-1"
          >
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* ── Filter Toolbar ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6 bg-white p-3 rounded-2xl border border-slate-200 shadow-xs">
        <div className="flex items-center gap-2">
          <Mail className="h-4 w-4 text-[#0453cd]" />
          <span className="text-xs font-semibold text-slate-800">
            Destination: <span className="text-[#0453cd] font-mono">pixelmintstudiomvs@gmail.com</span>
          </span>
        </div>

        <div className="flex items-center gap-2">
          <select
            value={statusFilter}
            onChange={(e) => setStatusFilter(e.target.value)}
            className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-700 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white"
          >
            <option value="ALL">All Delivery Statuses</option>
            <option value="SENT">Delivered Only</option>
            <option value="FAILED">Failed Only</option>
            <option value="SUPPRESSED_DUPLICATE">Suppressed Duplicates</option>
          </select>
        </div>
      </div>

      <Card className="overflow-hidden bg-white border-slate-200 shadow-xs">
        {loading ? (
          <div className="py-20 flex flex-col items-center justify-center gap-3">
            <div className="h-8 w-8 animate-spin rounded-full border-3 border-[#0453cd] border-t-transparent" />
            <p className="text-xs text-slate-500 font-medium">Retrieving notification ledger...</p>
          </div>
        ) : logs.length === 0 ? (
          <div className="py-20 text-center space-y-2">
            <Mail className="h-10 w-10 text-slate-300 mx-auto" />
            <p className="text-sm font-semibold text-slate-700">No email notification logs recorded yet.</p>
            <p className="text-xs text-slate-400">Emails will appear here once incident reports trigger notification alerts.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50/80 border-b border-slate-200 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  <th className="py-3 px-4">Ticket</th>
                  <th className="py-3 px-4">Subject & Delivery Info</th>
                  <th className="py-3 px-3">Severity</th>
                  <th className="py-3 px-3">Status</th>
                  <th className="py-3 px-3">Provider</th>
                  <th className="py-3 px-4">Time</th>
                  <th className="py-3 px-4 text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {logs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-50/80 transition-colors">
                    <td className="py-3.5 px-4 font-mono font-bold text-[#0453cd] whitespace-nowrap">
                      {log.ticket_id ? (
                        <Link href={`/helpdesk/tickets/${log.ticket_id}`} className="hover:underline">
                          {log.ticket_id}
                        </Link>
                      ) : (
                        <span className="text-slate-400 font-normal">Diagnostic Test</span>
                      )}
                    </td>

                    <td className="py-3.5 px-4 max-w-md">
                      <div className="font-semibold text-slate-900 truncate text-sm">{log.subject}</div>
                      {log.error_message && (
                        <div className="text-xs text-rose-600 truncate mt-0.5">
                          {log.error_message}
                        </div>
                      )}
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">
                      <span className="px-2 py-0.5 rounded text-xs font-semibold bg-slate-100 text-slate-700">
                        {log.severity}
                      </span>
                    </td>

                    <td className="py-3.5 px-3 whitespace-nowrap">{getStatusBadge(log.status)}</td>

                    <td className="py-3.5 px-3 whitespace-nowrap text-xs text-slate-600 font-medium">
                      {log.provider || 'DEFAULT'}
                    </td>

                    <td className="py-3.5 px-4 whitespace-nowrap text-xs text-slate-500">
                      {new Date(log.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </td>

                    <td className="py-3.5 px-4 whitespace-nowrap text-right">
                      {log.status === 'FAILED' ? (
                        <Button
                          variant="outline"
                          size="sm"
                          disabled={retryingLogId === log.id}
                          onClick={() => handleRetry(log.id)}
                          className="h-7 px-3 text-xs font-semibold hover:border-blue-300 hover:text-[#0453cd]"
                        >
                          <RotateCcw className={`h-3 w-3 mr-1 ${retryingLogId === log.id ? 'animate-spin' : ''}`} />
                          <span>{retryingLogId === log.id ? 'Sending...' : 'Retry'}</span>
                        </Button>
                      ) : (
                        <span className="text-slate-400">—</span>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="px-4 py-3 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
          <span>
            Total recorded delivery attempts: <strong className="text-slate-800">{total}</strong>
          </span>
          <span className="text-slate-400">PixelMint Notification Queue</span>
        </div>
      </Card>
    </AdminShell>
  );
}

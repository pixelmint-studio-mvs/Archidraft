'use client';

import React, { useState, useEffect, useRef, useMemo, useCallback } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { formatRelativeTime, formatTime } from '@/lib/dateUtils';
import { ActivityLog } from '@/lib/types';
import {
  Search,
  Activity,
  ExternalLink,
  AlertCircle,
  Wifi,
  WifiOff,
  Radio,
  Clock,
  Zap,
  Lock,
  ShieldAlert,
  RefreshCw,
} from 'lucide-react';

// ── Live poll interval (ms) ───────────────────────────────────────────────────

const POLL_INTERVAL = 15_000; // 15 seconds

// ── Action type colour map ────────────────────────────────────────────────────

const ACTION_COLORS: Record<string, { bg: string; text: string; border: string }> = {
  PROJECT_SUBMITTED:        { bg: '#eff6ff', text: '#1d4ed8', border: '#bfdbfe' },
  PROJECT_APPROVED:         { bg: '#ecfdf5', text: '#047857', border: '#a7f3d0' },
  PROJECT_REJECTED:         { bg: '#fef2f2', text: '#b91c1c', border: '#fecaca' },
  PROJECT_ASSIGNED:         { bg: '#f5f3ff', text: '#6d28d9', border: '#ddd6fe' },
  PROJECT_REASSIGNED:       { bg: '#fffbeb', text: '#b45309', border: '#fde68a' },
  PROJECT_CANCELLED:        { bg: '#f8fafc', text: '#475569', border: '#e2e8f0' },
  PROJECT_COMPLETED:        { bg: '#ecfeff', text: '#0e7490', border: '#a5f3fc' },
  CORRECTION_REQUESTED:     { bg: '#fdf2f8', text: '#be185d', border: '#fbcfe8' },
  FILE_UPLOADED:            { bg: '#f0fdfa', text: '#0f766e', border: '#99f6e4' },
  FILE_DELETED:             { bg: '#fef2f2', text: '#991b1b', border: '#fecaca' },
  DRAWING_SUBMITTED:        { bg: '#f0fdf4', text: '#15803d', border: '#bbf7d0' },
  STUDENT_ASSIGNED:         { bg: '#fdf4ff', text: '#a21caf', border: '#f5d0fe' },
  DRAUGHTSMAN_ASSIGNED:     { bg: '#f5f3ff', text: '#6d28d9', border: '#ddd6fe' },
  DRAUGHTSMAN_REASSIGNED:   { bg: '#fffbeb', text: '#b45309', border: '#fde68a' },
  ASSIGNMENT_ACCEPTED:      { bg: '#ecfdf5', text: '#047857', border: '#a7f3d0' },
  ASSIGNMENT_REJECTED:      { bg: '#fff1f2', text: '#be123c', border: '#fecdd3' },
  PROJECT_CREATED_BY_ADMIN: { bg: '#eff6ff', text: '#1d4ed8', border: '#bfdbfe' },
  TOTAL_VALUE_UPDATED:      { bg: '#fefce8', text: '#a16207', border: '#fef08a' },
  DEFAULT:                  { bg: '#f8fafc', text: '#475569', border: '#e2e8f0' },
};

function actionStyle(type: string) {
  return ACTION_COLORS[type] ?? ACTION_COLORS.DEFAULT;
}

// ── New-entry animation wrapper ───────────────────────────────────────────────

function LiveRow({ log, isNew }: { log: ActivityLog; isNew: boolean }) {
  const style = actionStyle(log.action_type);
  const prjShort = (log.project_id || '').substring(0, 8).toUpperCase();
  return (
    <tr
      className={`transition-all duration-300 ${
        isNew ? 'bg-blue-50/70 animate-[fadeInRow_0.4s_ease_forwards]' : 'hover:bg-slate-50/80'
      }`}
    >
      {/* Action Type */}
      <td className="px-5 py-3.5">
        <span
          className="inline-flex items-center gap-1.5 font-mono font-semibold px-2.5 py-1 rounded-md border text-[10px]"
          style={{ background: style.bg, color: style.text, borderColor: style.border }}
        >
          {isNew && <span className="h-1.5 w-1.5 rounded-full animate-pulse" style={{ background: style.text }} />}
          {log.action_type}
        </span>
      </td>

      {/* Actor Role & ID */}
      <td className="px-5 py-3.5">
        <Badge role={log.actor_role} />
        <p className="text-[10px] font-mono text-slate-500 mt-1">
          UID: {(log.actor_id || '').substring(0, 8)}…
        </p>
      </td>

      {/* Details */}
      <td className="px-5 py-3.5 max-w-sm">
        <p className="text-xs text-slate-800 leading-relaxed font-normal">{log.details}</p>
      </td>

      {/* Project Link */}
      <td className="px-5 py-3.5">
        {log.project_id ? (
          <div>
            <Link
              href={`/projects/${log.project_id}`}
              className="font-mono text-xs text-[#0453cd] hover:underline font-semibold flex items-center gap-1 transition-colors group"
              title={log.project_name || `Project ${log.project_id}`}
            >
              <span className="truncate max-w-[200px]">
                {log.project_name || `PRJ-${prjShort}`}
              </span>
              <ExternalLink className="h-3 w-3 opacity-60 group-hover:opacity-100 transition-opacity shrink-0" />
            </Link>
            {log.project_name && (
              <p className="text-[10px] font-mono text-slate-400 mt-0.5">
                PRJ-{prjShort}
              </p>
            )}
          </div>
        ) : (
          <span className="text-xs font-mono text-slate-400">—</span>
        )}
      </td>

      {/* Timestamp */}
      <td className="px-5 py-3.5 text-right">
        <span className="text-[11px] font-mono font-medium text-slate-700">{formatRelativeTime(log.timestamp)}</span>
        <p className="text-[10px] font-mono text-slate-400 mt-0.5">
          {formatTime(log.timestamp)}
        </p>
      </td>
    </tr>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function ActivityPage() {
  const [logs, setLogs] = useState<ActivityLog[]>([]);
  const [newIds, setNewIds] = useState<Set<string>>(new Set());
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);
  const [liveActive, setLiveActive] = useState<boolean>(true);
  const [lastPoll, setLastPoll] = useState<Date | null>(null);
  const [pollCount, setPollCount] = useState<number>(0);
  const [countdown, setCountdown] = useState<number>(POLL_INTERVAL / 1000);
  const knownIds = useRef<Set<string>>(new Set());
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const countdownRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // ── Core fetch ──────────────────────────────────────────────────────────────

  const fetchLogs = useCallback(async (isInitial = false) => {
    if (isInitial) setLoading(true);
    try {
      const incoming = await adminApi.getActivityLogs(100);

      // Sort reverse chronological by timestamp (newest first)
      const sorted = [...(incoming || [])].sort(
        (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime()
      );

      // Detect new entries
      const freshIds = new Set<string>();
      if (!isInitial) {
        sorted.forEach((l) => {
          if (!knownIds.current.has(l.id)) freshIds.add(l.id);
        });
      }

      // Update known set
      sorted.forEach((l) => knownIds.current.add(l.id));

      setLogs(sorted);
      setNewIds(freshIds);
      setLastPoll(new Date());
      setPollCount((c) => c + 1);
      setError(null);
      setErrorStatus(null);

      // Clear "new" highlight after 4 seconds
      if (freshIds.size > 0) {
        setTimeout(() => setNewIds(new Set()), 4000);
      }
    } catch (err: any) {
      console.error('Activity feed query error:', err);
      const status = err.status || (err.message?.includes('401') ? 401 : err.message?.includes('403') ? 403 : err.message?.includes('500') ? 500 : null);
      setErrorStatus(status);
      setError(err.message || 'Failed to load activity stream from Worker API');
      // Notice: Do NOT erase existing logs if we have them from a previous poll
    } finally {
      setLoading(false);
    }
  }, []);

  // ── Polling lifecycle ────────────────────────────────────────────────────────

  const startPolling = useCallback(() => {
    if (timerRef.current) clearInterval(timerRef.current);
    if (countdownRef.current) clearInterval(countdownRef.current);

    setCountdown(POLL_INTERVAL / 1000);

    timerRef.current = setInterval(() => {
      fetchLogs(false);
      setCountdown(POLL_INTERVAL / 1000);
    }, POLL_INTERVAL);

    countdownRef.current = setInterval(() => {
      setCountdown((c) => Math.max(0, c - 1));
    }, 1000);
  }, [fetchLogs]);

  const stopPolling = useCallback(() => {
    if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null; }
    if (countdownRef.current) { clearInterval(countdownRef.current); countdownRef.current = null; }
  }, []);

  useEffect(() => {
    fetchLogs(true);
    startPolling();
    return () => stopPolling();
  }, [fetchLogs, startPolling, stopPolling]);

  const toggleLive = () => {
    if (liveActive) {
      stopPolling();
      setLiveActive(false);
    } else {
      fetchLogs(false);
      startPolling();
      setLiveActive(true);
    }
  };

  // ── Filter ───────────────────────────────────────────────────────────────────

  const filteredLogs = useMemo(() => {
    return logs.filter((log) => {
      if (!searchQuery.trim()) return true;
      const q = searchQuery.toLowerCase();
      return (
        (log.action_type || '').toLowerCase().includes(q) ||
        (log.details || '').toLowerCase().includes(q) ||
        (log.project_id || '').toLowerCase().includes(q) ||
        (log.project_name || '').toLowerCase().includes(q) ||
        (log.actor_role || '').toLowerCase().includes(q)
      );
    });
  }, [logs, searchQuery]);

  // Error categorization helpers
  const isAuthError = errorStatus === 401 || errorStatus === 403 || error?.toLowerCase().includes('unauthorized') || error?.toLowerCase().includes('forbidden');
  const isServerError = (errorStatus !== null && errorStatus >= 500) || error?.toLowerCase().includes('internal');

  // ── Render ───────────────────────────────────────────────────────────────────

  return (
    <AdminShell
      title="Platform Activity Feed"
      subtitle="Live webhook audit stream — auto-refreshes every 15 seconds"
      onRefresh={() => fetchLogs(false)}
      isRefreshing={loading && pollCount > 0}
    >
      {/* ── Live Status Bar ── */}
      <div className="mb-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        {/* Left: live indicator */}
        <div className="flex items-center gap-2.5 sm:gap-3 flex-wrap">
          <button
            onClick={toggleLive}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-xl text-xs font-semibold border transition-all cursor-pointer ${
              liveActive
                ? 'bg-emerald-50 text-emerald-700 border-emerald-200 hover:bg-emerald-100 shadow-sm'
                : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50 shadow-sm'
            }`}
          >
            {liveActive ? (
              <>
                <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
                <Radio className="h-3.5 w-3.5 text-emerald-600" />
                LIVE
              </>
            ) : (
              <>
                <WifiOff className="h-3.5 w-3.5 text-slate-400" />
                PAUSED
              </>
            )}
          </button>

          {liveActive && (
            <span className="text-xs font-mono text-slate-500 flex items-center gap-1">
              <Clock className="h-3.5 w-3.5 text-slate-400" />
              Next poll in <span className="font-semibold text-slate-700 ml-0.5">{countdown}s</span>
            </span>
          )}

          {lastPoll && (
            <span className="text-xs font-mono text-slate-400 hidden sm:block">
              Last poll: {lastPoll.toLocaleTimeString()}
            </span>
          )}
        </div>

        {/* Right: search + count */}
        <div className="flex items-center gap-2.5 sm:gap-3 flex-wrap">
          <div className="relative w-full sm:w-72">
            <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search actions, roles, projects…"
              className="pl-10 pr-4 py-2 rounded-xl bg-white border border-slate-200 text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd] focus:border-[#0453cd] transition-all w-full shadow-sm"
            />
          </div>
          <span className="text-xs text-slate-500 font-mono whitespace-nowrap">
            {filteredLogs.length} {filteredLogs.length === 1 ? 'event' : 'events'}
          </span>
        </div>
      </div>

      {/* ── Background Poll Error Warning Banner (shown when logs are retained from earlier poll) ── */}
      {error && logs.length > 0 && (
        <div className="mb-5 p-4 rounded-xl bg-amber-50 border border-amber-200 text-xs font-mono text-amber-900 flex items-center gap-3">
          <AlertCircle className="h-4 w-4 text-amber-600 shrink-0" />
          <span className="flex-1">
            Background sync alert: {error}. Retaining last verified stream from {lastPoll ? lastPoll.toLocaleTimeString() : 'earlier'}.
          </span>
          <Button variant="outline" size="sm" onClick={() => fetchLogs(false)} className="shrink-0">
            <RefreshCw className="h-3 w-3 mr-1" /> Retry Poll
          </Button>
        </div>
      )}

      {/* ── Activity Content States ── */}
      {loading && pollCount === 0 ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500 mt-3 font-medium">Connecting to live activity stream…</p>
        </div>
      ) : error && logs.length === 0 ? (
        /* Dedicated Error Card when initial fetch fails — NEVER silently disguised as empty feed */
        <Card className="text-center py-16 px-6 max-w-xl mx-auto space-y-4">
          <div className={`h-12 w-12 rounded-full flex items-center justify-center mx-auto ${
            isAuthError ? 'bg-amber-50 text-amber-600' : isServerError ? 'bg-rose-50 text-rose-600' : 'bg-slate-100 text-slate-600'
          }`}>
            {isAuthError ? <Lock className="h-6 w-6" /> : isServerError ? <AlertCircle className="h-6 w-6" /> : <WifiOff className="h-6 w-6" />}
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900">
              {isAuthError
                ? 'Administrative Access Required'
                : isServerError
                ? 'Activity Logging Service Unavailable'
                : 'Unable to Connect to Activity Stream'}
            </h3>
            <p className="text-xs text-slate-500 mt-1.5 font-mono max-w-md mx-auto leading-relaxed">
              {isAuthError
                ? 'You must be signed in with an authorized Studio Admin or Admin role to inspect the platform audit stream.'
                : error}
            </p>
          </div>
          <div className="pt-2 flex items-center justify-center gap-3">
            <Button size="sm" onClick={() => fetchLogs(true)}>
              <RefreshCw className="h-3.5 w-3.5 mr-1.5" /> Retry Connection
            </Button>
          </div>
        </Card>
      ) : filteredLogs.length === 0 ? (
        /* Truthful Empty State — Only when query succeeded and returned 0 genuine records */
        <Card className="text-center py-16">
          <Activity className="h-10 w-10 text-slate-400 mx-auto mb-3" />
          <h3 className="text-sm font-semibold text-slate-900">
            {searchQuery ? 'No matching activity logs' : 'No Activity Events Recorded'}
          </h3>
          <p className="text-xs text-slate-500 mt-1 max-w-md mx-auto font-mono leading-relaxed">
            {searchQuery
              ? `No logs matched "${searchQuery}". Try adjusting your search query.`
              : 'No activity events have been recorded in Cloudflare D1 yet. Genuine system events (project submissions, assignments, reviews, redlines) will appear here in real time.'}
          </p>
        </Card>
      ) : (
        <div className="bg-white border border-slate-200 rounded-xl overflow-hidden shadow-sm">
          {/* Live event count banner */}
          {newIds.size > 0 && (
            <div className="px-5 py-2.5 bg-blue-50 border-b border-blue-200 flex items-center gap-2 text-xs text-[#0453cd] font-semibold">
              <Zap className="h-3.5 w-3.5 animate-pulse text-[#0453cd]" />
              {newIds.size} new event{newIds.size > 1 ? 's' : ''} received
            </div>
          )}

          {/* Desktop Table (>= 640px) */}
          <div className="hidden sm:block overflow-x-auto w-full max-w-full">
            <table className="w-full text-left text-xs min-w-[680px]">
              <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-semibold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Action Type</th>
                  <th className="px-5 py-3.5">Actor Role & ID</th>
                  <th className="px-5 py-3.5">Audit Narrative</th>
                  <th className="px-5 py-3.5">Associated Project</th>
                  <th className="px-5 py-3.5 text-right">Time</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-200">
                {filteredLogs.map((log) => (
                  <LiveRow key={log.id} log={log} isNew={newIds.has(log.id)} />
                ))}
              </tbody>
            </table>
          </div>

          {/* Mobile Card View (< 640px) */}
          <div className="block sm:hidden divide-y divide-slate-100 p-4 space-y-3">
            {filteredLogs.map((log) => {
              const style = actionStyle(log.action_type);
              const isNew = newIds.has(log.id);
              const prjShort = (log.project_id || '').substring(0, 6).toUpperCase();
              return (
                <div
                  key={log.id}
                  className={`p-3.5 rounded-xl border border-slate-200 transition-all ${
                    isNew ? 'bg-blue-50/80 border-blue-300 animate-[fadeInRow_0.4s_ease_forwards]' : 'bg-slate-50/60'
                  }`}
                >
                  <div className="flex items-center justify-between gap-2 mb-2">
                    <span
                      className="inline-flex items-center gap-1.5 font-mono font-semibold px-2 py-0.5 rounded-md border text-[10px]"
                      style={{ background: style.bg, color: style.text, borderColor: style.border }}
                    >
                      {isNew && <span className="h-1.5 w-1.5 rounded-full animate-pulse" style={{ background: style.text }} />}
                      {log.action_type}
                    </span>
                    <span className="text-[10px] font-mono text-slate-500">{formatRelativeTime(log.timestamp)}</span>
                  </div>

                  <p className="text-xs text-slate-800 leading-relaxed mb-2.5 font-normal">{log.details}</p>

                  <div className="flex items-center justify-between pt-2 border-t border-slate-200/70 text-xs">
                    <div className="flex items-center gap-2">
                      <Badge role={log.actor_role} />
                      <span className="text-[10px] font-mono text-slate-400">UID: {(log.actor_id || '').substring(0, 6)}…</span>
                    </div>
                    {log.project_id && (
                      <Link
                        href={`/projects/${log.project_id}`}
                        className="font-mono text-xs text-[#0453cd] hover:underline font-semibold flex items-center gap-1 max-w-[160px] truncate"
                        title={log.project_name || `Project ${log.project_id}`}
                      >
                        <span className="truncate">{log.project_name || `PRJ-${prjShort}`}</span>
                        <ExternalLink className="h-3 w-3 opacity-60 shrink-0" />
                      </Link>
                    )}
                  </div>
                </div>
              );
            })}
          </div>

          {/* Footer */}
          <div className="px-5 py-3 border-t border-slate-200 flex items-center justify-between text-xs font-mono text-slate-500 bg-slate-50/50">
            <span>
              {liveActive ? (
                <span className="flex items-center gap-1.5 text-emerald-700 font-medium">
                  <span className="h-1.5 w-1.5 rounded-full bg-emerald-500 animate-pulse" />
                  Live polling active · {pollCount} {pollCount === 1 ? 'poll' : 'polls'} completed
                </span>
              ) : (
                'Feed paused — click LIVE to resume'
              )}
            </span>
            <span>Archi Draft Studio · Audit Stream</span>
          </div>
        </div>
      )}

      {/* Keyframe injection for new-row fade */}
      <style>{`
        @keyframes fadeInRow {
          from { opacity: 0; transform: translateX(-8px); }
          to   { opacity: 1; transform: translateX(0); }
        }
      `}</style>
    </AdminShell>
  );
}

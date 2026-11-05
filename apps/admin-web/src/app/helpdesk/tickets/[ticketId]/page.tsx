'use client';

import React, { useEffect, useState } from 'react';
import { useParams, useRouter } from 'next/navigation';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { adminApi } from '@/lib/api';
import {
  HelpdeskTicket,
  HelpdeskEvent,
  HelpdeskComment,
  HelpdeskEmailLog,
  HelpdeskSeverity,
  HelpdeskStatus,
} from '@/lib/types';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import {
  LifeBuoy,
  ArrowLeft,
  AlertTriangle,
  Flame,
  CheckCircle2,
  Clock,
  Send,
  UserCheck,
  Copy,
  Check,
  Mail,
  RotateCcw,
  ExternalLink,
  ShieldCheck,
  Terminal,
  Activity,
  Layers,
  MessageSquare,
  User,
  Cpu,
  ChevronDown,
  ChevronUp,
  X,
  Trash2,
} from 'lucide-react';

export default function TicketDetailPage() {
  const params = useParams();
  const router = useRouter();
  const ticketId = params.ticketId as string;

  const [ticket, setTicket] = useState<HelpdeskTicket | null>(null);
  const [events, setEvents] = useState<HelpdeskEvent[]>([]);
  const [comments, setComments] = useState<HelpdeskComment[]>([]);
  const [emailLogs, setEmailLogs] = useState<HelpdeskEmailLog[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Triage state
  const [status, setStatus] = useState<HelpdeskStatus>('OPEN');
  const [severity, setSeverity] = useState<HelpdeskSeverity>('MEDIUM');
  const [resolutionNotes, setResolutionNotes] = useState<string>('');
  const [isUpdating, setIsUpdating] = useState<boolean>(false);
  const [feedback, setFeedback] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Comment state
  const [commentText, setCommentText] = useState<string>('');
  const [submittingComment, setSubmittingComment] = useState<boolean>(false);

  // Toggle for raw technical trace
  const [showTechnicalDetails, setShowTechnicalDetails] = useState<boolean>(false);
  const [copiedStack, setCopiedStack] = useState<boolean>(false);
  const [retryingLogId, setRetryingLogId] = useState<string | null>(null);

  // Delete state
  const [isDeleting, setIsDeleting] = useState<boolean>(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<boolean>(false);

  const handleDeleteTicket = async () => {
    setIsDeleting(true);
    try {
      await adminApi.deleteHelpdeskTicket(ticketId);
      router.push('/helpdesk');
    } catch (err: any) {
      setFeedback({ type: 'error', message: err?.message || 'Failed to delete ticket.' });
      setIsDeleting(false);
      setShowDeleteConfirm(false);
    }
  };

  const loadTicket = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getHelpdeskTicket(ticketId);
      setTicket(data.ticket);
      setEvents(data.events || []);
      setComments(data.comments || []);
      setEmailLogs(data.email_logs || []);

      setStatus(data.ticket.status);
      setSeverity(data.ticket.severity);
      setResolutionNotes(data.ticket.resolution_notes || '');
    } catch (err: any) {
      console.error('Failed to load ticket details:', err);
      setError(err?.message || 'Failed to retrieve ticket record from D1.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    if (ticketId) loadTicket();
  }, [ticketId]);

  const handleUpdateTriage = async (newStatus?: HelpdeskStatus) => {
    if (!ticket) return;

    setIsUpdating(true);
    setFeedback(null);

    const targetStatus = newStatus || status;

    try {
      const res = await adminApi.updateHelpdeskTicket(ticket.id, {
        status: targetStatus,
        severity,
        resolution_notes: resolutionNotes.trim() || undefined,
      });

      if (res.success && res.ticket) {
        setTicket(res.ticket);
        setStatus(res.ticket.status);
        setFeedback({
          type: 'success',
          message: targetStatus === 'RESOLVED' ? 'Ticket marked as Resolved!' : 'Ticket updated successfully!',
        });
        setTimeout(() => setFeedback(null), 4000);
        await loadTicket(true);
      }
    } catch (err: any) {
      setFeedback({
        type: 'error',
        message: err?.message || 'Failed to update ticket triage.',
      });
    } finally {
      setIsUpdating(false);
    }
  };

  const handleAddComment = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!ticket || !commentText.trim()) return;

    setSubmittingComment(true);
    setFeedback(null);
    try {
      await adminApi.addHelpdeskComment(ticket.id, commentText.trim(), true);
      setCommentText('');
      setFeedback({ type: 'success', message: 'Internal note added.' });
      setTimeout(() => setFeedback(null), 3000);
      await loadTicket(true);
    } catch (err: any) {
      setFeedback({ type: 'error', message: err?.message || 'Failed to add note.' });
    } finally {
      setSubmittingComment(false);
    }
  };

  const handleRetryEmail = async (logId: string) => {
    setRetryingLogId(logId);
    setFeedback(null);
    try {
      const res = await adminApi.retryHelpdeskEmail(logId);
      if (res.success) {
        setFeedback({ type: 'success', message: 'Notification email successfully dispatched!' });
        await loadTicket(true);
      } else {
        setFeedback({
          type: 'error',
          message: res.error || `Email dispatch failed (${res.status || 'Error'}). Check your Resend key in Settings.`,
        });
      }
    } catch (err: any) {
      setFeedback({ type: 'error', message: err?.message || 'Failed to retry email dispatch.' });
    } finally {
      setRetryingLogId(null);
    }
  };

  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedStack(true);
    setTimeout(() => setCopiedStack(false), 2000);
  };

  return (
    <AdminShell
      title={`Ticket: ${ticketId}`}
      subtitle="Issue details, user communication, audit history, and resolution management"
      backHref="/helpdesk"
      backLabel="Back to Help Desk"
      onRefresh={() => loadTicket(true)}
      isRefreshing={refreshing}
    >
      {/* ── Status Feedback Banner ── */}
      {feedback && (
        <div
          className={`mb-4 p-4 rounded-2xl border text-xs flex items-center justify-between gap-3 shadow-xs animate-in fade-in ${
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
          <button onClick={() => setFeedback(null)} className="text-slate-400 hover:text-slate-600 p-1">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      {loading ? (
        <div className="py-24 flex flex-col items-center justify-center gap-3">
          <div className="h-8 w-8 animate-spin rounded-full border-3 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500 font-medium">Loading ticket details...</p>
        </div>
      ) : error || !ticket ? (
        <Card className="p-8 text-center bg-white border-slate-200 space-y-3">
          <div className="h-12 w-12 rounded-2xl bg-rose-50 text-rose-600 flex items-center justify-center mx-auto">
            <AlertTriangle className="h-6 w-6" />
          </div>
          <p className="text-base font-bold text-slate-900">{error || 'Ticket Not Found'}</p>
          <div className="flex justify-center gap-3">
            <Link href="/helpdesk">
              <Button variant="outline" size="sm">
                Return to Help Desk
              </Button>
            </Link>
            <Button variant="primary" size="sm" onClick={() => loadTicket(true)}>
              Retry
            </Button>
          </div>
        </Card>
      ) : (
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* ── Left Column: Details & Communication (2 cols) ── */}
          <div className="lg:col-span-2 space-y-6">
            {/* Main Ticket Card */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex flex-wrap items-center justify-between gap-2 mb-4">
                <div className="flex items-center gap-2">
                  <span className="text-sm font-mono font-bold text-[#0453cd] px-3 py-1 rounded-xl bg-blue-50 border border-blue-200">
                    {ticket.id}
                  </span>
                  {ticket.is_user_submitted === 1 ? (
                    <span className="px-2.5 py-0.5 text-xs font-semibold rounded-full bg-blue-50 text-[#0453cd] border border-blue-200 inline-flex items-center gap-1">
                      <User className="h-3 w-3" />
                      <span>User Submitted</span>
                    </span>
                  ) : (
                    <span className="px-2.5 py-0.5 text-xs font-medium rounded-full bg-slate-100 text-slate-600 border border-slate-200 inline-flex items-center gap-1">
                      <Cpu className="h-3 w-3" />
                      <span>Automated Sensor</span>
                    </span>
                  )}
                  <span className="px-2.5 py-0.5 text-xs font-medium rounded-full bg-slate-100 text-slate-700">
                    {ticket.category.replace(/_/g, ' ')}
                  </span>
                </div>

                <div className="flex items-center gap-1.5 text-xs text-slate-500 font-medium">
                  <Clock className="h-3.5 w-3.5 text-slate-400" />
                  <span>{new Date(ticket.created_at).toLocaleString([], { dateStyle: 'medium', timeStyle: 'short' })}</span>
                </div>
              </div>

              <h1 className="text-xl font-bold text-slate-900 mb-4 leading-snug">{ticket.title}</h1>

              {/* User / Reporter Contact Block */}
              {ticket.user_email && (
                <div className="mb-4 p-3.5 bg-slate-50 border border-slate-200 rounded-xl flex items-center justify-between gap-3">
                  <div className="flex items-center gap-2.5">
                    <div className="h-8 w-8 rounded-lg bg-blue-100 text-[#0453cd] flex items-center justify-center font-bold text-xs">
                      @
                    </div>
                    <div>
                      <span className="text-[11px] text-slate-500 block font-medium">Submitted by:</span>
                      <a href={`mailto:${ticket.user_email}`} className="text-xs font-semibold text-[#0453cd] hover:underline">
                        {ticket.user_email}
                      </a>
                    </div>
                  </div>
                  <a
                    href={`mailto:${ticket.user_email}?subject=Regarding support ticket ${ticket.id}: ${encodeURIComponent(ticket.title)}`}
                    className="inline-flex items-center gap-1 text-xs font-semibold text-[#0453cd] bg-white border border-blue-200 px-3 py-1.5 rounded-lg hover:bg-blue-50 transition-colors"
                  >
                    <Mail className="h-3.5 w-3.5" />
                    <span>Reply via Email</span>
                  </a>
                </div>
              )}

              {/* Issue Description */}
              <div className="mb-6">
                <span className="text-xs font-semibold text-slate-700 uppercase tracking-wider block mb-2">
                  Description / Observed Behavior
                </span>
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 text-slate-800 text-sm leading-relaxed whitespace-pre-wrap">
                  {ticket.error_message}
                </div>
              </div>

              {/* Technical Stack Trace & Logs (Collapsible) */}
              {(ticket.stack_trace || ticket.error_code) && (
                <div className="mb-6 border border-slate-200 rounded-xl overflow-hidden">
                  <button
                    type="button"
                    onClick={() => setShowTechnicalDetails(!showTechnicalDetails)}
                    className="w-full px-4 py-3 bg-slate-50 hover:bg-slate-100/80 transition-colors flex items-center justify-between text-xs font-semibold text-slate-700 cursor-pointer"
                  >
                    <span className="flex items-center gap-2">
                      <Terminal className="h-4 w-4 text-slate-500" />
                      <span>Technical Error Trace & Server Logs</span>
                    </span>
                    <span className="flex items-center gap-1 text-[#0453cd]">
                      <span>{showTechnicalDetails ? 'Hide Details' : 'Show Details'}</span>
                      {showTechnicalDetails ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                    </span>
                  </button>

                  {showTechnicalDetails && (
                    <div className="p-4 bg-slate-950 text-slate-100 font-mono text-xs overflow-x-auto max-h-80 select-all border-t border-slate-800 leading-relaxed">
                      <div className="flex justify-end mb-2">
                        <button
                          type="button"
                          onClick={() => copyToClipboard(ticket.stack_trace || ticket.error_message)}
                          className="text-[11px] text-emerald-400 hover:text-emerald-300 flex items-center gap-1 cursor-pointer"
                        >
                          {copiedStack ? <Check className="h-3 w-3" /> : <Copy className="h-3 w-3" />}
                          <span>{copiedStack ? 'Copied' : 'Copy Log'}</span>
                        </button>
                      </div>
                      {ticket.error_code && <div className="text-amber-400 mb-1">Code: {ticket.error_code}</div>}
                      <pre className="whitespace-pre-wrap text-emerald-400/90 text-[11px]">
                        {ticket.stack_trace || ticket.error_message}
                      </pre>
                    </div>
                  )}
                </div>
              )}

              {/* Context Summary Cards */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 p-4 rounded-xl bg-slate-50 border border-slate-200 text-xs">
                <div>
                  <span className="block text-[11px] text-slate-500 font-medium">Module</span>
                  <span className="font-semibold text-slate-800 truncate block">{ticket.affected_module || 'General'}</span>
                </div>
                <div>
                  <span className="block text-[11px] text-slate-500 font-medium">Environment</span>
                  <span className="font-semibold text-slate-800 uppercase">{ticket.environment}</span>
                </div>
                <div>
                  <span className="block text-[11px] text-slate-500 font-medium">Occurrences</span>
                  <span className="font-bold text-[#0453cd]">{ticket.occurrence_count || 1}x</span>
                </div>
                <div>
                  <span className="block text-[11px] text-slate-500 font-medium">Page Route</span>
                  <span className="font-mono text-slate-700 truncate block" title={ticket.page_route || ''}>
                    {ticket.page_route || '—'}
                  </span>
                </div>
              </div>
            </Card>

            {/* Email Notification History Card */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex items-center justify-between mb-4">
                <div className="flex items-center gap-2">
                  <Mail className="h-4 w-4 text-[#0453cd]" />
                  <h3 className="text-sm font-bold text-slate-900">Email Notification Status</h3>
                </div>
                <span className="text-xs text-slate-500">Destination: pixelmintstudiomvs@gmail.com</span>
              </div>

              {emailLogs.length === 0 ? (
                <p className="text-xs text-slate-400 py-3 text-center">No email notifications recorded for this incident.</p>
              ) : (
                <div className="divide-y divide-slate-100">
                  {emailLogs.map((log) => (
                    <div key={log.id} className="py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
                      <div>
                        <div className="flex items-center gap-2">
                          <span
                            className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${
                              log.status === 'SENT'
                                ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                                : log.status === 'SUPPRESSED_DUPLICATE'
                                ? 'bg-slate-100 text-slate-600'
                                : 'bg-rose-50 text-rose-700 border border-rose-200'
                            }`}
                          >
                            {log.status}
                          </span>
                          <span className="font-medium text-slate-800">{log.recipient}</span>
                        </div>
                        <p className="text-xs text-slate-500 mt-0.5">{log.subject}</p>
                        {log.error_message && (
                          <p className="text-xs text-rose-600 mt-0.5 font-medium">{log.error_message}</p>
                        )}
                      </div>

                      <div className="flex items-center gap-2 shrink-0">
                        <span className="text-xs text-slate-400">
                          {new Date(log.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </span>
                        {log.status === 'FAILED' && (
                          <Button
                            variant="outline"
                            size="sm"
                            disabled={retryingLogId === log.id}
                            onClick={() => handleRetryEmail(log.id)}
                            className="text-xs h-7 px-2.5 font-semibold"
                          >
                            <RotateCcw className={`h-3 w-3 mr-1 ${retryingLogId === log.id ? 'animate-spin' : ''}`} />
                            <span>{retryingLogId === log.id ? 'Sending...' : 'Retry'}</span>
                          </Button>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </Card>

            {/* Audit History Timeline */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex items-center gap-2 mb-4">
                <Activity className="h-4 w-4 text-[#0453cd]" />
                <h3 className="text-sm font-bold text-slate-900">Activity Timeline</h3>
              </div>

              <div className="relative pl-6 space-y-4 before:absolute before:left-2 before:top-2 before:bottom-2 before:w-0.5 before:bg-slate-200">
                {events.map((ev) => (
                  <div key={ev.id} className="relative text-xs">
                    <span className="absolute -left-6 top-1 h-2.5 w-2.5 rounded-full bg-[#0453cd] ring-4 ring-white" />
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-slate-800 uppercase text-[11px]">{ev.event_type}</span>
                      <span className="text-[10px] text-slate-400">
                        {new Date(ev.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                      </span>
                    </div>
                    <p className="text-slate-600 mt-0.5">{ev.details}</p>
                    {ev.actor_name && (
                      <span className="text-[10px] text-slate-400 block mt-0.5">
                        By {ev.actor_name}
                      </span>
                    )}
                  </div>
                ))}
              </div>
            </Card>
          </div>

          {/* ── Right Column: Easy Triage & Notes (1 col) ── */}
          <div className="space-y-6">
            {/* Quick Action: Mark as Solved */}
            {ticket.status !== 'RESOLVED' && ticket.status !== 'CLOSED' && (
              <Button
                variant="primary"
                onClick={() => handleUpdateTriage('RESOLVED')}
                disabled={isUpdating}
                className="w-full bg-emerald-600 hover:bg-emerald-700 text-white font-semibold py-3 rounded-2xl shadow-xs flex items-center justify-center gap-2 text-sm transition-all"
              >
                <CheckCircle2 className="h-5 w-5" />
                <span>Mark Ticket as Solved</span>
              </Button>
            )}

            {/* Triage Control Card */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <h3 className="text-sm font-bold text-slate-900 mb-4 pb-2 border-b border-slate-100 flex items-center gap-2">
                <ShieldCheck className="h-4 w-4 text-[#0453cd]" />
                <span>Triage & Status</span>
              </h3>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Status
                  </label>
                  <select
                    value={status}
                    onChange={(e) => setStatus(e.target.value as any)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white"
                  >
                    <option value="OPEN">Needs Review (Open)</option>
                    <option value="INVESTIGATING">Under Investigation</option>
                    <option value="IN_PROGRESS">In Progress (Fix being made)</option>
                    <option value="RESOLVED">Resolved (Solved)</option>
                    <option value="CLOSED">Closed (Archived)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Priority / Urgency
                  </label>
                  <select
                    value={severity}
                    onChange={(e) => setSeverity(e.target.value as any)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-medium text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white"
                  >
                    <option value="LOW">Low (Minor / Cosmetic)</option>
                    <option value="MEDIUM">Medium (Normal)</option>
                    <option value="HIGH">High (Important feature blocked)</option>
                    <option value="CRITICAL">Critical (Urgent blocker)</option>
                  </select>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Resolution Notes
                  </label>
                  <textarea
                    value={resolutionNotes}
                    onChange={(e) => setResolutionNotes(e.target.value)}
                    placeholder="Document how this issue was fixed or addressed..."
                    rows={4}
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white resize-none"
                  />
                </div>

                <Button
                  type="button"
                  variant="primary"
                  onClick={() => handleUpdateTriage()}
                  disabled={isUpdating}
                  className="w-full bg-[#0453cd] hover:bg-blue-700 text-white text-xs py-2.5 rounded-xl font-semibold shadow-xs"
                >
                  {isUpdating ? 'Saving...' : 'Save Triage Update'}
                </Button>
              </div>
            </Card>

            {/* Internal Notes / Comments */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <h3 className="text-sm font-bold text-slate-900 mb-4 flex items-center gap-2">
                <MessageSquare className="h-4 w-4 text-[#0453cd]" />
                <span>Internal Discussion Notes</span>
              </h3>

              <div className="space-y-3 mb-4 max-h-60 overflow-y-auto">
                {comments.length === 0 ? (
                  <p className="text-xs text-slate-400 py-3 text-center">No internal notes yet.</p>
                ) : (
                  comments.map((c) => (
                    <div key={c.id} className="p-3 rounded-xl bg-slate-50 border border-slate-100 text-xs">
                      <div className="flex items-center justify-between mb-1">
                        <span className="font-bold text-slate-800 text-xs">{c.author_name}</span>
                        <span className="text-[10px] text-slate-400">
                          {new Date(c.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </span>
                      </div>
                      <p className="text-slate-700 whitespace-pre-wrap">{c.comment}</p>
                    </div>
                  ))
                )}
              </div>

              <form onSubmit={handleAddComment} className="space-y-2">
                <textarea
                  value={commentText}
                  onChange={(e) => setCommentText(e.target.value)}
                  placeholder="Add an internal note for other admins..."
                  rows={2}
                  className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white resize-none"
                  required
                />
                <Button
                  type="submit"
                  variant="outline"
                  size="sm"
                  disabled={submittingComment || !commentText.trim()}
                  className="w-full text-xs font-semibold"
                >
                  {submittingComment ? 'Posting...' : 'Add Note'}
                </Button>
              </form>
            </Card>

            {/* Danger Zone: Delete Ticket */}
            <Card className="p-4 bg-rose-50/50 border-rose-200 shadow-2xs">
              <div className="flex items-center justify-between gap-3">
                <div>
                  <h4 className="text-xs font-bold text-rose-900">Delete Ticket</h4>
                  <p className="text-[11px] text-rose-700/80 mt-0.5">Permanently remove this ticket and history</p>
                </div>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  onClick={() => setShowDeleteConfirm(true)}
                  className="bg-white border-rose-200 text-rose-600 hover:bg-rose-50 text-xs font-semibold px-3 py-1.5 flex items-center gap-1.5 shrink-0"
                >
                  <Trash2 className="h-3.5 w-3.5" />
                  <span>Delete</span>
                </Button>
              </div>
            </Card>
          </div>
        </div>
      )}

      {/* Delete Confirmation Modal */}
      {showDeleteConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-xs p-4 animate-in fade-in">
          <div className="bg-white rounded-2xl max-w-sm w-full p-5 shadow-xl border border-slate-200 space-y-4">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center shrink-0">
                <Trash2 className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900">Delete Ticket?</h3>
                <p className="text-xs text-slate-500">Ticket {ticketId} will be permanently removed.</p>
              </div>
            </div>

            <p className="text-xs text-slate-600">
              Are you sure you want to permanently delete this ticket and all its event history? This action cannot be undone.
            </p>

            <div className="flex items-center justify-end gap-2 pt-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowDeleteConfirm(false)}
                disabled={isDeleting}
                className="text-xs"
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                onClick={handleDeleteTicket}
                disabled={isDeleting}
                className="bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold px-4"
              >
                {isDeleting ? 'Deleting...' : 'Delete Permanently'}
              </Button>
            </div>
          </div>
        </div>
      )}
    </AdminShell>
  );
}

'use client';

import React, { useEffect, useState, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { adminApi } from '@/lib/api';
import { HelpdeskTicket, HelpdeskStats, HelpdeskStatus } from '@/lib/types';
import { CreateTicketModal } from '@/components/helpdesk/CreateTicketModal';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import {
  LifeBuoy,
  CheckCircle2,
  Clock,
  Search,
  PlusCircle,
  Sliders,
  ChevronRight,
  Inbox,
  User,
  Cpu,
  Trash2,
  AlertTriangle,
  X,
  Mail,
} from 'lucide-react';

export default function HelpDeskOverviewPage() {
  const [stats, setStats] = useState<HelpdeskStats | null>(null);
  const [tickets, setTickets] = useState<HelpdeskTicket[]>([]);
  const [totalTickets, setTotalTickets] = useState<number>(0);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Filters
  const [activeTab, setActiveTab] = useState<'ALL' | 'OPEN' | 'USER_SUBMITTED' | 'RESOLVED'>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');

  // Modal State
  const [isCreateModalOpen, setIsCreateModalOpen] = useState<boolean>(false);

  // Delete State
  const [deletingTicketId, setDeletingTicketId] = useState<string | null>(null);
  const [isDeleting, setIsDeleting] = useState<boolean>(false);
  const [showClearAllConfirm, setShowClearAllConfirm] = useState<boolean>(false);

  const loadData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [statsData, ticketsData] = await Promise.all([
        adminApi.getHelpdeskStats(),
        adminApi.getHelpdeskTickets({ limit: 100 }),
      ]);

      setStats(statsData);
      setTickets(ticketsData.tickets || []);
      setTotalTickets(ticketsData.total || 0);
    } catch (err: any) {
      console.error('Failed to load helpdesk data:', err);
      setError(err?.message || 'Unable to load tickets.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
    const interval = setInterval(() => loadData(false), 30000);
    return () => clearInterval(interval);
  }, []);

  // Filtered Tickets
  const filteredTickets = useMemo(() => {
    return tickets.filter((t) => {
      // Tab filter
      if (activeTab === 'OPEN' && (t.status === 'RESOLVED' || t.status === 'CLOSED')) return false;
      if (activeTab === 'RESOLVED' && t.status !== 'RESOLVED' && t.status !== 'CLOSED') return false;
      if (activeTab === 'USER_SUBMITTED' && t.is_user_submitted !== 1) return false;

      // Search Query
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase().trim();
        const matchesId = t.id.toLowerCase().includes(q);
        const matchesTitle = t.title.toLowerCase().includes(q);
        const matchesError = t.error_message.toLowerCase().includes(q);
        const matchesEmail = t.user_email?.toLowerCase().includes(q);
        if (!matchesId && !matchesTitle && !matchesError && !matchesEmail) return false;
      }

      return true;
    });
  }, [tickets, activeTab, searchQuery]);

  const handleDeleteTicket = async (ticketId: string) => {
    setIsDeleting(true);
    try {
      await adminApi.deleteHelpdeskTicket(ticketId);
      setTickets((prev) => prev.filter((t) => t.id !== ticketId));
      setTotalTickets((prev) => Math.max(0, prev - 1));
      setNotification({ type: 'success', message: `Ticket ${ticketId} was successfully deleted.` });
      // Refresh stats
      adminApi.getHelpdeskStats().then(setStats).catch(() => {});
    } catch (err: any) {
      setNotification({ type: 'error', message: err?.message || 'Failed to delete ticket.' });
    } finally {
      setIsDeleting(false);
      setDeletingTicketId(null);
    }
  };

  const handleClearAllTickets = async () => {
    setIsDeleting(true);
    try {
      await adminApi.bulkDeleteHelpdeskTickets({ clearAll: true });
      setTickets([]);
      setTotalTickets(0);
      setStats({
        totalReports: 0,
        openTickets: 0,
        criticalIssues: 0,
        highPriority: 0,
        inProgress: 0,
        awaitingResponse: 0,
        resolvedTickets: 0,
        avgResolutionTimeMinutes: 0,
        categoryDistribution: {},
        severityDistribution: {},
        recentEvents: [],
        emailDeliveryStats: {},
      });
      setNotification({ type: 'success', message: 'All tickets and records have been cleared.' });
    } catch (err: any) {
      setNotification({ type: 'error', message: err?.message || 'Failed to clear tickets.' });
    } finally {
      setIsDeleting(false);
      setShowClearAllConfirm(false);
    }
  };

  const userSubmittedCount = useMemo(() => {
    return tickets.filter((t) => t.is_user_submitted === 1).length;
  }, [tickets]);

  const statusBadge = (status: HelpdeskStatus) => {
    switch (status) {
      case 'OPEN':
        return <span className="inline-flex items-center gap-1 px-2.5 py-0.5 text-xs font-semibold rounded-full bg-amber-50 text-amber-700 border border-amber-200">Open</span>;
      case 'IN_PROGRESS':
        return <span className="inline-flex items-center gap-1 px-2.5 py-0.5 text-xs font-semibold rounded-full bg-blue-50 text-blue-700 border border-blue-200">In Progress</span>;
      case 'RESOLVED':
      case 'CLOSED':
        return <span className="inline-flex items-center gap-1 px-2.5 py-0.5 text-xs font-semibold rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">Solved</span>;
      default:
        return <span className="inline-flex items-center gap-1 px-2.5 py-0.5 text-xs font-semibold rounded-full bg-slate-50 text-slate-700 border border-slate-200">{status}</span>;
    }
  };

  return (
    <AdminShell
      title="Help Desk"
      subtitle="Simple support inbox for customer inquiries, bug reports, and incident alerts"
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      {/* ── Notification Banner ── */}
      {notification && (
        <div
          className={`mb-4 p-4 rounded-xl border text-xs flex items-center justify-between gap-3 shadow-xs animate-in fade-in ${
            notification.type === 'success'
              ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
              : 'bg-rose-50 border-rose-200 text-rose-900'
          }`}
        >
          <div className="flex items-center gap-2">
            {notification.type === 'success' ? (
              <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
            ) : (
              <AlertTriangle className="h-4 w-4 shrink-0 text-rose-600" />
            )}
            <span className="font-semibold">{notification.message}</span>
          </div>
          <button onClick={() => setNotification(null)} className="text-slate-400 hover:text-slate-600 p-1">
            <X className="h-4 w-4" />
          </button>
        </div>
      )}

      {/* ── Top Header Toolbar ── */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
        <div className="flex items-center gap-3">
          <div className="h-10 w-10 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center shadow-2xs">
            <LifeBuoy className="h-5 w-5" />
          </div>
          <div>
            <h2 className="text-base font-bold text-slate-900">Support Inquiries & Bugs</h2>
            <p className="text-xs text-slate-500">
              Admin Notifications: <span className="font-semibold text-slate-700">pixelmintstudiomvs@gmail.com</span>
            </p>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {tickets.length > 0 && (
            <Button
              variant="outline"
              onClick={() => setShowClearAllConfirm(true)}
              className="flex items-center gap-1.5 text-xs text-rose-600 hover:text-rose-700 hover:bg-rose-50 border-rose-200 px-3 py-2 font-semibold"
            >
              <Trash2 className="h-3.5 w-3.5" />
              <span>Clear All</span>
            </Button>
          )}

          <Link href="/helpdesk/settings">
            <Button variant="outline" className="flex items-center gap-1.5 text-xs font-semibold px-3 py-2">
              <Sliders className="h-4 w-4 text-slate-600" />
              <span>Settings</span>
            </Button>
          </Link>

          <Button
            variant="primary"
            onClick={() => setIsCreateModalOpen(true)}
            className="flex items-center gap-1.5 bg-[#0453cd] hover:bg-blue-700 text-white shadow-xs text-xs font-semibold px-4 py-2"
          >
            <PlusCircle className="h-4 w-4" />
            <span>New Ticket</span>
          </Button>
        </div>
      </div>

      {/* ── 3 Key Summary Cards ── */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-6">
        <Card className="p-4 bg-white border-slate-200 shadow-xs">
          <div className="flex items-center justify-between">
            <p className="text-xs font-semibold text-slate-500">Open Tickets</p>
            {(stats?.openTickets ?? 0) > 0 && <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />}
          </div>
          <p className="text-2xl font-bold text-amber-600 mt-1">{stats?.openTickets ?? 0}</p>
        </Card>

        <Card className="p-4 bg-white border-slate-200 shadow-xs">
          <p className="text-xs font-semibold text-slate-500">Solved Tickets</p>
          <p className="text-2xl font-bold text-emerald-600 mt-1">{stats?.resolvedTickets ?? 0}</p>
        </Card>

        <Card className="p-4 bg-white border-slate-200 shadow-xs">
          <p className="text-xs font-semibold text-slate-500">Total Tickets</p>
          <p className="text-2xl font-bold text-slate-900 mt-1">{stats?.totalReports ?? 0}</p>
        </Card>
      </div>

      {/* ── Tabs & Search Bar ── */}
      <div className="flex flex-col md:flex-row items-stretch md:items-center justify-between gap-3 mb-4 bg-white p-3 rounded-2xl border border-slate-200 shadow-xs">
        {/* Simple Tabs */}
        <div className="flex items-center gap-1 overflow-x-auto pb-1 sm:pb-0">
          {[
            { key: 'ALL', label: 'All Tickets', count: stats?.totalReports },
            { key: 'OPEN', label: 'Open', count: stats?.openTickets },
            { key: 'USER_SUBMITTED', label: 'From Users', count: userSubmittedCount },
            { key: 'RESOLVED', label: 'Solved', count: stats?.resolvedTickets },
          ].map((tab) => (
            <button
              key={tab.key}
              onClick={() => setActiveTab(tab.key as any)}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all cursor-pointer flex items-center gap-1.5 ${
                activeTab === tab.key
                  ? 'bg-[#0453cd] text-white shadow-xs'
                  : 'bg-white text-slate-600 hover:text-slate-900 hover:bg-slate-50'
              }`}
            >
              <span>{tab.label}</span>
              {tab.count !== undefined && tab.count > 0 && (
                <span
                  className={`px-1.5 py-0.2 rounded-full text-[10px] font-bold ${
                    activeTab === tab.key ? 'bg-white/20 text-white' : 'bg-slate-100 text-slate-700'
                  }`}
                >
                  {tab.count}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Search */}
        <div className="relative w-full md:w-80">
          <Search className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search tickets..."
            className="w-full pl-9 pr-3 py-1.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
          />
        </div>
      </div>

      {/* ── Clean Tickets Table ── */}
      <Card className="overflow-hidden border-slate-200 bg-white shadow-xs">
        {loading ? (
          <div className="py-20 flex flex-col items-center justify-center gap-3">
            <div className="h-8 w-8 animate-spin rounded-full border-3 border-[#0453cd] border-t-transparent" />
            <p className="text-xs text-slate-500 font-medium">Loading tickets...</p>
          </div>
        ) : error ? (
          <div className="p-8 text-center space-y-3">
            <div className="h-10 w-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center mx-auto">
              <AlertTriangle className="h-5 w-5" />
            </div>
            <p className="text-xs text-rose-700 font-semibold">{error}</p>
            <Button variant="outline" size="sm" onClick={() => loadData(true)}>
              Retry
            </Button>
          </div>
        ) : filteredTickets.length === 0 ? (
          <div className="py-20 text-center space-y-3">
            <div className="h-12 w-12 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-600 flex items-center justify-center mx-auto">
              <CheckCircle2 className="h-6 w-6" />
            </div>
            <p className="text-base font-bold text-slate-800">Inbox is All Clear</p>
            <p className="text-xs text-slate-500 max-w-sm mx-auto">
              {searchQuery
                ? 'No tickets match your search.'
                : 'No active tickets found. Create a ticket if you need assistance or want to test!'}
            </p>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setIsCreateModalOpen(true)}
              className="mt-2 text-xs font-semibold text-[#0453cd] border-blue-200"
            >
              + Create a Ticket
            </Button>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="bg-slate-50 border-b border-slate-200 text-xs font-semibold text-slate-500">
                  <th className="py-3 px-4">Ticket</th>
                  <th className="py-3 px-4">Subject & Description</th>
                  <th className="py-3 px-4">Reported By</th>
                  <th className="py-3 px-3">Status</th>
                  <th className="py-3 px-4 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs">
                {filteredTickets.map((ticket) => (
                  <tr key={ticket.id} className="hover:bg-slate-50/80 transition-colors group">
                    {/* Ticket Reference */}
                    <td className="py-3.5 px-4 font-mono font-bold text-[#0453cd] whitespace-nowrap">
                      <Link href={`/helpdesk/tickets/${ticket.id}`} className="hover:underline flex items-center gap-1.5">
                        <span>{ticket.id}</span>
                        {ticket.is_user_submitted === 1 ? (
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-blue-50 text-[#0453cd] border border-blue-200 font-semibold inline-flex items-center gap-1">
                            <User className="h-3 w-3" />
                            <span>User</span>
                          </span>
                        ) : (
                          <span className="text-[10px] px-2 py-0.5 rounded-full bg-slate-100 text-slate-600 border border-slate-200 font-medium inline-flex items-center gap-1">
                            <Cpu className="h-3 w-3" />
                            <span>System</span>
                          </span>
                        )}
                      </Link>
                      <div className="text-[11px] font-sans font-normal text-slate-400 mt-0.5">
                        {ticket.created_at ? new Date(ticket.created_at).toLocaleDateString() : '—'}
                      </div>
                    </td>

                    {/* Subject */}
                    <td className="py-3.5 px-4 max-w-md">
                      <div className="font-semibold text-slate-900 text-sm truncate" title={ticket.title}>
                        {ticket.title}
                      </div>
                      <div className="text-xs text-slate-500 truncate mt-0.5" title={ticket.error_message}>
                        {ticket.error_message}
                      </div>
                    </td>

                    {/* Reported By */}
                    <td className="py-3.5 px-4 whitespace-nowrap">
                      {ticket.user_email ? (
                        <div className="font-medium text-slate-800">{ticket.user_email}</div>
                      ) : (
                        <span className="text-slate-400">System Sensor</span>
                      )}
                    </td>

                    {/* Status */}
                    <td className="py-3.5 px-3 whitespace-nowrap">
                      {statusBadge(ticket.status)}
                    </td>

                    {/* Actions */}
                    <td className="py-3.5 px-4 whitespace-nowrap text-right">
                      <div className="flex items-center justify-end gap-2">
                        <Link href={`/helpdesk/tickets/${ticket.id}`}>
                          <Button variant="outline" size="sm" className="h-8 px-3 text-xs font-semibold">
                            <span>View</span>
                            <ChevronRight className="h-3 w-3 ml-1" />
                          </Button>
                        </Link>

                        <button
                          type="button"
                          onClick={() => setDeletingTicketId(ticket.id)}
                          title="Delete Ticket"
                          className="h-8 w-8 rounded-lg border border-slate-200 text-slate-400 hover:text-rose-600 hover:border-rose-200 hover:bg-rose-50 flex items-center justify-center transition-colors cursor-pointer"
                        >
                          <Trash2 className="h-3.5 w-3.5" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        <div className="px-4 py-3 bg-slate-50 border-t border-slate-100 flex items-center justify-between text-xs text-slate-500">
          <span>
            Showing <strong className="text-slate-800">{filteredTickets.length}</strong> of{' '}
            <strong className="text-slate-800">{totalTickets}</strong> tickets
          </span>
          <span className="text-slate-400">PixelMint Studio MVS</span>
        </div>
      </Card>

      {/* ── Single Ticket Delete Confirmation Dialog ── */}
      {deletingTicketId && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-xs p-4 animate-in fade-in">
          <div className="bg-white rounded-2xl max-w-sm w-full p-5 shadow-xl border border-slate-200 space-y-4">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center shrink-0">
                <Trash2 className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900">Delete Ticket?</h3>
                <p className="text-xs text-slate-500">This will permanently remove ticket {deletingTicketId}.</p>
              </div>
            </div>

            <p className="text-xs text-slate-600">
              Are you sure you want to delete this ticket? All associated investigation comments and event logs will also be removed.
            </p>

            <div className="flex items-center justify-end gap-2 pt-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setDeletingTicketId(null)}
                disabled={isDeleting}
                className="text-xs"
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                onClick={() => handleDeleteTicket(deletingTicketId)}
                disabled={isDeleting}
                className="bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold px-4"
              >
                {isDeleting ? 'Deleting...' : 'Delete Permanently'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* ── Clear All Confirmation Dialog ── */}
      {showClearAllConfirm && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/40 backdrop-blur-xs p-4 animate-in fade-in">
          <div className="bg-white rounded-2xl max-w-sm w-full p-5 shadow-xl border border-slate-200 space-y-4">
            <div className="flex items-center gap-3">
              <div className="h-10 w-10 rounded-xl bg-rose-50 text-rose-600 flex items-center justify-center shrink-0">
                <AlertTriangle className="h-5 w-5" />
              </div>
              <div>
                <h3 className="text-sm font-bold text-slate-900">Clear All Tickets?</h3>
                <p className="text-xs text-slate-500">This will wipe all {totalTickets} tickets from the database.</p>
              </div>
            </div>

            <p className="text-xs text-slate-600">
              This action cannot be undone. All active and resolved tickets, error reports, and email logs will be permanently deleted.
            </p>

            <div className="flex items-center justify-end gap-2 pt-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowClearAllConfirm(false)}
                disabled={isDeleting}
                className="text-xs"
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                onClick={handleClearAllTickets}
                disabled={isDeleting}
                className="bg-rose-600 hover:bg-rose-700 text-white text-xs font-semibold px-4"
              >
                {isDeleting ? 'Clearing...' : 'Yes, Clear All'}
              </Button>
            </div>
          </div>
        </div>
      )}

      {/* ── Create Ticket Modal ── */}
      <CreateTicketModal
        isOpen={isCreateModalOpen}
        onClose={() => setIsCreateModalOpen(false)}
        onSuccess={() => {
          loadData(true);
        }}
      />
    </AdminShell>
  );
}

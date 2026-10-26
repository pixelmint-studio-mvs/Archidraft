'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { formatDateTime } from '@/lib/dateUtils';
import { GlobalAssignment, AssignmentStatus } from '@/lib/types';
import {
  History,
  UserCheck,
  Search,
  Download,
  AlertCircle,
  ExternalLink,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  FolderKanban,
  PenTool,
  Clock,
  CheckCircle2,
  XCircle,
  RefreshCw,
  Layers,
} from 'lucide-react';

const PAGE_SIZE = 10;

const STATUS_TABS: { label: string; value: string }[] = [
  { label: 'All Records', value: 'ALL' },
  { label: 'Accepted', value: 'ACCEPTED' },
  { label: 'Pending', value: 'PENDING' },
  { label: 'Rejected', value: 'REJECTED' },
  { label: 'Replaced', value: 'REPLACED' },
];

export default function AssignmentHistoryPage() {
  const [assignments, setAssignments] = useState<GlobalAssignment[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const [selectedStatus, setSelectedStatus] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [page, setPage] = useState<number>(1);

  const loadHistory = async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getAdminAssignments({
        status: selectedStatus === 'ALL' ? undefined : selectedStatus,
      });
      setAssignments(data);
      setPage(1);
    } catch (err: any) {
      setError(err.message || 'Failed to query global assignment history from backend.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadHistory();
  }, [selectedStatus]);

  // Client-side search filtering across records
  const filteredAssignments = useMemo(() => {
    if (!searchQuery.trim()) return assignments;
    const query = searchQuery.toLowerCase();
    return assignments.filter((a) => {
      const matchProject =
        a.project_name?.toLowerCase().includes(query) ||
        a.project_id.toLowerCase().includes(query);
      const matchDraughtsman =
        a.draughtsman_name?.toLowerCase().includes(query) ||
        a.draughtsman_email?.toLowerCase().includes(query) ||
        a.draughtsman_id.toLowerCase().includes(query);
      const matchClient = a.client_name?.toLowerCase().includes(query);
      const matchId = a.id.toLowerCase().includes(query);
      return matchProject || matchDraughtsman || matchClient || matchId;
    });
  }, [assignments, searchQuery]);

  // Pagination calculation
  const totalPages = Math.max(1, Math.ceil(filteredAssignments.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const paginatedRecords = useMemo(() => {
    const start = (safePage - 1) * PAGE_SIZE;
    return filteredAssignments.slice(start, start + PAGE_SIZE);
  }, [filteredAssignments, safePage]);

  // Aggregate stats
  const totalCount = assignments.length;
  const acceptedCount = assignments.filter((a) => a.status === 'ACCEPTED').length;
  const pendingCount = assignments.filter((a) => a.status === 'PENDING').length;
  const rejectedCount = assignments.filter((a) => a.status === 'REJECTED').length;
  const replacedCount = assignments.filter((a) => a.status === 'REPLACED').length;

  const exportHistoryCSV = () => {
    let csv = 'Assignment ID,Project ID,Project Name,Discipline,Draughtsman,Status,Assigned At,Updated At\n';
    for (const a of filteredAssignments) {
      csv += `"${a.id}","${a.project_id}","${a.project_name || 'Project'}","${a.drawing_type || ''}","${a.draughtsman_name || a.draughtsman_id}","${a.status}","${a.created_at}","${a.updated_at || ''}"\n`;
    }
    const blob = new Blob([csv], { type: 'text/csv' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = `assignment_history_${Date.now()}.csv`;
    link.click();
    URL.revokeObjectURL(url);
  };

  const getStatusBadge = (status: AssignmentStatus | string) => {
    switch (status) {
      case 'ACCEPTED':
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-emerald-50 text-emerald-700 border border-emerald-200">
            <CheckCircle2 className="h-3 w-3" />
            <span>ACCEPTED</span>
          </span>
        );
      case 'PENDING':
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-amber-50 text-amber-700 border border-amber-200">
            <Clock className="h-3 w-3" />
            <span>PENDING</span>
          </span>
        );
      case 'REJECTED':
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-rose-50 text-rose-700 border border-rose-200">
            <XCircle className="h-3 w-3" />
            <span>REJECTED</span>
          </span>
        );
      case 'REPLACED':
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-purple-50 text-purple-700 border border-purple-200">
            <RefreshCw className="h-3 w-3" />
            <span>REPLACED</span>
          </span>
        );
      default:
        return (
          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-bold px-2 py-0.5 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
            <span>{status}</span>
          </span>
        );
    }
  };

  return (
    <AdminShell
      title="Global Assignment History"
      subtitle="Complete historical ledger of project assignments, draughtsman acceptances, rejections, and reassignments."
      onRefresh={() => loadHistory(true)}
      isRefreshing={refreshing}
    >
      <div className="space-y-6">
        {/* ── Top Telemetry & Navigation Tabs (Stitch Spec) ── */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-3">
          <div className="flex items-center gap-2">
            <Link
              href="/assignments"
              className="px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide text-slate-600 hover:text-slate-900 hover:bg-slate-100 transition-all flex items-center gap-2"
            >
              <UserCheck className="h-3.5 w-3.5 text-slate-400" />
              <span>01. Live Queue & Dispatch</span>
            </Link>
            <Link
              href="/assignments/history"
              className="px-4 py-2 rounded-lg text-xs font-semibold font-mono tracking-wide bg-[#0d1c32] text-white shadow-xs flex items-center gap-2"
            >
              <History className="h-3.5 w-3.5 text-[#0453cd]" />
              <span>02. Global Assignment History</span>
              <span className="bg-[#0453cd] text-white text-[10px] px-1.5 py-0.2 rounded-full font-bold ml-1">
                {totalCount}
              </span>
            </Link>
          </div>

          <div className="flex items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={exportHistoryCSV}
              disabled={filteredAssignments.length === 0}
              className="flex items-center gap-1.5 text-xs font-mono"
            >
              <Download className="h-3.5 w-3.5" />
              <span>Export CSV</span>
            </Button>
          </div>
        </div>

        {/* ── Stats Strip ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold mb-1">
              Total Dispatches
            </p>
            <p className="text-2xl font-bold font-mono text-slate-900">{totalCount}</p>
            <p className="text-[11px] text-slate-500 font-mono mt-1">Cross-project ledger records</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold mb-1">
              Accepted
            </p>
            <p className="text-2xl font-bold font-mono text-emerald-700">{acceptedCount}</p>
            <p className="text-[11px] text-emerald-600 font-mono mt-1">Confirmed assignments</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold mb-1">
              Pending Acceptance
            </p>
            <p className="text-2xl font-bold font-mono text-amber-700">{pendingCount}</p>
            <p className="text-[11px] text-amber-600 font-mono mt-1">Awaiting talent response</p>
          </div>

          <div className="p-4 rounded-xl border border-slate-200 bg-white soft-elevation">
            <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-semibold mb-1">
              Reassigned / Replaced
            </p>
            <p className="text-2xl font-bold font-mono text-purple-700">{replacedCount}</p>
            <p className="text-[11px] text-purple-600 font-mono mt-1">Reassigned projects</p>
          </div>
        </div>

        {error && (
          <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-3">
            <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
            <span className="flex-1">{error}</span>
            <Button variant="outline" size="sm" onClick={() => loadHistory(true)}>
              Retry
            </Button>
          </div>
        )}

        {/* ── Status Tabs & Search Bar ── */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div className="flex gap-1 border-b border-slate-200 pb-0 overflow-x-auto w-full sm:w-auto scrollbar-none">
            {STATUS_TABS.map((tab) => {
              const count =
                tab.value === 'ALL' ? totalCount
                : tab.value === 'ACCEPTED' ? acceptedCount
                : tab.value === 'PENDING' ? pendingCount
                : tab.value === 'REJECTED' ? rejectedCount
                : replacedCount;
              const isActive = selectedStatus === tab.value;
              return (
                <button
                  key={tab.value}
                  onClick={() => setSelectedStatus(tab.value)}
                  className={`px-3 py-2 text-xs font-mono font-semibold whitespace-nowrap transition-all border-b-2 ${
                    isActive
                      ? 'text-slate-900 border-[#0453cd]'
                      : 'text-slate-500 border-transparent hover:text-slate-800'
                  }`}
                >
                  {tab.label}
                  <span className="ml-1.5 text-[10px] font-mono opacity-80">({count})</span>
                </button>
              );
            })}
          </div>

          <div className="relative w-full sm:max-w-64">
            <Search className="h-3.5 w-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search history records…"
              className="w-full pl-9 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
            />
          </div>
        </div>

        {/* ── Historical Ledger Table ── */}
        <Card className="bg-white border-slate-200 soft-elevation overflow-hidden">
          {loading ? (
            <div className="flex flex-col items-center justify-center p-20">
              <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
              <p className="text-xs text-slate-500 mt-3 font-mono">Querying historical assignment records…</p>
            </div>
          ) : filteredAssignments.length === 0 ? (
            <div className="p-16 text-center">
              <History className="h-10 w-10 text-slate-300 mx-auto mb-3" />
              <p className="text-sm font-semibold text-slate-700">No assignment records found</p>
              <p className="text-xs text-slate-500 mt-1 font-mono">
                {searchQuery ? `No results match "${searchQuery}".` : 'No assignments match the selected status filter.'}
              </p>
            </div>
          ) : (
            <>
              <div className="overflow-x-auto">
                <table className="w-full text-left text-xs">
                  <thead className="bg-slate-50/80 border-b border-slate-200 text-slate-600 font-mono text-[10px] uppercase tracking-wider">
                    <tr>
                      <th className="py-3 px-4">Assignment ID</th>
                      <th className="py-3 px-4">Project</th>
                      <th className="py-3 px-4">Assigned Draughtsman</th>
                      <th className="py-3 px-4">Status</th>
                      <th className="py-3 px-4">Dispatched At</th>
                      <th className="py-3 px-4">Updated At</th>
                      <th className="py-3 px-4 text-right">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100 font-sans">
                    {paginatedRecords.map((record) => (
                      <tr key={record.id} className="hover:bg-slate-50/80 transition-colors">
                        {/* Assignment ID */}
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-700">
                          {record.id.substring(0, 10)}…
                        </td>

                        {/* Project Details */}
                        <td className="py-3 px-4">
                          <Link
                            href={`/projects/${record.project_id}`}
                            className="font-bold text-slate-900 hover:text-[#0453cd] transition-colors block truncate max-w-xs"
                          >
                            {record.project_name || 'Architectural Project'}
                          </Link>
                          <div className="flex items-center gap-2 text-[10px] font-mono text-slate-500 mt-0.5">
                            <span>{record.project_id.substring(0, 8)}</span>
                            {record.drawing_type && <span>· {record.drawing_type}</span>}
                            {record.project_status && (
                              <Badge status={record.project_status} size="sm" />
                            )}
                          </div>
                        </td>

                        {/* Draughtsman Details */}
                        <td className="py-3 px-4">
                          <div className="min-w-0">
                            <p className="font-semibold text-slate-900 truncate">
                              {record.draughtsman_name || 'Draughtsman'}
                            </p>
                            <p className="text-[10px] font-mono text-slate-500 truncate">
                              {record.draughtsman_email || record.draughtsman_id.substring(0, 10)}
                            </p>
                          </div>
                        </td>

                        {/* Status Badge */}
                        <td className="py-3 px-4">{getStatusBadge(record.status)}</td>

                        {/* Dispatched timestamp */}
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-600 whitespace-nowrap">
                          {formatDateTime(record.created_at)}
                        </td>

                        {/* Updated timestamp */}
                        <td className="py-3 px-4 font-mono text-[11px] text-slate-600 whitespace-nowrap">
                          {formatDateTime(record.updated_at)}
                        </td>

                        {/* Actions */}
                        <td className="py-3 px-4 text-right">
                          <Link
                            href={`/projects/${record.project_id}`}
                            className="inline-flex items-center gap-1 text-[11px] font-mono font-semibold text-[#0453cd] hover:text-[#0342a6] px-2 py-1 rounded hover:bg-blue-50 transition-colors"
                          >
                            <span>Inspect</span>
                            <ExternalLink className="h-3 w-3" />
                          </Link>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              {/* ── Pagination Controls ── */}
              {totalPages > 1 && (
                <div className="px-5 py-3 border-t border-slate-100 flex items-center justify-between gap-3 flex-wrap">
                  <p className="text-[10px] font-mono text-slate-500">
                    Showing <span className="text-slate-800 font-semibold">{(safePage - 1) * PAGE_SIZE + 1}–{Math.min(safePage * PAGE_SIZE, filteredAssignments.length)}</span> of{' '}
                    <span className="text-slate-800 font-semibold">{filteredAssignments.length}</span> records
                  </p>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => setPage(1)}
                      disabled={safePage === 1}
                      className="h-7 w-7 rounded border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-30 disabled:cursor-not-allowed flex items-center justify-center"
                      title="First Page"
                    >
                      <ChevronsLeft className="h-3.5 w-3.5" />
                    </button>
                    <button
                      onClick={() => setPage((p) => Math.max(1, p - 1))}
                      disabled={safePage === 1}
                      className="h-7 w-7 rounded border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-30 disabled:cursor-not-allowed flex items-center justify-center"
                      title="Previous Page"
                    >
                      <ChevronLeft className="h-3.5 w-3.5" />
                    </button>
                    <span className="px-2 text-xs font-mono font-bold text-slate-800">
                      {safePage} / {totalPages}
                    </span>
                    <button
                      onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                      disabled={safePage === totalPages}
                      className="h-7 w-7 rounded border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-30 disabled:cursor-not-allowed flex items-center justify-center"
                      title="Next Page"
                    >
                      <ChevronRight className="h-3.5 w-3.5" />
                    </button>
                    <button
                      onClick={() => setPage(totalPages)}
                      disabled={safePage === totalPages}
                      className="h-7 w-7 rounded border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:opacity-30 disabled:cursor-not-allowed flex items-center justify-center"
                      title="Last Page"
                    >
                      <ChevronsRight className="h-3.5 w-3.5" />
                    </button>
                  </div>
                </div>
              )}
            </>
          )}
        </Card>
      </div>
    </AdminShell>
  );
}

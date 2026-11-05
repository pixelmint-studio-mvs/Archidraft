'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { adminApi } from '@/lib/api';
import { EngineerProjectStatusItem, ProjectStatus } from '@/lib/types';
import {
  HardHat,
  Search,
  RefreshCw,
  FolderKanban,
  Building,
  Mail,
  Phone,
  AlertCircle,
  ExternalLink,
  Layers,
  Clock,
  CheckCircle2,
  XCircle,
  FileText,
  Filter,
  Calendar,
  ShieldCheck,
  ChevronRight,
  TrendingUp,
} from 'lucide-react';

export interface EngineerProjectStatusModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export type AcceptanceCategory = 'ALL' | 'ACCEPTED' | 'PENDING' | 'DECLINED' | 'COMMISSIONED';

export function getAcceptanceCategory(status: ProjectStatus): {
  category: 'ACCEPTED' | 'PENDING' | 'DECLINED' | 'COMMISSIONED';
  label: string;
  badgeClass: string;
  dotColor: string;
} {
  switch (status) {
    case 'IN_PROGRESS':
    case 'UNDER_CLIENT_REVIEW':
    case 'UNDER_ENGINEER_REVIEW':
      return {
        category: 'ACCEPTED',
        label: 'Accepted (In Progress)',
        badgeClass: 'bg-blue-50 text-[#0453cd] border-blue-200',
        dotColor: 'bg-[#0453cd]',
      };
    case 'COMPLETED':
      return {
        category: 'ACCEPTED',
        label: 'Accepted (Completed)',
        badgeClass: 'bg-emerald-50 text-emerald-700 border-emerald-200',
        dotColor: 'bg-emerald-500',
      };
    case 'WAITING_ACCEPTANCE':
      return {
        category: 'PENDING',
        label: 'Awaiting Response',
        badgeClass: 'bg-amber-50 text-amber-700 border-amber-200',
        dotColor: 'bg-amber-500 animate-pulse',
      };
    case 'CANCELLED':
      return {
        category: 'DECLINED',
        label: 'Declined / Cancelled',
        badgeClass: 'bg-rose-50 text-rose-700 border-rose-200',
        dotColor: 'bg-rose-500',
      };
    case 'WAITING_ASSIGNMENT':
      return {
        category: 'COMMISSIONED',
        label: 'Waiting Draughtsman',
        badgeClass: 'bg-purple-50 text-purple-700 border-purple-200',
        dotColor: 'bg-purple-500',
      };
    case 'SUBMITTED':
    case 'DRAFT':
    default:
      return {
        category: 'COMMISSIONED',
        label: 'Submitted (Intake)',
        badgeClass: 'bg-slate-100 text-slate-700 border-slate-200',
        dotColor: 'bg-slate-400',
      };
  }
}

export function formatDateTime(isoString?: string): string {
  if (!isoString) return '—';
  try {
    const d = new Date(isoString);
    if (isNaN(d.getTime())) return isoString;
    return d.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return isoString;
  }
}

export function EngineerProjectStatusModal({
  isOpen,
  onClose,
}: EngineerProjectStatusModalProps) {
  const [items, setItems] = useState<EngineerProjectStatusItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Filters & Search
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [acceptanceFilter, setAcceptanceFilter] = useState<AcceptanceCategory>('ALL');
  const [projectStatusFilter, setProjectStatusFilter] = useState<string>('ALL');
  const [engineerFilter, setEngineerFilter] = useState<string>('ALL');

  // Pagination
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 8;

  const loadStatuses = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getEngineerProjectStatuses();
      setItems(data || []);
    } catch (err: any) {
      console.error('Failed to load engineer project statuses:', err);
      setError(err.message || 'Failed to retrieve engineer/architect project status records');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    if (isOpen) {
      setSearchQuery('');
      setAcceptanceFilter('ALL');
      setProjectStatusFilter('ALL');
      setEngineerFilter('ALL');
      setCurrentPage(1);
      loadStatuses();
    }
  }, [isOpen]);

  // Unique engineers list for dropdown
  const uniqueEngineers = useMemo(() => {
    const map = new Map<string, { name: string; identification_number?: string }>();
    items.forEach((item) => {
      if (item.engineer_id && !map.has(item.engineer_id)) {
        map.set(item.engineer_id, {
          name: item.engineer_name || item.engineer_email || item.engineer_id,
          identification_number: item.engineer_identification_number,
        });
      }
    });
    return Array.from(map.entries()).map(([id, info]) => ({
      id,
      name: info.name,
      identification_number: info.identification_number,
    }));
  }, [items]);

  // KPI calculations
  const kpis = useMemo(() => {
    let total = items.length;
    let accepted = 0;
    let pending = 0;
    let completed = 0;
    let declined = 0;

    items.forEach((item) => {
      const { category } = getAcceptanceCategory(item.project_status);
      if (item.project_status === 'COMPLETED') completed++;
      else if (category === 'ACCEPTED') accepted++;
      else if (category === 'PENDING') pending++;
      else if (category === 'DECLINED') declined++;
    });

    return { total, accepted, pending, completed, declined };
  }, [items]);

  // Filtered dataset
  const filteredItems = useMemo(() => {
    return items.filter((item) => {
      // Acceptance category filter
      if (acceptanceFilter !== 'ALL') {
        const { category } = getAcceptanceCategory(item.project_status);
        if (category !== acceptanceFilter) return false;
      }

      // Project status filter
      if (projectStatusFilter !== 'ALL' && item.project_status !== projectStatusFilter) {
        return false;
      }

      // Engineer filter
      if (engineerFilter !== 'ALL' && item.engineer_id !== engineerFilter) {
        return false;
      }

      // Search query filter
      if (!searchQuery.trim()) return true;
      const q = searchQuery.toLowerCase();
      const engIdent = (item.engineer_identification_number || '').toLowerCase();
      const engName = (item.engineer_name || '').toLowerCase();
      const engEmail = (item.engineer_email || '').toLowerCase();
      const engCompany = (item.engineer_company || '').toLowerCase();
      const prjName = (item.project_name || '').toLowerCase();
      const prjId = (item.project_id || '').toLowerCase();
      const drwType = (item.drawing_type || '').toLowerCase();

      return (
        engIdent.includes(q) ||
        engName.includes(q) ||
        engEmail.includes(q) ||
        engCompany.includes(q) ||
        prjName.includes(q) ||
        prjId.includes(q) ||
        drwType.includes(q)
      );
    });
  }, [items, searchQuery, acceptanceFilter, projectStatusFilter, engineerFilter]);

  // Pagination
  const totalPages = Math.max(1, Math.ceil(filteredItems.length / pageSize));
  const paginatedItems = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredItems.slice(start, start + pageSize);
  }, [filteredItems, currentPage, pageSize]);

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Engineer/Architect Project Assignment Status"
      description="Centralized live status tracking, acceptance verification, and assignment progress for registered Engineers/Architects"
      maxWidth="4xl"
    >
      <div className="space-y-5">
        {/* Error Alert */}
        {error && (
          <div className="p-3.5 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-xs font-mono flex items-center justify-between gap-3">
            <div className="flex items-center gap-2">
              <AlertCircle className="h-4 w-4 shrink-0 text-rose-600" />
              <span>{error}</span>
            </div>
            <Button variant="outline" size="sm" onClick={() => loadStatuses(true)} className="text-xs font-mono">
              Retry
            </Button>
          </div>
        )}

        {/* ─── KPI Metric Cards Row ──────────────────────────────────── */}
        <div className="grid grid-cols-2 sm:grid-cols-5 gap-2.5">
          <Card technicalCorners className="p-3 bg-white border-slate-200 shadow-2xs">
            <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Total Assigned</p>
            <p className="text-xl font-bold font-mono text-slate-900 mt-1">{kpis.total}</p>
            <p className="text-[10px] text-slate-400 font-mono mt-0.5">Engineer/Architect projects</p>
          </Card>

          <Card technicalCorners className="p-3 bg-white border-slate-200 shadow-2xs">
            <div className="flex items-center justify-between">
              <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">In Progress</p>
              <span className="h-2 w-2 rounded-full bg-[#0453cd]" />
            </div>
            <p className="text-xl font-bold font-mono text-[#0453cd] mt-1">{kpis.accepted}</p>
            <p className="text-[10px] text-slate-400 font-mono mt-0.5">Accepted & active</p>
          </Card>

          <Card technicalCorners className="p-3 bg-white border-slate-200 shadow-2xs">
            <div className="flex items-center justify-between">
              <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Awaiting Response</p>
              <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
            </div>
            <p className="text-xl font-bold font-mono text-amber-700 mt-1">{kpis.pending}</p>
            <p className="text-[10px] text-slate-400 font-mono mt-0.5">Waiting acceptance</p>
          </Card>

          <Card technicalCorners className="p-3 bg-white border-slate-200 shadow-2xs">
            <div className="flex items-center justify-between">
              <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Completed</p>
              <span className="h-2 w-2 rounded-full bg-emerald-500" />
            </div>
            <p className="text-xl font-bold font-mono text-emerald-700 mt-1">{kpis.completed}</p>
            <p className="text-[10px] text-slate-400 font-mono mt-0.5">Delivered & closed</p>
          </Card>

          <Card technicalCorners className="p-3 bg-white border-slate-200 shadow-2xs col-span-2 sm:col-span-1">
            <div className="flex items-center justify-between">
              <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Declined / Closed</p>
              <span className="h-2 w-2 rounded-full bg-rose-500" />
            </div>
            <p className="text-xl font-bold font-mono text-rose-700 mt-1">{kpis.declined}</p>
            <p className="text-[10px] text-slate-400 font-mono mt-0.5">Cancelled status</p>
          </Card>
        </div>

        {/* ─── Search & Multi-Filter Toolbar ─────────────────────────── */}
        <div className="p-3.5 rounded-xl bg-slate-50 border border-slate-200 space-y-3">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <div className="relative flex-1">
              <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => {
                  setSearchQuery(e.target.value);
                  setCurrentPage(1);
                }}
                placeholder="Search by engineer/architect name, firm, project title, or ID..."
                className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd] focus:border-[#0453cd] shadow-2xs"
              />
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={() => loadStatuses(true)}
              disabled={refreshing}
              className="flex items-center gap-1.5 font-mono text-xs border-slate-200 bg-white shrink-0"
            >
              <RefreshCw className={`h-3.5 w-3.5 text-[#0453cd] ${refreshing ? 'animate-spin' : ''}`} />
              <span>{refreshing ? 'Refreshing...' : 'Refresh Live Status'}</span>
            </Button>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-1">
            {/* Acceptance Status Filter */}
            <div>
              <label className="block text-[10px] font-mono uppercase font-bold text-slate-500 mb-1">
                Acceptance State
              </label>
              <select
                value={acceptanceFilter}
                onChange={(e) => {
                  setAcceptanceFilter(e.target.value as AcceptanceCategory);
                  setCurrentPage(1);
                }}
                className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-800 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              >
                <option value="ALL">All Acceptance States</option>
                <option value="ACCEPTED">Accepted (Active / Completed)</option>
                <option value="PENDING">Awaiting Response (Pending)</option>
                <option value="DECLINED">Declined / Cancelled</option>
                <option value="COMMISSIONED">Commissioned (Intake / Queue)</option>
              </select>
            </div>

            {/* Project Lifecycle Status Filter */}
            <div>
              <label className="block text-[10px] font-mono uppercase font-bold text-slate-500 mb-1">
                Project Lifecycle Status
              </label>
              <select
                value={projectStatusFilter}
                onChange={(e) => {
                  setProjectStatusFilter(e.target.value);
                  setCurrentPage(1);
                }}
                className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-800 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              >
                <option value="ALL">All Project Statuses</option>
                <option value="SUBMITTED">SUBMITTED</option>
                <option value="WAITING_ASSIGNMENT">WAITING_ASSIGNMENT</option>
                <option value="WAITING_ACCEPTANCE">WAITING_ACCEPTANCE</option>
                <option value="IN_PROGRESS">IN_PROGRESS</option>
                <option value="UNDER_CLIENT_REVIEW">UNDER_CLIENT_REVIEW</option>
                <option value="COMPLETED">COMPLETED</option>
                <option value="CANCELLED">CANCELLED</option>
              </select>
            </div>

            {/* Engineer Filter */}
            <div>
              <label className="block text-[10px] font-mono uppercase font-bold text-slate-500 mb-1">
                Filter by Engineer/Architect
              </label>
              <select
                value={engineerFilter}
                onChange={(e) => {
                  setEngineerFilter(e.target.value);
                  setCurrentPage(1);
                }}
                className="w-full px-2.5 py-1.5 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-800 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
              >
                <option value="ALL">All Registered Engineers/Architects ({uniqueEngineers.length})</option>
                {uniqueEngineers.map((eng) => (
                  <option key={eng.id} value={eng.id}>
                    {eng.identification_number ? `${eng.identification_number} — ${eng.name}` : eng.name}
                  </option>
                ))}
              </select>
            </div>
          </div>
        </div>

        {/* ─── Status Overview Table ─────────────────────────────────── */}
        <Card technicalCorners className="bg-white border-slate-200 shadow-2xs overflow-hidden">
          {loading ? (
            <div className="flex flex-col items-center justify-center p-16">
              <RefreshCw className="h-7 w-7 text-[#0453cd] animate-spin mb-3" />
              <p className="text-xs text-slate-500 font-mono">Loading engineer/architect project assignments…</p>
            </div>
          ) : filteredItems.length === 0 ? (
            <div className="p-14 text-center">
              <FolderKanban className="h-10 w-10 text-slate-300 mx-auto mb-3" />
              <p className="text-sm font-semibold text-slate-700">No Engineer/Architect Project Assignments Found</p>
              <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto font-mono">
                {searchQuery || acceptanceFilter !== 'ALL' || projectStatusFilter !== 'ALL' || engineerFilter !== 'ALL'
                  ? 'No assignments match your current filters. Try resetting search or filter criteria.'
                  : 'No projects are currently assigned to engineers/architects.'}
              </p>
            </div>
          ) : (
            <div className="overflow-x-auto w-full max-w-full">
              <table className="w-full text-left text-xs min-w-[850px]">
                <thead className="bg-slate-50 text-slate-500 font-mono font-semibold uppercase tracking-wider border-b border-slate-200 text-[10px]">
                  <tr>
                    <th className="px-4 py-3">ID Number</th>
                    <th className="px-4 py-3">Engineer/Architect</th>
                    <th className="px-4 py-3">Assigned Project</th>
                    <th className="px-4 py-3">Assignment Date</th>
                    <th className="px-4 py-3">Acceptance Status</th>
                    <th className="px-4 py-3">Project Status</th>
                    <th className="px-4 py-3">Last Update</th>
                    <th className="px-4 py-3">Revisions / Progress</th>
                    <th className="px-4 py-3 text-right">Action</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100 font-mono">
                  {paginatedItems.map((item) => {
                    const acceptance = getAcceptanceCategory(item.project_status);

                    return (
                      <tr key={item.project_id} className="hover:bg-slate-50/70 transition-colors">
                        {/* ID Number */}
                        <td className="px-4 py-3.5 whitespace-nowrap">
                          <span className="inline-flex items-center px-2 py-0.5 rounded text-xs font-mono font-bold bg-blue-50 text-[#0453cd] border border-blue-200">
                            {item.engineer_identification_number || 'Pending'}
                          </span>
                        </td>

                        {/* Engineer Details */}
                        <td className="px-4 py-3.5">
                          <div className="flex items-center gap-2.5">
                            <div className="h-8 w-8 rounded-lg bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xs shrink-0">
                              {(item.engineer_name || 'E').charAt(0).toUpperCase()}
                            </div>
                            <div className="min-w-0">
                              <p className="font-bold text-slate-900 text-xs truncate max-w-[150px]">
                                {item.engineer_name || 'Unnamed Engineer/Architect'}
                              </p>
                              {item.engineer_company ? (
                                <p className="text-[10px] text-slate-500 truncate max-w-[150px] flex items-center gap-1">
                                  <Building className="h-2.5 w-2.5 text-slate-400 shrink-0" />
                                  <span>{item.engineer_company}</span>
                                </p>
                              ) : (
                                <p className="text-[10px] text-slate-400 truncate max-w-[150px]">
                                  {item.engineer_email}
                                </p>
                              )}
                            </div>
                          </div>
                        </td>

                        {/* Project Details */}
                        <td className="px-4 py-3.5">
                          <div className="min-w-0">
                            <p className="font-bold text-slate-900 text-xs truncate max-w-[180px]">
                              {item.project_name}
                            </p>
                            <div className="flex items-center gap-2 text-[10px] text-slate-500 mt-0.5">
                              <span className="text-[#0453cd] font-semibold">{item.project_id}</span>
                              <span>•</span>
                              <span className="truncate max-w-[100px]">{item.drawing_type}</span>
                            </div>
                          </div>
                        </td>

                        {/* Assigned Date & Time */}
                        <td className="px-4 py-3.5 text-slate-600 text-[11px] whitespace-nowrap">
                          <div className="flex items-center gap-1.5">
                            <Calendar className="h-3 w-3 text-slate-400 shrink-0" />
                            <span>{formatDateTime(item.assigned_at || item.submitted_at || item.created_at)}</span>
                          </div>
                        </td>

                        {/* Acceptance Status Badge */}
                        <td className="px-4 py-3.5 whitespace-nowrap">
                          <span
                            className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[10px] font-semibold border ${acceptance.badgeClass}`}
                          >
                            <span className={`h-1.5 w-1.5 rounded-full ${acceptance.dotColor}`} />
                            <span>{acceptance.label}</span>
                          </span>
                        </td>

                        {/* Current Project Status */}
                        <td className="px-4 py-3.5 whitespace-nowrap">
                          <span
                            className={`inline-block px-2 py-0.5 rounded text-[10px] font-bold border ${
                              item.project_status === 'COMPLETED'
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                                : item.project_status === 'IN_PROGRESS'
                                ? 'bg-blue-50 text-[#0453cd] border-blue-200'
                                : item.project_status === 'WAITING_ACCEPTANCE'
                                ? 'bg-amber-50 text-amber-700 border-amber-200'
                                : item.project_status === 'CANCELLED'
                                ? 'bg-rose-50 text-rose-700 border-rose-200'
                                : 'bg-slate-100 text-slate-700 border-slate-200'
                            }`}
                          >
                            {item.project_status}
                          </span>
                        </td>

                        {/* Last Update */}
                        <td className="px-4 py-3.5 text-slate-500 text-[10px] whitespace-nowrap">
                          <div className="flex items-center gap-1">
                            <Clock className="h-3 w-3 text-slate-400 shrink-0" />
                            <span>{formatDateTime(item.last_updated_at)}</span>
                          </div>
                        </td>

                        {/* Progress Information */}
                        <td className="px-4 py-3.5 whitespace-nowrap">
                          <div className="space-y-0.5">
                            <p className="text-[11px] text-slate-700 font-semibold">
                              Round {item.correction_round || 0} of 3
                            </p>
                            <p className="text-[10px] text-slate-400">
                              {item.drawing_versions_count || 0} CAD versions
                            </p>
                          </div>
                        </td>

                        {/* Action Link */}
                        <td className="px-4 py-3.5 text-right whitespace-nowrap">
                          <Link
                            href={`/projects/${item.project_id}`}
                            className="inline-flex items-center gap-1 text-[11px] text-[#0453cd] hover:underline bg-blue-50/70 border border-blue-200/80 px-2 py-1 rounded-md"
                          >
                            <span>Workspace</span>
                            <ExternalLink className="h-2.5 w-2.5" />
                          </Link>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}

          {/* Pagination Footer */}
          {!loading && filteredItems.length > 0 && (
            <div className="px-4 py-3 bg-slate-50 border-t border-slate-200 flex flex-col sm:flex-row items-center justify-between gap-3 text-xs font-mono text-slate-500">
              <p>
                Showing <span className="font-bold text-slate-900">{paginatedItems.length}</span> of{' '}
                <span className="font-bold text-slate-900">{filteredItems.length}</span> assignments
              </p>
              <div className="flex items-center gap-2">
                <Button
                  variant="outline"
                  size="sm"
                  disabled={currentPage <= 1}
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                  className="text-xs font-mono py-1 px-3"
                >
                  Previous
                </Button>
                <span className="text-xs font-mono px-2">
                  Page {currentPage} of {totalPages}
                </span>
                <Button
                  variant="outline"
                  size="sm"
                  disabled={currentPage >= totalPages}
                  onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                  className="text-xs font-mono py-1 px-3"
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </Card>

        {/* Modal Footer */}
        <div className="flex items-center justify-between pt-2 border-t border-slate-100">
          <p className="text-[11px] font-mono text-slate-400">
            Strictly isolated to registered Engineer/Architect accounts • D1 Database
          </p>
          <Button variant="primary" size="sm" onClick={onClose} className="bg-[#0453cd] hover:bg-blue-700 text-white font-mono text-xs px-5">
            Close Overview
          </Button>
        </div>
      </div>
    </Modal>
  );
}

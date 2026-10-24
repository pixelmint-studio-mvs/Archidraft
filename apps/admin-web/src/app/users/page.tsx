'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import { useAuth } from '@/lib/auth';
import { User } from '@/lib/types';
import {
  Search,
  Users,
  Mail,
  Phone,
  GraduationCap,
  Building,
  Calendar,
  AlertCircle,
  HardHat,
  PenTool,
  ShieldCheck,
  TrendingUp,
  BarChart3,
  UserCircle2,
  ExternalLink,
  ChevronLeft,
  ChevronRight,
  ChevronsLeft,
  ChevronsRight,
  Eye,
  FileText,
  MapPin,
  Clock,
  CheckCircle2,
  UserX,
  UserCheck,
  ShieldAlert,
} from 'lucide-react';

// ── Constants ─────────────────────────────────────────────────────────────────

const PAGE_SIZE = 10;

const ROLE_TABS: { label: string; value: string; color: string }[] = [
  { label: 'Engineers', value: 'CLIENT', color: '#818cf8' },
  { label: 'Draughtsmen', value: 'DRAUGHTSMAN', color: '#22d3ee' },
  { label: 'Students', value: 'STUDENT', color: '#34d399' },
  { label: 'Studio Admins', value: 'ADMIN', color: '#fb7185' },
  { label: 'All Users', value: 'ALL', color: '#94a3b8' },
];

// ── Pagination Controls ───────────────────────────────────────────────────────

interface PaginationProps {
  page: number;
  totalPages: number;
  total: number;
  pageSize: number;
  onPage: (p: number) => void;
  accentColor: string;
}

function Pagination({ page, totalPages, total, pageSize, onPage, accentColor }: PaginationProps) {
  if (totalPages <= 1) return null;

  const start = (page - 1) * pageSize + 1;
  const end = Math.min(page * pageSize, total);

  // Build visible page numbers (max 5 slots)
  const pages: (number | '…')[] = [];
  if (totalPages <= 7) {
    for (let i = 1; i <= totalPages; i++) pages.push(i);
  } else {
    pages.push(1);
    if (page > 3) pages.push('…');
    for (let i = Math.max(2, page - 1); i <= Math.min(totalPages - 1, page + 1); i++) {
      pages.push(i);
    }
    if (page < totalPages - 2) pages.push('…');
    pages.push(totalPages);
  }

  const btnBase =
    'h-7 min-w-[28px] px-2 rounded-lg text-[11px] font-mono font-semibold transition-all flex items-center justify-center';

  return (
    <div className="px-5 py-3 border-t border-slate-100 flex items-center justify-between gap-3 flex-wrap">
      {/* Record range */}
      <p className="text-[10px] font-mono text-slate-500">
        Showing{' '}
        <span className="text-slate-800 font-semibold">{start}–{end}</span> of{' '}
        <span className="text-slate-800 font-semibold">{total}</span> users
      </p>

      {/* Page controls */}
      <div className="flex items-center gap-1">
        {/* First */}
        <button
          onClick={() => onPage(1)}
          disabled={page === 1}
          className={`${btnBase} text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-slate-200 bg-white disabled:opacity-30 disabled:cursor-not-allowed`}
          title="First page"
        >
          <ChevronsLeft className="h-3.5 w-3.5" />
        </button>
        {/* Prev */}
        <button
          onClick={() => onPage(page - 1)}
          disabled={page === 1}
          className={`${btnBase} text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-slate-200 bg-white disabled:opacity-30 disabled:cursor-not-allowed`}
          title="Previous page"
        >
          <ChevronLeft className="h-3.5 w-3.5" />
        </button>

        {/* Page numbers */}
        {pages.map((p, idx) =>
          p === '…' ? (
            <span key={`ellipsis-${idx}`} className="text-slate-400 font-mono text-[11px] px-1">…</span>
          ) : (
            <button
              key={p}
              onClick={() => onPage(p as number)}
              className={`${btnBase} ${
                p === page
                  ? 'bg-[#0d1c32] text-white shadow-xs'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-slate-200 bg-white'
              }`}
            >
              {p}
            </button>
          )
        )}

        {/* Next */}
        <button
          onClick={() => onPage(page + 1)}
          disabled={page === totalPages}
          className={`${btnBase} text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-slate-200 bg-white disabled:opacity-30 disabled:cursor-not-allowed`}
          title="Next page"
        >
          <ChevronRight className="h-3.5 w-3.5" />
        </button>
        {/* Last */}
        <button
          onClick={() => onPage(totalPages)}
          disabled={page === totalPages}
          className={`${btnBase} text-slate-600 hover:text-slate-900 hover:bg-slate-50 border border-slate-200 bg-white disabled:opacity-30 disabled:cursor-not-allowed`}
          title="Last page"
        >
          <ChevronsRight className="h-3.5 w-3.5" />
        </button>
      </div>
    </div>
  );
}

// ── Page ──────────────────────────────────────────────────────────────────────

export default function UsersPage() {
  const { user: currentUser } = useAuth();
  const [users, setUsers] = useState<User[]>([]);
  const [selectedRole, setSelectedRole] = useState<string>('CLIENT');
  const [statusFilter, setStatusFilter] = useState<'ALL' | 'ACTIVE' | 'SUSPENDED'>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [page, setPage] = useState<number>(1);
  const [selectedUser, setSelectedUser] = useState<User | null>(null);
  const [userDetails, setUserDetails] = useState<{ user: User; projects: any[] } | null>(null);
  const [loadingDetails, setLoadingDetails] = useState<boolean>(false);

  // Account Governance Modal State
  const [governanceModalOpen, setGovernanceModalOpen] = useState<boolean>(false);
  const [governanceUser, setGovernanceUser] = useState<User | null>(null);
  const [targetStatus, setTargetStatus] = useState<'ACTIVE' | 'SUSPENDED'>('SUSPENDED');
  const [governanceReason, setGovernanceReason] = useState<string>('');
  const [updatingStatus, setUpdatingStatus] = useState<boolean>(false);
  const [governanceSuccess, setGovernanceSuccess] = useState<string | null>(null);
  const [governanceError, setGovernanceError] = useState<string | null>(null);

  const handleOpenGovernanceModal = (u: User, newStatus: 'ACTIVE' | 'SUSPENDED') => {
    setGovernanceUser(u);
    setTargetStatus(newStatus);
    setGovernanceReason('');
    setGovernanceSuccess(null);
    setGovernanceError(null);
    setGovernanceModalOpen(true);
  };

  const handleConfirmStatusChange = async () => {
    if (!governanceUser) return;
    setUpdatingStatus(true);
    setGovernanceError(null);

    try {
      await adminApi.updateUserStatus(governanceUser.id, targetStatus, governanceReason.trim() || undefined);
      setGovernanceSuccess(
        `User account "${governanceUser.name}" has been successfully ${targetStatus === 'SUSPENDED' ? 'suspended' : 'reactivated'}.`
      );

      // Update local state
      setUsers((prev) =>
        prev.map((u) => (u.id === governanceUser.id ? { ...u, status: targetStatus } : u))
      );
      if (selectedUser?.id === governanceUser.id) {
        setSelectedUser((prev) => (prev ? { ...prev, status: targetStatus } : prev));
      }

      setTimeout(() => {
        setGovernanceModalOpen(false);
        setGovernanceUser(null);
        setGovernanceSuccess(null);
      }, 1500);
    } catch (err: any) {
      setGovernanceError(err.message || 'Failed to update user account governance state.');
    } finally {
      setUpdatingStatus(false);
    }
  };

  const openUserDetails = async (u: User) => {
    setSelectedUser(u);
    setLoadingDetails(true);
    try {
      const data = await adminApi.getUserDetails(u.id);
      setUserDetails(data);
    } catch {
      setUserDetails({ user: u, projects: [] });
    } finally {
      setLoadingDetails(false);
    }
  };

  const loadUsers = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getUsers();
      setUsers(data || []);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load user directory');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  // Reset to page 1 when filter/search changes
  useEffect(() => {
    setPage(1);
  }, [selectedRole, statusFilter, searchQuery]);

  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      if (selectedRole !== 'ALL') {
        if (selectedRole === 'CLIENT') {
          if (u.role !== 'CLIENT' && u.role !== 'ENGINEER') return false;
        } else if (selectedRole === 'ADMIN') {
          if (u.role !== 'ADMIN' && u.role !== 'STUDIO_ADMIN') return false;
        } else if (u.role !== selectedRole) {
          return false;
        }
      }
      const userStatus = u.status || 'ACTIVE';
      if (statusFilter !== 'ALL' && userStatus !== statusFilter) return false;
      if (searchQuery.trim()) {
        const q = searchQuery.toLowerCase();
        return (
          (u.name || '').toLowerCase().includes(q) ||
          (u.email || '').toLowerCase().includes(q) ||
          (u.college_name || '').toLowerCase().includes(q) ||
          (u.company_name || '').toLowerCase().includes(q) ||
          (u.mobile || '').toLowerCase().includes(q)
        );
      }
      return true;
    });
  }, [users, selectedRole, statusFilter, searchQuery]);

  // Paginated slice
  const totalPages = Math.max(1, Math.ceil(filteredUsers.length / PAGE_SIZE));
  const safePage = Math.min(page, totalPages);
  const pageUsers = filteredUsers.slice((safePage - 1) * PAGE_SIZE, safePage * PAGE_SIZE);

  const engineerCount = users.filter((u) => u.role === 'CLIENT' || u.role === 'ENGINEER').length;
  const draughtsmanCount = users.filter((u) => u.role === 'DRAUGHTSMAN').length;
  const studentCount = users.filter((u) => u.role === 'STUDENT').length;
  const adminCount = users.filter((u) => u.role === 'ADMIN' || u.role === 'STUDIO_ADMIN').length;
  const activeCount = users.filter((u) => u.status !== 'SUSPENDED').length;
  const suspendedCount = users.filter((u) => u.status === 'SUSPENDED').length;

  const activeTabMeta = ROLE_TABS.find((t) => t.value === selectedRole) ?? ROLE_TABS[4];

  return (
    <AdminShell
      title="User Management"
      subtitle="Authoritative directory & account governance across Engineers, Draughtsmen, Students, and Studio Admins"
      onRefresh={() => loadUsers(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-sm text-rose-300 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadUsers(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {/* ── Bento Grid: Table (2/3) + Stats Panel (1/3) ── */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">

        {/* ── Left: User directory (lg:col-span-2) ── */}
        <div className="lg:col-span-2 space-y-4">

          {/* Role group tabs */}
          <div className="flex gap-1 border-b border-slate-200 pb-0 overflow-x-auto w-full max-w-full scrollbar-none">
            {ROLE_TABS.map((tab) => {
              const count =
                tab.value === 'CLIENT' ? engineerCount
                : tab.value === 'DRAUGHTSMAN' ? draughtsmanCount
                : tab.value === 'STUDENT' ? studentCount
                : tab.value === 'ADMIN' ? adminCount
                : users.length;
              const isActive = selectedRole === tab.value;
              return (
                <button
                  key={tab.value}
                  onClick={() => setSelectedRole(tab.value)}
                  className={`relative px-4 py-3 text-xs font-mono font-semibold whitespace-nowrap transition-all duration-200 border-b-2 ${
                    isActive
                      ? 'text-slate-900 border-b-2 border-[#0453cd]'
                      : 'text-slate-500 border-transparent hover:text-slate-800'
                  }`}
                >
                  {tab.label}
                  <span className="ml-1.5 text-[10px] font-mono opacity-80">({count})</span>
                </button>
              );
            })}
          </div>

          {/* Search & heading */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
            <h3 className="text-xs font-semibold text-slate-900 font-mono uppercase tracking-wider">
              {statusFilter === 'ALL' ? '' : `${statusFilter} `}{activeTabMeta.label}
            </h3>
            <div className="flex items-center gap-2 flex-wrap sm:flex-nowrap">
              <select
                value={statusFilter}
                onChange={(e) => setStatusFilter(e.target.value as any)}
                className="px-2.5 py-2 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-700 focus:outline-none focus:ring-1 focus:ring-[#0453cd] shadow-xs"
              >
                <option value="ALL">All Statuses</option>
                <option value="ACTIVE">Active Only</option>
                <option value="SUSPENDED">Suspended Only</option>
              </select>
              <div className="relative w-full sm:max-w-56">
                <Search className="h-3.5 w-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  placeholder="Search users…"
                  className="w-full pl-9 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd] focus:border-[#0453cd] shadow-xs transition-all font-mono"
                />
              </div>
            </div>
          </div>

          {/* User list */}
          <Card technicalCorners className="bg-white border-slate-200 soft-elevation">
            {loading ? (
              <div className="flex flex-col items-center justify-center p-20">
                <div className="h-6 w-6 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
                <p className="text-xs text-slate-500 mt-3 font-mono">Loading user directory…</p>
              </div>
            ) : filteredUsers.length === 0 ? (
              <div className="p-16 text-center">
                <UserCircle2 className="h-10 w-10 text-slate-300 mx-auto mb-3" />
                <p className="text-sm font-semibold text-slate-700">No users found</p>
                <p className="text-xs text-slate-500 mt-1 font-mono">
                  {searchQuery ? `No results for "${searchQuery}".` : `No ${activeTabMeta.label.toLowerCase()} registered yet.`}
                </p>
              </div>
            ) : (
              <>
                <div className="divide-y divide-slate-100">
                  {pageUsers.map((u) => {
                    const initials = (u.name || 'U').charAt(0).toUpperCase();
                    const profileHref =
                      u.role === 'CLIENT' ? `/engineers`
                      : u.role === 'DRAUGHTSMAN' ? `/draughtsmen`
                      : u.role === 'STUDENT' ? `/students`
                      : `/users`;
                    return (
                      <div key={u.id}
                        className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 px-4 sm:px-5 py-3.5 hover:bg-slate-50/80 transition-colors"
                      >
                        {/* Avatar + Name */}
                        <div className="flex items-center gap-3 min-w-0 flex-1">
                          <div className="h-10 w-10 rounded-full flex items-center justify-center font-bold text-sm shrink-0 border"
                            style={{
                              background: `${activeTabMeta.color}15`,
                              borderColor: `${activeTabMeta.color}30`,
                              color: activeTabMeta.color,
                            }}
                          >
                            {initials}
                          </div>
                          <div className="min-w-0 flex-1">
                            <p className="font-semibold text-sm text-slate-900 truncate">{u.name || 'Anonymous'}</p>
                            <p className="text-[10px] font-mono text-slate-500 truncate">{u.email}</p>
                          </div>
                        </div>

                        {/* Background */}
                        <div className="hidden md:block flex-1 min-w-0 px-2 lg:px-4">
                          {u.college_name && (
                            <p className="text-xs text-slate-600 truncate flex items-center gap-1">
                              <GraduationCap className="h-3.5 w-3.5 text-slate-400 shrink-0" /> {u.college_name}
                            </p>
                          )}
                          {u.company_name && (
                            <p className="text-xs text-slate-600 truncate flex items-center gap-1">
                              <Building className="h-3.5 w-3.5 text-slate-400 shrink-0" /> {u.company_name}
                            </p>
                          )}
                          {u.qualification && (
                            <p className="text-[10px] text-slate-500 font-mono truncate">{u.qualification}</p>
                          )}
                        </div>

                        {/* Role + Status + Actions */}
                        <div className="flex items-center justify-between sm:justify-end gap-2 shrink-0 pt-2 sm:pt-0 border-t sm:border-t-0 border-slate-100">
                          <Badge role={u.role} />
                          <span
                            className={`text-[9px] font-mono font-bold px-2 py-0.5 rounded border ${
                              u.status === 'SUSPENDED'
                                ? 'bg-rose-50 text-rose-700 border-rose-200'
                                : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            }`}
                          >
                            {u.status || 'ACTIVE'}
                          </span>

                          <div className="flex items-center gap-1">
                            {/* Suspend / Reactivate action button */}
                            {u.id !== currentUser?.id && (
                              u.status === 'SUSPENDED' ? (
                                <button
                                  onClick={() => handleOpenGovernanceModal(u, 'ACTIVE')}
                                  className="p-1.5 rounded-lg hover:bg-emerald-50 transition-colors text-slate-400 hover:text-emerald-600 cursor-pointer"
                                  title="Reactivate User Account"
                                >
                                  <UserCheck className="h-3.5 w-3.5" />
                                </button>
                              ) : (
                                <button
                                  onClick={() => handleOpenGovernanceModal(u, 'SUSPENDED')}
                                  className="p-1.5 rounded-lg hover:bg-rose-50 transition-colors text-slate-400 hover:text-rose-600 cursor-pointer"
                                  title="Suspend User Account"
                                >
                                  <UserX className="h-3.5 w-3.5" />
                                </button>
                              )
                            )}

                            <button
                              onClick={() => openUserDetails(u)}
                              className="p-1.5 rounded-lg hover:bg-blue-50 transition-colors text-slate-400 hover:text-[#0453cd] cursor-pointer"
                              title="Inspect User Dossier"
                            >
                              <Eye className="h-3.5 w-3.5" />
                            </button>
                            <Link href={profileHref}
                              className="p-1.5 rounded-lg hover:bg-slate-100 transition-colors text-slate-400 hover:text-slate-800"
                              title="View in dedicated module"
                            >
                              <ExternalLink className="h-3.5 w-3.5" />
                            </Link>
                          </div>
                        </div>
                      </div>
                    );
                  })}
                </div>

                {/* Pagination */}
                <Pagination
                  page={safePage}
                  totalPages={totalPages}
                  total={filteredUsers.length}
                  pageSize={PAGE_SIZE}
                  onPage={setPage}
                  accentColor={activeTabMeta.color}
                />
              </>
            )}
          </Card>
        </div>

        {/* ── Right: User Operations & Account Governance Overview ── */}
        <div className="space-y-5">

          {/* Verified Identity Role Counts */}
          <div className="grid grid-cols-2 gap-3">
            {[
              { label: 'Engineers', count: engineerCount, color: '#0453cd', icon: HardHat },
              { label: 'Draughtsmen', count: draughtsmanCount, color: '#0284c7', icon: PenTool },
              { label: 'Students', count: studentCount, color: '#059669', icon: GraduationCap },
              { label: 'Admins', count: adminCount, color: '#e11d48', icon: ShieldCheck },
            ].map(({ label, count, color, icon: Icon }) => (
              <div key={label} className="p-3.5 rounded-xl border border-slate-200 bg-white soft-elevation">
                <div className="flex items-center justify-between mb-1">
                  <p className="text-[9px] font-mono uppercase tracking-widest text-slate-500 font-semibold">{label}</p>
                  <Icon className="h-3.5 w-3.5" style={{ color }} />
                </div>
                <p className="text-2xl font-bold font-mono text-slate-900">{count}</p>
              </div>
            ))}
          </div>

          {/* Account Governance & Access Status */}
          <div className="rounded-xl border border-slate-200 bg-white soft-elevation overflow-hidden">
            <div className="p-5 space-y-4">
              <div className="flex items-center justify-between">
                <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest font-semibold flex items-center gap-2">
                  <ShieldCheck className="h-3.5 w-3.5 text-[#0453cd]" />
                  Account Governance Status
                </p>
                <span className="text-[10px] font-mono font-bold text-slate-500">
                  {users.length} {users.length === 1 ? 'Identity' : 'Identities'}
                </span>
              </div>

              {users.length === 0 ? (
                <div className="p-4 rounded-xl bg-slate-50 border border-slate-200 text-center">
                  <p className="text-xs text-slate-500 font-mono">
                    Operational analytics will appear when verified identity data is synchronized from Cloudflare D1.
                  </p>
                </div>
              ) : (
                <>
                  <div className="grid grid-cols-2 gap-3">
                    <div className="p-3 rounded-lg bg-emerald-50/70 border border-emerald-200">
                      <div className="flex items-center gap-1.5 text-emerald-700 text-xs font-semibold mb-0.5">
                        <CheckCircle2 className="h-3.5 w-3.5" />
                        <span>Active</span>
                      </div>
                      <p className="text-xl font-bold font-mono text-emerald-900">{activeCount}</p>
                      <p className="text-[10px] text-emerald-600 font-mono mt-0.5">
                        {users.length > 0 ? Math.round((activeCount / users.length) * 100) : 0}% operational
                      </p>
                    </div>

                    <div className="p-3 rounded-lg bg-rose-50/70 border border-rose-200">
                      <div className="flex items-center gap-1.5 text-rose-700 text-xs font-semibold mb-0.5">
                        <ShieldAlert className="h-3.5 w-3.5" />
                        <span>Suspended</span>
                      </div>
                      <p className="text-xl font-bold font-mono text-rose-900">{suspendedCount}</p>
                      <p className="text-[10px] text-rose-600 font-mono mt-0.5">
                        {users.length > 0 ? Math.round((suspendedCount / users.length) * 100) : 0}% restricted
                      </p>
                    </div>
                  </div>

                  {/* Visual Proportion Bar */}
                  <div>
                    <div className="flex justify-between text-[10px] font-mono text-slate-500 mb-1.5">
                      <span>Platform Health Allocation</span>
                      <span className="font-semibold text-slate-700">
                        {users.length > 0 ? Math.round((activeCount / users.length) * 100) : 0}% Operational
                      </span>
                    </div>
                    <div className="w-full h-2 rounded-full overflow-hidden bg-slate-100 flex">
                      <div
                        className="bg-emerald-500 h-full transition-all duration-500"
                        style={{
                          width: `${users.length > 0 ? (activeCount / users.length) * 100 : 100}%`,
                        }}
                        title={`Active: ${activeCount}`}
                      />
                      <div
                        className="bg-rose-500 h-full transition-all duration-500"
                        style={{
                          width: `${users.length > 0 ? (suspendedCount / users.length) * 100 : 0}%`,
                        }}
                        title={`Suspended: ${suspendedCount}`}
                      />
                    </div>
                  </div>
                </>
              )}
            </div>
          </div>

          {/* Directory Talent Distribution */}
          <div className="rounded-xl border border-slate-200 bg-white soft-elevation overflow-hidden">
            <div className="p-5 space-y-3.5">
              <p className="text-[10px] font-mono text-slate-500 uppercase tracking-widest font-semibold flex items-center gap-2">
                <Users className="h-3.5 w-3.5 text-indigo-600" />
                Verified Talent Distribution
              </p>

              {users.length === 0 ? (
                <p className="text-xs text-slate-400 font-mono italic">No synchronized identities found.</p>
              ) : (
                <div className="space-y-2.5">
                  {[
                    { label: 'Engineers (Client)', count: engineerCount, color: '#0453cd' },
                    { label: 'Draughtsmen (Production)', count: draughtsmanCount, color: '#0284c7' },
                    { label: 'Students (Trainees)', count: studentCount, color: '#059669' },
                    { label: 'Studio Administrators', count: adminCount, color: '#e11d48' },
                  ].map(({ label, count, color }) => {
                    const pct = users.length > 0 ? Math.round((count / users.length) * 100) : 0;
                    return (
                      <div key={label}>
                        <div className="flex justify-between text-[11px] font-mono mb-1">
                          <span className="text-slate-600 font-medium">{label}</span>
                          <span className="text-slate-900 font-bold">
                            {count} <span className="text-slate-400 font-normal">({pct}%)</span>
                          </span>
                        </div>
                        <div className="w-full h-1.5 rounded-full overflow-hidden bg-slate-100">
                          <div
                            className="h-full rounded-full transition-all duration-500"
                            style={{ width: `${pct}%`, background: color }}
                          />
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>

          {/* Quick links */}
          <div className="rounded-xl border border-slate-200 divide-y divide-slate-100 bg-white soft-elevation overflow-hidden">
            <p className="px-4 py-3 text-[10px] font-mono text-slate-500 uppercase tracking-widest font-semibold">
              Studio Quick Access
            </p>
            {[
              { label: 'Engineer Directory', href: '/engineers', icon: HardHat, color: '#0453cd' },
              { label: 'Draughtsman Studio', href: '/draughtsmen', icon: PenTool, color: '#0284c7' },
              { label: 'Student Portal', href: '/students', icon: GraduationCap, color: '#059669' },
              { label: 'Assignment History', href: '/assignments/history', icon: Clock, color: '#475569' },
            ].map(({ label, href, icon: Icon, color }) => (
              <Link
                key={href}
                href={href}
                className="flex items-center justify-between px-4 py-3 hover:bg-slate-50 transition-colors group"
              >
                <div className="flex items-center gap-3">
                  <div
                    className="h-7 w-7 rounded-lg flex items-center justify-center shrink-0"
                    style={{ background: `${color}15` }}
                  >
                    <Icon className="h-3.5 w-3.5" style={{ color }} />
                  </div>
                  <span className="text-xs font-medium text-slate-700 group-hover:text-slate-900 transition-colors">
                    {label}
                  </span>
                </div>
                <ExternalLink className="h-3.5 w-3.5 text-slate-400 group-hover:text-slate-600 transition-colors" />
              </Link>
            ))}
          </div>
        </div>
      </div>

      {/* ── User Dossier Modal (Unified Directory Inspection) ── */}
      {selectedUser && (
        <Modal
          isOpen={!!selectedUser}
          onClose={() => { setSelectedUser(null); setUserDetails(null); }}
          title={`User Dossier: ${selectedUser.name || 'User'}`}
          description={`UID ${selectedUser.id.substring(0, 12)}… • ROLE: ${selectedUser.role}`}
          maxWidth="2xl"
        >
          <div className="space-y-5 max-h-[75vh] overflow-y-auto pr-1">
            {/* Profile strip */}
            <div className="flex items-center gap-4 p-4 rounded-xl border border-slate-200 bg-slate-50">
              <div
                className="h-12 w-12 rounded-2xl flex items-center justify-center font-bold text-lg shrink-0 border"
                style={{
                  background: `${activeTabMeta.color}15`,
                  borderColor: `${activeTabMeta.color}30`,
                  color: activeTabMeta.color,
                }}
              >
                {(selectedUser.name || 'U').charAt(0).toUpperCase()}
              </div>
              <div className="flex-1 min-w-0">
                <p className="font-semibold text-slate-900 truncate">{selectedUser.name || 'Unnamed User'}</p>
                <p className="text-xs font-mono text-slate-500 truncate">{selectedUser.email}</p>
                {selectedUser.company_name && (
                  <p className="text-[11px] text-slate-600 mt-0.5 flex items-center gap-1">
                    <Building className="h-3 w-3 text-slate-400" /> {selectedUser.company_name}
                  </p>
                )}
                {selectedUser.college_name && (
                  <p className="text-[11px] text-slate-600 mt-0.5 flex items-center gap-1">
                    <GraduationCap className="h-3 w-3 text-slate-400" /> {selectedUser.college_name}
                  </p>
                )}
              </div>
              <div className="shrink-0 flex flex-col items-center">
                <Badge role={selectedUser.role} />
              </div>
            </div>

            {/* Profile Attributes Grid */}
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              <div className="p-3 rounded-xl border border-slate-200 bg-white">
                <p className="text-[9px] font-mono text-slate-400 uppercase tracking-wider mb-0.5">TELEPHONE</p>
                <p className="text-xs font-mono font-semibold text-slate-800">{selectedUser.mobile || 'Not specified'}</p>
              </div>
              <div className="p-3 rounded-xl border border-slate-200 bg-white">
                <p className="text-[9px] font-mono text-slate-400 uppercase tracking-wider mb-0.5">QUALIFICATION</p>
                <p className="text-xs font-semibold text-slate-800 truncate">{selectedUser.qualification || 'Standard'}</p>
              </div>
              <div className="p-3 rounded-xl border border-slate-200 bg-white">
                <p className="text-[9px] font-mono text-slate-400 uppercase tracking-wider mb-0.5">MEMBER SINCE</p>
                <p className="text-xs font-mono text-slate-800">{selectedUser.created_at ? new Date(selectedUser.created_at).toLocaleDateString() : '—'}</p>
              </div>
            </div>

            {/* Associated Records Section */}
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <h4 className="text-xs font-bold font-mono uppercase tracking-wider text-slate-900 flex items-center gap-2">
                  <FileText className="h-3.5 w-3.5 text-[#0453cd]" />
                  <span>
                    {selectedUser.role === 'CLIENT'
                      ? 'Client Project Portfolio'
                      : selectedUser.role === 'DRAUGHTSMAN'
                      ? 'Draughtsman Assignment History'
                      : 'Associated Platform Records'}
                  </span>
                </h4>
                {userDetails?.projects && (
                  <span className="text-[10px] font-mono bg-blue-50 text-[#0453cd] px-2 py-0.5 rounded border border-blue-200 font-semibold">
                    {userDetails.projects.length} Total Records
                  </span>
                )}
              </div>

              {loadingDetails ? (
                <div className="p-8 text-center bg-slate-50 border border-slate-200 rounded-xl">
                  <div className="h-5 w-5 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent mx-auto mb-2" />
                  <p className="text-xs text-slate-500 font-mono">Querying Cloudflare D1 records…</p>
                </div>
              ) : !userDetails?.projects || userDetails.projects.length === 0 ? (
                <div className="p-6 text-center rounded-xl border border-slate-200 bg-slate-50 text-xs text-slate-500 font-mono">
                  No active projects or assignments recorded for this account.
                </div>
              ) : (
                <div className="space-y-2 max-h-56 overflow-y-auto pr-1">
                  {userDetails.projects.map((proj: any, idx: number) => {
                    const projectId = proj.project_id || proj.id;
                    const projectName = proj.project_name || 'Project';
                    const status = proj.project_status || proj.status;
                    return (
                      <div
                        key={idx}
                        className="flex items-center justify-between p-3 rounded-xl border border-slate-200 bg-white hover:border-slate-300 transition-all shadow-xs"
                      >
                        <div className="min-w-0">
                          <Link
                            href={`/projects/${projectId}`}
                            className="text-xs font-semibold text-slate-900 hover:text-[#0453cd] transition-colors truncate block"
                          >
                            {projectName}
                          </Link>
                          <p className="text-[10px] font-mono text-slate-500 mt-0.5">
                            ID: {projectId.substring(0, 10)}… · {proj.drawing_type || 'Package'} {proj.project_area ? `· ${proj.project_area} sq.ft` : ''}
                          </p>
                        </div>
                        <div className="flex items-center gap-2 shrink-0">
                          <Badge status={status} size="sm" />
                          <Link
                            href={`/projects/${projectId}`}
                            className="p-1 text-slate-400 hover:text-[#0453cd] rounded hover:bg-slate-100 transition-colors"
                          >
                            <ChevronRight className="h-3.5 w-3.5" />
                          </Link>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>

            {/* Account Governance Section */}
            <div className="p-4 rounded-xl border border-slate-200 bg-slate-50 space-y-3">
              <div className="flex items-center justify-between">
                <div>
                  <h4 className="text-xs font-bold font-mono uppercase tracking-wider text-slate-900 flex items-center gap-1.5">
                    <ShieldAlert className="h-3.5 w-3.5 text-[#0453cd]" />
                    <span>Account Governance & Operational Status</span>
                  </h4>
                  <p className="text-[11px] text-slate-500 font-sans mt-0.5">
                    Enforce platform access and operational permissions across all 4 portal clients
                  </p>
                </div>
                <span
                  className={`text-[10px] font-mono font-bold px-2 py-0.5 rounded border ${
                    selectedUser.status === 'SUSPENDED'
                      ? 'bg-rose-50 text-rose-700 border-rose-200'
                      : 'bg-emerald-50 text-emerald-700 border-emerald-200'
                  }`}
                >
                  {selectedUser.status || 'ACTIVE'}
                </span>
              </div>

              {selectedUser.id === currentUser?.id ? (
                <p className="text-[11px] font-mono text-slate-500 bg-white p-2.5 rounded-lg border border-slate-200">
                  Self-governance lock: You are logged in as this administrator. Modifying your own status is prohibited.
                </p>
              ) : (
                <div className="flex items-center justify-between gap-3 pt-1">
                  <p className="text-[11px] text-slate-600 font-sans">
                    {selectedUser.status === 'SUSPENDED'
                      ? 'This account is currently suspended and blocked from API interactions.'
                      : 'Active account in good standing with standard portal privileges.'}
                  </p>
                  {selectedUser.status === 'SUSPENDED' ? (
                    <Button
                      variant="primary"
                      size="sm"
                      onClick={() => handleOpenGovernanceModal(selectedUser, 'ACTIVE')}
                      className="text-xs shrink-0 flex items-center gap-1.5"
                    >
                      <UserCheck className="h-3.5 w-3.5" />
                      <span>Reactivate Account</span>
                    </Button>
                  ) : (
                    <Button
                      variant="danger"
                      size="sm"
                      onClick={() => handleOpenGovernanceModal(selectedUser, 'SUSPENDED')}
                      className="text-xs shrink-0 flex items-center gap-1.5"
                    >
                      <UserX className="h-3.5 w-3.5" />
                      <span>Suspend Account</span>
                    </Button>
                  )}
                </div>
              )}
            </div>

            {/* Footer */}
            <div className="pt-3 border-t border-slate-200 flex items-center justify-between">
              <p className="text-[10px] font-mono text-slate-500">
                Verified via D1 endpoint: <code className="bg-slate-100 px-1 py-0.5 rounded text-slate-700">GET /api/users/{selectedUser.id}</code>
              </p>
              <Button
                variant="outline"
                size="sm"
                onClick={() => { setSelectedUser(null); setUserDetails(null); }}
              >
                Close Dossier
              </Button>
            </div>
          </div>
        </Modal>
      )}

      {/* ── Governance Confirmation Modal ── */}
      {governanceModalOpen && governanceUser && (
        <Modal
          isOpen={governanceModalOpen}
          onClose={() => !updatingStatus && setGovernanceModalOpen(false)}
          title={targetStatus === 'SUSPENDED' ? 'Confirm User Account Suspension' : 'Confirm Account Reactivation'}
        >
          <div className="space-y-4">
            {governanceSuccess && (
              <div className="p-4 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-mono flex items-center gap-2">
                <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                <span>{governanceSuccess}</span>
              </div>
            )}
            {governanceError && (
              <div className="p-4 rounded-xl bg-rose-50 border border-rose-200 text-rose-800 text-xs font-mono flex items-center gap-2">
                <AlertCircle className="h-4 w-4 text-rose-600 shrink-0" />
                <span>{governanceError}</span>
              </div>
            )}

            <div className={`p-4 rounded-xl border text-xs ${
              targetStatus === 'SUSPENDED'
                ? 'bg-rose-50/60 border-rose-200 text-rose-900'
                : 'bg-emerald-50/60 border-emerald-200 text-emerald-900'
            }`}>
              <p className="font-semibold mb-1 flex items-center gap-1.5">
                <ShieldAlert className="h-4 w-4" />
                <span>Operational Governance Warning</span>
              </p>
              <p className="text-[11px] leading-relaxed">
                {targetStatus === 'SUSPENDED'
                  ? `Suspending "${governanceUser.name}" will immediately revoke platform API access across Cloudflare Worker and R2. The user will be blocked from submitting drafts, commenting, or executing project lifecycle actions.`
                  : `Reactivating "${governanceUser.name}" will restore operational privileges on the shared Cloudflare D1 backend.`}
              </p>
            </div>

            <div className="p-3 rounded-xl bg-slate-50 border border-slate-200 text-xs font-mono space-y-1">
              <div className="flex justify-between">
                <span className="text-slate-500">Target User:</span>
                <span className="font-bold text-slate-800">{governanceUser.name}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Email:</span>
                <span className="text-slate-800">{governanceUser.email}</span>
              </div>
              <div className="flex justify-between">
                <span className="text-slate-500">Platform Role:</span>
                <span className="text-slate-800">{governanceUser.role}</span>
              </div>
            </div>

            {targetStatus === 'SUSPENDED' && (
              <div className="space-y-1.5">
                <label className="block text-[11px] font-mono font-semibold text-slate-700 uppercase tracking-wider">
                  Reason for Suspension (Audit Log)
                </label>
                <input
                  type="text"
                  value={governanceReason}
                  onChange={(e) => setGovernanceReason(e.target.value)}
                  placeholder="e.g. Terms violation, draughtsman inactive, project breach"
                  className="w-full px-3 py-2 bg-white border border-slate-200 rounded-lg text-xs font-mono text-slate-900 focus:outline-none focus:ring-1 focus:ring-[#0453cd]"
                />
              </div>
            )}

            <div className="pt-3 border-t border-slate-200 flex items-center justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                disabled={updatingStatus}
                onClick={() => setGovernanceModalOpen(false)}
              >
                Cancel
              </Button>
              <Button
                variant={targetStatus === 'SUSPENDED' ? 'danger' : 'primary'}
                size="sm"
                disabled={updatingStatus || !!governanceSuccess}
                onClick={handleConfirmStatusChange}
                className="flex items-center gap-1.5"
              >
                {updatingStatus ? (
                  <>
                    <span className="h-3 w-3 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>Applying…</span>
                  </>
                ) : (
                  <>
                    {targetStatus === 'SUSPENDED' ? <UserX className="h-3.5 w-3.5" /> : <UserCheck className="h-3.5 w-3.5" />}
                    <span>{targetStatus === 'SUSPENDED' ? 'Confirm Suspension' : 'Confirm Reactivation'}</span>
                  </>
                )}
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </AdminShell>
  );
}

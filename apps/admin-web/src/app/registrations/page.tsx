'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi, ApiError } from '@/lib/api';
import { useAuth } from '@/lib/auth';
import { RegistrationVerification, RegistrationStatus } from '@/lib/types';
import {
  Search,
  ClipboardCheck,
  CheckCircle2,
  XCircle,
  Clock,
  FileText,
  Download,
  Eye,
  AlertCircle,
  RefreshCw,
  HardHat,
  PenTool,
  GraduationCap,
  ShieldCheck,
  Building,
  School,
  Calendar,
  Mail,
  Phone,
  User,
  Filter,
} from 'lucide-react';

const STATUS_FILTERS: { label: string; value: string; color: string }[] = [
  { label: 'All Statuses', value: 'ALL', color: '#94a3b8' },
  { label: 'Pending Review', value: 'PENDING', color: '#f59e0b' },
  { label: 'Approved', value: 'APPROVED', color: '#10b981' },
  { label: 'Rejected', value: 'REJECTED', color: '#ef4444' },
];

const ROLE_FILTERS: { label: string; value: string }[] = [
  { label: 'All Roles', value: 'ALL' },
  { label: 'Engineer', value: 'ENGINEER' },
  { label: 'Draughtsman', value: 'DRAUGHTSMAN' },
  { label: 'Student', value: 'STUDENT' },
];

function formatBytes(bytes: number): string {
  if (!bytes || bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}

function formatDateTime(dtStr?: string | null): string {
  if (!dtStr) return '—';
  try {
    const d = new Date(dtStr);
    return d.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    });
  } catch {
    return dtStr;
  }
}

export default function RegistrationsPage() {
  const { user } = useAuth();
  const [registrations, setRegistrations] = useState<RegistrationVerification[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Filters
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [roleFilter, setRoleFilter] = useState<string>('ALL');

  // Selected item for detail review modal
  const [selectedReg, setSelectedReg] = useState<RegistrationVerification | null>(null);

  // Action states
  const [isApproving, setIsApproving] = useState<boolean>(false);
  const [isRejecting, setIsRejecting] = useState<boolean>(false);
  const [rejectReason, setRejectReason] = useState<string>('');
  const [showRejectForm, setShowRejectForm] = useState<boolean>(false);
  const [actionError, setActionError] = useState<string | null>(null);
  const [previewProofOpen, setPreviewProofOpen] = useState<boolean>(false);

  const fetchRegistrations = async (isManualRefresh = false) => {
    if (isManualRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getRegistrations();
      setRegistrations(Array.isArray(data) ? data : []);
    } catch (err: any) {
      console.error('Failed to load registrations:', err);
      setError(err?.message || 'Failed to load registrations. Ensure backend is running.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchRegistrations();
  }, []);

  // Filtered registrations
  const filteredRegistrations = useMemo(() => {
    return registrations.filter((reg) => {
      // Status filter
      if (statusFilter !== 'ALL' && reg.status !== statusFilter) {
        return false;
      }

      // Role filter (normalize CLIENT to ENGINEER)
      if (roleFilter !== 'ALL') {
        const regRole = reg.role === 'CLIENT' ? 'ENGINEER' : reg.role;
        if (regRole !== roleFilter) return false;
      }

      // Search query
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase().trim();
        const nameMatch = (reg.name || '').toLowerCase().includes(query);
        const emailMatch = (reg.email || '').toLowerCase().includes(query);
        const fileNameMatch = (reg.file_name || '').toLowerCase().includes(query);
        if (!nameMatch && !emailMatch && !fileNameMatch) return false;
      }

      return true;
    });
  }, [registrations, statusFilter, roleFilter, searchQuery]);

  // Metrics summary
  const metrics = useMemo(() => {
    const total = registrations.length;
    const pending = registrations.filter((r) => r.status === 'PENDING').length;
    const approved = registrations.filter((r) => r.status === 'APPROVED').length;
    const rejected = registrations.filter((r) => r.status === 'REJECTED').length;
    return { total, pending, approved, rejected };
  }, [registrations]);

  const handleApprove = async () => {
    if (!selectedReg) return;
    setIsApproving(true);
    setActionError(null);

    try {
      const res = await adminApi.approveRegistration(selectedReg.id);
      if (res && res.registration) {
        // Update local state
        setRegistrations((prev) =>
          prev.map((r) => (r.id === selectedReg.id ? res.registration : r))
        );
        setSelectedReg(res.registration);
      } else {
        await fetchRegistrations(true);
      }
    } catch (err: any) {
      setActionError(err?.message || 'Failed to approve registration.');
    } finally {
      setIsApproving(false);
    }
  };

  const handleReject = async () => {
    if (!selectedReg) return;
    if (!rejectReason.trim()) {
      setActionError('Please provide a reason for rejecting the registration.');
      return;
    }

    setIsRejecting(true);
    setActionError(null);

    try {
      const res = await adminApi.rejectRegistration(selectedReg.id, rejectReason.trim());
      if (res && res.registration) {
        setRegistrations((prev) =>
          prev.map((r) => (r.id === selectedReg.id ? res.registration : r))
        );
        setSelectedReg(res.registration);
        setShowRejectForm(false);
        setRejectReason('');
      } else {
        await fetchRegistrations(true);
      }
    } catch (err: any) {
      setActionError(err?.message || 'Failed to reject registration.');
    } finally {
      setIsRejecting(false);
    }
  };

  const handleDownloadProof = async (reg: RegistrationVerification) => {
    try {
      const blob = await adminApi.getRegistrationProofBlob(reg.id);
      const url = window.URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = reg.file_name || `proof_${reg.name.replace(/\s+/g, '_')}.pdf`;
      document.body.appendChild(a);
      a.click();
      window.URL.revokeObjectURL(url);
      document.body.removeChild(a);
    } catch (err: any) {
      alert(`Download failed: ${err?.message || 'Could not fetch proof document'}`);
    }
  };

  const renderRoleBadge = (role: string) => {
    const norm = role === 'CLIENT' ? 'ENGINEER' : role;
    if (norm === 'ENGINEER') {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-indigo-500/10 text-indigo-400 border border-indigo-500/20">
          <HardHat className="w-3.5 h-3.5" />
          Engineer
        </span>
      );
    }
    if (norm === 'DRAUGHTSMAN') {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-cyan-500/10 text-cyan-400 border border-cyan-500/20">
          <PenTool className="w-3.5 h-3.5" />
          Draughtsman
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-xs font-medium bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
        <GraduationCap className="w-3.5 h-3.5" />
        Student
      </span>
    );
  };

  const renderStatusBadge = (status: RegistrationStatus) => {
    if (status === 'APPROVED') {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
          <CheckCircle2 className="w-3.5 h-3.5" />
          Approved
        </span>
      );
    }
    if (status === 'REJECTED') {
      return (
        <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-rose-500/15 text-rose-400 border border-rose-500/30">
          <XCircle className="w-3.5 h-3.5" />
          Rejected
        </span>
      );
    }
    return (
      <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-amber-500/15 text-amber-400 border border-amber-500/30">
        <Clock className="w-3.5 h-3.5" />
        Pending Review
      </span>
    );
  };

  const getProofDocTypeName = (role: string, customType?: string): string => {
    if (customType) return customType;
    const norm = role === 'CLIENT' ? 'ENGINEER' : role;
    if (norm === 'ENGINEER') return 'Engineering Degree / Qualification Certificate';
    if (norm === 'DRAUGHTSMAN') return 'Draughtsmanship Degree / Diploma Certificate';
    return 'Valid Student ID Card';
  };

  return (
    <AdminShell title="Registration Approvals" subtitle="Review submitted credentials, preview qualification proofs, and approve or reject accounts" onRefresh={() => fetchRegistrations(true)} isRefreshing={loading}>
      <div className="p-6 max-w-7xl mx-auto space-y-6">
        {/* ── Page Header ── */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-2 border-b border-[#1e293b]">
          <div>
            <div className="flex items-center gap-3">
              <div className="p-2.5 rounded-xl bg-gradient-to-br from-indigo-500/20 to-blue-500/10 border border-indigo-500/30 text-indigo-400">
                <ClipboardCheck className="w-6 h-6" />
              </div>
              <div>
                <h1 className="text-2xl font-bold tracking-tight text-white">
                  Registrations Provision
                </h1>
                <p className="text-sm text-slate-400">
                  Review and verify new user qualification proofs and registration submissions.
                </p>
              </div>
            </div>
          </div>
          <div className="flex items-center gap-3">
            <button
              onClick={() => fetchRegistrations(true)}
              disabled={loading || refreshing}
              className="inline-flex items-center gap-2 px-3 py-2 text-xs font-medium text-slate-300 bg-[#15233e] hover:bg-[#1a2c4e] border border-[#22395d] rounded-lg transition-colors disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${refreshing ? 'animate-spin' : ''}`} />
              Refresh
            </button>
          </div>
        </div>

        {/* ── Metric Summary Cards ── */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          <Card className="p-4 bg-[#0d1c32]/80 border-[#1e293b]">
            <p className="text-xs font-medium text-slate-400">Total Submissions</p>
            <p className="text-2xl font-bold text-white mt-1">{metrics.total}</p>
          </Card>
          <Card className="p-4 bg-[#0d1c32]/80 border-amber-500/20">
            <div className="flex items-center justify-between">
              <p className="text-xs font-medium text-amber-400">Pending Review</p>
              <Clock className="w-4 h-4 text-amber-400" />
            </div>
            <p className="text-2xl font-bold text-amber-400 mt-1">{metrics.pending}</p>
          </Card>
          <Card className="p-4 bg-[#0d1c32]/80 border-emerald-500/20">
            <div className="flex items-center justify-between">
              <p className="text-xs font-medium text-emerald-400">Approved</p>
              <CheckCircle2 className="w-4 h-4 text-emerald-400" />
            </div>
            <p className="text-2xl font-bold text-emerald-400 mt-1">{metrics.approved}</p>
          </Card>
          <Card className="p-4 bg-[#0d1c32]/80 border-rose-500/20">
            <div className="flex items-center justify-between">
              <p className="text-xs font-medium text-rose-400">Rejected</p>
              <XCircle className="w-4 h-4 text-rose-400" />
            </div>
            <p className="text-2xl font-bold text-rose-400 mt-1">{metrics.rejected}</p>
          </Card>
        </div>

        {/* ── Search & Filter Controls ── */}
        <div className="flex flex-col md:flex-row gap-3 items-stretch md:items-center justify-between bg-[#0d1c32]/60 p-4 rounded-xl border border-[#1e293b]">
          {/* Search */}
          <div className="relative flex-1 max-w-md">
            <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-slate-400" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Search by name, email, or file name..."
              className="w-full pl-10 pr-4 py-2 text-sm bg-[#112340] border border-[#22395d] text-white rounded-lg focus:outline-none focus:border-indigo-500 placeholder:text-slate-500"
            />
          </div>

          {/* Status and Role Filters */}
          <div className="flex flex-wrap items-center gap-2">
            <div className="flex items-center gap-1 bg-[#112340] p-1 rounded-lg border border-[#22395d]">
              {STATUS_FILTERS.map((f) => (
                <button
                  key={f.value}
                  onClick={() => setStatusFilter(f.value)}
                  className={`px-3 py-1.5 text-xs font-medium rounded-md transition-all ${
                    statusFilter === f.value
                      ? 'bg-indigo-600 text-white shadow'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {f.label}
                </button>
              ))}
            </div>

            <select
              value={roleFilter}
              onChange={(e) => setRoleFilter(e.target.value)}
              className="px-3 py-2 text-xs font-medium bg-[#112340] border border-[#22395d] text-slate-200 rounded-lg focus:outline-none focus:border-indigo-500"
            >
              {ROLE_FILTERS.map((rf) => (
                <option key={rf.value} value={rf.value}>
                  {rf.label}
                </option>
              ))}
            </select>
          </div>
        </div>

        {/* ── Registration Table / List ── */}
        {loading ? (
          <div className="p-12 text-center bg-[#0d1c32]/60 border border-[#1e293b] rounded-xl">
            <RefreshCw className="w-8 h-8 text-indigo-400 animate-spin mx-auto mb-3" />
            <p className="text-sm text-slate-300">Loading registrations...</p>
          </div>
        ) : error ? (
          <div className="p-8 text-center bg-rose-500/10 border border-rose-500/30 rounded-xl">
            <AlertCircle className="w-8 h-8 text-rose-400 mx-auto mb-3" />
            <p className="text-sm font-medium text-rose-300">{error}</p>
            <button
              onClick={() => fetchRegistrations()}
              className="mt-4 px-4 py-2 text-xs font-medium bg-rose-600 hover:bg-rose-500 text-white rounded-lg"
            >
              Retry
            </button>
          </div>
        ) : filteredRegistrations.length === 0 ? (
          <div className="p-12 text-center bg-[#0d1c32]/60 border border-[#1e293b] rounded-xl">
            <ClipboardCheck className="w-12 h-12 text-slate-500 mx-auto mb-3" />
            <h3 className="text-base font-medium text-white">No registrations found</h3>
            <p className="text-xs text-slate-400 mt-1">
              {searchQuery || statusFilter !== 'ALL' || roleFilter !== 'ALL'
                ? 'Try adjusting your search criteria or filter tabs.'
                : 'No registration submissions have been recorded yet.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto bg-[#0d1c32]/80 border border-[#1e293b] rounded-xl">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="text-xs uppercase bg-[#091526] text-slate-400 border-b border-[#1e293b]">
                <tr>
                  <th className="px-6 py-4 font-semibold">User</th>
                  <th className="px-6 py-4 font-semibold">Role</th>
                  <th className="px-6 py-4 font-semibold">Submitted</th>
                  <th className="px-6 py-4 font-semibold">Proof Document</th>
                  <th className="px-6 py-4 font-semibold">Verification Status</th>
                  <th className="px-6 py-4 font-semibold">Review Status</th>
                  <th className="px-6 py-4 font-semibold text-right">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#1e293b]">
                {filteredRegistrations.map((reg) => (
                  <tr
                    key={reg.id}
                    className="hover:bg-[#132542]/60 transition-colors cursor-pointer"
                    onClick={() => {
                      setSelectedReg(reg);
                      setShowRejectForm(false);
                      setActionError(null);
                    }}
                  >
                    <td className="px-6 py-4">
                      <div className="font-medium text-white">{reg.name}</div>
                      <div className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                        <Mail className="w-3 h-3 text-slate-500" />
                        {reg.email}
                      </div>
                      {reg.mobile && (
                        <div className="text-xs text-slate-400 flex items-center gap-1.5 mt-0.5">
                          <Phone className="w-3 h-3 text-slate-500" />
                          {reg.mobile}
                        </div>
                      )}
                    </td>
                    <td className="px-6 py-4">{renderRoleBadge(reg.role)}</td>
                    <td className="px-6 py-4 text-xs text-slate-400">
                      {formatDateTime(reg.submitted_at || reg.created_at)}
                    </td>
                    <td className="px-6 py-4">
                      {reg.file_name ? (
                        <div className="flex items-center gap-2">
                          <FileText className="w-4 h-4 text-indigo-400 shrink-0" />
                          <div className="max-w-[180px] truncate">
                            <span className="text-xs font-medium text-slate-200">
                              {reg.file_name}
                            </span>
                            <span className="block text-[10px] text-slate-400">
                              {formatBytes(reg.file_size)}
                            </span>
                          </div>
                        </div>
                      ) : (
                        <span className="text-xs text-slate-500">No file</span>
                      )}
                    </td>
                    <td className="px-6 py-4">{renderStatusBadge(reg.status)}</td>
                    <td className="px-6 py-4 text-xs text-slate-400">
                      {reg.reviewed_by ? (
                        <div>
                          <span className="text-slate-200 font-medium">
                            {reg.reviewer_name || 'Admin'}
                          </span>
                          <span className="block text-[10px] text-slate-500">
                            {formatDateTime(reg.reviewed_at)}
                          </span>
                        </div>
                      ) : (
                        <span className="text-amber-400/80 italic">Awaiting Review</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <Button
                        size="sm"
                        variant="secondary"
                        onClick={(e) => {
                          e.stopPropagation();
                          setSelectedReg(reg);
                          setShowRejectForm(false);
                          setActionError(null);
                        }}
                      >
                        Review
                      </Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}

        {/* ── Registration Details & Proof Review Modal ── */}
        {selectedReg && (
          <Modal
            isOpen={!!selectedReg}
            onClose={() => setSelectedReg(null)}
            title="Registration Proof Verification"
            maxWidth="3xl"
          >
            <div className="space-y-6 text-slate-200">
              {/* Status Header */}
              <div className="flex items-center justify-between p-4 rounded-xl bg-[#091526] border border-[#1e293b]">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 rounded-full bg-indigo-500/20 flex items-center justify-center text-indigo-400 font-bold">
                    {selectedReg.name.charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <h3 className="font-bold text-white text-base">{selectedReg.name}</h3>
                    <p className="text-xs text-slate-400">{selectedReg.email}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2">
                  {renderRoleBadge(selectedReg.role)}
                  {renderStatusBadge(selectedReg.status)}
                </div>
              </div>

              {/* Action Error Banner */}
              {actionError && (
                <div className="p-3 bg-rose-500/15 border border-rose-500/30 rounded-lg text-xs text-rose-300 flex items-center gap-2">
                  <AlertCircle className="w-4 h-4 shrink-0 text-rose-400" />
                  <span>{actionError}</span>
                </div>
              )}

              {/* Applicant Profile Information */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 bg-[#0d1c32] p-4 rounded-xl border border-[#1e293b]">
                <div>
                  <label className="text-[10px] uppercase font-semibold text-slate-400">
                    Full Name
                  </label>
                  <p className="text-sm font-medium text-white">{selectedReg.name}</p>
                </div>
                <div>
                  <label className="text-[10px] uppercase font-semibold text-slate-400">
                    Email Address
                  </label>
                  <p className="text-sm font-medium text-white">{selectedReg.email}</p>
                </div>
                <div>
                  <label className="text-[10px] uppercase font-semibold text-slate-400">
                    Phone / Mobile
                  </label>
                  <p className="text-sm font-medium text-white">{selectedReg.mobile || '—'}</p>
                </div>
                <div>
                  <label className="text-[10px] uppercase font-semibold text-slate-400">
                    Requested Role
                  </label>
                  <div className="mt-0.5">{renderRoleBadge(selectedReg.role)}</div>
                </div>
                {selectedReg.company_name && (
                  <div>
                    <label className="text-[10px] uppercase font-semibold text-slate-400">
                      Company Name
                    </label>
                    <p className="text-sm font-medium text-white">{selectedReg.company_name}</p>
                  </div>
                )}
                {selectedReg.college_name && (
                  <div>
                    <label className="text-[10px] uppercase font-semibold text-slate-400">
                      College / Institution
                    </label>
                    <p className="text-sm font-medium text-white">{selectedReg.college_name}</p>
                  </div>
                )}
                {selectedReg.qualification && (
                  <div>
                    <label className="text-[10px] uppercase font-semibold text-slate-400">
                      Qualification
                    </label>
                    <p className="text-sm font-medium text-white">{selectedReg.qualification}</p>
                  </div>
                )}
                <div>
                  <label className="text-[10px] uppercase font-semibold text-slate-400">
                    Submission Timestamp
                  </label>
                  <p className="text-sm font-medium text-white">
                    {formatDateTime(selectedReg.submitted_at || selectedReg.created_at)}
                  </p>
                </div>
              </div>

              {/* Uploaded Proof Document Section */}
              <div className="bg-[#0d1c32] p-4 rounded-xl border border-[#1e293b] space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <FileText className="w-5 h-5 text-indigo-400" />
                    <div>
                      <h4 className="text-xs font-semibold uppercase text-slate-300">
                        Uploaded Proof Document
                      </h4>
                      <p className="text-xs text-indigo-300">
                        {getProofDocTypeName(selectedReg.role, selectedReg.document_type)}
                      </p>
                    </div>
                  </div>
                </div>

                <div className="p-3 bg-[#091526] rounded-lg border border-[#1e293b] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                  <div>
                    <p className="text-sm font-medium text-white">{selectedReg.file_name}</p>
                    <p className="text-xs text-slate-400">
                      {formatBytes(selectedReg.file_size)} • {selectedReg.content_type}
                    </p>
                  </div>

                  <div className="flex items-center gap-2">
                    <button
                      onClick={() => setPreviewProofOpen(!previewProofOpen)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-[#15233e] hover:bg-[#1d3257] text-indigo-300 border border-indigo-500/30 rounded-lg transition-colors"
                    >
                      <Eye className="w-3.5 h-3.5" />
                      {previewProofOpen ? 'Hide Preview' : 'Preview Document'}
                    </button>
                    <button
                      onClick={() => handleDownloadProof(selectedReg)}
                      className="inline-flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium bg-[#15233e] hover:bg-[#1d3257] text-slate-200 border border-[#22395d] rounded-lg transition-colors"
                    >
                      <Download className="w-3.5 h-3.5" />
                      Download
                    </button>
                  </div>
                </div>

                {/* Inline Proof Preview */}
                {previewProofOpen && (
                  <div className="mt-3 p-2 bg-[#091526] rounded-lg border border-[#1e293b]">
                    {selectedReg.content_type?.startsWith('image/') ? (
                      <img
                        src={adminApi.getRegistrationProofUrl(selectedReg.id)}
                        alt="Submitted proof document"
                        className="max-h-96 mx-auto object-contain rounded"
                      />
                    ) : (
                      <iframe
                        src={adminApi.getRegistrationProofUrl(selectedReg.id)}
                        title="Document preview"
                        className="w-full h-96 rounded border border-slate-700"
                      />
                    )}
                  </div>
                )}
              </div>

              {/* Rejection / Approval History */}
              {selectedReg.status === 'APPROVED' && (
                <div className="p-4 bg-emerald-500/10 border border-emerald-500/30 rounded-xl space-y-1">
                  <div className="flex items-center gap-2 text-emerald-400 font-semibold text-sm">
                    <CheckCircle2 className="w-4 h-4" />
                    Approved by {selectedReg.reviewer_name || 'Administrator'}
                  </div>
                  <p className="text-xs text-slate-400">
                    Reviewed on {formatDateTime(selectedReg.reviewed_at)}. Application access has been granted.
                  </p>
                </div>
              )}

              {selectedReg.status === 'REJECTED' && (
                <div className="p-4 bg-rose-500/10 border border-rose-500/30 rounded-xl space-y-2">
                  <div className="flex items-center gap-2 text-rose-400 font-semibold text-sm">
                    <XCircle className="w-4 h-4" />
                    Rejected by {selectedReg.reviewer_name || 'Administrator'}
                  </div>
                  <p className="text-xs text-slate-400">
                    Reviewed on {formatDateTime(selectedReg.reviewed_at)}. Access remains restricted.
                  </p>
                  {selectedReg.rejection_reason && (
                    <div className="mt-2 p-2.5 bg-[#091526] rounded border border-rose-500/20 text-xs text-rose-200">
                      <span className="font-semibold block text-slate-400">Rejection Reason:</span>
                      {selectedReg.rejection_reason}
                    </div>
                  )}
                </div>
              )}

              {/* Reject Form Input */}
              {showRejectForm && (
                <div className="p-4 bg-rose-500/10 border border-rose-500/30 rounded-xl space-y-3">
                  <h4 className="text-xs font-bold uppercase text-rose-300">
                    Reason for Rejection (Required)
                  </h4>
                  <p className="text-xs text-slate-400">
                    This reason will be included in the rejection notification email sent to the applicant.
                  </p>
                  <textarea
                    value={rejectReason}
                    onChange={(e) => setRejectReason(e.target.value)}
                    placeholder="e.g. Uploaded document is blurry or does not match the required qualification certificate."
                    rows={3}
                    className="w-full p-2.5 text-xs bg-[#112340] border border-rose-500/40 text-white rounded-lg focus:outline-none focus:border-rose-400 placeholder:text-slate-500"
                  />
                  <div className="flex justify-end gap-2">
                    <Button
                      size="sm"
                      variant="secondary"
                      onClick={() => setShowRejectForm(false)}
                      disabled={isRejecting}
                    >
                      Cancel
                    </Button>
                    <Button
                      size="sm"
                      variant="danger"
                      onClick={handleReject}
                      disabled={isRejecting || !rejectReason.trim()}
                    >
                      {isRejecting ? 'Rejecting...' : 'Confirm Rejection'}
                    </Button>
                  </div>
                </div>
              )}

              {/* Action Buttons Footer */}
              <div className="flex items-center justify-between pt-4 border-t border-[#1e293b]">
                <Button variant="secondary" onClick={() => setSelectedReg(null)}>
                  Close
                </Button>

                {selectedReg.status === 'PENDING' && !showRejectForm && (
                  <div className="flex items-center gap-3">
                    <Button
                      variant="danger"
                      onClick={() => setShowRejectForm(true)}
                      disabled={isApproving || isRejecting}
                    >
                      Reject Registration
                    </Button>
                    <Button
                      variant="primary"
                      onClick={handleApprove}
                      disabled={isApproving || isRejecting}
                    >
                      {isApproving ? 'Approving...' : 'Approve Registration'}
                    </Button>
                  </div>
                )}
              </div>
            </div>
          </Modal>
        )}
      </div>
    </AdminShell>
  );
}


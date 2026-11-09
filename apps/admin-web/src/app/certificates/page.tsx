'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import {
  Award,
  Search,
  Filter,
  RefreshCw,
  ExternalLink,
  ShieldCheck,
  ShieldAlert,
  AlertCircle,
  CheckCircle2,
  XCircle,
  Copy,
  Check,
  FileText,
  User,
  Calendar,
} from 'lucide-react';

interface CredentialItem {
  id: string;
  studentId: string;
  studentName: string;
  studentEmail: string;
  studentIdentificationNumber?: string;
  type: string;
  title: string;
  description?: string;
  issuedAt: string;
  status: 'VALID' | 'REVOKED' | 'PENDING';
  revokedAt?: string;
  revocationReason?: string;
  verificationToken?: string;
  certificateObjectKey?: string;
}

export default function CertificatesPage() {
  const [credentials, setCredentials] = useState<CredentialItem[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Filters & Pagination
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [statusFilter, setStatusFilter] = useState<string>('ALL');
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 20;
  const [totalCount, setTotalCount] = useState<number>(0);

  // Revoke Modal State
  const [revokingCert, setRevokingCert] = useState<CredentialItem | null>(null);
  const [revokeReason, setRevokeReason] = useState<string>('');
  const [submittingRevoke, setSubmittingRevoke] = useState<boolean>(false);
  const [revokeError, setRevokeError] = useState<string | null>(null);

  // Reinstate Confirmation
  const [reinstatingCert, setReinstatingCert] = useState<CredentialItem | null>(null);
  const [submittingReinstate, setSubmittingReinstate] = useState<boolean>(false);

  // Copy feedback
  const [copiedId, setCopiedId] = useState<string | null>(null);

  const fetchCredentials = useCallback(async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getAdminCredentials({
        query: searchQuery.trim(),
        status: statusFilter,
        limit: pageSize,
        offset: (currentPage - 1) * pageSize,
      });

      setCredentials(data.credentials || []);
      setTotalCount(data.total || 0);
    } catch (err: any) {
      console.error('Failed to load certificates registry:', err);
      setError(err?.message || 'Unable to connect to authoritative certificate registry');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, [searchQuery, statusFilter, currentPage]);

  useEffect(() => {
    fetchCredentials();
  }, [fetchCredentials]);

  const handleCopy = (id: string) => {
    navigator.clipboard.writeText(id);
    setCopiedId(id);
    setTimeout(() => setCopiedId(null), 2000);
  };

  const handleRevokeConfirm = async () => {
    if (!revokingCert) return;
    if (!revokeReason.trim()) {
      setRevokeError('Please provide a mandatory revocation reason for administrative audit trail.');
      return;
    }

    setSubmittingRevoke(true);
    setRevokeError(null);

    try {
      await adminApi.revokeCredential(revokingCert.id, revokeReason.trim());
      setRevokingCert(null);
      setRevokeReason('');
      fetchCredentials(true);
    } catch (err: any) {
      setRevokeError(err?.message || 'Failed to revoke certificate');
    } finally {
      setSubmittingRevoke(false);
    }
  };

  const handleReinstateConfirm = async () => {
    if (!reinstatingCert) return;
    setSubmittingReinstate(true);

    try {
      await adminApi.reinstateCredential(reinstatingCert.id);
      setReinstatingCert(null);
      fetchCredentials(true);
    } catch (err: any) {
      alert(err?.message || 'Failed to reinstate certificate');
    } finally {
      setSubmittingReinstate(false);
    }
  };

  const validCount = credentials.filter((c) => c.status === 'VALID').length;
  const revokedCount = credentials.filter((c) => c.status === 'REVOKED').length;

  return (
    <AdminShell title="Certificates & Registry" backHref="/students" backLabel="Back to Students">
      <div className="space-y-6 max-w-7xl mx-auto pb-12">
        {/* Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-slate-200 pb-5">
          <div>
            <div className="flex items-center gap-2.5">
              <div className="p-2 rounded-xl bg-amber-50 border border-amber-200 text-amber-700">
                <Award className="h-6 w-6" />
              </div>
              <div>
                <h1 className="text-xl font-bold text-slate-900 tracking-tight">
                  Certificate Registry & Public Verification
                </h1>
                <p className="text-xs text-slate-500 font-mono mt-0.5">
                  Authoritative cryptographic credential governance · Draughtsman Studio & Archi Draft
                </p>
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <a
              href="https://www.draughtsmanstudio.com/verify"
              target="_blank"
              rel="noopener noreferrer"
              className="px-3.5 py-2 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-800 text-xs font-mono font-semibold flex items-center gap-1.5 transition-colors border border-slate-200"
            >
              <ExternalLink className="h-3.5 w-3.5 text-slate-500" />
              <span>Public Verification Portal</span>
            </a>
            <Button
              variant="outline"
              size="sm"
              onClick={() => fetchCredentials(true)}
              disabled={loading || refreshing}
              className="text-xs font-mono flex items-center gap-1.5"
            >
              <RefreshCw className={`h-3.5 w-3.5 ${refreshing ? 'animate-spin' : ''}`} />
              <span>{refreshing ? 'Syncing…' : 'Sync Registry'}</span>
            </Button>
          </div>
        </div>

        {/* Metric Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-4 gap-4">
          <Card className="p-4 border-slate-200 bg-white shadow-2xs">
            <p className="text-[10px] font-mono uppercase tracking-widest text-slate-500 font-bold mb-1">
              TOTAL RECORDED
            </p>
            <p className="text-2xl font-bold font-mono text-slate-900">{totalCount}</p>
            <p className="text-[11px] text-slate-400 font-mono mt-1">Authoritative D1 Ledger</p>
          </Card>

          <Card className="p-4 border-emerald-200 bg-emerald-50/40 shadow-2xs">
            <p className="text-[10px] font-mono uppercase tracking-widest text-emerald-700 font-bold mb-1">
              ACTIVE & VALID
            </p>
            <p className="text-2xl font-bold font-mono text-emerald-700">{validCount}</p>
            <p className="text-[11px] text-emerald-600 font-mono mt-1">Cryptographically Authenticated</p>
          </Card>

          <Card className="p-4 border-rose-200 bg-rose-50/40 shadow-2xs">
            <p className="text-[10px] font-mono uppercase tracking-widest text-rose-700 font-bold mb-1">
              FORMALLY REVOKED
            </p>
            <p className="text-2xl font-bold font-mono text-rose-700">{revokedCount}</p>
            <p className="text-[11px] text-rose-600 font-mono mt-1">Audit Actions Recorded</p>
          </Card>

          <Card className="p-4 border-blue-200 bg-blue-50/40 shadow-2xs">
            <p className="text-[10px] font-mono uppercase tracking-widest text-[#0453cd] font-bold mb-1">
              PUBLIC ACCESS
            </p>
            <div className="flex items-center gap-1.5 text-xs font-mono font-bold text-[#0453cd] mt-2">
              <ShieldCheck className="h-4 w-4 text-emerald-600" />
              <span>LIVE & VERIFIABLE</span>
            </div>
            <p className="text-[11px] text-slate-500 font-mono mt-1">QR Code & ID Resolution</p>
          </Card>
        </div>

        {/* Filter and Search Bar */}
        <Card className="p-4 border-slate-200 bg-white shadow-2xs">
          <div className="flex flex-col sm:flex-row items-center gap-3">
            <div className="relative flex-1 w-full">
              <Search className="h-4 w-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search by Certificate ID, Student Name, Email, or Title…"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === 'Enter') {
                    setCurrentPage(1);
                    fetchCredentials();
                  }
                }}
                className="w-full pl-9 pr-4 py-2 text-xs font-mono border border-slate-200 rounded-xl focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd]"
              />
            </div>

            <div className="flex items-center gap-2 w-full sm:w-auto">
              <div className="flex items-center gap-1.5 border border-slate-200 rounded-xl px-3 py-1.5 bg-slate-50 shrink-0">
                <Filter className="h-3.5 w-3.5 text-slate-400" />
                <span className="text-xs font-mono text-slate-500">Status:</span>
                <select
                  value={statusFilter}
                  onChange={(e) => {
                    setStatusFilter(e.target.value);
                    setCurrentPage(1);
                  }}
                  className="bg-transparent text-xs font-mono font-semibold text-slate-800 focus:outline-none cursor-pointer"
                >
                  <option value="ALL">All Statuses</option>
                  <option value="VALID">Valid Only</option>
                  <option value="REVOKED">Revoked Only</option>
                  <option value="PENDING">Pending Only</option>
                </select>
              </div>

              <Button
                size="sm"
                onClick={() => {
                  setCurrentPage(1);
                  fetchCredentials();
                }}
                className="text-xs font-mono bg-[#0a192f] hover:bg-slate-800 text-white shrink-0"
              >
                Filter
              </Button>
            </div>
          </div>
        </Card>

        {/* Error Notification */}
        {error && (
          <div className="p-4 rounded-xl border border-rose-200 bg-rose-50 text-rose-800 text-xs font-mono flex items-center justify-between">
            <div className="flex items-center gap-2">
              <AlertCircle className="h-4 w-4 shrink-0 text-rose-600" />
              <span>{error}</span>
            </div>
            <Button size="sm" variant="outline" onClick={() => fetchCredentials(true)} className="text-xs">
              Retry
            </Button>
          </div>
        )}

        {/* Credentials Table */}
        <Card className="border-slate-200 bg-white shadow-2xs overflow-hidden">
          <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
              <thead>
                <tr className="border-b border-slate-200 bg-slate-50 text-[10px] font-mono text-slate-500 uppercase tracking-widest">
                  <th className="py-3 px-4">Certificate ID</th>
                  <th className="py-3 px-4">Recipient</th>
                  <th className="py-3 px-4">Credential Title</th>
                  <th className="py-3 px-4">Issued At</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4 text-right">Administrative Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100 text-xs font-mono">
                {loading && credentials.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-12 text-center text-slate-400 font-mono">
                      <div className="h-6 w-6 animate-spin rounded-full border-2 border-[#0453cd] border-t-transparent mx-auto mb-2" />
                      Loading authoritative certificate registry…
                    </td>
                  </tr>
                ) : credentials.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-12 text-center text-slate-400 font-mono">
                      No certificates located matching query filters.
                    </td>
                  </tr>
                ) : (
                  credentials.map((cert) => {
                    const isRevoked = cert.status === 'REVOKED';
                    const isPending = cert.status === 'PENDING';
                    const verifyUrl = `https://www.draughtsmanstudio.com/verify?id=${encodeURIComponent(
                      cert.id
                    )}${cert.verificationToken ? `&token=${encodeURIComponent(cert.verificationToken)}` : ''}`;

                    return (
                      <tr key={cert.id} className="hover:bg-slate-50/80 transition-colors">
                        <td className="py-3.5 px-4 font-bold text-slate-900">
                          <div className="flex items-center gap-1.5">
                            <span className="font-mono text-xs">{cert.id}</span>
                            <button
                              onClick={() => handleCopy(cert.id)}
                              className="text-slate-400 hover:text-slate-600 transition-colors"
                              title="Copy Certificate ID"
                            >
                              {copiedId === cert.id ? (
                                <Check className="h-3 w-3 text-emerald-600" />
                              ) : (
                                <Copy className="h-3 w-3" />
                              )}
                            </button>
                          </div>
                          {cert.verificationToken && (
                            <p className="text-[10px] text-slate-400 font-mono truncate max-w-[140px]" title={cert.verificationToken}>
                              Hash: {cert.verificationToken.substring(0, 10)}…
                            </p>
                          )}
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="font-semibold text-slate-900">{cert.studentName}</div>
                          <div className="text-[11px] text-slate-400 truncate max-w-[180px]">{cert.studentEmail}</div>
                          {cert.studentIdentificationNumber && (
                            <span className="inline-block mt-0.5 text-[9px] px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200">
                              {cert.studentIdentificationNumber}
                            </span>
                          )}
                        </td>

                        <td className="py-3.5 px-4">
                          <div className="font-semibold text-slate-900">{cert.title}</div>
                          <div className="text-[11px] text-slate-400 capitalize">{cert.type.replace(/_/g, ' ')}</div>
                        </td>

                        <td className="py-3.5 px-4 text-slate-600 whitespace-nowrap">
                          {cert.issuedAt ? new Date(cert.issuedAt).toLocaleDateString() : '—'}
                        </td>

                        <td className="py-3.5 px-4">
                          {isRevoked ? (
                            <div>
                              <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-rose-50 border border-rose-200 text-rose-700">
                                <XCircle className="h-3 w-3 text-rose-600" /> REVOKED
                              </span>
                              {cert.revocationReason && (
                                <p className="text-[10px] text-rose-600 mt-1 truncate max-w-[160px]" title={cert.revocationReason}>
                                  {cert.revocationReason}
                                </p>
                              )}
                            </div>
                          ) : isPending ? (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-amber-50 border border-amber-200 text-amber-700">
                              PENDING
                            </span>
                          ) : (
                            <span className="inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-[10px] font-bold bg-emerald-50 border border-emerald-200 text-emerald-700">
                              <CheckCircle2 className="h-3 w-3 text-emerald-600" /> VALID
                            </span>
                          )}
                        </td>

                        <td className="py-3.5 px-4 text-right">
                          <div className="flex items-center justify-end gap-2">
                            <a
                              href={verifyUrl}
                              target="_blank"
                              rel="noopener noreferrer"
                              className="px-2.5 py-1.5 rounded-lg border border-slate-200 hover:border-slate-300 text-slate-700 hover:bg-slate-100 text-xs font-mono font-medium flex items-center gap-1 transition-colors"
                              title="Open public verification page"
                            >
                              <ExternalLink className="h-3 w-3 text-slate-400" />
                              <span>Verify</span>
                            </a>

                            {isRevoked ? (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => setReinstatingCert(cert)}
                                className="text-xs font-mono text-emerald-700 border-emerald-200 hover:bg-emerald-50"
                              >
                                Reinstate
                              </Button>
                            ) : (
                              <Button
                                size="sm"
                                variant="outline"
                                onClick={() => {
                                  setRevokingCert(cert);
                                  setRevokeReason('');
                                  setRevokeError(null);
                                }}
                                className="text-xs font-mono text-rose-700 border-rose-200 hover:bg-rose-50"
                              >
                                Revoke
                              </Button>
                            )}
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>

          {/* Pagination */}
          {totalCount > pageSize && (
            <div className="p-4 border-t border-slate-200 bg-slate-50 flex items-center justify-between text-xs font-mono text-slate-500">
              <span>
                Showing {(currentPage - 1) * pageSize + 1}–{Math.min(currentPage * pageSize, totalCount)} of {totalCount} records
              </span>
              <div className="flex items-center gap-2">
                <Button
                  size="sm"
                  variant="outline"
                  disabled={currentPage === 1}
                  onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                  className="text-xs"
                >
                  Previous
                </Button>
                <Button
                  size="sm"
                  variant="outline"
                  disabled={currentPage * pageSize >= totalCount}
                  onClick={() => setCurrentPage((p) => p + 1)}
                  className="text-xs"
                >
                  Next
                </Button>
              </div>
            </div>
          )}
        </Card>

        {/* Revoke Modal */}
        {revokingCert && (
          <Modal
            isOpen={!!revokingCert}
            onClose={() => setRevokingCert(null)}
            title="Administrative Certificate Revocation"
          >
            <div className="space-y-4">
              <div className="p-3.5 rounded-xl border border-rose-200 bg-rose-50 text-rose-800 text-xs font-mono space-y-1">
                <div className="font-bold flex items-center gap-1.5">
                  <ShieldAlert className="h-4 w-4 text-rose-600" />
                  <span>WARNING: FORMAL ACCREDITATION REVOCATION</span>
                </div>
                <p>
                  Revoking this certificate immediately marks it invalid on the public registry and QR code lookup portal.
                </p>
              </div>

              <div className="space-y-2 text-xs font-mono bg-slate-50 p-3.5 rounded-xl border border-slate-200">
                <p><strong>Certificate ID:</strong> {revokingCert.id}</p>
                <p><strong>Recipient:</strong> {revokingCert.studentName} ({revokingCert.studentEmail})</p>
                <p><strong>Credential:</strong> {revokingCert.title}</p>
              </div>

              <div className="space-y-1.5">
                <label className="text-xs font-bold font-mono text-slate-700 block">
                  Mandatory Audit Reason for Revocation:
                </label>
                <textarea
                  rows={3}
                  value={revokeReason}
                  onChange={(e) => setRevokeReason(e.target.value)}
                  placeholder="e.g. Disciplinary revocation, fraudulent submission, or administrative correction."
                  className="w-full text-xs font-mono border border-slate-200 rounded-xl p-3 focus:outline-none focus:ring-2 focus:ring-rose-500/20 focus:border-rose-500"
                />
              </div>

              {revokeError && (
                <p className="text-xs font-mono text-rose-600 font-semibold">{revokeError}</p>
              )}

              <div className="flex justify-end gap-2.5 pt-2">
                <Button variant="outline" size="sm" onClick={() => setRevokingCert(null)} disabled={submittingRevoke}>
                  Cancel
                </Button>
                <Button
                  size="sm"
                  onClick={handleRevokeConfirm}
                  disabled={submittingRevoke || !revokeReason.trim()}
                  className="bg-rose-600 hover:bg-rose-700 text-white text-xs font-mono"
                >
                  {submittingRevoke ? 'Revoking…' : 'Confirm Revocation'}
                </Button>
              </div>
            </div>
          </Modal>
        )}

        {/* Reinstate Modal */}
        {reinstatingCert && (
          <Modal
            isOpen={!!reinstatingCert}
            onClose={() => setReinstatingCert(null)}
            title="Reinstate Certificate Credential"
          >
            <div className="space-y-4">
              <p className="text-xs font-mono text-slate-600">
                Are you sure you want to reinstate certificate <strong>{reinstatingCert.id}</strong> for{' '}
                <strong>{reinstatingCert.studentName}</strong>?
              </p>
              <p className="text-xs font-mono text-slate-500">
                This will restore its status to <strong>VALID</strong> and re-enable positive verification on the public registry.
              </p>

              <div className="flex justify-end gap-2.5 pt-2">
                <Button variant="outline" size="sm" onClick={() => setReinstatingCert(null)} disabled={submittingReinstate}>
                  Cancel
                </Button>
                <Button
                  size="sm"
                  onClick={handleReinstateConfirm}
                  disabled={submittingReinstate}
                  className="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-mono"
                >
                  {submittingReinstate ? 'Reinstating…' : 'Reinstate Certificate'}
                </Button>
              </div>
            </div>
          </Modal>
        )}
      </div>
    </AdminShell>
  );
}

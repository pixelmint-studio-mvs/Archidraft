'use client';

import React, { useState, useEffect, useCallback } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { adminApi } from '@/lib/api';
import {
  LegalComplianceStats,
  LegalBusinessProfile,
  LegalDocumentAdmin,
  AdminConsentEvent,
  AdminAccountDeletionRequest,
  AdminDataExportRequest,
  AdminDataCorrectionRequest,
  AdminGuardianConsent,
  AdminCancellationRefundRequest,
  DataRetentionPolicy,
  AdminPrivacyRequest,
} from '@/lib/types';
import { LegalOverviewTab } from '@/components/legal/LegalOverviewTab';
import { BusinessProfileTab } from '@/components/legal/BusinessProfileTab';
import { DocumentRegistryTab } from '@/components/legal/DocumentRegistryTab';
import { ConsentAuditTab } from '@/components/legal/ConsentAuditTab';
import { AccountDeletionsTab } from '@/components/legal/AccountDeletionsTab';
import { DataExportsTab } from '@/components/legal/DataExportsTab';
import { DataCorrectionsTab } from '@/components/legal/DataCorrectionsTab';
import { GuardianConsentsTab } from '@/components/legal/GuardianConsentsTab';
import { CancellationRefundsTab } from '@/components/legal/CancellationRefundsTab';
import { RetentionPoliciesTab } from '@/components/legal/RetentionPoliciesTab';
import { PrivacyGrievancesTab } from '@/components/legal/PrivacyGrievancesTab';
import { DocumentReaderModal } from '@/components/legal/DocumentReaderModal';
import { DocumentDraftModal } from '@/components/legal/DocumentDraftModal';
import { PublishDocumentModal } from '@/components/legal/PublishDocumentModal';
import { ReviewActionModal, LegalReviewType } from '@/components/legal/ReviewActionModal';
import {
  ShieldCheck,
  Building2,
  FileText,
  UserCheck,
  UserX,
  DownloadCloud,
  Edit3,
  CreditCard,
  Archive,
  LifeBuoy,
  LayoutDashboard,
  AlertTriangle,
  CheckCircle2,
} from 'lucide-react';

type TabKey =
  | 'overview'
  | 'business'
  | 'documents'
  | 'consents'
  | 'deletions'
  | 'exports'
  | 'corrections'
  | 'guardians'
  | 'refunds'
  | 'retention'
  | 'grievances';

export default function LegalCompliancePage() {
  const [activeTab, setActiveTab] = useState<TabKey>('overview');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [notification, setNotification] = useState<{ type: 'success' | 'error'; message: string } | null>(null);

  // Data States
  const [stats, setStats] = useState<LegalComplianceStats | null>(null);
  const [businessProfile, setBusinessProfile] = useState<LegalBusinessProfile | null>(null);
  const [documents, setDocuments] = useState<LegalDocumentAdmin[]>([]);
  const [consents, setConsents] = useState<AdminConsentEvent[]>([]);
  const [deletionRequests, setDeletionRequests] = useState<AdminAccountDeletionRequest[]>([]);
  const [exportRequests, setExportRequests] = useState<AdminDataExportRequest[]>([]);
  const [correctionRequests, setCorrectionRequests] = useState<AdminDataCorrectionRequest[]>([]);
  const [guardianConsents, setGuardianConsents] = useState<AdminGuardianConsent[]>([]);
  const [refundRequests, setRefundRequests] = useState<AdminCancellationRefundRequest[]>([]);
  const [retentionPolicies, setRetentionPolicies] = useState<DataRetentionPolicy[]>([]);
  const [privacyRequests, setPrivacyRequests] = useState<AdminPrivacyRequest[]>([]);

  // Modal States
  const [viewingDoc, setViewingDoc] = useState<LegalDocumentAdmin | null>(null);
  const [publishingDoc, setPublishingDoc] = useState<LegalDocumentAdmin | null>(null);
  const [isDraftModalOpen, setIsDraftModalOpen] = useState<boolean>(false);
  const [reviewModalType, setReviewModalType] = useState<LegalReviewType | null>(null);
  const [reviewingItem, setReviewingItem] = useState<any>(null);

  const loadAllData = useCallback(async (isRefresh = false) => {
    if (isRefresh) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [
        statsRes,
        profileRes,
        docsRes,
        consentsRes,
        deletionsRes,
        exportsRes,
        correctionsRes,
        guardiansRes,
        refundsRes,
        retentionRes,
        privacyRes,
      ] = await Promise.allSettled([
        adminApi.getLegalStats(),
        adminApi.getLegalBusinessProfile(),
        adminApi.getLegalDocuments(),
        adminApi.getLegalConsentEvents(100),
        adminApi.getLegalAccountDeletionRequests(),
        adminApi.getLegalDataExportRequests(),
        adminApi.getLegalDataCorrectionRequests(),
        adminApi.getLegalGuardianConsents(),
        adminApi.getLegalCancellationRefundRequests(),
        adminApi.getLegalRetentionPolicies(),
        adminApi.getLegalPrivacyRequests(),
      ]);

      if (statsRes.status === 'fulfilled') setStats(statsRes.value);
      if (profileRes.status === 'fulfilled') setBusinessProfile(profileRes.value);
      if (docsRes.status === 'fulfilled') setDocuments(docsRes.value.documents || []);
      if (consentsRes.status === 'fulfilled') setConsents(consentsRes.value.events || []);
      if (deletionsRes.status === 'fulfilled') setDeletionRequests(deletionsRes.value.requests || []);
      if (exportsRes.status === 'fulfilled') setExportRequests(exportsRes.value.requests || []);
      if (correctionsRes.status === 'fulfilled') setCorrectionRequests(correctionsRes.value.requests || []);
      if (guardiansRes.status === 'fulfilled') setGuardianConsents(guardiansRes.value.guardianConsents || []);
      if (refundsRes.status === 'fulfilled') setRefundRequests(refundsRes.value.refundRequests || []);
      if (retentionRes.status === 'fulfilled') setRetentionPolicies(retentionRes.value.retentionPolicies || []);
      if (privacyRes.status === 'fulfilled') setPrivacyRequests(privacyRes.value.requests || []);
    } catch (err: any) {
      setError(err.message || 'Failed to load legal compliance datasets.');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadAllData();
  }, [loadAllData]);

  // Actions
  const handleCreateDraft = async (payload: any) => {
    await adminApi.createLegalDocumentDraft(payload);
    setNotification({ type: 'success', message: 'Legal policy draft created successfully in D1.' });
    loadAllData(true);
  };

  const handlePublishDoc = async (id: string) => {
    await adminApi.publishLegalDocument(id);
    setNotification({ type: 'success', message: 'Document atomically published as EFFECTIVE.' });
    loadAllData(true);
  };

  const handleReviewSubmit = async (payload: any) => {
    if (!reviewModalType || !reviewingItem) return;

    if (reviewModalType === 'DELETION') {
      await adminApi.updateLegalAccountDeletionRequest(reviewingItem.id, payload);
      setNotification({ type: 'success', message: 'Account deletion request updated.' });
    } else if (reviewModalType === 'EXPORT') {
      await adminApi.updateLegalDataExportRequest(reviewingItem.id, payload);
      setNotification({ type: 'success', message: 'Data export request status updated.' });
    } else if (reviewModalType === 'CORRECTION') {
      await adminApi.updateLegalDataCorrectionRequest(reviewingItem.id, payload);
      setNotification({ type: 'success', message: 'Data correction request reviewed and applied.' });
    } else if (reviewModalType === 'GUARDIAN') {
      await adminApi.updateLegalGuardianConsent(reviewingItem.id, payload);
      setNotification({ type: 'success', message: 'Guardian consent verification status updated.' });
    } else if (reviewModalType === 'REFUND') {
      await adminApi.updateLegalCancellationRefundRequest(reviewingItem.id, payload);
      setNotification({ type: 'success', message: 'Milestone refund decision recorded.' });
    } else if (reviewModalType === 'GRIEVANCE') {
      await adminApi.resolveLegalPrivacyRequest(reviewingItem.id, payload);
      setNotification({ type: 'success', message: 'Grievance ticket status updated.' });
    }

    setReviewModalType(null);
    setReviewingItem(null);
    loadAllData(true);
  };

  const pendingQueues = stats?.queues;

  const tabs: Array<{ id: TabKey; label: string; icon: React.ComponentType<{ className?: string }>; badge?: number }> = [
    { id: 'overview', label: 'Overview', icon: LayoutDashboard },
    { id: 'business', label: 'Business Profile', icon: Building2 },
    { id: 'documents', label: 'Documents Registry', icon: FileText, badge: stats?.documents?.pendingReview },
    { id: 'consents', label: 'Consent Audit', icon: ShieldCheck },
    { id: 'deletions', label: 'Account Erasures', icon: UserX, badge: pendingQueues?.pendingDeletions },
    { id: 'exports', label: 'Data Exports', icon: DownloadCloud, badge: pendingQueues?.pendingExports },
    { id: 'corrections', label: 'Data Corrections', icon: Edit3, badge: pendingQueues?.pendingCorrections },
    { id: 'guardians', label: 'Guardian Consents', icon: UserCheck, badge: pendingQueues?.pendingGuardians },
    { id: 'refunds', label: 'Cancellations & Refunds', icon: CreditCard, badge: pendingQueues?.pendingRefunds },
    { id: 'retention', label: 'Retention Policies', icon: Archive },
    { id: 'grievances', label: 'Privacy & Grievances', icon: LifeBuoy, badge: pendingQueues?.pendingPrivacyRequests },
  ];

  return (
    <AdminShell
      title="Legal & Compliance Center"
      subtitle="Statutory governance, DPDP Act 2023 compliance, policy lifecycle & user data rights"
      onRefresh={() => loadAllData(true)}
      isRefreshing={refreshing}
    >
      <div className="space-y-6 pb-12 select-none">
        {/* ── Notification Banner ── */}
        {notification && (
          <div
            className={`p-3.5 rounded-xl border flex items-center justify-between text-xs font-mono ${
              notification.type === 'success'
                ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
                : 'bg-rose-50 border-rose-200 text-rose-800'
            }`}
          >
            <div className="flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4" />
              <span>{notification.message}</span>
            </div>
            <button
              onClick={() => setNotification(null)}
              className="text-slate-400 hover:text-slate-600 font-bold"
            >
              &times;
            </button>
          </div>
        )}

        {/* ── Navigation Tabs ── */}
        <div className="border-b border-slate-200 overflow-x-auto scrollbar-none">
          <nav className="flex space-x-1 min-w-max pb-px">
            {tabs.map((tab) => {
              const Icon = tab.icon;
              const isActive = activeTab === tab.id;

              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`flex items-center gap-2 py-3 px-3.5 border-b-2 font-mono text-xs font-semibold transition-all ${
                    isActive
                      ? 'border-[#0453cd] text-[#0453cd] bg-white rounded-t-lg'
                      : 'border-transparent text-slate-500 hover:text-slate-800 hover:border-slate-300'
                  }`}
                >
                  <Icon className={`h-4 w-4 ${isActive ? 'text-[#0453cd]' : 'text-slate-400'}`} />
                  <span>{tab.label}</span>
                  {tab.badge !== undefined && tab.badge > 0 && (
                    <span className="ml-1 text-[10px] font-mono font-bold px-1.5 py-0.2 rounded-full bg-amber-100 text-amber-800 border border-amber-300">
                      {tab.badge}
                    </span>
                  )}
                </button>
              );
            })}
          </nav>
        </div>

        {/* ── Tab Content ── */}
        <div>
          {activeTab === 'overview' && (
            <LegalOverviewTab
              stats={stats}
              loading={loading}
              onNavigateTab={(tab) => setActiveTab(tab as TabKey)}
            />
          )}

          {activeTab === 'business' && (
            <BusinessProfileTab profile={businessProfile} loading={loading} />
          )}

          {activeTab === 'documents' && (
            <DocumentRegistryTab
              documents={documents}
              loading={loading}
              onViewDoc={(doc) => setViewingDoc(doc)}
              onCreateDraft={() => setIsDraftModalOpen(true)}
              onPublishDoc={(doc) => setPublishingDoc(doc)}
            />
          )}

          {activeTab === 'consents' && (
            <ConsentAuditTab
              events={consents}
              loading={loading}
              onRefresh={() => loadAllData(true)}
            />
          )}

          {activeTab === 'deletions' && (
            <AccountDeletionsTab
              requests={deletionRequests}
              loading={loading}
              onReviewRequest={(req) => {
                setReviewingItem(req);
                setReviewModalType('DELETION');
              }}
            />
          )}

          {activeTab === 'exports' && (
            <DataExportsTab
              requests={exportRequests}
              loading={loading}
              onReviewRequest={(req) => {
                setReviewingItem(req);
                setReviewModalType('EXPORT');
              }}
            />
          )}

          {activeTab === 'corrections' && (
            <DataCorrectionsTab
              requests={correctionRequests}
              loading={loading}
              onReviewRequest={(req) => {
                setReviewingItem(req);
                setReviewModalType('CORRECTION');
              }}
            />
          )}

          {activeTab === 'guardians' && (
            <GuardianConsentsTab
              consents={guardianConsents}
              loading={loading}
              onReviewConsent={(gc) => {
                setReviewingItem(gc);
                setReviewModalType('GUARDIAN');
              }}
            />
          )}

          {activeTab === 'refunds' && (
            <CancellationRefundsTab
              requests={refundRequests}
              loading={loading}
              onReviewRequest={(req) => {
                setReviewingItem(req);
                setReviewModalType('REFUND');
              }}
            />
          )}

          {activeTab === 'retention' && (
            <RetentionPoliciesTab policies={retentionPolicies} loading={loading} />
          )}

          {activeTab === 'grievances' && (
            <PrivacyGrievancesTab
              requests={privacyRequests}
              loading={loading}
              onReviewRequest={(req) => {
                setReviewingItem(req);
                setReviewModalType('GRIEVANCE');
              }}
            />
          )}
        </div>

        {/* ── Modals ── */}
        <DocumentReaderModal
          isOpen={!!viewingDoc}
          onClose={() => setViewingDoc(null)}
          document={viewingDoc}
          onPublish={(doc) => setPublishingDoc(doc)}
        />

        <DocumentDraftModal
          isOpen={isDraftModalOpen}
          onClose={() => setIsDraftModalOpen(false)}
          onSubmit={handleCreateDraft}
        />

        <PublishDocumentModal
          isOpen={!!publishingDoc}
          onClose={() => setPublishingDoc(null)}
          document={publishingDoc}
          onConfirmPublish={handlePublishDoc}
        />

        <ReviewActionModal
          isOpen={!!reviewModalType && !!reviewingItem}
          onClose={() => {
            setReviewModalType(null);
            setReviewingItem(null);
          }}
          reviewType={reviewModalType}
          item={reviewingItem}
          onSubmit={handleReviewSubmit}
        />
      </div>
    </AdminShell>
  );
}

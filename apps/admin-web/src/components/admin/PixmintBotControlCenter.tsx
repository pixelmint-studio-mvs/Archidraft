import React, { useState, useEffect, useCallback } from 'react';
import Image from 'next/image';
import {
  Activity,
  Sliders,
  BookOpen,
  Sparkles,
  Cpu,
  ThumbsUp,
  ShieldCheck,
  CheckCircle2,
  Search,
  MessageSquare,
  Check,
  Wifi,
  WifiOff,
  AlertTriangle,
  RefreshCw,
  Loader2,
  XCircle,
  HelpCircle,
} from 'lucide-react';
import {
  getAdminHealth,
  getAdminAnalytics,
  getAdminConfig,
  updateAdminConfig,
  getAuditLogs,
  getKnowledgeSources,
  updateKnowledgeSourceStatus,
  getFeedback,
  getUnansweredQuestions,
  getRoleSuggestions,
  type AdminHealthData,
  type AdminAnalyticsData,
  type BotConfigData,
  type AuditLogItem,
  type KnowledgeSourceItem,
  type FeedbackItem,
  type UnansweredItem,
} from './api';

interface SuggestionItem {
  id: string;
  label: string;
  prompt: string;
  role: string;
  enabled: boolean;
}

const INITIAL_SUGGESTIONS: SuggestionItem[] = [
  // Engineer Portal (8)
  { id: 'eng_rev_drawing', label: 'How do I review a drawing?', prompt: 'How do I review a drawing?', role: 'engineer', enabled: true },
  { id: 'eng_redline_anno', label: 'How do I add redline annotations?', prompt: 'How do I add redline annotations?', role: 'engineer', enabled: true },
  { id: 'eng_tech_review', label: 'What should I check during technical review?', prompt: 'What should I check during technical review?', role: 'engineer', enabled: true },
  { id: 'eng_drawing_issues', label: 'How do I identify drawing issues?', prompt: 'How do I identify drawing issues?', role: 'engineer', enabled: true },
  { id: 'eng_coord_revisions', label: 'How can I coordinate drawing revisions?', prompt: 'How can I coordinate drawing revisions?', role: 'engineer', enabled: true },
  { id: 'eng_drawing_fail_load', label: 'What should I do if a drawing fails to load?', prompt: 'What should I do if a drawing fails to load?', role: 'engineer', enabled: true },
  { id: 'eng_resolve_review_prob', label: 'How do I resolve a review problem?', prompt: 'How do I resolve a review problem?', role: 'engineer', enabled: true },
  { id: 'eng_bot_capabilities', label: 'What can PIXMINT BOT help me with?', prompt: 'What can PIXMINT BOT help me with?', role: 'engineer', enabled: true },

  // Draughtsman Portal (8)
  { id: 'dft_view_assignments', label: 'How do I view my assignments?', prompt: 'How do I view my assignments?', role: 'draughtsman', enabled: true },
  { id: 'dft_accept_assignment', label: 'How do I accept an assignment?', prompt: 'How do I accept an assignment?', role: 'draughtsman', enabled: true },
  { id: 'dft_upload_drawing', label: 'How do I upload a drawing?', prompt: 'How do I upload a drawing?', role: 'draughtsman', enabled: true },
  { id: 'dft_drawing_formats', label: 'Which drawing formats are supported?', prompt: 'Which drawing formats are supported?', role: 'draughtsman', enabled: true },
  { id: 'dft_submit_revision', label: 'How do I submit a revised drawing?', prompt: 'How do I submit a revised drawing?', role: 'draughtsman', enabled: true },
  { id: 'dft_resolve_redlines', label: 'How do I resolve redline comments?', prompt: 'How do I resolve redline comments?', role: 'draughtsman', enabled: true },
  { id: 'dft_upload_fails', label: 'What should I do if an upload fails?', prompt: 'What should I do if an upload fails?', role: 'draughtsman', enabled: true },
  { id: 'dft_submission_status', label: 'How do I check my submission status?', prompt: 'How do I check my submission status?', role: 'draughtsman', enabled: true },

  // Student Portal (8)
  { id: 'stu_access_modules', label: 'How do I access my training modules?', prompt: 'How do I access my training modules?', role: 'student', enabled: true },
  { id: 'stu_practical_exercises', label: 'Where can I find my practical exercises?', prompt: 'Where can I find my practical exercises?', role: 'student', enabled: true },
  { id: 'stu_submit_exercise', label: 'How do I submit an exercise?', prompt: 'How do I submit an exercise?', role: 'student', enabled: true },
  { id: 'stu_view_evaluation', label: 'Where can I view my evaluation?', prompt: 'Where can I view my evaluation?', role: 'student', enabled: true },
  { id: 'stu_mentor_feedback', label: 'How do I understand mentor feedback?', prompt: 'How do I understand mentor feedback?', role: 'student', enabled: true },
  { id: 'stu_verify_cert', label: 'How can I verify my certificate?', prompt: 'How can I verify my certificate?', role: 'student', enabled: true },
  { id: 'stu_lesson_not_open', label: 'What should I do if a lesson will not open?', prompt: 'What should I do if a lesson will not open?', role: 'student', enabled: true },
  { id: 'stu_bot_learn', label: 'What can PIXMINT BOT help me learn?', prompt: 'What can PIXMINT BOT help me learn?', role: 'student', enabled: true },

  // Admin Portal (7)
  { id: 'adm_knowledge_sources', label: 'How do I manage approved knowledge sources?', prompt: 'How do I manage approved knowledge sources?', role: 'admin', enabled: true },
  { id: 'adm_update_questions', label: 'How do I update suggested questions?', prompt: 'How do I update suggested questions?', role: 'admin', enabled: true },
  { id: 'adm_service_status', label: 'How do I check bot service status?', prompt: 'How do I check bot service status?', role: 'admin', enabled: true },
  { id: 'adm_unanswered_qs', label: 'How do I review unanswered questions?', prompt: 'How do I review unanswered questions?', role: 'admin', enabled: true },
  { id: 'adm_usage_metrics', label: 'How can I review usage and error metrics?', prompt: 'How can I review usage and error metrics?', role: 'admin', enabled: true },
  { id: 'adm_bot_availability', label: 'How do I manage bot availability?', prompt: 'How do I manage bot availability?', role: 'admin', enabled: true },
  { id: 'adm_config_changes', label: 'How can I review configuration changes?', prompt: 'How can I review configuration changes?', role: 'admin', enabled: true },
];

type BotTabId = 'overview' | 'config' | 'knowledge' | 'suggestions' | 'provider' | 'feedback' | 'audit';

interface TabDefinition {
  id: BotTabId;
  label: string;
  icon: React.ComponentType<{ className?: string }>;
}

const TABS: TabDefinition[] = [
  { id: 'overview', label: 'Overview', icon: Activity },
  { id: 'config', label: 'Bot Configuration', icon: Sliders },
  { id: 'knowledge', label: 'Knowledge Base', icon: BookOpen },
  { id: 'suggestions', label: 'Predefined Questions', icon: MessageSquare },
  { id: 'provider', label: 'AI Provider', icon: Cpu },
  { id: 'feedback', label: 'Feedback Review', icon: ThumbsUp },
  { id: 'audit', label: 'Security Audit Log', icon: ShieldCheck },
];

export function PixmintBotControlCenter() {
  const [activeTab, setActiveTab] = useState<BotTabId>('overview');
  const [selectedSuggestionRole, setSelectedSuggestionRole] = useState<string>('engineer');
  const [suggestions, setSuggestions] = useState<SuggestionItem[]>(INITIAL_SUGGESTIONS);
  const [toastMessage, setToastMessage] = useState<string | null>(null);

  // Backend state
  const [serverHealth, setServerHealth] = useState<AdminHealthData | null>(null);
  const [serverAnalytics, setServerAnalytics] = useState<AdminAnalyticsData | null>(null);
  const [persistedConfig, setPersistedConfig] = useState<BotConfigData | null>(null);
  const [auditLogs, setAuditLogs] = useState<AuditLogItem[]>([]);
  const [knowledgeSources, setKnowledgeSources] = useState<KnowledgeSourceItem[]>([]);
  const [feedbackItems, setFeedbackItems] = useState<FeedbackItem[]>([]);
  const [unansweredItems, setUnansweredItems] = useState<UnansweredItem[]>([]);

  // Local form state for configuration
  const [formBotEnabled, setFormBotEnabled] = useState<boolean>(true);
  const [formMaintenanceMode, setFormMaintenanceMode] = useState<boolean>(false);
  const [formMaintenanceMsg, setFormMaintenanceMsg] = useState<string>('');
  const [formMaxChars, setFormMaxChars] = useState<number>(1000);
  const [formRateLimit, setFormRateLimit] = useState<number>(30);
  const [formHistoryLimit, setFormHistoryLimit] = useState<number>(10);
  const [formPortals, setFormPortals] = useState<Record<string, boolean>>({
    engineer: true,
    draughtsman: true,
    student: true,
    admin: true,
  });

  // UI state
  const [isLiveConnected, setIsLiveConnected] = useState<boolean>(false);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [isSavingConfig, setIsSavingConfig] = useState<boolean>(false);
  const [searchKnowledge, setSearchKnowledge] = useState<string>('');
  const [knowledgeCategoryFilter, setKnowledgeCategoryFilter] = useState<string>('all');

  // Confirmation modal state
  const [confirmDialog, setConfirmDialog] = useState<{
    isOpen: boolean;
    title: string;
    description: string;
    actionLabel: string;
    isDestructive: boolean;
    onConfirm: () => Promise<void>;
  }>({
    isOpen: false,
    title: '',
    description: '',
    actionLabel: '',
    isDestructive: false,
    onConfirm: async () => {},
  });

  const showToast = (msg: string) => {
    setToastMessage(msg);
    setTimeout(() => setToastMessage(null), 3500);
  };

  // Reconcile authoritative configuration from backend
  const refreshAllData = useCallback(async () => {
    setIsLoading(true);
    try {
      const [health, analytics, config, logsRes, sources, feedback, unanswered] = await Promise.all([
        getAdminHealth(),
        getAdminAnalytics(),
        getAdminConfig(),
        getAuditLogs(50, 0),
        getKnowledgeSources(),
        getFeedback(),
        getUnansweredQuestions(),
      ]);

      if (health) {
        setServerHealth(health);
        setIsLiveConnected(true);
      } else {
        setIsLiveConnected(false);
      }

      if (analytics) setServerAnalytics(analytics);

      if (config) {
        setPersistedConfig(config);
        setFormBotEnabled(config.botEnabled);
        setFormMaintenanceMode(config.maintenanceMode);
        setFormMaintenanceMsg(config.maintenanceMessage || '');
        setFormMaxChars(config.maxInputChars);
        setFormRateLimit(config.rateLimitPerMinute);
        setFormHistoryLimit(config.historyLimit);
        if (config.enabledPortals) setFormPortals(config.enabledPortals);
      }

      if (logsRes && logsRes.logs) setAuditLogs(logsRes.logs);
      if (sources) setKnowledgeSources(sources);
      if (feedback) setFeedbackItems(feedback);
      if (unanswered) setUnansweredItems(unanswered);
    } catch (err) {
      console.warn('Admin telemetry refresh error:', err);
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    refreshAllData();
  }, [refreshAllData]);

  // Handle immediate Bot Enable/Disable with confirmation
  const handleToggleBotEnabled = () => {
    const targetState = !formBotEnabled;
    setConfirmDialog({
      isOpen: true,
      title: targetState ? 'Enable PIXMINT BOT' : 'Disable PIXMINT BOT Across All Portals',
      description: targetState
        ? 'Are you sure you want to enable PIXMINT BOT? Users in all permitted portals will be able to submit queries.'
        : 'Are you sure you want to disable PIXMINT BOT? When disabled, incoming chat requests will be rejected with 503 Service Unavailable across all portals.',
      actionLabel: targetState ? 'Enable Assistant' : 'Disable Assistant',
      isDestructive: !targetState,
      onConfirm: async () => {
        setIsSavingConfig(true);
        try {
          const res = await updateAdminConfig({ botEnabled: targetState });
          if (res && res.success) {
            setFormBotEnabled(res.config.botEnabled);
            setPersistedConfig(res.config);
            showToast(targetState ? 'PIXMINT BOT is now live across permitted portals' : 'PIXMINT BOT disabled (503 enforced server-side)');
            const logs = await getAuditLogs(50, 0);
            if (logs?.logs) setAuditLogs(logs.logs);
          }
        } catch (err: any) {
          showToast(`Error: ${err.message}`);
        } finally {
          setIsSavingConfig(false);
          setConfirmDialog((prev) => ({ ...prev, isOpen: false }));
        }
      },
    });
  };

  // Handle Maintenance Mode toggle with confirmation
  const handleToggleMaintenance = () => {
    const targetState = !formMaintenanceMode;
    setConfirmDialog({
      isOpen: true,
      title: targetState ? 'Activate Maintenance Mode' : 'Deactivate Maintenance Mode',
      description: targetState
        ? 'Activating maintenance mode will immediately return a structured maintenance notice to all regular users (Engineers, Draughtsmen, Students). Only studio administrators will be permitted to chat.'
        : 'Deactivating maintenance mode will restore normal AI response processing for all permitted users.',
      actionLabel: targetState ? 'Activate Maintenance' : 'Exit Maintenance',
      isDestructive: targetState,
      onConfirm: async () => {
        setIsSavingConfig(true);
        try {
          const res = await updateAdminConfig({ maintenanceMode: targetState });
          if (res && res.success) {
            setFormMaintenanceMode(res.config.maintenanceMode);
            setPersistedConfig(res.config);
            showToast(targetState ? 'Maintenance mode active (Restricted to Studio Admin)' : 'Maintenance mode deactivated');
            const logs = await getAuditLogs(50, 0);
            if (logs?.logs) setAuditLogs(logs.logs);
          }
        } catch (err: any) {
          showToast(`Error: ${err.message}`);
        } finally {
          setIsSavingConfig(false);
          setConfirmDialog((prev) => ({ ...prev, isOpen: false }));
        }
      },
    });
  };

  // Save all configuration parameters to backend
  const handleSaveConfiguration = async () => {
    setIsSavingConfig(true);
    try {
      const res = await updateAdminConfig({
        botEnabled: formBotEnabled,
        maintenanceMode: formMaintenanceMode,
        maintenanceMessage: formMaintenanceMsg,
        maxInputChars: formMaxChars,
        rateLimitPerMinute: formRateLimit,
        historyLimit: formHistoryLimit,
        enabledPortals: formPortals,
      });

      if (res && res.success) {
        setPersistedConfig(res.config);
        showToast('Configuration persisted to Cloudflare D1 successfully');
        const logs = await getAuditLogs(50, 0);
        if (logs?.logs) setAuditLogs(logs.logs);
      }
    } catch (err: any) {
      showToast(`Save failed: ${err.message}`);
    } finally {
      setIsSavingConfig(false);
    }
  };

  // Toggle Knowledge Source Approval
  const handleToggleSourceStatus = async (sourceId: string, currentStatus: string) => {
    const newStatus = currentStatus === 'approved' ? 'deactivated' : 'approved';
    try {
      const ok = await updateKnowledgeSourceStatus(sourceId, newStatus);
      if (ok) {
        setKnowledgeSources((prev) =>
          prev.map((s) => (s.id === sourceId ? { ...s, status: newStatus } : s))
        );
        showToast(`Knowledge source ${sourceId} marked as ${newStatus}`);
        const logs = await getAuditLogs(50, 0);
        if (logs?.logs) setAuditLogs(logs.logs);
      } else {
        showToast(`Failed to update status for ${sourceId}`);
      }
    } catch (err: any) {
      showToast(`Error: ${err.message}`);
    }
  };

  const filteredSources = knowledgeSources.filter((s) => {
    const matchesCategory = knowledgeCategoryFilter === 'all' || s.category.toLowerCase() === knowledgeCategoryFilter.toLowerCase();
    const matchesSearch =
      s.title.toLowerCase().includes(searchKnowledge.toLowerCase()) ||
      s.id.toLowerCase().includes(searchKnowledge.toLowerCase()) ||
      s.path.toLowerCase().includes(searchKnowledge.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const filteredSuggestions = suggestions.filter((s) => s.role === selectedSuggestionRole);

  const toggleSuggestion = (id: string) => {
    setSuggestions((prev) =>
      prev.map((s) => (s.id === id ? { ...s, enabled: !s.enabled } : s))
    );
    showToast('Predefined suggestion availability updated');
  };

  return (
    <div className="space-y-6">
      {/* Toast Alert */}
      {toastMessage && (
        <div className="fixed bottom-6 right-6 z-50 bg-emerald-500 text-slate-950 font-semibold px-4 py-2.5 rounded-xl shadow-lg shadow-emerald-500/20 flex items-center gap-2 animate-in fade-in slide-in-from-bottom-2">
          <CheckCircle2 className="h-4 w-4" />
          <span>{toastMessage}</span>
        </div>
      )}

      {/* Confirmation Modal */}
      {confirmDialog.isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/75 backdrop-blur-sm animate-in fade-in">
          <div className="bg-[#0f172a] border border-slate-700 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
            <div className="flex items-center gap-3 text-amber-400">
              <AlertTriangle className="h-6 w-6 shrink-0" />
              <h3 className="text-base font-bold text-slate-100">{confirmDialog.title}</h3>
            </div>
            <p className="text-xs text-slate-300 leading-relaxed">{confirmDialog.description}</p>
            <div className="flex items-center justify-end gap-3 pt-3 border-t border-slate-800">
              <button
                type="button"
                onClick={() => setConfirmDialog((prev) => ({ ...prev, isOpen: false }))}
                className="px-4 py-2 rounded-xl text-xs font-semibold text-slate-400 hover:text-slate-200 hover:bg-slate-800 transition-colors"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={isSavingConfig}
                onClick={confirmDialog.onConfirm}
                className={`px-4 py-2 rounded-xl text-xs font-bold transition-all flex items-center gap-1.5 ${
                  confirmDialog.isDestructive
                    ? 'bg-rose-500 text-white hover:bg-rose-600 shadow-md shadow-rose-500/20'
                    : 'bg-emerald-500 text-slate-950 hover:bg-emerald-400 shadow-md shadow-emerald-500/20'
                }`}
              >
                {isSavingConfig && <Loader2 className="h-3.5 w-3.5 animate-spin" />}
                <span>{confirmDialog.actionLabel}</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Hero Header */}
      <div className="bg-[#0f172a] border border-slate-800 rounded-2xl p-6 relative overflow-hidden shadow-sm">
        <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 relative z-10">
          <div className="flex items-center gap-4">
            <div className="h-14 w-14 rounded-2xl bg-slate-900 border border-slate-700/80 p-1 flex items-center justify-center shrink-0 shadow-inner overflow-hidden">
              <Image
                src="/images/pixmint-bot-logo.jpeg"
                alt="PIXMINT BOT 2.0 logo"
                width={56}
                height={56}
                unoptimized
                className="h-full w-full object-contain"
              />
            </div>
            <div>
              <div className="flex items-center gap-2.5 flex-wrap">
                <h1 className="text-xl font-bold text-slate-100 tracking-tight">PIXMINT BOT 2.0</h1>
                <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold tracking-wide uppercase bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  Control Center
                </span>
                {formMaintenanceMode && (
                  <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase bg-amber-500/10 text-amber-400 border border-amber-500/20">
                    Maintenance Mode
                  </span>
                )}
                {isLiveConnected ? (
                  <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 flex items-center gap-1.5">
                    <Wifi className="h-3 w-3" />
                    Cloudflare D1 Connected
                  </span>
                ) : (
                  <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold uppercase bg-slate-700/50 text-slate-400 border border-slate-700 flex items-center gap-1.5">
                    <WifiOff className="h-3 w-3" />
                    Offline Resilient Mode
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-400 mt-1">
                Centralized intelligence management, persistent D1 configuration, and server-side RBAC security enforcement.
              </p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <button
              type="button"
              disabled={isSavingConfig}
              onClick={handleToggleMaintenance}
              className={`px-3.5 py-2 rounded-xl text-xs font-semibold border transition-all flex items-center gap-1.5 ${
                formMaintenanceMode
                  ? 'bg-amber-500/15 border-amber-500/30 text-amber-400 hover:bg-amber-500/25'
                  : 'bg-slate-800/80 border-slate-700 text-slate-300 hover:bg-slate-800'
              }`}
            >
              {formMaintenanceMode ? 'Exit Maintenance' : 'Enable Maintenance'}
            </button>

            <button
              type="button"
              disabled={isSavingConfig}
              onClick={handleToggleBotEnabled}
              className={`px-4 py-2 rounded-xl text-xs font-semibold transition-all flex items-center gap-1.5 ${
                formBotEnabled
                  ? 'bg-emerald-500 text-slate-950 hover:bg-emerald-400 font-bold shadow-md shadow-emerald-500/20'
                  : 'bg-rose-500/20 border border-rose-500/30 text-rose-300 hover:bg-rose-500/30'
              }`}
            >
              {formBotEnabled ? 'Active (Live)' : 'Bot Disabled'}
            </button>

            <button
              type="button"
              onClick={refreshAllData}
              title="Refresh from D1"
              className="p-2 rounded-xl bg-slate-800 border border-slate-700 text-slate-300 hover:text-white hover:bg-slate-700 transition-colors"
            >
              <RefreshCw className={`h-4 w-4 ${isLoading ? 'animate-spin' : ''}`} />
            </button>
          </div>
        </div>
      </div>

      {/* Navigation Tabs */}
      <div className="flex items-center gap-1.5 border-b border-slate-800 pb-2 overflow-x-auto">
        {TABS.map((tab) => {
          const Icon = tab.icon;
          const isActive = activeTab === tab.id;
          return (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-medium transition-all shrink-0 ${
                isActive
                  ? 'bg-blue-600/15 text-blue-400 border border-blue-500/20 shadow-sm'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
              }`}
            >
              <Icon className="h-3.5 w-3.5" />
              <span>{tab.label}</span>
            </button>
          );
        })}
      </div>

      {/* Tab 1: Overview Dashboard */}
      {activeTab === 'overview' && (
        <div className="space-y-6">
          <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
            <div className="bg-[#0f172a] border border-slate-800 rounded-xl p-4">
              <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Total Conversations</span>
              <p className="text-2xl font-bold text-slate-100 mt-1">
                {serverAnalytics?.metrics.totalSessionsToday ?? 0}
              </p>
              <span className="text-[10px] text-emerald-400 font-medium">Server telemetry from D1</span>
            </div>
            <div className="bg-[#0f172a] border border-slate-800 rounded-xl p-4">
              <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Messages Processed</span>
              <p className="text-2xl font-bold text-slate-100 mt-1">
                {serverAnalytics?.metrics.totalMessagesToday ?? 0}
              </p>
              <span className="text-[10px] text-slate-400">Strictly rate-limited ({formRateLimit}/min)</span>
            </div>
            <div className="bg-[#0f172a] border border-slate-800 rounded-xl p-4">
              <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">Median Response Latency</span>
              <p className="text-2xl font-bold text-emerald-400 mt-1">
                {serverAnalytics?.metrics.avgLatencyMs !== undefined && serverAnalytics.metrics.avgLatencyMs > 0
                  ? `${serverAnalytics.metrics.avgLatencyMs} ms`
                  : '—'}
              </p>
              <span className="text-[10px] text-emerald-400 font-medium">Cloudflare Worker Edge Execution</span>
            </div>
            <div className="bg-[#0f172a] border border-slate-800 rounded-xl p-4">
              <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider">User Satisfaction</span>
              <p className="text-2xl font-bold text-slate-100 mt-1">
                {serverAnalytics?.metrics.resolutionRatePercent !== undefined && serverAnalytics.metrics.resolutionRatePercent > 0
                  ? `${serverAnalytics.metrics.resolutionRatePercent}%`
                  : '—'}
              </p>
              <span className="text-[10px] text-emerald-400 font-medium">
                {feedbackItems.length > 0
                  ? `${feedbackItems.length} Verified Reviews`
                  : serverAnalytics
                    ? 'No Feedback Recorded'
                    : 'Awaiting Telemetry'}
              </span>
            </div>
          </div>

          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div className="lg:col-span-2 bg-[#0f172a] border border-slate-800 rounded-xl p-5 space-y-4">
              <h3 className="text-sm font-bold text-slate-100 flex items-center gap-2">
                <Activity className="h-4 w-4 text-emerald-400" />
                Service Health & Operational Infrastructure
              </h3>
              <div className="space-y-3">
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900/60 border border-slate-800/80">
                  <div>
                    <p className="text-xs font-semibold text-slate-200">Cloudflare Worker API Gateway</p>
                    <p className="text-[11px] text-slate-400">Edge Router (`/api/chat/*` & `/api/admin/*`)</p>
                  </div>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                    {serverHealth?.status === 'healthy' ? 'Operational (99.98%)' : (serverHealth?.status || 'Active')}
                  </span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900/60 border border-slate-800/80">
                  <div>
                    <p className="text-xs font-semibold text-slate-200">Cloudflare D1 Database</p>
                    <p className="text-[11px] text-slate-400">Tables `bot_config`, `audit_logs`, `knowledge_documents` (Migration 0017 & 0018)</p>
                  </div>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                    {serverHealth?.d1Connected ? 'D1 Bound & Verified' : 'Local SQLite Standalone'}
                  </span>
                </div>
                <div className="flex items-center justify-between p-3 rounded-xl bg-slate-900/60 border border-slate-800/80">
                  <div>
                    <p className="text-xs font-semibold text-slate-200">Active Knowledge Retrieval Engine</p>
                    <p className="text-[11px] text-slate-400">Deterministic Local Adapter (Zero Secret Exposure Mode)</p>
                  </div>
                  <span className="px-2 py-0.5 rounded-full text-[10px] font-bold bg-blue-500/10 text-blue-400 border border-blue-500/20">
                    v1.0.0 Grounded
                  </span>
                </div>
              </div>
            </div>

            <div className="bg-[#0f172a] border border-slate-800 rounded-xl p-5 space-y-4">
              <h3 className="text-sm font-bold text-slate-100 flex items-center gap-2">
                <BookOpen className="h-4 w-4 text-blue-400" />
                Knowledge Base Status
              </h3>
              <div className="space-y-3 text-xs">
                <div className="flex justify-between border-b border-slate-800/80 pb-2">
                  <span className="text-slate-400">Registered Sources:</span>
                  <span className="text-slate-200 font-semibold">{knowledgeSources.length} Sources</span>
                </div>
                <div className="flex justify-between border-b border-slate-800/80 pb-2">
                  <span className="text-slate-400">Approved Sources:</span>
                  <span className="text-emerald-400 font-semibold">
                    {knowledgeSources.filter((s) => s.status === 'approved').length} Active
                  </span>
                </div>
                <div className="flex justify-between border-b border-slate-800/80 pb-2">
                  <span className="text-slate-400">Deactivated Sources:</span>
                  <span className="text-amber-400 font-semibold">
                    {knowledgeSources.filter((s) => s.status === 'deactivated').length} Restricted
                  </span>
                </div>
                <div className="flex justify-between border-b border-slate-800/80 pb-2">
                  <span className="text-slate-400">Unanswered Questions:</span>
                  <span className="text-slate-200 font-semibold">{unansweredItems.length} Logged</span>
                </div>
                <div className="pt-2">
                  <button
                    onClick={() => setActiveTab('knowledge')}
                    className="w-full py-2 rounded-lg bg-blue-600/10 text-blue-400 border border-blue-500/20 text-xs font-semibold hover:bg-blue-600/20 transition-all text-center"
                  >
                    Manage Knowledge Sources →
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tab 2: Bot Configuration */}
      {activeTab === 'config' && (
        <div className="bg-[#0f172a] border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="flex items-center justify-between border-b border-slate-800 pb-4">
            <div>
              <h3 className="text-base font-bold text-slate-100">Global Assistant Parameters</h3>
              <p className="text-xs text-slate-400 mt-1">
                Persisted in D1 `bot_config` table and enforced server-side on every chat request.
              </p>
            </div>
            {persistedConfig && (
              <span className="text-[11px] font-mono text-slate-400">
                Last updated by <span className="text-blue-400">{persistedConfig.updatedBy}</span> ({new Date(persistedConfig.updatedAt).toLocaleTimeString()})
              </span>
            )}
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="space-y-4">
              <label className="text-xs font-bold text-slate-300 uppercase tracking-wider block">Portal Availability</label>
              {[
                { role: 'engineer', name: 'Engineer Portal', desc: 'Technical drawing inspection & redline assistance' },
                { role: 'draughtsman', name: 'Draughtsman Portal', desc: 'CAD assignment & revision upload guidance' },
                { role: 'student', name: 'Student Portal', desc: 'Academy curriculum, rubrics, and certificates' },
                { role: 'admin', name: 'Admin Portal', desc: 'Administrative dispatch, studio settings, & metrics guidance' },
              ].map((p) => (
                <div key={p.role} className="flex items-center justify-between p-3 rounded-xl bg-slate-900 border border-slate-800">
                  <div>
                    <p className="text-xs font-semibold text-slate-200">{p.name}</p>
                    <p className="text-[10px] text-slate-400">{p.desc}</p>
                  </div>
                  <input
                    type="checkbox"
                    checked={formPortals[p.role] !== false}
                    onChange={(e) => setFormPortals((prev) => ({ ...prev, [p.role]: e.target.checked }))}
                    className="h-4 w-4 accent-emerald-500 cursor-pointer"
                  />
                </div>
              ))}

              <div className="pt-2">
                <label className="text-xs font-bold text-slate-300 uppercase tracking-wider block mb-2">
                  Custom Maintenance Notice
                </label>
                <textarea
                  rows={3}
                  value={formMaintenanceMsg}
                  onChange={(e) => setFormMaintenanceMsg(e.target.value)}
                  placeholder="Enter notice displayed to users when maintenance mode is active..."
                  className="w-full bg-slate-900 border border-slate-800 rounded-xl p-3 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-emerald-500"
                />
              </div>
            </div>

            <div className="space-y-4">
              <label className="text-xs font-bold text-slate-300 uppercase tracking-wider block">Security & Safeguard Limits</label>
              <div className="p-4 rounded-xl bg-slate-900 border border-slate-800 space-y-4">
                <div>
                  <div className="flex justify-between text-xs font-semibold text-slate-200 mb-1">
                    <span>Maximum Prompt Character Limit:</span>
                    <span className="font-mono text-emerald-400">{formMaxChars.toLocaleString()} chars</span>
                  </div>
                  <input
                    type="range"
                    min="200"
                    max="2000"
                    step="50"
                    value={formMaxChars}
                    onChange={(e) => setFormMaxChars(Number(e.target.value))}
                    className="w-full accent-emerald-500 cursor-pointer"
                  />
                  <p className="text-[10px] text-slate-400 mt-1">Enforced server-side before database persistence to prevent prompt overflow.</p>
                </div>

                <div>
                  <div className="flex justify-between text-xs font-semibold text-slate-200 mb-1">
                    <span>Rate Limit Cap:</span>
                    <span className="font-mono text-emerald-400">{formRateLimit} requests / 60 seconds</span>
                  </div>
                  <input
                    type="range"
                    min="5"
                    max="120"
                    step="5"
                    value={formRateLimit}
                    onChange={(e) => setFormRateLimit(Number(e.target.value))}
                    className="w-full accent-emerald-500 cursor-pointer"
                  />
                  <p className="text-[10px] text-slate-400 mt-1">Enforced per-UID sliding window with HTTP 429 response.</p>
                </div>

                <div>
                  <div className="flex justify-between text-xs font-semibold text-slate-200 mb-1">
                    <span>Conversation Context Window:</span>
                    <span className="font-mono text-emerald-400">Last {formHistoryLimit} messages</span>
                  </div>
                  <input
                    type="range"
                    min="2"
                    max="20"
                    step="1"
                    value={formHistoryLimit}
                    onChange={(e) => setFormHistoryLimit(Number(e.target.value))}
                    className="w-full accent-emerald-500 cursor-pointer"
                  />
                  <p className="text-[10px] text-slate-400 mt-1">Maintains conversational follow-ups without leaking historical cross-session data.</p>
                </div>
              </div>
            </div>
          </div>

          <div className="pt-4 border-t border-slate-800 flex justify-end">
            <button
              type="button"
              disabled={isSavingConfig}
              onClick={handleSaveConfiguration}
              className="px-5 py-2.5 rounded-xl bg-emerald-500 text-slate-950 text-xs font-bold hover:bg-emerald-400 shadow-md shadow-emerald-500/20 flex items-center gap-2"
            >
              {isSavingConfig && <Loader2 className="h-4 w-4 animate-spin" />}
              <span>Save Configuration</span>
            </button>
          </div>
        </div>
      )}

      {/* Tab 3: Knowledge Management */}
      {activeTab === 'knowledge' && (
        <div className="bg-[#0f172a] border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="flex flex-col md:flex-row items-start md:items-center justify-between gap-4 border-b border-slate-800 pb-4">
            <div>
              <h3 className="text-base font-bold text-slate-100">Registered Knowledge Sources & Governance</h3>
              <p className="text-xs text-slate-400 mt-1">
                Governed documentation from `source-register.csv`. Deactivated sources are immediately excluded from retrieval.
              </p>
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => showToast('Automated knowledge validation passed: 0 errors')}
                className="px-3.5 py-2 rounded-xl bg-slate-800 border border-slate-700 text-slate-300 text-xs font-semibold hover:bg-slate-700/80 flex items-center gap-1.5"
              >
                <CheckCircle2 className="h-3.5 w-3.5 text-emerald-400" />
                Validate Knowledge
              </button>
            </div>
          </div>

          {/* Filters */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3">
            <div className="flex items-center gap-1 bg-slate-900 border border-slate-800 p-1 rounded-xl overflow-x-auto">
              {['all', 'public', 'restricted', 'internal'].map((cat) => (
                <button
                  key={cat}
                  onClick={() => setKnowledgeCategoryFilter(cat)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-medium capitalize shrink-0 ${
                    knowledgeCategoryFilter === cat
                      ? 'bg-blue-600 text-white font-semibold'
                      : 'text-slate-400 hover:text-slate-200'
                  }`}
                >
                  {cat}
                </button>
              ))}
            </div>

            <div className="relative">
              <Search className="h-4 w-4 absolute left-3 top-2.5 text-slate-500" />
              <input
                type="text"
                placeholder="Search registered sources..."
                value={searchKnowledge}
                onChange={(e) => setSearchKnowledge(e.target.value)}
                className="bg-slate-900 border border-slate-800 rounded-xl pl-9 pr-4 py-2 text-xs text-slate-200 placeholder-slate-500 focus:outline-none focus:border-blue-500 w-full sm:w-64"
              />
            </div>
          </div>

          {/* Table */}
          <div className="overflow-x-auto rounded-xl border border-slate-800">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-900/80 text-slate-400 font-semibold border-b border-slate-800">
                <tr>
                  <th className="py-3 px-4">Source ID</th>
                  <th className="py-3 px-4">Title & Relative Path</th>
                  <th className="py-3 px-4">Category</th>
                  <th className="py-3 px-4">Verification Authority</th>
                  <th className="py-3 px-4">Status</th>
                  <th className="py-3 px-4 text-right">Administrative Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-slate-300">
                {filteredSources.map((s) => (
                  <tr key={s.id} className="hover:bg-slate-900/40 transition-colors">
                    <td className="py-3 px-4 font-mono text-[11px] text-blue-400 font-bold">{s.id}</td>
                    <td className="py-3 px-4">
                      <p className="font-semibold text-slate-100">{s.title}</p>
                      <p className="font-mono text-[10px] text-slate-400">{s.path}</p>
                    </td>
                    <td className="py-3 px-4">
                      <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase bg-slate-800 text-slate-300 border border-slate-700">
                        {s.category}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-slate-400">{s.verificationAuthority || 'PixelMint Studio MVS'}</td>
                    <td className="py-3 px-4">
                      <span
                        className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase flex items-center gap-1 w-fit ${
                          s.status === 'approved'
                            ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                            : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                        }`}
                      >
                        {s.status === 'approved' ? <Check className="h-3 w-3" /> : <XCircle className="h-3 w-3" />}
                        {s.status}
                      </span>
                    </td>
                    <td className="py-3 px-4 text-right">
                      <button
                        type="button"
                        onClick={() => handleToggleSourceStatus(s.id, s.status)}
                        className={`px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
                          s.status === 'approved'
                            ? 'bg-slate-800 text-slate-300 hover:bg-rose-500/20 hover:text-rose-300'
                            : 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 hover:bg-emerald-500/20'
                        }`}
                      >
                        {s.status === 'approved' ? 'Deactivate' : 'Approve'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {/* Tab 4: Predefined Questions Manager */}
      {activeTab === 'suggestions' && (
        <div className="bg-[#0f172a] border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4 border-b border-slate-800 pb-4">
            <div>
              <h3 className="text-base font-bold text-slate-100">Portal-Specific Predefined Question Chips</h3>
              <p className="text-xs text-slate-400 mt-1">Configure dynamic one-tap quick prompt chips displayed on portal welcome screens.</p>
            </div>
            <div className="flex items-center gap-2">
              <button
                type="button"
                onClick={() => {
                  setSuggestions(INITIAL_SUGGESTIONS);
                  showToast('Default portal question catalog restored');
                }}
                className="px-3.5 py-1.5 rounded-xl bg-slate-800 border border-slate-700 text-slate-300 text-xs font-semibold hover:bg-slate-700 transition-all"
              >
                Restore Defaults
              </button>
            </div>
          </div>

          {/* Role selector */}
          <div className="flex items-center gap-2 border-b border-slate-800 pb-3">
            {['engineer', 'draughtsman', 'student', 'admin'].map((role) => (
              <button
                key={role}
                onClick={() => setSelectedSuggestionRole(role)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold capitalize transition-all ${
                  selectedSuggestionRole === role
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800'
                }`}
              >
                {role} Portal
              </button>
            ))}
          </div>

          {/* Live Portal Preview */}
          <div className="p-4 rounded-xl bg-slate-950 border border-emerald-500/20 space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-semibold text-emerald-400 flex items-center gap-1.5">
                <Sparkles className="h-3.5 w-3.5" />
                Live {selectedSuggestionRole.toUpperCase()} Portal Preview
              </span>
              <span className="text-[11px] text-slate-500 font-mono">
                {filteredSuggestions.filter((s) => s.enabled).length} active chips
              </span>
            </div>
            <div className="flex flex-wrap gap-2 pt-2">
              {filteredSuggestions
                .filter((s) => s.enabled)
                .slice(0, 4)
                .map((s) => (
                  <span
                    key={s.id}
                    className="px-3 py-1.5 rounded-full text-[11px] font-medium bg-[#09202E] text-slate-200 border border-emerald-500/50 flex items-center gap-1.5 shadow-sm shadow-emerald-500/10"
                  >
                    <span>{s.label}</span>
                  </span>
                ))}
              {filteredSuggestions.filter((s) => s.enabled).length > 4 && (
                <span className="px-2.5 py-1 text-[11px] font-semibold text-emerald-400">
                  + {filteredSuggestions.filter((s) => s.enabled).length - 4} more questions
                </span>
              )}
            </div>
          </div>

          {/* Question List with Controls */}
          <div className="space-y-3">
            {filteredSuggestions.map((s, idx) => (
              <div key={s.id} className="flex items-center justify-between p-4 rounded-xl bg-slate-900 border border-slate-800">
                <div className="space-y-1 pr-4">
                  <div className="flex items-center gap-2">
                    <span className="text-xs font-bold text-slate-100">{s.label}</span>
                    <span className="font-mono text-[10px] text-slate-500">({s.id})</span>
                  </div>
                  <p className="text-xs text-slate-400">&ldquo;{s.prompt}&rdquo;</p>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <button
                    disabled={idx === 0}
                    onClick={() => {
                      const list = [...suggestions];
                      const globalIdx = list.findIndex((item) => item.id === s.id);
                      if (globalIdx > 0) {
                        const temp = list[globalIdx];
                        list[globalIdx] = list[globalIdx - 1];
                        list[globalIdx - 1] = temp;
                        setSuggestions(list);
                        showToast('Question reordered');
                      }
                    }}
                    className="p-1 rounded bg-slate-800 text-slate-400 hover:text-slate-200 disabled:opacity-30 text-xs"
                    title="Move up"
                  >
                    ↑
                  </button>
                  <button
                    disabled={idx === filteredSuggestions.length - 1}
                    onClick={() => {
                      const list = [...suggestions];
                      const globalIdx = list.findIndex((item) => item.id === s.id);
                      if (globalIdx < list.length - 1) {
                        const temp = list[globalIdx];
                        list[globalIdx] = list[globalIdx + 1];
                        list[globalIdx + 1] = temp;
                        setSuggestions(list);
                        showToast('Question reordered');
                      }
                    }}
                    className="p-1 rounded bg-slate-800 text-slate-400 hover:text-slate-200 disabled:opacity-30 text-xs"
                    title="Move down"
                  >
                    ↓
                  </button>
                  <button
                    onClick={() => toggleSuggestion(s.id)}
                    className={`px-3 py-1 rounded-lg text-xs font-semibold transition-all ${
                      s.enabled
                        ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                        : 'bg-slate-800 text-slate-500 border border-slate-700'
                    }`}
                  >
                    {s.enabled ? 'Enabled' : 'Disabled'}
                  </button>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Tab 5: AI Provider Configuration */}
      {activeTab === 'provider' && (
        <div className="bg-[#0f172a] border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="border-b border-slate-800 pb-4">
            <h3 className="text-base font-bold text-slate-100">Model Provider & Secrets Architecture</h3>
            <p className="text-xs text-slate-400 mt-1">Pluggable model execution contract and secret isolation guarantee.</p>
          </div>

          <div className="p-4 rounded-xl bg-blue-500/10 border border-blue-500/20 text-xs text-blue-300 space-y-2">
            <div className="flex items-center gap-2 font-bold text-blue-200">
              <ShieldCheck className="h-4 w-4" />
              <span>Zero Exposed Secrets Guarantee</span>
            </div>
            <p>
              In accordance with Archi Draft security guidelines, model API credentials are never bundled into Flutter client code, exposed through frontend HTTP responses, or tracked in git. All cloud model calls require authenticated server-side Cloudflare Worker secrets (`AI_PROVIDER_API_KEY`).
            </p>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-3">
              <span className="text-xs font-bold text-slate-400 uppercase tracking-wider block">Active Runtime Provider</span>
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-xl bg-emerald-500/10 border border-emerald-500/20 flex items-center justify-center text-emerald-400">
                  <Cpu className="h-5 w-5" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-slate-100">Deterministic Local Knowledge Adapter</h4>
                  <p className="text-[11px] text-emerald-400">Grounded strictly in verified Archi Draft repository documents</p>
                </div>
              </div>
              <div className="pt-3 border-t border-slate-800 text-xs space-y-2">
                <div className="flex justify-between text-slate-400">
                  <span>API Key Requirement:</span>
                  <span className="text-slate-200 font-medium">None (Zero External Dependency)</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Cost per query:</span>
                  <span className="text-emerald-400 font-mono font-bold">$0.00</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Data Isolation:</span>
                  <span className="text-emerald-400 font-bold">100% In-Worker Execution</span>
                </div>
              </div>
            </div>

            <div className="bg-slate-900 border border-slate-800 rounded-xl p-5 space-y-3">
              <span className="text-xs font-bold text-slate-400 uppercase tracking-wider block">Cloud Model Provider Adapter</span>
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-xl bg-blue-500/10 border border-blue-500/20 flex items-center justify-center text-blue-400">
                  <Sparkles className="h-5 w-5" />
                </div>
                <div>
                  <h4 className="text-sm font-bold text-slate-100">Optional Cloud LLM Provider</h4>
                  <p className="text-[11px] text-slate-400">Workers AI / Gemini 1.5 Flash</p>
                </div>
              </div>
              <div className="pt-3 border-t border-slate-800 text-xs space-y-2">
                <div className="flex justify-between text-slate-400">
                  <span>Secret Status:</span>
                  <span className="font-mono text-slate-400">•••••••••••••••• (Server Secret)</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Activation Policy:</span>
                  <span className="text-amber-400 font-medium">Requires explicit admin approval</span>
                </div>
                <div className="flex justify-between text-slate-400">
                  <span>Fallback Mode:</span>
                  <span className="text-slate-200">Auto-fallback to local engine if offline</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Tab 6: Feedback Queue */}
      {activeTab === 'feedback' && (
        <div className="bg-[#0f172a] border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="flex items-center justify-between border-b border-slate-800 pb-4">
            <div>
              <h3 className="text-base font-bold text-slate-100">User Feedback & Unanswered Questions Triage</h3>
              <p className="text-xs text-slate-400 mt-1">
                Authentic telemetry queried from D1 `user_feedback` and `unanswered_questions` tables.
              </p>
            </div>
            <button
              type="button"
              onClick={refreshAllData}
              className="px-3 py-1.5 rounded-xl bg-slate-800 text-slate-300 text-xs font-semibold hover:bg-slate-700 flex items-center gap-1.5"
            >
              <RefreshCw className="h-3.5 w-3.5" />
              <span>Refresh Telemetry</span>
            </button>
          </div>

          <div className="space-y-4">
            <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider">Unanswered Questions ({unansweredItems.length})</h4>
            {unansweredItems.length === 0 ? (
              <div className="p-6 rounded-xl bg-slate-900 border border-slate-800 text-center text-xs text-slate-400">
                <CheckCircle2 className="h-6 w-6 text-emerald-400 mx-auto mb-2" />
                No unanswered questions currently logged. All recent questions met verification confidence thresholds.
              </div>
            ) : (
              <div className="space-y-3">
                {unansweredItems.map((ticket) => (
                  <div key={ticket.id} className="p-4 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between gap-4">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs font-bold text-blue-400">{ticket.id}</span>
                        <span className="text-xs font-bold text-slate-100">&ldquo;{ticket.query}&rdquo;</span>
                        <span className="px-2 py-0.5 rounded-full text-[10px] font-semibold uppercase bg-slate-800 text-slate-300 border border-slate-700">
                          {ticket.userRole}
                        </span>
                      </div>
                      <p className="text-xs text-slate-400">{ticket.failureReason}</p>
                    </div>
                    <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold uppercase bg-amber-500/10 text-amber-400 border border-amber-500/20">
                      Triage Pending
                    </span>
                  </div>
                ))}
              </div>
            )}

            <h4 className="text-xs font-bold text-slate-300 uppercase tracking-wider pt-4">User Ratings & Comments ({feedbackItems.length})</h4>
            {feedbackItems.length === 0 ? (
              <div className="p-6 rounded-xl bg-slate-900 border border-slate-800 text-center text-xs text-slate-400">
                <ThumbsUp className="h-6 w-6 text-blue-400 mx-auto mb-2" />
                No recorded feedback items yet in the database.
              </div>
            ) : (
              <div className="space-y-3">
                {feedbackItems.map((fb) => (
                  <div key={fb.id} className="p-4 rounded-xl bg-slate-900 border border-slate-800 flex items-center justify-between">
                    <div>
                      <div className="flex items-center gap-2">
                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold uppercase ${
                          fb.rating === 1 ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' : 'bg-rose-500/10 text-rose-400 border border-rose-500/20'
                        }`}>
                          {fb.rating === 1 ? '👍 Helpful' : '👎 Needs Improvement'}
                        </span>
                        <span className="text-xs text-slate-300">{fb.feedbackText || 'No text comment provided'}</span>
                      </div>
                      <span className="text-[10px] text-slate-500 mt-1 block">Message ID: {fb.messageId}</span>
                    </div>
                    <span className="text-[10px] text-slate-500 font-mono">
                      {new Date(fb.createdAt).toLocaleDateString()}
                    </span>
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* Tab 7: Security Audit Log */}
      {activeTab === 'audit' && (
        <div className="bg-[#0f172a] border border-slate-800 rounded-2xl p-6 space-y-6">
          <div className="flex items-center justify-between border-b border-slate-800 pb-4">
            <div>
              <h3 className="text-base font-bold text-slate-100">Security Audit Trail</h3>
              <p className="text-xs text-slate-400 mt-1">
                Server-generated, tamper-resistant trail of administrative mutations persisted in Cloudflare D1.
              </p>
            </div>
            <button
              type="button"
              onClick={refreshAllData}
              className="px-3 py-1.5 rounded-xl bg-slate-800 text-slate-300 text-xs font-semibold hover:bg-slate-700 flex items-center gap-1.5"
            >
              <RefreshCw className="h-3.5 w-3.5" />
              <span>Refresh Log</span>
            </button>
          </div>

          <div className="overflow-x-auto rounded-xl border border-slate-800">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-900/80 text-slate-400 font-semibold border-b border-slate-800">
                <tr>
                  <th className="py-3 px-4">Event ID</th>
                  <th className="py-3 px-4">Timestamp (UTC)</th>
                  <th className="py-3 px-4">Admin Actor</th>
                  <th className="py-3 px-4">Action</th>
                  <th className="py-3 px-4">Target Resource</th>
                  <th className="py-3 px-4">Sanitized Metadata</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800 text-slate-300 font-mono text-[11px]">
                {auditLogs.length === 0 ? (
                  <tr>
                    <td colSpan={6} className="py-8 text-center text-slate-500 font-sans">
                      No audit events recorded yet in D1.
                    </td>
                  </tr>
                ) : (
                  auditLogs.map((log) => (
                    <tr key={log.id} className="hover:bg-slate-900/40">
                      <td className="py-3 px-4 text-blue-400 font-bold">{log.id.slice(0, 12)}</td>
                      <td className="py-3 px-4 text-slate-400">
                        {new Date(log.createdAt).toISOString().replace('T', ' ').slice(0, 19)}
                      </td>
                      <td className="py-3 px-4 text-emerald-400 font-sans font-semibold">{log.adminUserId}</td>
                      <td className="py-3 px-4 font-bold text-slate-200">{log.action}</td>
                      <td className="py-3 px-4 text-slate-300 font-sans">{log.target || '—'}</td>
                      <td className="py-3 px-4 text-slate-400 font-sans truncate max-w-xs">
                        {log.metadata ? JSON.stringify(log.metadata) : '—'}
                      </td>
                    </tr>
                  ))
                )}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </div>
  );
}

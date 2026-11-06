'use client';

import React, { useState, useEffect, useMemo, useCallback, useRef } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { EmptyState } from '@/components/ui/EmptyState';
import { Modal } from '@/components/ui/Modal';
import { adminApi, classifyApiError, ClassifiedError } from '@/lib/api';
import { formatRelativeTime, formatTime, formatDate } from '@/lib/dateUtils';
import {
  AdminHealthData,
  AdminAnalyticsData,
  BotConfigData,
  KnowledgeSourceItem,
  RemoteSuggestion,
  AuditLogItem,
  FeedbackItem,
  UnansweredItem,
  ConversationSessionItem,
  ConversationMessageItem,
  UserConversationGroup,
  QuestionAnalyticsData,
  QuestionAnalyticsFilter,
  FrequentlyAskedQuestionItem,
  KnowledgeGapItem,
} from '@/lib/types';
import {
  Bot,
  Activity,
  Settings2,
  BookOpen,
  MessageSquare,
  ThumbsUp,
  ThumbsDown,
  HelpCircle,
  RefreshCw,
  Search,
  Filter,
  ShieldCheck,
  AlertTriangle,
  CheckCircle2,
  X,
  ChevronRight,
  Plus,
  Trash2,
  Edit2,
  Upload,
  Copy,
  Check,
  Lock,
  Eye,
  Sparkles,
  Clock,
  Zap,
  AlertCircle,
  Info,
  FileText,
  Layers,
  ChevronDown,
  ChevronUp,
  Cpu,
  BarChart3,
  Download,
  Users,
  ExternalLink,
  TrendingUp,
} from 'lucide-react';

// ============================================================================
// NAVIGATION ARCHITECTURE (EXACTLY 5 CONSOLIDATED SECTIONS)
// ============================================================================

type TabKey = 'dashboard' | 'settings' | 'knowledge' | 'conversations' | 'insights';

const TAB_CONFIG: Array<{ key: TabKey; label: string; icon: React.ComponentType<{ className?: string }> }> = [
  { key: 'dashboard', label: 'Dashboard', icon: Activity },
  { key: 'settings', label: 'Bot Settings', icon: Settings2 },
  { key: 'knowledge', label: 'Knowledge Base', icon: BookOpen },
  { key: 'conversations', label: 'Conversations', icon: MessageSquare },
  { key: 'insights', label: 'Feedback & Insights', icon: ThumbsUp },
];

// Supported user roles in ARCHI DRAFT (Strict: NO Client, NO Guest)
type SupportedRole = 'engineer' | 'draughtsman' | 'student';
const SUPPORTED_ROLES: Array<{ key: SupportedRole; label: string }> = [
  { key: 'engineer', label: 'Engineer' },
  { key: 'draughtsman', label: 'Draughtsman' },
  { key: 'student', label: 'Student' },
];

export default function PixmintBotAdminPage() {
  const [activeTab, setActiveTab] = useState<TabKey>('dashboard');
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const [errorInfo, setErrorInfo] = useState<ClassifiedError | null>(null);
  const [successBanner, setSuccessBanner] = useState<string | null>(null);

  // ── Tab 1: Dashboard Data ──────────────────────────────────────────────────
  const [health, setHealth] = useState<AdminHealthData | null>(null);
  const [analytics, setAnalytics] = useState<AdminAnalyticsData | null>(null);

  // ── Tab 2: Bot Settings Data ───────────────────────────────────────────────
  const [config, setConfig] = useState<BotConfigData | null>(null);
  const [configForm, setConfigForm] = useState<BotConfigData | null>(null);
  const [isConfigSaving, setIsConfigSaving] = useState(false);

  // Suggested Questions state (managed within Bot Settings)
  const [suggestionRole, setSuggestionRole] = useState<SupportedRole>('engineer');
  const [suggestions, setSuggestions] = useState<RemoteSuggestion[]>([]);
  const [loadingSuggestions, setLoadingSuggestions] = useState(false);
  const [isAddSuggestionOpen, setIsAddSuggestionOpen] = useState(false);
  const [editingSuggestion, setEditingSuggestion] = useState<RemoteSuggestion | null>(null);
  const [suggestionForm, setSuggestionForm] = useState<{ role: SupportedRole; label: string; prompt: string; sortOrder: number }>({
    role: 'engineer',
    label: '',
    prompt: '',
    sortOrder: 0,
  });
  const [isSuggestionSaving, setIsSuggestionSaving] = useState(false);
  const [suggestionToDelete, setSuggestionToDelete] = useState<RemoteSuggestion | null>(null);

  // ── Tab 3: Knowledge Base Data ─────────────────────────────────────────────
  const [sources, setSources] = useState<KnowledgeSourceItem[]>([]);
  const [knowledgeSearch, setKnowledgeSearch] = useState('');
  const [knowledgeCategoryFilter, setKnowledgeCategoryFilter] = useState('ALL');
  const [sourceTogglingId, setSourceTogglingId] = useState<string | null>(null);
  const [isUploadDocOpen, setIsUploadDocOpen] = useState(false);
  const [uploadDocForm, setUploadDocForm] = useState({
    title: '',
    category: 'Architectural Standards',
    content: '',
  });
  const [isDocUploading, setIsDocUploading] = useState(false);
  const [docToDelete, setDocToDelete] = useState<KnowledgeSourceItem | null>(null);

  // ── Tab 4: Conversations Data ──────────────────────────────────────────────
  const [conversations, setConversations] = useState<ConversationSessionItem[]>([]);
  const [conversationSearch, setConversationSearch] = useState('');
  const [conversationRoleFilter, setConversationRoleFilter] = useState<'ALL' | 'engineer' | 'draughtsman' | 'student' | 'admin'>('ALL');
  const [expandedUserIds, setExpandedUserIds] = useState<Record<string, boolean>>({});
  const [selectedSession, setSelectedSession] = useState<ConversationSessionItem | null>(null);
  const [inspectMessages, setInspectMessages] = useState<ConversationMessageItem[]>([]);
  const [loadingMessages, setLoadingMessages] = useState(false);
  const [inspectError, setInspectError] = useState<string | null>(null);
  const [showTechnicalDetails, setShowTechnicalDetails] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // ── Tab 5: Feedback, Audit & Question Analytics ────────────────────────────
  const [feedback, setFeedback] = useState<FeedbackItem[]>([]);
  const [unanswered, setUnanswered] = useState<UnansweredItem[]>([]);
  const [auditLogs, setAuditLogs] = useState<AuditLogItem[]>([]);
  const [auditActionFilter, setAuditActionFilter] = useState<string>('ALL');
  const [copiedQueryId, setCopiedQueryId] = useState<string | null>(null);

  // Question Analytics State
  const [questionAnalytics, setQuestionAnalytics] = useState<QuestionAnalyticsData | null>(null);
  const [loadingAnalytics, setLoadingAnalytics] = useState(false);
  const [analyticsFilter, setAnalyticsFilter] = useState<QuestionAnalyticsFilter>({
    portal: 'all',
    timeRange: '30d',
    search: '',
  });
  const [selectedFaqGroup, setSelectedFaqGroup] = useState<FrequentlyAskedQuestionItem | null>(null);
  const [isExportingCsv, setIsExportingCsv] = useState(false);

  // ────────────────────────────────────────────────────────────────────────────
  // DATA INGESTION
  // ────────────────────────────────────────────────────────────────────────────

  const loadData = useCallback(async () => {
    try {
      setErrorInfo(null);

      const [healthRes, analyticsRes, configRes, sourcesRes, convsRes, feedbackRes, unansweredRes, auditRes] =
        await Promise.allSettled([
          adminApi.getBotHealth(),
          adminApi.getBotAnalytics(),
          adminApi.getBotConfig(),
          adminApi.getBotKnowledgeSources(),
          adminApi.getBotConversations(100),
          adminApi.getBotFeedback(50),
          adminApi.getBotUnanswered(50),
          adminApi.getBotAuditLogs(100),
        ]);

      if (healthRes.status === 'fulfilled') setHealth(healthRes.value);
      if (analyticsRes.status === 'fulfilled') setAnalytics(analyticsRes.value);
      if (configRes.status === 'fulfilled') {
        setConfig(configRes.value.config);
        setConfigForm(configRes.value.config);
      }
      if (sourcesRes.status === 'fulfilled') setSources(sourcesRes.value.sources);
      if (convsRes.status === 'fulfilled') setConversations(convsRes.value.conversations);
      if (feedbackRes.status === 'fulfilled') setFeedback(feedbackRes.value.feedback);
      if (unansweredRes.status === 'fulfilled') setUnanswered(unansweredRes.value.questions);
      if (auditRes.status === 'fulfilled') setAuditLogs(auditRes.value.logs);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  }, []);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleRefresh = async () => {
    setRefreshing(true);
    await loadData();
    if (activeTab === 'settings') {
      fetchRoleSuggestions(suggestionRole);
    }
    if (activeTab === 'insights') {
      fetchQuestionAnalytics(analyticsFilter);
    }
  };

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 2: SUGGESTIONS MANAGEMENT
  // ────────────────────────────────────────────────────────────────────────────

  const fetchRoleSuggestions = useCallback(async (role: SupportedRole) => {
    setLoadingSuggestions(true);
    try {
      const res = await adminApi.getBotSuggestions(role);
      const list = Array.isArray(res) ? res : res.suggestions || [];
      setSuggestions(list);
    } catch (err: any) {
      console.error('Failed to load suggestions for role:', role, err);
      setSuggestions([]);
    } finally {
      setLoadingSuggestions(false);
    }
  }, []);

  useEffect(() => {
    if (activeTab === 'settings') {
      fetchRoleSuggestions(suggestionRole);
    }
  }, [activeTab, suggestionRole, fetchRoleSuggestions]);

  const handleSaveConfig = async () => {
    if (!configForm) return;
    setIsConfigSaving(true);
    setErrorInfo(null);
    try {
      await adminApi.updateBotConfig(configForm);
      setConfig(configForm);
      setSuccessBanner('Bot configuration saved and synchronized to Cloudflare D1.');
      setTimeout(() => setSuccessBanner(null), 4000);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    } finally {
      setIsConfigSaving(false);
    }
  };

  const handleQuickToggleBotStatus = async () => {
    if (!config) return;
    const updated = { ...config, botEnabled: !config.botEnabled };
    try {
      await adminApi.updateBotConfig(updated);
      setConfig(updated);
      setConfigForm(updated);
      setHealth((prev) => (prev ? { ...prev, botEnabled: updated.botEnabled } : null));
      setSuccessBanner(`PIXMINT BOT is now ${updated.botEnabled ? 'ACTIVE' : 'DISABLED'}.`);
      setTimeout(() => setSuccessBanner(null), 3000);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    }
  };

  const handleToggleSuggestionActive = async (sug: RemoteSuggestion) => {
    try {
      await adminApi.updateBotSuggestion(sug.id, { isActive: !sug.isActive });
      setSuggestions((prev) =>
        prev.map((item) => (item.id === sug.id ? { ...item, isActive: !item.isActive } : item))
      );
      setSuccessBanner(`Suggestion status updated to ${!sug.isActive ? 'ACTIVE' : 'DISABLED'}.`);
      setTimeout(() => setSuccessBanner(null), 2500);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    }
  };

  const handleSaveSuggestion = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSuggestionSaving(true);
    setErrorInfo(null);
    try {
      if (editingSuggestion) {
        await adminApi.updateBotSuggestion(editingSuggestion.id, suggestionForm);
        setSuccessBanner('Suggested question updated successfully.');
      } else {
        await adminApi.createBotSuggestion(suggestionForm);
        setSuccessBanner('Suggested question added successfully.');
      }
      setIsAddSuggestionOpen(false);
      setEditingSuggestion(null);
      fetchRoleSuggestions(suggestionRole);
      setTimeout(() => setSuccessBanner(null), 3000);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    } finally {
      setIsSuggestionSaving(false);
    }
  };

  const handleDeleteSuggestion = async () => {
    if (!suggestionToDelete) return;
    try {
      await adminApi.deleteBotSuggestion(suggestionToDelete.id);
      setSuggestions((prev) => prev.filter((item) => item.id !== suggestionToDelete.id));
      setSuggestionToDelete(null);
      setSuccessBanner('Suggested question deleted.');
      setTimeout(() => setSuccessBanner(null), 3000);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    }
  };

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 3: KNOWLEDGE BASE ACTIONS
  // ────────────────────────────────────────────────────────────────────────────

  const handleToggleSourceStatus = async (source: KnowledgeSourceItem) => {
    setSourceTogglingId(source.id);
    const nextStatus = source.status === 'approved' ? 'deactivated' : 'approved';
    try {
      await adminApi.updateBotKnowledgeSourceStatus(source.id, nextStatus);
      setSources((prev) =>
        prev.map((s) => (s.id === source.id ? { ...s, status: nextStatus } : s))
      );
      setSuccessBanner(`Knowledge source "${source.title}" is now ${nextStatus.toUpperCase()}.`);
      setTimeout(() => setSuccessBanner(null), 3000);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    } finally {
      setSourceTogglingId(null);
    }
  };

  const handleUploadDocument = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsDocUploading(true);
    setErrorInfo(null);
    try {
      const res = await adminApi.uploadBotKnowledgeDocument(uploadDocForm);
      if (res.document) {
        setSources((prev) => [res.document, ...prev]);
      }
      setIsUploadDocOpen(false);
      setUploadDocForm({ title: '', category: 'Architectural Standards', content: '' });
      setSuccessBanner('Knowledge document uploaded, chunked, and indexed into D1.');
      setTimeout(() => setSuccessBanner(null), 4000);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    } finally {
      setIsDocUploading(false);
    }
  };

  const handleDeleteDocument = async () => {
    if (!docToDelete) return;
    try {
      await adminApi.deleteBotKnowledgeDocument(docToDelete.id);
      setSources((prev) => prev.filter((d) => d.id !== docToDelete.id));
      setDocToDelete(null);
      setSuccessBanner('Knowledge document removed.');
      setTimeout(() => setSuccessBanner(null), 3000);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    }
  };

  const uniqueCategories = useMemo(() => {
    const cats = new Set(sources.map((s) => s.category).filter(Boolean));
    return Array.from(cats);
  }, [sources]);

  const filteredSources = useMemo(() => {
    return sources.filter((s) => {
      const matchSearch =
        !knowledgeSearch ||
        s.title.toLowerCase().includes(knowledgeSearch.toLowerCase()) ||
        s.path.toLowerCase().includes(knowledgeSearch.toLowerCase()) ||
        s.category.toLowerCase().includes(knowledgeSearch.toLowerCase());
      const matchCat = knowledgeCategoryFilter === 'ALL' || s.category === knowledgeCategoryFilter;
      return matchSearch && matchCat;
    });
  }, [sources, knowledgeSearch, knowledgeCategoryFilter]);

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 4: CONVERSATION INSPECTION
  // ────────────────────────────────────────────────────────────────────────────

  const filteredConversations = useMemo(() => {
    return conversations.filter((c) => {
      const matchSearch =
        !conversationSearch ||
        c.userEmail?.toLowerCase().includes(conversationSearch.toLowerCase()) ||
        c.title?.toLowerCase().includes(conversationSearch.toLowerCase()) ||
        c.userId?.toLowerCase().includes(conversationSearch.toLowerCase());
      const matchRole =
        conversationRoleFilter === 'ALL' || c.userRole?.toLowerCase() === conversationRoleFilter.toLowerCase();
      return matchSearch && matchRole;
    });
  }, [conversations, conversationSearch, conversationRoleFilter]);

  const userConversationGroups = useMemo<UserConversationGroup[]>(() => {
    const groupsMap = new Map<string, UserConversationGroup>();

    for (const conv of filteredConversations) {
      const key = conv.userId || conv.userEmail || 'unknown';
      let group = groupsMap.get(key);
      const convTime = typeof conv.updatedAt === 'number' 
        ? conv.updatedAt 
        : new Date(conv.updatedAt || conv.createdAt || Date.now()).getTime();

      if (!group) {
        group = {
          userId: conv.userId,
          userEmail: conv.userEmail || conv.userId,
          userRole: conv.userRole,
          totalSessions: 0,
          totalMessages: 0,
          lastActive: convTime,
          sessions: [],
        };
        groupsMap.set(key, group);
      }

      group.totalSessions += 1;
      group.totalMessages += conv.messageCount || 0;
      group.sessions.push(conv);

      if (convTime > group.lastActive) {
        group.lastActive = convTime;
      }
    }

    const sortedGroups = Array.from(groupsMap.values()).map((group) => {
      group.sessions.sort((a, b) => {
        const timeA = new Date(a.updatedAt || a.createdAt).getTime();
        const timeB = new Date(b.updatedAt || b.createdAt).getTime();
        return timeB - timeA;
      });
      return group;
    });

    sortedGroups.sort((a, b) => {
      return b.lastActive - a.lastActive;
    });

    return sortedGroups;
  }, [filteredConversations]);

  const toggleUserExpanded = (userId: string) => {
    setExpandedUserIds((prev) => ({
      ...prev,
      [userId]: !prev[userId],
    }));
  };

  const handleInspectSession = async (session: ConversationSessionItem) => {
    setSelectedSession(session);
    setLoadingMessages(true);
    setInspectMessages([]);
    setInspectError(null);
    setShowTechnicalDetails(false);
    try {
      const res = await adminApi.getBotConversationMessages(session.id);
      setInspectMessages(res.messages || []);
    } catch (err: any) {
      setInspectError(err?.message || 'Failed to load conversation history.');
      setErrorInfo(classifyApiError(err));
    } finally {
      setLoadingMessages(false);
    }
  };

  useEffect(() => {
    if (selectedSession && inspectMessages.length > 0) {
      const timer = setTimeout(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
      }, 100);
      return () => clearTimeout(timer);
    }
  }, [selectedSession, inspectMessages]);

  const getMessageDateGroup = (timestamp: number): string => {
    const d = new Date(timestamp);
    if (isNaN(d.getTime())) return 'Conversation History';
    const now = new Date();
    const isToday =
      d.getDate() === now.getDate() &&
      d.getMonth() === now.getMonth() &&
      d.getFullYear() === now.getFullYear();
    if (isToday) return 'Today';

    const yesterday = new Date(now);
    yesterday.setDate(yesterday.getDate() - 1);
    const isYesterday =
      d.getDate() === yesterday.getDate() &&
      d.getMonth() === yesterday.getMonth() &&
      d.getFullYear() === yesterday.getFullYear();
    if (isYesterday) return 'Yesterday';

    return d.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
  };

  // ────────────────────────────────────────────────────────────────────────────
  // TAB 5: QUESTION ANALYTICS & KNOWLEDGE GAP AUDIT
  // ────────────────────────────────────────────────────────────────────────────

  const fetchQuestionAnalytics = useCallback(async (filter: QuestionAnalyticsFilter) => {
    setLoadingAnalytics(true);
    try {
      const data = await adminApi.getBotQuestionAnalytics(filter);
      setQuestionAnalytics(data);
    } catch (err: any) {
      console.error('Failed to load question analytics:', err);
      // Fallback empty structure
      setQuestionAnalytics({
        summary: {
          totalQuestionsAnalyzed: 0,
          uniqueQuestionGroups: 0,
          mostRepeatedTopic: 'None',
          unansweredQuestionCount: 0,
          negativeFeedbackCount: 0,
          topicsNeedingAttention: 0,
          groupingMethod: 'Normalized Architectural Intent & Token Clustering',
          auditPeriod: { timeRange: filter.timeRange, startDate: 0, endDate: Date.now() },
        },
        frequentlyAskedQuestions: [],
        knowledgeGaps: [],
      });
    } finally {
      setLoadingAnalytics(false);
    }
  }, []);

  useEffect(() => {
    if (activeTab === 'insights') {
      fetchQuestionAnalytics(analyticsFilter);
    }
  }, [activeTab, analyticsFilter, fetchQuestionAnalytics]);

  const handleCopyText = (id: string, text: string) => {
    navigator.clipboard.writeText(text);
    setCopiedQueryId(id);
    setTimeout(() => setCopiedQueryId(null), 2000);
  };

  const handleExportCsvReport = () => {
    if (!questionAnalytics) return;
    setIsExportingCsv(true);

    try {
      const summary = questionAnalytics.summary;
      const faqs = questionAnalytics.frequentlyAskedQuestions;
      const gaps = questionAnalytics.knowledgeGaps;

      const dateStr = new Date().toISOString().split('T')[0];
      const rows: string[] = [];

      // Section A: Header & Summary
      rows.push('PIXMINT BOT 2.0 — QUESTION ANALYTICS & KNOWLEDGE GAP AUDIT REPORT');
      rows.push(`Generated At,${new Date().toISOString()}`);
      rows.push(`Audit Period,${summary.auditPeriod.timeRange.toUpperCase()}`);
      rows.push(`Grouping Engine,"${summary.groupingMethod}"`);
      rows.push(`Portal Filter,${analyticsFilter.portal.toUpperCase()}`);
      rows.push(`Total Questions Analyzed,${summary.totalQuestionsAnalyzed}`);
      rows.push(`Unique Question Groups,${summary.uniqueQuestionGroups}`);
      rows.push(`Most Repeated Topic,"${summary.mostRepeatedTopic}"`);
      rows.push(`Unanswered Inquiries,${summary.unansweredQuestionCount}`);
      rows.push(`Negative Feedback Ratings,${summary.negativeFeedbackCount}`);
      rows.push(`Flagged Knowledge Gaps,${summary.topicsNeedingAttention}`);
      rows.push('');

      // Section B: Ranked Questions
      rows.push('--- MOST FREQUENTLY ASKED QUESTIONS ---');
      rows.push('Rank,Topic,Category,Times Asked,Engineer Count,Draughtsman Count,Student Count,Unique Users,First Asked,Last Asked,Flagged Gap');
      for (const faq of faqs) {
        rows.push(
          `${faq.rank},"${faq.topic.replace(/"/g, '""')}","${faq.category}",${faq.timesAsked},${faq.portals.engineer},${faq.portals.draughtsman},${faq.portals.student},${faq.uniqueUsersCount},"${new Date(faq.firstAsked).toISOString()}","${new Date(faq.lastAsked).toISOString()}",${faq.isFlaggedGap ? 'YES' : 'NO'}`
        );
      }
      rows.push('');

      // Section C: Original Question Variations
      rows.push('--- ORIGINAL QUESTION PHRASING VARIATIONS ---');
      rows.push('Topic,Original User Phrasing,Times Asked');
      for (const faq of faqs) {
        for (const v of faq.originalVariations) {
          rows.push(`"${faq.topic.replace(/"/g, '""')}","${v.text.replace(/"/g, '""')}",${v.count}`);
        }
      }
      rows.push('');

      // Section D: Knowledge Gaps
      rows.push('--- KNOWLEDGE GAPS & DOCUMENTATION ACTION ITEMS ---');
      rows.push('Topic,Category,Affected Questions,Unanswered Count,Negative Feedback Count,Reason Flagged,Recommended Action');
      for (const gap of gaps) {
        rows.push(
          `"${gap.topic.replace(/"/g, '""')}","${gap.category}",${gap.affectedQuestionsCount},${gap.unansweredCount},${gap.negativeFeedbackCount},"${gap.flagReason.replace(/"/g, '""')}","${gap.recommendedAction.replace(/"/g, '""')}"`
        );
      }

      const csvContent = 'data:text/csv;charset=utf-8,' + encodeURIComponent(rows.join('\n'));
      const link = document.createElement('a');
      link.setAttribute('href', csvContent);
      link.setAttribute('download', `pixmint_bot_question_audit_${dateStr}.csv`);
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);

      setSuccessBanner('Question Audit CSV Report generated and downloaded.');
      setTimeout(() => setSuccessBanner(null), 3500);
    } catch (err: any) {
      setErrorInfo(classifyApiError(err));
    } finally {
      setIsExportingCsv(false);
    }
  };

  const filteredAuditLogs = useMemo(() => {
    if (auditActionFilter === 'ALL') return auditLogs;
    return auditLogs.filter((l) => l.action === auditActionFilter);
  }, [auditLogs, auditActionFilter]);

  // ────────────────────────────────────────────────────────────────────────────
  // RENDER
  // ────────────────────────────────────────────────────────────────────────────

  return (
    <AdminShell
      title="PIXMINT BOT 2.0"
      subtitle="Centralized AI assistant controls, knowledge base, prompt curation, and user insights"
      onRefresh={handleRefresh}
      isRefreshing={refreshing}
    >
      <div className="space-y-6 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
        {/* ==================================================================== */}
        {/* COMPACT CLEAN HEADER */}
        {/* ==================================================================== */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200">
          <div>
            <div className="flex items-center gap-2.5">
              <div className="h-9 w-9 rounded-xl bg-blue-50 border border-blue-200 flex items-center justify-center text-[#0453cd]">
                <Bot className="h-5 w-5" />
              </div>
              <h1 className="text-xl font-bold tracking-tight text-slate-900">
                PIXMINT BOT 2.0 Management
              </h1>
              <span className="px-2 py-0.5 text-[11px] font-mono font-bold rounded-full bg-blue-50 text-blue-700 border border-blue-200">
                v2.0.0
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-1">
              Centralized AI assistant controls, knowledge base, prompt curation, and user insights.
            </p>
          </div>

          <div className="flex items-center gap-2.5 shrink-0">
            <Button
              variant="outline"
              size="sm"
              onClick={handleRefresh}
              loading={refreshing}
              className="text-xs border-slate-200"
            >
              <RefreshCw className="h-3.5 w-3.5 mr-1.5" />
              <span>Refresh</span>
            </Button>
          </div>
        </div>

        {/* ==================================================================== */}
        {/* FEEDBACK BANNERS */}
        {/* ==================================================================== */}
        {successBanner && (
          <div className="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-medium flex items-center justify-between">
            <div className="flex items-center gap-2">
              <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
              <span>{successBanner}</span>
            </div>
            <button onClick={() => setSuccessBanner(null)} className="text-emerald-600 hover:text-emerald-800">
              <X className="h-4 w-4" />
            </button>
          </div>
        )}

        {errorInfo && (
          <div className="p-3.5 rounded-xl bg-amber-50 border border-amber-200 text-amber-800 text-xs font-medium flex items-center justify-between">
            <div className="flex items-center gap-2">
              <AlertTriangle className="h-4 w-4 text-amber-600 shrink-0" />
              <span>{errorInfo.message}</span>
            </div>
            <Button size="sm" variant="secondary" onClick={handleRefresh}>
              Retry
            </Button>
          </div>
        )}

        {/* ==================================================================== */}
        {/* 5-TAB NAVIGATION BAR */}
        {/* ==================================================================== */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 border-b border-slate-200">
          {TAB_CONFIG.map((t) => {
            const Icon = t.icon;
            const isActive = activeTab === t.key;
            return (
              <button
                key={t.key}
                onClick={() => setActiveTab(t.key)}
                className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs sm:text-sm font-medium transition-all whitespace-nowrap cursor-pointer ${
                  isActive
                    ? 'bg-[#0453cd] text-white shadow-sm font-semibold'
                    : 'text-slate-600 hover:bg-slate-100 hover:text-slate-900'
                }`}
              >
                <Icon className={`h-4 w-4 ${isActive ? 'text-white' : 'text-slate-400'}`} />
                <span>{t.label}</span>
              </button>
            );
          })}
        </div>

        {/* Loading Spinner */}
        {loading ? (
          <div className="py-20 text-center space-y-3">
            <RefreshCw className="h-8 w-8 animate-spin mx-auto text-[#0453cd]" />
            <p className="text-xs text-slate-500 font-mono">Loading PIXMINT BOT management center...</p>
          </div>
        ) : (
          <div>
            {/* ==================================================================== */}
            {/* TAB 1: DASHBOARD */}
            {/* ==================================================================== */}
            {activeTab === 'dashboard' && (
              <div className="space-y-6">
                {/* 4 Primary KPI Metric Cards */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
                  <div className="bg-white border border-slate-200 rounded-2xl p-5 border-t-4 border-t-blue-600 soft-elevation">
                    <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-wider">
                      Conversations Today
                    </span>
                    <div className="mt-3 flex items-baseline justify-between">
                      <span className="text-3xl font-extrabold font-mono text-slate-900">
                        {analytics?.metrics.totalSessionsToday ?? 0}
                      </span>
                      <span className="text-xs text-blue-600 font-medium flex items-center gap-1">
                        <MessageSquare className="h-3.5 w-3.5" /> Active
                      </span>
                    </div>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-2xl p-5 border-t-4 border-t-indigo-600 soft-elevation">
                    <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-wider">
                      Messages Today
                    </span>
                    <div className="mt-3 flex items-baseline justify-between">
                      <span className="text-3xl font-extrabold font-mono text-slate-900">
                        {analytics?.metrics.totalMessagesToday ?? 0}
                      </span>
                      <span className="text-xs text-indigo-600 font-medium flex items-center gap-1">
                        <Zap className="h-3.5 w-3.5" /> Queries
                      </span>
                    </div>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-2xl p-5 border-t-4 border-t-emerald-600 soft-elevation">
                    <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-wider">
                      Avg Response Time
                    </span>
                    <div className="mt-3 flex items-baseline justify-between">
                      <span className="text-3xl font-extrabold font-mono text-slate-900">
                        {analytics?.metrics.avgLatencyMs ?? 0}
                        <span className="text-sm font-normal text-slate-500 ml-1">ms</span>
                      </span>
                      <span className="text-xs text-emerald-600 font-medium flex items-center gap-1">
                        <Clock className="h-3.5 w-3.5" /> Synthesized
                      </span>
                    </div>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-2xl p-5 border-t-4 border-t-amber-600 soft-elevation">
                    <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-wider">
                      User Satisfaction
                    </span>
                    <div className="mt-3 flex items-baseline justify-between">
                      <span className="text-3xl font-extrabold font-mono text-slate-900">
                        {analytics?.metrics.resolutionRatePercent ?? 100}
                        <span className="text-sm font-normal text-slate-500 ml-0.5">%</span>
                      </span>
                      <span className="text-xs text-amber-600 font-medium flex items-center gap-1">
                        <ThumbsUp className="h-3.5 w-3.5" /> Positive
                      </span>
                    </div>
                  </div>
                </div>

                {/* Compact Bot Status & Quick Actions Banner */}
                <div className="p-5 rounded-2xl bg-white border border-slate-200 soft-elevation flex flex-col md:flex-row md:items-center justify-between gap-4">
                  <div className="flex flex-wrap items-center gap-3">
                    <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-100 text-xs font-medium text-slate-800">
                      <span className={`h-2.5 w-2.5 rounded-full ${health?.botEnabled ? 'bg-emerald-500 animate-pulse' : 'bg-red-500'}`} />
                      <span>Bot Status: <strong>{health?.botEnabled ? 'ACTIVE' : 'DISABLED'}</strong></span>
                    </div>

                    <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-100 text-xs font-medium text-slate-800">
                      <span className={`h-2.5 w-2.5 rounded-full ${health?.maintenanceMode ? 'bg-amber-500' : 'bg-slate-400'}`} />
                      <span>Maintenance: <strong>{health?.maintenanceMode ? 'ON' : 'OFF'}</strong></span>
                    </div>

                    <div className="flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-100 text-xs font-medium text-slate-800">
                      <span className="h-2.5 w-2.5 rounded-full bg-blue-500" />
                      <span>Engine: <strong>{health?.activeProvider || 'Local Grounded Synthesizer'}</strong></span>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center gap-2 shrink-0">
                    <Button
                      variant={health?.botEnabled ? 'outline' : 'primary'}
                      size="sm"
                      onClick={handleQuickToggleBotStatus}
                      className="text-xs"
                    >
                      {health?.botEnabled ? 'Disable Bot' : 'Enable Bot'}
                    </Button>
                    <Button
                      variant="secondary"
                      size="sm"
                      onClick={() => setActiveTab('settings')}
                      className="text-xs"
                    >
                      <Settings2 className="h-3.5 w-3.5 mr-1" />
                      Manage Settings
                    </Button>
                    <Button
                      variant="secondary"
                      size="sm"
                      onClick={() => setActiveTab('knowledge')}
                      className="text-xs"
                    >
                      <BookOpen className="h-3.5 w-3.5 mr-1" />
                      Knowledge Base
                    </Button>
                    <Button
                      variant="secondary"
                      size="sm"
                      onClick={() => setActiveTab('conversations')}
                      className="text-xs"
                    >
                      <MessageSquare className="h-3.5 w-3.5 mr-1" />
                      View Chats
                    </Button>
                  </div>
                </div>

                {/* Compact Recent Activity Section */}
                <Card>
                  <CardHeader
                    title="Recent Administrative Activity"
                    subtitle="Latest governance events, document updates, and configuration actions"
                  />
                  <div className="p-6">
                    {analytics?.recentAuditLogs && analytics.recentAuditLogs.length > 0 ? (
                      <div className="divide-y divide-slate-100">
                        {analytics.recentAuditLogs.slice(0, 5).map((log) => (
                          <div key={log.id} className="py-3 first:pt-0 last:pb-0 flex items-start justify-between gap-3 text-xs">
                            <div className="space-y-1">
                              <div className="flex items-center gap-2">
                                <span className="font-mono font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-800 border border-slate-200 text-[10px]">
                                  {log.action}
                                </span>
                                {log.target && (
                                  <span className="text-slate-600 font-mono truncate max-w-xs">{log.target}</span>
                                )}
                              </div>
                              <p className="text-slate-400 font-mono text-[11px]">
                                By: {log.adminUserId ? `${log.adminUserId.slice(0, 14)}...` : 'Administrator'}
                              </p>
                            </div>
                            <span className="text-slate-400 shrink-0 font-mono text-[11px]">
                              {formatRelativeTime(new Date(log.timestamp))}
                            </span>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <EmptyState
                        title="No Recent Activity"
                        description="Administrative changes on bot settings and knowledge will appear here."
                        compact
                      />
                    )}
                  </div>
                </Card>
              </div>
            )}

            {/* ==================================================================== */}
            {/* TAB 2: BOT SETTINGS */}
            {/* ==================================================================== */}
            {activeTab === 'settings' && configForm && (
              <div className="space-y-6">
                {/* Section A: General Settings */}
                <Card>
                  <CardHeader
                    title="A. General Settings"
                    subtitle="Master service switch and scheduled maintenance mode"
                  />
                  <div className="p-6 space-y-5">
                    {/* Master Switch */}
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 rounded-xl border border-slate-200 bg-slate-50 gap-4">
                      <div>
                        <h4 className="font-bold text-sm text-slate-900">Master Bot Service</h4>
                        <p className="text-xs text-slate-500 mt-0.5">
                          When disabled, PIXMINT BOT is hidden across all client portals and will reject inquiries with a polite notice.
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={() =>
                          setConfigForm((prev) => (prev ? { ...prev, botEnabled: !prev.botEnabled } : null))
                        }
                        className="cursor-pointer shrink-0"
                      >
                        {configForm.botEnabled ? (
                          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-emerald-600 text-white font-medium text-xs shadow-sm">
                            <Check className="h-4 w-4" /> ACTIVE
                          </div>
                        ) : (
                          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-200 text-slate-700 font-medium text-xs">
                            <X className="h-4 w-4" /> DISABLED
                          </div>
                        )}
                      </button>
                    </div>

                    {/* Maintenance Mode */}
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between p-4 rounded-xl border border-amber-200 bg-amber-50/50 gap-4">
                      <div>
                        <h4 className="font-bold text-sm text-slate-900">Maintenance Mode</h4>
                        <p className="text-xs text-slate-600 mt-0.5">
                          When active, users receive the scheduled maintenance notice below.
                        </p>
                      </div>
                      <button
                        type="button"
                        onClick={() =>
                          setConfigForm((prev) => (prev ? { ...prev, maintenanceMode: !prev.maintenanceMode } : null))
                        }
                        className="cursor-pointer shrink-0"
                      >
                        {configForm.maintenanceMode ? (
                          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-amber-600 text-white font-medium text-xs shadow-sm">
                            <AlertTriangle className="h-4 w-4" /> ON
                          </div>
                        ) : (
                          <div className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-slate-200 text-slate-700 font-medium text-xs">
                            OFF
                          </div>
                        )}
                      </button>
                    </div>

                    {/* Maintenance Message */}
                    <div>
                      <label className="block text-xs font-mono font-bold text-slate-700 uppercase tracking-wider mb-2">
                        Maintenance Notice Message
                      </label>
                      <input
                        type="text"
                        value={configForm.maintenanceMessage || ''}
                        onChange={(e) =>
                          setConfigForm((prev) => (prev ? { ...prev, maintenanceMessage: e.target.value } : null))
                        }
                        className="w-full px-3.5 py-2.5 rounded-lg border border-slate-200 text-sm focus:outline-none focus:ring-2 focus:ring-[#0453cd]"
                        placeholder="PIXMINT Bot is undergoing scheduled calibration. Please try again shortly."
                      />
                    </div>
                  </div>
                </Card>

                {/* Section B: Portal Access (Strict: Engineer, Draughtsman, Student ONLY) */}
                <Card>
                  <CardHeader
                    title="B. Portal Access"
                    subtitle="Control chatbot availability across the 3 supported user portals (Engineer, Draughtsman, Student)"
                  />
                  <div className="p-6">
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
                      {SUPPORTED_ROLES.map((r) => {
                        const isPermitted = Boolean(configForm.enabledPortals?.[r.key] ?? true);
                        return (
                          <div
                            key={r.key}
                            className="p-4 rounded-xl border border-slate-200 bg-white flex items-center justify-between"
                          >
                            <div>
                              <span className="font-bold text-sm text-slate-900">{r.label} Portal</span>
                              <p className="text-[11px] text-slate-400 mt-0.5">
                                {isPermitted ? 'Bot launcher displayed' : 'Bot launcher hidden'}
                              </p>
                            </div>

                            <button
                              type="button"
                              onClick={() => {
                                setConfigForm((prev) => {
                                  if (!prev) return null;
                                  return {
                                    ...prev,
                                    enabledPortals: {
                                      ...prev.enabledPortals,
                                      [r.key]: !isPermitted,
                                    },
                                  };
                                });
                              }}
                              className={`px-3 py-1 rounded-lg text-xs font-mono font-bold cursor-pointer transition-colors ${
                                isPermitted
                                  ? 'bg-emerald-100 text-emerald-800 border border-emerald-300'
                                  : 'bg-slate-100 text-slate-500 border border-slate-200'
                              }`}
                            >
                              {isPermitted ? 'PERMITTED' : 'BLOCKED'}
                            </button>
                          </div>
                        );
                      })}
                    </div>
                  </div>
                </Card>

                {/* Section C: AI Configuration */}
                <Card>
                  <CardHeader
                    title="C. AI Configuration"
                    subtitle="Active inference engine and grounding fallback status"
                  />
                  <div className="p-6 space-y-4">
                    <div className="p-4 rounded-xl border border-slate-200 bg-slate-50 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                      <div>
                        <span className="text-xs font-mono font-bold text-slate-500 uppercase tracking-wider">
                          Active Grounded Provider
                        </span>
                        <div className="text-base font-bold text-slate-900 mt-1 flex items-center gap-2">
                          <Cpu className="h-5 w-5 text-blue-600" />
                          <span>{health?.activeProvider === 'local_grounded' ? 'Local Grounded Synthesizer v3' : health?.activeProvider || 'Local Grounded Synthesizer'}</span>
                        </div>
                        <p className="text-xs text-slate-500 mt-1">
                          Verifies drawing queries against approved architectural knowledge chunks before dispatch.
                        </p>
                      </div>
                      <span className="px-3 py-1 rounded-full text-xs font-bold font-mono bg-emerald-100 text-emerald-800 border border-emerald-300 shrink-0">
                        OPERATIONAL
                      </span>
                    </div>

                    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                      <div className="p-4 rounded-xl border border-slate-200 bg-white">
                        <span className="text-xs font-bold text-slate-900">Cloudflare Workers AI Fallback</span>
                        <p className="text-xs text-slate-500 mt-1">
                          Available when `@cloudflare/ai` binding is provisioned in the Worker environment.
                        </p>
                        <span className="mt-2 inline-block text-[11px] font-mono px-2 py-0.5 rounded bg-slate-100 text-slate-600">
                          Status: {health?.workersAiAvailable ? 'Available' : 'Standby / Local Primary'}
                        </span>
                      </div>

                      <div className="p-4 rounded-xl border border-slate-200 bg-white">
                        <span className="text-xs font-bold text-slate-900">Safety & Injection Defense</span>
                        <p className="text-xs text-slate-500 mt-1">
                          Deterministic prompt-injection, privilege-escalation, and system-prompt extraction shields active.
                        </p>
                        <span className="mt-2 inline-block text-[11px] font-mono px-2 py-0.5 rounded bg-emerald-50 text-emerald-700">
                          Shields: Enforced
                        </span>
                      </div>
                    </div>

                    <div className="pt-2 flex justify-end">
                      <Button
                        variant="primary"
                        onClick={handleSaveConfig}
                        loading={isConfigSaving}
                        className="bg-[#0453cd]"
                      >
                        Save Settings Changes
                      </Button>
                    </div>
                  </div>
                </Card>

                {/* Section D: Suggested Questions (Consolidated from old Tab 4) */}
                <Card>
                  <CardHeader
                    title="D. Suggested Questions"
                    subtitle="Manage 1-tap quick action prompts for each supported portal"
                  />
                  <div className="p-6 space-y-4">
                    {/* Role Selector & Add Button */}
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 border-b border-slate-100 pb-4">
                      <div className="flex items-center gap-2">
                        {SUPPORTED_ROLES.map((r) => (
                          <button
                            key={r.key}
                            onClick={() => setSuggestionRole(r.key)}
                            className={`px-3 py-1.5 rounded-lg text-xs font-medium cursor-pointer transition-all ${
                              suggestionRole === r.key
                                ? 'bg-[#0453cd] text-white shadow-sm font-semibold'
                                : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                            }`}
                          >
                            {r.label}
                          </button>
                        ))}
                      </div>

                      <Button
                        variant="primary"
                        size="sm"
                        onClick={() => {
                          setEditingSuggestion(null);
                          setSuggestionForm({
                            role: suggestionRole,
                            label: '',
                            prompt: '',
                            sortOrder: suggestions.length,
                          });
                          setIsAddSuggestionOpen(true);
                        }}
                        className="bg-[#0453cd] text-xs"
                      >
                        <Plus className="h-3.5 w-3.5 mr-1" />
                        Add Question
                      </Button>
                    </div>

                    {/* Suggestions Table */}
                    {loadingSuggestions ? (
                      <div className="py-12 text-center text-slate-400">
                        <RefreshCw className="h-5 w-5 animate-spin mx-auto text-[#0453cd] mb-2" />
                        <span className="text-xs">Loading questions...</span>
                      </div>
                    ) : suggestions.length > 0 ? (
                      <div className="border border-slate-200 rounded-xl overflow-hidden">
                        <table className="w-full text-left text-xs">
                          <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-mono uppercase text-[11px]">
                            <tr>
                              <th className="px-4 py-3">Order</th>
                              <th className="px-4 py-3">Label / Short Question</th>
                              <th className="px-4 py-3">Full Prompt</th>
                              <th className="px-4 py-3">Status</th>
                              <th className="px-4 py-3 text-right">Actions</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-slate-100">
                            {suggestions.map((sug, idx) => (
                              <tr key={sug.id} className="hover:bg-slate-50 transition-colors">
                                <td className="px-4 py-3 font-mono text-slate-500">#{sug.sortOrder ?? idx + 1}</td>
                                <td className="px-4 py-3 font-bold text-slate-900">{sug.label}</td>
                                <td className="px-4 py-3 text-slate-600 italic truncate max-w-xs">&ldquo;{sug.prompt}&rdquo;</td>
                                <td className="px-4 py-3">
                                  <button
                                    onClick={() => handleToggleSuggestionActive(sug)}
                                    className={`px-2 py-0.5 rounded-full text-[10px] font-bold font-mono cursor-pointer ${
                                      sug.isActive
                                        ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                                        : 'bg-slate-100 text-slate-500 border border-slate-200'
                                    }`}
                                  >
                                    {sug.isActive ? 'ACTIVE' : 'DISABLED'}
                                  </button>
                                </td>
                                <td className="px-4 py-3 text-right">
                                  <div className="flex items-center justify-end gap-1.5">
                                    <button
                                      onClick={() => {
                                        setEditingSuggestion(sug);
                                        setSuggestionForm({
                                          role: (sug.role as SupportedRole) || suggestionRole,
                                          label: sug.label,
                                          prompt: sug.prompt,
                                          sortOrder: sug.sortOrder || idx + 1,
                                        });
                                        setIsAddSuggestionOpen(true);
                                      }}
                                      className="p-1 rounded text-slate-500 hover:text-blue-600 hover:bg-slate-100"
                                      title="Edit question"
                                    >
                                      <Edit2 className="h-3.5 w-3.5" />
                                    </button>
                                    <button
                                      onClick={() => setSuggestionToDelete(sug)}
                                      className="p-1 rounded text-slate-500 hover:text-red-600 hover:bg-slate-100"
                                      title="Delete question"
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
                    ) : (
                      <EmptyState
                        title="No Suggested Questions"
                        description={`No suggested questions currently registered for the ${suggestionRole} portal.`}
                        compact
                      />
                    )}
                  </div>
                </Card>
              </div>
            )}

            {/* ==================================================================== */}
            {/* TAB 3: KNOWLEDGE BASE */}
            {/* ==================================================================== */}
            {activeTab === 'knowledge' && (
              <div className="space-y-6">
                {/* Search & Upload Action Bar */}
                <div className="flex flex-col sm:flex-row gap-3 justify-between items-stretch sm:items-center">
                  <div className="relative flex-1 max-w-md">
                    <Search className="h-4 w-4 text-slate-400 absolute left-3 top-3" />
                    <input
                      type="text"
                      value={knowledgeSearch}
                      onChange={(e) => setKnowledgeSearch(e.target.value)}
                      placeholder="Search documents by title, path, or category..."
                      className="w-full pl-9 pr-3.5 py-2 rounded-xl border border-slate-200 text-xs sm:text-sm focus:outline-none focus:ring-2 focus:ring-[#0453cd]"
                    />
                  </div>

                  <div className="flex items-center gap-2">
                    <Button
                      variant="primary"
                      size="sm"
                      onClick={() => setIsUploadDocOpen(true)}
                      className="bg-[#0453cd] text-xs shrink-0"
                    >
                      <Upload className="h-3.5 w-3.5 mr-1.5" />
                      Upload Document
                    </Button>
                  </div>
                </div>

                {/* Category Filter Pills */}
                <div className="flex items-center gap-2 overflow-x-auto pb-1">
                  <button
                    onClick={() => setKnowledgeCategoryFilter('ALL')}
                    className={`px-3 py-1.5 rounded-lg text-xs font-medium cursor-pointer transition-colors ${
                      knowledgeCategoryFilter === 'ALL'
                        ? 'bg-[#0453cd] text-white'
                        : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'
                    }`}
                  >
                    All Categories ({sources.length})
                  </button>
                  {uniqueCategories.map((cat) => (
                    <button
                      key={cat}
                      onClick={() => setKnowledgeCategoryFilter(cat)}
                      className={`px-3 py-1.5 rounded-lg text-xs font-medium cursor-pointer transition-colors whitespace-nowrap ${
                        knowledgeCategoryFilter === cat
                          ? 'bg-[#0453cd] text-white'
                          : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'
                      }`}
                    >
                      {cat}
                    </button>
                  ))}
                </div>

                {/* Clean Knowledge Documents Table */}
                <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden soft-elevation">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-mono uppercase tracking-wider text-[11px]">
                        <tr>
                          <th className="px-5 py-3.5">Document Title & Path</th>
                          <th className="px-5 py-3.5">Category</th>
                          <th className="px-5 py-3.5">Verification Source</th>
                          <th className="px-5 py-3.5">Audit Date</th>
                          <th className="px-5 py-3.5">Status</th>
                          <th className="px-5 py-3.5 text-right">Actions</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {filteredSources.length > 0 ? (
                          filteredSources.map((source) => {
                            const isApproved = source.status === 'approved';
                            return (
                              <tr key={source.id} className="hover:bg-slate-50/80 transition-colors">
                                <td className="px-5 py-4">
                                  <div className="space-y-0.5">
                                    <div className="font-bold text-slate-900">{source.title}</div>
                                    <div className="font-mono text-[10px] text-slate-400">{source.path}</div>
                                  </div>
                                </td>
                                <td className="px-5 py-4">
                                  <span className="px-2 py-0.5 rounded-full text-[10px] font-medium bg-blue-50 text-blue-700 border border-blue-200">
                                    {source.category}
                                  </span>
                                </td>
                                <td className="px-5 py-4 text-slate-600">
                                  {source.verificationAuthority || 'Studio Administrator'}
                                </td>
                                <td className="px-5 py-4 text-slate-500 font-mono text-[11px]">
                                  {source.lastAuditDate || formatRelativeTime(new Date(source.updatedAt || Date.now()))}
                                </td>
                                <td className="px-5 py-4">
                                  <span
                                    className={`px-2 py-0.5 rounded-full text-[10px] font-bold font-mono ${
                                      isApproved
                                        ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                                        : 'bg-amber-50 text-amber-800 border border-amber-200'
                                    }`}
                                  >
                                    {isApproved ? 'APPROVED' : 'DEACTIVATED'}
                                  </span>
                                </td>
                                <td className="px-5 py-4 text-right">
                                  <div className="flex items-center justify-end gap-2">
                                    <Button
                                      variant={isApproved ? 'outline' : 'success'}
                                      size="sm"
                                      loading={sourceTogglingId === source.id}
                                      onClick={() => handleToggleSourceStatus(source)}
                                      className="text-xs"
                                    >
                                      {isApproved ? 'Deactivate' : 'Approve'}
                                    </Button>
                                    <button
                                      onClick={() => setDocToDelete(source)}
                                      className="p-1.5 rounded text-slate-400 hover:text-red-600 hover:bg-slate-100"
                                      title="Delete document"
                                    >
                                      <Trash2 className="h-4 w-4" />
                                    </button>
                                  </div>
                                </td>
                              </tr>
                            );
                          })
                        ) : (
                          <tr>
                            <td colSpan={6} className="p-8 text-center text-slate-400">
                              No knowledge documents match your search criteria.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* ==================================================================== */}
            {/* TAB 4: CONVERSATIONS */}
            {/* ==================================================================== */}
            {activeTab === 'conversations' && (
              <div className="space-y-6">
                {/* Search & Role Filters (NO Client, NO Guest) */}
                <div className="flex flex-col sm:flex-row gap-3 justify-between items-stretch sm:items-center">
                  <div className="relative flex-1 max-w-md">
                    <Search className="h-4 w-4 text-slate-400 absolute left-3 top-3" />
                    <input
                      type="text"
                      value={conversationSearch}
                      onChange={(e) => setConversationSearch(e.target.value)}
                      placeholder="Search by user email, topic, or title..."
                      className="w-full pl-9 pr-3.5 py-2 rounded-xl border border-slate-200 text-xs sm:text-sm focus:outline-none focus:ring-2 focus:ring-[#0453cd]"
                    />
                  </div>

                  <div className="flex items-center gap-1.5 overflow-x-auto pb-1">
                    {[
                      { key: 'ALL', label: 'All Roles' },
                      { key: 'engineer', label: 'Engineer' },
                      { key: 'draughtsman', label: 'Draughtsman' },
                      { key: 'student', label: 'Student' },
                      { key: 'admin', label: 'Admin' },
                    ].map((rf) => (
                      <button
                        key={rf.key}
                        onClick={() => setConversationRoleFilter(rf.key as any)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-medium cursor-pointer transition-colors whitespace-nowrap ${
                          conversationRoleFilter === rf.key
                            ? 'bg-[#0453cd] text-white'
                            : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-50'
                        }`}
                      >
                        {rf.label}
                      </button>
                    ))}
                  </div>
                </div>

                {/* User-Grouped Conversations Table */}
                <div className="bg-white border border-slate-200 rounded-2xl overflow-hidden soft-elevation">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-xs">
                      <thead className="bg-slate-50 border-b border-slate-200 text-slate-500 font-mono uppercase tracking-wider text-[11px]">
                        <tr>
                          <th className="px-5 py-3.5">User</th>
                          <th className="px-5 py-3.5">Role</th>
                          <th className="px-5 py-3.5">Total Sessions</th>
                          <th className="px-5 py-3.5">Last Active</th>
                          <th className="px-5 py-3.5 text-right">Action</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-slate-100">
                        {userConversationGroups.length > 0 ? (
                          userConversationGroups.map((group) => {
                            const isExpanded = !!expandedUserIds[group.userId];
                            const roleColor =
                              group.userRole === 'engineer'
                                ? 'bg-blue-50 text-blue-800 border-blue-200'
                                : group.userRole === 'draughtsman'
                                ? 'bg-emerald-50 text-emerald-800 border-emerald-200'
                                : group.userRole === 'student'
                                ? 'bg-purple-50 text-purple-800 border-purple-200'
                                : 'bg-slate-100 text-slate-700 border-slate-200';

                            return (
                              <React.Fragment key={group.userId}>
                                <tr className={`hover:bg-slate-50/80 transition-colors ${isExpanded ? 'bg-slate-50/50' : ''}`}>
                                  <td className="px-5 py-4">
                                    <div className="flex items-center gap-2.5">
                                      <div className={`h-8 w-8 rounded-full flex items-center justify-center font-bold text-xs border shrink-0 ${roleColor}`}>
                                        {(group.userEmail || 'U').charAt(0).toUpperCase()}
                                      </div>
                                      <div>
                                        <div className="font-bold text-slate-900 truncate max-w-[220px]">
                                          {group.userEmail}
                                        </div>
                                        <div className="text-[10px] font-mono text-slate-400">
                                          ID: {group.userId.slice(0, 12)}...
                                        </div>
                                      </div>
                                    </div>
                                  </td>
                                  <td className="px-5 py-4">
                                    <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold font-mono border uppercase ${roleColor}`}>
                                      {group.userRole}
                                    </span>
                                  </td>
                                  <td className="px-5 py-4">
                                    <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
                                      <MessageSquare className="h-3 w-3 text-slate-400" />
                                      {group.totalSessions} {group.totalSessions === 1 ? 'session' : 'sessions'}
                                    </span>
                                  </td>
                                  <td className="px-5 py-4 text-slate-500 font-mono text-[11px]">
                                    {formatRelativeTime(new Date(group.lastActive))}
                                  </td>
                                  <td className="px-5 py-4 text-right">
                                    <Button
                                      variant={isExpanded ? 'primary' : 'secondary'}
                                      size="sm"
                                      onClick={() => toggleUserExpanded(group.userId)}
                                      className="text-xs cursor-pointer inline-flex items-center gap-1.5"
                                    >
                                      {isExpanded ? (
                                        <>
                                          <ChevronUp className="h-3.5 w-3.5" />
                                          Hide History
                                        </>
                                      ) : (
                                        <>
                                          <ChevronDown className="h-3.5 w-3.5" />
                                          View History ({group.totalSessions})
                                        </>
                                      )}
                                    </Button>
                                  </td>
                                </tr>

                                {/* Expanded Conversation History View */}
                                {isExpanded && (
                                  <tr className="bg-slate-50/70 border-b border-slate-200">
                                    <td colSpan={5} className="p-4 sm:p-5">
                                      <div className="bg-white border border-slate-200 rounded-xl p-4 shadow-sm space-y-3">
                                        <div className="flex items-center justify-between pb-2 border-b border-slate-100">
                                          <div className="flex items-center gap-2">
                                            <Bot className="h-4 w-4 text-[#0453cd]" />
                                            <span className="font-semibold text-slate-800 text-xs">
                                              Conversation History for <span className="text-[#0453cd] font-mono">{group.userEmail}</span>
                                            </span>
                                          </div>
                                          <span className="text-[11px] font-mono text-slate-400">
                                            {group.sessions.length} recorded {group.sessions.length === 1 ? 'session' : 'sessions'}
                                          </span>
                                        </div>

                                        <div className="overflow-x-auto">
                                          <table className="w-full text-left text-xs">
                                            <thead className="text-[10px] uppercase font-mono text-slate-400 border-b border-slate-100 pb-2">
                                              <tr>
                                                <th className="pb-2 font-medium">Conversation Title</th>
                                                <th className="pb-2 font-medium">Created</th>
                                                <th className="pb-2 font-medium">Last Active</th>
                                                <th className="pb-2 font-medium">Messages</th>
                                                <th className="pb-2 font-medium text-right">Action</th>
                                              </tr>
                                            </thead>
                                            <tbody className="divide-y divide-slate-100">
                                              {group.sessions.map((conv) => (
                                                <tr key={conv.id} className="hover:bg-slate-50 transition-colors">
                                                  <td className="py-2.5 pr-3">
                                                    <div className="flex items-center gap-2">
                                                      <div className="h-2 w-2 rounded-full bg-emerald-500 shrink-0" />
                                                      <span className="font-semibold text-slate-800 max-w-[280px] truncate" title={conv.title}>
                                                        {conv.title}
                                                      </span>
                                                    </div>
                                                  </td>
                                                  <td className="py-2.5 pr-3 text-slate-500 font-mono text-[11px]">
                                                    {conv.createdAt ? new Date(conv.createdAt).toLocaleDateString(undefined, { month: 'short', day: 'numeric', hour: '2-digit', minute: '2-digit' }) : '—'}
                                                  </td>
                                                  <td className="py-2.5 pr-3 text-slate-500 font-mono text-[11px]">
                                                    {formatRelativeTime(new Date(conv.updatedAt || conv.createdAt))}
                                                  </td>
                                                  <td className="py-2.5 pr-3">
                                                    <span className="inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-mono bg-blue-50 text-blue-700 border border-blue-200">
                                                      {conv.messageCount ?? 0} {conv.messageCount === 1 ? 'msg' : 'msgs'}
                                                    </span>
                                                  </td>
                                                  <td className="py-2.5 text-right">
                                                    <Button
                                                      variant="secondary"
                                                      size="sm"
                                                      onClick={() => handleInspectSession(conv)}
                                                      className="text-xs h-7 px-2.5 cursor-pointer hover:bg-[#0453cd] hover:text-white transition-colors"
                                                    >
                                                      <Eye className="h-3 w-3 mr-1" />
                                                      Inspect Chat
                                                    </Button>
                                                  </td>
                                                </tr>
                                              ))}
                                            </tbody>
                                          </table>
                                        </div>
                                      </div>
                                    </td>
                                  </tr>
                                )}
                              </React.Fragment>
                            );
                          })
                        ) : (
                          <tr>
                            <td colSpan={5} className="p-8 text-center text-slate-400">
                              No conversations match your search criteria.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            )}

            {/* ==================================================================== */}
            {/* TAB 5: FEEDBACK, QUESTION ANALYTICS & KNOWLEDGE GAP AUDIT */}
            {/* ==================================================================== */}
            {activeTab === 'insights' && (
              <div className="space-y-6">
                {/* ──────────────────────────────────────────────────────────── */}
                {/* 1. AUDIT SUMMARY METRIC CARDS (6 KPIS) */}
                {/* ──────────────────────────────────────────────────────────── */}
                <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-6 gap-3">
                  <div className="bg-white border border-slate-200 rounded-xl p-4 border-t-4 border-t-blue-600 soft-elevation">
                    <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-wider block">
                      Questions Analyzed
                    </span>
                    <span className="text-2xl font-extrabold font-mono text-slate-900 mt-1 block">
                      {questionAnalytics?.summary.totalQuestionsAnalyzed ?? 0}
                    </span>
                    <span className="text-[10px] text-slate-400 mt-1 block">In scope queries</span>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-xl p-4 border-t-4 border-t-indigo-600 soft-elevation">
                    <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-wider block">
                      Question Groups
                    </span>
                    <span className="text-2xl font-extrabold font-mono text-slate-900 mt-1 block">
                      {questionAnalytics?.summary.uniqueQuestionGroups ?? 0}
                    </span>
                    <span className="text-[10px] text-slate-400 mt-1 block">Semantic topics</span>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-xl p-4 border-t-4 border-t-emerald-600 soft-elevation">
                    <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-wider block">
                      Most Repeated
                    </span>
                    <span className="text-sm font-bold text-slate-900 mt-1 block truncate" title={questionAnalytics?.summary.mostRepeatedTopic}>
                      {questionAnalytics?.summary.mostRepeatedTopic || 'None'}
                    </span>
                    <span className="text-[10px] text-emerald-600 font-medium mt-1 block flex items-center gap-1">
                      <TrendingUp className="h-3 w-3" /> Top volume
                    </span>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-xl p-4 border-t-4 border-t-amber-600 soft-elevation">
                    <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-wider block">
                      Unanswered
                    </span>
                    <span className="text-2xl font-extrabold font-mono text-slate-900 mt-1 block">
                      {questionAnalytics?.summary.unansweredQuestionCount ?? 0}
                    </span>
                    <span className="text-[10px] text-amber-600 mt-1 block font-medium">Low confidence</span>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-xl p-4 border-t-4 border-t-rose-600 soft-elevation">
                    <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-wider block">
                      Negative Ratings
                    </span>
                    <span className="text-2xl font-extrabold font-mono text-slate-900 mt-1 block">
                      {questionAnalytics?.summary.negativeFeedbackCount ?? 0}
                    </span>
                    <span className="text-[10px] text-rose-600 mt-1 block font-medium">-1 feedback</span>
                  </div>

                  <div className="bg-white border border-slate-200 rounded-xl p-4 border-t-4 border-t-red-600 soft-elevation">
                    <span className="text-[10px] font-mono font-bold text-slate-500 uppercase tracking-wider block">
                      Topics To Review
                    </span>
                    <span className="text-2xl font-extrabold font-mono text-red-600 mt-1 block">
                      {questionAnalytics?.summary.topicsNeedingAttention ?? 0}
                    </span>
                    <span className="text-[10px] text-red-600 mt-1 block font-medium flex items-center gap-0.5">
                      <AlertCircle className="h-3 w-3" /> Action items
                    </span>
                  </div>
                </div>

                {/* ──────────────────────────────────────────────────────────── */}
                {/* 2. ANALYTICS CONTROL & FILTERS BAR */}
                {/* ──────────────────────────────────────────────────────────── */}
                <div className="p-4 rounded-xl bg-white border border-slate-200 soft-elevation flex flex-col lg:flex-row lg:items-center justify-between gap-3">
                  <div className="flex flex-wrap items-center gap-2">
                    {/* Portal Filter */}
                    <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-lg">
                      {[
                        { key: 'all', label: 'All Portals' },
                        { key: 'engineer', label: 'Engineer' },
                        { key: 'draughtsman', label: 'Draughtsman' },
                        { key: 'student', label: 'Student' },
                      ].map((p) => (
                        <button
                          key={p.key}
                          onClick={() => setAnalyticsFilter((prev) => ({ ...prev, portal: p.key as any }))}
                          className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                            analyticsFilter.portal === p.key
                              ? 'bg-white text-slate-900 shadow-sm font-bold'
                              : 'text-slate-600 hover:text-slate-900'
                          }`}
                        >
                          {p.label}
                        </button>
                      ))}
                    </div>

                    {/* Time Window Filter */}
                    <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-lg">
                      {[
                        { key: 'today', label: 'Today' },
                        { key: '7d', label: '7 Days' },
                        { key: '30d', label: '30 Days' },
                        { key: 'all', label: 'All Time' },
                      ].map((tw) => (
                        <button
                          key={tw.key}
                          onClick={() => setAnalyticsFilter((prev) => ({ ...prev, timeRange: tw.key as any }))}
                          className={`px-2.5 py-1 rounded-md text-xs font-medium cursor-pointer transition-colors ${
                            analyticsFilter.timeRange === tw.key
                              ? 'bg-white text-slate-900 shadow-sm font-bold'
                              : 'text-slate-600 hover:text-slate-900'
                          }`}
                        >
                          {tw.label}
                        </button>
                      ))}
                    </div>

                    {/* Search Topic */}
                    <div className="relative">
                      <Search className="h-3.5 w-3.5 text-slate-400 absolute left-2.5 top-2.5" />
                      <input
                        type="text"
                        value={analyticsFilter.search || ''}
                        onChange={(e) => setAnalyticsFilter((prev) => ({ ...prev, search: e.target.value }))}
                        placeholder="Search topic or variation..."
                        className="pl-8 pr-3 py-1.5 rounded-lg border border-slate-200 text-xs focus:outline-none focus:ring-2 focus:ring-[#0453cd] w-48 sm:w-60"
                      />
                    </div>
                  </div>

                  <div className="flex items-center gap-2 shrink-0">
                    <Button
                      variant="primary"
                      size="sm"
                      onClick={handleExportCsvReport}
                      loading={isExportingCsv}
                      className="bg-[#0453cd] text-xs font-medium"
                    >
                      <Download className="h-3.5 w-3.5 mr-1.5" />
                      Generate Question Audit Report
                    </Button>
                  </div>
                </div>

                {/* Grouping Engine Transparency Badge */}
                <div className="flex items-center justify-between text-[11px] text-slate-500 font-mono px-1">
                  <span>
                    Grouping Method: <strong className="text-slate-700">{questionAnalytics?.summary.groupingMethod || 'Normalized Architectural Intent & Token Clustering'}</strong>
                  </span>
                  <span>
                    Audit Window: {questionAnalytics?.summary.auditPeriod.timeRange.toUpperCase()}
                  </span>
                </div>

                {/* ──────────────────────────────────────────────────────────── */}
                {/* 3. MOST FREQUENTLY ASKED QUESTIONS TABLE */}
                {/* ──────────────────────────────────────────────────────────── */}
                <Card>
                  <CardHeader
                    title="Most Frequently Asked Questions"
                    subtitle="Ranked architectural inquiries grouped by semantic topic and normalized intent"
                  />
                  <div className="p-0 overflow-x-auto">
                    {loadingAnalytics ? (
                      <div className="py-12 text-center text-slate-400">
                        <RefreshCw className="h-6 w-6 animate-spin mx-auto text-[#0453cd] mb-2" />
                        <span className="text-xs">Analyzing conversation records...</span>
                      </div>
                    ) : questionAnalytics && questionAnalytics.frequentlyAskedQuestions.length > 0 ? (
                      <table className="w-full text-left text-xs">
                        <thead className="bg-slate-50 border-y border-slate-200 text-slate-500 font-mono uppercase tracking-wider text-[11px]">
                          <tr>
                            <th className="px-5 py-3.5">Rank</th>
                            <th className="px-5 py-3.5">Question / Topic</th>
                            <th className="px-5 py-3.5 text-center">Times Asked</th>
                            <th className="px-5 py-3.5">Portal Distribution</th>
                            <th className="px-5 py-3.5">Last Asked</th>
                            <th className="px-5 py-3.5 text-right">Action</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-slate-100">
                          {questionAnalytics.frequentlyAskedQuestions.map((faq) => (
                            <tr key={faq.id} className="hover:bg-slate-50/80 transition-colors">
                              <td className="px-5 py-4 font-mono font-bold text-slate-500">#{faq.rank}</td>
                              <td className="px-5 py-4">
                                <div className="space-y-1">
                                  <div className="flex items-center gap-2">
                                    <span className="font-bold text-slate-900">{faq.topic}</span>
                                    <span className="px-2 py-0.5 rounded text-[10px] font-mono bg-blue-50 text-blue-700 border border-blue-200">
                                      {faq.category}
                                    </span>
                                    {faq.isFlaggedGap && (
                                      <span className="px-1.5 py-0.5 rounded text-[10px] font-bold font-mono bg-amber-50 text-amber-700 border border-amber-200 flex items-center gap-1">
                                        <AlertTriangle className="h-3 w-3" /> GAP
                                      </span>
                                    )}
                                  </div>
                                  <p className="text-slate-500 text-[11px] italic truncate max-w-md">
                                    Variations: &ldquo;{faq.originalVariations[0]?.text || faq.topic}&rdquo;
                                    {faq.originalVariations.length > 1 && (
                                      <span className="text-blue-600 font-medium ml-1">
                                        (+{faq.originalVariations.length - 1} more)
                                      </span>
                                    )}
                                  </p>
                                </div>
                              </td>
                              <td className="px-5 py-4 text-center font-mono font-extrabold text-sm text-slate-900">
                                {faq.timesAsked}
                                <span className="block text-[10px] font-normal text-slate-400">
                                  {faq.uniqueUsersCount} {faq.uniqueUsersCount === 1 ? 'user' : 'users'}
                                </span>
                              </td>
                              <td className="px-5 py-4">
                                <div className="flex items-center gap-1.5 text-[10px] font-mono">
                                  {faq.portals.engineer > 0 && (
                                    <span className="px-2 py-0.5 rounded bg-blue-50 text-blue-700 font-medium">
                                      Eng: {faq.portals.engineer}
                                    </span>
                                  )}
                                  {faq.portals.draughtsman > 0 && (
                                    <span className="px-2 py-0.5 rounded bg-emerald-50 text-emerald-700 font-medium">
                                      Drt: {faq.portals.draughtsman}
                                    </span>
                                  )}
                                  {faq.portals.student > 0 && (
                                    <span className="px-2 py-0.5 rounded bg-purple-50 text-purple-700 font-medium">
                                      Stu: {faq.portals.student}
                                    </span>
                                  )}
                                </div>
                              </td>
                              <td className="px-5 py-4 text-slate-500 font-mono text-[11px]">
                                {formatRelativeTime(new Date(faq.lastAsked))}
                              </td>
                              <td className="px-5 py-4 text-right">
                                <Button
                                  variant="secondary"
                                  size="sm"
                                  onClick={() => setSelectedFaqGroup(faq)}
                                  className="text-xs"
                                >
                                  <Eye className="h-3.5 w-3.5 mr-1" />
                                  Inspect Details
                                </Button>
                              </td>
                            </tr>
                          ))}
                        </tbody>
                      </table>
                    ) : (
                      <div className="p-8">
                        <EmptyState
                          title="No Questions Recorded in Time Window"
                          description="When users ask questions across Engineer, Draughtsman, or Student portals, analytics and repeated topics will appear here."
                          compact
                        />
                      </div>
                    )}
                  </div>
                </Card>

                {/* ──────────────────────────────────────────────────────────── */}
                {/* 4. KNOWLEDGE GAPS & ACTION ITEMS */}
                {/* ──────────────────────────────────────────────────────────── */}
                <Card>
                  <CardHeader
                    title="Knowledge Gaps & Documentation Action Items"
                    subtitle="Identifies topics with unanswered inquiries, negative feedback, or missing verified guidelines"
                  />
                  <div className="p-6">
                    {questionAnalytics && questionAnalytics.knowledgeGaps.length > 0 ? (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {questionAnalytics.knowledgeGaps.map((gap) => (
                          <div
                            key={gap.id}
                            className="p-4 rounded-xl border border-amber-200 bg-amber-50/40 space-y-3 soft-elevation"
                          >
                            <div className="flex items-start justify-between gap-2">
                              <div>
                                <span className="font-bold text-sm text-slate-900 block">{gap.topic}</span>
                                <span className="text-[10px] font-mono uppercase px-2 py-0.5 rounded bg-amber-100 text-amber-800 font-bold inline-block mt-1">
                                  {gap.category}
                                </span>
                              </div>
                              <span className="text-xs font-mono font-bold text-amber-900 bg-white px-2 py-1 rounded border border-amber-200">
                                {gap.affectedQuestionsCount} affected
                              </span>
                            </div>

                            <p className="text-xs text-slate-700 bg-white p-2.5 rounded-lg border border-amber-100">
                              <strong>Flag Reason:</strong> {gap.flagReason}
                            </p>

                            <div className="flex items-center justify-between pt-1 border-t border-amber-200/60">
                              <span className="text-[11px] font-medium text-amber-900">
                                Action: {gap.recommendedAction}
                              </span>
                              <Button
                                variant="outline"
                                size="sm"
                                onClick={() => {
                                  setActiveTab('knowledge');
                                  setIsUploadDocOpen(true);
                                  setUploadDocForm({
                                    title: `${gap.topic} Guidelines`,
                                    category: gap.category,
                                    content: `# ${gap.topic}\n\nVerified architectural guidelines for ${gap.topic.toLowerCase()}...`,
                                  });
                                }}
                                className="text-xs border-amber-300 text-amber-900 hover:bg-amber-100"
                              >
                                <Upload className="h-3 w-3 mr-1" />
                                Upload Document
                              </Button>
                            </div>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <EmptyState
                        title="No Knowledge Gaps Detected"
                        description="All analyzed topics currently exhibit sufficient knowledge coverage, zero grounding failures, and acceptable user satisfaction."
                        compact
                      />
                    )}
                  </div>
                </Card>

                {/* ──────────────────────────────────────────────────────────── */}
                {/* 5. USER FEEDBACK STREAM */}
                {/* ──────────────────────────────────────────────────────────── */}
                <Card>
                  <CardHeader
                    title="User Satisfaction & Feedback"
                    subtitle="Real-time ratings (+1 / -1) and comments submitted by users"
                  />
                  <div className="p-6">
                    {feedback.length > 0 ? (
                      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                        {feedback.map((item) => (
                          <div
                            key={item.id}
                            className="p-4 rounded-xl border border-slate-200 bg-white space-y-2 soft-elevation"
                          >
                            <div className="flex items-center justify-between">
                              <span
                                className={`flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-bold font-mono ${
                                  item.rating === 1
                                    ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                                    : 'bg-red-50 text-red-800 border border-red-200'
                                }`}
                              >
                                {item.rating === 1 ? (
                                  <>
                                    <ThumbsUp className="h-3.5 w-3.5" /> Helpful (+1)
                                  </>
                                ) : (
                                  <>
                                    <ThumbsDown className="h-3.5 w-3.5" /> Unhelpful (-1)
                                  </>
                                )}
                              </span>
                              <span className="text-[11px] text-slate-400 font-mono">
                                {formatRelativeTime(new Date(item.createdAt))}
                              </span>
                            </div>

                            {item.feedbackText && (
                              <p className="text-xs text-slate-800 bg-slate-50 p-2.5 rounded-lg border border-slate-100">
                                &ldquo;{item.feedbackText}&rdquo;
                              </p>
                            )}

                            {item.messageContent && (
                              <p className="text-[11px] text-slate-500 truncate">
                                Context: &ldquo;{item.messageContent}&rdquo;
                              </p>
                            )}
                          </div>
                        ))}
                      </div>
                    ) : (
                      <EmptyState
                        title="No Feedback Submitted"
                        description="User ratings and comments on chatbot answers will appear here."
                        compact
                      />
                    )}
                  </div>
                </Card>

                {/* ──────────────────────────────────────────────────────────── */}
                {/* 6. ADMINISTRATIVE ACTIVITY STREAM */}
                {/* ──────────────────────────────────────────────────────────── */}
                <Card>
                  <CardHeader
                    title="Administrative Activity Stream"
                    subtitle="Comprehensive audit trail of configuration mutations, knowledge updates, and governance actions"
                  />
                  <div className="p-6 space-y-4">
                    <div className="flex items-center justify-between gap-3">
                      <span className="text-xs text-slate-500 font-mono">
                        Showing {filteredAuditLogs.length} events
                      </span>
                      <select
                        value={auditActionFilter}
                        onChange={(e) => setAuditActionFilter(e.target.value)}
                        className="px-2.5 py-1.5 rounded-lg border border-slate-200 text-xs font-mono bg-white"
                      >
                        <option value="ALL">All Actions</option>
                        <option value="UPDATE_CONFIG">Configuration Changes</option>
                        <option value="APPROVE_KNOWLEDGE_SOURCE">Knowledge Approvals</option>
                        <option value="DEACTIVATE_KNOWLEDGE_SOURCE">Knowledge Deactivations</option>
                        <option value="UPLOAD_KNOWLEDGE_DOCUMENT">Document Uploads</option>
                        <option value="CREATE_SUGGESTION">Suggestion Additions</option>
                        <option value="DELETE_SUGGESTION">Suggestion Deletions</option>
                      </select>
                    </div>

                    {filteredAuditLogs.length > 0 ? (
                      <div className="divide-y divide-slate-100">
                        {filteredAuditLogs.map((log) => (
                          <div key={log.id} className="py-3 first:pt-0 last:pb-0 flex items-start justify-between gap-3 text-xs">
                            <div className="space-y-1">
                              <div className="flex items-center gap-2">
                                <span className="font-mono font-bold px-2 py-0.5 rounded bg-slate-100 text-slate-800 border border-slate-200 text-[10px]">
                                  {log.action}
                                </span>
                                {log.target && (
                                  <span className="text-slate-600 font-mono truncate max-w-xs">{log.target}</span>
                                )}
                              </div>
                              <p className="text-slate-400 font-mono text-[11px]">
                                By: {log.adminUserId ? `${log.adminUserId.slice(0, 14)}...` : 'Administrator'}
                              </p>
                            </div>
                            <span className="text-slate-400 shrink-0 font-mono text-[11px]">
                              {formatRelativeTime(new Date(log.createdAt))}
                            </span>
                          </div>
                        ))}
                      </div>
                    ) : (
                      <EmptyState
                        title="No Audit Logs"
                        description="No activity records match the selected action filter."
                        compact
                      />
                    )}
                  </div>
                </Card>
              </div>
            )}
          </div>
        )}

        {/* ==================================================================== */}
        {/* MODAL 1: ADD / EDIT SUGGESTED QUESTION */}
        {/* ==================================================================== */}
        <Modal
          isOpen={isAddSuggestionOpen}
          onClose={() => {
            setIsAddSuggestionOpen(false);
            setEditingSuggestion(null);
          }}
          title={editingSuggestion ? 'Edit Suggested Question' : 'Add Suggested Question'}
        >
          <form onSubmit={handleSaveSuggestion} className="space-y-4 p-4 text-xs">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Target Portal / Role</label>
              <select
                value={suggestionForm.role}
                onChange={(e) => setSuggestionForm((prev) => ({ ...prev, role: e.target.value as SupportedRole }))}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs font-mono"
              >
                {SUPPORTED_ROLES.map((r) => (
                  <option key={r.key} value={r.key}>
                    {r.label} Portal
                  </option>
                ))}
              </select>
            </div>

            <div>
              <label className="block font-bold text-slate-700 mb-1">Question Label (Short Display)</label>
              <input
                type="text"
                value={suggestionForm.label}
                onChange={(e) => setSuggestionForm((prev) => ({ ...prev, label: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs"
                placeholder="e.g. How do I review a drawing?"
                required
              />
            </div>

            <div>
              <label className="block font-bold text-slate-700 mb-1">Full Query Prompt (Sent to Bot)</label>
              <textarea
                value={suggestionForm.prompt}
                onChange={(e) => setSuggestionForm((prev) => ({ ...prev, prompt: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs"
                rows={3}
                placeholder="e.g. What are the standard steps for conducting an architectural technical review?"
                required
              />
            </div>

            <div>
              <label className="block font-bold text-slate-700 mb-1">Sort Order Number</label>
              <input
                type="number"
                value={suggestionForm.sortOrder}
                onChange={(e) => setSuggestionForm((prev) => ({ ...prev, sortOrder: parseInt(e.target.value, 10) || 0 }))}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs font-mono"
                min={0}
                max={50}
              />
            </div>

            <div className="pt-3 border-t border-slate-200 flex justify-end gap-2">
              <Button
                variant="outline"
                size="sm"
                type="button"
                onClick={() => {
                  setIsAddSuggestionOpen(false);
                  setEditingSuggestion(null);
                }}
              >
                Cancel
              </Button>
              <Button
                variant="primary"
                size="sm"
                type="submit"
                loading={isSuggestionSaving}
                className="bg-[#0453cd]"
              >
                {editingSuggestion ? 'Update Question' : 'Save Question'}
              </Button>
            </div>
          </form>
        </Modal>

        {/* ==================================================================== */}
        {/* MODAL 2: DELETE SUGGESTION CONFIRMATION */}
        {/* ==================================================================== */}
        <Modal
          isOpen={Boolean(suggestionToDelete)}
          onClose={() => setSuggestionToDelete(null)}
          title="Delete Suggested Question"
        >
          <div className="p-4 space-y-4 text-xs">
            <p className="text-slate-600">
              Are you sure you want to delete the suggested question{' '}
              <strong>&ldquo;{suggestionToDelete?.label}&rdquo;</strong> for the {suggestionToDelete?.role} portal?
            </p>
            <div className="pt-2 flex justify-end gap-2">
              <Button variant="outline" size="sm" onClick={() => setSuggestionToDelete(null)}>
                Cancel
              </Button>
              <Button variant="danger" size="sm" onClick={handleDeleteSuggestion} className="bg-red-600 text-white">
                Delete Question
              </Button>
            </div>
          </div>
        </Modal>

        {/* ==================================================================== */}
        {/* MODAL 3: UPLOAD KNOWLEDGE DOCUMENT */}
        {/* ==================================================================== */}
        <Modal
          isOpen={isUploadDocOpen}
          onClose={() => setIsUploadDocOpen(false)}
          title="Upload Knowledge Document"
        >
          <form onSubmit={handleUploadDocument} className="space-y-4 p-4 text-xs">
            <div>
              <label className="block font-bold text-slate-700 mb-1">Document Title</label>
              <input
                type="text"
                value={uploadDocForm.title}
                onChange={(e) => setUploadDocForm((prev) => ({ ...prev, title: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs"
                placeholder="e.g. Architectural Drawing Annotation Guidelines"
                required
              />
            </div>

            <div>
              <label className="block font-bold text-slate-700 mb-1">Category</label>
              <input
                type="text"
                value={uploadDocForm.category}
                onChange={(e) => setUploadDocForm((prev) => ({ ...prev, category: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs"
                placeholder="e.g. Architectural Standards"
                required
              />
            </div>

            <div>
              <label className="block font-bold text-slate-700 mb-1">Document Content (Markdown / Text)</label>
              <textarea
                value={uploadDocForm.content}
                onChange={(e) => setUploadDocForm((prev) => ({ ...prev, content: e.target.value }))}
                className="w-full px-3 py-2 rounded-lg border border-slate-200 text-xs font-mono"
                rows={6}
                placeholder="Paste the verified architectural guidelines, specifications, or FAQ content here..."
                required
              />
            </div>

            <div className="pt-3 border-t border-slate-200 flex justify-end gap-2">
              <Button variant="outline" size="sm" type="button" onClick={() => setIsUploadDocOpen(false)}>
                Cancel
              </Button>
              <Button variant="primary" size="sm" type="submit" loading={isDocUploading} className="bg-[#0453cd]">
                Upload & Index Document
              </Button>
            </div>
          </form>
        </Modal>

        {/* ==================================================================== */}
        {/* MODAL 4: DELETE DOCUMENT CONFIRMATION */}
        {/* ==================================================================== */}
        <Modal
          isOpen={Boolean(docToDelete)}
          onClose={() => setDocToDelete(null)}
          title="Delete Knowledge Document"
        >
          <div className="p-4 space-y-4 text-xs">
            <p className="text-slate-600">
              Are you sure you want to permanently delete the document{' '}
              <strong>&ldquo;{docToDelete?.title}&rdquo;</strong> from the knowledge base?
            </p>
            <div className="pt-2 flex justify-end gap-2">
              <Button variant="outline" size="sm" onClick={() => setDocToDelete(null)}>
                Cancel
              </Button>
              <Button variant="danger" size="sm" onClick={handleDeleteDocument} className="bg-red-600 text-white">
                Delete Document
              </Button>
            </div>
          </div>
        </Modal>

        {/* ==================================================================== */}
        {/* MODAL 5: INSPECT CONVERSATION SESSION (WHATSAPP-STYLE CHAT INTERFACE) */}
        {/* ==================================================================== */}
        <Modal
          isOpen={Boolean(selectedSession)}
          onClose={() => {
            setSelectedSession(null);
            setInspectMessages([]);
            setInspectError(null);
          }}
          title={selectedSession ? `Conversation: ${selectedSession.title}` : 'Inspect Conversation'}
          description={selectedSession ? `Continuous chat session with ${selectedSession.userEmail || 'user'} (${selectedSession.userRole.toUpperCase()})` : undefined}
          maxWidth="3xl"
        >
          <div className="p-4 sm:p-5 flex flex-col max-h-[82vh] overflow-hidden text-xs">
            {/* Header: User Profile & Session Info Bar */}
            {selectedSession && (
              <div className="p-3.5 mb-3 rounded-xl bg-slate-50 border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 shrink-0">
                <div className="flex items-center gap-3">
                  <div
                    className={`h-10 w-10 rounded-full flex items-center justify-center font-bold text-sm border shrink-0 ${
                      selectedSession.userRole === 'engineer'
                        ? 'bg-blue-100 text-blue-800 border-blue-200'
                        : selectedSession.userRole === 'draughtsman'
                        ? 'bg-emerald-100 text-emerald-800 border-emerald-200'
                        : selectedSession.userRole === 'student'
                        ? 'bg-purple-100 text-purple-800 border-purple-200'
                        : 'bg-slate-200 text-slate-800 border-slate-300'
                    }`}
                  >
                    {(selectedSession.userEmail || 'U').charAt(0).toUpperCase()}
                  </div>
                  <div>
                    <div className="flex items-center gap-2">
                      <span className="font-bold text-slate-900 text-sm">
                        {selectedSession.userEmail || 'Authenticated User'}
                      </span>
                      <span
                        className={`px-2 py-0.5 rounded text-[10px] font-mono font-bold uppercase border ${
                          selectedSession.userRole === 'engineer'
                            ? 'bg-blue-50 text-blue-700 border-blue-200'
                            : selectedSession.userRole === 'draughtsman'
                            ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            : selectedSession.userRole === 'student'
                            ? 'bg-purple-50 text-purple-700 border-purple-200'
                            : 'bg-slate-100 text-slate-700 border-slate-200'
                        }`}
                      >
                        {selectedSession.userRole}
                      </span>
                    </div>
                    <div className="text-[11px] text-slate-500 flex items-center gap-2 mt-0.5">
                      <span>Topic: <strong className="text-slate-700">{selectedSession.title}</strong></span>
                    </div>
                  </div>
                </div>

                <div className="flex items-center gap-2 sm:self-center shrink-0">
                  <span
                    className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-[11px] font-medium ${
                      !selectedSession.isArchived
                        ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                        : 'bg-slate-100 text-slate-600 border border-slate-200'
                    }`}
                  >
                    <span
                      className={`h-2 w-2 rounded-full ${
                        !selectedSession.isArchived ? 'bg-emerald-500 animate-pulse' : 'bg-slate-400'
                      }`}
                    />
                    {!selectedSession.isArchived ? 'Active Session' : 'Archived'}
                  </span>
                  <span className="px-2.5 py-1 rounded-full bg-slate-100 font-mono text-[11px] text-slate-700 border border-slate-200">
                    {inspectMessages.length} {inspectMessages.length === 1 ? 'message' : 'messages'}
                  </span>
                </div>
              </div>
            )}

            {/* Error Banner */}
            {inspectError && (
              <div className="mb-3 p-3 rounded-xl bg-amber-50 border border-amber-200 text-amber-800 text-xs flex items-center justify-between shrink-0">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="h-4 w-4 text-amber-600 shrink-0" />
                  <span>{inspectError}</span>
                </div>
                {selectedSession && (
                  <Button size="sm" variant="secondary" onClick={() => handleInspectSession(selectedSession)}>
                    Retry
                  </Button>
                )}
              </div>
            )}

            {/* Continuous Chat Message Canvas (WhatsApp / Messaging UI) */}
            <div className="flex-1 bg-slate-50 border border-slate-200 rounded-2xl p-4 sm:p-5 overflow-y-auto space-y-4 max-h-[55vh] min-h-[340px]">
              {loadingMessages ? (
                <div className="py-16 text-center space-y-3">
                  <div className="flex items-center justify-center gap-2 text-[#0453cd]">
                    <span className="h-2.5 w-2.5 rounded-full bg-[#0453cd] animate-bounce" style={{ animationDelay: '0ms' }} />
                    <span className="h-2.5 w-2.5 rounded-full bg-[#0453cd] animate-bounce" style={{ animationDelay: '150ms' }} />
                    <span className="h-2.5 w-2.5 rounded-full bg-[#0453cd] animate-bounce" style={{ animationDelay: '300ms' }} />
                  </div>
                  <p className="text-xs text-slate-500 font-medium">Loading continuous conversation history...</p>
                </div>
              ) : inspectMessages.length > 0 ? (
                (() => {
                  let lastDateGroup = '';
                  return inspectMessages.map((msg) => {
                    const isBot = msg.sender === 'bot';
                    const dateGroup = getMessageDateGroup(msg.createdAt);
                    const showDateDivider = dateGroup !== lastDateGroup;
                    lastDateGroup = dateGroup;

                    return (
                      <React.Fragment key={msg.id}>
                        {showDateDivider && (
                          <div className="flex justify-center my-2">
                            <span className="px-3 py-1 rounded-full bg-white/90 backdrop-blur-xs text-[10px] font-mono font-medium text-slate-500 shadow-xs border border-slate-200">
                              {dateGroup}
                            </span>
                          </div>
                        )}

                        {isBot ? (
                          /* PIXMINT BOT MESSAGE (Left-Aligned Bubble) */
                          <div className="flex justify-start items-start gap-2.5 group">
                            <div className="h-8 w-8 rounded-full bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center shrink-0 mt-0.5 shadow-xs">
                              <Bot className="h-4 w-4" />
                            </div>

                            <div className="max-w-[88%] sm:max-w-[80%] rounded-2xl rounded-tl-xs bg-white border border-slate-200/90 text-slate-900 p-3.5 sm:p-4 shadow-xs space-y-2">
                              {/* Bot Header */}
                              <div className="flex items-center justify-between gap-2 pb-1.5 border-b border-slate-100 text-[11px]">
                                <div className="flex items-center gap-1.5 font-bold text-slate-800">
                                  <span>PIXMINT BOT</span>
                                  <span className="text-[10px] font-mono px-1.5 py-0.2 rounded bg-blue-50 text-blue-700 font-semibold">
                                    v2.0
                                  </span>
                                </div>
                                <div className="flex items-center gap-2 text-[10px] font-mono text-slate-400">
                                  {msg.latencyMs && (
                                    <span className="flex items-center gap-0.5 text-emerald-600 font-medium">
                                      <Clock className="h-3 w-3" />
                                      {msg.latencyMs}ms
                                    </span>
                                  )}
                                  {msg.modelName && (
                                    <span className="hidden sm:inline px-1 py-0.2 rounded bg-slate-100 text-slate-600">
                                      {msg.modelName}
                                    </span>
                                  )}
                                </div>
                              </div>

                              {/* Message Content */}
                              <p className="text-xs sm:text-sm leading-relaxed whitespace-pre-wrap break-words text-slate-800">
                                {msg.content}
                              </p>

                              {/* Source Citations */}
                              {msg.sources && msg.sources.length > 0 && (
                                <div className="mt-2.5 pt-2 border-t border-slate-100">
                                  <div className="flex items-center gap-1 text-[11px] font-semibold text-slate-600 mb-1.5">
                                    <BookOpen className="h-3 w-3 text-[#0453cd]" />
                                    <span>Grounded Sources ({msg.sources.length})</span>
                                  </div>
                                  <div className="flex flex-wrap gap-1.5">
                                    {msg.sources.map((src, sIdx) => {
                                      const title =
                                        typeof src === 'string'
                                          ? src
                                          : (src as { title?: string; path?: string }).title ||
                                            (src as { title?: string; path?: string }).path ||
                                            'Document';
                                      const section =
                                        typeof src === 'object' && (src as any).section
                                          ? ` § ${(src as any).section}`
                                          : '';
                                      return (
                                        <span
                                          key={sIdx}
                                          className="inline-flex items-center gap-1 text-[10px] font-mono px-2 py-0.5 rounded-md bg-blue-50 text-blue-800 border border-blue-200"
                                        >
                                          <FileText className="h-2.5 w-2.5 text-blue-600 shrink-0" />
                                          <span className="truncate max-w-[220px]">
                                            {title}
                                            {section}
                                          </span>
                                        </span>
                                      );
                                    })}
                                  </div>
                                </div>
                              )}

                              {/* Associated User Feedback */}
                              {msg.feedbackRating !== undefined && msg.feedbackRating !== null && (
                                <div className="mt-2 pt-2 border-t border-slate-100">
                                  {msg.feedbackRating === 1 ? (
                                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-emerald-50 text-emerald-800 border border-emerald-200 text-[10px] font-bold">
                                      <ThumbsUp className="h-3 w-3 text-emerald-600" />
                                      Helpful (+1)
                                    </span>
                                  ) : (
                                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-md bg-amber-50 text-amber-800 border border-amber-200 text-[10px] font-bold">
                                      <ThumbsDown className="h-3 w-3 text-amber-600" />
                                      Unhelpful (-1)
                                    </span>
                                  )}
                                  {msg.feedbackText && (
                                    <div className="mt-1 text-[11px] text-slate-600 italic bg-slate-50 p-2 rounded-lg border border-slate-100">
                                      "{msg.feedbackText}"
                                    </div>
                                  )}
                                </div>
                              )}

                              {/* Timestamp Footer */}
                              <div className="flex items-center justify-end text-[10px] font-mono text-slate-400 pt-1">
                                <span>{formatTime(new Date(msg.createdAt))}</span>
                              </div>
                            </div>
                          </div>
                        ) : (
                          /* USER MESSAGE (Right-Aligned Bubble) */
                          <div className="flex justify-end items-end gap-2 group">
                            <div className="max-w-[84%] sm:max-w-[74%] rounded-2xl rounded-tr-xs bg-[#0453cd] text-white p-3.5 sm:p-4 shadow-xs space-y-1">
                              <div className="flex items-center justify-between gap-3 text-[10px] font-medium text-blue-200 mb-0.5">
                                <span className="font-bold uppercase tracking-wider">
                                  {selectedSession?.userEmail || 'User'}
                                </span>
                              </div>
                              <p className="text-xs sm:text-sm leading-relaxed whitespace-pre-wrap break-words font-normal text-white">
                                {msg.content}
                              </p>
                              <div className="flex items-center justify-end gap-1 text-[10px] text-blue-100 font-mono pt-0.5">
                                <span>{formatTime(new Date(msg.createdAt))}</span>
                                <Check className="h-3 w-3 inline text-blue-200" />
                              </div>
                            </div>

                            <div className="h-7 w-7 rounded-full bg-blue-100 text-blue-800 flex items-center justify-center font-bold text-xs shrink-0 mb-1">
                              {(selectedSession?.userEmail || 'U').charAt(0).toUpperCase()}
                            </div>
                          </div>
                        )}
                      </React.Fragment>
                    );
                  });
                })()
              ) : (
                /* Empty Conversation State */
                <div className="py-16 text-center space-y-2">
                  <div className="h-12 w-12 rounded-full bg-slate-200/80 flex items-center justify-center mx-auto text-slate-400">
                    <MessageSquare className="h-6 w-6" />
                  </div>
                  <p className="font-semibold text-slate-700 text-sm">No messages in this conversation session</p>
                  <p className="text-xs text-slate-400 max-w-sm mx-auto">
                    This session was initialized without any user or bot message turns.
                  </p>
                </div>
              )}
              <div ref={messagesEndRef} />
            </div>

            {/* Technical Identifiers & Metadata Collapsible */}
            {selectedSession && (
              <div className="pt-3 mt-2 border-t border-slate-100 shrink-0">
                <button
                  type="button"
                  onClick={() => setShowTechnicalDetails(!showTechnicalDetails)}
                  className="flex items-center gap-1.5 text-[11px] font-mono text-slate-400 hover:text-slate-600 cursor-pointer"
                >
                  {showTechnicalDetails ? <ChevronUp className="h-3.5 w-3.5" /> : <ChevronDown className="h-3.5 w-3.5" />}
                  <span>Technical Identifiers (Session ID, User UID)</span>
                </button>
                {showTechnicalDetails && (
                  <div className="mt-2 p-3 rounded-xl bg-slate-100 font-mono text-[11px] text-slate-700 space-y-1.5 border border-slate-200">
                    <div className="flex items-center justify-between">
                      <span>Session ID: <strong className="text-slate-900">{selectedSession.id}</strong></span>
                      <button
                        type="button"
                        onClick={() => handleCopyText(`session-${selectedSession.id}`, selectedSession.id)}
                        className="text-xs text-blue-600 hover:text-blue-800 flex items-center gap-1"
                      >
                        {copiedQueryId === `session-${selectedSession.id}` ? <Check className="h-3 w-3" /> : <Copy className="h-3 w-3" />}
                        {copiedQueryId === `session-${selectedSession.id}` ? 'Copied' : 'Copy'}
                      </button>
                    </div>
                    <div className="flex items-center justify-between">
                      <span>User UID: <strong className="text-slate-900">{selectedSession.userId}</strong></span>
                      <button
                        type="button"
                        onClick={() => handleCopyText(`uid-${selectedSession.userId}`, selectedSession.userId)}
                        className="text-xs text-blue-600 hover:text-blue-800 flex items-center gap-1"
                      >
                        {copiedQueryId === `uid-${selectedSession.userId}` ? <Check className="h-3 w-3" /> : <Copy className="h-3 w-3" />}
                        {copiedQueryId === `uid-${selectedSession.userId}` ? 'Copied' : 'Copy'}
                      </button>
                    </div>
                    <div>Created: {new Date(selectedSession.createdAt).toISOString()}</div>
                    <div>Last Active: {new Date(selectedSession.updatedAt || selectedSession.createdAt).toISOString()}</div>
                  </div>
                )}
              </div>
            )}
          </div>
        </Modal>

        {/* ==================================================================== */}
        {/* MODAL 6: QUESTION GROUP DEEP-DIVE AUDIT */}
        {/* ==================================================================== */}
        <Modal
          isOpen={Boolean(selectedFaqGroup)}
          onClose={() => setSelectedFaqGroup(null)}
          title={selectedFaqGroup ? `Topic Audit: ${selectedFaqGroup.topic}` : 'Question Detail Audit'}
        >
          {selectedFaqGroup && (
            <div className="p-4 space-y-5 max-h-[75vh] overflow-y-auto text-xs">
              {/* Header Badge & Category */}
              <div className="flex items-center justify-between pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2">
                  <span className="px-2 py-0.5 rounded font-mono text-xs font-bold bg-blue-50 text-blue-700 border border-blue-200">
                    {selectedFaqGroup.category}
                  </span>
                  {selectedFaqGroup.isFlaggedGap && (
                    <span className="px-2 py-0.5 rounded font-mono text-xs font-bold bg-amber-50 text-amber-700 border border-amber-200">
                      FLAGGED KNOWLEDGE GAP
                    </span>
                  )}
                </div>
                <span className="text-[11px] font-mono text-slate-400">
                  Rank #{selectedFaqGroup.rank}
                </span>
              </div>

              {/* Metric Grid */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-[10px] text-slate-500 font-mono block">Times Asked</span>
                  <span className="text-lg font-bold font-mono text-slate-900">{selectedFaqGroup.timesAsked}</span>
                </div>
                <div className="p-2.5 rounded-xl bg-slate-50 border border-slate-200">
                  <span className="text-[10px] text-slate-500 font-mono block">Unique Users</span>
                  <span className="text-lg font-bold font-mono text-slate-900">{selectedFaqGroup.uniqueUsersCount}</span>
                </div>
                <div className="p-2.5 rounded-xl bg-emerald-50 border border-emerald-200">
                  <span className="text-[10px] text-emerald-700 font-mono block">Positive (+1)</span>
                  <span className="text-lg font-bold font-mono text-emerald-800">{selectedFaqGroup.positiveFeedbackCount}</span>
                </div>
                <div className="p-2.5 rounded-xl bg-red-50 border border-red-200">
                  <span className="text-[10px] text-red-700 font-mono block">Negative (-1)</span>
                  <span className="text-lg font-bold font-mono text-red-800">{selectedFaqGroup.negativeFeedbackCount}</span>
                </div>
              </div>

              {/* Portal Distribution */}
              <div className="p-3 rounded-xl bg-white border border-slate-200 space-y-1.5">
                <span className="font-bold text-slate-800 block text-[11px]">Portal Distribution</span>
                <div className="flex items-center gap-3 text-xs font-mono">
                  <span className="px-2 py-1 rounded bg-blue-50 text-blue-800">
                    Engineer: <strong>{selectedFaqGroup.portals.engineer}</strong>
                  </span>
                  <span className="px-2 py-1 rounded bg-emerald-50 text-emerald-800">
                    Draughtsman: <strong>{selectedFaqGroup.portals.draughtsman}</strong>
                  </span>
                  <span className="px-2 py-1 rounded bg-purple-50 text-purple-800">
                    Student: <strong>{selectedFaqGroup.portals.student}</strong>
                  </span>
                </div>
              </div>

              {/* Original User Variations */}
              <div className="space-y-2">
                <span className="font-bold text-slate-800 block text-[11px]">
                  Original Question Variations ({selectedFaqGroup.originalVariations.length})
                </span>
                <div className="divide-y divide-slate-100 border border-slate-200 rounded-xl overflow-hidden bg-slate-50/50">
                  {selectedFaqGroup.originalVariations.map((v, vIdx) => (
                    <div key={vIdx} className="p-2.5 flex items-center justify-between gap-3 text-xs">
                      <span className="text-slate-800">&ldquo;{v.text}&rdquo;</span>
                      <span className="px-2 py-0.5 rounded-full bg-white border border-slate-200 text-slate-600 font-mono text-[10px] font-bold">
                        {v.count}x
                      </span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Sample Bot Synthesized Answers */}
              {selectedFaqGroup.botAnswers.length > 0 && (
                <div className="space-y-2">
                  <span className="font-bold text-slate-800 block text-[11px]">
                    Sample Bot Answers Provided
                  </span>
                  <div className="space-y-2">
                    {selectedFaqGroup.botAnswers.map((ans, aIdx) => (
                      <div key={aIdx} className="p-2.5 rounded-xl bg-blue-50/60 border border-blue-200/60 text-xs text-slate-800">
                        <p className="line-clamp-3">&ldquo;{ans}&rdquo;</p>
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* User Feedback Comments */}
              {selectedFaqGroup.feedbackComments.length > 0 && (
                <div className="space-y-2">
                  <span className="font-bold text-slate-800 block text-[11px]">
                    User Feedback Remarks ({selectedFaqGroup.feedbackComments.length})
                  </span>
                  <div className="space-y-1.5">
                    {selectedFaqGroup.feedbackComments.map((com, cIdx) => (
                      <div key={cIdx} className="p-2 rounded-lg bg-amber-50 border border-amber-200 text-[11px] text-amber-900">
                        &ldquo;{com}&rdquo;
                      </div>
                    ))}
                  </div>
                </div>
              )}

              {/* Audit Timeline */}
              <div className="pt-2 border-t border-slate-100 flex items-center justify-between text-[11px] text-slate-400 font-mono">
                <span>First Asked: {new Date(selectedFaqGroup.firstAsked).toLocaleDateString()}</span>
                <span>Last Asked: {new Date(selectedFaqGroup.lastAsked).toLocaleDateString()}</span>
              </div>
            </div>
          )}
        </Modal>
      </div>
    </AdminShell>
  );
}

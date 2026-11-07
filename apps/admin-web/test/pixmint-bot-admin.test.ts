import fs from 'node:fs';
import path from 'node:path';
import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('PIXMINT BOT 2.0 — Simplified 5-Section Admin Control Center Contracts', () => {
  const getSafePath = (relPath: string) => {
    const direct = path.resolve(process.cwd(), relPath);
    if (fs.existsSync(direct)) return direct;
    return path.resolve(process.cwd(), 'apps/admin-web', relPath);
  };

  const sidebarPath = getSafePath('src/components/layout/Sidebar.tsx');
  const botPagePath = getSafePath('src/app/bot/page.tsx');
  const apiPath = getSafePath('src/lib/api.ts');
  const typesPath = getSafePath('src/lib/types.ts');
  const adminShellPath = getSafePath('src/components/layout/AdminShell.tsx');

  // ==========================================================================
  // 1. SIDEBAR NAVIGATION CONTRACTS
  // ==========================================================================
  describe('1. Sidebar Navigation & Menu Integration', () => {
    it('Sidebar.tsx imports Bot icon from lucide-react', () => {
      const content = fs.readFileSync(sidebarPath, 'utf-8');
      assert.ok(
        /import\s*\{[^}]*\bBot\b[^}]*\}\s*from\s*['"]lucide-react['"]/.test(content),
        'Sidebar must import Bot from lucide-react'
      );
    });

    it('Sidebar.tsx contains dedicated AI Assistant section with PIXMINT Bot 2.0 menu item', () => {
      const content = fs.readFileSync(sidebarPath, 'utf-8');
      assert.ok(content.includes("title: 'AI Assistant'"), 'Must have "AI Assistant" section title');
      assert.ok(content.includes("name: 'PIXMINT Bot 2.0'"), 'Must have "PIXMINT Bot 2.0" item name');
      assert.ok(content.includes("href: '/bot'"), 'Must link to "/bot" route');
      assert.ok(content.includes('icon: Bot'), 'Must use Bot icon');
    });

    it('Keeps Help Desk and Support category completely isolated from AI Assistant', () => {
      const content = fs.readFileSync(sidebarPath, 'utf-8');
      const supportIdx = content.indexOf("title: 'Support'");
      const botIdx = content.indexOf("title: 'AI Assistant'");
      const helpdeskIdx = content.indexOf("name: 'Help Desk'");

      assert.ok(supportIdx !== -1, 'Support category must exist');
      assert.ok(botIdx !== -1, 'AI Assistant category must exist');
      assert.ok(helpdeskIdx !== -1, 'Help Desk item must exist');
      assert.ok(botIdx > supportIdx, 'AI Assistant section must appear distinct from Support');
    });
  });

  // ==========================================================================
  // 2. API CLIENT METHODS & TYPE CONTRACTS
  // ==========================================================================
  describe('2. API Client Bot Methods & Type Contracts', () => {
    it('types.ts exports all required PIXMINT BOT interfaces', () => {
      const content = fs.readFileSync(typesPath, 'utf-8');
      const requiredTypes = [
        'AdminHealthData',
        'AdminAnalyticsData',
        'BotConfigData',
        'KnowledgeSourceItem',
        'RemoteSuggestion',
        'AuditLogItem',
        'FeedbackItem',
        'UnansweredItem',
        'ConversationSessionItem',
        'ConversationMessageItem',
        'QuestionAnalyticsData',
        'QuestionAnalyticsSummary',
        'FrequentlyAskedQuestionItem',
        'KnowledgeGapItem',
        'QuestionAnalyticsFilter',
      ];

      for (const t of requiredTypes) {
        assert.ok(
          content.includes(`export interface ${t}`) || content.includes(`export type ${t}`),
          `types.ts must export interface/type ${t}`
        );
      }
    });

    it('api.ts defines all essential PIXMINT BOT administration methods including Question Analytics', () => {
      const content = fs.readFileSync(apiPath, 'utf-8');
      const requiredMethods = [
        'getBotHealth',
        'getBotAnalytics',
        'getBotConfig',
        'updateBotConfig',
        'getBotKnowledgeSources',
        'updateBotKnowledgeSourceStatus',
        'uploadBotKnowledgeDocument',
        'deleteBotKnowledgeDocument',
        'getBotSuggestions',
        'createBotSuggestion',
        'updateBotSuggestion',
        'deleteBotSuggestion',
        'getBotConversations',
        'getBotConversationMessages',
        'getBotFeedback',
        'getBotUnanswered',
        'getBotAuditLogs',
        'getBotQuestionAnalytics',
      ];

      for (const m of requiredMethods) {
        assert.ok(content.includes(`async ${m}(`), `adminApi must define method ${m}`);
      }
    });

    it('api.ts routes point to /api/pixmint/ endpoints', () => {
      const content = fs.readFileSync(apiPath, 'utf-8');
      assert.ok(content.includes('/api/pixmint/admin/health'), 'Must call /api/pixmint/admin/health');
      assert.ok(content.includes('/api/pixmint/admin/analytics'), 'Must call /api/pixmint/admin/analytics');
      assert.ok(content.includes('/api/pixmint/admin/config'), 'Must call /api/pixmint/admin/config');
      assert.ok(content.includes('/api/pixmint/admin/knowledge/sources'), 'Must call knowledge sources endpoint');
      assert.ok(content.includes('/api/pixmint/admin/knowledge/documents'), 'Must call knowledge documents endpoint');
      assert.ok(content.includes('/api/pixmint/admin/suggestions'), 'Must call suggestions endpoint');
      assert.ok(content.includes('/api/pixmint/admin/audit-logs'), 'Must call audit-logs endpoint');
      assert.ok(content.includes('/api/pixmint/admin/conversations'), 'Must call conversations endpoint');
      assert.ok(content.includes('/api/pixmint/admin/feedback'), 'Must call feedback endpoint');
      assert.ok(content.includes('/api/pixmint/admin/unanswered'), 'Must call unanswered endpoint');
      assert.ok(content.includes('/api/pixmint/admin/question-analytics'), 'Must call question-analytics endpoint');
    });
  });

  // ==========================================================================
  // 3. EXACTLY FIVE CONSOLIDATED NAVIGATION SECTIONS
  // ==========================================================================
  describe('3. Consolidated 5-Tab Architecture Contracts', () => {
    it('bot/page.tsx renders exactly five main navigation tabs', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      const expectedTabs = ['dashboard', 'settings', 'knowledge', 'conversations', 'insights'];

      assert.ok(
        content.includes("type TabKey = 'dashboard' | 'settings' | 'knowledge' | 'conversations' | 'insights';"),
        'TabKey union must contain exactly the 5 consolidated sections'
      );

      for (const tab of expectedTabs) {
        assert.ok(content.includes(`key: '${tab}'`), `TAB_CONFIG must contain key '${tab}'`);
        assert.ok(content.includes(`activeTab === '${tab}'`), `Must render section for activeTab === '${tab}'`);
      }

      assert.strictEqual(content.includes("key: 'overview'"), false, 'Overview tab must not exist in TAB_CONFIG');
      assert.strictEqual(content.includes("key: 'audit'"), false, 'Separate audit tab must not exist in TAB_CONFIG');
    });

    it('Tab 1 (Dashboard) displays four primary metrics, compact status, quick actions, and recent activity', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('Conversations Today'), 'Must display Conversations Today metric');
      assert.ok(content.includes('Messages Today'), 'Must display Messages Today metric');
      assert.ok(content.includes('Avg Response Time'), 'Must display Avg Response Time metric');
      assert.ok(content.includes('User Satisfaction'), 'Must display User Satisfaction metric');

      assert.ok(content.includes('Bot Status:'), 'Must show Bot Status indicator');
      assert.ok(content.includes('Maintenance:'), 'Must show Maintenance indicator');
      assert.ok(content.includes('Engine:'), 'Must show Engine indicator');

      assert.ok(content.includes('handleQuickToggleBotStatus'), 'Must provide quick bot status toggle action');
      assert.ok(content.includes("setActiveTab('settings')"), 'Must link quick action to settings');
      assert.ok(content.includes("setActiveTab('knowledge')"), 'Must link quick action to knowledge base');
      assert.ok(content.includes("setActiveTab('conversations')"), 'Must link quick action to conversations');

      assert.ok(content.includes('Recent Administrative Activity'), 'Must render Recent Administrative Activity');
    });

    it('Tab 2 (Bot Settings) organizes into 4 clear sections: General, Portal Access, AI Engine, and Suggested Questions', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('A. General Settings'), 'Must render Section A: General Settings');
      assert.ok(content.includes('B. Portal Access'), 'Must render Section B: Portal Access');
      assert.ok(content.includes('C. AI Configuration'), 'Must render Section C: AI Configuration');
      assert.ok(content.includes('D. Suggested Questions'), 'Must render Section D: Suggested Questions');

      assert.ok(content.includes('handleToggleSuggestionActive'), 'Must support toggling active state of suggestion');
      assert.ok(content.includes('handleSaveSuggestion'), 'Must support adding/updating suggested question');
      assert.ok(content.includes('handleDeleteSuggestion'), 'Must support deleting suggested question');
    });

    it('Tab 3 (Knowledge Base) provides document management, search, upload modal, status toggle, and delete', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('knowledgeSearch'), 'Must support document search');
      assert.ok(content.includes('knowledgeCategoryFilter'), 'Must support category filter');
      assert.ok(content.includes('handleUploadDocument'), 'Must support document upload modal submission');
      assert.ok(content.includes('handleToggleSourceStatus'), 'Must support status approval/deactivation');
      assert.ok(content.includes('handleDeleteDocument'), 'Must support document deletion with modal confirmation');
    });

    it('Tab 4 (Conversations) provides search, role filters, clean table, and inspection modal with citations', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('conversationSearch'), 'Must support conversation search');
      assert.ok(content.includes('conversationRoleFilter'), 'Must support role filtering');
      assert.ok(content.includes('handleInspectSession'), 'Must support inspecting conversation sessions');
      assert.ok(content.includes('inspectMessages'), 'Must render conversation turn messages');
      assert.ok(content.includes('showTechnicalDetails'), 'Must tuck raw IDs into optional technical identifiers');
    });

    it('Tab 5 (Feedback & Insights) integrates Question Analytics, Knowledge Gaps, User Ratings, and Audit Log', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');

      // 6 Summary metric cards
      assert.ok(content.includes('Questions Analyzed'), 'Must display Questions Analyzed KPI');
      assert.ok(content.includes('Question Groups'), 'Must display Question Groups KPI');
      assert.ok(content.includes('Most Repeated'), 'Must display Most Repeated KPI');
      assert.ok(content.includes('Unanswered'), 'Must display Unanswered KPI');
      assert.ok(content.includes('Negative Ratings'), 'Must display Negative Ratings KPI');
      assert.ok(content.includes('Topics To Review'), 'Must display Topics To Review KPI');

      // Analytics control filters
      assert.ok(content.includes('All Portals'), 'Must provide All Portals filter');
      assert.ok(content.includes('All Time'), 'Must provide All Time filter');
      assert.ok(content.includes('Search topic or variation...'), 'Must provide topic search input');

      // Ranked FAQ Table
      assert.ok(content.includes('Most Frequently Asked Questions'), 'Must render Most Frequently Asked Questions section');
      assert.ok(content.includes('setSelectedFaqGroup'), 'Must support opening question group audit modal');

      // Knowledge Gap Detection
      assert.ok(content.includes('Knowledge Gaps & Documentation Action Items'), 'Must render Knowledge Gaps section');
      assert.ok(content.includes('Upload Knowledge Document'), 'Must link knowledge gap to upload modal');

      // Audit Report Export
      assert.ok(content.includes('Generate Question Audit Report'), 'Must provide Generate Question Audit Report action');
      assert.ok(content.includes('handleExportCsvReport'), 'Must implement handleExportCsvReport');

      // Standard Feedback & Activity Stream
      assert.ok(content.includes('User Satisfaction & Feedback'), 'Must render User Feedback section');
      assert.ok(content.includes('Administrative Activity Stream'), 'Must render Administrative Activity Stream');
    });
  });

  // ==========================================================================
  // 4. STRICT ROLE ENFORCEMENT: NO CLIENT, NO GUEST
  // ==========================================================================
  describe('4. Strict Role Isolation & Governance Invariants', () => {
    it('Supported roles in PIXMINT BOT admin page are strictly engineer, draughtsman, and student', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(
        content.includes("type SupportedRole = 'engineer' | 'draughtsman' | 'student';"),
        'SupportedRole type must be limited to engineer, draughtsman, student'
      );
    });

    it('Strictly prohibits "client" or "guest" portal toggles, filters, or mock objects in bot/page.tsx', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');

      assert.strictEqual(
        content.includes("'client'"),
        false,
        "bot/page.tsx must not contain 'client' role key"
      );
      assert.strictEqual(
        content.includes("'guest'"),
        false,
        "bot/page.tsx must not contain 'guest' role key"
      );
      assert.strictEqual(
        content.includes("Client Portal"),
        false,
        "bot/page.tsx must not reference 'Client Portal'"
      );
      assert.strictEqual(
        content.includes("Guest Portal"),
        false,
        "bot/page.tsx must not reference 'Guest Portal'"
      );
    });

    it('Prohibits "client" and "guest" role suggestions in worker/src/pixmint/chat.ts default suggestions', () => {
      const chatPath = getSafePath('../../worker/src/pixmint/chat.ts');
      if (fs.existsSync(chatPath)) {
        const content = fs.readFileSync(chatPath, 'utf-8');
        assert.strictEqual(
          content.includes("client: ["),
          false,
          'DEFAULT_SUGGESTIONS_MAP must not have client suggestions'
        );
        assert.strictEqual(
          content.includes("guest: ["),
          false,
          'DEFAULT_SUGGESTIONS_MAP must not have guest suggestions'
        );
      }
    });
  });

  // ==========================================================================
  // 5. SECURITY & RBAC ISOLATION CONTRACTS
  // ==========================================================================
  describe('5. Security & Role Invariants', () => {
    it('AdminShell rejects non-admin users and redirects to /login', () => {
      const content = fs.readFileSync(adminShellPath, 'utf-8');
      assert.ok(
        content.includes("user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN'"),
        'AdminShell must enforce that only ADMIN or STUDIO_ADMIN roles are permitted'
      );
      assert.ok(
        content.includes("window.location.replace('/login')"),
        'Unauthorized users must be redirected to /login'
      );
    });

    it('API client does not leak secrets, service account credentials, or internal provider keys', () => {
      const content = fs.readFileSync(apiPath, 'utf-8');
      assert.strictEqual(content.includes('AI_PROVIDER_API_KEY'), false, 'Must not contain AI_PROVIDER_API_KEY');
      assert.strictEqual(content.includes('CLOUDFLARE_API_TOKEN'), false, 'Must not contain CLOUDFLARE_API_TOKEN');
      assert.strictEqual(content.includes('FIREBASE_PRIVATE_KEY'), false, 'Must not contain FIREBASE_PRIVATE_KEY');
    });
  });

  // ==========================================================================
  // 6. CONVERSATION INSPECTOR & CONTINUOUS CHAT EXPERIENCE CONTRACTS
  // ==========================================================================
  describe('6. Conversation Inspector & Continuous Chat Experience Contracts', () => {
    it('1. Tab 4 renders a User-Grouped table with expandable session history and chat inspection', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('userConversationGroups.map((group) =>'), 'Table must iterate through user conversation groups');
      assert.ok(content.includes('toggleUserExpanded(group.userId)'), 'Must allow toggling user history view');
      assert.ok(content.includes('group.sessions.map((conv) =>'), 'Expanded view must iterate through sessions for that user');
      assert.ok(content.includes('onClick={() => handleInspectSession(conv)}'), 'Each session row must pass session object to inspector');
      assert.ok(content.includes('{conv.title}'), 'Must display session title per session row');
      assert.ok(content.includes('{group.userEmail'), 'Must display user email per user group row');
    });

    it('2. Multiple messages appear together in one continuous chat inspector without pagination splitting', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('inspectMessages.map((msg) =>'), 'Inspector must render all session messages in one continuous thread');
      assert.ok(content.includes('messagesEndRef'), 'Must maintain a ref to scroll to latest message');
      assert.ok(content.includes('messagesEndRef.current?.scrollIntoView'), 'Must auto-scroll to the bottom of the conversation');
    });

    it('3. User and bot messages are visually distinct with WhatsApp-style bubble styling', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      // User styling (right-aligned, brand background, subtle checkmark)
      assert.ok(content.includes('justify-end'), 'User messages must be right-aligned');
      assert.ok(content.includes('bg-[#0453cd] text-white'), 'User bubble must use distinct brand contrast background');
      
      // Bot styling (left-aligned, Bot avatar, official identity, latency)
      assert.ok(content.includes('justify-start'), 'Bot messages must be left-aligned');
      assert.ok(content.includes('<Bot className="h-4 w-4" />'), 'Bot messages must display official bot avatar');
      assert.ok(content.includes('PIXMINT BOT'), 'Bot bubble must display official identity');
      assert.ok(content.includes('v2.0'), 'Bot bubble must display v2.0 identity badge');
    });

    it('4. Messages are chronologically ordered with date separators', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('getMessageDateGroup'), 'Must group message timestamps by date');
      assert.ok(content.includes('showDateDivider'), 'Must dynamically display date divider pills between different days');

      // Backend handler contract
      const adminPath = getSafePath('../../worker/src/pixmint/admin.ts');
      if (fs.existsSync(adminPath)) {
        const adminContent = fs.readFileSync(adminPath, 'utf-8');
        assert.ok(
          adminContent.includes('ORDER BY m.created_at ASC') || adminContent.includes('ORDER BY created_at ASC'),
          'Backend query must strictly order messages chronologically ascending'
        );
      }
    });

    it('5. Different sessions remain strictly isolated in state and API calls', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('setInspectMessages([])'), 'Must reset messages when switching or closing sessions');
      assert.ok(content.includes('adminApi.getBotConversationMessages(session.id)'), 'Must query messages by specific session ID');
      assert.ok(content.includes('setSelectedSession(null)'), 'Must clear selected session on modal close');
    });

    it('6. Grounded source citations and user feedback remain visible on bot responses', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('msg.sources && msg.sources.length > 0'), 'Must conditionally render source citations');
      assert.ok(content.includes('Grounded Sources'), 'Must display Grounded Sources header');
      assert.ok(content.includes('msg.feedbackRating'), 'Must render user feedback ratings (+1 / -1) on bot messages');
      assert.ok(content.includes('Helpful (+1)'), 'Must render Helpful rating badge');
      assert.ok(content.includes('Unhelpful (-1)'), 'Must render Unhelpful rating badge');
    });

    it('7. Empty, loading, and error states work correctly with actionable retry', () => {
      const content = fs.readFileSync(botPagePath, 'utf-8');
      assert.ok(content.includes('Loading continuous conversation history...'), 'Must render informative loading state');
      assert.ok(content.includes('No messages in this conversation session'), 'Must render friendly empty conversation state');
      assert.ok(content.includes('inspectError'), 'Must handle inspect error state');
      assert.ok(content.includes('Retry'), 'Must provide Retry button on error');
    });
  });

  // ==========================================================================
  // 7. CONVERSATION SESSION LIFECYCLE & DEDUPLICATION CONTRACTS
  // ==========================================================================
  describe('7. Conversation Session Lifecycle & Deduplication Contracts', () => {
    it('UserConversationGroup interface includes required fields in types.ts', () => {
      const content = fs.readFileSync(typesPath, 'utf-8');
      assert.ok(content.includes('export interface UserConversationGroup'), 'Must export UserConversationGroup');
      assert.ok(content.includes('totalSessions: number;'), 'Must have totalSessions');
      assert.ok(content.includes('totalMessages: number;'), 'Must have totalMessages');
      assert.ok(content.includes('sessions: ConversationSessionItem[];'), 'Must have sessions array');
    });

    it('ConversationSessionItem supports messageCount in types.ts', () => {
      const content = fs.readFileSync(typesPath, 'utf-8');
      assert.ok(content.includes('messageCount?: number;'), 'ConversationSessionItem must support messageCount');
    });

    it('Worker backend chat.ts generates descriptive titles from first user message and reuses active session', () => {
      const chatPath = getSafePath('../../worker/src/pixmint/chat.ts');
      if (fs.existsSync(chatPath)) {
        const content = fs.readFileSync(chatPath, 'utf-8');
        assert.ok(content.includes('generateConversationTitle'), 'chat.ts must implement generateConversationTitle');
        assert.ok(content.includes('is_archived = 0'), 'chat.ts must query active unarchived session');
        assert.ok(content.includes('UPDATE chat_sessions SET title = ?'), 'chat.ts must update title on first message');
      }
    });

    it('Worker backend admin.ts includes self-healing title backfill and message count in conversation queries', () => {
      const adminPath = getSafePath('../../worker/src/pixmint/admin.ts');
      if (fs.existsSync(adminPath)) {
        const content = fs.readFileSync(adminPath, 'utf-8');
        assert.ok(content.includes('message_count'), 'admin.ts must query message_count per session');
        assert.ok(content.includes("title = 'New Conversation'"), 'admin.ts must check for legacy New Conversation titles to heal');
      }
    });
  });

  // ==========================================================================
  // 8. ADMIN PANEL FLOATING PIXMINT CHATBOT WIDGET CONTRACTS
  // ==========================================================================
  describe('8. Admin Panel Floating PIXMINT Chatbot Widget Contracts', () => {
    const chatWidgetPath = getSafePath('src/components/bot/PixmintChatWidget.tsx');
    const providersPath = getSafePath('src/components/providers.tsx');

    it('PixmintChatWidget.tsx exists and implements interactive floating chatbot', () => {
      assert.ok(fs.existsSync(chatWidgetPath), 'PixmintChatWidget.tsx must exist');
      const content = fs.readFileSync(chatWidgetPath, 'utf-8');
      assert.ok(content.includes('export function PixmintChatWidget'), 'Must export PixmintChatWidget');
      assert.ok(content.includes('PIXMINT Bot'), 'Must display PIXMINT Bot brand name');
      assert.ok(content.includes('handleSendMessage'), 'Must implement message sending');
      assert.ok(content.includes('handleResetChat'), 'Must implement chat reset');
      assert.ok(content.includes('handleFeedback'), 'Must implement helpful/unhelpful feedback');
    });

    it('PixmintChatWidget.tsx enforces high-contrast composer with white background and charcoal text', () => {
      const content = fs.readFileSync(chatWidgetPath, 'utf-8');
      assert.ok(content.includes('bg-white'), 'Chat input container must use white background');
      assert.ok(content.includes('text-[#17212B]'), 'Input text must use dark charcoal #17212B');
      assert.ok(content.includes('caret-emerald-600'), 'Caret must use emerald green');
    });

    it('providers.tsx mounts PixmintChatWidget globally across all admin pages', () => {
      const content = fs.readFileSync(providersPath, 'utf-8');
      assert.ok(content.includes('<PixmintChatWidget />'), 'providers.tsx must render PixmintChatWidget');
    });

    it('api.ts defines all 6 interactive chat client methods and provides content field', () => {
      const content = fs.readFileSync(apiPath, 'utf-8');
      assert.ok(content.includes('getBotChatStatus'), 'Must define getBotChatStatus');
      assert.ok(content.includes('getOrCreateBotChatSession'), 'Must define getOrCreateBotChatSession');
      assert.ok(content.includes('getBotChatSuggestions'), 'Must define getBotChatSuggestions');
      assert.ok(content.includes('getBotChatSessionMessages'), 'Must define getBotChatSessionMessages');
      assert.ok(content.includes('sendBotChatMessage'), 'Must define sendBotChatMessage');
      assert.ok(content.includes('submitBotChatFeedback'), 'Must define submitBotChatFeedback');
      assert.ok(content.includes('content: message'), 'sendBotChatMessage must pass content field in body');
    });

    it('PixmintChatWidget and SupportWidget are strictly hidden before login and on /login', () => {
      const chatWidgetContent = fs.readFileSync(chatWidgetPath, 'utf-8');
      const supportWidgetPath = getSafePath('src/components/helpdesk/SupportWidget.tsx');
      const supportWidgetContent = fs.readFileSync(supportWidgetPath, 'utf-8');

      // Both must require authenticated user
      assert.ok(chatWidgetContent.includes('loading || !user'), 'PixmintChatWidget must return null if not authenticated');
      assert.ok(chatWidgetContent.includes("pathname === '/login'"), 'PixmintChatWidget must return null on /login');

      assert.ok(supportWidgetContent.includes('loading || !user'), 'SupportWidget must return null if not authenticated');
      assert.ok(supportWidgetContent.includes("pathname === '/login'"), 'SupportWidget must return null on /login');
    });
  });
});

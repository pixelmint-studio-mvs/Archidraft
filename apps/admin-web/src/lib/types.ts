/**
 * Shared TypeScript types for the Admin Panel.
 * Maps directly to the D1 database schema and Worker API responses.
 *
 * Ref: docs/02_architecture/DATA_ARCHITECTURE.md
 * Ref: worker/migrations/0001-0005
 */

// ── User ──

export type UserRole = 'CLIENT' | 'DRAUGHTSMAN' | 'ADMIN' | 'STUDENT' | 'STUDIO_ADMIN' | 'ENGINEER';
export type UserStatus = 'ACTIVE' | 'SUSPENDED';

/**
 * Helper to get the canonical user-facing role name.
 * 'CLIENT' and 'ENGINEER' are canonical identifiers for Engineers.
 */
export function getDisplayRole(role?: string): string {
  if (!role) return 'Unknown';
  switch (role) {
    case 'CLIENT':
    case 'ENGINEER':
      return 'Engineer/Architect';
    case 'DRAUGHTSMAN':
      return 'Draughtsman';
    case 'STUDENT':

      return 'Student';
    case 'ADMIN':
    case 'STUDIO_ADMIN':
      return 'Admin';
    default:
      return role;
  }
}

export interface User {
  id: string;
  identification_number?: string;
  email: string;
  name: string;
  role: UserRole;
  status?: UserStatus;
  mobile?: string;
  qualification?: string;
  date_of_birth?: string;
  address?: string;
  company_name?: string;
  college_name?: string;
  updated_at?: string;
  created_at: string;
}

// ── Project ──

export type ProjectStatus =
  | 'DRAFT'
  | 'SUBMITTED'
  | 'WAITING_ASSIGNMENT'
  | 'WAITING_ACCEPTANCE'
  | 'IN_PROGRESS'
  | 'UNDER_ADMIN_REVIEW'
  | 'UNDER_CLIENT_REVIEW'
  | 'UNDER_ENGINEER_REVIEW'
  | 'COMPLETED'
  | 'CANCELLED';

export interface Project {
  id: string;
  client_id: string;
  client_name?: string;
  client_email?: string;
  project_name: string;
  project_address: string;
  drawing_name: string;
  drawing_type: string;
  project_area: string;
  status: ProjectStatus;
  is_training_project?: number;
  training_module_id?: string;
  last_action_id?: string;
  client_identification_number?: string;
  draughtsman_id?: string;
  draughtsman_name?: string;
  draughtsman_identification_number?: string;
  rejection_reason?: string;
  current_assignment_id?: string;
  correction_round: number;
  created_at: string;
  submitted_at?: string;
  approved_at?: string;
  assigned_at?: string;
  rejected_at?: string;
  cancelled_at?: string;
}

// ── Assignment ──

export type AssignmentStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'REPLACED' | 'CANCELLED';

export interface Assignment {
  id: string;
  project_id: string;
  draughtsman_id: string;
  draughtsman_identification_number?: string;
  status: AssignmentStatus;
  created_at: string;
  updated_at: string;
  draughtsman_name?: string;
  draughtsman_email?: string;
}

export interface GlobalAssignment extends Assignment {
  project_name?: string;
  project_status?: ProjectStatus;
  drawing_type?: string;
  project_area?: string;
  client_id?: string;
  client_name?: string;
  client_identification_number?: string;
}

// ── Engineer Project Status Item (Isolated status overview) ──

export interface EngineerProjectStatusItem {
  project_id: string;
  project_name: string;
  drawing_name?: string;
  drawing_type: string;
  project_area?: string | number;
  project_address?: string;
  project_status: ProjectStatus;
  engineer_id: string;
  engineer_identification_number?: string;
  engineer_name: string;
  engineer_email: string;
  engineer_company?: string;
  engineer_mobile?: string;
  current_assignment_id?: string;
  assigned_at?: string;
  submitted_at?: string;
  approved_at?: string;
  rejected_at?: string;
  cancelled_at?: string;
  created_at: string;
  correction_round?: number;
  draughtsman_id?: string;
  draughtsman_name?: string;
  last_updated_at?: string;
  drawing_versions_count?: number;
  corrections_count?: number;
}

// ── File ──

export interface ProjectFile {
  id: string;
  project_id: string;
  uploaded_by: string;
  original_name: string;
  sanitized_name: string;
  object_key: string;
  content_type: string;
  size: number;
  category: string;
  status: string;
  created_at: string;
}

// ── Drawing Version ──

export interface DrawingVersion {
  id: string;
  project_id: string;
  file_id: string;
  version_number: number;
  uploaded_by: string;
  correction_id?: string;
  approval_status?: 'PENDING' | 'APPROVED' | 'REJECTED' | string;
  approval_source?: string;
  reviewed_by?: string;
  reviewed_at?: string;
  review_feedback?: string;
  created_at: string;
  // Joined fields from files table
  original_name?: string;
  sanitized_name?: string;
  object_key?: string;
  content_type?: string;
  size?: number;
}

// ── Drawing Version Review Audit Record ──

export interface AdminNotification {
  id: string;
  user_id: string;
  project_id?: string | null;
  project_name?: string | null;
  type: string;
  title: string;
  message: string;
  is_read: number | boolean;
  created_at: string;
}

export interface DrawingVersionReview {
  id: string;
  project_id: string;
  drawing_version_id: string;
  reviewer_id: string;
  decision: 'APPROVED' | 'REJECTED';
  feedback?: string | null;
  created_at: string;
  reviewer_name?: string;
  reviewer_role?: string;
  version_number?: number;
}

// ── Correction ──

export type CorrectionStatus = 'OPEN' | 'IN_PROGRESS' | 'RESOLVED';

export interface Correction {
  id: string;
  project_id: string;
  requested_by: string;
  target_version_id: string;
  round_number: number;
  description: string;
  status: CorrectionStatus;
  created_at: string;
  resolved_at?: string;
}

// ── Activity Log ──

export interface ActivityLog {
  id: string;
  project_id: string;
  action_type: string;
  actor_id: string;
  actor_role: string;
  details?: string;
  timestamp: string;
  project_name?: string;
}

// ── Admin Stats (GET /api/admin/stats response) ──

export interface AdminStats {
  metrics?: AdminDashboardMetrics | null;
  projects: {
    total: number;
    byStatus: Record<string, number>;
  };
  users: {
    total: number;
    byRole: Record<string, number>;
    registeredEngineers?: number;
  };
  recentActivity: ActivityLog[];
  pendingRegistrations?: number;
}

export interface AdminDashboardMetrics {
  totalProjects: number;
  activeProjects: number;
  projectsAwaitingAssignment: number;
  projectsUnderClientReview: number;
  completedProjects: number;
  activeDraughtsmen: number;
  pendingAssignments: number;
  registeredEngineers?: number;
  activeEngineers?: number;
}

// ── Project Comment / Collaboration Message ──

export interface ProjectComment {
  id: string;
  project_id: string;
  author_id: string;
  author_name: string;
  author_role: 'ADMIN' | 'STUDIO_ADMIN' | 'DRAUGHTSMAN' | 'CLIENT' | 'ENGINEER' | 'STUDENT' | string;
  content: string;
  attachment_file_id?: string | null;
  attachment_name?: string | null;
  attachment_size?: string | null;
  attachment_type?: string | null;
  created_at: string;
}

// ── Studio Governance Settings (D1 Backed) ──

export interface StudioSettings {
  multiDiscipline: boolean;
  turnaround: string;
  autoRasterizer: boolean;
  strictLayerCompliance: boolean;
  maxUploadCeiling: string;
  notifySubmissions: boolean;
  notifyAssignments: boolean;
  notifyCorrections: boolean;
  notifyDigest: boolean;
  updated_at?: string;
  updated_by?: string;
}

// ── Student Submissions Queue & Evaluation Types ──

export interface StudentSubmission {
  id: string; // project_id
  project_name: string;
  drawing_name: string;
  drawing_type: string;
  status: ProjectStatus | string;
  correction_round: number;
  created_at: string;
  submitted_at: string | null;
  training_module_id: string | null;
  rejection_reason: string | null;
  student_id: string;
  student_identification_number?: string | null;
  student_name: string | null;
  student_email: string | null;
  module_title: string | null;
  latest_drawing_version_id: string | null;
  latest_version_number: number | null;
  latest_file_id: string | null;
}

export type EvaluationDecision = 'APPROVED' | 'NEEDS_CORRECTION' | 'REJECTED';

export interface EvaluationCriteria {
  Accuracy: number; // 1 - 5
  'Technical Standards': number; // 1 - 5
}

export interface EvaluateSubmissionPayload {
  projectId: string;
  drawingVersionId: string;
  overallResult: EvaluationDecision;
  generalFeedback: string;
  criteriaJson: string; // JSON.stringify(EvaluationCriteria)
  actionId?: string;
  correctionId?: string;
}

// ── Teaching Students: Training Curriculum, Plans & Progress Types ──

export type ModulePublicationStatus = 'DRAFT' | 'PUBLISHED' | 'ARCHIVED';

export interface LessonResource {
  id: string;
  name: string;
  url: string;
  type?: string;
  size?: number;
  previewable?: boolean;
}

export interface TrainingLesson {
  id: string;
  module_id: string;
  chapter_id?: string | null;
  title: string;
  content: string;
  video_url?: string | null;
  resources?: LessonResource[] | string;
  resources_json?: string | null;
  is_required: number | boolean;
  lesson_order?: number;
  order_index?: number;
  estimated_duration?: string;
  created_at: string;
  updated_at?: string;
}

export interface TrainingChapter {
  id: string;
  module_id: string;
  title: string;
  description?: string | null;
  chapter_order: number;
  created_at: string;
}

export interface TrainingModule {
  id: string;
  title: string;
  category: string;
  type?: string;
  level?: string;
  description: string;
  prerequisites?: string;
  learning_objectives?: string | null;
  thumbnail_url?: string | null;
  publication_status: ModulePublicationStatus;
  is_locked?: number;
  created_at: string;
  updated_at?: string;
  chapters_count?: number;
  lessons_count?: number;
  enrolled_students_count?: number;
  chapters?: TrainingChapter[];
  lessons?: TrainingLesson[];
}

export interface StudentLearningPlan {
  id: string;
  student_id: string;
  student_name?: string;
  student_email?: string;
  module_id: string;
  module_title?: string;
  module_category?: string;
  module_level?: string;
  assigned_by?: string;
  assigned_at: string;
  target_completion_date?: string | null;
  instructions?: string | null;
  selected_chapters?: string | null;
  selected_lessons?: string | null;
  status: 'ASSIGNED' | 'IN_PROGRESS' | 'COMPLETED' | 'REVOKED';
  completed_lessons_count?: number;
  total_required_lessons_count?: number;
  progress_percentage?: number;
}

export interface StudentProgressSummary {
  student_id: string;
  identification_number?: string;
  student_name: string;
  student_email: string;
  student_status: string;
  college_name?: string;
  qualification?: string;
  assigned_plans_count: number;
  assigned_modules_count?: number;
  completed_plans_count: number;
  in_progress_plans_count: number;
  not_started_plans_count: number;
  total_required_lessons: number;
  completed_required_lessons: number;
  overall_completion_percentage: number;
  training_status?: string;
  practical_projects_count: number;
  practical_approved_count: number;
  practical_pending_count?: number;
  has_overdue: boolean;
  overdue_count?: number;
  earliest_assignment_date?: string | null;
  earliest_target_date?: string | null;
  latest_completion_date?: string | null;
  plans: Array<{
    id: string;
    module_id: string;
    module_title: string;
    module_category: string;
    plan_status: string;
    target_completion_date: string | null;
    module_status: string | null;
    module_score: number | null;
  }>;
  // Legacy aliases
  name?: string;
  email?: string;
  account_status?: string;
  total_assigned_modules?: number;
  completed_modules?: number;
  in_progress_modules?: number;
  not_started_modules?: number;
  practical_projects?: {
    total: number;
    completed: number;
    pending_review: number;
  };
}

export interface StudentProgressDetail {
  student: User;
  plans: any[];
  summary?: {
    total_modules: number;
    total_required_lessons: number;
    completed_required_lessons: number;
    overall_completion_percentage: number;
  };
  modules: Array<{
    module: TrainingModule;
    plan: any;
    chapters: Array<{
      chapter: TrainingChapter;
      lessons: Array<{
        id: string;
        title: string;
        is_required: boolean;
        is_completed: boolean;
        completed_at: string | null;
        resources?: LessonResource[];
        video_url?: string | null;
      }>;
    }>;
    standaloneLessons: Array<{
      id: string;
      title: string;
      is_required: boolean;
      is_completed: boolean;
      completed_at: string | null;
      resources?: LessonResource[];
      video_url?: string | null;
    }>;
    lessons?: any[];
    progress: {
      total_required_lessons: number;
      completed_required_lessons: number;
      total_lessons: number;
      completed_lessons: number;
      completion_percentage: number;
      status: string;
    };
  }>;
  practicalProjects: Array<{
    id: string;
    project_name: string;
    drawing_name: string;
    drawing_type: string;
    status: string;
    correction_round: number;
    created_at: string;
    submitted_at: string | null;
    evaluation?: {
      overall_result: string;
      score: number | null;
      general_feedback: string | null;
      evaluated_at: string | null;
    } | null;
  }>;
  completionHistory?: Array<{
    id: string;
    type: 'LESSON_COMPLETED' | 'MODULE_COMPLETED' | 'PROJECT_SUBMITTED' | 'PROJECT_EVALUATED';
    title: string;
    subtitle: string;
    timestamp: string;
    status?: string;
    badge?: string;
  }>;
  overallSummary: {
    total_assigned_modules: number;
    completed_modules: number;
    in_progress_modules: number;
    not_started_modules: number;
    total_required_lessons: number;
    completed_required_lessons: number;
    overall_completion_percentage: number;
    has_overdue: boolean;
  };
}

// ============================================================================
// HELP DESK & INCIDENT MANAGEMENT SYSTEM TYPES
// ============================================================================

export type HelpdeskSeverity = 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
export type HelpdeskStatus = 'OPEN' | 'INVESTIGATING' | 'IN_PROGRESS' | 'RESOLVED' | 'CLOSED';
export type HelpdeskSource = 'MAIN_APP' | 'ADMIN_PANEL' | 'BACKEND' | 'EXTERNAL_SERVICE' | 'USER_SUBMITTED';

export interface HelpdeskTicket {
  id: string;
  fingerprint?: string;
  title: string;
  category: string;
  severity: HelpdeskSeverity;
  status: HelpdeskStatus;
  source: HelpdeskSource;
  affected_module: string;
  error_message: string;
  error_code?: string | null;
  stack_trace?: string | null;
  environment: string;
  user_id?: string | null;
  user_email?: string | null;
  browser?: string | null;
  device?: string | null;
  page_route?: string | null;
  request_id?: string | null;
  occurrence_count: number;
  assigned_to?: string | null;
  assigned_to_name?: string | null;
  resolution_notes?: string | null;
  resolved_at?: string | null;
  resolved_by?: string | null;
  screenshot_url?: string | null;
  is_user_submitted: number;
  created_at: string;
  updated_at: string;
  last_occurred_at: string;
}

export interface HelpdeskEvent {
  id: string;
  ticket_id: string;
  event_type: string;
  actor_id?: string | null;
  actor_name?: string | null;
  actor_role?: string | null;
  details?: string | null;
  metadata?: string | null;
  created_at: string;
  ticket_title?: string;
  ticket_severity?: string;
}

export interface HelpdeskComment {
  id: string;
  ticket_id: string;
  author_id: string;
  author_name: string;
  author_role: string;
  comment: string;
  is_internal: number;
  created_at: string;
}

export interface HelpdeskEmailLog {
  id: string;
  ticket_id?: string | null;
  recipient: string;
  subject: string;
  severity: string;
  status: 'PENDING' | 'SENT' | 'FAILED' | 'SUPPRESSED_DUPLICATE';
  provider?: string | null;
  error_message?: string | null;
  response_body?: string | null;
  retry_count: number;
  sent_at?: string | null;
  created_at: string;
}

export interface HelpdeskStats {
  totalReports: number;
  openTickets: number;
  criticalIssues: number;
  highPriority: number;
  inProgress: number;
  awaitingResponse: number;
  resolvedTickets: number;
  avgResolutionTimeMinutes: number;
  categoryDistribution: Record<string, number>;
  severityDistribution: Record<string, number>;
  recentEvents: HelpdeskEvent[];
  emailDeliveryStats: Record<string, number>;
}

export interface HelpdeskHealthReport {
  status: 'OPERATIONAL' | 'DEGRADED' | 'DOWN';
  timestamp: string;
  checks: Record<string, { status: string; latencyMs: number; details?: string }>;
}

export interface HelpdeskSettings {
  notification_email: string;
  alert_critical_enabled: boolean;
  alert_high_enabled: boolean;
  alert_medium_enabled: boolean;
  alert_low_digest_enabled: boolean;
  suppression_window_minutes: number;
  incident_retention_days: number;
  monitoring_enabled: boolean;
  email_provider: string;
  resend_api_key?: string;
  sendgrid_api_key?: string;
  email_from_address?: string;
  email_configured?: boolean;
  email_provider_active?: string;
}




// ── Registration Verifications ────────────────────────────────────────────────
export type RegistrationStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export interface RegistrationVerification {
  id: string;
  user_id: string;
  identification_number?: string;
  name: string;
  email: string;
  role: 'ENGINEER' | 'CLIENT' | 'DRAUGHTSMAN' | 'STUDENT' | string;
  mobile?: string | null;
  document_type: string;
  file_id: string;
  file_name: string;
  file_size: number;
  content_type: string;
  object_key?: string | null;
  status: RegistrationStatus;
  reviewed_by?: string | null;
  reviewer_name?: string | null;
  reviewed_at?: string | null;
  rejection_reason?: string | null;
  submitted_at: string;
  created_at: string;
  updated_at?: string;
  company_name?: string | null;
  college_name?: string | null;
  qualification?: string | null;
  date_of_birth?: string | null;
  address?: string | null;
}

// ── PIXMINT BOT 2.0 Types ──────────────────────────────────────────────────

export type BotUserRole = 'engineer' | 'draughtsman' | 'student' | 'admin' | 'guest';

export interface AdminHealthData {
  status: string;
  botVersion: string;
  activeProvider: string;
  isProviderConfigured: boolean;
  modelName: string;
  d1Connected: boolean;
  workersAiAvailable: boolean;
  botEnabled?: boolean;
  maintenanceMode?: boolean;
  timestamp: number;
}

export interface AdminAnalyticsData {
  metrics: {
    totalSessionsToday: number;
    totalMessagesToday: number;
    avgLatencyMs: number;
    resolutionRatePercent: number;
    unansweredCountToday: number;
  };
  topQueries: Array<{ query: string; count: number }>;
  recentAuditLogs: Array<{ id: string; adminUserId: string; action: string; target: string; timestamp: number }>;
}

export interface RemoteSuggestion {
  id: string;
  role: string;
  label: string;
  prompt: string;
  icon: string;
  sortOrder: number;
  isActive: boolean;
}

export interface BotConfigData {
  botEnabled: boolean;
  maintenanceMode: boolean;
  maintenanceMessage: string;
  allowedMaintenanceRoles: string[];
  maxInputChars: number;
  rateLimitPerMinute: number;
  historyLimit: number;
  enabledPortals: Record<string, boolean>;
  updatedAt: number;
  updatedBy: string;
}

export interface AuditLogItem {
  id: string;
  adminUserId: string;
  action: string;
  target?: string;
  metadata?: Record<string, unknown>;
  createdAt: number;
}

export interface KnowledgeSourceItem {
  id: string;
  title: string;
  path: string;
  category: string;
  version: string;
  status: 'approved' | 'deactivated';
  chunkCount: number;
  lastAuditDate?: string;
  verificationAuthority?: string;
  updatedAt: number;
}

export interface FeedbackItem {
  id: string;
  messageId: string;
  userId: string;
  rating: number;
  feedbackText?: string;
  messageContent?: string;
  createdAt: number;
}

export interface UnansweredItem {
  id: string;
  userId: string;
  userRole: string;
  query: string;
  intentCategory?: string;
  failureReason: string;
  createdAt: number;
}

export interface ConversationSessionItem {
  id: string;
  userId: string;
  userEmail: string;
  userRole: string;
  title: string;
  isArchived: boolean;
  createdAt: number;
  updatedAt: number;
  messageCount?: number;
}

export interface UserConversationGroup {
  userId: string;
  userEmail: string;
  userRole: string;
  totalSessions: number;
  totalMessages: number;
  lastActive: number;
  sessions: ConversationSessionItem[];
}

export interface ConversationMessageItem {
  id: string;
  sessionId: string;
  userId: string;
  sender: 'user' | 'bot';
  content: string;
  sources?: Array<{ title: string; path: string; section?: string; category?: string }>;
  modelName?: string;
  latencyMs?: number;
  createdAt: number;
  feedbackRating?: number;
  feedbackText?: string;
}

export interface QuestionAnalyticsSummary {
  totalQuestionsAnalyzed: number;
  uniqueQuestionGroups: number;
  mostRepeatedTopic: string;
  unansweredQuestionCount: number;
  negativeFeedbackCount: number;
  topicsNeedingAttention: number;
  groupingMethod: string;
  auditPeriod: {
    timeRange: string;
    startDate: number;
    endDate: number;
  };
}

export interface FrequentlyAskedQuestionItem {
  rank: number;
  id: string;
  topic: string;
  category: string;
  timesAsked: number;
  portals: {
    engineer: number;
    draughtsman: number;
    student: number;
  };
  uniqueUsersCount: number;
  firstAsked: number;
  lastAsked: number;
  originalVariations: Array<{ text: string; count: number }>;
  botAnswers: string[];
  positiveFeedbackCount: number;
  negativeFeedbackCount: number;
  feedbackComments: string[];
  relatedSessionIds: string[];
  isFlaggedGap: boolean;
}

export interface KnowledgeGapItem {
  id: string;
  topic: string;
  category: string;
  affectedQuestionsCount: number;
  unansweredCount: number;
  negativeFeedbackCount: number;
  flagReason: string;
  relatedDocuments: Array<{ id: string; title: string }>;
  recommendedAction: string;
}

export interface QuestionAnalyticsData {
  summary: QuestionAnalyticsSummary;
  frequentlyAskedQuestions: FrequentlyAskedQuestionItem[];
  knowledgeGaps: KnowledgeGapItem[];
}

export interface QuestionAnalyticsFilter {
  portal: 'all' | 'engineer' | 'draughtsman' | 'student';
  timeRange: 'today' | '7d' | '30d' | 'all' | 'custom';
  startDate?: string;
  endDate?: string;
  search?: string;
}

// =============================================================================
// LEGAL & COMPLIANCE SYSTEM TYPES (PHASE 4)
// =============================================================================

export interface LegalComplianceStats {
  documents: {
    total: number;
    published: number;
    draft: number;
    pendingReview: number;
  };
  queues: {
    pendingDeletions: number;
    pendingExports: number;
    pendingCorrections: number;
    pendingGuardians: number;
    pendingRefunds: number;
    pendingPrivacyRequests: number;
    totalPendingAction: number;
  };
  telemetry: {
    totalConsentEvents: number;
    retentionPoliciesConfigured: number;
  };
}

export interface LegalDocumentAdmin {
  id: string;
  document_type: string;
  version: string;
  title: string;
  content?: string;
  effective_at: string | null;
  published_at: string | null;
  published_by: string | null;
  status: 'DRAFT' | 'UNDER_REVIEW' | 'PENDING_LEGAL_REVIEW' | 'APPROVED' | 'PUBLISHED' | 'EFFECTIVE' | 'SUPERSEDED' | 'ARCHIVED';
  is_mandatory: number | boolean;
  locale: string;
  change_summary: string | null;
  created_at: string;
  updated_at: string;
}

export interface LegalBusinessProfile {
  businessIdentity: {
    structure: string;
    legalProprietor: string;
    operatingBrand: string;
    legalRepresentation: string;
  };
  productIdentity: {
    productName: string;
    description: string;
  };
  websiteAddresses: {
    applicationWebsite: string;
    businessWebsite: string;
  };
  contactInformation: {
    grievanceEmail: string;
    supportEmail: string;
    privacyEmail: string;
  };
  physicalAddress: {
    status: string;
    line1: string | null;
    line2: string | null;
    city: string | null;
    state: string | null;
    postalCode: string | null;
    country: string;
    note: string;
  };
  grievanceOfficer: {
    status: string;
    formalAppointmentStatus: string;
    name: string;
    designation: string;
    email: string;
    appointmentDate: string | null;
    note: string;
  };
  verificationStatus: Record<string, string>;
  configurationVersion: string;
  updatedAt: string;
}

export interface AdminAccountDeletionRequest {
  id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
  user_role?: string;
  status: 'PENDING' | 'IDENTITY_VERIFICATION_REQUIRED' | 'VERIFIED' | 'UNDER_REVIEW' | 'DELETION_SCHEDULED' | 'PROCESSING' | 'PARTIALLY_COMPLETED' | 'COMPLETED' | 'CANCELLED' | 'REJECTED_WITH_REASON';
  reason?: string | null;
  submitted_at: string;
  scheduled_purge_at?: string | null;
  completed_at?: string | null;
  assigned_admin_id?: string | null;
  review_notes?: string | null;
  retention_hold_reason?: string | null;
  failure_details?: string | null;
  systems_processed?: string | null;
}

export interface AdminDataExportRequest {
  id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
  user_role?: string;
  export_scope: 'FULL_ARCHIVE' | 'PROJECTS_ONLY' | 'CONSENT_AUDIT';
  status: 'PENDING' | 'PROCESSING' | 'COMPLETED' | 'FAILED' | 'EXPIRED';
  requested_at: string;
  completed_at?: string | null;
  expires_at?: string | null;
  failure_details?: string | null;
  download_url?: string | null;
  download_token?: string | null;
}

export interface AdminDataCorrectionRequest {
  id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
  user_role?: string;
  field_name: string;
  current_value?: string | null;
  proposed_value: string;
  reason?: string | null;
  status: 'PENDING' | 'UNDER_REVIEW' | 'RESOLVED' | 'REJECTED';
  review_notes?: string | null;
  reviewed_by?: string | null;
  resolved_at?: string | null;
  created_at: string;
}

export interface AdminGuardianConsent {
  id: string;
  student_user_id: string;
  student_email?: string;
  student_name?: string;
  guardian_name: string;
  guardian_email: string;
  guardian_phone: string;
  relationship: string;
  consent_declaration: string;
  verification_status: 'PENDING' | 'VERIFIED' | 'REJECTED' | 'WITHDRAWN' | 'EXPIRED';
  verified_by?: string | null;
  verified_at?: string | null;
  withdrawn_at?: string | null;
  notes?: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdminCancellationRefundRequest {
  id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
  user_role?: string;
  project_id?: string | null;
  milestone_id?: string | null;
  reason: string;
  amount_requested?: number | null;
  amount_approved?: number | null;
  status: 'PENDING' | 'UNDER_REVIEW' | 'APPROVED' | 'REJECTED' | 'PROCESSED';
  review_decision?: string | null;
  resolution_notes?: string | null;
  refund_transaction_ref?: string | null;
  reviewed_by?: string | null;
  resolved_at?: string | null;
  created_at: string;
  updated_at: string;
}

export interface AdminConsentEvent {
  id: string;
  user_id: string;
  document_id: string;
  document_type: string;
  document_version: string;
  action_type: string;
  consent_purpose: string;
  idempotency_key?: string | null;
  ip_hash: string;
  user_agent?: string | null;
  source: string;
  recorded_at: string;
}

export interface AdminPrivacyRequest {
  id: string;
  user_id: string;
  user_email?: string;
  user_name?: string;
  user_role?: string;
  request_type: string;
  details?: string | null;
  status: 'PENDING' | 'ACKNOWLEDGED' | 'RESOLVED' | 'REJECTED';
  resolution_notes?: string | null;
  resolved_by?: string | null;
  created_at: string;
  acknowledged_at?: string | null;
  resolved_at?: string | null;
}

export interface DataRetentionPolicy {
  id: string;
  data_category: string;
  purpose: string;
  retention_period: string;
  legal_basis: string;
  policy_source: string;
  last_reviewed_at: string;
  review_status: string;
}

// ==========================================
// SYSTEM TELEMETRY & ACCURACY MODELS
// ==========================================

export interface StorageCategoryStat {
  category: string;
  count: number;
  totalBytes: number;
  formattedSize: string;
}

export interface StorageTelemetry {
  provider: string;
  bucket: string;
  r2Status: 'CONNECTED' | 'UNCONFIGURED' | 'DEGRADED';
  s3Status: {
    configured: boolean;
    status: string;
    provider: string;
    details: string;
  };
  totalFiles: number;
  totalBytes: number;
  formattedTotalSize: string;
  categories: StorageCategoryStat[];
  quota: {
    hasFixedQuota: boolean;
    model: string;
    quotaCeiling: string;
    displayQuota: string;
    usagePercentage: number | null;
    explanation: string;
  };
  lastAudited: string;
}

export interface InfrastructureTelemetry {
  workerGateway: {
    status: string;
    version: string;
    runtime: string;
    environment: string;
    region: string;
    latencyMs: number;
  };
  database: {
    provider: string;
    databaseName: string;
    status: string;
    latencyMs: number;
    foreignKeyCheck: {
      status: string;
      violations: number;
    };
    error?: string | null;
  };
  cadEngine: {
    status: string;
    mode: string;
    externalForgeApi: {
      status: string;
      cluster: string;
    };
    supportedFormats: string[];
    strictLayerCompliance: boolean;
  };
  identityProvider: {
    provider: string;
    projectId: string;
    jwksStatus: string;
    tokenVerification: string;
  };
}

export interface StatutoryBusinessProfile {
  legalProprietor: string;
  businessStructure: string;
  operatingBrand: string;
  productName: string;
  supportEmail: string;
  privacyEmail: string;
  grievanceEmail: string;
  physicalAddressStatus: string;
  physicalAddressCountry: string;
  grievanceOfficerName: string;
  grievanceOfficerStatus: string;
  configurationVersion: string;
  lastUpdated: string | null;
}

export interface SessionAdminProfile {
  id: string;
  name: string;
  email: string;
  role: string;
  mobile: string | null;
  company: string;
  address: string;
  isDistinctFromProprietor: boolean;
  proprietorClarification: string;
}

export interface SystemTelemetryReport {
  success: boolean;
  timestamp: string;
  storage: StorageTelemetry;
  infrastructure: InfrastructureTelemetry;
  legalBusinessProfile: StatutoryBusinessProfile;
  sessionAdmin: SessionAdminProfile;
}

// ==========================================
// ADMIN FINANCIAL MODELS (INR AUTHORITATIVE)
// ==========================================

export interface AdminInvoiceRecord {
  id: string;
  project_id: string;
  invoice_number: string;
  amount: number;
  currency: string;
  status: 'PAID' | 'UNPAID' | 'OVERDUE' | 'CANCELLED';
  due_date: string;
  created_at: string;
  project_title?: string | null;
  drawing_type?: string | null;
  project_area?: string | null;
  project_status?: string | null;
  client_name?: string | null;
  client_email?: string | null;
}

export interface AdminPaymentRecord {
  id: string;
  invoice_id: string;
  amount: number;
  payment_method: string;
  processed_at: string;
  recorded_by: string;
  invoice_number?: string | null;
  currency?: string | null;
  project_id?: string | null;
}

export interface AdminFinancialSummary {
  success: boolean;
  currency: string;
  currencySymbol: string;
  summary: {
    totalInvoiced: number;
    totalCollected: number;
    totalOutstanding: number;
    collectionRate: number;
    invoiceCount: number;
    paidInvoicesCount: number;
    pendingInvoicesCount: number;
    paymentCount: number;
  };
  invoices: AdminInvoiceRecord[];
  payments: AdminPaymentRecord[];
}




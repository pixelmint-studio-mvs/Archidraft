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
      return 'Engineer';
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
  draughtsman_id?: string;
  draughtsman_name?: string;
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
  created_at: string;
  // Joined fields from files table
  original_name?: string;
  sanitized_name?: string;
  object_key?: string;
  content_type?: string;
  size?: number;
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



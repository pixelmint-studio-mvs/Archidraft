/**
 * Shared TypeScript types for the Admin Panel.
 * Maps directly to the D1 database schema and Worker API responses.
 *
 * Ref: docs/02_architecture/DATA_ARCHITECTURE.md
 * Ref: worker/migrations/0001-0005
 */

// ── User ──

export type UserRole = 'CLIENT' | 'DRAUGHTSMAN' | 'ADMIN' | 'STUDIO_ADMIN' | 'STUDENT';
export type UserStatus = 'ACTIVE' | 'SUSPENDED';

/**
 * Helper to get the canonical user-facing role name.
 * 'CLIENT' is the backend database identifier for Engineers.
 */
export function getDisplayRole(role?: string): string {
  if (!role) return 'Unknown';
  switch (role) {
    case 'CLIENT':
      return 'Engineer';
    case 'DRAUGHTSMAN':
      return 'Draughtsman';
    case 'STUDENT':
      return 'Student';
    case 'ADMIN':
    case 'STUDIO_ADMIN':
      return 'Studio Admin';
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
}

// ── Admin Stats (GET /api/admin/stats response) ──

export interface AdminStats {
  projects: {
    total: number;
    byStatus: Record<string, number>;
  };
  users: {
    total: number;
    byRole: Record<string, number>;
  };
  recentActivity: ActivityLog[];
}

// ── Project Comment / Collaboration Message ──

export interface ProjectComment {
  id: string;
  project_id: string;
  author_id: string;
  author_name: string;
  author_role: 'ADMIN' | 'DRAUGHTSMAN' | 'CLIENT';
  content: string;
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




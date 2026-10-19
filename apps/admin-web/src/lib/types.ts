/**
 * Shared TypeScript types for the Admin Panel.
 * Maps directly to the D1 database schema and Worker API responses.
 *
 * Ref: docs/02_architecture/DATA_ARCHITECTURE.md
 * Ref: worker/migrations/0001-0005
 */

// ── User ──

export type UserRole = 'CLIENT' | 'DRAUGHTSMAN' | 'ADMIN';

export interface User {
  id: string;
  email: string;
  name: string;
  role: UserRole;
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
  | 'COMPLETED'
  | 'CANCELLED';

export interface Project {
  id: string;
  client_id: string;
  project_name: string;
  project_address: string;
  drawing_name: string;
  drawing_type: string;
  project_area: string;
  status: ProjectStatus;
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

export type AssignmentStatus = 'PENDING' | 'ACCEPTED' | 'REJECTED' | 'CANCELLED';

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

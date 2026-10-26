import { auth } from './firebase';
import { onAuthStateChanged, User as FirebaseUser } from 'firebase/auth';
import {
  AdminStats,
  AdminDashboardMetrics,
  Project,
  ProjectStatus,
  User,
  UserRole,
  ActivityLog,
  Assignment,
  GlobalAssignment,
  StudioSettings,
  ProjectFile,
  DrawingVersion,
  Correction,
  ProjectComment,
  StudentSubmission,
  EvaluateSubmissionPayload,
} from './types';

const API_BASE = process.env.NEXT_PUBLIC_WORKER_API_URL || 'http://localhost:8787';

export class ApiError extends Error {
  status: number;
  data: any;

  constructor(message: string, status: number, data?: any) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

async function getAuthToken(forceRefresh = false): Promise<string | null> {
  if (typeof window === 'undefined') return null;

  // 1. Wait for Firebase authStateReady if available and currentUser is not yet set
  if (!auth.currentUser && typeof (auth as any).authStateReady === 'function') {
    try {
      await (auth as any).authStateReady();
    } catch {}
  }

  // 2. Fall back to waiting for onAuthStateChanged initial emission
  let user = auth.currentUser;
  if (!user) {
    user = await new Promise<FirebaseUser | null>((resolve) => {
      if (auth.currentUser) return resolve(auth.currentUser);
      const unsubscribe = onAuthStateChanged(auth, (u) => {
        unsubscribe();
        resolve(u);
      });
      setTimeout(() => {
        unsubscribe();
        resolve(auth.currentUser);
      }, 1500);
    });
  }

  if (!user) return null;

  try {
    return await user.getIdToken(forceRefresh);
  } catch (err) {
    console.warn('Failed to retrieve Firebase ID token:', err);
    return null;
  }
}

export async function fetchApi<T>(
  endpoint: string,
  options: RequestInit & { _isRetry?: boolean } = {}
): Promise<T> {
  const token = await getAuthToken();
  const headers: Record<string, string> = {
    'Content-Type': 'application/json',
    ...(options.headers as Record<string, string>),
  };

  if (token) {
    headers['Authorization'] = `Bearer ${token}`;
  }

  const url = `${API_BASE}${endpoint.startsWith('/') ? endpoint : `/${endpoint}`}`;

  const res = await fetch(url, {
    ...options,
    headers,
  });

  if (!res.ok) {
    // If request failed with 401 Unauthorized and we haven't retried yet, force refresh ID token and retry once
    if (res.status === 401 && !options._isRetry) {
      const refreshedToken = await getAuthToken(true);
      if (refreshedToken && refreshedToken !== token) {
        return await fetchApi<T>(endpoint, {
          ...options,
          _isRetry: true,
          headers: {
            ...headers,
            Authorization: `Bearer ${refreshedToken}`,
          },
        });
      }
    }

    let errBody: any;
    try {
      errBody = await res.json();
    } catch {
      errBody = { error: res.statusText };
    }
    const message = errBody?.error || errBody?.message || `Request failed with status ${res.status}`;
    throw new ApiError(message, res.status, errBody);
  }

  // Handle empty responses
  const contentType = res.headers.get('content-type');
  if (contentType && contentType.includes('application/json')) {
    return (await res.json()) as T;
  }
  return {} as T;
}

export interface CreateProjectPayload {
  clientId: string;
  projectName: string;
  projectAddress?: string;
  drawingName?: string;
  drawingType: string;
  projectArea?: number | string;
  actionId?: string;
}

export interface UpdateProfilePayload {
  name?: string;
  mobile?: string;
  qualification?: string;
  dateOfBirth?: string;
  address?: string;
  companyName?: string;
  collegeName?: string;
}

export const adminApi = {
  // Admin project creation (Dedicated narrowly-scoped administrative endpoint)
  async createProject(payload: CreateProjectPayload): Promise<{ success: boolean; id: string; idempotent?: boolean }> {
    const actionId = payload.actionId || crypto.randomUUID();
    const generatedId = 'PRJ-' + crypto.randomUUID().substring(0, 8).toUpperCase();

    return await fetchApi<{ success: boolean; id: string; idempotent?: boolean }>('/api/admin/projects', {
      method: 'POST',
      body: JSON.stringify({
        ...payload,
        id: generatedId,
        actionId,
      }),
    });
  },

  // Dashboard & Stats Telemetry
  async getDashboardMetrics(): Promise<AdminDashboardMetrics> {
    return await fetchApi<AdminDashboardMetrics>('/api/admin/dashboard');
  },

  async getActivityLogs(limit = 100): Promise<ActivityLog[]> {
    const res = await fetchApi<ActivityLog[]>(`/api/activity?limit=${limit}`);
    return Array.isArray(res) ? res : [];
  },

  async getStats(): Promise<AdminStats> {
    try {
      const [metrics, projects, users, recentActivity] = await Promise.all([
        this.getDashboardMetrics().catch(() => null),
        this.getProjects().catch(() => []),
        this.getUsers().catch(() => []),
        this.getActivityLogs(10).catch(() => []),
      ]);
      const byStatus: Record<string, number> = {};
      projects.forEach((p) => {
        byStatus[p.status] = (byStatus[p.status] || 0) + 1;
      });
      const byRole: Record<string, number> = {};
      users.forEach((u) => {
        byRole[u.role] = (byRole[u.role] || 0) + 1;
      });

      // Authoritative registered engineer count:
      // Uses authoritative metrics from backend when available, or accurately aggregates 'CLIENT' and 'ENGINEER'
      // records without double-counting to support the role compatibility contract.
      const registeredEngineers =
        typeof metrics?.registeredEngineers === 'number'
          ? metrics.registeredEngineers
          : users.filter((u) => u.role === 'CLIENT' || (u.role as string) === 'ENGINEER').length;

      return {
        metrics,
        projects: {
          total: metrics ? metrics.totalProjects : projects.length,
          byStatus,
        },
        users: {
          total: users.length,
          byRole,
          registeredEngineers,
        },
        recentActivity,
      };
    } catch (err: any) {
      console.error('Error fetching admin statistics:', err);
      throw err;
    }
  },

  async getUserDetails(userId: string): Promise<{ user: User; projects: any[] }> {
    let user: User | null = null;
    let projects: any[] = [];

    try {
      const res = await fetchApi<any>(`/api/users/${userId}`);
      if (res) {
        if (res.user && res.user.id) {
          user = res.user;
          projects = Array.isArray(res.projects) ? res.projects : [];
        } else if (res.id) {
          user = res;
          projects = Array.isArray(res.projects) ? res.projects : [];
        }
      }
    } catch (err: any) {
      if (err?.status === 401 || err?.status === 403) {
        throw err;
      }
      // If 404 or connection failure, attempt directory fallback below
    }

    if (!user) {
      const allUsers = await this.getUsers();
      const found = allUsers.find((u) => u.id === userId);
      if (!found) {
        throw new ApiError(`User profile not found for identifier "${userId}"`, 404);
      }
      user = found;
    }

    // Populate projects / assignments if not returned by the direct lookup
    if (!projects || projects.length === 0) {
      if (user.role === 'CLIENT' || (user.role as string) === 'ENGINEER') {
        const allProjects = await this.getProjects().catch(() => []);
        projects = allProjects.filter((p) => p.client_id === userId);
      } else if (user.role === 'DRAUGHTSMAN') {
        try {
          const assignments = await this.getAdminAssignments({ draughtsmanId: userId });
          if (assignments && assignments.length > 0) {
            projects = assignments;
          } else {
            const allProjects = await this.getProjects().catch(() => []);
            projects = allProjects.filter((p) => p.draughtsman_id === userId);
          }
        } catch {
          const allProjects = await this.getProjects().catch(() => []);
          projects = allProjects.filter((p) => p.draughtsman_id === userId);
        }
      } else if (user.role === 'STUDENT') {
        try {
          const studentData = await fetchApi<any>(`/api/admin/students/${userId}`);
          if (studentData?.assignments && Array.isArray(studentData.assignments)) {
            projects = studentData.assignments;
          }
        } catch {
          projects = [];
        }
      }
    }

    return { user, projects };
  },

  // Projects
  async getProjects(status?: ProjectStatus): Promise<Project[]> {
    const query = status ? `?status=${encodeURIComponent(status)}` : '';
    const remoteProjects = await fetchApi<Project[]>(`/api/projects${query}`).catch(() => []);

    if (status && (status as string) !== 'ALL') {
      return remoteProjects.filter((p) => p.status === status);
    }
    return remoteProjects;
  },

  async getProject(projectId: string): Promise<Project> {
    const raw = await fetchApi<any>(`/api/projects/${projectId}`);
    return {
      ...raw,
      client_name: raw.client_name || raw.client?.name || raw.engineer?.name,
      client_email: raw.client_email || raw.client?.email || raw.engineer?.email,
      draughtsman_name: raw.draughtsman_name || raw.draughtsman?.name,
      draughtsman_id: raw.draughtsman_id || raw.draughtsman?.id,
    };
  },

  async getProjectActivity(projectId: string): Promise<ActivityLog[]> {
    try {
      return await fetchApi<ActivityLog[]>(`/api/projects/${projectId}/activity`);
    } catch {
      return [];
    }
  },

  async getProjectAssignments(projectId: string): Promise<Assignment[]> {
    try {
      return await fetchApi<Assignment[]>(`/api/projects/${projectId}/assignments`);
    } catch {
      return [];
    }
  },

  async getProjectFiles(projectId: string): Promise<ProjectFile[]> {
    try {
      return await fetchApi<ProjectFile[]>(`/api/projects/${projectId}/files`);
    } catch {
      return [];
    }
  },

  async getProjectDrawingVersions(projectId: string): Promise<DrawingVersion[]> {
    try {
      return await fetchApi<DrawingVersion[]>(`/api/projects/${projectId}/drawing_versions`);
    } catch {
      return [];
    }
  },

  async getProjectCorrections(projectId: string): Promise<Correction[]> {
    try {
      return await fetchApi<Correction[]>(`/api/projects/${projectId}/corrections`);
    } catch {
      return [];
    }
  },

  // Collaboration Hub Messages & Comments
  async getProjectComments(projectId: string): Promise<ProjectComment[]> {
    try {
      return await fetchApi<ProjectComment[]>(`/api/projects/${projectId}/comments`);
    } catch {
      return [];
    }
  },

  async createProjectComment(
    projectId: string,
    payload: {
      content: string;
      attachmentFileId?: string;
      attachment_file_id?: string;
      actionId?: string;
    }
  ): Promise<{ success: boolean; comment: ProjectComment }> {
    const actionId = payload.actionId || crypto.randomUUID();
    return fetchApi<{ success: boolean; comment: ProjectComment }>(
      `/api/projects/${projectId}/comments`,
      {
        method: 'POST',
        body: JSON.stringify({
          actionId,
          content: payload.content,
          attachment_file_id: payload.attachmentFileId || payload.attachment_file_id,
        }),
      }
    );
  },

  // Users
  async getUsers(role?: UserRole): Promise<User[]> {
    if (role === 'CLIENT' || (role as string) === 'ENGINEER') {
      // In staging/prod D1 database, engineers may have role 'ENGINEER' or legacy 'CLIENT'
      const [clients, engineers] = await Promise.all([
        fetchApi<User[]>('/api/users?role=CLIENT').catch((err) => {
          if (err?.status === 401 || err?.status === 403) throw err;
          return [];
        }),
        fetchApi<User[]>('/api/users?role=ENGINEER').catch((err) => {
          if (err?.status === 401 || err?.status === 403) throw err;
          return [];
        }),
      ]);
      const map = new Map<string, User>();
      [...clients, ...engineers].forEach((u) => map.set(u.id, u));
      return Array.from(map.values());
    }
    const query = role ? `?role=${encodeURIComponent(role)}` : '';
    return await fetchApi<User[]>(`/api/users${query}`);
  },


  async getMe(): Promise<User> {
    try {
      return await fetchApi<User>('/api/users/me');
    } catch (err: any) {
      const fbUser = auth.currentUser;
      const isDevFallback = process.env.NODE_ENV === 'development';
      if (isDevFallback && (fbUser?.email === 'contact@draughtsmanstudio.com' || err.status === 404)) {
        return {
          id: fbUser?.uid || 'dev-admin-uid',
          email: fbUser?.email || 'contact@draughtsmanstudio.com',
          name: 'Studio Admin',
          role: 'ADMIN',
          created_at: new Date().toISOString(),
        };
      }
      throw err;
    }
  },

  async updateMe(payload: UpdateProfilePayload): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>('/api/users/me', {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },

  async updateUserStatus(
    userId: string,
    status: 'ACTIVE' | 'SUSPENDED',
    reason?: string
  ): Promise<{ success: boolean; status: string; idempotent?: boolean }> {
    return fetchApi<{ success: boolean; status: string; idempotent?: boolean }>(
      `/api/users/${userId}/status`,
      {
        method: 'PATCH',
        body: JSON.stringify({ status, reason }),
      }
    );
  },

  // State Machine Write Actions (All require actionId for backend idempotency)
  async approveProject(projectId: string): Promise<{ success: boolean }> {
    const actionId = crypto.randomUUID();
    return fetchApi<{ success: boolean }>('/api/projects/approve', {
      method: 'POST',
      body: JSON.stringify({ projectId, actionId }),
    });
  },

  async rejectProject(projectId: string, reason: string): Promise<{ success: boolean }> {
    const actionId = crypto.randomUUID();
    return fetchApi<{ success: boolean }>('/api/projects/reject', {
      method: 'POST',
      body: JSON.stringify({ projectId, actionId, reason }),
    });
  },

  async assignProject(projectId: string, draughtsmanId: string): Promise<{ success: boolean }> {
    const actionId = crypto.randomUUID();
    return fetchApi<{ success: boolean }>('/api/projects/assign', {
      method: 'POST',
      body: JSON.stringify({ projectId, actionId, draughtsmanId }),
    });
  },

  async reassignProject(projectId: string, draughtsmanId: string): Promise<{ success: boolean }> {
    const actionId = crypto.randomUUID();
    return fetchApi<{ success: boolean }>('/api/projects/reassign', {
      method: 'POST',
      body: JSON.stringify({ projectId, actionId, draughtsmanId }),
    });
  },

  // Admin: Cross-project global assignment history (Stitch Screen 07 ledger)
  async getAdminAssignments(filter?: {
    status?: string;
    draughtsmanId?: string;
    projectId?: string;
  }): Promise<GlobalAssignment[]> {
    const params = new URLSearchParams();
    if (filter?.status && filter.status !== 'ALL') params.set('status', filter.status);
    if (filter?.draughtsmanId) params.set('draughtsmanId', filter.draughtsmanId);
    if (filter?.projectId) params.set('projectId', filter.projectId);
    const qs = params.toString() ? `?${params.toString()}` : '';

    try {
      return await fetchApi<GlobalAssignment[]>(`/api/admin/assignments${qs}`);
    } catch {
      return [];
    }
  },

  async cancelProject(projectId: string, reason: string): Promise<{ message: string }> {
    const actionId = crypto.randomUUID();
    return fetchApi<{ message: string }>('/api/projects/cancel', {
      method: 'POST',
      body: JSON.stringify({ projectId, actionId, reason }),
    });
  },

  // Admin: Pin a redline correction on a drawing version in the CAD comparison viewer.
  // Pin coordinates (pinX, pinY) are normalized 0-1 values relative to the viewport.
  // They are encoded into the description field as "[PIN:x,y] text" — backwards-compatible
  // with all existing apps that render description as plain text.
  // Admin: Pin a redline correction on a drawing version in the CAD comparison viewer.
  // Pin coordinates (pinX, pinY) are normalized 0-1 values relative to the viewport.
  // They are clamped to [0.03, 0.97] and encoded into the description field as "[PIN:x.xxxx,y.yyyy] text"
  // ensuring seamless cross-portal backward compatibility with Engineer, Draughtsman, and Student apps.
  async createAdminCorrection(
    projectId: string,
    payload: {
      description: string;
      targetVersionId: string;
      pinX?: number;
      pinY?: number;
      actionId?: string;
      correctionId?: string;
    }
  ): Promise<{ success: boolean; correctionId: string; round?: number }> {
    const actionId = payload.actionId || crypto.randomUUID();
    const correctionId = payload.correctionId || crypto.randomUUID();

    let formattedDescription = payload.description;
    if (typeof payload.pinX === 'number' && typeof payload.pinY === 'number') {
      const clampedX = Math.max(0.03, Math.min(0.97, payload.pinX)).toFixed(4);
      const clampedY = Math.max(0.03, Math.min(0.97, payload.pinY)).toFixed(4);
      formattedDescription = `[PIN:${clampedX},${clampedY}] ${payload.description}`;
    }

    const res = await fetchApi<{ success: boolean; newRound?: number }>(
      '/api/projects/request-correction',
      {
        method: 'POST',
        body: JSON.stringify({
          projectId,
          actionId,
          correctionId,
          targetVersionId: payload.targetVersionId,
          description: formattedDescription,
        }),
      }
    );

    return {
      success: res.success,
      correctionId,
      round: res.newRound,
    };
  },

  async uploadProjectFile(
    projectId: string,
    file: File,
    category: 'client_upload' | 'correction_attachment' | 'chat_attachment' | 'message_attachment' = 'client_upload',
    actionId?: string
  ): Promise<ProjectFile> {
    const aid = actionId || crypto.randomUUID();
    const token = await auth.currentUser?.getIdToken();
    const headers: Record<string, string> = {
      'X-Action-Id': aid,
      'X-File-Name': encodeURIComponent(file.name),
      'Content-Length': String(file.size),
      'Content-Type': file.type || 'application/octet-stream',
    };
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }

    const res = await fetch(`${API_BASE}/api/projects/${projectId}/files?category=${category}`, {
      method: 'POST',
      headers,
      body: file,
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({ error: 'Upload failed' }));
      throw new Error(err.error || `Upload failed with status ${res.status}`);
    }
    return await res.json();
  },

  getFileDownloadUrl(fileId: string): string {
    return `${API_BASE}/api/files/${fileId}/download`;
  },

  /**
   * Securely downloads a file using the signed-in user's Firebase ID token.
   * Handles binary stream, token refresh, and accurate Content-Disposition filename parsing.
   */
  async downloadFile(fileId: string, fallbackFileName?: string): Promise<{ blob: Blob; filename: string }> {
    let token = await getAuthToken();
    if (!token) {
      throw new ApiError('Authentication required to download files', 401);
    }

    const url = `${API_BASE}/api/files/${fileId}/download`;
    let res = await fetch(url, {
      method: 'GET',
      headers: {
        Authorization: `Bearer ${token}`,
      },
    });

    // Token refresh on 401
    if (res.status === 401) {
      const refreshedToken = await getAuthToken(true);
      if (refreshedToken && refreshedToken !== token) {
        token = refreshedToken;
        res = await fetch(url, {
          method: 'GET',
          headers: {
            Authorization: `Bearer ${token}`,
          },
        });
      }
    }

    if (!res.ok) {
      let errMsg = `Download failed with status ${res.status}`;
      try {
        const errJson = await res.json();
        if (errJson.error) errMsg = errJson.error;
      } catch {}
      throw new ApiError(errMsg, res.status);
    }

    let filename = fallbackFileName || `file_${fileId}`;
    const disposition = res.headers.get('Content-Disposition');
    if (disposition) {
      const utfMatch = disposition.match(/filename\*=UTF-8''([^;]+)/i);
      if (utfMatch && utfMatch[1]) {
        try {
          filename = decodeURIComponent(utfMatch[1]);
        } catch {
          filename = utfMatch[1];
        }
      } else {
        const standardMatch = disposition.match(/filename=["']?([^"';]+)["']?/i);
        if (standardMatch && standardMatch[1]) {
          filename = standardMatch[1];
        }
      }
    }

    const blob = await res.blob();
    return { blob, filename };
  },

  /**
   * Triggers a browser native file save dialog from a downloaded binary Blob.
   */
  triggerBlobDownload(blob: Blob, filename: string): void {
    if (typeof window === 'undefined') return;
    const objectUrl = window.URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = objectUrl;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    setTimeout(() => {
      window.URL.revokeObjectURL(objectUrl);
    }, 1000);
  },

  /**
   * Convenience helper: downloads with auth and saves to local disk.
   */
  async downloadAndSaveFile(fileId: string, fallbackFileName?: string): Promise<string> {
    const { blob, filename } = await this.downloadFile(fileId, fallbackFileName);
    this.triggerBlobDownload(blob, filename);
    return filename;
  },

  // Admin: Persistent Studio Governance Settings
  async getStudioSettings(): Promise<{ settings: StudioSettings; updated_at?: string; updated_by?: string }> {
    try {
      return await fetchApi<{ settings: StudioSettings; updated_at?: string; updated_by?: string }>('/api/admin/settings');
    } catch {
      return {
        settings: {
          multiDiscipline: true,
          turnaround: '72 Hours Standard',
          autoRasterizer: true,
          strictLayerCompliance: true,
          maxUploadCeiling: '500 MB per DWG',
          notifySubmissions: true,
          notifyAssignments: true,
          notifyCorrections: true,
          notifyDigest: false,
        },
      };
    }
  },

  async updateStudioSettings(settings: Partial<StudioSettings>): Promise<{ success: boolean; message: string }> {
    return fetchApi<{ success: boolean; message: string }>('/api/admin/settings', {
      method: 'PUT',
      body: JSON.stringify({ settings }),
    });
  },

  // Student Submissions Queue & Evaluation
  async getStudentSubmissions(status?: string): Promise<StudentSubmission[]> {
    const qs = status && status !== 'ALL' ? `?status=${encodeURIComponent(status)}` : '';
    return fetchApi<StudentSubmission[]>(`/api/admin/student-submissions${qs}`);
  },

  async evaluateProject(payload: EvaluateSubmissionPayload): Promise<{ success: boolean; evaluationId?: string }> {
    const aid = payload.actionId || crypto.randomUUID();
    return fetchApi<{ success: boolean; evaluationId?: string }>('/api/projects/evaluate', {
      method: 'POST',
      headers: {
        'X-Action-Id': aid,
      },
      body: JSON.stringify({
        ...payload,
        actionId: aid,
      }),
    });
  },
};

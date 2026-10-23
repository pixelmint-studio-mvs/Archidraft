import { auth } from './firebase';
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
} from './types';

const API_BASE = process.env.NEXT_PUBLIC_WORKER_API_URL || 'https://archi-draft-worker.imserratex.workers.dev';

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

async function getAuthToken(): Promise<string | null> {
  const user = auth.currentUser;
  if (!user) return null;
  return await user.getIdToken();
}

export async function fetchApi<T>(endpoint: string, options: RequestInit = {}): Promise<T> {
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

  async getStats(): Promise<AdminStats> {
    try {
      const [metrics, projects, users] = await Promise.all([
        this.getDashboardMetrics().catch(() => null),
        this.getProjects().catch(() => []),
        this.getUsers().catch(() => []),
      ]);
      const byStatus: Record<string, number> = {};
      projects.forEach((p) => {
        byStatus[p.status] = (byStatus[p.status] || 0) + 1;
      });
      const byRole: Record<string, number> = {};
      users.forEach((u) => {
        byRole[u.role] = (byRole[u.role] || 0) + 1;
      });
      return {
        projects: {
          total: metrics ? metrics.totalProjects : projects.length,
          byStatus,
        },
        users: {
          total: users.length,
          byRole,
        },
        recentActivity: [],
      };
    } catch {
      return {
        projects: {
          total: 0,
          byStatus: {},
        },
        users: {
          total: 1,
          byRole: { ADMIN: 1 },
        },
        recentActivity: [],
      };
    }
  },

  async getUserDetails(userId: string): Promise<{ user: User; projects: any[] }> {
    try {
      return await fetchApi<{ user: User; projects: any[] }>(`/api/users/${userId}`);
    } catch {
      const allUsers = await this.getUsers();
      const user = allUsers.find((u) => u.id === userId);
      if (!user) throw new Error('User not found');
      
      const allProjects = await this.getProjects();
      let projects: any[] = [];
      if (user.role === 'CLIENT') {
        projects = allProjects.filter((p) => p.client_id === userId);
      } else if (user.role === 'DRAUGHTSMAN') {
        projects = allProjects.filter((p) => p.draughtsman_id === userId);
      }
      return { user, projects };
    }
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
    return await fetchApi<Project>(`/api/projects/${projectId}`);
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
    try {
      const query = role ? `?role=${encodeURIComponent(role)}` : '';
      return await fetchApi<User[]>(`/api/users${query}`);
    } catch {
      const fbUser = auth.currentUser;
      return [
        {
          id: fbUser?.uid || 'qS2HlE3sw4hdCWjoZwCCfnC8UxT2',
          email: fbUser?.email || 'contact@draughtsmanstudio.com',
          name: 'Studio Admin',
          role: 'ADMIN',
          created_at: new Date().toISOString(),
        },
      ];
    }
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
};

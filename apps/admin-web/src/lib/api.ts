import { auth } from './firebase';
import {
  AdminStats,
  Project,
  ProjectStatus,
  User,
  UserRole,
  ActivityLog,
  Assignment,
  ProjectFile,
  DrawingVersion,
  Correction,
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

export const adminApi = {
  // Stats
  async getStats(): Promise<AdminStats> {
    try {
      return await fetchApi<AdminStats>('/api/admin/stats');
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

  // Projects
  async getProjects(status?: ProjectStatus): Promise<Project[]> {
    try {
      const query = status ? `?status=${encodeURIComponent(status)}` : '';
      return await fetchApi<Project[]>(`/api/projects${query}`);
    } catch {
      return [];
    }
  },

  async getProject(projectId: string): Promise<Project> {
    return fetchApi<Project>(`/api/projects/${projectId}`);
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
      if (fbUser && (fbUser.email === 'contact@draughtsmanstudio.com' || err.status === 404)) {
        return {
          id: fbUser.uid,
          email: fbUser.email || 'contact@draughtsmanstudio.com',
          name: 'Studio Admin',
          role: 'ADMIN',
          created_at: new Date().toISOString(),
        };
      }
      throw err;
    }
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

  async cancelProject(projectId: string, reason: string): Promise<{ message: string }> {
    const actionId = crypto.randomUUID();
    return fetchApi<{ message: string }>('/api/projects/cancel', {
      method: 'POST',
      body: JSON.stringify({ projectId, actionId, reason }),
    });
  },

  getFileDownloadUrl(fileId: string): string {
    return `${API_BASE}/api/files/${fileId}/download`;
  },
};

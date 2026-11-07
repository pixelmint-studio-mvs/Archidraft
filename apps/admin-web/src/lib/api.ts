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
  DrawingVersionReview,
  AdminNotification,
  Correction,
  ProjectComment,
  StudentSubmission,
  EvaluateSubmissionPayload,
  TrainingModule,
  TrainingChapter,
  TrainingLesson,
  StudentLearningPlan,
  StudentProgressSummary,
  StudentProgressDetail,
  LessonResource,
  EngineerProjectStatusItem,
  HelpdeskTicket,
  HelpdeskEvent,
  HelpdeskComment,
  HelpdeskEmailLog,
  HelpdeskStats,
  HelpdeskHealthReport,
  HelpdeskSettings,
  RegistrationVerification,
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
  QuestionAnalyticsData,
  QuestionAnalyticsFilter,
  LegalComplianceStats,
  LegalDocumentAdmin,
  LegalBusinessProfile,
  AdminAccountDeletionRequest,
  AdminDataExportRequest,
  AdminDataCorrectionRequest,
  AdminGuardianConsent,
  AdminCancellationRefundRequest,
  AdminConsentEvent,
  AdminPrivacyRequest,
  DataRetentionPolicy,
} from './types';

export const API_BASE = (() => {
  if (process.env.NEXT_PUBLIC_WORKER_API_URL) {
    return process.env.NEXT_PUBLIC_WORKER_API_URL;
  }
  if (typeof window !== 'undefined') {
    const hostname = window.location.hostname;
    const isLocalhost = hostname === 'localhost' || hostname === '127.0.0.1' || hostname === '0.0.0.0';
    if (isLocalhost) {
      return 'http://localhost:8787';
    }
    if (hostname.endsWith('.vercel.app') || window.location.protocol === 'https:') {
      return 'https://archi-draft-worker-staging.imserratex.workers.dev';
    }
  }
  return 'http://localhost:8787';
})();

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

export type ApiErrorKind =
  | 'AUTH_FAILED'        // 401: Authentication failure (expired / invalid token)
  | 'AUTH_FORBIDDEN'     // 403: Authorization failure (insufficient privileges / role)
  | 'BACKEND_DOWN'       // 502, 503, 504: Cloudflare Worker backend unavailable
  | 'NETWORK_FAILURE'    // 0: Network / DNS / offline / connection drop
  | 'INVALID_RESPONSE'   // Malformed JSON / unexpected schema
  | 'SERVER_ERROR'       // 500: Worker unhandled runtime error
  | 'NOT_FOUND'          // 404: Resource not found
  | 'UNKNOWN';

export interface ClassifiedError {
  kind: ApiErrorKind;
  title: string;
  message: string;
  status: number;
  canRetry: boolean;
  actionText?: string;
}

export function classifyApiError(err: unknown): ClassifiedError {
  if (err instanceof ApiError) {
    if (err.data?.invalidResponse || err.message.toLowerCase().includes('invalid response')) {
      return {
        kind: 'INVALID_RESPONSE',
        title: 'Invalid Response',
        message: 'The server returned an invalid or malformed data payload.',
        status: err.status,
        canRetry: true,
        actionText: 'Retry Request',
      };
    }
    if (err.status === 401) {
      return {
        kind: 'AUTH_FAILED',
        title: 'Authentication Failure',
        message: 'Your authentication session has expired or is invalid. Please sign in again to continue.',
        status: 401,
        canRetry: true,
        actionText: 'Sign In Again',
      };
    }
    if (err.status === 403) {
      return {
        kind: 'AUTH_FORBIDDEN',
        title: 'Authorization Failure',
        message: 'Access Denied: Your account does not possess administrator privileges to access this console.',
        status: 403,
        canRetry: false,
        actionText: 'Check Permissions',
      };
    }
    if (err.status === 502 || err.status === 503 || err.status === 504) {
      return {
        kind: 'BACKEND_DOWN',
        title: 'Backend Unavailable',
        message: `The Cloudflare Worker backend service is currently unreachable (HTTP ${err.status}). Please verify service status and retry.`,
        status: err.status,
        canRetry: true,
        actionText: 'Retry Connection',
      };
    }
    if (err.status === 0 || err.data?.isNetworkError) {
      return {
        kind: 'NETWORK_FAILURE',
        title: 'Network Failure',
        message: 'Unable to connect to the backend server. Please verify your internet connection.',
        status: 0,
        canRetry: true,
        actionText: 'Retry Request',
      };
    }
    if (err.status >= 500) {
      return {
        kind: 'SERVER_ERROR',
        title: 'Backend Service Error',
        message: err.message || `An internal server error occurred (HTTP ${err.status}).`,
        status: err.status,
        canRetry: true,
        actionText: 'Retry Request',
      };
    }
    return {
      kind: 'UNKNOWN',
      title: 'API Request Failed',
      message: err.message || `Request failed with status ${err.status}`,
      status: err.status,
      canRetry: true,
      actionText: 'Retry Request',
    };
  }

  if (err instanceof TypeError || (err as any)?.message?.includes('fetch')) {
    return {
      kind: 'NETWORK_FAILURE',
      title: 'Network Failure',
      message: 'Failed to communicate with the backend API. Please check your internet connection.',
      status: 0,
      canRetry: true,
      actionText: 'Retry Request',
    };
  }

  return {
    kind: 'UNKNOWN',
    title: 'Unexpected Error',
    message: (err as any)?.message || 'An unexpected error occurred while communicating with the server.',
    status: -1,
    canRetry: true,
    actionText: 'Retry Request',
  };
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

function reportApiFailureSafely(endpoint: string, status: number, message: string) {
  // Never report client-side network dropouts (HTTP 0), routine auth/not-found (401/404), or helpdesk polling calls
  if (
    status === 0 ||
    status === 401 ||
    status === 404 ||
    endpoint.includes('/helpdesk') ||
    typeof window === 'undefined'
  ) {
    return;
  }

  const key = `${endpoint}:${status}`;
  const now = Date.now();
  const cache = (reportApiFailureSafely as any)._debounce || ((reportApiFailureSafely as any)._debounce = {});
  if (cache[key] && now - cache[key] < 30000) return;
  cache[key] = now;

  try {
    fetch(`${API_BASE}/api/helpdesk/report`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        title: `API Request Failure: HTTP ${status} on ${endpoint.split('?')[0]}`,
        category: status === 401 || status === 403 ? 'AUTHENTICATION' : 'API',
        severity: status >= 500 ? 'HIGH' : status === 403 ? 'MEDIUM' : 'LOW',
        source: 'ADMIN_PANEL',
        affected_module: endpoint.split('?')[0],
        error_message: message,
        error_code: String(status),
        page_route: window.location?.pathname,
        browser: typeof navigator !== 'undefined' ? navigator.userAgent : undefined,
      }),
    }).catch(() => {});
  } catch {}
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

  let res: Response;
  try {
    res = await fetch(url, {
      ...options,
      headers,
    });
  } catch (netErr: any) {
    const isNetworkError =
      netErr?.message?.includes('Failed to fetch') ||
      netErr?.name === 'TypeError' ||
      netErr?.message?.includes('NetworkError');
    reportApiFailureSafely(endpoint, 0, netErr?.message || 'Network failure');
    throw new ApiError(
      isNetworkError
        ? 'Network failure: Unable to reach backend API. Please check your internet connection or server availability.'
        : `Network connection error: ${netErr?.message || 'Failed to fetch'}`,
      0,
      { isNetworkError: true, originalError: netErr }
    );
  }

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
    reportApiFailureSafely(endpoint, res.status, message);
    throw new ApiError(message, res.status, errBody);
  }

  // Handle empty or JSON responses
  const contentType = res.headers.get('content-type');
  if (contentType && contentType.includes('application/json')) {
    try {
      return (await res.json()) as T;
    } catch (parseErr: any) {
      throw new ApiError(
        'Invalid response: Expected JSON from backend but received malformed data.',
        502,
        { invalidResponse: true, parseErr }
      );
    }
  }
  return {} as T;
}

export interface CreateProjectPayload {
  clientId?: string;
  studentId?: string;
  isTrainingProject?: boolean;
  trainingModuleId?: string;
  instructions?: string;
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
      const [metrics, projects, users, recentActivity, pendingRegs] = await Promise.all([
        this.getDashboardMetrics().catch((err) => {
          if (err?.status === 404) return null;
          throw err;
        }),
        this.getProjects(),
        this.getUsers(),
        this.getActivityLogs(10).catch((err) => {
          if (err?.status === 404) return [];
          throw err;
        }),
        this.getRegistrations({ status: 'PENDING' }).catch(() => []),
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
        pendingRegistrations: (pendingRegs as any[])?.length || 0,
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
        const allProjects = await this.getProjects();
        projects = allProjects.filter((p) => p.client_id === userId);
      } else if (user.role === 'DRAUGHTSMAN') {
        try {
          const assignments = await this.getAdminAssignments({ draughtsmanId: userId });
          if (assignments && assignments.length > 0) {
            projects = assignments;
          } else {
            const allProjects = await this.getProjects();
            projects = allProjects.filter((p) => p.draughtsman_id === userId);
          }
        } catch (err: any) {
          if (err?.status === 404) {
            const allProjects = await this.getProjects();
            projects = allProjects.filter((p) => p.draughtsman_id === userId);
          } else {
            throw err;
          }
        }
      } else if (user.role === 'STUDENT') {
        try {
          const studentData = await fetchApi<any>(`/api/admin/students/${userId}`);
          if (studentData?.assignments && Array.isArray(studentData.assignments)) {
            projects = studentData.assignments;
          }
        } catch (err: any) {
          if (err?.status === 404) {
            projects = [];
          } else {
            throw err;
          }
        }
      }
    }

    return { user, projects };
  },

  // Projects
  async getProjects(status?: ProjectStatus | string): Promise<Project[]> {
    const params = new URLSearchParams();
    if (status && status !== 'ALL') {
      params.set('status', status);
    }
    const query = params.toString() ? `?${params.toString()}` : '';
    const remoteProjects = await fetchApi<Project[]>(`/api/projects${query}`);

    if (status && status !== 'ALL') {
      return remoteProjects.filter((p) => p.status === status);
    }
    return remoteProjects;
  },

  async removeProject(projectId: string): Promise<{ success: boolean; removedProjectId: string; message?: string }> {
    return fetchApi<{ success: boolean; removedProjectId: string; message?: string }>(
      `/api/projects/${projectId}`,
      {
        method: 'DELETE',
      }
    );
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
    } catch (err: any) {
      if (err?.status === 404) return [];
      throw err;
    }
  },

  async getProjectAssignments(projectId: string): Promise<Assignment[]> {
    try {
      return await fetchApi<Assignment[]>(`/api/projects/${projectId}/assignments`);
    } catch (err: any) {
      if (err?.status === 404) return [];
      throw err;
    }
  },

  async getProjectFiles(projectId: string): Promise<ProjectFile[]> {
    try {
      return await fetchApi<ProjectFile[]>(`/api/projects/${projectId}/files`);
    } catch (err: any) {
      if (err?.status === 404) return [];
      throw err;
    }
  },

  async getProjectDrawingVersions(projectId: string): Promise<DrawingVersion[]> {
    try {
      return await fetchApi<DrawingVersion[]>(`/api/projects/${projectId}/drawing_versions`);
    } catch (err: any) {
      if (err?.status === 404) return [];
      throw err;
    }
  },

  async getDrawingVersionReviews(projectId: string): Promise<DrawingVersionReview[]> {
    try {
      return await fetchApi<DrawingVersionReview[]>(`/api/projects/${projectId}/drawing_version_reviews`);
    } catch {
      return [];
    }
  },

  async adminApproveDrawing(
    projectId: string,
    drawingVersionId: string,
    feedback?: string,
    actionId?: string
  ): Promise<{
    success: boolean;
    drawingVersionId: string;
    versionNumber: number;
    approvalStatus: string;
    projectStatus: string;
  }> {
    return await fetchApi<{
      success: boolean;
      drawingVersionId: string;
      versionNumber: number;
      approvalStatus: string;
      projectStatus: string;
    }>('/api/projects/admin-approve-drawing', {
      method: 'POST',
      body: JSON.stringify({
        projectId,
        drawingVersionId,
        actionId: actionId || (typeof crypto !== 'undefined' ? crypto.randomUUID() : undefined),
        feedback,
      }),
    });
  },

  async adminRequestRevision(
    projectId: string,
    drawingVersionId: string,
    feedback: string,
    actionId?: string
  ): Promise<{
    success: boolean;
    drawingVersionId: string;
    versionNumber: number;
    approvalStatus: string;
    projectStatus: string;
  }> {
    return await fetchApi<{
      success: boolean;
      drawingVersionId: string;
      versionNumber: number;
      approvalStatus: string;
      projectStatus: string;
    }>('/api/projects/admin-request-revision', {
      method: 'POST',
      body: JSON.stringify({
        projectId,
        drawingVersionId,
        actionId: actionId || (typeof crypto !== 'undefined' ? crypto.randomUUID() : undefined),
        feedback,
      }),
    });
  },

  async getProjectCorrections(projectId: string): Promise<Correction[]> {
    try {
      return await fetchApi<Correction[]>(`/api/projects/${projectId}/corrections`);
    } catch (err: any) {
      if (err?.status === 404) return [];
      throw err;
    }
  },

  // Collaboration Hub Messages & Comments
  async getProjectComments(projectId: string): Promise<ProjectComment[]> {
    try {
      return await fetchApi<ProjectComment[]>(`/api/projects/${projectId}/comments`);
    } catch (err: any) {
      if (err?.status === 404) return [];
      throw err;
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
          if (err?.status === 404) return [];
          throw err;
        }),
        fetchApi<User[]>('/api/users?role=ENGINEER').catch((err) => {
          if (err?.status === 404) return [];
          throw err;
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

  // Admin: Assign an architectural drafting project to a registered Engineer
  async assignProjectToEngineer(
    projectId: string,
    engineerId: string,
    actionId?: string
  ): Promise<{ success: boolean; projectId: string; engineerId: string; message?: string }> {
    const effectiveActionId = actionId || crypto.randomUUID();
    return fetchApi<{ success: boolean; projectId: string; engineerId: string; message?: string }>(
      '/api/admin/projects/assign-engineer',
      {
        method: 'POST',
        body: JSON.stringify({ projectId, engineerId, actionId: effectiveActionId }),
      }
    );
  },

  // Admin: Centralized status overview of projects assigned exclusively to Engineers
  async getEngineerProjectStatuses(filter?: {
    status?: string;
    engineerId?: string;
  }): Promise<EngineerProjectStatusItem[]> {
    const params = new URLSearchParams();
    if (filter?.status && filter.status !== 'ALL') params.set('status', filter.status);
    if (filter?.engineerId) params.set('engineerId', filter.engineerId);
    const qs = params.toString() ? `?${params.toString()}` : '';

    try {
      const res = await fetchApi<EngineerProjectStatusItem[]>(`/api/admin/engineers/project-statuses${qs}`);
      if (Array.isArray(res)) return res;
      return [];
    } catch {
      // Graceful local aggregation fallback for test environments or offline mode
      const [allProjects, allUsers] = await Promise.all([
        this.getProjects().catch(() => []),
        this.getUsers('CLIENT').catch(() => []),
      ]);
      const engineerMap = new Map(allUsers.map((u) => [u.id, u]));

      let engineerProjects = allProjects.filter((p) => {
        const eng = engineerMap.get(p.client_id);
        const isNotStudent = !p.is_training_project || p.is_training_project === 0;
        return !!eng && isNotStudent;
      });

      if (filter?.status && filter.status !== 'ALL') {
        engineerProjects = engineerProjects.filter((p) => p.status === filter.status);
      }
      if (filter?.engineerId) {
        engineerProjects = engineerProjects.filter((p) => p.client_id === filter.engineerId);
      }

      return engineerProjects.map((p) => {
        const eng = engineerMap.get(p.client_id);
        return {
          project_id: p.id,
          project_name: p.project_name,
          drawing_name: p.drawing_name,
          drawing_type: p.drawing_type,
          project_area: p.project_area,
          project_address: p.project_address,
          project_status: p.status,
          engineer_id: p.client_id,
          engineer_identification_number: eng?.identification_number,
          engineer_name: eng?.name || eng?.email || p.client_name || 'Engineer',
          engineer_email: eng?.email || p.client_email || '',
          engineer_company: eng?.company_name,
          engineer_mobile: eng?.mobile,
          current_assignment_id: p.current_assignment_id,
          assigned_at: p.assigned_at,
          submitted_at: p.submitted_at,
          approved_at: p.approved_at,
          rejected_at: p.rejected_at,
          cancelled_at: p.cancelled_at,
          created_at: p.created_at,
          correction_round: p.correction_round,
          draughtsman_id: p.draughtsman_id,
          draughtsman_name: p.draughtsman_name,
          last_updated_at: p.approved_at || p.assigned_at || p.submitted_at || p.created_at,
        };
      });
    }
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
    } catch (err: any) {
      if (err?.status === 404) return [];
      throw err;
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
    category: 'client_upload' | 'correction_attachment' | 'chat_attachment' | 'message_attachment' | 'reference' | 'specification' = 'client_upload',
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

  // ══════════════════════════════════════════════════════════════════════════
  // TEACHING STUDENTS — Modules, Chapters, Lessons, Learning Plans & Progress
  // ══════════════════════════════════════════════════════════════════════════

  // Modules CRUD & Publication
  async getTrainingModules(params?: { category?: string; status?: string; search?: string }): Promise<TrainingModule[]> {
    const query = new URLSearchParams();
    if (params?.category && params.category !== 'ALL') query.set('category', params.category);
    if (params?.status && params.status !== 'ALL') query.set('status', params.status);
    if (params?.search) query.set('search', params.search);
    const qs = query.toString() ? `?${query.toString()}` : '';
    return fetchApi<TrainingModule[]>(`/api/admin/training/modules${qs}`);
  },

  async getTrainingModule(moduleId: string): Promise<{ module: TrainingModule; chapters: TrainingChapter[]; lessons: TrainingLesson[] }> {
    return fetchApi<{ module: TrainingModule; chapters: TrainingChapter[]; lessons: TrainingLesson[] }>(`/api/admin/training/modules/${moduleId}`);
  },

  async createTrainingModule(
    payload: Partial<TrainingModule> & {
      assign_to_student_id?: string;
      target_completion_date?: string | null;
      assignment_instructions?: string;
    }
  ): Promise<{
    success: boolean;
    id: string;
    module: TrainingModule;
    assignment?: {
      assigned: boolean;
      plan_id: string;
      student_id: string;
      student_name: string;
    };
  }> {
    return fetchApi<{
      success: boolean;
      id: string;
      module: TrainingModule;
      assignment?: {
        assigned: boolean;
        plan_id: string;
        student_id: string;
        student_name: string;
      };
    }>('/api/admin/training/modules', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async updateTrainingModule(moduleId: string, payload: Partial<TrainingModule>): Promise<{ success: boolean; module: TrainingModule }> {
    return fetchApi<{ success: boolean; module: TrainingModule }>(`/api/admin/training/modules/${moduleId}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  async deleteTrainingModule(moduleId: string): Promise<{ success: boolean; archived: boolean }> {
    return fetchApi<{ success: boolean; archived: boolean }>(`/api/admin/training/modules/${moduleId}`, {
      method: 'DELETE',
    });
  },

  // Chapters Management
  async createTrainingChapter(
    moduleId: string,
    payload: { title: string; description?: string; chapter_order?: number; id?: string }
  ): Promise<{ success: boolean; id: string; chapter: TrainingChapter }> {
    return fetchApi<{ success: boolean; id: string; chapter: TrainingChapter }>(`/api/admin/training/modules/${moduleId}/chapters`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async updateTrainingChapter(
    chapterId: string,
    payload: { title?: string; description?: string; chapter_order?: number }
  ): Promise<{ success: boolean; chapter: TrainingChapter }> {
    return fetchApi<{ success: boolean; chapter: TrainingChapter }>(`/api/admin/training/chapters/${chapterId}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  async deleteTrainingChapter(chapterId: string): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/admin/training/chapters/${chapterId}`, {
      method: 'DELETE',
    });
  },

  // Lessons Management
  async createTrainingLesson(
    moduleId: string,
    payload: {
      title: string;
      content?: string;
      chapter_id?: string | null;
      video_url?: string | null;
      resources?: LessonResource[];
      resources_json?: string;
      is_required?: boolean | number;
      lesson_order?: number;
      estimated_duration?: string;
      id?: string;
    }
  ): Promise<{ success: boolean; id: string; lesson: TrainingLesson }> {
    return fetchApi<{ success: boolean; id: string; lesson: TrainingLesson }>(`/api/admin/training/modules/${moduleId}/lessons`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async updateTrainingLesson(
    lessonId: string,
    payload: {
      title?: string;
      content?: string;
      chapter_id?: string | null;
      video_url?: string | null;
      resources?: LessonResource[];
      resources_json?: string;
      is_required?: boolean | number;
      lesson_order?: number;
      estimated_duration?: string;
    }
  ): Promise<{ success: boolean; lesson: TrainingLesson }> {
    return fetchApi<{ success: boolean; lesson: TrainingLesson }>(`/api/admin/training/lessons/${lessonId}`, {
      method: 'PUT',
      body: JSON.stringify(payload),
    });
  },

  async deleteTrainingLesson(lessonId: string): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/admin/training/lessons/${lessonId}`, {
      method: 'DELETE',
    });
  },

  // Student Learning Plans
  async getAllLearningPlans(params?: { studentId?: string; moduleId?: string; status?: string }): Promise<StudentLearningPlan[]> {
    const query = new URLSearchParams();
    if (params?.studentId) query.set('studentId', params.studentId);
    if (params?.moduleId) query.set('moduleId', params.moduleId);
    if (params?.status) query.set('status', params.status);
    const qs = query.toString() ? `?${query.toString()}` : '';
    return fetchApi<StudentLearningPlan[]>(`/api/admin/learning-plans${qs}`);
  },

  async getStudentLearningPlans(studentId: string): Promise<StudentLearningPlan[]> {
    return fetchApi<StudentLearningPlan[]>(`/api/admin/students/${studentId}/learning-plans`);
  },

  async assignLearningPlan(
    studentId: string,
    payload: {
      moduleIds: string[];
      targetCompletionDate?: string | null;
      instructions?: string;
      selectedChapters?: string[];
      selectedLessons?: string[];
    }
  ): Promise<{ success: boolean; count: number; plans: StudentLearningPlan[] }> {
    return fetchApi<{ success: boolean; count: number; plans: StudentLearningPlan[] }>(`/api/admin/students/${studentId}/learning-plans`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async revokeLearningPlan(planId: string): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/admin/learning-plans/${planId}`, {
      method: 'DELETE',
    });
  },

  // Student Progress Monitoring
  async getStudentsProgress(params?: { search?: string; status?: string }): Promise<StudentProgressSummary[]> {
    const query = new URLSearchParams();
    if (params?.search) query.set('search', params.search);
    if (params?.status && params.status !== 'ALL') query.set('status', params.status);
    const qs = query.toString() ? `?${query.toString()}` : '';
    return fetchApi<StudentProgressSummary[]>(`/api/admin/students-progress${qs}`);
  },

  async getStudentProgressDetail(studentId: string): Promise<StudentProgressDetail> {
    return fetchApi<StudentProgressDetail>(`/api/admin/students/${studentId}/progress-detail`);
  },

  // ── Notifications Feed & Actions ──
  async getNotifications(): Promise<AdminNotification[]> {
    try {
      const data = await fetchApi<AdminNotification[]>('/api/notifications');
      return Array.isArray(data) ? data : [];
    } catch {
      return [];
    }
  },

  async markNotificationRead(id: string): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/notifications/${id}/read`, {
      method: 'PATCH',
    });
  },

  async markAllNotificationsRead(): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>('/api/notifications/read-all', {
      method: 'PATCH',
    });
  },

  async clearNotification(id: string): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/notifications/${id}`, {
      method: 'DELETE',
    });
  },

  // ── Registration Verification Provision ──
  async getRegistrations(params?: { search?: string; role?: string; status?: string }): Promise<RegistrationVerification[]> {
    const query = new URLSearchParams();
    if (params?.search) query.set('search', params.search);
    if (params?.role && params.role !== 'ALL') query.set('role', params.role);
    if (params?.status && params.status !== 'ALL') query.set('status', params.status);
    const qs = query.toString() ? `?${query.toString()}` : '';
    return fetchApi<RegistrationVerification[]>(`/api/admin/registrations${qs}`);
  },

  async getRegistration(id: string): Promise<RegistrationVerification> {
    return fetchApi<RegistrationVerification>(`/api/admin/registrations/${id}`);
  },

  async approveRegistration(id: string): Promise<{ success: boolean; registration: RegistrationVerification }> {
    return fetchApi<{ success: boolean; registration: RegistrationVerification }>(`/api/admin/registrations/${id}/approve`, {
      method: 'POST',
    });
  },

  async rejectRegistration(id: string, reason: string): Promise<{ success: boolean; registration: RegistrationVerification }> {
    return fetchApi<{ success: boolean; registration: RegistrationVerification }>(`/api/admin/registrations/${id}/reject`, {
      method: 'POST',
      body: JSON.stringify({ reason }),
    });
  },

  async getRegistrationProofBlob(id: string): Promise<Blob> {
    const token = await getAuthToken();
    const headers: Record<string, string> = {};
    if (token) headers['Authorization'] = `Bearer ${token}`;
    const url = `${API_BASE}/api/admin/registrations/${id}/proof`;
    const res = await fetch(url, { headers });
    if (!res.ok) {
      throw new ApiError('Failed to download proof document', res.status);
    }
    return await res.blob();
  },

  getRegistrationProofUrl(id: string, token?: string): string {
    const base = `${API_BASE}/api/admin/registrations/${id}/proof`;
    return token ? `${base}?token=${encodeURIComponent(token)}` : base;
  },

  // ==========================================
  // HELPDESK & INCIDENT MANAGEMENT SYSTEM
  // ==========================================

  // Report technical incident beacon (Client-side, React errors, unhandled rejections)
  async reportIncident(incident: {
    title: string;
    category?: string;
    severity?: 'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW';
    source?: string;
    affected_module?: string;
    error_message: string;
    error_code?: string;
    stack_trace?: string;
    page_route?: string;
  }): Promise<{ success: boolean; ticketId?: string; isNew?: boolean }> {
    try {
      return await fetchApi<{ success: boolean; ticketId?: string; isNew?: boolean }>('/api/helpdesk/report', {
        method: 'POST',
        body: JSON.stringify({
          source: 'ADMIN_PANEL',
          category: 'FRONTEND',
          severity: 'MEDIUM',
          page_route: typeof window !== 'undefined' ? window.location.pathname : undefined,
          browser: typeof navigator !== 'undefined' ? navigator.userAgent : undefined,
          ...incident,
        }),
      });
    } catch {
      return { success: false };
    }
  },

  // Submit manual user support ticket
  async submitUserTicket(payload: {
    subject: string;
    description: string;
    category?: string;
    affected_feature?: string;
    priority_suggestion?: string;
    screenshot_url?: string;
    user_email?: string;
    contact_email?: string;
    page_route?: string;
  }): Promise<{ success: boolean; ticketId: string; message: string }> {
    return fetchApi<{ success: boolean; ticketId: string; message: string }>('/api/helpdesk/tickets', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  // Get current user's submitted tickets
  async getMyTickets(): Promise<HelpdeskTicket[]> {
    return fetchApi<HelpdeskTicket[]>('/api/helpdesk/my-tickets');
  },

  // Admin: Help Desk telemetry stats
  async getHelpdeskStats(): Promise<HelpdeskStats> {
    return fetchApi<HelpdeskStats>('/api/admin/helpdesk/stats');
  },

  // Admin: List tickets with filtering, search, pagination
  async getHelpdeskTickets(params?: {
    status?: string;
    severity?: string;
    category?: string;
    source?: string;
    search?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ tickets: HelpdeskTicket[]; total: number; limit: number; offset: number }> {
    const query = new URLSearchParams();
    if (params?.status && params.status !== 'ALL') query.set('status', params.status);
    if (params?.severity && params.severity !== 'ALL') query.set('severity', params.severity);
    if (params?.category && params.category !== 'ALL') query.set('category', params.category);
    if (params?.source && params.source !== 'ALL') query.set('source', params.source);
    if (params?.search) query.set('search', params.search);
    if (params?.limit) query.set('limit', String(params.limit));
    if (params?.offset) query.set('offset', String(params.offset));
    const qs = query.toString() ? '?' + query.toString() : '';
    return fetchApi<{ tickets: HelpdeskTicket[]; total: number; limit: number; offset: number }>('/api/admin/helpdesk/tickets' + qs);
  },

  // Admin: Get single ticket with timeline, comments, and email logs
  async getHelpdeskTicket(id: string): Promise<{
    ticket: HelpdeskTicket;
    events: HelpdeskEvent[];
    comments: HelpdeskComment[];
    email_logs: HelpdeskEmailLog[];
  }> {
    return fetchApi<{
      ticket: HelpdeskTicket;
      events: HelpdeskEvent[];
      comments: HelpdeskComment[];
      email_logs: HelpdeskEmailLog[];
    }>('/api/admin/helpdesk/tickets/' + id);
  },

  // Admin: Update ticket status, severity, assignment, or resolution notes
  async updateHelpdeskTicket(
    id: string,
    updates: {
      status?: string;
      severity?: string;
      assigned_to?: string | null;
      assigned_to_name?: string | null;
      resolution_notes?: string;
    }
  ): Promise<{ success: boolean; ticket: HelpdeskTicket }> {
    return fetchApi<{ success: boolean; ticket: HelpdeskTicket }>('/api/admin/helpdesk/tickets/' + id, {
      method: 'PATCH',
      body: JSON.stringify(updates),
    });
  },

  // Admin: Post internal note or comment on ticket
  async addHelpdeskComment(ticketId: string, comment: string, isInternal = true): Promise<{ success: boolean; commentId: string }> {
    return fetchApi<{ success: boolean; commentId: string }>('/api/admin/helpdesk/tickets/' + ticketId + '/comments', {
      method: 'POST',
      body: JSON.stringify({ comment, is_internal: isInternal }),
    });
  },

  // Admin: Run self-healing diagnostics
  async runHelpdeskSelfHealing(ticketId?: string): Promise<{ success: boolean; actionsTaken: string[]; recovered: boolean }> {
    return fetchApi<{ success: boolean; actionsTaken: string[]; recovered: boolean }>('/api/admin/helpdesk/heal', {
      method: 'POST',
      body: JSON.stringify({ ticketId }),
    });
  },

  // Admin: Get live system health diagnostics
  async getHelpdeskHealth(): Promise<HelpdeskHealthReport> {
    return fetchApi<HelpdeskHealthReport>('/api/admin/helpdesk/health');
  },

  async getHelpdeskHealthReport(): Promise<HelpdeskHealthReport> {
    return this.getHelpdeskHealth();
  },

  // Admin: Get email notification logs
  async getHelpdeskEmailLogs(params?: {
    status?: string;
    limit?: number;
    offset?: number;
  }): Promise<{ logs: HelpdeskEmailLog[]; total: number; limit: number; offset: number }> {
    const query = new URLSearchParams();
    if (params?.status && params.status !== 'ALL') query.set('status', params.status);
    if (params?.limit) query.set('limit', String(params.limit));
    if (params?.offset) query.set('offset', String(params.offset));
    const qs = query.toString() ? '?' + query.toString() : '';
    return fetchApi<{ logs: HelpdeskEmailLog[]; total: number; limit: number; offset: number }>('/api/admin/helpdesk/email-logs' + qs);
  },

  // Admin: Retry failed email delivery
  async retryHelpdeskEmail(logId: string): Promise<{ success: boolean; status: string; error?: string }> {
    return fetchApi<{ success: boolean; status: string; error?: string }>('/api/admin/helpdesk/email-logs/' + logId + '/retry', {
      method: 'POST',
    });
  },

  // Admin: Retrieve configurable settings
  async getHelpdeskSettings(): Promise<HelpdeskSettings> {
    return fetchApi<HelpdeskSettings>('/api/admin/helpdesk/settings');
  },

  // Admin: Update settings
  async updateHelpdeskSettings(settings: Partial<HelpdeskSettings>): Promise<{ success: boolean; settings: HelpdeskSettings }> {
    return fetchApi<{ success: boolean; settings: HelpdeskSettings }>('/api/admin/helpdesk/settings', {
      method: 'PUT',
      body: JSON.stringify(settings),
    });
  },

  // Admin: Delete a single ticket
    // Admin: Delete a single ticket
  async deleteHelpdeskTicket(ticketId: string): Promise<{ success: boolean; id: string }> {
    return fetchApi<{ success: boolean; id: string }>('/api/admin/helpdesk/tickets/' + ticketId, {
      method: 'DELETE',
    });
  },

  async clearAllNotifications(): Promise<{ success: boolean }> {
    try {
      return await fetchApi<{ success: boolean }>('/api/notifications', {
        method: 'DELETE',
      });
    } catch {
      return await fetchApi<{ success: boolean }>('/api/notifications/clear', {
        method: 'POST',
      });
    }

  },
// Admin: Bulk delete tickets or clear all
  async bulkDeleteHelpdeskTickets(payload: { ids?: string[]; clearAll?: boolean }): Promise<{ success: boolean; count?: number; message?: string }> {
    return fetchApi<{ success: boolean; count?: number; message?: string }>('/api/admin/helpdesk/tickets/bulk-delete', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  // Admin: Trigger test email notification
  async sendHelpdeskTestEmail(recipient?: string): Promise<{ success: boolean; status: string; error?: string; messageId?: string }> {
    return fetchApi<{ success: boolean; status: string; error?: string; messageId?: string }>('/api/admin/helpdesk/settings/test-email', {
      method: 'POST',
      body: JSON.stringify({ recipient }),
    });
  },

  // ============================================================================
  // PIXMINT BOT 2.0 ADMINISTRATION API
  // ============================================================================

  async getBotHealth(): Promise<AdminHealthData> {
    return fetchApi<AdminHealthData>('/api/pixmint/admin/health');
  },

  async getBotAnalytics(): Promise<AdminAnalyticsData> {
    return fetchApi<AdminAnalyticsData>('/api/pixmint/admin/analytics');
  },

  async getBotConfig(): Promise<{ config: BotConfigData }> {
    return fetchApi<{ config: BotConfigData }>('/api/pixmint/admin/config');
  },

  async updateBotConfig(payload: Partial<BotConfigData>): Promise<{ success: boolean; config: BotConfigData }> {
    return fetchApi<{ success: boolean; config: BotConfigData }>('/api/pixmint/admin/config', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async getBotKnowledgeSources(): Promise<{ sources: KnowledgeSourceItem[] }> {
    return fetchApi<{ sources: KnowledgeSourceItem[] }>('/api/pixmint/admin/knowledge/sources');
  },

  async updateBotKnowledgeSourceStatus(
    id: string,
    status: 'approved' | 'deactivated'
  ): Promise<{ success: boolean; sourceId: string; status: string; message: string }> {
    return fetchApi<{ success: boolean; sourceId: string; status: string; message: string }>(
      `/api/pixmint/admin/knowledge/sources/${encodeURIComponent(id)}/status`,
      {
        method: 'POST',
        body: JSON.stringify({ status }),
      }
    );
  },

  async getBotSuggestions(role: string): Promise<{ role: string; suggestions: RemoteSuggestion[] }> {
    const res = await fetchApi<RemoteSuggestion[] | { role: string; suggestions: RemoteSuggestion[] }>(
      `/api/pixmint/admin/suggestions?role=${encodeURIComponent(role)}`
    ).catch(() =>
      fetchApi<RemoteSuggestion[] | { role: string; suggestions: RemoteSuggestion[] }>(
        `/api/pixmint/chat/suggestions?role=${encodeURIComponent(role)}`
      )
    );
    if (Array.isArray(res)) {
      return { role, suggestions: res };
    }
    return res || { role, suggestions: [] };
  },

  async createBotSuggestion(data: { role: string; label: string; prompt: string; icon?: string; sortOrder?: number }): Promise<{ success: boolean; suggestion: RemoteSuggestion }> {
    return fetchApi<{ success: boolean; suggestion: RemoteSuggestion }>('/api/pixmint/admin/suggestions', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async updateBotSuggestion(id: string, data: Partial<RemoteSuggestion>): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/pixmint/admin/suggestions/${encodeURIComponent(id)}`, {
      method: 'PUT',
      body: JSON.stringify(data),
    });
  },

  async deleteBotSuggestion(id: string): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/pixmint/admin/suggestions/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    });
  },

  async uploadBotKnowledgeDocument(data: { title: string; category: string; content: string; allowedRoles?: string[] }): Promise<{ success: boolean; document: KnowledgeSourceItem }> {
    return fetchApi<{ success: boolean; document: KnowledgeSourceItem }>('/api/pixmint/admin/knowledge/documents', {
      method: 'POST',
      body: JSON.stringify(data),
    });
  },

  async deleteBotKnowledgeDocument(id: string): Promise<{ success: boolean }> {
    return fetchApi<{ success: boolean }>(`/api/pixmint/admin/knowledge/documents/${encodeURIComponent(id)}`, {
      method: 'DELETE',
    });
  },

  async getBotConversations(limit = 50, offset = 0): Promise<{ conversations: ConversationSessionItem[] }> {
    return fetchApi<{ conversations: ConversationSessionItem[] }>(
      `/api/pixmint/admin/conversations?limit=${limit}&offset=${offset}`
    );
  },

  async getBotConversationMessages(sessionId: string): Promise<{ messages: ConversationMessageItem[] }> {
    return fetchApi<{ messages: ConversationMessageItem[] }>(
      `/api/pixmint/admin/conversations/${encodeURIComponent(sessionId)}/messages`
    );
  },

  async getBotFeedback(limit = 50): Promise<{ feedback: FeedbackItem[]; total: number }> {
    return fetchApi<{ feedback: FeedbackItem[]; total: number }>(`/api/pixmint/admin/feedback?limit=${limit}`);
  },

  async getBotUnanswered(limit = 50): Promise<{ questions: UnansweredItem[]; total: number }> {
    return fetchApi<{ questions: UnansweredItem[]; total: number }>(`/api/pixmint/admin/unanswered?limit=${limit}`);
  },

  async getBotAuditLogs(
    limit = 50,
    offset = 0,
    action?: string
  ): Promise<{ logs: AuditLogItem[]; total: number }> {
    const q = new URLSearchParams({ limit: String(limit), offset: String(offset) });
    if (action) q.set('action', action);
    return fetchApi<{ logs: AuditLogItem[]; total: number }>(`/api/pixmint/admin/audit-logs?${q.toString()}`);
  },

  async getBotQuestionAnalytics(filter?: QuestionAnalyticsFilter): Promise<QuestionAnalyticsData> {
    const q = new URLSearchParams();
    if (filter?.portal && filter.portal !== 'all') q.set('portal', filter.portal);
    if (filter?.timeRange) q.set('timeRange', filter.timeRange);
    if (filter?.startDate) q.set('startDate', filter.startDate);
    if (filter?.endDate) q.set('endDate', filter.endDate);
    if (filter?.search) q.set('search', filter.search);
    const qs = q.toString() ? `?${q.toString()}` : '';
    return fetchApi<QuestionAnalyticsData>(`/api/pixmint/admin/question-analytics${qs}`);
  },

  // ── PIXMINT BOT 2.0 INTERACTIVE CHAT CLIENT API ───────────────────────────
  async getBotChatStatus(): Promise<{ status: string; version: string; timestamp: number }> {
    return fetchApi<{ status: string; version: string; timestamp: number }>('/api/pixmint/chat/status');
  },

  async getOrCreateBotChatSession(params?: {
    title?: string;
    newSession?: boolean;
    sessionId?: string;
  }): Promise<ConversationSessionItem> {
    return fetchApi<ConversationSessionItem>('/api/pixmint/chat/sessions', {
      method: 'POST',
      body: JSON.stringify(params || {}),
    });
  },

  async getBotChatSuggestions(role = 'admin'): Promise<RemoteSuggestion[]> {
    return fetchApi<RemoteSuggestion[]>(`/api/pixmint/chat/suggestions?role=${encodeURIComponent(role)}`);
  },

  async getBotChatSessionMessages(sessionId: string): Promise<ConversationMessageItem[]> {
    return fetchApi<ConversationMessageItem[]>(`/api/pixmint/chat/sessions/${encodeURIComponent(sessionId)}/messages`);
  },

  async sendBotChatMessage(sessionId: string, message: string): Promise<ConversationMessageItem> {
    return fetchApi<ConversationMessageItem>(`/api/pixmint/chat/sessions/${encodeURIComponent(sessionId)}/messages`, {
      method: 'POST',
      body: JSON.stringify({ content: message, message }),
    });
  },

  async submitBotChatFeedback(payload: {
    messageId: string;
    rating: 1 | -1;
    feedbackText?: string;
  }): Promise<{ success: boolean; message?: string }> {
    return fetchApi<{ success: boolean; message?: string }>('/api/pixmint/chat/feedback', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  // =========================================================================
  // LEGAL & COMPLIANCE SYSTEM API METHODS (PHASE 4)
  // =========================================================================

  async getLegalStats(): Promise<LegalComplianceStats> {
    return fetchApi<LegalComplianceStats>('/api/admin/legal/stats');
  },

  async getLegalBusinessProfile(): Promise<LegalBusinessProfile> {
    return fetchApi<LegalBusinessProfile>('/api/legal/business-profile');
  },

  async getLegalDocuments(): Promise<{ documents: LegalDocumentAdmin[] }> {
    return fetchApi<{ documents: LegalDocumentAdmin[] }>('/api/admin/legal/documents');
  },

  async createLegalDocumentDraft(payload: {
    documentType: string;
    version: string;
    title: string;
    content: string;
    effectiveAt?: string;
    isMandatory?: boolean;
    locale?: string;
    changeSummary?: string;
  }): Promise<{ success: boolean; documentId: string; status: string }> {
    return fetchApi<{ success: boolean; documentId: string; status: string }>('/api/admin/legal/documents', {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async publishLegalDocument(id: string): Promise<{ success: boolean; documentId: string; status: string }> {
    return fetchApi<{ success: boolean; documentId: string; status: string }>(`/api/admin/legal/documents/${encodeURIComponent(id)}/publish`, {
      method: 'POST',
    });
  },

  async getLegalPrivacyRequests(status?: string): Promise<{ requests: AdminPrivacyRequest[] }> {
    const q = status ? `?status=${encodeURIComponent(status)}` : '';
    return fetchApi<{ requests: AdminPrivacyRequest[] }>(`/api/admin/legal/privacy-requests${q}`);
  },

  async resolveLegalPrivacyRequest(
    id: string,
    payload: { status: 'ACKNOWLEDGED' | 'RESOLVED' | 'REJECTED'; resolutionNotes?: string }
  ): Promise<{ success: boolean; requestId: string; status: string }> {
    return fetchApi<{ success: boolean; requestId: string; status: string }>(`/api/admin/legal/privacy-requests/${encodeURIComponent(id)}/resolve`, {
      method: 'POST',
      body: JSON.stringify(payload),
    });
  },

  async getLegalConsentEvents(limit = 50, offset = 0): Promise<{ events: AdminConsentEvent[]; count: number }> {
    return fetchApi<{ events: AdminConsentEvent[]; count: number }>(`/api/admin/legal/consents?limit=${limit}&offset=${offset}`);
  },

  async getLegalAccountDeletionRequests(status?: string): Promise<{ requests: AdminAccountDeletionRequest[] }> {
    const q = status ? `?status=${encodeURIComponent(status)}` : '';
    return fetchApi<{ requests: AdminAccountDeletionRequest[] }>(`/api/admin/legal/account-deletion-requests${q}`);
  },

  async updateLegalAccountDeletionRequest(
    id: string,
    payload: {
      status: string;
      reviewNotes?: string;
      retentionHoldReason?: string;
      failureDetails?: string;
    }
  ): Promise<{ success: boolean; requestId: string; status: string; systemsProcessed?: string }> {
    return fetchApi<{ success: boolean; requestId: string; status: string; systemsProcessed?: string }>(`/api/admin/legal/account-deletion-requests/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },

  async getLegalDataExportRequests(): Promise<{ requests: AdminDataExportRequest[] }> {
    return fetchApi<{ requests: AdminDataExportRequest[] }>('/api/admin/legal/data-export-requests');
  },

  async updateLegalDataExportRequest(
    id: string,
    payload: { status: string; failureDetails?: string }
  ): Promise<{ success: boolean; requestId: string; status: string }> {
    return fetchApi<{ success: boolean; requestId: string; status: string }>(`/api/admin/legal/data-export-requests/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },

  async getLegalDataCorrectionRequests(): Promise<{ requests: AdminDataCorrectionRequest[] }> {
    return fetchApi<{ requests: AdminDataCorrectionRequest[] }>('/api/admin/legal/data-correction-requests');
  },

  async updateLegalDataCorrectionRequest(
    id: string,
    payload: { status: 'RESOLVED' | 'REJECTED'; reviewNotes?: string; applyToUser?: boolean }
  ): Promise<{ success: boolean; requestId: string; status: string }> {
    return fetchApi<{ success: boolean; requestId: string; status: string }>(`/api/admin/legal/data-correction-requests/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },

  async getLegalGuardianConsents(): Promise<{ guardianConsents: AdminGuardianConsent[] }> {
    return fetchApi<{ guardianConsents: AdminGuardianConsent[] }>('/api/admin/legal/guardian-consents');
  },

  async updateLegalGuardianConsent(
    id: string,
    payload: { status: 'VERIFIED' | 'REJECTED' | 'WITHDRAWN' | 'EXPIRED'; notes?: string }
  ): Promise<{ success: boolean; consentId: string; status: string }> {
    return fetchApi<{ success: boolean; consentId: string; status: string }>(`/api/admin/legal/guardian-consents/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },

  async getLegalCancellationRefundRequests(): Promise<{ refundRequests: AdminCancellationRefundRequest[] }> {
    return fetchApi<{ refundRequests: AdminCancellationRefundRequest[] }>('/api/admin/legal/cancellation-refund-requests');
  },

  async updateLegalCancellationRefundRequest(
    id: string,
    payload: {
      status: string;
      amountApproved?: number;
      reviewDecision?: string;
      resolutionNotes?: string;
      refundTransactionRef?: string;
    }
  ): Promise<{ success: boolean; requestId: string; status: string }> {
    return fetchApi<{ success: boolean; requestId: string; status: string }>(`/api/admin/legal/cancellation-refund-requests/${encodeURIComponent(id)}`, {
      method: 'PATCH',
      body: JSON.stringify(payload),
    });
  },

  async getLegalRetentionPolicies(): Promise<{ retentionPolicies: DataRetentionPolicy[] }> {
    return fetchApi<{ retentionPolicies: DataRetentionPolicy[] }>('/api/admin/legal/retention-policies');
  },
};

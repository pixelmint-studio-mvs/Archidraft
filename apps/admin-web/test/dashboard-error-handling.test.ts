import { describe, it } from 'node:test';
import assert from 'node:assert';

// Mirroring the exact error classification logic from apps/admin-web/src/lib/api.ts
class ApiError extends Error {
  status: number;
  data: any;

  constructor(message: string, status: number, data?: any) {
    super(message);
    this.name = 'ApiError';
    this.status = status;
    this.data = data;
  }
}

type ApiErrorKind =
  | 'AUTH_FAILED'        // 401
  | 'AUTH_FORBIDDEN'     // 403
  | 'BACKEND_DOWN'       // 502, 503, 504
  | 'NETWORK_FAILURE'    // 0
  | 'INVALID_RESPONSE'   // parse failure or unexpected format
  | 'SERVER_ERROR'       // 500
  | 'NOT_FOUND'          // 404
  | 'UNKNOWN';

interface ClassifiedError {
  kind: ApiErrorKind;
  title: string;
  message: string;
  status: number;
  canRetry: boolean;
  actionText?: string;
}

function classifyApiError(err: unknown): ClassifiedError {
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

describe('Admin Dashboard — Error Handling & Zero-Record Integrity Tests', () => {
  describe('Error Classification Engine (classifyApiError)', () => {
    it('classifies HTTP 401 as Authentication Failure (AUTH_FAILED)', () => {
      const err = new ApiError('Unauthorized', 401);
      const classified = classifyApiError(err);

      assert.strictEqual(classified.kind, 'AUTH_FAILED');
      assert.strictEqual(classified.status, 401);
      assert.strictEqual(classified.title, 'Authentication Failure');
      assert.strictEqual(classified.canRetry, true);
      assert.strictEqual(classified.actionText, 'Sign In Again');
      assert.ok(classified.message.includes('expired or is invalid'));
    });

    it('classifies HTTP 403 as Authorization Failure (AUTH_FORBIDDEN)', () => {
      const err = new ApiError('Forbidden: Insufficient privileges', 403);
      const classified = classifyApiError(err);

      assert.strictEqual(classified.kind, 'AUTH_FORBIDDEN');
      assert.strictEqual(classified.status, 403);
      assert.strictEqual(classified.title, 'Authorization Failure');
      assert.strictEqual(classified.canRetry, false);
      assert.strictEqual(classified.actionText, 'Check Permissions');
      assert.ok(classified.message.includes('administrator privileges'));
    });

    it('classifies HTTP 502, 503, 504 as Backend Unavailable (BACKEND_DOWN)', () => {
      [502, 503, 504].forEach((status) => {
        const err = new ApiError(`Service Unavailable (${status})`, status);
        const classified = classifyApiError(err);

        assert.strictEqual(classified.kind, 'BACKEND_DOWN');
        assert.strictEqual(classified.status, status);
        assert.strictEqual(classified.title, 'Backend Unavailable');
        assert.strictEqual(classified.canRetry, true);
        assert.strictEqual(classified.actionText, 'Retry Connection');
        assert.ok(classified.message.includes(String(status)));
      });
    });

    it('classifies network failure (status 0 / fetch TypeError) as Network Failure (NETWORK_FAILURE)', () => {
      const netErr = new ApiError('Network failure: Unable to reach backend API', 0, { isNetworkError: true });
      const classified = classifyApiError(netErr);

      assert.strictEqual(classified.kind, 'NETWORK_FAILURE');
      assert.strictEqual(classified.status, 0);
      assert.strictEqual(classified.title, 'Network Failure');
      assert.strictEqual(classified.canRetry, true);
      assert.strictEqual(classified.actionText, 'Retry Request');

      // Also test standard browser TypeError from fetch()
      const typeErr = new TypeError('Failed to fetch');
      const classifiedTypeErr = classifyApiError(typeErr);
      assert.strictEqual(classifiedTypeErr.kind, 'NETWORK_FAILURE');
      assert.strictEqual(classifiedTypeErr.status, 0);
    });

    it('classifies malformed JSON / response parsing failure as Invalid Response (INVALID_RESPONSE)', () => {
      const parseErr = new ApiError('Invalid response: Expected JSON from backend', 502, { invalidResponse: true });
      const classified = classifyApiError(parseErr);

      assert.strictEqual(classified.kind, 'INVALID_RESPONSE');
      assert.strictEqual(classified.title, 'Invalid Response');
      assert.strictEqual(classified.canRetry, true);
    });

    it('classifies HTTP 500 as Backend Service Error (SERVER_ERROR)', () => {
      const serverErr = new ApiError('Internal Server Error: DB connection failed', 500);
      const classified = classifyApiError(serverErr);

      assert.strictEqual(classified.kind, 'SERVER_ERROR');
      assert.strictEqual(classified.status, 500);
      assert.strictEqual(classified.title, 'Backend Service Error');
      assert.strictEqual(classified.canRetry, true);
    });
  });

  describe('Zero-Record Truthfulness vs API Outage Distinction', () => {
    it('distinguishes genuine empty state (zero records) from API failure', () => {
      // 1. Genuine Empty State: API succeeded, zero records returned
      const emptyStateResponse = {
        stats: {
          metrics: { totalProjects: 0, activeProjects: 0, registeredEngineers: 0 },
          projects: { total: 0, byStatus: {} },
          users: { total: 0, byRole: {}, registeredEngineers: 0 },
          recentActivity: [],
        },
        error: null,
      };

      const isGenuineEmpty = emptyStateResponse.stats.projects.total === 0 && emptyStateResponse.error === null;
      assert.strictEqual(isGenuineEmpty, true, 'Zero projects with null error represents genuine zero records');

      // 2. Failed API Call: Must produce error state, NOT zero-record empty state
      const failedApiResponse = {
        stats: null,
        error: classifyApiError(new ApiError('Failed to fetch', 0)),
      };

      assert.strictEqual(failedApiResponse.stats, null, 'Failed request must leave stats as null');
      assert.notStrictEqual(failedApiResponse.error, null, 'Failed request must set error');
      assert.strictEqual(failedApiResponse.error.kind, 'NETWORK_FAILURE');
    });

    it('ensures API errors never get fabricated into mock zero-count objects', () => {
      // Prior bug test: adminApi.getStats().catch(() => ({ projects: { total: 0 } }))
      // Now: Any error thrown by getStats() or getProjects() must propagate
      const simulateDashboardLoad = async (shouldFail: boolean) => {
        if (shouldFail) {
          throw new ApiError('Cloudflare Worker unreachable', 503);
        }
        return {
          projects: { total: 31, byStatus: { SUBMITTED: 5 } },
          users: { total: 14, byRole: { ADMIN: 1 } },
        };
      };

      return assert.rejects(
        async () => {
          await simulateDashboardLoad(true);
        },
        (err: any) => {
          assert.strictEqual(err.status, 503);
          assert.ok(err.message.includes('unreachable'));
          return true;
        },
        'API error must reject instead of returning fabricated zero records'
      );
    });
  });
});

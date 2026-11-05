'use client';

import React, { useEffect } from 'react';
import { adminApi } from '@/lib/api';

/**
 * Global Error Monitoring Provider for Client Runtime
 * Captures unhandled window errors and promise rejections across Admin Web.
 */
export function ErrorMonitoringProvider({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    if (typeof window === 'undefined') return;

    // Deduplication tracker
    const reportedSignatures = new Set<string>();

    const handleError = (event: ErrorEvent) => {
      const msg = event.message || 'Unhandled Client Error';
      const file = event.filename || 'unknown';
      const line = event.lineno || 0;
      const sig = `${msg}:${file}:${line}`;

      if (reportedSignatures.has(sig)) return;
      reportedSignatures.add(sig);

      adminApi.reportIncident({
        title: `Frontend Client Error: ${msg.slice(0, 60)}`,
        category: 'FRONTEND',
        severity: 'HIGH',
        source: 'ADMIN_PANEL',
        affected_module: file.split('/').pop() || 'Window',
        error_message: msg,
        stack_trace: event.error?.stack || `${file}:${line}:${event.colno || 0}`,
        page_route: window.location.pathname,
      });
    };

    const handleRejection = (event: PromiseRejectionEvent) => {
      const reason = event.reason;
      const msg = reason?.message || String(reason) || 'Unhandled Promise Rejection';
      const sig = `rejection:${msg}`;

      if (reportedSignatures.has(sig)) return;
      reportedSignatures.add(sig);

      adminApi.reportIncident({
        title: `Unhandled Promise Rejection: ${msg.slice(0, 60)}`,
        category: 'FRONTEND',
        severity: 'MEDIUM',
        source: 'ADMIN_PANEL',
        affected_module: 'PromiseRuntime',
        error_message: msg,
        stack_trace: reason?.stack || String(reason),
        page_route: window.location.pathname,
      });
    };

    window.addEventListener('error', handleError);
    window.addEventListener('unhandledrejection', handleRejection);

    return () => {
      window.removeEventListener('error', handleError);
      window.removeEventListener('unhandledrejection', handleRejection);
    };
  }, []);

  return <>{children}</>;
}


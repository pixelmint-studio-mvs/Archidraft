'use client';

import React, { Component, ErrorInfo, ReactNode } from 'react';
import { adminApi } from '@/lib/api';
import { AlertTriangle, RefreshCw, LifeBuoy } from 'lucide-react';
import Link from 'next/link';

interface Props {
  children: ReactNode;
  fallbackTitle?: string;
  moduleName?: string;
}

interface State {
  hasError: boolean;
  error: Error | null;
  ticketId?: string;
  isReporting: boolean;
}

export class ErrorBoundary extends Component<Props, State> {
  public state: State = {
    hasError: false,
    error: null,
    isReporting: false,
  };

  public static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error, isReporting: true };
  }

  public componentDidCatch(error: Error, errorInfo: ErrorInfo) {
    console.error('ErrorBoundary caught an unhandled exception:', error, errorInfo);

    adminApi
      .reportIncident({
        title: `React Component Crash: ${error.message.slice(0, 70)}`,
        category: 'FRONTEND',
        severity: 'CRITICAL',
        source: 'ADMIN_PANEL',
        affected_module: this.props.moduleName || 'ReactComponentTree',
        error_message: error.message,
        stack_trace: `${error.stack || ''}\nComponent Stack:${errorInfo.componentStack || ''}`,
        page_route: typeof window !== 'undefined' ? window.location.pathname : undefined,
      })
      .then((res) => {
        if (res.ticketId) {
          this.setState({ ticketId: res.ticketId, isReporting: false });
        } else {
          this.setState({ isReporting: false });
        }
      })
      .catch(() => {
        this.setState({ isReporting: false });
      });
  }

  private handleReload = () => {
    if (typeof window !== 'undefined') {
      window.location.reload();
    }
  };

  private handleReset = () => {
    this.setState({ hasError: false, error: null, ticketId: undefined });
  };

  public render() {
    if (this.state.hasError) {
      return (
        <div className="min-h-[380px] w-full flex items-center justify-center p-6 bg-slate-50/60 rounded-2xl border border-slate-200">
          <div className="max-w-md w-full bg-white p-6 sm:p-8 rounded-2xl border border-rose-200 shadow-sm text-center">
            <div className="h-12 w-12 rounded-2xl bg-rose-50 border border-rose-200 text-rose-600 flex items-center justify-center mx-auto mb-4">
              <AlertTriangle className="h-6 w-6" />
            </div>

            <h3 className="text-base font-bold text-slate-900 font-mono">
              {this.props.fallbackTitle || 'Rendering Exception Detected'}
            </h3>

            <p className="text-xs text-slate-500 mt-2 mb-4 leading-relaxed">
              An unexpected error occurred while rendering this interface. An automated incident report has been dispatched to Studio Monitoring.
            </p>

            {this.state.ticketId && (
              <div className="bg-slate-50 border border-slate-200 rounded-xl px-3 py-2 mb-4 inline-flex items-center gap-2">
                <span className="text-[10px] font-mono text-slate-400 uppercase font-semibold">Incident Ref:</span>
                <span className="text-xs font-mono font-bold text-[#0453cd]">{this.state.ticketId}</span>
              </div>
            )}

            <div className="flex flex-col sm:flex-row items-center justify-center gap-3">
              <button
                onClick={this.handleReset}
                className="w-full sm:w-auto px-4 py-2 text-xs font-mono font-semibold rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors"
              >
                Try Again
              </button>
              <button
                onClick={this.handleReload}
                className="w-full sm:w-auto px-4 py-2 text-xs font-mono font-semibold rounded-xl bg-[#0453cd] text-white hover:bg-blue-700 transition-colors flex items-center justify-center gap-2"
              >
                <RefreshCw className="h-3.5 w-3.5" />
                <span>Reload Page</span>
              </button>
              <Link
                href="/helpdesk"
                className="w-full sm:w-auto px-4 py-2 text-xs font-mono font-semibold rounded-xl border border-slate-200 text-slate-700 hover:bg-slate-50 transition-colors flex items-center justify-center gap-1.5"
              >
                <LifeBuoy className="h-3.5 w-3.5 text-[#0453cd]" />
                <span>Help Desk</span>
              </Link>
            </div>
          </div>
        </div>
      );
    }

    return this.props.children;
  }
}


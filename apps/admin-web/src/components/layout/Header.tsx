'use client';

import React from 'react';
import { Shield, RefreshCw, PanelLeft } from 'lucide-react';
import { useAuth } from '@/lib/auth';

interface HeaderProps {
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
  isRefreshing?: boolean;
  onToggleSidebar?: () => void;
  isSidebarCollapsed?: boolean;
}

export function Header({
  title,
  subtitle,
  onRefresh,
  isRefreshing = false,
  onToggleSidebar,
  isSidebarCollapsed = false,
}: HeaderProps) {
  const { user } = useAuth();

  return (
    <header className="h-16 px-4 sm:px-6 md:px-8 border-b border-slate-200 bg-white/85 backdrop-blur-md flex items-center justify-between gap-2.5 sm:gap-3 shrink-0 z-10 shadow-xs">
      <div className="flex items-center gap-2.5 min-w-0 flex-1">
        {onToggleSidebar && (
          <button
            onClick={onToggleSidebar}
            className="p-1.5 -ml-1 text-slate-500 hover:text-slate-900 hover:bg-slate-100 rounded-lg transition-colors cursor-pointer shrink-0"
            title={isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
            aria-label={isSidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
          >
            <PanelLeft className="h-4 w-4" />
          </button>
        )}
        <div className="min-w-0 flex-1">
          <h2 className="text-sm sm:text-base font-bold text-slate-900 tracking-tight leading-tight truncate">
            {title}
          </h2>
          {subtitle && (
            <p className="text-xs text-slate-500 mt-0.5 leading-snug truncate">
              {subtitle}
            </p>
          )}
        </div>
      </div>

      <div className="flex items-center flex-wrap gap-2 sm:gap-2.5 shrink-0 self-start sm:self-center ml-auto sm:ml-0">
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isRefreshing}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-slate-700 hover:text-slate-900 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg transition-colors shadow-xs disabled:opacity-50 cursor-pointer"
            title="Refresh data"
          >
            <RefreshCw className={`h-3.5 w-3.5 text-slate-500 ${isRefreshing ? 'animate-spin text-[#0453cd]' : ''}`} />
            <span>Sync</span>
          </button>
        )}

        {/* Worker API status indicator */}
        <div className="flex items-center gap-1.5 sm:gap-2 px-2.5 sm:px-3 py-1 rounded-full bg-slate-50 border border-slate-200 text-xs shrink-0">
          <span className="relative flex h-2 w-2">
            <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
            <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500" />
          </span>
          <span className="text-[10px] sm:text-[11px] font-mono font-semibold text-slate-700">
            D1 Worker Live
          </span>
        </div>

        {/* Security badge (shown on larger screens) */}
        <div className="hidden lg:flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#0d1c32] text-white text-xs font-mono font-medium shadow-xs shrink-0">
          <Shield className="h-3.5 w-3.5 text-blue-300" />
          <span>Studio Admin</span>
        </div>
      </div>
    </header>
  );
}

'use client';

import React from 'react';
import Link from 'next/link';
import { Shield, RefreshCw, PanelLeft, ArrowLeft, Clock, AlertTriangle, Bot, LifeBuoy } from 'lucide-react';
import { formatTime } from '@/lib/dateUtils';
import { useAuth } from '@/lib/auth';
import { AdminNotificationPopover } from './AdminNotificationPopover';
import { Monogram3DViewer } from '@/components/ui/Monogram3DViewer';

interface HeaderProps {
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
  isRefreshing?: boolean;
  lastSyncedAt?: Date | null;
  syncError?: string | null;
  onToggleSidebar?: () => void;
  isSidebarCollapsed?: boolean;
  backHref?: string;
  backLabel?: string;
}

export function Header({
  title,
  subtitle,
  onRefresh,
  isRefreshing = false,
  lastSyncedAt,
  syncError,
  onToggleSidebar,
  isSidebarCollapsed = false,
  backHref,
  backLabel = 'Back',
}: HeaderProps) {
  const { user } = useAuth();

  return (
    <header className={`${backHref ? 'min-h-16 py-2.5' : 'h-16'} px-4 sm:px-6 md:px-8 border-b border-slate-200 bg-white/85 backdrop-blur-md flex items-center justify-between gap-2.5 sm:gap-3 shrink-0 z-10 shadow-xs`}>
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
        {isSidebarCollapsed && (
          <Link
            href="/dashboard"
            className="h-8 w-8 rounded-lg overflow-hidden bg-slate-900 border border-slate-700/60 shadow-xs shrink-0 flex items-center justify-center p-0.5 hover:border-blue-500 transition-colors"
            title="ArchiDraft Studio Dashboard"
          >
            <Monogram3DViewer className="w-full h-full" autoRotate={true} rotationSpeed={0.02} />
          </Link>
        )}
        <div className="min-w-0 flex-1">
          {backHref && (
            <div className="mb-1">
              <Link
                href={backHref}
                className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-lg text-xs font-mono font-bold bg-blue-50 hover:bg-blue-100 text-[#0453cd] hover:text-blue-800 border border-blue-200/90 hover:border-blue-300 shadow-xs transition-all cursor-pointer group w-fit active:scale-[0.98]"
                title={(backLabel || 'Back').replace(/^[←\s]+/, '').trim()}
              >
                <ArrowLeft className="h-3.5 w-3.5 text-[#0453cd] group-hover:-translate-x-0.5 transition-transform shrink-0" />
                <span>{(backLabel || 'Back').replace(/^[←\s]+/, '').trim()}</span>
              </Link>
            </div>
          )}
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
        {lastSyncedAt && (
          <span className="hidden sm:inline-flex items-center gap-1 text-[11px] font-mono text-slate-500">
            <Clock className="h-3 w-3 text-slate-400" />
            Last synced: {formatTime(lastSyncedAt)}
          </span>
        )}
        {syncError && !isRefreshing && (
          <span className="hidden sm:inline-flex items-center gap-1 text-[11px] font-mono text-rose-600">
            <AlertTriangle className="h-3 w-3" />
            Sync error
          </span>
        )}
        {onRefresh && (
          <button
            onClick={onRefresh}
            disabled={isRefreshing}
            className="flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium text-slate-700 hover:text-slate-900 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg transition-colors shadow-xs disabled:opacity-50 cursor-pointer"
            title="Refresh data"
          >
            <RefreshCw className={`h-3.5 w-3.5 text-slate-500 ${isRefreshing ? 'animate-spin text-[#0453cd]' : ''}`} />
            <span className="font-mono text-xs">{isRefreshing ? 'Syncing...' : 'Sync'}</span>
          </button>
        )}

        {/* PIXMINT BOT Studio Assistant Launcher */}
        <button
          type="button"
          onClick={() => {
            if (typeof window !== 'undefined') {
              window.dispatchEvent(new CustomEvent('open-pixmint-bot'));
            }
          }}
          className="flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-medium text-slate-700 hover:text-slate-900 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg transition-colors shadow-xs cursor-pointer group"
          title="Chat with PIXMINT Bot (Architectural AI Assistant)"
        >
          <div className="relative flex items-center justify-center">
            <Bot className="h-3.5 w-3.5 text-[#0453cd] group-hover:text-emerald-600 transition-colors" />
            <span className="absolute -top-0.5 -right-0.5 h-1.5 w-1.5 rounded-full bg-emerald-500" />
          </div>
          <span className="hidden md:inline font-mono text-xs">PIXMINT</span>
        </button>

        {/* PixelMint Support Request Launcher */}
        <button
          type="button"
          onClick={() => {
            if (typeof window !== 'undefined') {
              window.dispatchEvent(new CustomEvent('open-support-widget'));
            }
          }}
          className="flex items-center gap-1.5 px-2.5 py-1.5 text-xs font-medium text-slate-700 hover:text-slate-900 bg-white hover:bg-slate-50 border border-slate-200 rounded-lg transition-colors shadow-xs cursor-pointer group"
          title="Need Help? Open Support Request"
        >
          <LifeBuoy className="h-3.5 w-3.5 text-slate-500 group-hover:text-blue-600 transition-colors" />
          <span className="hidden md:inline font-mono text-xs">Help</span>
        </button>

        {/* Studio Notifications Feed */}
        <AdminNotificationPopover />

        {/* Security badge (shown on larger screens) */}
        <div className="hidden lg:flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#0d1c32] text-white text-xs font-mono font-medium shadow-xs shrink-0">
          <Shield className="h-3.5 w-3.5 text-blue-300" />
          <span>Studio Admin</span>
        </div>
      </div>
    </header>
  );
}

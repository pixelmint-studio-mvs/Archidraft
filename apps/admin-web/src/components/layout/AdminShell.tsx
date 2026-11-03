'use client';

import React, { ReactNode, useState, useEffect } from 'react';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { useAuth } from '@/lib/auth';

interface AdminShellProps {
  children: ReactNode;
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
  isRefreshing?: boolean;
  backHref?: string;
  backLabel?: string;
}

export function AdminShell({
  children,
  title,
  subtitle,
  onRefresh,
  isRefreshing,
  backHref,
  backLabel,
}: AdminShellProps) {
  const { user, loading } = useAuth();
  const [isSidebarCollapsed, setIsSidebarCollapsed] = useState(false);

  // Auto-collapse sidebar on narrow screens (< 1024px) or load saved user preference
  useEffect(() => {
    if (typeof window !== 'undefined') {
      const saved = localStorage.getItem('archidraft_sidebar_collapsed');
      if (saved !== null) {
        setIsSidebarCollapsed(saved === 'true');
      } else if (window.innerWidth < 1024) {
        setIsSidebarCollapsed(true);
      } else {
        setIsSidebarCollapsed(false);
      }
    }
  }, []);

  const handleToggleSidebar = () => {
    setIsSidebarCollapsed((prev) => {
      const next = !prev;
      if (typeof window !== 'undefined') {
        localStorage.setItem('archidraft_sidebar_collapsed', String(next));
      }
      return next;
    });
  };

  if (loading) {
    return (
      <div className="h-screen w-full flex items-center justify-center bg-[#fbf9fb] blueprint-bg">
        <div className="flex flex-col items-center gap-3 p-8 bg-white border border-slate-200 rounded-2xl shadow-sm">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs font-mono font-medium text-slate-600 uppercase tracking-wider">Verifying Admin Privileges...</p>
        </div>
      </div>
    );
  }

  if (!user || (user.role !== 'ADMIN' && user.role !== 'STUDIO_ADMIN')) {
    if (typeof window !== 'undefined') {
      window.location.replace('/login');
    }
    return (
      <div className="h-screen w-full flex items-center justify-center bg-[#0B0F17] text-white">
        <div className="flex flex-col items-center gap-4 p-8 bg-slate-900 border border-slate-800 rounded-2xl shadow-xl max-w-sm text-center">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
          <h3 className="font-bold text-base text-white">Redirecting to Login...</h3>
          <p className="text-xs text-slate-400">
            Please sign in with your Studio Admin credentials to access the Dashboard.
          </p>
          <a
            href="/login"
            className="mt-2 px-4 py-2 rounded-xl bg-blue-600 hover:bg-blue-500 text-white text-xs font-semibold transition-colors"
          >
            Click here if not redirected
          </a>
        </div>
      </div>
    );
  }

  return (
    <div className="h-screen w-full flex bg-[#fbf9fb] text-slate-900 overflow-hidden select-none">
      <React.Suspense
        fallback={
          <aside className="w-20 lg:w-72 bg-[#0d1c32] border-r border-[#1e293b] shrink-0 h-full" />
        }
      >
        <Sidebar isCollapsed={isSidebarCollapsed} onToggle={handleToggleSidebar} />
      </React.Suspense>
      <div className="flex-1 flex flex-col h-full min-w-0 overflow-hidden">
        <Header
          title={title}
          subtitle={subtitle}
          onRefresh={onRefresh}
          isRefreshing={isRefreshing}
          onToggleSidebar={handleToggleSidebar}
          isSidebarCollapsed={isSidebarCollapsed}
          backHref={backHref}
          backLabel={backLabel}
        />
        <main
          id="admin-main-content"
          className="flex-1 min-h-0 p-3.5 sm:p-5 md:p-8 overflow-y-auto overflow-x-hidden min-w-0 max-w-full blueprint-bg"
        >
          {children}
        </main>
      </div>
    </div>
  );
}

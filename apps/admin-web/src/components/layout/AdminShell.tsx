'use client';

import React, { ReactNode } from 'react';
import { Sidebar } from './Sidebar';
import { Header } from './Header';
import { useAuth } from '@/lib/auth';

interface AdminShellProps {
  children: ReactNode;
  title: string;
  subtitle?: string;
  onRefresh?: () => void;
  isRefreshing?: boolean;
}

export function AdminShell({
  children,
  title,
  subtitle,
  onRefresh,
  isRefreshing,
}: AdminShellProps) {
  const { user, loading } = useAuth();

  if (loading) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-[#090d16]">
        <div className="flex flex-col items-center gap-3">
          <div className="h-10 w-10 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
          <p className="text-sm font-medium text-slate-400">Verifying Admin Privileges...</p>
        </div>
      </div>
    );
  }

  if (!user || user.role !== 'ADMIN') {
    return null; // Route protection in AuthProvider will redirect
  }

  return (
    <div className="min-h-screen flex bg-[#090d16] text-slate-100">
      <React.Suspense fallback={<aside className="w-64 bg-[#0b1120] border-r border-slate-800 shrink-0 h-screen sticky top-0" />}>
        <Sidebar />
      </React.Suspense>
      <div className="flex-1 flex flex-col min-w-0">
        <Header
          title={title}
          subtitle={subtitle}
          onRefresh={onRefresh}
          isRefreshing={isRefreshing}
        />
        <main className="flex-1 p-8 overflow-y-auto">{children}</main>
      </div>
    </div>
  );
}

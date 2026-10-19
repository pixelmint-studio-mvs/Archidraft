'use client';

import React from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  FolderKanban,
  HardHat,
  PenTool,
  GraduationCap,
  Activity,
  Settings,
  LogOut,
  ShieldCheck,
} from 'lucide-react';
import { useAuth } from '@/lib/auth';

const NAV_ITEMS = [
  {
    name: 'Dashboard',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    name: 'Projects',
    href: '/projects',
    icon: FolderKanban,
  },
  {
    name: 'Engineers',
    href: '/engineers',
    icon: HardHat,
  },
  {
    name: 'Draughtsmen',
    href: '/draughtsmen',
    icon: PenTool,
  },
  {
    name: 'Students',
    href: '/students',
    icon: GraduationCap,
  },
  {
    name: 'Activity Feed',
    href: '/activity',
    icon: Activity,
  },
  {
    name: 'Settings & Health',
    href: '/settings',
    icon: Settings,
  },
];

export function Sidebar() {
  const pathname = usePathname();
  const { user, logout } = useAuth();

  return (
    <aside className="w-64 bg-[#0b1120] border-r border-slate-800 flex flex-col justify-between shrink-0 h-screen sticky top-0">
      {/* Brand Header */}
      <div>
        <div className="h-16 flex items-center gap-3 px-6 border-b border-slate-800/80">
          <img
            src="/draughtsman_logo.jpeg"
            alt="Draughtsman Studio Logo"
            className="h-9 w-9 rounded-xl object-cover bg-slate-900 border border-slate-700/60 shadow-md shadow-blue-500/10 shrink-0"
          />
          <div className="overflow-hidden">
            <h1 className="text-sm font-bold tracking-wider text-slate-100 uppercase truncate">
              Archi Draft
            </h1>
            <div className="flex items-center gap-1.5 mt-0.5">
              <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
              <p className="text-[10px] tracking-widest text-slate-400 font-semibold uppercase truncate">
                Draughtsman Studio
              </p>
            </div>
          </div>
        </div>

        {/* Navigation */}
        <nav className="p-4 space-y-1.5">
          {NAV_ITEMS.map((item) => {
            const Icon = item.icon;
            const isActive =
              pathname === item.href ||
              (item.href !== '/dashboard' && pathname.startsWith(item.href));

            return (
              <Link
                key={item.href}
                href={item.href}
                className={`flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all ${
                  isActive
                    ? 'bg-blue-600/15 text-blue-400 border border-blue-500/20 shadow-sm'
                    : 'text-slate-400 hover:text-slate-200 hover:bg-slate-800/50'
                }`}
              >
                <Icon
                  className={`h-4 w-4 transition-colors ${
                    isActive ? 'text-blue-400' : 'text-slate-500 group-hover:text-slate-300'
                  }`}
                />
                <span>{item.name}</span>
              </Link>
            );
          })}
        </nav>
      </div>

      {/* User Footer */}
      <div className="p-4 border-t border-slate-800/80 bg-[#090d16]/50">
        <div className="flex items-center justify-between mb-2">
          <div className="flex items-center gap-2.5 overflow-hidden">
            <div className="h-8 w-8 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-300 font-medium shrink-0">
              {user?.name ? user.name.charAt(0).toUpperCase() : 'A'}
            </div>
            <div className="overflow-hidden">
              <p className="text-xs font-semibold text-slate-200 truncate">
                {user?.name || 'Administrator'}
              </p>
              <div className="flex items-center gap-1 text-[10px] text-blue-400 font-medium">
                <ShieldCheck className="h-3 w-3" />
                <span>Studio Admin</span>
              </div>
            </div>
          </div>
          <button
            onClick={() => logout()}
            title="Sign out"
            className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors"
          >
            <LogOut className="h-4 w-4" />
          </button>
        </div>
        <div className="pt-2 border-t border-slate-800/50 flex items-center justify-between text-[9px] text-slate-500 font-mono">
          <span>Draughtsman Studio</span>
          <span>PixelMint MVS</span>
        </div>
      </div>
    </aside>
  );
}

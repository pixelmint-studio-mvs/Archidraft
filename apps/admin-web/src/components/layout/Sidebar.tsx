'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  LayoutDashboard,
  FolderKanban,
  HardHat,
  PenTool,
  GraduationCap,
  Users,
  Activity,
  DollarSign,
  Settings,
  LogOut,
  ShieldCheck,
  ChevronLeft,
  ChevronRight,
  UserCheck,
  Clock,
  ClipboardCheck,
} from 'lucide-react';
import { useAuth } from '@/lib/auth';
import { adminApi } from '@/lib/api';

// ── Types ─────────────────────────────────────────────────────────────────────

interface NavBadgeCounts {
  projects: number;
  engineers: number;
  draughtsmen: number;
  students: number;
}

interface NavItem {
  name: string;
  href: string;
  icon: React.ComponentType<{ className?: string }>;
  badgeKey?: keyof NavBadgeCounts | null;
}

interface NavSection {
  title: string;
  items: NavItem[];
}

// ── Nav items grouped by Stitch Architectural Precision System ────────────────

const NAV_SECTIONS: NavSection[] = [
  {
    title: 'Overview',
    items: [
      {
        name: 'Dashboard',
        href: '/dashboard',
        icon: LayoutDashboard,
      },
      {
        name: 'Activity Feed',
        href: '/activity',
        icon: Activity,
      },
    ],
  },
  {
    title: 'Workflow & Pipeline',
    items: [
      {
        name: 'Projects Catalogue',
        href: '/projects',
        icon: FolderKanban,
        badgeKey: 'projects',
      },
      {
        name: 'Student Submissions',
        href: '/students/submissions',
        icon: ClipboardCheck,
      },
      {
        name: 'Assignment Console',
        href: '/assignments',
        icon: UserCheck,
      },
      {
        name: 'Assignment History',
        href: '/assignments/history',
        icon: Clock,
      },
    ],
  },
  {
    title: 'Portal Directories',
    items: [
      {
        name: 'All Users Directory',
        href: '/users',
        icon: Users,
      },
      {
        name: 'Engineers',
        href: '/engineers',
        icon: HardHat,
        badgeKey: 'engineers',
      },
      {
        name: 'Draughtsmen',
        href: '/draughtsmen',
        icon: PenTool,
        badgeKey: 'draughtsmen',
      },
      {
        name: 'Students',
        href: '/students',
        icon: GraduationCap,
        badgeKey: 'students',
      },
    ],
  },
  {
    title: 'Studio Governance',
    items: [
      {
        name: 'System Settings & SLA',
        href: '/settings',
        icon: Settings,
      },
      {
        name: 'Financials (Frozen)',
        href: '/financials',
        icon: DollarSign,
      },
    ],
  },
];

// ── Compact badge pill ────────────────────────────────────────────────────────

function NavBadge({ count, isActive }: { count: number; isActive: boolean }) {
  if (count === 0) return null;
  return (
    <span
      className={`ml-auto text-[10px] font-mono font-bold px-2 py-0.5 rounded-full leading-none transition-all ${
        isActive
          ? 'bg-white/20 text-white'
          : 'bg-[#15294a] text-slate-300 border border-[#22395d]'
      }`}
    >
      {count > 99 ? '99+' : count}
    </span>
  );
}

// ── Sidebar Component ─────────────────────────────────────────────────────────

interface SidebarProps {
  isCollapsed?: boolean;
  onToggle?: () => void;
}

export function Sidebar({ isCollapsed = false, onToggle }: SidebarProps) {
  const pathname = usePathname();
  const { user, logout } = useAuth();
  const [counts, setCounts] = useState<NavBadgeCounts>({
    projects: 0,
    engineers: 0,
    draughtsmen: 0,
    students: 0,
  });

  // Fetch live counts on mount, then refresh every 30 seconds
  useEffect(() => {
    let mounted = true;

    async function fetchCounts() {
      try {
        const stats = await adminApi.getStats();
        if (!mounted) return;
        setCounts({
          projects: stats.projects?.total ?? 0,
          engineers: stats.users?.byRole?.['CLIENT'] ?? 0,
          draughtsmen: stats.users?.byRole?.['DRAUGHTSMAN'] ?? 0,
          students: stats.users?.byRole?.['STUDENT'] ?? 0,
        });
      } catch {
        // Silently fail — badge just shows 0
      }
    }

    fetchCounts();
    const interval = setInterval(fetchCounts, 30_000);
    return () => {
      mounted = false;
      clearInterval(interval);
    };
  }, []);

  return (
    <aside
      className={`bg-[#0d1c32] border-r border-[#1e293b] flex flex-col justify-between shrink-0 h-full z-20 transition-all duration-300 ease-in-out select-none ${
        isCollapsed ? 'w-20' : 'w-64 lg:w-72'
      }`}
    >
      {/* ── Brand Header (Fixed top) ── */}
      <div
        className={`h-16 flex items-center border-b border-[#1e293b]/90 bg-[#091322]/60 shrink-0 transition-all ${
          isCollapsed ? 'justify-center px-2' : 'justify-between px-5'
        }`}
      >
        <div className="flex items-center gap-3 overflow-hidden min-w-0">
          <img
            src="/draughtsman_logo.jpeg"
            alt="Draughtsman Studio Logo"
            className="h-9 w-9 rounded-xl object-cover bg-slate-900 border border-slate-700/60 shadow-md shrink-0"
          />
          {!isCollapsed && (
            <div className="overflow-hidden min-w-0">
              <h1 className="text-sm font-bold tracking-wider text-white uppercase truncate font-mono">
                Archi Draft
              </h1>
              <div className="flex items-center gap-1.5 mt-0.5">
                <span className="h-1.5 w-1.5 rounded-full bg-emerald-400 animate-pulse shrink-0" />
                <p className="text-[10px] tracking-widest text-slate-400 font-semibold uppercase truncate">
                  Draughtsman Studio
                </p>
              </div>
            </div>
          )}
        </div>
      </div>

      {/* ── Scrollable Navigation Section ── */}
      <nav
        className={`flex-1 min-h-0 overflow-y-auto overflow-x-hidden space-y-4 py-3.5 transition-all ${
          isCollapsed ? 'px-2' : 'px-3.5'
        }`}
      >
        {NAV_SECTIONS.map((section, sIdx) => (
          <div key={section.title} className="space-y-1">
            {!isCollapsed ? (
              <p className="px-3 pt-1 pb-1 text-[10px] font-mono text-slate-400 uppercase tracking-wider font-semibold">
                {section.title}
              </p>
            ) : sIdx > 0 ? (
              <div className="my-2 border-t border-[#1e293b]/70 mx-2" />
            ) : null}

            {section.items.map((item) => {
              const Icon = item.icon;
              const isActive =
                pathname === item.href ||
                (item.href !== '/dashboard' && pathname.startsWith(item.href));
              const badgeCount = item.badgeKey ? counts[item.badgeKey] : 0;

              return (
                <Link
                  key={item.href}
                  href={item.href}
                  title={item.name}
                  className={`flex items-center rounded-xl text-sm font-medium transition-all relative group ${
                    isCollapsed
                      ? 'justify-center p-2.5 my-1 mx-1'
                      : 'gap-3 px-3.5 py-2.5'
                  } ${
                    isActive
                      ? 'bg-[#0453cd] text-white shadow-md shadow-blue-900/30 font-semibold'
                      : 'text-slate-300 hover:text-white hover:bg-white/5'
                  }`}
                >
                  <Icon
                    className={`h-4 w-4 shrink-0 transition-colors ${
                      isActive ? 'text-white' : 'text-slate-400 group-hover:text-slate-200'
                    }`}
                  />
                  {!isCollapsed && (
                    <>
                      <span className="flex-1 truncate">{item.name}</span>
                      {item.badgeKey && (
                        <NavBadge count={badgeCount} isActive={isActive} />
                      )}
                    </>
                  )}
                  {isCollapsed && badgeCount > 0 && (
                    <span className="absolute top-1.5 right-1.5 h-2 w-2 rounded-full bg-emerald-400 ring-2 ring-[#0d1c32]" />
                  )}

                  {/* Compact tooltip when collapsed */}
                  {isCollapsed && (
                    <div className="absolute left-full ml-2 px-2.5 py-1 bg-slate-900 text-white text-xs font-medium rounded-md shadow-lg border border-slate-700 pointer-events-none opacity-0 group-hover:opacity-100 transition-opacity whitespace-nowrap z-50">
                      {item.name}
                      {badgeCount > 0 && ` (${badgeCount})`}
                    </div>
                  )}
                </Link>
              );
            })}
          </div>
        ))}
      </nav>

      {/* ── User Footer & Toggle (Fixed bottom) ── */}
      <div
        className={`border-t border-[#1e293b]/90 bg-[#091322]/80 shrink-0 transition-all ${
          isCollapsed ? 'p-2' : 'p-3.5'
        }`}
      >
        {isCollapsed ? (
          <div className="flex flex-col items-center gap-2.5">
            <div
              className="h-9 w-9 rounded-xl bg-[#15294a] border border-[#22395d] flex items-center justify-center text-white font-mono text-xs font-bold shadow-xs"
              title={user?.name || 'Administrator'}
            >
              {user?.name ? user.name.charAt(0).toUpperCase() : 'A'}
            </div>
            <button
              onClick={() => logout()}
              title="Sign out"
              aria-label="Sign out"
              className="p-2 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-xl transition-colors cursor-pointer"
            >
              <LogOut className="h-4 w-4" />
            </button>
            {onToggle && (
              <button
                onClick={onToggle}
                title="Expand sidebar"
                aria-label="Expand sidebar"
                className="p-1.5 text-slate-400 hover:text-white hover:bg-white/10 rounded-lg transition-colors cursor-pointer"
              >
                <ChevronRight className="h-4 w-4" />
              </button>
            )}
          </div>
        ) : (
          <>
            <div className="flex items-center justify-between mb-2.5">
              <div className="flex items-center gap-2.5 overflow-hidden min-w-0">
                <div className="h-9 w-9 rounded-xl bg-[#15294a] border border-[#22395d] flex items-center justify-center text-white font-mono text-xs font-bold shrink-0 shadow-xs">
                  {user?.name ? user.name.charAt(0).toUpperCase() : 'A'}
                </div>
                <div className="overflow-hidden min-w-0">
                  <p className="text-xs font-semibold text-slate-100 truncate">
                    {user?.name || 'Administrator'}
                  </p>
                  <div className="flex items-center gap-1 text-[10px] text-blue-400 font-medium">
                    <ShieldCheck className="h-3 w-3 shrink-0" />
                    <span className="truncate">Studio Admin</span>
                  </div>
                </div>
              </div>
              <div className="flex items-center gap-1 shrink-0">
                <button
                  onClick={() => logout()}
                  title="Sign out"
                  aria-label="Sign out"
                  className="p-1.5 text-slate-400 hover:text-rose-400 hover:bg-rose-500/10 rounded-lg transition-colors cursor-pointer"
                >
                  <LogOut className="h-4 w-4" />
                </button>
                {onToggle && (
                  <button
                    onClick={onToggle}
                    title="Collapse sidebar"
                    aria-label="Collapse sidebar"
                    className="p-1.5 text-slate-400 hover:text-white hover:bg-white/10 rounded-lg transition-colors cursor-pointer"
                  >
                    <ChevronLeft className="h-4 w-4" />
                  </button>
                )}
              </div>
            </div>
            <div className="pt-2 border-t border-[#1e293b]/50 flex items-center justify-between text-[9px] text-slate-400 font-mono">
              <span>Draughtsman OS</span>
              <span>PixelMint MVS</span>
            </div>
          </>
        )}
      </div>
    </aside>
  );
}

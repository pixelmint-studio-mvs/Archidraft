'use client';

import React, { useState, useEffect, useRef } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import {
  Bell,
  CheckCircle,
  FileText,
  RotateCcw,
  UserCheck,
  UserX,
  Clock,
  Trash2,
  RefreshCw,
  X,
  ExternalLink,
  ShieldCheck,
  AlertTriangle,
  Layers,
} from 'lucide-react';
import { adminApi } from '@/lib/api';
import { AdminNotification } from '@/lib/types';

function formatRelativeTime(dateString: string): string {
  try {
    const date = new Date(dateString);
    const now = new Date();
    const diffMs = now.getTime() - date.getTime();
    const diffSec = Math.floor(diffMs / 1000);
    const diffMin = Math.floor(diffSec / 60);
    const diffHours = Math.floor(diffMin / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffSec < 60) return 'just now';
    if (diffMin < 60) return `${diffMin}m ago`;
    if (diffHours < 24) return `${diffHours}h ago`;
    if (diffDays < 7) return `${diffDays}d ago`;
    return date.toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
  } catch {
    return 'recently';
  }
}

function getNotificationVisuals(type: string) {
  switch (type) {
    case 'PROJECT_SUBMITTED':
      return {
        icon: FileText,
        colorClass: 'text-blue-600 bg-blue-50 border-blue-200',
        badge: 'NEW BRIEF',
      };
    case 'PROJECT_READY_FOR_ASSIGNMENT':
      return {
        icon: UserCheck,
        colorClass: 'text-amber-600 bg-amber-50 border-amber-200',
        badge: 'NEEDS ALLOCATION',
      };
    case 'ASSIGNMENT_ACCEPTED':
      return {
        icon: UserCheck,
        colorClass: 'text-emerald-600 bg-emerald-50 border-emerald-200',
        badge: 'ACCEPTED',
      };
    case 'ASSIGNMENT_REJECTED':
      return {
        icon: UserX,
        colorClass: 'text-rose-600 bg-rose-50 border-rose-200',
        badge: 'DECLINED',
      };
    case 'DRAWING_SUBMITTED_FOR_ADMIN':
    case 'DRAWING_RESUBMITTED_FOR_ADMIN':
      return {
        icon: Layers,
        colorClass: 'text-purple-600 bg-purple-50 border-purple-200',
        badge: type === 'DRAWING_RESUBMITTED_FOR_ADMIN' ? 'CORRECTED QC' : 'STUDIO QC',
      };
    case 'CORRECTION_REQUESTED':
      return {
        icon: RotateCcw,
        colorClass: 'text-amber-700 bg-amber-50 border-amber-200',
        badge: 'CORRECTION',
      };
    case 'PROJECT_COMPLETED':
      return {
        icon: ShieldCheck,
        colorClass: 'text-emerald-700 bg-emerald-50 border-emerald-200',
        badge: 'COMPLETED',
      };
    default:
      return {
        icon: Bell,
        colorClass: 'text-slate-600 bg-slate-50 border-slate-200',
        badge: 'EVENT',
      };
  }
}

export function AdminNotificationPopover() {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [filter, setFilter] = useState<'all' | 'unread' | 'projects'>('all');
  const [notifications, setNotifications] = useState<AdminNotification[]>([]);
  const [loading, setLoading] = useState(false);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const popoverRef = useRef<HTMLDivElement>(null);

  const fetchNotifications = async (silent = false) => {
    if (!silent) setIsRefreshing(true);
    setError(null);
    try {
      const data = await adminApi.getNotifications();
      const rawList = Array.isArray(data) ? data : [];
      let clearedIds: string[] = [];
      if (typeof window !== 'undefined') {
        try {
          clearedIds = JSON.parse(localStorage.getItem('archidraft_cleared_notifs') || '[]');
        } catch {}
      }
      const filtered = clearedIds.length > 0 ? rawList.filter((n) => !clearedIds.includes(n.id)) : rawList;
      setNotifications(filtered);
    } catch (err: any) {
      if (!silent) {
        setError(err.message || 'Failed to load notifications');
      }
    } finally {
      if (!silent) setIsRefreshing(false);
    }
  };

  // Initial fetch and 6-second live polling interval
  useEffect(() => {
    fetchNotifications(true);
    const interval = setInterval(() => {
      fetchNotifications(true);
    }, 6000);
    return () => clearInterval(interval);
  }, []);

  // Close on click outside
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (popoverRef.current && !popoverRef.current.contains(event.target as Node)) {
        setIsOpen(false);
      }
    }
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => {
      document.removeEventListener('mousedown', handleClickOutside);
    };
  }, [isOpen]);

  const unreadCount = notifications.filter(
    (n) => n.is_read === 0 || n.is_read === false
  ).length;

  const projectsCount = notifications.filter(
    (n) => Boolean(n.project_id) || n.type.includes('PROJECT') || n.type.includes('DRAWING') || n.type.includes('CORRECTION') || n.type.includes('ASSIGNMENT')
  ).length;

  const displayedNotifications = notifications.filter((n) => {
    if (filter === 'unread') return n.is_read === 0 || n.is_read === false;
    if (filter === 'projects') return Boolean(n.project_id) || n.type.includes('PROJECT') || n.type.includes('DRAWING') || n.type.includes('CORRECTION') || n.type.includes('ASSIGNMENT');
    return true;
  });

  const handleMarkAsRead = async (id: string, e?: React.MouseEvent) => {
    if (e) e.stopPropagation();
    const previous = [...notifications];
    setNotifications((prev) =>
      prev.map((n) => (n.id === id ? { ...n, is_read: 1 } : n))
    );
    try {
      await adminApi.markNotificationRead(id);
    } catch (err: any) {
      console.error('Mark notification read error:', err);
      setNotifications(previous);
    }
  };

  const handleDismiss = async (id: string, e: React.MouseEvent) => {
    e.stopPropagation();
    const previous = [...notifications];
    setNotifications((prev) => prev.filter((n) => n.id !== id));
    if (typeof window !== 'undefined') {
      try {
        const stored = JSON.parse(localStorage.getItem('archidraft_cleared_notifs') || '[]');
        localStorage.setItem('archidraft_cleared_notifs', JSON.stringify([...new Set([...stored, id])]));
      } catch {}
    }
    try {
      await adminApi.clearNotification(id);
    } catch (err: any) {
      console.error('Dismiss notification error:', err);
      setNotifications(previous);
    }
  };

  const handleMarkAllAsRead = async () => {
    const previous = [...notifications];
    setNotifications((prev) => prev.map((n) => ({ ...n, is_read: 1 })));
    try {
      await adminApi.markAllNotificationsRead();
      await fetchNotifications(true);
    } catch (err: any) {
      console.error('Mark all notifications read error:', err);
      setNotifications(previous);
      setError(err.message || 'Failed to mark all notifications as read');
    }
  };

  const handleClearAll = async (e?: React.MouseEvent) => {
    if (e) {
      e.preventDefault();
      e.stopPropagation();
    }
    const previous = [...notifications];
    setNotifications([]);
    setError(null);
    setLoading(true);

    if (typeof window !== 'undefined') {
      try {
        const clearedIds = previous.map((n) => n.id);
        const stored = JSON.parse(localStorage.getItem('archidraft_cleared_notifs') || '[]');
        localStorage.setItem(
          'archidraft_cleared_notifs',
          JSON.stringify([...new Set([...stored, ...clearedIds])])
        );
      } catch {}
    }

    try {
      await adminApi.clearAllNotifications();
    } catch (err: any) {
      console.error('Failed to clear notifications:', err);
      setNotifications(previous);
      setError(err.message || 'Failed to clear notifications');
    } finally {
      setLoading(false);
    }
  };

  const handleNotificationClick = async (notif: AdminNotification) => {
    if (!notif.is_read) {
      handleMarkAsRead(notif.id);
    }
    setIsOpen(false);
    if (notif.project_id) {
      router.push(`/projects/${notif.project_id}`);
    }
  };

  return (
    <div className="relative inline-block" ref={popoverRef}>
      {/* Trigger Button (Replaces "D1 Worker Live") */}
      <button
        type="button"
        onClick={() => setIsOpen((prev) => !prev)}
        className={`flex items-center gap-2 px-3 py-1.5 rounded-full border text-xs font-mono font-medium transition-all shadow-xs cursor-pointer select-none ${
          unreadCount > 0
            ? 'bg-amber-50/90 border-amber-300 text-amber-900 hover:bg-amber-100 hover:border-amber-400'
            : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50 hover:border-slate-300'
        }`}
        title="Studio Notifications Feed"
      >
        <span className="relative flex items-center justify-center">
          <Bell className={`h-3.5 w-3.5 ${unreadCount > 0 ? 'text-amber-700 animate-wiggle' : 'text-slate-500'}`} />
          {unreadCount > 0 && (
            <span className="absolute -top-1 -right-1 flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-amber-400 opacity-75" />
              <span className="relative inline-flex rounded-full h-2 w-2 bg-amber-600" />
            </span>
          )}
        </span>
        <span className="font-semibold text-[11px] tracking-tight">
          Notifications
        </span>
        {unreadCount > 0 && (
          <span className="px-1.5 py-0.2 bg-amber-600 text-white rounded-full text-[10px] font-bold">
            {unreadCount}
          </span>
        )}
      </button>

      {/* Floating Dropdown Panel */}
      {isOpen && (
        <div className="absolute right-0 mt-2 w-[calc(100vw-2rem)] sm:w-[420px] max-w-md bg-white rounded-2xl border border-slate-200 shadow-xl overflow-hidden z-50 animate-in fade-in slide-in-from-top-2 duration-150">
          {/* Header */}
          <div className="flex items-center justify-between px-4 py-3 border-b border-slate-100 bg-slate-50/80">
            <div className="flex items-center gap-2">
              <div className="p-1.5 rounded-lg bg-[#0d1c32] text-white">
                <Bell className="h-4 w-4" />
              </div>
              <div>
                <h4 className="text-xs font-bold font-mono text-slate-900 uppercase tracking-wider">
                  Studio Operations Feed
                </h4>
                <p className="text-[10px] text-slate-500 font-mono">
                  {unreadCount} unread {unreadCount === 1 ? 'alert' : 'alerts'} across workflows
                </p>
              </div>
            </div>

            <div className="flex items-center gap-1">
              <button
                type="button"
                onClick={() => fetchNotifications()}
                disabled={isRefreshing}
                className="p-1.5 text-slate-500 hover:text-slate-800 rounded-lg hover:bg-slate-200/60 transition-colors cursor-pointer"
                title="Refresh notifications"
              >
                <RefreshCw className={`h-3.5 w-3.5 ${isRefreshing ? 'animate-spin text-[#0453cd]' : ''}`} />
              </button>
              {unreadCount > 0 && (
                <button
                  type="button"
                  onClick={handleMarkAllAsRead}
                  className="px-2 py-1 text-[11px] font-mono text-slate-500 hover:text-emerald-700 hover:bg-emerald-50 rounded-md transition-colors cursor-pointer"
                  title="Mark all as read"
                >
                  Mark read
                </button>
              )}
              {notifications.length > 0 && (
                <button
                  type="button"
                  onClick={(e) => handleClearAll(e)}
                  disabled={loading}
                  className="px-2 py-1 text-[11px] font-mono text-slate-500 hover:text-rose-600 hover:bg-rose-50 rounded-md transition-colors cursor-pointer"
                  title="Clear all notifications"
                >
                  Clear All
                </button>
              )}
              <button
                type="button"
                onClick={() => setIsOpen(false)}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg hover:bg-slate-200/60 transition-colors cursor-pointer"
              >
                <X className="h-4 w-4" />
              </button>
            </div>
          </div>

          {/* Filter Tabs (Improvement 6) */}
          <div className="flex items-center gap-1.5 px-4 py-2 border-b border-slate-100 bg-slate-50/60 overflow-x-auto scrollbar-none">
            <button
              type="button"
              onClick={() => setFilter('all')}
              className={`px-2.5 py-1 rounded-full text-[10px] font-mono font-medium transition-colors cursor-pointer shrink-0 ${
                filter === 'all'
                  ? 'bg-[#0d1c32] text-white shadow-xs'
                  : 'text-slate-600 hover:bg-slate-200/60'
              }`}
            >
              All ({notifications.length})
            </button>
            <button
              type="button"
              onClick={() => setFilter('unread')}
              className={`px-2.5 py-1 rounded-full text-[10px] font-mono font-medium transition-colors cursor-pointer shrink-0 ${
                filter === 'unread'
                  ? 'bg-amber-600 text-white shadow-xs'
                  : 'text-slate-600 hover:bg-slate-200/60'
              }`}
            >
              Unread ({unreadCount})
            </button>
            <button
              type="button"
              onClick={() => setFilter('projects')}
              className={`px-2.5 py-1 rounded-full text-[10px] font-mono font-medium transition-colors cursor-pointer shrink-0 ${
                filter === 'projects'
                  ? 'bg-blue-600 text-white shadow-xs'
                  : 'text-slate-600 hover:bg-slate-200/60'
              }`}
            >
              Projects ({projectsCount})
            </button>
          </div>

          {/* Body */}
          <div className="max-h-[380px] overflow-y-auto divide-y divide-slate-100">
            {error && (
              <div className="p-3 bg-rose-50 border-b border-rose-100 text-rose-800 text-xs flex items-center justify-between">
                <span>{error}</span>
                <button
                  type="button"
                  onClick={() => fetchNotifications()}
                  className="underline text-[11px] font-mono font-bold ml-2 cursor-pointer"
                >
                  Retry
                </button>
              </div>
            )}

            {displayedNotifications.length === 0 ? (
              <div className="py-12 px-6 text-center space-y-2">
                <div className="mx-auto w-10 h-10 rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
                  <CheckCircle className="h-5 w-5 text-emerald-600" />
                </div>
                <h5 className="text-xs font-bold font-mono text-slate-800 uppercase">
                  Studio Queue All Clear
                </h5>
                <p className="text-xs text-slate-500 max-w-xs mx-auto">
                  No active notifications requiring attention. Submissions, assignments, and review actions will appear here live.
                </p>
              </div>
            ) : (
              displayedNotifications.map((notif) => {
                const isUnread = notif.is_read === 0 || notif.is_read === false;
                const visuals = getNotificationVisuals(notif.type);
                const IconComponent = visuals.icon;

                return (
                  <div
                    key={notif.id}
                    onClick={() => handleNotificationClick(notif)}
                    className={`p-3.5 flex items-start gap-3 transition-colors cursor-pointer group ${
                      isUnread
                        ? 'bg-amber-50/40 hover:bg-amber-50/80'
                        : 'bg-white hover:bg-slate-50'
                    }`}
                  >
                    {/* Unread indicator dot */}
                    <div className="pt-1 shrink-0">
                      <div
                        className={`w-2 h-2 rounded-full ${
                          isUnread ? 'bg-amber-500 ring-2 ring-amber-200' : 'bg-transparent'
                        }`}
                      />
                    </div>

                    {/* Icon */}
                    <div
                      className={`p-2 rounded-lg border shrink-0 ${visuals.colorClass}`}
                    >
                      <IconComponent className="h-4 w-4" />
                    </div>

                    {/* Content */}
                    <div className="flex-1 min-w-0 space-y-1">
                      <div className="flex items-center justify-between gap-1">
                        <span className="text-[10px] font-mono font-bold tracking-wider uppercase text-slate-500">
                          {visuals.badge}
                        </span>
                        <span className="text-[10px] font-mono text-slate-400 shrink-0 flex items-center gap-1">
                          <Clock className="h-2.5 w-2.5" />
                          {formatRelativeTime(notif.created_at)}
                        </span>
                      </div>

                      <h5
                        className={`text-xs leading-snug line-clamp-1 ${
                          isUnread
                            ? 'font-bold text-slate-900'
                            : 'font-medium text-slate-700'
                        }`}
                      >
                        {notif.title}
                      </h5>

                      <p className="text-xs text-slate-600 line-clamp-2 leading-relaxed">
                        {notif.message}
                      </p>

                      {notif.project_name && (
                        <div className="pt-0.5 flex items-center gap-1 text-[11px] font-mono font-medium text-[#0453cd] group-hover:underline">
                          <span>{notif.project_name}</span>
                          <ExternalLink className="h-2.5 w-2.5 shrink-0" />
                        </div>
                      )}
                    </div>

                    {/* Dismiss Button */}
                    <button
                      type="button"
                      onClick={(e) => handleDismiss(notif.id, e)}
                      className="opacity-0 group-hover:opacity-100 p-1 text-slate-400 hover:text-rose-600 hover:bg-rose-50 rounded transition-all cursor-pointer shrink-0"
                      title="Dismiss notification"
                    >
                      <X className="h-3.5 w-3.5" />
                    </button>
                  </div>
                );
              })
            )}
          </div>
        </div>
      )}
    </div>
  );
}

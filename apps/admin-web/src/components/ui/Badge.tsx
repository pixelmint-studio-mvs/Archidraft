import React from 'react';
import { ProjectStatus, UserRole } from '@/lib/types';

interface BadgeProps {
  children?: React.ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info' | 'purple';
  status?: ProjectStatus | string;
  role?: UserRole | string;
  size?: 'sm' | 'md';
}

export function Badge({ children, variant, status, role, size = 'sm' }: BadgeProps) {
  let style = 'bg-slate-800 text-slate-300 border-slate-700';

  if (status) {
    switch (status) {
      case 'DRAFT':
        style = 'bg-slate-800/80 text-slate-400 border-slate-700/60';
        break;
      case 'SUBMITTED':
        style = 'bg-amber-500/10 text-amber-400 border-amber-500/30';
        break;
      case 'WAITING_ASSIGNMENT':
        style = 'bg-blue-500/10 text-blue-400 border-blue-500/30';
        break;
      case 'WAITING_ACCEPTANCE':
        style = 'bg-purple-500/10 text-purple-400 border-purple-500/30';
        break;
      case 'IN_PROGRESS':
        style = 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30';
        break;
      case 'UNDER_CLIENT_REVIEW':
        style = 'bg-teal-500/10 text-teal-400 border-teal-500/30';
        break;
      case 'COMPLETED':
        style = 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30';
        break;
      case 'CANCELLED':
        style = 'bg-rose-500/10 text-rose-400 border-rose-500/30';
        break;
      default:
        style = 'bg-slate-800 text-slate-300 border-slate-700';
    }
  } else if (role) {
    switch (role) {
      case 'ADMIN':
        style = 'bg-rose-500/10 text-rose-400 border-rose-500/30 font-semibold';
        break;
      case 'DRAUGHTSMAN':
        style = 'bg-cyan-500/10 text-cyan-400 border-cyan-500/30';
        break;
      case 'CLIENT':
        style = 'bg-indigo-500/10 text-indigo-400 border-indigo-500/30';
        break;
      case 'STUDENT':
        style = 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30';
        break;
    }
  } else if (variant) {
    switch (variant) {
      case 'success':
        style = 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30';
        break;
      case 'warning':
        style = 'bg-amber-500/10 text-amber-400 border-amber-500/30';
        break;
      case 'danger':
        style = 'bg-rose-500/10 text-rose-400 border-rose-500/30';
        break;
      case 'info':
        style = 'bg-blue-500/10 text-blue-400 border-blue-500/30';
        break;
      case 'purple':
        style = 'bg-purple-500/10 text-purple-400 border-purple-500/30';
        break;
    }
  }

  const sizeClass = size === 'sm' ? 'px-2 py-0.5 text-xs' : 'px-2.5 py-1 text-sm';
  const label = children || (status ? formatStatus(status) : formatRole(role));

  return (
    <span
      className={`inline-flex items-center gap-1.5 font-medium rounded-full border transition-colors ${sizeClass} ${style}`}
    >
      <span className="h-1.5 w-1.5 rounded-full bg-current opacity-70" />
      {label}
    </span>
  );
}

function formatRole(role?: string): string {
  if (!role) return '';
  if (role === 'CLIENT') return 'ENGINEER';
  return role.toUpperCase();
}

function formatStatus(status: string): string {
  if (status === 'UNDER_CLIENT_REVIEW') {
    return 'Under Engineer Review';
  }
  return status
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

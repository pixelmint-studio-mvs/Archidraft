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
  let style = 'bg-slate-100 text-slate-700 border-slate-200';

  if (status) {
    switch (status) {
      case 'DRAFT':
        style = 'bg-slate-100 text-slate-600 border-slate-200';
        break;
      case 'SUBMITTED':
        style = 'bg-amber-50 text-amber-800 border-amber-200';
        break;
      case 'WAITING_ASSIGNMENT':
        style = 'bg-blue-50 text-blue-800 border-blue-200';
        break;
      case 'WAITING_ACCEPTANCE':
        style = 'bg-purple-50 text-purple-800 border-purple-200';
        break;
      case 'IN_PROGRESS':
        style = 'bg-cyan-50 text-cyan-800 border-cyan-200';
        break;
      case 'UNDER_CLIENT_REVIEW':
      case 'UNDER_ENGINEER_REVIEW':
        style = 'bg-teal-50 text-teal-800 border-teal-200';
        break;
      case 'NEEDS_CORRECTION':
        style = 'bg-amber-50 text-amber-800 border-amber-200';
        break;
      case 'COMPLETED':
        style = 'bg-emerald-50 text-emerald-800 border-emerald-200';
        break;
      case 'CANCELLED':
        style = 'bg-rose-50 text-rose-800 border-rose-200';
        break;
      default:
        style = 'bg-slate-100 text-slate-700 border-slate-200';
    }
  } else if (role) {
    switch (role) {
      case 'ADMIN':
        style = 'bg-[#0d1c32] text-white border-[#0d1c32] font-semibold';
        break;
      case 'DRAUGHTSMAN':
        style = 'bg-blue-50 text-[#0453cd] border-blue-200 font-semibold';
        break;
      case 'CLIENT':
        style = 'bg-indigo-50 text-indigo-700 border-indigo-200 font-semibold';
        break;
      case 'STUDENT':
        style = 'bg-emerald-50 text-emerald-700 border-emerald-200 font-semibold';
        break;
    }
  } else if (variant) {
    switch (variant) {
      case 'success':
        style = 'bg-emerald-50 text-emerald-800 border-emerald-200';
        break;
      case 'warning':
        style = 'bg-amber-50 text-amber-800 border-amber-200';
        break;
      case 'danger':
        style = 'bg-rose-50 text-rose-800 border-rose-200';
        break;
      case 'info':
        style = 'bg-blue-50 text-blue-800 border-blue-200';
        break;
      case 'purple':
        style = 'bg-purple-50 text-purple-800 border-purple-200';
        break;
    }
  }

  const sizeClass = size === 'sm' ? 'px-2 py-0.5 text-[11px]' : 'px-2.5 py-1 text-xs';
  const label = children || (status ? formatStatus(status) : formatRole(role));

  return (
    <span
      className={`inline-flex items-center gap-1.5 font-mono font-medium rounded-full border transition-colors shadow-xs ${sizeClass} ${style}`}
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
  if (status === 'UNDER_CLIENT_REVIEW' || status === 'UNDER_ENGINEER_REVIEW') {
    return 'Under Engineer Review';
  }
  return status
    .split('_')
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
    .join(' ');
}

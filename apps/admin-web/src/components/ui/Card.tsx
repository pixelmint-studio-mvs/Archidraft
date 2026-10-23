import React, { ReactNode } from 'react';

interface CardProps {
  children: ReactNode;
  className?: string;
  onClick?: () => void;
  hoverable?: boolean;
  technicalCorners?: boolean;
}

export function Card({
  children,
  className = '',
  onClick,
  hoverable = false,
  technicalCorners = false,
}: CardProps) {
  return (
    <div
      onClick={onClick}
      className={`relative bg-white border border-slate-200 rounded-xl p-5 soft-elevation transition-all duration-200 ${
        hoverable ? 'hover:border-slate-300 hover:shadow-md cursor-pointer' : ''
      } ${className}`}
    >
      {technicalCorners && (
        <>
          <span className="absolute top-2 left-2 text-slate-300 font-mono text-[10px] leading-none pointer-events-none select-none">+</span>
          <span className="absolute top-2 right-2 text-slate-300 font-mono text-[10px] leading-none pointer-events-none select-none">+</span>
          <span className="absolute bottom-2 left-2 text-slate-300 font-mono text-[10px] leading-none pointer-events-none select-none">+</span>
          <span className="absolute bottom-2 right-2 text-slate-300 font-mono text-[10px] leading-none pointer-events-none select-none">+</span>
        </>
      )}
      {children}
    </div>
  );
}

export function CardHeader({
  title,
  subtitle,
  action,
  className = '',
}: {
  title: string;
  subtitle?: string;
  action?: ReactNode;
  className?: string;
}) {
  return (
    <div className={`flex items-start justify-between mb-4 ${className}`}>
      <div>
        <h3 className="text-base font-semibold text-slate-900 tracking-tight">{title}</h3>
        {subtitle && <p className="text-xs text-slate-500 mt-0.5">{subtitle}</p>}
      </div>
      {action && <div>{action}</div>}
    </div>
  );
}


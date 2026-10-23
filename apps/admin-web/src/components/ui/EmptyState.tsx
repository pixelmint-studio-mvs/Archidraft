'use client';

import React from 'react';
import Link from 'next/link';
import { FolderOpen, MapPin, PlusCircle, CloudUpload, FileCode2 } from 'lucide-react';

interface EmptyStateProps {
  title?: string;
  description?: string;
  primaryAction?: {
    label: string;
    onClick?: () => void;
    href?: string;
  };
  secondaryAction?: {
    label: string;
    onClick?: () => void;
    href?: string;
  };
  coordinateHud?: string;
  gridLabel?: string;
  statusBadge?: string;
  scaleLabel?: string;
  compact?: boolean;
}

export function EmptyState({
  title = 'Technical Vault Empty',
  description = 'No active records, drawings, or project items detected in this workspace repository.',
  primaryAction,
  secondaryAction,
  coordinateHud = '+40.7128° N, -74.0060° W',
  gridLabel = 'GRID: 40MM ISOM',
  statusBadge = '0 RECORDS // D1 VAULT READY',
  scaleLabel = 'SCALE: 1:100 (METRIC)',
  compact = false,
}: EmptyStateProps) {
  return (
    <div className={`relative rounded-xl bg-white border border-slate-200 p-6 md:p-8 soft-elevation overflow-hidden ${compact ? 'max-w-xl mx-auto my-4' : 'w-full'}`}>
      {/* Technical Corner Crosshairs */}
      <span className="absolute top-3 left-3 text-slate-300 font-mono text-xs leading-none select-none pointer-events-none">+</span>
      <span className="absolute top-3 right-3 text-slate-300 font-mono text-xs leading-none select-none pointer-events-none">+</span>
      <span className="absolute bottom-3 left-3 text-slate-300 font-mono text-xs leading-none select-none pointer-events-none">+</span>
      <span className="absolute bottom-3 right-3 text-slate-300 font-mono text-xs leading-none select-none pointer-events-none">+</span>

      {/* Coordinate HUD Header */}
      <div className="flex items-center justify-between mb-4 pb-2 border-b border-slate-100">
        <div className="flex items-center gap-1.5 bg-slate-50 border border-slate-200/70 px-2.5 py-1 rounded text-slate-500 text-xs font-mono">
          <MapPin className="h-3 w-3 text-slate-400" />
          <span>{coordinateHud}</span>
        </div>
        <div className="bg-blue-50 text-[#0453cd] border border-blue-200 px-2.5 py-1 rounded font-mono text-[11px] font-semibold tracking-wider uppercase">
          {gridLabel}
        </div>
      </div>

      {/* Title & Description */}
      <div className="flex items-center gap-2 mb-2">
        <div className="p-2 rounded-lg bg-blue-50 text-[#0453cd]">
          <FolderOpen className="h-5 w-5" />
        </div>
        <h3 className="text-lg font-bold text-slate-900 tracking-tight">{title}</h3>
      </div>
      <p className="text-sm text-slate-600 mb-6 max-w-xl">{description}</p>

      {/* Precision Drafting Wireframe SVG (Isometric Projection from Stitch) */}
      <div className="relative w-full h-44 flex items-center justify-center bg-slate-50 border border-slate-200/80 rounded-lg overflow-hidden my-3">
        <svg
          className="w-full h-full text-[#0453cd]"
          fill="none"
          viewBox="0 0 320 180"
          xmlns="http://www.w3.org/2000/svg"
        >
          <defs>
            <pattern id="iso-dots-svg" patternUnits="userSpaceOnUse" width="20" height="20">
              <circle cx="2" cy="2" r="1" fill="#75777e" fillOpacity="0.25" />
            </pattern>
          </defs>
          <rect width="100%" height="100%" fill="url(#iso-dots-svg)" />
          
          {/* Axis Guides */}
          <line x1="160" y1="10" x2="160" y2="170" stroke="#cbd5e1" strokeWidth="1" strokeDasharray="3 3" />
          <line x1="20" y1="90" x2="300" y2="90" stroke="#cbd5e1" strokeWidth="1" strokeDasharray="3 3" />
          
          {/* Isometric Volume Box */}
          <g stroke="#0453cd" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round">
            <polygon points="160,35 225,65 160,95 95,65" fill="#356ee7" fillOpacity="0.08" />
            <polygon points="95,65 160,95 160,145 95,115" fill="#0453cd" fillOpacity="0.04" />
            <polygon points="160,95 225,65 225,115 160,145" fill="#0453cd" fillOpacity="0.12" />
            <line x1="160" y1="95" x2="160" y2="40" stroke="#0453cd" strokeDasharray="2 2" strokeOpacity="0.4" />
            <line x1="95" y1="65" x2="160" y2="40" stroke="#0453cd" strokeDasharray="2 2" strokeOpacity="0.4" />
            <line x1="225" y1="65" x2="160" y2="40" stroke="#0453cd" strokeDasharray="2 2" strokeOpacity="0.4" />
          </g>
          
          {/* Calibrated Dimension Anchors */}
          <circle cx="160" cy="35" r="3" fill="#0453cd" />
          <circle cx="225" cy="65" r="3" fill="#0453cd" />
          <circle cx="160" cy="145" r="3" fill="#0453cd" />
          <circle cx="95" cy="65" r="3" fill="#0453cd" />
          <circle cx="160" cy="95" r="2" fill="#0453cd" />
          
          <line x1="235" y1="65" x2="255" y2="65" stroke="#94a3b8" strokeWidth="1" />
          <line x1="235" y1="115" x2="255" y2="115" stroke="#94a3b8" strokeWidth="1" />
          <line x1="250" y1="65" x2="250" y2="115" stroke="#94a3b8" strokeWidth="1" strokeDasharray="2 2" />
          <text x="256" y="93" fill="#475569" fontFamily="monospace" fontSize="8" letterSpacing="0.05em">H: 0.00m</text>
        </svg>

        {/* Center Floating Status Badge */}
        <div className="absolute flex items-center gap-1.5 bg-white/95 backdrop-blur-md px-3 py-1.5 rounded-lg border border-slate-200/90 shadow-sm">
          <FileCode2 className="h-3.5 w-3.5 text-blue-600" />
          <span className="font-mono text-xs font-semibold text-slate-800">{statusBadge}</span>
        </div>
      </div>

      {/* Scale Status Footer */}
      <div className="flex items-center justify-between mt-3 bg-slate-50 border border-slate-200/60 px-3 py-2 rounded text-xs font-mono">
        <div className="flex items-center gap-2">
          <span className="h-2 w-2 rounded-full bg-emerald-500" />
          <span className="text-slate-700 font-medium">VIEWPORT READY</span>
        </div>
        <span className="text-slate-500">{scaleLabel}</span>
      </div>

      {/* Action Buttons */}
      {(primaryAction || secondaryAction) && (
        <div className="flex flex-wrap items-center gap-3 mt-6 pt-4 border-t border-slate-100">
          {primaryAction && (
            primaryAction.href ? (
              <Link
                href={primaryAction.href}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg bg-[#0d1c32] hover:bg-[#15294a] text-white text-xs font-semibold transition-all shadow-sm"
              >
                <PlusCircle className="h-4 w-4 text-emerald-400" />
                <span>{primaryAction.label}</span>
              </Link>
            ) : (
              <button
                onClick={primaryAction.onClick}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg bg-[#0d1c32] hover:bg-[#15294a] text-white text-xs font-semibold transition-all shadow-sm cursor-pointer"
              >
                <PlusCircle className="h-4 w-4 text-emerald-400" />
                <span>{primaryAction.label}</span>
              </button>
            )
          )}
          {secondaryAction && (
            secondaryAction.href ? (
              <Link
                href={secondaryAction.href}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-semibold transition-all shadow-xs"
              >
                <CloudUpload className="h-4 w-4 text-[#0453cd]" />
                <span>{secondaryAction.label}</span>
              </Link>
            ) : (
              <button
                onClick={secondaryAction.onClick}
                className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg bg-white border border-slate-200 hover:bg-slate-50 text-slate-700 text-xs font-semibold transition-all shadow-xs cursor-pointer"
              >
                <CloudUpload className="h-4 w-4 text-[#0453cd]" />
                <span>{secondaryAction.label}</span>
              </button>
            )
          )}
        </div>
      )}
    </div>
  );
}

'use client';

import React from 'react';

interface DraughtsmanBrandSignatureProps {
  className?: string;
  compact?: boolean;
}

export function DraughtsmanBrandSignature({
  className = '',
  compact = false,
}: DraughtsmanBrandSignatureProps) {
  return (
    <div
      className={`flex flex-col items-center justify-center select-none ${className}`}
      aria-label="DRAUGHTSMAN STUDIO"
    >
      {/* Top Drafting Guide Line with Precision Registration Marks */}
      <div className="relative flex items-center justify-center w-full max-w-[200px] md:max-w-[240px] h-2">
        {/* Animated Linework */}
        <div className="h-[1px] w-full bg-slate-300/80 animate-[draftingLine_1.2s_cubic-bezier(0.16,1,0.3,1)_forwards] origin-center" />
        
        {/* Precision Registration End Ticks */}
        <div className="absolute left-0 top-0 bottom-0 w-[1px] bg-slate-400" />
        <div className="absolute right-0 top-0 bottom-0 w-[1px] bg-slate-400" />
        <div className="absolute left-1/2 -translate-x-1/2 top-0.5 bottom-0.5 w-[1px] bg-slate-300" />
      </div>

      {/* Main Studio Wordmark with Letter-Spacing Transition */}
      <h2
        className={`font-mono uppercase font-bold text-slate-800 text-center tracking-[0.28em] md:tracking-[0.32em] my-1 transition-all duration-1000 ${
          compact ? 'text-[11px] md:text-xs' : 'text-xs md:text-sm'
        }`}
        style={{
          fontFeatureSettings: '"tnum" 1, "zero" 1',
        }}
      >
        DRAUGHTSMAN STUDIO
      </h2>

      {/* Bottom Drafting Guide Line */}
      <div className="relative flex items-center justify-center w-full max-w-[200px] md:max-w-[240px] h-2">
        <div className="h-[1px] w-full bg-slate-300/80 animate-[draftingLine_1.2s_cubic-bezier(0.16,1,0.3,1)_forwards] origin-center" />
        
        <div className="absolute left-0 top-0 bottom-0 w-[1px] bg-slate-400" />
        <div className="absolute right-0 top-0 bottom-0 w-[1px] bg-slate-400" />
        <div className="absolute left-1/2 -translate-x-1/2 top-0.5 bottom-0.5 w-[1px] bg-slate-300" />
      </div>
    </div>
  );
}

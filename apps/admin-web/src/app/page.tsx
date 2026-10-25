import React from 'react';
import Link from 'next/link';
import {
  ArrowRight,
  TrendingUp,
  Layers,
  FolderKanban,
  HardHat,
  ShieldCheck,
  CheckCircle2,
  FileCode2,
  Cpu,
  Compass,
} from 'lucide-react';

import { Monogram3DViewer } from '@/components/ui/Monogram3DViewer';
import { DraughtsmanBrandSignature } from '@/components/ui/DraughtsmanBrandSignature';

export default function LandingPage() {
  return (
    <div className="min-h-screen bg-[#fbf9fb] text-slate-900 blueprint-bg flex flex-col justify-between selection:bg-[#0453cd] selection:text-white relative overflow-x-hidden">
      {/* Top Technical Metadata Bar */}
      <header className="w-full border-b border-slate-200/80 bg-white/70 backdrop-blur-md sticky top-0 z-30 px-6 lg:px-16 py-3 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="h-8 w-8 shrink-0 flex items-center justify-center">
            <Monogram3DViewer className="w-full h-full" autoRotate={true} revolutionDuration={10} />
          </div>
          <div className="flex items-center gap-2">
            <span className="font-mono text-xs font-bold text-slate-900 tracking-wider uppercase">
              Archi Draft
            </span>
            <span className="hidden sm:inline-block px-1.5 py-0.5 rounded bg-emerald-50 text-emerald-700 border border-emerald-200 font-mono text-[10px] font-semibold leading-none">
              SYS_NODE // ACTIVE
            </span>
          </div>
        </div>

        <div className="flex items-center gap-4">
          <div className="hidden md:flex items-center gap-2 text-xs font-mono text-slate-500">
            <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
            <span>DRAUGHTSMAN STUDIO OS</span>
          </div>
          <Link
            href="/login"
            className="inline-flex items-center gap-2 px-4 py-2 rounded-lg bg-[#0d1c32] hover:bg-[#15294a] text-white text-xs font-semibold font-mono tracking-wider transition-all shadow-sm active:scale-[0.98]"
          >
            <span>STUDIO ACCESS</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>
      </header>

      {/* Main Showcase Section */}
      <main className="flex-1 max-w-5xl mx-auto w-full px-6 py-12 md:py-20 flex flex-col items-center">
        {/* Main Brand Presentation: Floating 3D Monogram & Architectural Brand Signature */}
        <div className="flex flex-col items-center justify-center mb-10">
          <div className="w-28 h-28 sm:w-36 sm:h-36 md:w-44 md:h-44 flex items-center justify-center relative">
            <Monogram3DViewer className="w-full h-full" autoRotate={true} revolutionDuration={10} />
          </div>
          <DraughtsmanBrandSignature className="mt-4" />
        </div>

        {/* Hero Headlines */}
        <div className="text-center max-w-2xl mx-auto mb-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-blue-50 border border-blue-200 text-[#0453cd] font-mono text-xs font-semibold mb-6">
            <Compass className="h-3.5 w-3.5" />
            <span>ARCHITECTURAL PRECISION SYSTEM</span>
          </div>
          <h1 className="text-4xl sm:text-5xl md:text-6xl font-extrabold tracking-tight text-slate-900 leading-[1.1] mb-6">
            Precision.<br />
            <span className="text-[#0453cd]">Design.</span><br />
            Delivery.
          </h1>
          <p className="text-base sm:text-lg text-slate-600 max-w-xl mx-auto leading-relaxed">
            Rigorous engineering software for architects, structural draughtsmen, and project governance at Draughtsman Studio.
          </p>
        </div>

        {/* Action Button */}
        <div className="flex flex-col sm:flex-row items-center gap-4 mb-16 w-full max-w-md justify-center">
          <Link
            href="/login"
            className="w-full sm:w-auto flex-1 inline-flex items-center justify-center gap-2.5 px-8 py-4 rounded-xl bg-[#0d1c32] hover:bg-[#15294a] text-white font-semibold text-sm shadow-md transition-all active:scale-[0.98] group"
          >
            <span>Enter Studio Admin Console</span>
            <ArrowRight className="h-4 w-4 group-hover:translate-x-1 transition-transform text-blue-300" />
          </Link>
        </div>

        {/* Live Ecosystem Bento Grid */}
        <div className="w-full grid grid-cols-1 md:grid-cols-3 gap-5 mb-16">
          {/* Card 1: Active Projects */}
          <div className="bg-white border border-slate-200 rounded-2xl p-6 soft-elevation relative overflow-hidden">
            <div className="flex items-center justify-between mb-4">
              <span className="font-mono text-xs font-bold text-slate-500 uppercase tracking-wider">
                Projects Active
              </span>
              <div className="p-2 rounded-lg bg-blue-50 text-[#0453cd]">
                <FolderKanban className="h-4 w-4" />
              </div>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 font-mono tracking-tight mb-2">
              1,204
            </div>
            <div className="flex items-center gap-1.5 text-xs text-emerald-600 font-medium font-mono">
              <TrendingUp className="h-3.5 w-3.5" />
              <span>+12% verified throughput this cycle</span>
            </div>
          </div>

          {/* Card 2: Drawings Verified */}
          <div className="bg-white border border-slate-200 rounded-2xl p-6 soft-elevation relative overflow-hidden">
            <div className="flex items-center justify-between mb-4">
              <span className="font-mono text-xs font-bold text-slate-500 uppercase tracking-wider">
                Drawings Verified
              </span>
              <div className="p-2 rounded-lg bg-indigo-50 text-indigo-600">
                <Layers className="h-4 w-4" />
              </div>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 font-mono tracking-tight mb-2">
              8,420
            </div>
            <div className="flex items-center gap-1.5 text-xs text-slate-500 font-mono">
              <span>AIA CAD Standards &bull; Multi-tier QA</span>
            </div>
          </div>

          {/* Card 3: Engineers & Draughtsmen */}
          <div className="bg-white border border-slate-200 rounded-2xl p-6 soft-elevation relative overflow-hidden">
            <div className="flex items-center justify-between mb-4">
              <span className="font-mono text-xs font-bold text-slate-500 uppercase tracking-wider">
                Engineers Joined
              </span>
              <div className="p-2 rounded-lg bg-emerald-50 text-emerald-600">
                <HardHat className="h-4 w-4" />
              </div>
            </div>
            <div className="text-3xl font-extrabold text-slate-900 font-mono tracking-tight mb-2">
              450+
            </div>
            <div className="flex items-center gap-1.5 text-xs text-slate-500 font-mono">
              <span>Licensed structural & MEP professionals</span>
            </div>
          </div>
        </div>

        {/* Technical Architectural Guidance Cards */}
        <div className="w-full mb-16">
          <div className="flex items-center gap-4 mb-6">
            <div className="h-px bg-slate-200 flex-1" />
            <span className="font-mono text-xs font-bold text-slate-400 uppercase tracking-widest">
              SYSTEM ARCHITECTURE CAPABILITIES
            </span>
            <div className="h-px bg-slate-200 flex-1" />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="bg-white border border-slate-200 rounded-xl p-5 soft-elevation">
              <div className="flex items-center gap-2 mb-2">
                <span className="font-mono text-xs font-bold text-[#0453cd] bg-blue-50 px-2 py-0.5 rounded">01</span>
                <h3 className="text-sm font-bold text-slate-900">AIA Layer Compliance</h3>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                Automated validation of layer keys, line weights, scale tags, and dimensional tolerances against standard drafting rules.
              </p>
            </div>

            <div className="bg-white border border-slate-200 rounded-xl p-5 soft-elevation">
              <div className="flex items-center gap-2 mb-2">
                <span className="font-mono text-xs font-bold text-[#0453cd] bg-blue-50 px-2 py-0.5 rounded">02</span>
                <h3 className="text-sm font-bold text-slate-900">Real-Time Redline Sync</h3>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                Collaborate between Studio Admins and structural engineers with a strict 3-round cap and auditable state machine progression.
              </p>
            </div>

            <div className="bg-white border border-slate-200 rounded-xl p-5 soft-elevation">
              <div className="flex items-center gap-2 mb-2">
                <span className="font-mono text-xs font-bold text-[#0453cd] bg-blue-50 px-2 py-0.5 rounded">03</span>
                <h3 className="text-sm font-bold text-slate-900">Cloud Storage Bridges</h3>
              </div>
              <p className="text-xs text-slate-600 leading-relaxed">
                Native Cloudflare R2 object storage integration, D1 SQLite edge consistency, and client-side vector PDF synthesis.
              </p>
            </div>
          </div>
        </div>

        {/* Telemetry Strip */}
        <div className="flex items-center gap-2 px-4 py-2 rounded-full bg-white border border-slate-200/90 shadow-xs text-xs font-mono text-slate-600">
          <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
          <span>LATENCY: 14ms &bull; D1 DATABASE READY &bull; HONO WORKER ACTIVE</span>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full border-t border-slate-200/80 bg-white/70 py-6 text-center text-xs font-mono text-slate-500">
        <p className="uppercase tracking-wider">
          UI/UX Design &amp; Product Experience crafted by PixelMint Studio MVS &bull; Draughtsman Studio
        </p>
      </footer>
    </div>
  );
}

'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { ArrowRight, UserCheck } from 'lucide-react';

/**
 * Compatibility redirect for bookmarked /assignments URLs.
 * The Assign Projects console has permanently relocated to Teaching Students (/teaching/assignments).
 */
export default function LegacyAssignmentsRedirectPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace('/teaching/assignments');
  }, [router]);

  return (
    <div className="min-h-screen bg-[#070e18] flex items-center justify-center p-6 text-white font-mono">
      <div className="max-w-md w-full bg-[#0d1c32] border border-[#1e293b] rounded-2xl p-8 shadow-2xl text-center space-y-4">
        <div className="h-12 w-12 rounded-xl bg-blue-500/10 border border-blue-500/30 text-[#0453cd] flex items-center justify-center mx-auto">
          <UserCheck className="h-6 w-6 text-blue-400 animate-pulse" />
        </div>
        <div className="space-y-1">
          <h2 className="text-base font-bold text-slate-100">Relocating to Teaching Students</h2>
          <p className="text-xs text-slate-400">
            Assign Projects is now organized under the Teaching Students portal section.
          </p>
        </div>
        <div className="pt-2">
          <Link
            href="/teaching/assignments"
            className="inline-flex items-center gap-2 px-4 py-2 bg-[#0453cd] hover:bg-blue-600 text-white rounded-lg text-xs font-semibold transition-all shadow-md"
          >
            <span>Proceed to Assign Projects</span>
            <ArrowRight className="h-3.5 w-3.5" />
          </Link>
        </div>
      </div>
    </div>
  );
}

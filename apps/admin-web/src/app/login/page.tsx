'use client';

import React, { useState, useEffect } from 'react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { useAuth } from '@/lib/auth';
import { ShieldCheck, Lock, Mail, AlertCircle, ArrowRight } from 'lucide-react';
import { Monogram3DViewer } from '@/components/ui/Monogram3DViewer';
import { DraughtsmanBrandSignature } from '@/components/ui/DraughtsmanBrandSignature';

export default function LoginPage() {
  const [email, setEmail] = useState('contact@draughtsmanstudio.com');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [localError, setLocalError] = useState<string | null>(null);

  const { user, login, error: authError } = useAuth();
  const router = useRouter();

  useEffect(() => {
    if (user && (user.role === 'ADMIN' || user.role === 'STUDIO_ADMIN')) {
      router.replace('/dashboard');
    }
  }, [user, router]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (loading) return;

    setLocalError(null);

    const trimmedEmail = email.trim();
    if (!trimmedEmail) {
      setLocalError('Please enter your email address.');
      return;
    }
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(trimmedEmail)) {
      setLocalError('Please enter a valid email address.');
      return;
    }
    if (!password) {
      setLocalError('Please enter your password.');
      return;
    }

    setLoading(true);

    try {
      await login(trimmedEmail, password);
      router.replace('/dashboard');
    } catch (err: any) {
      setLocalError(err.message || 'Invalid email or password. Please check your credentials and try again.');
    } finally {
      setLoading(false);
    }
  };

  const displayError = localError || authError;

  return (
    <div
      className="blueprint-bg min-h-screen text-slate-900 selection:bg-[#0453cd] selection:text-white flex flex-col justify-between relative overflow-x-hidden p-6 md:p-12"
      suppressHydrationWarning
    >
      {/* Top Left Technical Tag */}
      <div className="absolute top-6 left-6 md:top-10 md:left-12 text-slate-400 font-mono text-xs hidden sm:flex items-center gap-2">
        <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse" />
        <span>SYS.ADMIN.AUTH.v2.4 // PROTOCOL_SECURE</span>
      </div>

      {/* Main Content Area */}
      <main className="flex-1 flex items-center justify-center py-10 relative z-10">
        <div className="w-full max-w-[440px]">
          {/* Main Brand Presentation: Floating 3D Monogram & Architectural Brand Signature */}
          <div className="flex flex-col items-center justify-center mb-6 relative">
            <div className="w-20 h-20 sm:w-24 sm:h-24 relative flex items-center justify-center">
              <Monogram3DViewer className="w-full h-full" autoRotate={true} revolutionDuration={10} />
            </div>
            <DraughtsmanBrandSignature compact className="mt-2" />
          </div>

          {/* Login Card (Stitch Architectural Precision System) */}
          <div className="bg-white rounded-2xl glass-elevation p-8 md:p-10 relative border border-slate-200">
            {/* Corner Technical Marks */}
            <div className="technical-corner-tl" />
            <div className="technical-corner-tr" />
            <div className="technical-corner-bl" />
            <div className="technical-corner-br" />

            {/* Header */}
            <div className="text-center mb-6">
              <div className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full bg-blue-50 text-[#0453cd] border border-blue-200 text-[11px] font-mono font-semibold mb-3">
                <ShieldCheck className="h-3.5 w-3.5" />
                <span>STUDIO ADMIN CONSOLE</span>
              </div>
              <h1 className="text-2xl md:text-3xl font-extrabold text-slate-900 tracking-tight">
                Studio Access
              </h1>
              <p className="text-xs text-slate-500 mt-1 font-sans">
                Enter your credentials to access the administrative workspace.
              </p>
            </div>

            {/* Error Message */}
            {displayError && (
              <div className="mb-5 flex items-start gap-2.5 p-3.5 text-xs text-rose-800 bg-rose-50 border border-rose-200 rounded-xl">
                <AlertCircle className="h-4 w-4 text-rose-600 shrink-0 mt-0.5" />
                <span className="font-medium">{displayError}</span>
              </div>
            )}

            {/* Form */}
            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="space-y-1.5">
                <label className="block font-mono text-[11px] font-semibold text-slate-700 uppercase tracking-wider">
                  Admin Email
                </label>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                    <Mail className="h-4 w-4" />
                  </span>
                  <input
                    id="admin-email-input"
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="contact@draughtsmanstudio.com"
                    required
                    className="w-full bg-[#fbf9fb] pl-10 pr-4 py-2.5 border border-slate-300/80 rounded-lg text-slate-900 text-sm font-sans focus:ring-4 focus:ring-blue-500/10 focus:border-[#0453cd] transition-all outline-none"
                  />
                </div>
              </div>

              <div className="space-y-1.5">
                <div className="flex justify-between items-center">
                  <label htmlFor="admin-password-input" className="block font-mono text-[11px] font-semibold text-slate-700 uppercase tracking-wider">
                    Access Key / Password
                  </label>
                  <Link
                    href="/forgot-password"
                    className="font-mono text-[11px] text-[#0453cd] hover:underline transition-colors"
                  >
                    Restore Access?
                  </Link>
                </div>
                <div className="relative">
                  <span className="absolute inset-y-0 left-0 flex items-center pl-3.5 text-slate-400">
                    <Lock className="h-4 w-4" />
                  </span>
                  <input
                    id="admin-password-input"
                    type="password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    placeholder="••••••••••••"
                    required
                    className="w-full bg-[#fbf9fb] pl-10 pr-4 py-2.5 border border-slate-300/80 rounded-lg text-slate-900 text-sm font-sans focus:ring-4 focus:ring-blue-500/10 focus:border-[#0453cd] transition-all outline-none"
                  />
                </div>
              </div>

              {/* Action Button */}
              <button
                id="admin-login-submit"
                type="submit"
                disabled={loading}
                className="w-full bg-[#0d1c32] hover:bg-[#15294a] text-white py-3 px-6 rounded-lg font-mono text-xs font-semibold tracking-wider transition-all duration-200 flex items-center justify-center gap-2 shadow-sm disabled:opacity-50 cursor-pointer active:scale-[0.98]"
              >
                {loading ? (
                  <span className="inline-flex items-center gap-2">
                    <span className="h-4 w-4 border-2 border-white border-t-transparent rounded-full animate-spin" />
                    <span>AUTHENTICATING...</span>
                  </span>
                ) : (
                  <>
                    <span>SECURE SIGN IN</span>
                    <ArrowRight className="h-3.5 w-3.5 text-blue-300" />
                  </>
                )}
              </button>
            </form>

            {/* Security Notice */}
            <div className="mt-6 pt-5 border-t border-slate-100 text-center">
              <p className="font-mono text-[11px] text-slate-500">
                Protected Studio Administrative Environment
              </p>
              <p className="text-[11px] text-slate-400 mt-1">
                Accounts are managed by Draughtsman Studio.
              </p>
            </div>
          </div>
        </div>
      </main>

      {/* Footer Credit */}
      <footer className="w-full text-center py-4 relative z-10">
        <p className="font-mono text-[11px] text-slate-400 uppercase tracking-widest">
          UI/UX Design &amp; Product Experience crafted by PixelMint Studio MVS &bull; Draughtsman Studio
        </p>
      </footer>
    </div>
  );
}

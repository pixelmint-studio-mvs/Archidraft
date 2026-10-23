'use client';

import React, { useState } from 'react';
import Link from 'next/link';
import { sendPasswordResetEmail } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import {
  Mail,
  ArrowLeft,
  CheckCircle2,
  AlertCircle,
  Compass,
} from 'lucide-react';

export default function ForgotPasswordPage() {
  const [email, setEmail] = useState('');
  const [loading, setLoading] = useState(false);
  const [sent, setSent] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!email.trim()) return;
    setLoading(true);
    setError(null);

    try {
      await sendPasswordResetEmail(auth, email.trim());
      setSent(true);
    } catch (err: any) {
      const code: string = err?.code || '';
      if (code === 'auth/user-not-found') {
        setError('No account found with this email address.');
      } else if (code === 'auth/invalid-email') {
        setError('Please enter a valid email address.');
      } else if (code === 'auth/too-many-requests') {
        setError('Too many attempts. Please wait a moment before trying again.');
      } else {
        setError(err?.message || 'Failed to send recovery email. Please try again.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <div
      className="min-h-screen flex flex-col justify-between relative overflow-hidden"
      style={{ backgroundColor: '#fbf9fb' }}
    >
      {/* Blueprint grid texture */}
      <div
        className="absolute inset-0 pointer-events-none z-0"
        style={{
          backgroundImage:
            'linear-gradient(to right, rgba(117,119,126,0.07) 1px, transparent 1px), linear-gradient(to bottom, rgba(117,119,126,0.07) 1px, transparent 1px)',
          backgroundSize: '40px 40px',
        }}
      />

      {/* Main centred card */}
      <main className="flex-grow flex items-center justify-center px-4 md:px-16 py-12 relative z-10">
        <div
          className="w-full max-w-md rounded-xl p-8 relative"
          style={{
            background: '#ffffff',
            border: '1px solid rgba(197,198,205,0.6)',
            boxShadow: '0 1px 0 rgba(0,0,0,0.05), 0 20px 40px -10px rgba(0,0,0,0.04)',
          }}
        >
          {/* Technical accent line at top */}
          <div className="absolute top-0 left-0 right-0 h-px" style={{ background: '#0d1c32' }} />

          {/* Corner Technical Marks */}
          <div className="technical-corner-tl" />
          <div className="technical-corner-tr" />
          <div className="technical-corner-bl" />
          <div className="technical-corner-br" />

          {/* Brand */}
          <div className="flex flex-col items-center mb-8">
            <img
              src="/draughtsman_logo.jpeg"
              alt="Draughtsman Studio Logo"
              className="h-14 w-14 rounded-2xl object-cover bg-slate-900 border border-slate-700/60 shadow-md mb-3"
            />
            <h1 className="text-xl font-bold tracking-tight text-slate-900">
              DRAUGHTSMAN STUDIO
            </h1>
            <p className="text-[11px] font-mono uppercase tracking-widest text-slate-400 mt-0.5">
              Access Recovery
            </p>
          </div>

          {sent ? (
            /* ── Success state ── */
            <div className="text-center space-y-4">
              <div className="flex justify-center">
                <div className="h-14 w-14 rounded-full flex items-center justify-center"
                  style={{ background: 'rgba(6,150,105,0.08)', border: '1px solid rgba(6,150,105,0.2)' }}
                >
                  <CheckCircle2 className="h-7 w-7" style={{ color: '#069669' }} />
                </div>
              </div>
              <div>
                <h2 className="text-xl font-semibold" style={{ color: '#1b1b1d' }}>Recovery Email Sent</h2>
                <p className="text-sm mt-2" style={{ color: '#44474d' }}>
                  A password reset link has been dispatched to{' '}
                  <span className="font-mono font-medium" style={{ color: '#0d1c32' }}>{email}</span>.
                  Please check your inbox and follow the instructions.
                </p>
              </div>
              <p className="text-[11px] font-mono" style={{ color: '#75777e' }}>
                Didn't receive it? Check your spam folder or{' '}
                <button
                  onClick={() => { setSent(false); setError(null); }}
                  className="underline transition-colors"
                  style={{ color: '#0453cd' }}
                >
                  try again
                </button>.
              </p>
              <div className="pt-4">
                <Link href="/login"
                  className="flex items-center justify-center gap-2 text-sm font-semibold transition-colors"
                  style={{ color: '#0453cd' }}
                >
                  <ArrowLeft className="h-4 w-4" />
                  Return to Login
                </Link>
              </div>
            </div>
          ) : (
            /* ── Form state ── */
            <>
              <div className="text-center mb-8">
                <h2 className="text-2xl font-semibold" style={{ color: '#1b1b1d' }}>Restore Access</h2>
                <p className="text-sm mt-2" style={{ color: '#44474d' }}>
                  Enter your registered email address to receive a recovery code.
                </p>
              </div>

              {error && (
                <div className="mb-5 flex items-center gap-2.5 p-3 rounded-lg text-sm"
                  style={{ background: 'rgba(186,26,26,0.06)', border: '1px solid rgba(186,26,26,0.2)', color: '#93000a' }}
                >
                  <AlertCircle className="h-4 w-4 shrink-0" />
                  <span>{error}</span>
                </div>
              )}

              <form onSubmit={handleSubmit} className="space-y-6">
                <div>
                  <label
                    htmlFor="email"
                    className="block text-[11px] font-mono uppercase tracking-widest mb-2"
                    style={{ color: '#1b1b1d' }}
                  >
                    Registered Email
                  </label>
                  <div className="relative">
                    <div className="absolute inset-y-0 left-0 pl-3.5 flex items-center pointer-events-none">
                      <Mail className="h-4 w-4" style={{ color: '#75777e' }} />
                    </div>
                    <input
                      id="email"
                      type="email"
                      required
                      value={email}
                      onChange={(e) => setEmail(e.target.value)}
                      placeholder="architect@studio.com"
                      className="block w-full pl-10 pr-4 py-3 text-sm rounded transition-all focus:outline-none"
                      style={{
                        background: '#f5f3f5',
                        border: '1px solid #c5c6cd',
                        color: '#1b1b1d',
                      }}
                      onFocus={(e) => {
                        e.target.style.borderColor = '#0453cd';
                        e.target.style.boxShadow = '0 0 0 4px rgba(4,83,205,0.08)';
                      }}
                      onBlur={(e) => {
                        e.target.style.borderColor = '#c5c6cd';
                        e.target.style.boxShadow = 'none';
                      }}
                    />
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading || !email.trim()}
                  className="w-full py-3 rounded text-sm font-semibold flex items-center justify-center gap-2 transition-all disabled:opacity-50 disabled:cursor-not-allowed"
                  style={{
                    background: '#0d1c32',
                    color: '#ffffff',
                    borderTop: '1px solid rgba(255,255,255,0.15)',
                  }}
                >
                  {loading ? (
                    <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
                  ) : (
                    'Send Recovery Code'
                  )}
                </button>
              </form>

              <div className="mt-8 text-center">
                <Link
                  href="/login"
                  className="inline-flex items-center gap-1 text-[12px] font-mono transition-colors"
                  style={{ color: '#44474d' }}
                  onMouseEnter={(e) => (e.currentTarget.style.color = '#0d1c32')}
                  onMouseLeave={(e) => (e.currentTarget.style.color = '#44474d')}
                >
                  <ArrowLeft className="h-3.5 w-3.5" />
                  Return to Login
                </Link>
              </div>
            </>
          )}
        </div>
      </main>

      {/* Footer signature */}
      <footer
        className="relative z-10 w-full py-5 px-4 md:px-16 flex justify-center md:justify-end"
        style={{ borderTop: '1px solid rgba(197,198,205,0.3)', background: 'rgba(251,249,251,0.85)' }}
      >
        <p className="text-[11px] font-mono" style={{ color: '#94a3b8' }}>
          UI/UX Design &amp; Product Experience crafted by PixelMint Studio MVS
        </p>
      </footer>
    </div>
  );
}

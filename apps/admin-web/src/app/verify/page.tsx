'use client';

import React, { useState, useRef, useEffect, Suspense } from 'react';
import Link from 'next/link';
import { useSearchParams, useRouter } from 'next/navigation';
import {
  ShieldCheck,
  ArrowLeft,
  RefreshCw,
  LogIn,
  AlertCircle,
  Compass,
  CheckCircle2,
  MailCheck,
} from 'lucide-react';
import { sendEmailVerification } from 'firebase/auth';
import { useAuth } from '@/lib/auth';

// OTP digit input component
function OtpInput({ onComplete }: { onComplete: (code: string) => void }) {
  const [digits, setDigits] = useState<string[]>(Array(6).fill(''));
  const refs = Array.from({ length: 6 }, () => useRef<HTMLInputElement>(null));

  useEffect(() => {
    refs[0]?.current?.focus();
  }, []);

  const handleChange = (idx: number, val: string) => {
    if (!/^\d?$/.test(val)) return;
    const next = [...digits];
    next[idx] = val;
    setDigits(next);
    if (val && idx < 5) {
      refs[idx + 1]?.current?.focus();
    }
    const full = next.join('');
    if (full.length === 6 && !next.includes('')) {
      onComplete(full);
    }
  };

  const handleKeyDown = (idx: number, e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === 'Backspace' && !digits[idx] && idx > 0) {
      refs[idx - 1]?.current?.focus();
    }
  };

  const handlePaste = (e: React.ClipboardEvent) => {
    const paste = e.clipboardData.getData('text').replace(/\D/g, '').slice(0, 6);
    if (paste.length === 6) {
      const next = paste.split('');
      setDigits(next);
      refs[5]?.current?.focus();
      onComplete(paste);
    }
    e.preventDefault();
  };

  return (
    <div className="flex justify-between gap-2 md:gap-3" onPaste={handlePaste}>
      {digits.map((d, i) => (
        <React.Fragment key={i}>
          {i === 3 && (
            // Separator dash between digit groups
            <div className="flex items-center justify-center w-4 shrink-0">
              <div className="w-full h-px" style={{ background: 'rgba(197,198,205,0.6)' }} />
            </div>
          )}
          <input
            ref={refs[i]}
            type="text"
            inputMode="numeric"
            maxLength={1}
            value={d}
            onChange={(e) => handleChange(i, e.target.value)}
            onKeyDown={(e) => handleKeyDown(i, e)}
            className="w-12 h-16 md:w-14 md:h-20 text-center text-2xl font-bold rounded transition-all focus:outline-none"
            style={{
              background: '#f5f3f5',
              border: `1px solid ${d ? '#0453cd' : '#c5c6cd'}`,
              color: '#0d1c32',
              boxShadow: d ? '0 0 0 3px rgba(4,83,205,0.1)' : 'inset 0 1px 3px rgba(0,0,0,0.04)',
            }}
            onFocus={(e) => {
              e.target.style.borderColor = '#0453cd';
              e.target.style.boxShadow = '0 0 0 4px rgba(4,83,205,0.08)';
            }}
            onBlur={(e) => {
              e.target.style.borderColor = d ? '#0453cd' : '#c5c6cd';
              e.target.style.boxShadow = d ? '0 0 0 3px rgba(4,83,205,0.1)' : 'inset 0 1px 3px rgba(0,0,0,0.04)';
            }}
            aria-label={`OTP digit ${i + 1}`}
          />
        </React.Fragment>
      ))}
    </div>
  );
}

function VerifyContent() {
  const params = useSearchParams();
  const router = useRouter();
  const { user, firebaseUser } = useAuth();

  const emailParam = params.get('email') || firebaseUser?.email || 'contact@draughtsmanstudio.com';
  const sessionId = params.get('session') || (firebaseUser?.uid ? `AUTH-${firebaseUser.uid.substring(0, 8).toUpperCase()}` : 'ARCH-7492');

  const [code, setCode] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);
  const [resent, setResent] = useState(false);
  const [resendCooldown, setResendCooldown] = useState(0);

  // If already verified, allow automatic entry to dashboard
  useEffect(() => {
    if (firebaseUser?.emailVerified && (user?.role === 'ADMIN' || user?.role === 'STUDIO_ADMIN')) {
      router.replace('/dashboard');
    }
  }, [firebaseUser, user, router]);

  // Countdown timer for resend
  useEffect(() => {
    if (resendCooldown <= 0) return;
    const t = setTimeout(() => setResendCooldown((c) => c - 1), 1000);
    return () => clearTimeout(t);
  }, [resendCooldown]);

  const handleComplete = (fullCode: string) => {
    setCode(fullCode);
    setError(null);
  };

  const handleVerify = async () => {
    if (!firebaseUser) {
      setError('No active session detected. Please sign in with your administrative credentials first.');
      return;
    }

    if (code.length !== 6) {
      setError('Please enter all 6 digits of your verification code.');
      return;
    }

    setLoading(true);
    setError(null);
    setStatusMessage(null);

    try {
      // Authoritative check: reload Firebase user to check emailVerified status
      await firebaseUser.reload();
      if (firebaseUser.emailVerified) {
        setStatusMessage('Administrative session verified successfully. Entering console…');
        setTimeout(() => router.replace('/dashboard'), 800);
        return;
      }

      // Authoritative security: Arbitrary 6-digit codes cannot bypass authentication
      setError(
        'Authoritative Verification Required: An enterprise OTP gateway is not provisioned for direct 6-digit exchange. Please verify via the official email link sent to your inbox, then click "Check Email Status".'
      );
    } catch (err: any) {
      setError(err.message || 'Verification check failed. Please refresh and retry.');
    } finally {
      setLoading(false);
    }
  };

  const handleCheckEmailStatus = async () => {
    if (!firebaseUser) {
      setError('Please log in with your administrative account first.');
      return;
    }
    setLoading(true);
    setError(null);
    setStatusMessage(null);
    try {
      await firebaseUser.reload();
      if (firebaseUser.emailVerified) {
        setStatusMessage('Email verified! Authorizing administrative workspace…');
        setTimeout(() => router.replace('/dashboard'), 800);
      } else {
        setError('Email is not yet verified. Please click the confirmation link sent to your inbox.');
      }
    } catch (err: any) {
      setError(err.message || 'Failed to check verification status.');
    } finally {
      setLoading(false);
    }
  };

  const handleResend = async () => {
    if (resendCooldown > 0) return;
    setResent(false);
    setError(null);
    setStatusMessage(null);

    if (!firebaseUser) {
      setError('No active session found. Please log in first to receive a verification email.');
      return;
    }

    try {
      await sendEmailVerification(firebaseUser);
      setResendCooldown(60);
      setResent(true);
      setTimeout(() => setResent(false), 5000);
    } catch (err: any) {
      setError(err.message || 'Failed to dispatch verification email.');
    }
  };

  return (
    <div
      className="min-h-screen flex flex-col justify-between relative overflow-hidden"
      style={{ backgroundColor: '#fbf9fb' }}
    >
      {/* Blueprint grid */}
      <div
        className="absolute inset-0 pointer-events-none z-0 opacity-30"
        style={{
          backgroundImage:
            'linear-gradient(to right, #e2e8f0 1px, transparent 1px), linear-gradient(to bottom, #e2e8f0 1px, transparent 1px)',
          backgroundSize: '40px 40px',
        }}
      />

      <main className="flex-grow flex items-center justify-center px-4 md:px-16 py-12 relative z-10">
        <div
          className="w-full max-w-[480px] rounded-xl p-8 md:p-12 relative overflow-hidden"
          style={{
            background: '#ffffff',
            border: '1px solid rgba(197,198,205,0.5)',
            boxShadow: '0 1px 0 rgba(0,0,0,0.05), 0 12px 40px rgba(0,0,0,0.03)',
          }}
        >
          {/* Technical accent lines */}
          <div className="absolute top-0 left-0 right-0 h-px" style={{ background: '#0d1c32' }} />
          <div className="absolute top-0 left-0 w-px bottom-0" style={{ background: 'rgba(13,28,50,0.08)' }} />
          <div className="absolute top-0 right-0 w-px bottom-0" style={{ background: 'rgba(13,28,50,0.08)' }} />

          {/* Corner Technical Marks */}
          <div className="technical-corner-tl" />
          <div className="technical-corner-tr" />
          <div className="technical-corner-bl" />
          <div className="technical-corner-br" />

          {/* Brand header */}
          <div className="text-center mb-8">
            <div className="flex justify-center mb-3">
              <img
                src="/draughtsman_logo.jpeg"
                alt="Draughtsman Studio Logo"
                className="h-14 w-14 rounded-2xl object-cover bg-slate-900 border border-slate-700/60 shadow-md"
              />
            </div>
            <h1 className="text-2xl font-bold tracking-tight text-slate-900">
              DRAUGHTSMAN STUDIO
            </h1>
            <p className="text-[11px] font-mono uppercase tracking-widest text-slate-400 mt-1">
              Secure Studio Verification
            </p>
          </div>

          {/* Context */}
          <div className="text-center mb-8">
            <p className="text-sm" style={{ color: '#44474d' }}>
              Enter the 6-digit authorization code sent to your registered device.
            </p>
            <p className="text-[12px] font-mono mt-2" style={{ color: '#0d1c32' }}>
              ID: <span style={{ color: '#0453cd' }}>{sessionId}</span>
            </p>
          </div>

          {/* Error banner */}
          {error && (
            <div className="mb-6 flex items-center gap-2.5 p-3 rounded text-xs"
              style={{ background: 'rgba(186,26,26,0.05)', border: '1px solid rgba(186,26,26,0.2)', color: '#93000a' }}
            >
              <AlertCircle className="h-4 w-4 shrink-0" />
              <span>{error}</span>
            </div>
          )}

          {/* Resent confirmation */}
          {resent && (
            <div className="mb-6 flex items-center gap-2.5 p-3 rounded text-xs"
              style={{ background: 'rgba(6,150,105,0.06)', border: '1px solid rgba(6,150,105,0.2)', color: '#005137' }}
            >
              <ShieldCheck className="h-4 w-4 shrink-0" />
              <span>New code dispatched to {emailParam}.</span>
            </div>
          )}

          {/* Status Message */}
          {statusMessage && (
            <div className="mb-6 flex items-center gap-2.5 p-3 rounded text-xs bg-emerald-50 border border-emerald-200 text-emerald-800 font-mono">
              <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
              <span>{statusMessage}</span>
            </div>
          )}

          {/* OTP inputs */}
          <div className="mb-10">
            <OtpInput onComplete={handleComplete} />
          </div>

          {/* CTA */}
          <button
            onClick={handleVerify}
            disabled={loading || code.length < 6}
            className="w-full py-4 rounded text-sm font-semibold flex items-center justify-center gap-2 group relative overflow-hidden transition-all disabled:opacity-50 disabled:cursor-not-allowed"
            style={{
              background: '#0d1c32',
              color: '#ffffff',
              borderTop: '1px solid rgba(255,255,255,0.15)',
            }}
          >
            {/* Hover shimmer */}
            <span
              className="absolute inset-0 translate-y-full group-hover:translate-y-0 transition-transform duration-300"
              style={{ background: 'rgba(255,255,255,0.08)' }}
            />
            <span className="relative z-10 flex items-center gap-2">
              {loading ? (
                <div className="h-4 w-4 animate-spin rounded-full border-2 border-white border-t-transparent" />
              ) : (
                <>
                  Verify &amp; Enter Studio
                  <LogIn className="h-4 w-4 group-hover:translate-x-0.5 transition-transform" />
                </>
              )}
            </span>
          </button>

          {/* Authoritative Email Verification Checker */}
          <button
            type="button"
            onClick={handleCheckEmailStatus}
            disabled={loading}
            className="w-full mt-3 py-3 rounded text-xs font-mono font-semibold flex items-center justify-center gap-2 border border-slate-300 hover:border-slate-400 bg-white hover:bg-slate-50 text-slate-800 transition-all cursor-pointer shadow-xs disabled:opacity-50"
          >
            <MailCheck className="h-3.5 w-3.5 text-[#0453cd]" />
            <span>Check Email Verification Status</span>
          </button>

          {/* Resend + back */}
          <div className="text-center mt-6 space-y-3">
            <button
              onClick={handleResend}
              disabled={resendCooldown > 0}
              className="inline-flex items-center gap-1.5 text-[12px] font-mono transition-colors disabled:opacity-50"
              style={{ color: '#44474d' }}
              onMouseEnter={(e) => { if (resendCooldown <= 0) e.currentTarget.style.color = '#0453cd'; }}
              onMouseLeave={(e) => (e.currentTarget.style.color = '#44474d')}
            >
              <RefreshCw className="h-3 w-3" />
              {resendCooldown > 0 ? `Resend in ${resendCooldown}s` : 'Resend Code'}
            </button>
            <div>
              <Link
                href="/login"
                className="inline-flex items-center gap-1 text-[11px] font-mono transition-colors"
                style={{ color: '#75777e' }}
                onMouseEnter={(e) => (e.currentTarget.style.color = '#0d1c32')}
                onMouseLeave={(e) => (e.currentTarget.style.color = '#75777e')}
              >
                <ArrowLeft className="h-3 w-3" />
                Return to Login
              </Link>
            </div>
          </div>
        </div>
      </main>

      {/* Footer signature */}
      <footer
        className="relative z-10 w-full p-6 flex justify-end"
        style={{ borderTop: '1px solid rgba(197,198,205,0.25)' }}
      >
        <p className="text-[11px] font-mono tracking-wide" style={{ color: '#94a3b8' }}>
          UI/UX Design &amp; Product Experience crafted by PixelMint Studio MVS
        </p>
      </footer>
    </div>
  );
}

export default function VerifyPage() {
  return (
    <Suspense fallback={<div className="min-h-screen" style={{ background: '#fbf9fb' }} />}>
      <VerifyContent />
    </Suspense>
  );
}

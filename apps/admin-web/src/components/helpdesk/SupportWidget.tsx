'use client';

import React, { useState, useEffect } from 'react';
import { usePathname } from 'next/navigation';
import { useAuth } from '@/lib/auth';
import { adminApi } from '@/lib/api';
import { Button } from '@/components/ui/Button';
import {
  MessageSquare,
  X,
  Send,
  CheckCircle2,
  AlertCircle,
  HelpCircle,
  LifeBuoy,
  FileQuestion,
  ChevronDown,
} from 'lucide-react';

const FRIENDLY_TOPICS = [
  { id: 'DRAWING_UPLOAD', label: '📐 Drawings & File Uploads' },
  { id: 'PROJECT_MANAGEMENT', label: '📁 Projects & Assignments' },
  { id: 'STUDENT_PORTAL', label: '🎓 Student Training & Lessons' },
  { id: 'LOGIN_AND_AUTH', label: '🔑 Login & Account Access' },
  { id: 'APPLICATION_BUG', label: '🐛 Something isn\'t working / Bug' },
  { id: 'PAYMENT_INVOICING', label: '💳 Financials & Billing' },
  { id: 'OTHER', label: '💬 General Question or Other' },
];

export function SupportWidget() {
  const pathname = usePathname();
  const { user, loading } = useAuth();

  const [isOpen, setIsOpen] = useState(false);
  const [email, setEmail] = useState('');
  const [topic, setTopic] = useState('APPLICATION_BUG');
  const [summary, setSummary] = useState('');
  const [details, setDetails] = useState('');
  const [screenshotUrl, setScreenshotUrl] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdTicketId, setCreatedTicketId] = useState<string | null>(null);

  // Pre-fill user email when logged in
  useEffect(() => {
    if (user?.email && !email) {
      setEmail(user.email);
    }
  }, [user?.email, email]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!summary.trim()) {
      setError('Please provide a short summary of what you need help with.');
      return;
    }
    if (!details.trim()) {
      setError('Please describe what happened or what question you have.');
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const res = await adminApi.submitUserTicket({
        subject: summary.trim(),
        description: details.trim(),
        category: topic,
        user_email: email.trim() || undefined,
        contact_email: email.trim() || undefined,
        affected_feature: pathname || 'User Portal',
        page_route: pathname || '/',
        screenshot_url: screenshotUrl.trim() || undefined,
        priority_suggestion: topic === 'LOGIN_AND_AUTH' || topic === 'APPLICATION_BUG' ? 'HIGH' : 'MEDIUM',
      });

      if (res.success && res.ticketId) {
        setCreatedTicketId(res.ticketId);
      } else {
        setError('Unable to send support ticket. Please try again.');
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to submit support request. Please retry.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleReset = () => {
    setSummary('');
    setDetails('');
    setScreenshotUrl('');
    setError(null);
    setCreatedTicketId(null);
    setIsOpen(false);
  };

  // STRICT REQUIREMENT: Only visible AFTER login, never before
  if (loading || !user) {
    return null;
  }

  // Do not render on auth pages or admin helpdesk pages itself
  const isExcluded =
    pathname === '/login' ||
    pathname === '/forgot-password' ||
    pathname === '/verify' ||
    pathname?.startsWith('/registration') ||
    pathname?.startsWith('/helpdesk');
  if (isExcluded) {
    return null;
  }

  return (
    <>
      {/* ── Floating Launcher Button (positioned above bottom-right controls) ── */}
      <div className="fixed bottom-20 right-6 z-40 select-none">
        <button
          type="button"
          onClick={() => setIsOpen(!isOpen)}
          aria-label="Open Help & Support"
          className="group flex items-center gap-2.5 px-4 py-2.5 bg-[#0453cd] hover:bg-blue-700 active:scale-95 text-white font-medium text-xs rounded-full shadow-lg hover:shadow-xl transition-all duration-200 border border-blue-400/30"
        >
          <div className="relative">
            <LifeBuoy className="h-4 w-4 animate-spin-slow group-hover:rotate-45 transition-transform" />
            <span className="absolute -top-1 -right-1 h-1.5 w-1.5 rounded-full bg-emerald-400 ring-2 ring-[#0453cd]" />
          </div>
          <span className="font-semibold tracking-wide">Need Help?</span>
        </button>
      </div>

      {/* ── Support Modal Dialog ── */}
      {isOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/50 backdrop-blur-xs animate-in fade-in duration-150">
          <div className="bg-white border border-slate-200 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col max-h-[92vh] animate-in zoom-in-95 duration-150">
            {/* Header */}
            <div className="px-6 py-4.5 border-b border-slate-100 flex items-center justify-between bg-gradient-to-r from-blue-50/70 via-slate-50 to-white">
              <div className="flex items-center gap-3">
                <div className="h-10 w-10 rounded-xl bg-[#0453cd] text-white flex items-center justify-center shadow-xs">
                  <LifeBuoy className="h-5 w-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-slate-900">PixelMint Support</h3>
                  <p className="text-xs text-slate-500">How can we help you today?</p>
                </div>
              </div>
              <button
                type="button"
                onClick={handleReset}
                className="p-1.5 text-slate-400 hover:text-slate-700 rounded-lg hover:bg-slate-100 transition-colors"
                aria-label="Close"
              >
                <X className="h-5 w-5" />
              </button>
            </div>

            {/* Content */}
            {createdTicketId ? (
              <div className="p-8 text-center space-y-4 my-auto">
                <div className="h-16 w-16 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-600 flex items-center justify-center mx-auto shadow-xs">
                  <CheckCircle2 className="h-10 w-10" />
                </div>
                <h4 className="text-lg font-bold text-slate-900">We Got Your Request!</h4>
                <p className="text-sm text-slate-600 max-w-sm mx-auto leading-relaxed">
                  Your ticket has been sent directly to the Studio support team at{' '}
                  <strong className="text-slate-900 font-semibold">pixelmintstudiomvs@gmail.com</strong>.
                </p>

                <div className="bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 inline-flex flex-col items-center gap-1">
                  <span className="text-[11px] text-slate-500 font-medium">Your Ticket ID</span>
                  <span className="text-base font-mono font-bold text-[#0453cd]">{createdTicketId}</span>
                </div>

                <p className="text-xs text-slate-400">
                  We'll reply to {email || 'your email'} as soon as possible.
                </p>

                <div className="pt-2">
                  <Button variant="primary" onClick={handleReset} className="px-6 py-2 bg-[#0453cd]">
                    Close
                  </Button>
                </div>
              </div>
            ) : (
              <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto flex-1">
                {error && (
                  <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-xl flex items-start gap-2.5 text-xs text-rose-700">
                    <AlertCircle className="h-4 w-4 shrink-0 text-rose-500 mt-0.5" />
                    <span className="font-medium">{error}</span>
                  </div>
                )}

                {/* Email Address */}
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Your Email Address <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    required
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                  />
                  <p className="text-[11px] text-slate-400 mt-1">
                    We'll email you when there is an update or resolution.
                  </p>
                </div>

                {/* Topic Selector */}
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    What can we help you with?
                  </label>
                  <div className="relative">
                    <select
                      value={topic}
                      onChange={(e) => setTopic(e.target.value)}
                      className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white appearance-none transition-all pr-10 cursor-pointer"
                    >
                      {FRIENDLY_TOPICS.map((t) => (
                        <option key={t.id} value={t.id}>
                          {t.label}
                        </option>
                      ))}
                    </select>
                    <ChevronDown className="h-4 w-4 text-slate-400 absolute right-3.5 top-3.5 pointer-events-none" />
                  </div>
                </div>

                {/* Short Summary */}
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Short Summary <span className="text-rose-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={summary}
                    onChange={(e) => setSummary(e.target.value)}
                    placeholder="e.g. Cannot open drawing viewer, or question about certificate"
                    required
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                  />
                </div>

                {/* Details */}
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Tell us what happened <span className="text-rose-500">*</span>
                  </label>
                  <textarea
                    value={details}
                    onChange={(e) => setDetails(e.target.value)}
                    placeholder="Please describe what you were trying to do and what went wrong..."
                    rows={4}
                    required
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white resize-none transition-all leading-relaxed"
                  />
                </div>

                {/* Screenshot URL */}
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Image / Screenshot Link <span className="text-slate-400 font-normal">(Optional)</span>
                  </label>
                  <input
                    type="url"
                    value={screenshotUrl}
                    onChange={(e) => setScreenshotUrl(e.target.value)}
                    placeholder="https://..."
                    className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                  />
                </div>

                {/* Action Buttons */}
                <div className="pt-2 border-t border-slate-100 flex items-center justify-between gap-3">
                  <span className="text-[11px] text-slate-400">
                    Notifies: <span className="text-slate-600 font-medium">pixelmintstudiomvs@gmail.com</span>
                  </span>
                  <div className="flex items-center gap-2">
                    <Button type="button" variant="outline" onClick={handleReset} disabled={submitting}>
                      Cancel
                    </Button>
                    <Button
                      type="submit"
                      variant="primary"
                      disabled={submitting}
                      className="bg-[#0453cd] hover:bg-blue-700 flex items-center gap-2 text-white px-5"
                    >
                      <Send className="h-4 w-4" />
                      <span>{submitting ? 'Sending...' : 'Send Request'}</span>
                    </Button>
                  </div>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </>
  );
}


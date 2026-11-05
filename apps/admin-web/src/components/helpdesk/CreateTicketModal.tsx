'use client';

import React, { useState } from 'react';
import { adminApi } from '@/lib/api';
import { Button } from '@/components/ui/Button';
import { X, Send, AlertCircle, CheckCircle2, LifeBuoy, ChevronDown } from 'lucide-react';

interface CreateTicketModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSuccess?: (ticketId: string) => void;
}

const CATEGORY_OPTIONS = [
  { value: 'APPLICATION_BUG', label: '🐛 Technical Bug or Glitch' },
  { value: 'DRAWING_UPLOAD', label: '📐 Drawings & File Uploads' },
  { value: 'PROJECT_MANAGEMENT', label: '📁 Projects & Assignments' },
  { value: 'STUDENT_PORTAL', label: '🎓 Student Training & Lessons' },
  { value: 'CERTIFICATE_GENERATION', label: '📜 Certificates & Verification' },
  { value: 'LOGIN_AND_AUTH', label: '🔑 Login & Access' },
  { value: 'ENGINEER_PORTAL', label: '👷 Engineer Portal' },
  { value: 'DRAUGHTSMAN_PORTAL', label: '✏️ Draughtsman Portal' },
  { value: 'PAYMENT_INVOICING', label: '💳 Financials & Billing' },
  { value: 'PERFORMANCE_ISSUE', label: '⚡ Slow Loading / Performance' },
  { value: 'OTHER', label: '💬 General Inquiry / Other' },
];

export function CreateTicketModal({ isOpen, onClose, onSuccess }: CreateTicketModalProps) {
  const [subject, setSubject] = useState('');
  const [category, setCategory] = useState('APPLICATION_BUG');
  const [priority, setPriority] = useState<'CRITICAL' | 'HIGH' | 'MEDIUM' | 'LOW'>('MEDIUM');
  const [contactEmail, setContactEmail] = useState('');
  const [affectedFeature, setAffectedFeature] = useState('');
  const [description, setDescription] = useState('');
  const [screenshotUrl, setScreenshotUrl] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [createdTicketId, setCreatedTicketId] = useState<string | null>(null);

  if (!isOpen) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!subject.trim()) {
      setError('Please provide a subject / title for the issue.');
      return;
    }
    if (!description.trim()) {
      setError('Please provide a description of what happened.');
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const res = await adminApi.submitUserTicket({
        subject: subject.trim(),
        description: description.trim(),
        category,
        affected_feature: affectedFeature.trim() || undefined,
        priority_suggestion: priority,
        contact_email: contactEmail.trim() || undefined,
        screenshot_url: screenshotUrl.trim() || undefined,
      });

      if (res.success && res.ticketId) {
        setCreatedTicketId(res.ticketId);
        if (onSuccess) onSuccess(res.ticketId);
      } else {
        setError('Failed to submit ticket. Please retry.');
      }
    } catch (err: any) {
      setError(err?.message || 'Failed to submit support ticket.');
    } finally {
      setSubmitting(false);
    }
  };

  const handleReset = () => {
    setSubject('');
    setDescription('');
    setContactEmail('');
    setAffectedFeature('');
    setScreenshotUrl('');
    setCreatedTicketId(null);
    setError(null);
    onClose();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center p-4 bg-slate-900/60 backdrop-blur-xs animate-in fade-in duration-200">
      <div className="bg-white border border-slate-200 rounded-2xl w-full max-w-lg shadow-2xl overflow-hidden flex flex-col max-h-[90vh]">
        {/* Header */}
        <div className="px-6 py-4.5 border-b border-slate-100 flex items-center justify-between bg-slate-50/70">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center shadow-xs">
              <LifeBuoy className="h-5 w-5" />
            </div>
            <div>
              <h3 className="text-base font-bold text-slate-900">Create Support Ticket</h3>
              <p className="text-xs text-slate-500">Alerts dispatched to pixelmintstudiomvs@gmail.com</p>
            </div>
          </div>
          <button
            onClick={handleReset}
            className="p-1.5 text-slate-400 hover:text-slate-600 rounded-lg hover:bg-slate-100 transition-colors"
          >
            <X className="h-5 w-5" />
          </button>
        </div>

        {/* Form Body */}
        {createdTicketId ? (
          <div className="p-8 text-center space-y-4">
            <div className="h-14 w-14 rounded-2xl bg-emerald-50 border border-emerald-200 text-emerald-600 flex items-center justify-center mx-auto">
              <CheckCircle2 className="h-8 w-8" />
            </div>
            <h4 className="text-base font-bold text-slate-900">Support Ticket Created</h4>
            <p className="text-xs text-slate-600 max-w-sm mx-auto leading-relaxed">
              Your support ticket has been created and sent to{' '}
              <strong className="text-slate-800">pixelmintstudiomvs@gmail.com</strong>.
            </p>
            <div className="bg-slate-50 border border-slate-200 rounded-xl px-4 py-3 inline-flex items-center gap-2">
              <span className="text-xs text-slate-400 font-semibold uppercase">Ticket ID:</span>
              <span className="text-sm font-mono font-bold text-[#0453cd]">{createdTicketId}</span>
            </div>
            <div className="pt-4 flex justify-center">
              <Button variant="primary" onClick={handleReset} className="px-6 py-2 bg-[#0453cd]">
                Done
              </Button>
            </div>
          </div>
        ) : (
          <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto flex-1">
            {error && (
              <div className="p-3 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-2 text-xs text-rose-700 font-medium">
                <AlertCircle className="h-4 w-4 shrink-0 text-rose-500" />
                <span>{error}</span>
              </div>
            )}

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Subject / Summary <span className="text-rose-500">*</span>
              </label>
              <input
                type="text"
                value={subject}
                onChange={(e) => setSubject(e.target.value)}
                placeholder="e.g. Can't download certificate or issue with assignment"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white"
                required
              />
            </div>

            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Category
                </label>
                <div className="relative">
                  <select
                    value={category}
                    onChange={(e) => setCategory(e.target.value)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white appearance-none pr-9 cursor-pointer"
                  >
                    {CATEGORY_OPTIONS.map((cat) => (
                      <option key={cat.value} value={cat.value}>
                        {cat.label}
                      </option>
                    ))}
                  </select>
                  <ChevronDown className="h-4 w-4 text-slate-400 absolute right-3 top-3.5 pointer-events-none" />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Urgency / Priority
                </label>
                <div className="relative">
                  <select
                    value={priority}
                    onChange={(e) => setPriority(e.target.value as any)}
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white appearance-none pr-9 cursor-pointer"
                  >
                    <option value="LOW">Low (Minor / General question)</option>
                    <option value="MEDIUM">Medium (Normal issue)</option>
                    <option value="HIGH">High (Important feature blocked)</option>
                    <option value="CRITICAL">Critical (Urgent blocker / Outage)</option>
                  </select>
                  <ChevronDown className="h-4 w-4 text-slate-400 absolute right-3 top-3.5 pointer-events-none" />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Your Contact Email (Optional)
              </label>
              <input
                type="email"
                value={contactEmail}
                onChange={(e) => setContactEmail(e.target.value)}
                placeholder="Where should we reach you?"
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white"
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Details & Description <span className="text-rose-500">*</span>
              </label>
              <textarea
                value={description}
                onChange={(e) => setDescription(e.target.value)}
                placeholder="Describe what you were doing, what went wrong, or what you need help with..."
                rows={4}
                className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white resize-none leading-relaxed"
                required
              />
            </div>

            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Screenshot / Attachment Link (Optional)
              </label>
              <input
                type="url"
                value={screenshotUrl}
                onChange={(e) => setScreenshotUrl(e.target.value)}
                placeholder="https://..."
                className="w-full px-3.5 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white"
              />
            </div>

            <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-3">
              <Button type="button" variant="outline" onClick={handleReset} disabled={submitting}>
                Cancel
              </Button>
              <Button type="submit" variant="primary" disabled={submitting} className="flex items-center gap-2 bg-[#0453cd] hover:bg-blue-700">
                <Send className="h-4 w-4" />
                <span>{submitting ? 'Submitting...' : 'Submit Support Ticket'}</span>
              </Button>
            </div>
          </form>
        )}
      </div>
    </div>
  );
}

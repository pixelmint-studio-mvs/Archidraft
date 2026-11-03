'use client';

import React, { useEffect, useState } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { adminApi } from '@/lib/api';
import { HelpdeskSettings } from '@/lib/types';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import {
  Sliders,
  Mail,
  Send,
  CheckCircle2,
  AlertTriangle,
  Clock,
  ShieldCheck,
  Flame,
  ArrowLeft,
  Key,
  ExternalLink,
  Info,
  Activity,
} from 'lucide-react';

export default function HelpDeskSettingsPage() {
  const [settings, setSettings] = useState<HelpdeskSettings | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [saving, setSaving] = useState<boolean>(false);
  const [saveSuccess, setSaveSuccess] = useState<boolean>(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  // Test email state
  const [testingEmail, setTestingEmail] = useState<boolean>(false);
  const [testRecipient, setTestRecipient] = useState<string>('');
  const [testResult, setTestResult] = useState<{ success: boolean; status: string; messageId?: string; error?: string; recipient?: string } | null>(null);

  const loadSettings = async () => {
    setLoading(true);
    try {
      const data = await adminApi.getHelpdeskSettings();
      setSettings(data);
      if (data?.notification_email && !testRecipient) {
        setTestRecipient(data.notification_email);
      }
    } catch (err: any) {
      console.error('Failed to load helpdesk settings:', err);
      setErrorMessage(err?.message || 'Failed to load configuration.');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadSettings();
  }, []);

  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!settings) return;

    setSaving(true);
    setSaveSuccess(false);
    setErrorMessage(null);

    try {
      const res = await adminApi.updateHelpdeskSettings(settings);
      if (res.success && res.settings) {
        setSettings(res.settings);
        setSaveSuccess(true);
        setTimeout(() => setSaveSuccess(false), 3000);
      }
    } catch (err: any) {
      setErrorMessage(err?.message || 'Failed to save settings.');
    } finally {
      setSaving(false);
    }
  };

  const handleTestEmail = async (overrideRecipient?: string) => {
    const target = (overrideRecipient || testRecipient || settings?.notification_email || 'pixelmintstudiomvs@gmail.com').trim();
    setTestingEmail(true);
    setTestResult(null);

    try {
      const res = await adminApi.sendHelpdeskTestEmail(target);
      setTestResult({ ...res, recipient: target });
    } catch (err: any) {
      setTestResult({
        success: false,
        status: 'FAILED',
        error: err?.message || 'Network request failed',
        recipient: target,
      });
    } finally {
      setTestingEmail(false);
    }
  };

  return (
    <AdminShell
      title="Help Desk Settings & Email Alerts"
      subtitle="Configure notification recipients, email keys, alert rules, and test email delivery"
      backHref="/helpdesk"
      backLabel="Back to Help Desk"
      onRefresh={loadSettings}
      isRefreshing={loading}
    >
      <div className="max-w-4xl space-y-6">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white p-3.5 rounded-2xl border border-slate-200 shadow-xs">
          <div className="text-xs text-slate-600 font-medium">Advanced Developer & Telemetry Tools:</div>
          <div className="flex items-center gap-2">
            <Link href="/helpdesk/email-logs">
              <Button variant="outline" size="sm" className="text-xs font-semibold px-3 py-1.5 flex items-center gap-1.5">
                <Mail className="h-3.5 w-3.5 text-slate-500" />
                <span>Email Delivery Logs</span>
              </Button>
            </Link>
            <Link href="/helpdesk/health">
              <Button variant="outline" size="sm" className="text-xs font-semibold px-3 py-1.5 flex items-center gap-1.5">
                <Activity className="h-3.5 w-3.5 text-slate-500" />
                <span>Server Health</span>
              </Button>
            </Link>
          </div>
        </div>

        {loading || !settings ? (
          <div className="py-20 flex flex-col items-center justify-center gap-3">
            <div className="h-8 w-8 animate-spin rounded-full border-3 border-[#0453cd] border-t-transparent" />
            <p className="text-xs text-slate-500 font-medium">Retrieving configuration settings...</p>
          </div>
        ) : (
          <form onSubmit={handleSave} className="space-y-6">
            {saveSuccess && (
              <div className="p-3.5 bg-emerald-50 border border-emerald-200 rounded-xl flex items-center gap-2.5 text-xs text-emerald-800 font-semibold shadow-xs">
                <CheckCircle2 className="h-4 w-4 shrink-0 text-emerald-600" />
                <span>Configuration changes successfully saved!</span>
              </div>
            )}

            {errorMessage && (
              <div className="p-3.5 bg-rose-50 border border-rose-200 rounded-xl flex items-center gap-2.5 text-xs text-rose-800 font-semibold shadow-xs">
                <AlertTriangle className="h-4 w-4 shrink-0 text-rose-600" />
                <span>{errorMessage}</span>
              </div>
            )}

            {/* ── 1. Email Service Connection Card ── */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-100">
                <div className="flex items-center gap-2.5">
                  <div className="h-8 w-8 rounded-lg bg-blue-50 text-[#0453cd] flex items-center justify-center">
                    <Key className="h-4 w-4" />
                  </div>
                  <div>
                    <h3 className="text-sm font-bold text-slate-900">Email Delivery Service</h3>
                    <p className="text-xs text-slate-500">Powers outgoing notification emails to Studio MVS</p>
                  </div>
                </div>

                {settings.email_configured ? (
                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                    <span className="h-2 w-2 rounded-full bg-emerald-500" />
                    <span>Connected ({settings.email_provider_active || 'RESEND'})</span>
                  </span>
                ) : (
                  <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-semibold bg-amber-50 text-amber-700 border border-amber-200">
                    <span className="h-2 w-2 rounded-full bg-amber-500 animate-pulse" />
                    <span>Setup Required</span>
                  </span>
                )}
              </div>

              <div className="space-y-4">
                <div className="p-3.5 bg-blue-50/70 border border-blue-200/80 rounded-xl text-xs text-blue-900 leading-relaxed flex items-start gap-2.5">
                  <Info className="h-4 w-4 shrink-0 text-[#0453cd] mt-0.5" />
                  <div>
                    <p className="font-semibold mb-0.5">Why am I not receiving emails?</p>
                    <p className="text-blue-800/90">
                      Cloudflare Workers needs an email provider API key to dispatch real emails to{' '}
                      <strong>{settings.notification_email}</strong>. Resend provides 3,000 free emails per month without any credit card required.
                    </p>
                  </div>
                </div>

                <div>
                  <div className="flex items-center justify-between mb-1">
                    <label className="text-xs font-semibold text-slate-700">
                      Resend API Key (starts with <code className="text-[#0453cd] font-mono">re_</code>)
                    </label>
                    <a
                      href="https://resend.com/api-keys"
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-[#0453cd] hover:underline flex items-center gap-1 font-medium"
                    >
                      <span>Get free Resend key</span>
                      <ExternalLink className="h-3 w-3" />
                    </a>
                  </div>
                  <input
                    type="text"
                    value={settings.resend_api_key || ''}
                    onChange={(e) => setSettings({ ...settings, resend_api_key: e.target.value })}
                    placeholder="re_123456789_abcdef..."
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                  />
                  <p className="text-[11px] text-slate-500 mt-1">
                    Paste your key here and click <strong>Save Configuration</strong>. Once saved, emails will send immediately.
                  </p>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Sender Address (From)
                  </label>
                  <input
                    type="text"
                    value={settings.email_from_address || ''}
                    onChange={(e) => setSettings({ ...settings, email_from_address: e.target.value })}
                    placeholder="PixelMint HelpDesk <onboarding@resend.dev>"
                    className="w-full max-w-md px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                  />
                  <p className="text-[11px] text-slate-500 mt-1">
                    Default is <code className="font-mono text-slate-700">onboarding@resend.dev</code> (works automatically with zero DNS setup for accounts registered to your email).
                  </p>
                </div>
              </div>
            </Card>

            {/* ── 2. Notification Target Card ── */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex items-center gap-2.5 mb-4 pb-3 border-b border-slate-100">
                <div className="h-8 w-8 rounded-lg bg-blue-50 text-[#0453cd] flex items-center justify-center">
                  <Mail className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Notification Recipient</h3>
                  <p className="text-xs text-slate-500">Destination inbox for all incident alerts and user reports</p>
                </div>
              </div>

              <div className="space-y-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Admin Notification Email Address
                  </label>
                  <input
                    type="email"
                    value={settings.notification_email}
                    onChange={(e) => setSettings({ ...settings, notification_email: e.target.value })}
                    className="w-full max-w-md px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                    required
                  />
                  <p className="text-[11px] text-slate-500 mt-1">
                    Default: <strong className="text-slate-800">pixelmintstudiomvs@gmail.com</strong>
                  </p>
                </div>
              </div>
            </Card>

            {/* ── 3. Alert Severity Triggers ── */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex items-center gap-2.5 mb-4 pb-3 border-b border-slate-100">
                <div className="h-8 w-8 rounded-lg bg-orange-50 text-orange-600 flex items-center justify-center">
                  <Flame className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Alert Dispatch Thresholds</h3>
                  <p className="text-xs text-slate-500">Choose when the system sends an email alert</p>
                </div>
              </div>

              <div className="space-y-3">
                <label className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50/80 border border-slate-200/70 hover:bg-slate-50 cursor-pointer transition-colors">
                  <div>
                    <span className="text-xs font-bold text-slate-900 block">Critical Issues (Immediate Alert)</span>
                    <span className="text-[11px] text-slate-500">System outages, major crashes, rendering failures, or database issues.</span>
                  </div>
                  <input
                    type="checkbox"
                    checked={settings.alert_critical_enabled}
                    onChange={(e) => setSettings({ ...settings, alert_critical_enabled: e.target.checked })}
                    className="h-4 w-4 text-[#0453cd] rounded focus:ring-0 cursor-pointer"
                  />
                </label>

                <label className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50/80 border border-slate-200/70 hover:bg-slate-50 cursor-pointer transition-colors">
                  <div>
                    <span className="text-xs font-bold text-slate-900 block">High Priority Issues (Prompt Alert)</span>
                    <span className="text-[11px] text-slate-500">Drawing upload failures, user-submitted bug tickets, or assignment errors.</span>
                  </div>
                  <input
                    type="checkbox"
                    checked={settings.alert_high_enabled}
                    onChange={(e) => setSettings({ ...settings, alert_high_enabled: e.target.checked })}
                    className="h-4 w-4 text-[#0453cd] rounded focus:ring-0 cursor-pointer"
                  />
                </label>

                <label className="flex items-center justify-between p-3.5 rounded-xl bg-slate-50/80 border border-slate-200/70 hover:bg-slate-50 cursor-pointer transition-colors">
                  <div>
                    <span className="text-xs font-bold text-slate-900 block">Medium Priority Alerts</span>
                    <span className="text-[11px] text-slate-500">Non-blocking recoverable API issues or minor glitches.</span>
                  </div>
                  <input
                    type="checkbox"
                    checked={settings.alert_medium_enabled}
                    onChange={(e) => setSettings({ ...settings, alert_medium_enabled: e.target.checked })}
                    className="h-4 w-4 text-[#0453cd] rounded focus:ring-0 cursor-pointer"
                  />
                </label>
              </div>
            </Card>

            {/* ── 4. Suppression Window ── */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex items-center gap-2.5 mb-4 pb-3 border-b border-slate-100">
                <div className="h-8 w-8 rounded-lg bg-purple-50 text-purple-600 flex items-center justify-center">
                  <Clock className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Anti-Spam & Deduplication</h3>
                  <p className="text-xs text-slate-500">Prevent your inbox from being flooded with duplicate error reports</p>
                </div>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Suppression Window (Minutes)
                  </label>
                  <input
                    type="number"
                    min="1"
                    max="1440"
                    value={settings.suppression_window_minutes}
                    onChange={(e) =>
                      setSettings({ ...settings, suppression_window_minutes: parseInt(e.target.value, 10) || 15 })
                    }
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                  />
                  <p className="text-[11px] text-slate-500 mt-1">
                    If the same error happens 100 times, you get only 1 email during this window.
                  </p>
                </div>

                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Retention Period (Days)
                  </label>
                  <input
                    type="number"
                    min="30"
                    max="365"
                    value={settings.incident_retention_days}
                    onChange={(e) =>
                      setSettings({ ...settings, incident_retention_days: parseInt(e.target.value, 10) || 90 })
                    }
                    className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                  />
                  <p className="text-[11px] text-slate-500 mt-1">
                    Number of days incident records and email logs are kept in the database.
                  </p>
                </div>
              </div>
            </Card>

            {/* ── 5. Live Test Email Dispatch ── */}
            <Card className="p-6 bg-white border-slate-200 shadow-xs">
              <div className="flex items-center gap-2.5 mb-4 pb-3 border-b border-slate-100">
                <div className="h-8 w-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center">
                  <Send className="h-4 w-4" />
                </div>
                <div>
                  <h3 className="text-sm font-bold text-slate-900">Live Email Diagnostic Test</h3>
                  <p className="text-xs text-slate-500">Send an immediate test alert to verify your email API connection</p>
                </div>
              </div>

              <div className="space-y-3">
                <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2">
                  <div className="relative flex-1">
                    <input
                      type="email"
                      value={testRecipient}
                      onChange={(e) => setTestRecipient(e.target.value)}
                      placeholder={settings.notification_email || 'pixelmintstudiomvs@gmail.com'}
                      className="w-full px-3.5 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono text-slate-900 focus:outline-none focus:ring-2 focus:ring-[#0453cd]/20 focus:border-[#0453cd] focus:bg-white transition-all"
                    />
                  </div>

                  <Button
                    type="button"
                    variant="outline"
                    onClick={() => handleTestEmail()}
                    disabled={testingEmail}
                    className="flex items-center justify-center gap-2 text-xs font-semibold px-5 py-2.5 border-[#0453cd]/30 text-[#0453cd] hover:bg-blue-50 transition-colors whitespace-nowrap"
                  >
                    <Send className={`h-3.5 w-3.5 ${testingEmail ? 'animate-spin' : ''}`} />
                    <span>{testingEmail ? 'Sending Test...' : 'Send Test Alert to pixelmintstudiomvs@gmail.com'}</span>
                  </Button>
                </div>

                {/* Test Email Result */}
                {testResult && (
                  <div
                    className={`mt-4 p-4 rounded-xl border text-xs shadow-2xs animate-in fade-in ${
                      testResult.success
                        ? 'bg-emerald-50 border-emerald-200 text-emerald-900'
                        : 'bg-rose-50 border-rose-200 text-rose-900'
                    }`}
                  >
                    <div className="flex items-center gap-2 font-bold mb-1">
                      {testResult.success ? (
                        <CheckCircle2 className="h-4 w-4 text-emerald-600 shrink-0" />
                      ) : (
                        <AlertTriangle className="h-4 w-4 text-rose-600 shrink-0" />
                      )}
                      <span>{testResult.success ? 'Test Email Successfully Delivered!' : 'Delivery Test Failed'}</span>
                    </div>

                    {testResult.success ? (
                      <p className="mt-1 text-emerald-800 text-[11px] leading-relaxed">
                        A test notification was successfully accepted by Resend and dispatched to{' '}
                        <strong>{testResult.recipient || settings.notification_email}</strong>. Please check your inbox or spam folder! (Message ID:{' '}
                        <code className="font-mono text-emerald-900">{testResult.messageId || 'resend_ok'}</code>)
                      </p>
                    ) : (
                      <div className="space-y-3 mt-1">
                        <p className="text-rose-800 text-[11px] leading-relaxed">
                          {testResult.error || 'The email could not be delivered. Please verify your Resend API Key.'}
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </Card>

            {/* ── Save Button ── */}
            <div className="flex items-center justify-between pt-2">
              <Button
                type="submit"
                variant="primary"
                disabled={saving}
                className="bg-[#0453cd] hover:bg-blue-700 text-white text-xs px-8 py-3 rounded-xl font-bold shadow-xs flex items-center gap-2"
              >
                {saving && <div className="h-3.5 w-3.5 border-2 border-white border-t-transparent rounded-full animate-spin" />}
                <span>{saving ? 'Saving Configuration...' : 'Save Configuration'}</span>
              </Button>
            </div>
          </form>
        )}
      </div>
    </AdminShell>
  );
}

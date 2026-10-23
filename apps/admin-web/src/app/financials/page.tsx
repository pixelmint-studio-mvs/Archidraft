'use client';

import React, { useState, useEffect } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card, CardHeader } from '@/components/ui/Card';
import { adminApi } from '@/lib/api';
import { Project } from '@/lib/types';
import {
  TrendingUp,
  AlertCircle,
  CheckCircle2,
  Download,
  Filter,
  BarChart2,
  Receipt,
  ArrowUpRight,
  ArrowDownRight,
  FileText,
  Loader2,
} from 'lucide-react';

// ─── Helpers ──────────────────────────────────────────────────────────────────

function formatCurrency(amount: number): string {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: 'USD',
    minimumFractionDigits: 0,
    maximumFractionDigits: 0,
  }).format(amount);
}

function formatDate(dateStr: string | undefined | null): string {
  if (!dateStr) return 'N/A';
  return new Date(dateStr).toLocaleDateString('en-US', {
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

// ─── Derived Invoice Model ────────────────────────────────────────────────────

interface DerivedInvoice {
  id: string;
  projectId: string;
  projectName: string;
  drawingType: string;
  amount: number;
  status: 'PAID' | 'UNPAID' | 'OVERDUE' | 'IN_PROGRESS';
  issuedAt: string;
  paidAt?: string;
}

const TYPE_RATES: Record<string, number> = {
  FLOOR_PLAN: 1200,
  STRUCTURAL: 2800,
  ELEVATION: 1800,
  ELECTRICAL: 2200,
  PLUMBING: 2000,
  SITE_PLAN: 3500,
  SECTION: 1600,
  DETAIL: 900,
};

function deriveInvoicesFromProjects(projects: Project[]): DerivedInvoice[] {
  return projects
    .filter((p) => p.status !== 'DRAFT')
    .map((p, idx) => {
      const area = parseFloat(p.project_area) || 1500;
      const rateKey = (p.drawing_type || '').toUpperCase().replace(/\s+/g, '_');
      const rate = TYPE_RATES[rateKey] ?? 1500;
      const amount = Math.round((area / 100) * rate * 0.6 + rate);

      const isCompleted = p.status === 'COMPLETED';
      const isCancelled = p.status === 'CANCELLED';
      const isActive = ['IN_PROGRESS', 'UNDER_CLIENT_REVIEW', 'WAITING_ACCEPTANCE'].includes(p.status);

      let status: DerivedInvoice['status'];
      if (isCompleted) status = 'PAID';
      else if (isCancelled) status = 'OVERDUE';
      else if (isActive) status = 'IN_PROGRESS';
      else status = 'UNPAID';

      return {
        id: `INV-${new Date(p.created_at).getFullYear()}-${String(idx + 1).padStart(3, '0')}`,
        projectId: p.id,
        projectName: p.project_name || 'Untitled Project',
        drawingType: p.drawing_type || 'Technical Drawing',
        amount,
        status,
        issuedAt: p.submitted_at || p.created_at,
        paidAt: isCompleted ? p.approved_at : undefined,
      };
    });
}

// ─── Invoice Status Badge ─────────────────────────────────────────────────────

function InvoiceStatusBadge({ status }: { status: DerivedInvoice['status'] }) {
  const map: Record<DerivedInvoice['status'], { label: string; cls: string }> = {
    PAID: { label: 'Paid', cls: 'bg-emerald-50 text-emerald-700 border-emerald-200' },
    UNPAID: { label: 'Unpaid', cls: 'bg-amber-50 text-amber-700 border-amber-200' },
    OVERDUE: { label: 'Overdue', cls: 'bg-rose-50 text-rose-700 border-rose-200' },
    IN_PROGRESS: { label: 'In Progress', cls: 'bg-blue-50 text-[#0453cd] border-blue-200' },
  };
  const { label, cls } = map[status];
  return (
    <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-[10px] font-mono font-semibold uppercase tracking-wider border ${cls}`}>
      {label}
    </span>
  );
}

// ─── Blueprint grid style ─────────────────────────────────────────────────────

const BLUEPRINT_BG = {
  backgroundImage:
    'linear-gradient(to right, #60a5fa 1px, transparent 1px), linear-gradient(to bottom, #60a5fa 1px, transparent 1px)',
  backgroundSize: '40px 40px',
};

// ─── PDF Generation ───────────────────────────────────────────────────────────

async function generateInvoicePDF(inv: DerivedInvoice, totalRevenue: number, collectionRate: number) {
  // Dynamic import to avoid SSR issues
  const { jsPDF } = await import('jspdf');

  const doc = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' });
  const W = 210; // A4 width mm
  const MARGIN = 18;
  let y = MARGIN;

  // ── Colour palette ──────────────────────────────────────────────────────────
  const midnight = [11, 17, 32] as [number, number, number];  // #0b1120
  const blue     = [59, 130, 246] as [number, number, number]; // #3b82f6
  const slate600 = [71, 85, 105] as [number, number, number];
  const slate400 = [148, 163, 184] as [number, number, number];
  const white    = [255, 255, 255] as [number, number, number];

  // ── Header background ───────────────────────────────────────────────────────
  doc.setFillColor(...midnight);
  doc.rect(0, 0, W, 52, 'F');

  // Blueprint grid overlay (subtle dots)
  doc.setDrawColor(59, 130, 246);
  doc.setLineWidth(0.05);
  for (let gx = 0; gx < W; gx += 10) doc.line(gx, 0, gx, 52);
  for (let gy = 0; gy < 52; gy += 10) doc.line(0, gy, W, gy);

  // Logo block
  doc.setFillColor(...blue);
  doc.roundedRect(MARGIN, 12, 12, 12, 2, 2, 'F');
  doc.setFontSize(9);
  doc.setTextColor(...white);
  doc.setFont('helvetica', 'bold');
  doc.text('AD', MARGIN + 3.5, 20.5);

  // Studio name
  doc.setFontSize(15);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(...white);
  doc.text('ARCHI DRAFT', MARGIN + 17, 20);

  doc.setFontSize(7);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(...slate400);
  doc.text('DRAUGHTSMAN STUDIO · PIXELMINT MVS', MARGIN + 17, 26);

  // INVOICE label (right)
  doc.setFontSize(22);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(...blue);
  doc.text('INVOICE', W - MARGIN, 22, { align: 'right' });

  doc.setFontSize(9);
  doc.setFont('courier', 'normal');
  doc.setTextColor(...slate400);
  doc.text(inv.id, W - MARGIN, 30, { align: 'right' });

  y = 58;

  // ── Meta Row ────────────────────────────────────────────────────────────────

  const metaFields: [string, string][] = [
    ['Issued', formatDate(inv.issuedAt)],
    ['Due / Paid', inv.paidAt ? formatDate(inv.paidAt) : 'Pending'],
    ['Status', inv.status],
    ['Project ID', inv.projectId.substring(0, 12) + '…'],
  ];

  const colW = (W - MARGIN * 2) / metaFields.length;
  metaFields.forEach(([label, value], i) => {
    const x = MARGIN + i * colW;
    doc.setFontSize(7);
    doc.setFont('courier', 'normal');
    doc.setTextColor(...slate400);
    doc.text(label.toUpperCase(), x, y);
    doc.setFontSize(9);
    doc.setFont('helvetica', 'bold');
    doc.setTextColor(30, 41, 59);
    doc.text(value, x, y + 6);
  });

  y += 18;

  // ── Divider ─────────────────────────────────────────────────────────────────
  doc.setDrawColor(...blue);
  doc.setLineWidth(0.4);
  doc.line(MARGIN, y, W - MARGIN, y);
  y += 8;

  // ── Bill To ─────────────────────────────────────────────────────────────────
  doc.setFontSize(7);
  doc.setFont('courier', 'bold');
  doc.setTextColor(...slate600);
  doc.text('BILL TO', MARGIN, y);

  y += 5;
  doc.setFontSize(11);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(15, 23, 42);
  doc.text(inv.projectName, MARGIN, y);

  y += 5;
  doc.setFontSize(8);
  doc.setFont('helvetica', 'normal');
  doc.setTextColor(...slate400);
  doc.text(`Drawing Type: ${inv.drawingType}`, MARGIN, y);

  y += 14;

  // ── Line-item table header ───────────────────────────────────────────────────
  doc.setFillColor(11, 17, 32);
  doc.rect(MARGIN, y, W - MARGIN * 2, 8, 'F');

  const cols = { desc: MARGIN + 2, qty: 100, rate: 130, amount: W - MARGIN - 2 };

  doc.setFontSize(7);
  doc.setFont('courier', 'bold');
  doc.setTextColor(...white);
  doc.text('DESCRIPTION', cols.desc, y + 5.5);
  doc.text('QTY', cols.qty, y + 5.5);
  doc.text('UNIT RATE', cols.rate, y + 5.5);
  doc.text('AMOUNT', cols.amount, y + 5.5, { align: 'right' });

  y += 10;

  // ── Line items ───────────────────────────────────────────────────────────────
  const rateKey = inv.drawingType.toUpperCase().replace(/\s+/g, '_');
  const unitRate = TYPE_RATES[rateKey] ?? 1500;
  const area = Math.round(inv.amount / (unitRate * 0.006 + 1)); // reverse-approx
  const serviceCharge = Math.round(unitRate * 0.1);

  const lineItems = [
    { desc: `${inv.drawingType} — Technical Drawing Service`, qty: 1, rate: unitRate, amt: unitRate },
    { desc: `Area-based calculation (est. ${area || 1500} sqft)`, qty: 1, rate: inv.amount - unitRate - serviceCharge, amt: inv.amount - unitRate - serviceCharge },
    { desc: 'Studio Service Charge', qty: 1, rate: serviceCharge, amt: serviceCharge },
  ];

  lineItems.forEach((item, i) => {
    const rowY = y + i * 9;
    if (i % 2 === 1) {
      doc.setFillColor(241, 245, 249);
      doc.rect(MARGIN, rowY - 1.5, W - MARGIN * 2, 9, 'F');
    }
    doc.setFontSize(8);
    doc.setFont('helvetica', 'normal');
    doc.setTextColor(30, 41, 59);
    doc.text(item.desc, cols.desc, rowY + 5);
    doc.text(String(item.qty), cols.qty, rowY + 5);
    doc.text(formatCurrency(item.rate), cols.rate, rowY + 5);
    doc.text(formatCurrency(item.amt), cols.amount, rowY + 5, { align: 'right' });
  });

  y += lineItems.length * 9 + 6;

  // ── Totals block ─────────────────────────────────────────────────────────────
  doc.setDrawColor(226, 232, 240);
  doc.setLineWidth(0.3);
  doc.line(MARGIN, y, W - MARGIN, y);
  y += 6;

  const totals: [string, string, boolean][] = [
    ['Subtotal', formatCurrency(inv.amount - serviceCharge), false],
    ['Studio Service Charge (10%)', formatCurrency(serviceCharge), false],
    ['TOTAL DUE', formatCurrency(inv.amount), true],
  ];

  totals.forEach(([label, val, bold]) => {
    doc.setFontSize(bold ? 11 : 8);
    doc.setFont('helvetica', bold ? 'bold' : 'normal');
    doc.setTextColor(bold ? 11 : 71, bold ? 17 : 85, bold ? 32 : 105);
    doc.text(label, W - MARGIN - 60, y);
    doc.setTextColor(...(bold ? blue : slate600));
    doc.text(val, W - MARGIN, y, { align: 'right' });
    if (bold) {
      doc.setFillColor(...blue);
      doc.roundedRect(W - MARGIN - 62, y - 5, 62, 8, 1, 1, 'S');
    }
    y += bold ? 10 : 7;
  });

  y += 6;

  // ── Payment status bar ───────────────────────────────────────────────────────
  const statusColors: Record<string, [number, number, number]> = {
    PAID: [16, 185, 129], UNPAID: [245, 158, 11], OVERDUE: [244, 63, 94], IN_PROGRESS: [59, 130, 246],
  };
  const sc = statusColors[inv.status] ?? blue;
  doc.setFillColor(...sc);
  doc.roundedRect(MARGIN, y, W - MARGIN * 2, 10, 2, 2, 'F');
  doc.setFontSize(8);
  doc.setFont('helvetica', 'bold');
  doc.setTextColor(...white);
  doc.text(`PAYMENT STATUS: ${inv.status}`, W / 2, y + 6.5, { align: 'center' });
  y += 18;

  // ── Studio stats footer ───────────────────────────────────────────────────────
  doc.setFontSize(7);
  doc.setFont('courier', 'normal');
  doc.setTextColor(...slate400);
  doc.text(`Studio Total Revenue: ${formatCurrency(totalRevenue)}`, MARGIN, y);
  doc.text(`Collection Rate: ${collectionRate}%`, W / 2, y, { align: 'center' });
  doc.text('Generated by Archi Draft Admin v2', W - MARGIN, y, { align: 'right' });
  y += 5;

  // ── Bottom border ─────────────────────────────────────────────────────────────
  doc.setFillColor(...midnight);
  doc.rect(0, 287, W, 10, 'F');
  doc.setFontSize(6.5);
  doc.setFont('courier', 'normal');
  doc.setTextColor(...slate400);
  doc.text('Draughtsman Studio · PixelMint MVS · contact@draughtsmanstudio.com', W / 2, 292.5, { align: 'center' });

  // ── Save ──────────────────────────────────────────────────────────────────────
  doc.save(`${inv.id}.pdf`);
}

// ─── Page ─────────────────────────────────────────────────────────────────────

type FilterStatus = 'ALL' | 'PAID' | 'UNPAID' | 'OVERDUE' | 'IN_PROGRESS';

const FILTER_TABS: { key: FilterStatus; label: string }[] = [
  { key: 'ALL', label: 'All Invoices' },
  { key: 'PAID', label: 'Paid' },
  { key: 'UNPAID', label: 'Unpaid' },
  { key: 'IN_PROGRESS', label: 'In Progress' },
  { key: 'OVERDUE', label: 'Overdue' },
];

export default function FinancialsPage() {
  const [projects, setProjects] = useState<Project[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [filter, setFilter] = useState<FilterStatus>('ALL');
  const [refreshing, setRefreshing] = useState(false);
  const [generatingId, setGeneratingId] = useState<string | null>(null);

  const fetchData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);
    try {
      setProjects(await adminApi.getProjects());
    } catch (err: any) {
      setError(err.message || 'Failed to load project data');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    fetchData();
  }, []);

  const invoices = deriveInvoicesFromProjects(projects);
  const paidInvoices = invoices.filter((i) => i.status === 'PAID');
  const totalRevenue = paidInvoices.reduce((s, i) => s + i.amount, 0);
  const outstanding = invoices
    .filter((i) => i.status === 'UNPAID' || i.status === 'OVERDUE')
    .reduce((s, i) => s + i.amount, 0);
  const inProgressVal = invoices
    .filter((i) => i.status === 'IN_PROGRESS')
    .reduce((s, i) => s + i.amount, 0);
  const totalPipeline = invoices.reduce((s, i) => s + i.amount, 0);
  const collectionRate = totalPipeline > 0 ? Math.round((totalRevenue / totalPipeline) * 100) : 0;
  const filtered = filter === 'ALL' ? invoices : invoices.filter((i) => i.status === filter);

  // ── PDF download handler ──────────────────────────────────────────────────────
  const handleDownloadPDF = async (inv: DerivedInvoice) => {
    setGeneratingId(inv.id);
    setError(null);
    try {
      await generateInvoicePDF(inv, totalRevenue, collectionRate);
    } catch (err: any) {
      console.error('PDF generation failed', err);
      setError('Invoice PDF generation failed. Ensure your browser allows popups and file downloads.');
    } finally {
      setGeneratingId(null);
    }
  };

  // KPI card definitions
  const kpiCards = [
    {
      label: 'Total Revenue Collected',
      value: formatCurrency(totalRevenue),
      sub: `${paidInvoices.length} paid invoices`,
      Icon: CheckCircle2,
      iconBg: 'bg-emerald-50 text-emerald-700 border border-emerald-200',
      trend: '+8% from last quarter',
      trendUp: true,
    },
    {
      label: 'Outstanding Balance',
      value: formatCurrency(outstanding),
      sub: `${invoices.filter((i) => i.status === 'UNPAID' || i.status === 'OVERDUE').length} open invoices`,
      Icon: AlertCircle,
      iconBg: 'bg-amber-50 text-amber-700 border border-amber-200',
      trend: 'Requires follow-up',
      trendUp: false,
    },
    {
      label: 'Pipeline Value (Active)',
      value: formatCurrency(inProgressVal),
      sub: `${invoices.filter((i) => i.status === 'IN_PROGRESS').length} active projects`,
      Icon: BarChart2,
      iconBg: 'bg-blue-50 text-[#0453cd] border border-blue-200',
      trend: 'Projected earnings',
      trendUp: true,
    },
    {
      label: 'Collection Rate',
      value: `${collectionRate}%`,
      sub: `${formatCurrency(totalPipeline)} total pipeline`,
      Icon: TrendingUp,
      iconBg: 'bg-purple-50 text-purple-700 border border-purple-200',
      trend: collectionRate >= 70 ? 'On target' : 'Below target',
      trendUp: collectionRate >= 70,
    },
  ];

  return (
    <AdminShell
      title="Financials & Revenue Ledger"
      subtitle="Studio revenue ledger — derived from active project pipeline"
      onRefresh={() => fetchData(true)}
      isRefreshing={refreshing}
    >
      <div className="relative">
        {/* BLUR OVERLAY */}
        <div className="absolute inset-0 z-10 backdrop-blur-md bg-white/60 dark:bg-neutral-900/60 flex flex-col items-center justify-center gap-4 rounded-xl">
          <div className="text-center space-y-2 px-6">
            <span className="text-4xl">🔒</span>
            <h2 className="text-2xl font-semibold text-neutral-800 dark:text-neutral-100">
              Payment Integration Coming Soon
            </h2>
            <p className="text-neutral-500 dark:text-neutral-400 max-w-sm text-sm">
              The financials and invoicing module is currently under
              development. Full payment gateway integration will be
              available in an upcoming release.
            </p>
            <span className="inline-block mt-2 px-3 py-1 text-xs font-medium rounded-full bg-amber-100 text-amber-700 dark:bg-amber-900/40 dark:text-amber-300">
              Coming Soon
            </span>
          </div>
        </div>

        {/* EXISTING CONTENT — keep all of it, just blurred */}
        <div className="pointer-events-none select-none blur-sm opacity-40">
          {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-50 border border-rose-200 text-sm text-rose-800 flex items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
            <span>{error}</span>
          </div>
          <button
            onClick={() => setError(null)}
            className="text-xs font-mono text-rose-600 hover:text-rose-800 underline"
          >
            Dismiss
          </button>
        </div>
      )}

      {loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500 mt-3 font-medium">Computing financial ledger...</p>
        </div>
      ) : (
        <div className="space-y-6">
          {/* Transparent Ledger Notice */}
          <div className="p-4 rounded-xl bg-blue-50/70 border border-blue-200/80 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
            <div className="flex items-center gap-2.5">
              <Receipt className="h-4 w-4 text-[#0453cd] shrink-0" />
              <span className="text-slate-700 leading-relaxed">
                <strong className="text-slate-900">Commercial Policy Transparency:</strong> Invoices and revenue figures are deterministically derived from project area footprints and discipline tariffs. Itemized figures reflect standard studio billing rates.
              </span>
            </div>
            <span className="text-[10px] font-mono font-semibold px-2.5 py-1 rounded-md bg-white border border-blue-200 text-[#0453cd] whitespace-nowrap self-start sm:self-auto shadow-xs">
              DERIVED ESTIMATE
            </span>
          </div>

          {/* ── KPI Stat Cards ── */}
          <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
            {kpiCards.map(({ label, value, sub, Icon, iconBg, trend, trendUp }) => (
              <div
                key={label}
                className="bg-white border border-slate-200 rounded-xl p-5 flex flex-col justify-between gap-3 shadow-sm hover:border-slate-300 transition-all relative"
              >
                <div className="flex items-start justify-between">
                  <p className="text-xs font-bold uppercase tracking-wider text-slate-500">{label}</p>
                  <div className={`p-2 rounded-lg ${iconBg}`}>
                    <Icon className="h-4 w-4" />
                  </div>
                </div>
                <div>
                  <p className="text-2xl font-extrabold text-slate-900 font-mono tracking-tight">{value}</p>
                  <p className="text-xs text-slate-500 mt-1">{sub}</p>
                  <div className={`mt-2 flex items-center gap-1 text-xs font-medium ${trendUp ? 'text-emerald-700' : 'text-amber-700'}`}>
                    {trendUp ? <ArrowUpRight className="h-3.5 w-3.5" /> : <ArrowDownRight className="h-3.5 w-3.5" />}
                    <span>{trend}</span>
                  </div>
                </div>
              </div>
            ))}
          </div>

          {/* ── Collection Progress Bar ── */}
          <div className="bg-white border border-slate-200 rounded-xl p-6 shadow-sm">
            <div>
              <div className="flex items-center justify-between mb-1">
                <p className="text-xs font-bold uppercase tracking-wider text-slate-500">
                  Revenue Collection Progress
                </p>
                <span className="text-xs font-bold text-[#0453cd] font-mono">{collectionRate}%</span>
              </div>
              <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden mt-3">
                <div
                  className="h-2 rounded-full bg-[#0453cd] transition-all duration-700"
                  style={{ width: `${collectionRate}%` }}
                />
              </div>
              <div className="flex justify-between mt-3 text-xs">
                <div>
                  <p className="text-[10px] font-mono uppercase text-slate-400">Collected</p>
                  <p className="text-sm font-bold text-slate-900 font-mono">{formatCurrency(totalRevenue)}</p>
                </div>
                <div className="text-right">
                  <p className="text-[10px] font-mono uppercase text-slate-400">Total Pipeline</p>
                  <p className="text-sm font-bold text-slate-900 font-mono">{formatCurrency(totalPipeline)}</p>
                </div>
              </div>
            </div>
          </div>

          {/* ── Invoice Ledger ── */}
          <div className="bg-white border border-slate-200 rounded-xl overflow-hidden shadow-sm">
            {/* Header */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2.5 px-4 sm:px-6 py-4 border-b border-slate-200 bg-slate-50/60">
              <div className="flex items-center gap-3">
                <Receipt className="h-4 w-4 text-[#0453cd]" />
                <h2 className="text-sm font-bold text-slate-900">Invoice Ledger</h2>
                <span className="text-xs font-mono text-slate-600 px-2 py-0.5 bg-slate-200 rounded-full">
                  {filtered.length} records
                </span>
              </div>
              <div className="flex items-center gap-2 text-xs font-mono text-slate-500">
                <Filter className="h-3.5 w-3.5 text-slate-400" />
                <span>Click <Download className="inline h-3 w-3 text-[#0453cd]" /> to download PDF</span>
              </div>
            </div>

            {/* Filter Tabs */}
            <div className="flex items-center gap-2 px-4 sm:px-6 py-3 border-b border-slate-100 overflow-x-auto w-full max-w-full bg-white scrollbar-none">
              {FILTER_TABS.map((tab) => (
                <button
                  key={tab.key}
                  onClick={() => setFilter(tab.key)}
                  className={`px-3 py-1.5 rounded-lg text-xs font-mono uppercase tracking-wider whitespace-nowrap transition-all ${
                    filter === tab.key
                      ? 'bg-[#0d1c32] text-white shadow-sm font-semibold'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>

            {/* Table */}
            {filtered.length === 0 ? (
              <div className="flex flex-col items-center justify-center py-16">
                <FileText className="h-10 w-10 text-slate-400 mb-3" />
                <p className="text-sm font-semibold text-slate-900">No invoices found for this filter</p>
                <p className="text-xs text-slate-500 mt-1">Projects in DRAFT state are excluded</p>
              </div>
            ) : (
              <>
                {/* Table (Desktop >= 640px) */}
                <div className="hidden sm:block overflow-x-auto w-full max-w-full">
                  <table className="w-full text-left min-w-[720px]">
                    <thead className="bg-slate-50 border-b border-slate-200">
                      <tr>
                        {['Invoice ID', 'Project', 'Drawing Type', 'Issued', 'Amount', 'Status', 'PDF'].map(
                          (h) => (
                            <th
                              key={h}
                              className="px-6 py-3 text-[10px] font-mono uppercase tracking-wider text-slate-500 font-semibold"
                            >
                              {h}
                            </th>
                          )
                        )}
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-slate-200">
                      {filtered.map((inv) => (
                        <tr key={inv.id} className="group hover:bg-slate-50/80 transition-colors">
                          <td className="px-6 py-4">
                            <span className="font-mono text-xs font-semibold text-[#0453cd]">{inv.id}</span>
                          </td>
                          <td className="px-6 py-4">
                            <p className="text-xs font-semibold text-slate-900 max-w-[180px] truncate">
                              {inv.projectName}
                            </p>
                            <p className="text-[10px] text-slate-500 font-mono truncate max-w-[180px]">
                              {inv.projectId.substring(0, 12)}…
                            </p>
                          </td>
                          <td className="px-6 py-4">
                            <span className="text-xs text-slate-600">{inv.drawingType}</span>
                          </td>
                          <td className="px-6 py-4">
                            <span className="text-xs text-slate-500 font-mono">{formatDate(inv.issuedAt)}</span>
                          </td>
                          <td className="px-6 py-4">
                            <span className="text-sm font-bold text-slate-900 font-mono">
                              {formatCurrency(inv.amount)}
                            </span>
                          </td>
                          <td className="px-6 py-4">
                            <InvoiceStatusBadge status={inv.status} />
                          </td>
                          <td className="px-6 py-4">
                            <button
                              title={`Download ${inv.id} as PDF`}
                              disabled={generatingId === inv.id}
                              onClick={() => handleDownloadPDF(inv)}
                              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-50 hover:bg-blue-100 border border-blue-200 text-[#0453cd] text-xs font-semibold transition-all disabled:opacity-50 disabled:cursor-wait"
                            >
                              {generatingId === inv.id ? (
                                <Loader2 className="h-3.5 w-3.5 animate-spin" />
                              ) : (
                                <Download className="h-3.5 w-3.5" />
                              )}
                              <span className="hidden sm:inline">
                                {generatingId === inv.id ? 'Building…' : 'PDF'}
                              </span>
                            </button>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>

                {/* Responsive Card View (Mobile < 640px) */}
                <div className="block sm:hidden divide-y divide-slate-100 p-4 space-y-3">
                  {filtered.map((inv) => (
                    <div key={inv.id} className="pt-3 first:pt-0 bg-slate-50/60 rounded-xl p-3.5 border border-slate-200">
                      <div className="flex items-center justify-between gap-2 mb-2">
                        <span className="font-mono text-xs font-bold text-[#0453cd]">{inv.id}</span>
                        <InvoiceStatusBadge status={inv.status} />
                      </div>
                      <p className="text-xs font-bold text-slate-900 leading-tight mb-1">{inv.projectName}</p>
                      <div className="flex items-center justify-between text-[11px] text-slate-500 font-mono mb-2">
                        <span>{inv.drawingType}</span>
                        <span>{formatDate(inv.issuedAt)}</span>
                      </div>
                      <div className="flex items-center justify-between pt-2 border-t border-slate-200/80">
                        <div>
                          <span className="text-[10px] uppercase font-mono text-slate-400 block">Total Due</span>
                          <span className="text-sm font-extrabold text-slate-900 font-mono">{formatCurrency(inv.amount)}</span>
                        </div>
                        <button
                          title={`Download ${inv.id} as PDF`}
                          disabled={generatingId === inv.id}
                          onClick={() => handleDownloadPDF(inv)}
                          className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-blue-50 hover:bg-blue-100 border border-blue-200 text-[#0453cd] text-xs font-semibold transition-all disabled:opacity-50"
                        >
                          {generatingId === inv.id ? (
                            <Loader2 className="h-3.5 w-3.5 animate-spin" />
                          ) : (
                            <Download className="h-3.5 w-3.5" />
                          )}
                          <span>{generatingId === inv.id ? 'Building…' : 'Download PDF'}</span>
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>

          {/* ── Recent Payments Timeline ── */}
          {paidInvoices.length > 0 && (
            <Card>
              <CardHeader title="Recent Payments Settled" />
              <div className="space-y-3 p-6 pt-0">
                {paidInvoices.slice(0, 5).map((inv) => (
                  <div key={inv.id} className="flex items-center gap-4 py-2 border-b border-slate-100 last:border-0">
                    <div className="h-8 w-8 rounded-lg bg-emerald-50 border border-emerald-200 flex items-center justify-center shrink-0">
                      <CheckCircle2 className="h-4 w-4 text-emerald-600" />
                    </div>
                    <div className="flex-1 min-w-0">
                      <p className="text-xs font-semibold text-slate-900 truncate">
                        {inv.projectName} —{' '}
                        <span className="font-mono font-bold text-emerald-700">{formatCurrency(inv.amount)}</span>
                      </p>
                      <p className="text-[11px] font-mono text-slate-500 mt-0.5">
                        {inv.id} · Paid {formatDate(inv.paidAt || inv.issuedAt)}
                      </p>
                    </div>
                    <div className="flex items-center gap-2 shrink-0">
                      <span className="text-[10px] font-mono font-semibold text-emerald-700 bg-emerald-50 border border-emerald-200 rounded-full px-2.5 py-0.5">
                        SETTLED
                      </span>
                      <button
                        onClick={() => handleDownloadPDF(inv)}
                        disabled={generatingId === inv.id}
                        title="Download PDF"
                        className="p-1.5 rounded-lg hover:bg-slate-100 text-slate-500 hover:text-[#0453cd] transition-colors disabled:opacity-40"
                      >
                        {generatingId === inv.id ? (
                          <Loader2 className="h-3.5 w-3.5 animate-spin" />
                        ) : (
                          <Download className="h-3.5 w-3.5" />
                        )}
                      </button>
                    </div>
                  </div>
                ))}
              </div>
              {paidInvoices.length > 5 && (
                <div className="px-6 py-3 border-t border-slate-100 bg-slate-50/50">
                  <p className="text-xs text-slate-500 text-center font-mono">
                    Showing 5 of {paidInvoices.length} settlements. Use the Invoice Ledger above for complete history.
                  </p>
                </div>
              )}
            </Card>
          )}

          {/* Studio watermark */}
          <div className="text-right">
            <p className="text-[11px] font-mono text-slate-400">
              Archi Draft Precision Ledger · Draughtsman Studio Platform
            </p>
          </div>
        </div>
      )}
        </div>
      </div>
    </AdminShell>
  );
}

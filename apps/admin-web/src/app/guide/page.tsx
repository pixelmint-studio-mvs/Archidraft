'use client';

import React, { useState } from 'react';
import Link from 'next/link';

interface ButtonItem {
  name: string;
  action: string;
  result: string;
  tag?: string;
}

interface GuideSection {
  id: string;
  num: string;
  title: string;
  route: string;
  badge: string;
  image: string;
  summary: string;
  wordings: string[];
  buttons: ButtonItem[];
  tips?: string;
}

const SECTIONS: GuideSection[] = [
  {
    id: 'login',
    num: '01',
    title: 'Authentication & Security Gateway',
    route: '/login',
    badge: 'Security Gateway',
    image: '/guide/01-admin-login-shell.png',
    summary: 'The administrative front door securing the studio ecosystem via Firebase Authentication and Cloudflare D1 role authorization.',
    wordings: [
      'The Login screen is the exclusive gateway for Studio Administrators to access client briefs, engineering deliverables, and financial statements.',
      'When you enter your credentials, Firebase Auth validates your identity and issues a Google-signed JSON Web Token (JWT).',
      'The Cloudflare Worker cross-references your Firebase UID (bCrLwG8lMRbViDOrBmClwc96xJ42) against the D1 users database to verify that you possess the canonical STUDIO_ADMIN role before granting dashboard access.'
    ],
    buttons: [
      {
        name: 'Email Input (#admin-email-input)',
        action: 'Accepts registered administrator email (contact@draughtsmanstudio.com).',
        result: 'RFC regex validation checks format in real time',
        tag: 'Input'
      },
      {
        name: 'Password Input (#admin-password-input)',
        action: 'Accepts admin password (AAAJ@PMS or AAAJ@PIXELMINT). Eye icon toggles cleartext visibility.',
        result: 'Transmits securely over HTTPS to Firebase Auth',
        tag: 'Input'
      },
      {
        name: 'Sign In as Studio Admin (#admin-login-submit)',
        action: 'Validates credentials, retrieves JWT, authorizes session, and navigates to Dashboard.',
        result: 'Redirects to /dashboard upon success',
        tag: 'Primary Action'
      },
      {
        name: 'Forgot password? Link',
        action: 'Navigates to /forgot-password to trigger an official password reset email.',
        result: 'Dispatches Firebase recovery email',
        tag: 'Navigation'
      },
      {
        name: '3D Monogram Canvas',
        action: 'Interactive 3D geometric architectural monogram rendered with Three.js.',
        result: 'Responds with subtle tilt to cursor or touch interaction',
        tag: 'Interactive'
      }
    ],
    tips: 'If you ever encounter an "Invalid email or password" warning, ensure you are using AAAJ@PMS (PMS stands for PixelMint Studio).'
  },
  {
    id: 'dashboard',
    num: '02',
    title: 'Executive Command Cockpit',
    route: '/dashboard',
    badge: 'Operations Cockpit',
    image: '/guide/03-admin-dashboard-hydrated.png',
    summary: 'Real-time studio oversight panel tracking live drafting metrics, active workloads, and cloud infrastructure latency.',
    wordings: [
      'The Executive Dashboard is designed for studio coordinators to assess studio capacity and deliverable status within seconds of opening the application.',
      'The top metric cards continuously query Cloudflare D1 to compute aggregate totals for all projects, active drafting assignments, pending redline reviews, and registered engineers/architects.',
      'The Cloud System Health widget monitors round-trip ping latency across Cloudflare D1 (Database), Cloudflare R2 (CAD Storage), and Firebase Auth.'
    ],
    buttons: [
      {
        name: 'Total Projects Card',
        action: 'Displays total project count commissioned across all client engineers/architects and students.',
        result: 'Real-time D1 count query',
        tag: 'KPI Metric'
      },
      {
        name: 'In Progress Card',
        action: 'Displays projects currently actively drafted by professional drafters or academy students.',
        result: 'Filters projects by status = IN_PROGRESS',
        tag: 'KPI Metric'
      },
      {
        name: 'Under Review Card',
        action: 'Highlights drawings submitted for admin quality inspection or client signoff.',
        result: 'Filters projects by status = UNDER_REVIEW',
        tag: 'KPI Metric'
      },
      {
        name: 'Active Draughtsmen Card',
        action: 'Shows number of verified professional draughtsmen currently carrying active projects.',
        result: 'D1 active specialists count',
        tag: 'KPI Metric'
      },
      {
        name: 'Cloud Health Widget',
        action: 'Monitors ping latency for D1 Database, R2 Object Storage, and Firebase Auth.',
        result: 'Green status indicator confirms 100% cloud uptime',
        tag: 'Diagnostics'
      },
      {
        name: 'View All Projects Button',
        action: 'Fast redirect from Recent Projects table to the full project catalogue.',
        result: 'Navigates to /projects',
        tag: 'Navigation'
      }
    ],
    tips: 'Clicking any project title in the Recent Projects list opens its Project Dossier immediately without having to search the full catalogue.'
  },
  {
    id: 'projects',
    num: '03',
    title: 'Projects Catalogue & Pipeline',
    route: '/projects',
    badge: 'Project Governance',
    image: '/guide/04-admin-projects-queue.png',
    summary: 'Comprehensive projects repository featuring multi-state lifecycle filtering, instant text search, and rapid dispatch initiation.',
    wordings: [
      'The Projects Catalogue visualizes every architectural assignment across its complete lifecycle.',
      'The lifecycle starts at BRIEF_SUBMITTED (when an engineer/architect submits a brief), moves to READY_TO_ASSIGN (once approved by admin), then ASSIGNED, IN_PROGRESS, UNDER_REVIEW, and finally COMPLETED.',
      'The instant search input queries project titles, site addresses, and client engineer/architect names in real time without triggering full-page refreshes.'
    ],
    buttons: [
      {
        name: 'Status Filter Tabs',
        action: 'Filters catalogue by: All, Brief Submitted, Ready to Assign, Assigned, In Progress, Under Review, Completed.',
        result: 'Filters cards in memory instantaneously',
        tag: 'Filter'
      },
      {
        name: 'Search Bar (#project-search-input)',
        action: 'Accepts project name, address, or client engineer/architect name.',
        result: 'Matches substring across all project records',
        tag: 'Search'
      },
      {
        name: '+ New Project Button',
        action: 'Launches the 3-step project commissioning modal wizard.',
        result: 'Opens project creation dialog',
        tag: 'Primary Action'
      },
      {
        name: 'Assign Draughtsman Button',
        action: 'Direct quick-action on unassigned project cards to trigger the specialist dispatch modal.',
        result: 'Opens Draughtsman Dispatch modal',
        tag: 'Quick Action'
      },
      {
        name: 'Project Card Click',
        action: 'Opens the full Project Dossier containing scope narrative, redlines, and deliverables.',
        result: 'Navigates to /projects/[id]',
        tag: 'Navigation'
      }
    ]
  },
  {
    id: 'new-project',
    num: '04',
    title: 'Project Creation Wizard',
    route: '/projects (Modal)',
    badge: 'Project Commissioning',
    image: '/guide/06-admin-new-project-modal.png',
    summary: '3-step guided modal to commission new architectural drawing projects, configure technical specifications, and upload brief assets.',
    wordings: [
      'The Project Creation Wizard allows studio administrators to commission projects on behalf of clients or create practice briefs for academy students.',
      'Step 1 sets project identity, target assignee (e.g. Student 1 / Sarah Jenkins), physical site address, and narrative drafting instructions.',
      'Step 2 specifies the architectural discipline (Layout, Structural, MEP, Interior, Permit), drawing scale (1:50, 1:100, 1:200), and footprint area.',
      'Step 3 allows uploading hand sketches, PDF site plans, or preliminary CAD files directly into Cloudflare R2 object storage.'
    ],
    buttons: [
      {
        name: 'Assignee Dropdown',
        action: 'Selects the target draughtsman or academy student from the registered roster.',
        result: 'Binds foreign key assignee_id',
        tag: 'Step 1'
      },
      {
        name: 'Project Title & Address Fields',
        action: 'Defines canonical project name and physical site location.',
        result: 'Stored in projects table',
        tag: 'Step 1'
      },
      {
        name: 'Discipline Selector',
        action: 'Selects Architectural Layout, Structural Framing, MEP & HVAC, Interior, or Municipal Permit.',
        result: 'Categorizes technical requirements',
        tag: 'Step 2'
      },
      {
        name: 'Scale & Area Inputs',
        action: 'Sets drawing scale (1:50, 1:100, 1:200) and square footage (default: 1500 sq. ft.).',
        result: 'Configures drafting parameters',
        tag: 'Step 2'
      },
      {
        name: 'CAD & Brief File Uploader',
        action: 'Drag-and-drop zone for PDF specifications, DWG base files, or reference photos.',
        result: 'Streams directly to Cloudflare R2 bucket',
        tag: 'Step 3'
      },
      {
        name: 'Create Project Button',
        action: 'Submits form via POST /api/projects, creates project record, and alerts the assigned drafter.',
        result: 'Persists in D1 and closes modal',
        tag: 'Finalize'
      }
    ]
  },
  {
    id: 'assign',
    num: '05',
    title: 'Draughtsman Dispatch & Workload',
    route: '/projects -> Assign',
    badge: 'Dispatch & Workload',
    image: '/guide/04-admin-assign-modal.png',
    summary: 'Capacity-aware dispatch interface ensuring projects are assigned to specialists with available bandwidth and matching discipline credentials.',
    wordings: [
      'The Dispatch modal prevents drafter burnout by displaying active workload indicators (e.g. 0/3 projects) for every specialist.',
      'Administrators can inspect specialized qualifications (e.g., Structural vs Architectural Interior) before confirming dispatch.',
      'Submitting the modal updates the project status from READY_TO_ASSIGN to ASSIGNED in Cloudflare D1 and sends an assignment alert to the drafter.'
    ],
    buttons: [
      {
        name: 'Specialist Selection List',
        action: 'Lists all verified draughtsmen alongside their current active project count.',
        result: 'Selects specialist for dispatch',
        tag: 'Selection'
      },
      {
        name: 'Discipline Match Badge',
        action: 'Highlights specialists whose registered profile matches the project discipline.',
        result: 'Prevents competence mismatch',
        tag: 'Validation'
      },
      {
        name: 'Assignment Directives Field',
        action: 'Input for specific drafting instructions, standards, and priorities.',
        result: 'Saved in assignment record',
        tag: 'Input'
      },
      {
        name: 'Deadline Date Picker',
        action: 'Sets target milestone date for initial draft delivery.',
        result: 'Initializes SLA countdown timer',
        tag: 'Schedule'
      },
      {
        name: 'Confirm Assignment Button',
        action: 'Executes POST /api/projects/:id/assign and locks assignment in Cloudflare D1.',
        result: 'Transitions project to ASSIGNED',
        tag: 'Finalize'
      }
    ]
  },
  {
    id: 'dossier-overview',
    num: '06',
    title: 'Project Dossier: Scope & Client Brief',
    route: '/projects/[id]',
    badge: 'Project Dossier',
    image: '/guide/07-admin-project-detail-r1.png',
    summary: 'Master operational view detailing project metadata, client contact coordinates, site specifications, and scope of work.',
    wordings: [
      'The Project Dossier is the central hub for each engagement, structured into three primary tabs: Overview, Redlines & QA, and Deliverables.',
      'The Overview screen displays client firm contact details, site address, assigned draughtsman, and the unedited client brief narrative.',
      'Administrators can modify project settings or soft-delete cancelled engagements directly from this screen.'
    ],
    buttons: [
      {
        name: 'Status Pill Badge',
        action: 'Displays current lifecycle status (e.g. IN_PROGRESS, UNDER_REVIEW, COMPLETED).',
        result: 'Real-time status reference',
        tag: 'Indicator'
      },
      {
        name: 'Sub-Navigation Tabs',
        action: 'Switches between Overview, Redlines & Quality Control, and Deliverables.',
        result: 'Toggles active dossier sub-view',
        tag: 'Navigation'
      },
      {
        name: 'Client Engineer/Architect Card',
        action: 'Displays client engineer/architect contact details, phone number, and firm affiliation.',
        result: 'Provides direct contact access',
        tag: 'Reference'
      },
      {
        name: 'Scope of Work Narrative',
        action: 'Full unedited drafting requirements and sheet index.',
        result: 'Authoritative brief reference',
        tag: 'Content'
      },
      {
        name: 'Edit Project Action',
        action: 'Opens modification modal to adjust deadline, drawing scale, or address.',
        result: 'Updates project in Cloudflare D1',
        tag: 'Action'
      }
    ]
  },
  {
    id: 'dossier-redlines',
    num: '07',
    title: 'Project Dossier: Redlines & QA',
    route: '/projects/[id] -> Redlines',
    badge: 'Quality Control',
    image: '/guide/08-admin-project-detail-r2.png',
    summary: 'Digital architectural redline review loop allowing administrators to inspect submissions, upload technical markups, and approve deliverables.',
    wordings: [
      'This screen digitizes the physical architectural red-pen review process.',
      'Revision milestones (R1, R2, R3) preserve complete version history so drafters and clients can verify that previous corrections were implemented.',
      'Clicking "Approve Deliverable" advances the project to COMPLETED and authorizes client release; clicking "Request Changes" returns it to IN_PROGRESS with feedback.'
    ],
    buttons: [
      {
        name: 'Revision Milestone Tabs (R1, R2, R3)',
        action: 'Cycles through revision history to compare initial drafts against revisions.',
        result: 'Loads historic revision assets',
        tag: 'Milestone'
      },
      {
        name: 'Redline Drawing Viewer',
        action: 'Visual canvas displaying CAD drawing sheets with overlaid redline markups.',
        result: 'High-res drawing inspection',
        tag: 'Viewer'
      },
      {
        name: '+ Upload Redline Markup',
        action: 'Uploads annotated PDF or CAD sketch detailing required technical fixes.',
        result: 'Streams markup to Cloudflare R2',
        tag: 'Upload'
      },
      {
        name: 'Approve Deliverable Button',
        action: 'Validates technical drawing quality, advances status to COMPLETED, and authorizes payment.',
        result: 'Unlocks final asset release',
        tag: 'Approval'
      },
      {
        name: 'Request Changes Button',
        action: 'Rejects submission with mandatory defect notes, resetting status to IN_PROGRESS for rework.',
        result: 'Sends revision alert to drafter',
        tag: 'Feedback'
      }
    ]
  },
  {
    id: 'dossier-deliverables',
    num: '08',
    title: 'Project Dossier: CAD File Repository',
    route: '/projects/[id] -> Deliverables',
    badge: 'Asset Repository',
    image: '/guide/09-admin-project-detail-r3.png',
    summary: 'Secure vault for downloading, hashing, and releasing final AutoCAD (.dwg), PDF, and BIM project deliverables.',
    wordings: [
      'All drawing sheets uploaded by draughtsmen and students are securely stored in Cloudflare R2 object storage with zero egress fees.',
      'The SHA-256 checksum validates that CAD files have not been corrupted during upload or download.',
      'The "Release to Client" toggle ensures that client engineers/architects cannot download final high-resolution DWG files until commercial milestones are satisfied.'
    ],
    buttons: [
      {
        name: 'Deliverables File List',
        action: 'Lists all drawing sheets with file extensions (.dwg, .pdf, .zip) and file sizes.',
        result: 'Complete deliverable inventory',
        tag: 'Inventory'
      },
      {
        name: 'Download CAD Package Button',
        action: 'Generates secure pre-signed Cloudflare R2 download URL to download all drawing files.',
        result: 'Direct encrypted download',
        tag: 'Download'
      },
      {
        name: 'SHA-256 Checksum Tag',
        action: 'Cryptographic hash confirming file integrity.',
        result: 'Guarantees uncorrupted transfer',
        tag: 'Security'
      },
      {
        name: 'Release to Client Toggle',
        action: 'Permission switch unlocking deliverable download links in the Client Engineer/Architect Portal.',
        result: 'Protects studio IP until billing signoff',
        tag: 'Commercial'
      },
      {
        name: 'Student Assessment Scorecard',
        action: 'Grading rubric (Accuracy, Layering, Line Weights) for apprentice student submissions.',
        result: 'Records grade in academy database',
        tag: 'Education'
      }
    ]
  },
  {
    id: 'users',
    num: '09',
    title: 'User & Talent Directory',
    route: '/users',
    badge: 'User Administration',
    image: '/guide/10-admin-user-directory.png',
    summary: 'Centralized directory managing Client Engineers/Architects, Professional Draughtsmen, Academy Students, and Studio Administrators.',
    wordings: [
      'The User Directory enforces role-based access control across all ArchiDraft web and mobile portals.',
      'Administrators can filter users by role, inspect professional credentials, and monitor account verification status.',
      'The row action menu (···) allows changing user roles, resetting passwords, or deactivating accounts.'
    ],
    buttons: [
      {
        name: 'Role Filter Tabs',
        action: 'Filters directory by role: All, Studio Admins, Draughtsmen, Client Engineers/Architects, and Students.',
        result: 'Segmented directory table',
        tag: 'Filter'
      },
      {
        name: 'Verification Status Pills',
        action: 'Displays account compliance status: Verified, Pending Verification, or Suspended.',
        result: 'Compliance status tracking',
        tag: 'Badge'
      },
      {
        name: 'Search Bar',
        action: 'Searches users by full name, email, phone number, or firm affiliation.',
        result: 'Real-time table filtering',
        tag: 'Search'
      },
      {
        name: '+ Add User / Invite Button',
        action: 'Launches invitation modal to onboard new draughtsmen or enroll apprentice students.',
        result: 'Dispatches registration invite',
        tag: 'Onboarding'
      },
      {
        name: 'Row Action Menu (···)',
        action: 'Dropdown to: View Portfolio, Change Role, Reset Password, or Deactivate User.',
        result: 'Administrative user modification',
        tag: 'Control'
      }
    ]
  },
  {
    id: 'assignments',
    num: '10',
    title: 'Global Assignment & Workload Matrix',
    route: '/assignments',
    badge: 'Capacity Planning',
    image: '/guide/11-admin-global-assignments.png',
    summary: 'Studio-wide operational matrix tracking capacity, active drawing sheets, and approaching deadlines.',
    wordings: [
      'This screen serves as the studio operations manager\'s daily capacity command center.',
      'The color-coded SLA countdown tags instantly highlight drawings due within 48 hours or overdue.',
      'If a specialist is delayed or unavailable, the "Reassign Project" override transfers the project immediately without losing revision history.'
    ],
    buttons: [
      {
        name: 'Specialist Workload Table',
        action: 'Displays each draughtsman alongside active sheet counts and project commitments.',
        result: 'Visualizes studio capacity',
        tag: 'Capacity'
      },
      {
        name: 'SLA Countdown Indicators',
        action: 'Color-coded tags highlighting deliverable urgency (Green >48h, Amber <24h, Red Overdue).',
        result: 'Proactive bottleneck alerts',
        tag: 'Deadline'
      },
      {
        name: 'Reassign Emergency Override',
        action: 'Transfers project from one draughtsman to another if delays occur.',
        result: 'Immediate reassignment in D1',
        tag: 'Override'
      },
      {
        name: 'Export Matrix Button',
        action: 'Downloads current studio workload ledger as CSV/Excel for operations reporting.',
        result: 'Generates offline spreadsheet',
        tag: 'Export'
      }
    ]
  },
  {
    id: 'settings',
    num: '11',
    title: 'Studio Governance & Settings',
    route: '/settings',
    badge: 'System Governance',
    image: '/guide/12-admin-studio-settings.png',
    summary: 'Administrative configuration panel for studio profile, API gateways, storage buckets, and security.',
    wordings: [
      'Studio settings allows administrators to configure organizational defaults, CAD layering standards, and cloud endpoints.',
      'The Cloudflare Worker and R2 storage status checks confirm live bindings to the remote staging infrastructure.',
      'Clicking "Test Connections" runs a simultaneous diagnostic health check across D1, R2, and Firebase Auth.'
    ],
    buttons: [
      {
        name: 'Studio Profile Inputs',
        action: 'Configures Studio Name, Contact Email, and standard drafting unit convention.',
        result: 'Sets global project defaults',
        tag: 'Config'
      },
      {
        name: 'Worker API Route Input',
        action: 'Configures backend worker route (imserratex.workers.dev).',
        result: 'Directs frontend API requests',
        tag: 'Endpoint'
      },
      {
        name: 'R2 Bucket Status Badge',
        action: 'Verifies active binding to archi-draft-storage-staging R2 bucket.',
        result: 'Confirms file storage health',
        tag: 'Storage'
      },
      {
        name: 'Firebase Project Config',
        action: 'Displays connected Firebase project ID (archi-draft-staging) and web app ID.',
        result: 'Confirms SSO integration',
        tag: 'Security'
      },
      {
        name: 'Test Connections Button',
        action: 'Executes diagnostic roundtrip ping checks across all connected cloud services.',
        result: 'Generates comprehensive health report',
        tag: 'Diagnostics'
      }
    ]
  },
  {
    id: 'audit',
    num: '12',
    title: 'Security & Activity Audit Log',
    route: '/audit',
    badge: 'Audit & Compliance',
    image: '/guide/13-admin-activity-audit.png',
    summary: 'Immutable compliance audit trail tracking every project state modification, deliverable release, and administrative access event.',
    wordings: [
      'High-value architectural blueprints demand rigorous access accountability.',
      'Every status transition, file upload, deliverable release, and role change is permanently logged with the actor\'s UID, IP address, and UTC timestamp.',
      'Administrators can filter events by category or export a signed CSV compliance report for clients and insurers.'
    ],
    buttons: [
      {
        name: 'Event Category Filter',
        action: 'Filters logs by: All Events, Auth Events, Project Lifecycle, File Downloads, or Admin Actions.',
        result: 'Isolates specific audit categories',
        tag: 'Filter'
      },
      {
        name: 'Actor Attribution Column',
        action: 'Displays the exact email and UID of the individual who performed the action.',
        result: 'Enforces complete accountability',
        tag: 'Security'
      },
      {
        name: 'IP Address & Timestamp',
        action: 'Records client IP address, user-agent, and precise UTC timestamp.',
        result: 'Meets architectural compliance',
        tag: 'Logging'
      },
      {
        name: 'Export Audit Log Button',
        action: 'Generates cryptographically signed CSV audit report for compliance auditing.',
        result: 'Produces compliance artifact',
        tag: 'Export'
      }
    ]
  },
  {
    id: 'financials',
    num: '13',
    title: 'Financials, Invoicing & Payouts',
    route: '/financials',
    badge: 'Commercial Governance',
    image: '/guide/14-admin-financials-frozen.png',
    summary: 'Commercial governance module tracking project contract values, client invoice states, and drafter disbursements.',
    wordings: [
      'The Financials module links drawing deliverables directly to client billing and contractor compensation.',
      'The Project Invoicing table displays whether an engagement is Pending Deposit, Invoiced, Paid, or Milestone Locked.',
      'Administrators can generate PDF commercial invoices and reconcile drafter payroll disbursements based on approved sheet counts.'
    ],
    buttons: [
      {
        name: 'Revenue Metric Cards',
        action: 'Displays total invoiced value, collected revenue, and outstanding receivables.',
        result: 'Visualizes studio cashflow',
        tag: 'KPI'
      },
      {
        name: 'Project Invoicing Table',
        action: 'Tracks billing status per project: Pending Deposit, Invoiced, Paid, or Locked.',
        result: 'Coordinates CAD file release',
        tag: 'Ledger'
      },
      {
        name: 'Drafter Payout Ledger',
        action: 'Calculates contractor payouts based on approved sheet counts and square footage tier.',
        result: 'Automates payroll calculations',
        tag: 'Payroll'
      },
      {
        name: 'Generate Invoice Button',
        action: 'Generates PDF invoice detailing project milestones, drawing sheets, and bank wire info.',
        result: 'Produces commercial invoice',
        tag: 'Billing'
      }
    ]
  }
];

export default function GuidePage() {
  const [activeTab, setActiveTab] = useState<'reading' | 'slides'>('reading');
  const [currentSlideIndex, setCurrentSlideIndex] = useState(0);
  const [copiedKey, setCopiedKey] = useState<string | null>(null);

  const copyToClipboard = (text: string, key: string) => {
    navigator.clipboard.writeText(text);
    setCopiedKey(key);
    setTimeout(() => setCopiedKey(null), 2000);
  };

  const currentSlide = SECTIONS[currentSlideIndex];

  return (
    <div className="min-h-screen bg-[#0B0F17] text-slate-100 font-sans pb-24">
      {/* Top Mobile Sticky Header */}
      <header className="sticky top-0 z-50 bg-[#0B0F17]/90 backdrop-blur-md border-b border-white/10 px-4 py-3 sm:px-8 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-gradient-to-tr from-blue-600 to-cyan-500 flex items-center justify-center font-bold text-white shadow-lg shadow-blue-500/20">
            AD
          </div>
          <div>
            <h1 className="text-sm sm:text-base font-bold text-white leading-tight">
              ArchiDraft Studio
            </h1>
            <p className="text-xs text-cyan-400 font-medium">Admin Operator Guide</p>
          </div>
        </div>

        {/* Action Buttons */}
        <div className="flex items-center gap-2">
          <Link
            href="/login"
            className="px-3 py-1.5 text-xs font-semibold bg-blue-600 hover:bg-blue-500 text-white rounded-lg transition-colors shadow-sm"
          >
            Sign In
          </Link>
          <Link
            href="/dashboard"
            className="hidden sm:inline-flex px-3 py-1.5 text-xs font-semibold bg-white/10 hover:bg-white/15 text-white rounded-lg transition-colors"
          >
            Dashboard
          </Link>
        </div>
      </header>

      {/* Hero Header with Mobile Quick Actions */}
      <div className="max-w-4xl mx-auto px-4 pt-6 pb-4 sm:pt-10">
        <div className="bg-gradient-to-br from-blue-950/40 via-slate-900 to-slate-950 border border-white/10 rounded-2xl p-5 sm:p-8 shadow-2xl relative overflow-hidden">
          <div className="absolute top-0 right-0 w-64 h-64 bg-blue-500/10 rounded-full blur-3xl -z-10" />

          <div className="flex flex-wrap items-center gap-2 mb-3">
            <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold tracking-wide uppercase bg-blue-500/20 text-blue-400 border border-blue-500/30">
              Mobile & Desktop Guide
            </span>
            <span className="px-2.5 py-0.5 rounded-full text-[11px] font-mono font-medium bg-emerald-500/20 text-emerald-400 border border-emerald-500/30">
              Production Verified
            </span>
          </div>

          <h2 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight mb-2">
            Admin Panel Complete Guide
          </h2>
          <p className="text-sm sm:text-base text-slate-300 leading-relaxed mb-6">
            A comprehensive reference explaining every screen, button, workflow, and operational feature in the ArchiDraft Studio Admin Portal.
          </p>

          {/* Quick Credential Box with One-Tap Copy */}
          <div className="bg-slate-900/90 border border-slate-700/60 rounded-xl p-3 sm:p-4 mb-6">
            <div className="text-xs font-bold text-slate-400 uppercase tracking-wider mb-2 flex items-center justify-between">
              <span>Admin Credentials</span>
              <span className="text-[10px] text-emerald-400 font-mono">Role: STUDIO_ADMIN</span>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs">
              <div className="flex items-center justify-between bg-black/40 px-3 py-2 rounded-lg border border-white/5">
                <span className="text-slate-400">Email:</span>
                <div className="flex items-center gap-2 font-mono text-white">
                  <span>contact@draughtsmanstudio.com</span>
                  <button
                    onClick={() => copyToClipboard('contact@draughtsmanstudio.com', 'email')}
                    className="text-blue-400 hover:text-blue-300 font-sans text-[11px]"
                  >
                    {copiedKey === 'email' ? '✓ Copied' : 'Copy'}
                  </button>
                </div>
              </div>
              <div className="flex items-center justify-between bg-black/40 px-3 py-2 rounded-lg border border-white/5">
                <span className="text-slate-400">Password:</span>
                <div className="flex items-center gap-2 font-mono text-emerald-400">
                  <span>AAAJ@PMS</span>
                  <button
                    onClick={() => copyToClipboard('AAAJ@PMS', 'pass')}
                    className="text-blue-400 hover:text-blue-300 font-sans text-[11px]"
                  >
                    {copiedKey === 'pass' ? '✓ Copied' : 'Copy'}
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Download & View Controls */}
          <div className="flex flex-wrap items-center gap-3">
            <a
              href="/ArchiDraft_Admin_Guide.docx"
              download
              className="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-blue-600 hover:bg-blue-500 text-white font-semibold text-xs transition-all shadow-md active:scale-95"
            >
              📄 Download Word (.docx)
            </a>
            <a
              href="/ArchiDraft_Admin_Deck.pptx"
              download
              className="flex-1 sm:flex-none inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-xl bg-slate-800 hover:bg-slate-700 text-white font-semibold text-xs border border-white/10 transition-all active:scale-95"
            >
              📊 Download PPT (.pptx)
            </a>
          </div>
        </div>

        {/* View Mode Toggle */}
        <div className="flex items-center justify-between mt-6 mb-4">
          <div className="flex items-center bg-slate-900 border border-white/10 rounded-xl p-1">
            <button
              onClick={() => setActiveTab('reading')}
              className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'reading'
                  ? 'bg-blue-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              📖 Reading Mode (Full Wordings)
            </button>
            <button
              onClick={() => setActiveTab('slides')}
              className={`px-4 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                activeTab === 'slides'
                  ? 'bg-blue-600 text-white shadow-sm'
                  : 'text-slate-400 hover:text-white'
              }`}
            >
              🖥️ Slide Deck Mode
            </button>
          </div>

          <span className="text-xs text-slate-400 hidden sm:inline">
            13 Complete Screens
          </span>
        </div>

        {/* Horizontal Quick-Jump Pills for Mobile */}
        {activeTab === 'reading' && (
          <div className="overflow-x-auto no-scrollbar flex items-center gap-2 pb-2 mb-6 border-b border-white/5">
            {SECTIONS.map((sec) => (
              <a
                key={sec.id}
                href={`#${sec.id}`}
                className="whitespace-nowrap px-3 py-1 rounded-full text-xs font-medium bg-slate-900 hover:bg-slate-800 border border-white/10 text-slate-300 hover:text-white transition-colors"
              >
                {sec.num}. {sec.title.split(' ')[0]}
              </a>
            ))}
          </div>
        )}
      </div>

      {/* Main Body: Mode 1 - Reading View */}
      {activeTab === 'reading' && (
        <main className="max-w-4xl mx-auto px-4 space-y-12">
          {SECTIONS.map((sec) => (
            <article
              key={sec.id}
              id={sec.id}
              className="bg-slate-900/60 border border-white/10 rounded-2xl p-5 sm:p-8 scroll-mt-20 shadow-xl"
            >
              {/* Header */}
              <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
                <div className="flex items-center gap-2">
                  <span className="text-blue-400 font-mono font-bold text-sm">
                    SECTION {sec.num}
                  </span>
                  <span className="text-slate-600">•</span>
                  <span className="text-xs font-semibold px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20">
                    {sec.badge}
                  </span>
                </div>
                <span className="text-xs font-mono px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
                  {sec.route}
                </span>
              </div>

              <h3 className="text-xl sm:text-2xl font-bold text-white mb-2">
                {sec.title}
              </h3>
              <p className="text-sm text-slate-300 mb-6 leading-relaxed">
                {sec.summary}
              </p>

              {/* Embedded Screenshot */}
              <div className="rounded-xl overflow-hidden border border-white/10 bg-black/60 mb-6 shadow-lg">
                <div className="bg-slate-950 px-3 py-2 border-b border-white/10 flex items-center justify-between text-xs text-slate-400">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2.5 h-2.5 rounded-full bg-red-500/80 inline-block" />
                    <span className="w-2.5 h-2.5 rounded-full bg-amber-500/80 inline-block" />
                    <span className="w-2.5 h-2.5 rounded-full bg-emerald-500/80 inline-block" />
                  </div>
                  <span className="font-mono text-[11px]">{sec.route}</span>
                </div>
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img
                  src={sec.image}
                  alt={sec.title}
                  className="w-full h-auto object-contain max-h-[460px] mx-auto"
                  loading="lazy"
                />
              </div>

              {/* Wordings / Detailed Explanation */}
              <div className="space-y-3 mb-6 bg-slate-950/40 p-4 rounded-xl border border-white/5">
                <h4 className="text-xs font-bold text-cyan-400 uppercase tracking-wider">
                  Operational Wordings & Context
                </h4>
                {sec.wordings.map((p, idx) => (
                  <p key={idx} className="text-xs sm:text-sm text-slate-300 leading-relaxed">
                    {p}
                  </p>
                ))}
              </div>

              {/* Buttons & Elements Breakdown Table */}
              <div>
                <h4 className="text-xs font-bold text-blue-400 uppercase tracking-wider mb-3">
                  Buttons & Interactive Controls
                </h4>
                <div className="space-y-2">
                  {sec.buttons.map((btn, bIdx) => (
                    <div
                      key={bIdx}
                      className="bg-slate-950/80 border border-white/5 rounded-xl p-3.5 hover:border-blue-500/30 transition-colors"
                    >
                      <div className="flex flex-wrap items-center justify-between gap-1 mb-1.5">
                        <span className="font-semibold text-white text-xs sm:text-sm">
                          {btn.name}
                        </span>
                        {btn.tag && (
                          <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-blue-900/40 text-blue-300 border border-blue-700/40">
                            {btn.tag}
                          </span>
                        )}
                      </div>
                      <p className="text-xs text-slate-300 mb-1.5 leading-normal">
                        {btn.action}
                      </p>
                      <div className="text-[11px] font-mono text-emerald-400/90 flex items-center gap-1.5">
                        <span className="text-slate-500">Result:</span>
                        <span>{btn.result}</span>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {sec.tips && (
                <div className="mt-4 p-3 bg-amber-500/10 border border-amber-500/20 rounded-xl text-xs text-amber-300 leading-relaxed">
                  💡 <span className="font-semibold">Operator Tip:</span> {sec.tips}
                </div>
              )}
            </article>
          ))}
        </main>
      )}

      {/* Main Body: Mode 2 - Slides Presentation View */}
      {activeTab === 'slides' && (
        <main className="max-w-4xl mx-auto px-4">
          <div className="bg-slate-900 border border-white/10 rounded-2xl overflow-hidden shadow-2xl">
            {/* Slide Navigation Bar */}
            <div className="bg-slate-950 px-4 py-3 border-b border-white/10 flex items-center justify-between">
              <div className="flex items-center gap-2">
                <span className="text-xs font-bold text-blue-400 font-mono">
                  Slide {currentSlideIndex + 1} of {SECTIONS.length}
                </span>
                <span className="text-slate-600">•</span>
                <span className="text-xs font-mono text-slate-400">
                  {currentSlide.route}
                </span>
              </div>

              <div className="flex items-center gap-2">
                <button
                  onClick={() => setCurrentSlideIndex((prev) => Math.max(0, prev - 1))}
                  disabled={currentSlideIndex === 0}
                  className="px-3 py-1 text-xs font-semibold rounded bg-white/10 hover:bg-white/20 disabled:opacity-30 disabled:cursor-not-allowed text-white"
                >
                  ← Prev
                </button>
                <button
                  onClick={() =>
                    setCurrentSlideIndex((prev) => Math.min(SECTIONS.length - 1, prev + 1))
                  }
                  disabled={currentSlideIndex === SECTIONS.length - 1}
                  className="px-3 py-1 text-xs font-semibold rounded bg-blue-600 hover:bg-blue-500 disabled:opacity-30 disabled:cursor-not-allowed text-white"
                >
                  Next →
                </button>
              </div>
            </div>

            {/* Slide Image */}
            <div className="bg-black/80 p-2 sm:p-4 border-b border-white/10">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src={currentSlide.image}
                alt={currentSlide.title}
                className="w-full h-auto object-contain max-h-[440px] mx-auto rounded-lg"
              />
            </div>

            {/* Slide Content */}
            <div className="p-5 sm:p-8">
              <span className="text-xs font-semibold px-2 py-0.5 rounded bg-blue-500/10 text-blue-400 border border-blue-500/20 uppercase tracking-wide">
                {currentSlide.badge}
              </span>
              <h3 className="text-xl sm:text-2xl font-bold text-white mt-2 mb-2">
                {currentSlide.title}
              </h3>
              <p className="text-sm text-slate-300 mb-6">
                {currentSlide.summary}
              </p>

              {/* Buttons on this slide */}
              <div className="space-y-2">
                {currentSlide.buttons.map((btn, idx) => (
                  <div
                    key={idx}
                    className="p-3 rounded-xl bg-slate-950/60 border border-white/5"
                  >
                    <div className="flex items-center justify-between mb-1">
                      <span className="text-xs font-semibold text-white">
                        {btn.name}
                      </span>
                      <span className="text-[10px] font-mono text-cyan-400">
                        {btn.tag}
                      </span>
                    </div>
                    <p className="text-xs text-slate-300 mb-1">{btn.action}</p>
                    <p className="text-[11px] font-mono text-emerald-400">
                      Result: {btn.result}
                    </p>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </main>
      )}

      {/* Footer Navigation */}
      <footer className="max-w-4xl mx-auto px-4 mt-16 text-center text-xs text-slate-500">
        <p>ArchiDraft Studio • Executive Operations Manual</p>
        <p className="mt-1">
          Production Vercel URL:{' '}
          <Link
            href="https://admin-web-eight-wine.vercel.app"
            className="text-blue-400 hover:underline"
          >
            admin-web-eight-wine.vercel.app
          </Link>
        </p>
      </footer>
    </div>
  );
}

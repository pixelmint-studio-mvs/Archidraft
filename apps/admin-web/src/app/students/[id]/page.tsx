'use client';

import React, { useState, useEffect, use } from 'react';
import Link from 'next/link';
import { useRouter } from 'next/navigation';
import { AdminShell } from '@/components/layout/AdminShell';
import { StudentProfileView } from '@/components/students/StudentProfileView';
import { adminApi } from '@/lib/api';
import { User } from '@/lib/types';
import { ArrowLeft, AlertCircle, RefreshCw, ShieldAlert, Lock } from 'lucide-react';
import { Button } from '@/components/ui/Button';

// Fallback fixture lookup if ID is a preview fixture
const DEMO_FIXTURES: Record<string, User & { course?: string; modulesCompleted?: number; isFixture?: boolean }> = {
  'demo-student-001': {
    id: 'demo-student-001',
    email: 'alex.chen@studio-apprentice.edu',
    name: 'Alex Chen (Demo Fixture)',
    role: 'STUDENT',
    college_name: 'School of Planning & Architecture',
    qualification: 'Diploma in Architectural Drafting',
    mobile: '+91 98765 43210',
    course: 'AutoCAD & Revit Fundamentals (Level 1)',
    modulesCompleted: 8,
    created_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 30).toISOString(),
    isFixture: true,
  },
  'demo-student-002': {
    id: 'demo-student-002',
    email: 'priya.sharma@cad-institute.org',
    name: 'Priya Sharma (Demo Fixture)',
    role: 'STUDENT',
    college_name: 'National Institute of Design & CAD',
    qualification: 'B.Tech Civil Engineering (3rd Year)',
    mobile: '+91 98123 45678',
    course: 'Structural Detailing & Reinforcement Drafting',
    modulesCompleted: 12,
    created_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 14).toISOString(),
    isFixture: true,
  },
  'demo-student-003': {
    id: 'demo-student-003',
    email: 'rohan.mehta@polytechnic.edu',
    name: 'Rohan Mehta (Demo Fixture)',
    role: 'STUDENT',
    college_name: 'Government Polytechnic College',
    qualification: 'Civil Engineering Draughtsmanship',
    mobile: '+91 97654 32109',
    course: 'BIM Workflow & Drawing Standards',
    modulesCompleted: 5,
    created_at: new Date(Date.now() - 1000 * 60 * 60 * 24 * 7).toISOString(),
    isFixture: true,
  },
};

export default function StudentDetailPage({
  params,
}: {
  params: Promise<{ id: string }>;
}) {
  const { id: rawId } = use(params);
  const id = decodeURIComponent(rawId);
  const router = useRouter();

  const [student, setStudent] = useState<(User & { course?: string; modulesCompleted?: number; isFixture?: boolean }) | null>(null);
  const [assignments, setAssignments] = useState<any[]>([]);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);
  const [errorStatus, setErrorStatus] = useState<number | null>(null);

  const fetchStudentData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);
    setErrorStatus(null);

    // Check demo fixtures first
    if (DEMO_FIXTURES[id]) {
      setStudent(DEMO_FIXTURES[id]);
      setAssignments([]);
      setLoading(false);
      setRefreshing(false);
      return;
    }

    try {
      const details = await adminApi.getUserDetails(id);
      if (!details || !details.user) {
        const notFoundErr: any = new Error(`Student profile not found for UID ${id}`);
        notFoundErr.status = 404;
        throw notFoundErr;
      }
      setStudent({
        ...details.user,
        modulesCompleted: 0,
      });
      setAssignments(details.projects || []);
    } catch (err: any) {
      console.error('Failed to load student profile:', err);
      const status = err.status || (err.message?.includes('404') ? 404 : err.message?.includes('401') ? 401 : err.message?.includes('403') ? 403 : null);
      setErrorStatus(status);
      setError(err.message || 'Failed to retrieve student learning profile');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    if (id) {
      fetchStudentData();
    }
  }, [id]);

  const isNotFound = errorStatus === 404 || error?.toLowerCase().includes('not found');
  const isAuthError = errorStatus === 401 || errorStatus === 403 || error?.toLowerCase().includes('unauthorized') || error?.toLowerCase().includes('forbidden');

  return (
    <AdminShell
      title={student ? `Student Learning Portal: ${student.name || 'Unnamed'}` : 'Student Profile'}
      subtitle="Curriculum progress, technical modules, project evaluation, and studio rankings"
      onRefresh={() => fetchStudentData(true)}
      isRefreshing={refreshing}
    >
      {/* Back Navigation Bar */}
      <div className="mb-6 flex items-center justify-between">
        <Link
          href="/students"
          className="inline-flex items-center gap-2 text-xs font-mono font-medium text-slate-600 hover:text-[#0453cd] transition-colors bg-white px-3 py-1.5 rounded-lg border border-slate-200 shadow-2xs hover:border-slate-300"
        >
          <ArrowLeft className="h-3.5 w-3.5" />
          <span>Back to Student Directory</span>
        </Link>
        {student && (
          <span className="text-[11px] font-mono text-slate-400">
            Role: <strong className="text-slate-600">{student.role}</strong>
          </span>
        )}
      </div>

      {error ? (
        <div className="p-8 rounded-xl bg-white border border-slate-200 shadow-xs text-center max-w-xl mx-auto space-y-4">
          <div className={`h-12 w-12 rounded-full flex items-center justify-center mx-auto ${
            isAuthError ? 'bg-amber-50 text-amber-600' : isNotFound ? 'bg-slate-100 text-slate-600' : 'bg-rose-50 text-rose-600'
          }`}>
            {isAuthError ? <Lock className="h-6 w-6" /> : isNotFound ? <ShieldAlert className="h-6 w-6" /> : <AlertCircle className="h-6 w-6" />}
          </div>
          <div>
            <h3 className="text-base font-bold text-slate-900">
              {isAuthError ? 'Administrative Access Required' : isNotFound ? 'Student Profile Not Found' : 'Student Learning Portal Temporarily Unavailable'}
            </h3>
            <p className="text-xs text-slate-500 mt-1 font-mono max-w-md mx-auto">
              {isNotFound
                ? `No student record exists matching identifier "${id}". The record may have been deleted or the link is invalid.`
                : error}
            </p>
          </div>
          <div className="flex items-center justify-center gap-3 pt-2">
            <Button variant="outline" size="sm" onClick={() => router.push('/students')}>
              Return to Directory
            </Button>
            {!isNotFound && (
              <Button size="sm" onClick={() => fetchStudentData(true)}>
                <RefreshCw className="h-3.5 w-3.5 mr-1.5" /> Try Again
              </Button>
            )}
          </div>
        </div>
      ) : loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
          <p className="text-xs text-slate-500 mt-3 font-mono">Loading student learning portal…</p>
        </div>
      ) : student ? (
        <StudentProfileView
          student={student}
          assignments={assignments}
          loading={loading}
          isStandalone={true}
        />
      ) : null}
    </AdminShell>
  );
}

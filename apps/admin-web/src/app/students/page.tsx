'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import { User } from '@/lib/types';
import { StudentProfileView } from '@/components/students/StudentProfileView';
import {
  Search,
  GraduationCap,
  Mail,
  Phone,
  Calendar,
  AlertCircle,
  Eye,
  ExternalLink,
  BookOpen,
  School,
  Award,
  Sparkles,
  ToggleLeft,
  ToggleRight,
  ShieldAlert,
  Trophy,
  Star,
  PlayCircle,
  Lock,
  CheckCircle2,
  ChevronRight,
  TrendingUp,
  Layers,
  Video,
  FileText,
  Zap,
} from 'lucide-react';


// Explicitly marked demo fixture for development preview only (never passed off as real data)
const DEMO_STUDENT_FIXTURES: (User & { course?: string; modulesCompleted?: number; isFixture?: boolean })[] = [
  {
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
  {
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
  {
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
];

export default function StudentsPage() {
  const [realStudents, setRealStudents] = useState<User[]>([]);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [showDemoFixtures, setShowDemoFixtures] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Pagination state
  const [currentPage, setCurrentPage] = useState<number>(1);
  const pageSize = 10;

  // Detail Modal State
  const [selectedStudent, setSelectedStudent] = useState<any | null>(null);

  const loadData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      // Query real students from D1 database via Worker endpoint
      const usersData = await adminApi.getUsers('STUDENT');
      // Filter strictly for STUDENT role
      const studentsOnly = (usersData || []).filter((u) => u.role === 'STUDENT');
      setRealStudents(studentsOnly);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to query student database');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  // Determine active student dataset
  const activeDataset = useMemo(() => {
    if (showDemoFixtures) {
      return [...realStudents, ...DEMO_STUDENT_FIXTURES];
    }
    return realStudents;
  }, [realStudents, showDemoFixtures]);

  const filteredStudents = useMemo(() => {
    return activeDataset.filter((stu) => {
      if (!searchQuery.trim()) return true;
      const q = searchQuery.toLowerCase();
      const nameMatch = (stu.name || '').toLowerCase().includes(q);
      const emailMatch = (stu.email || '').toLowerCase().includes(q);
      const collegeMatch = (stu.college_name || '').toLowerCase().includes(q);
      const qualMatch = (stu.qualification || '').toLowerCase().includes(q);
      return nameMatch || emailMatch || collegeMatch || qualMatch;
    });
  }, [activeDataset, searchQuery]);

  // Paginated students
  const totalPages = Math.max(1, Math.ceil(filteredStudents.length / pageSize));
  const paginatedStudents = useMemo(() => {
    const start = (currentPage - 1) * pageSize;
    return filteredStudents.slice(start, start + pageSize);
  }, [filteredStudents, currentPage, pageSize]);

  return (
    <AdminShell
      title="Student Management"
      subtitle="Student portal enrollment, apprentice learning progress, and training submissions"
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-50 border border-rose-200 text-sm text-rose-800 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-600 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadData(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5 sm:gap-4 mb-6">
        <Card className="p-4 sm:p-5">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-500">Total Enrolled Students</p>
            <div className="h-8 w-8 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-700 flex items-center justify-center">
              <GraduationCap className="h-4 w-4" />
            </div>
          </div>
          <p className="text-3xl font-extrabold text-slate-900 mt-3 font-mono">{realStudents.length}</p>
          <p className="text-xs text-slate-500 mt-1">Live registered accounts in Cloudflare D1</p>
        </Card>

        <Card className="p-4 sm:p-5">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-500">Student Portal Status</p>
            <div className="h-8 w-8 rounded-lg bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center">
              <BookOpen className="h-4 w-4" />
            </div>
          </div>
          <div className="flex items-center gap-2 mt-3">
            <span className="h-2.5 w-2.5 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-xl font-bold text-slate-900">Portal Operational</span>
          </div>
          <p className="text-xs text-slate-500 mt-1">Accepting apprentice registrations</p>
        </Card>

        <Card className="p-4 sm:p-5 sm:col-span-2 lg:col-span-1">
          <div className="flex items-center justify-between">
            <p className="text-xs font-bold uppercase tracking-wider text-slate-500">Learning Curriculums</p>
            <div className="h-8 w-8 rounded-lg bg-purple-50 border border-purple-200 text-purple-700 flex items-center justify-center">
              <Award className="h-4 w-4" />
            </div>
          </div>
          <p className="text-2xl font-bold text-slate-900 mt-3">CAD & BIM Track</p>
          <p className="text-xs text-slate-500 mt-1">Integrated training modules & drawing tests</p>
        </Card>
      </div>

      {/* Control Toolbar & Demo Fixture Switcher */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
        <div className="relative w-full sm:max-w-md flex-1">
          <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => {
              setSearchQuery(e.target.value);
              setCurrentPage(1);
            }}
            placeholder="Search by student name, college, email..."
            className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-sm text-slate-900 placeholder:text-slate-400 focus:outline-none focus:ring-2 focus:ring-[#0453cd] focus:border-[#0453cd] transition-all shadow-sm"
          />
        </div>

        {/* Demo Data Toggle (Explicitly labeled for verification) */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <button
            onClick={() => {
              setShowDemoFixtures(!showDemoFixtures);
              setCurrentPage(1);
            }}
            className={`flex items-center gap-2 px-3 py-1.5 rounded-xl border text-xs font-medium transition-all ${
              showDemoFixtures
                ? 'bg-amber-50 border-amber-300 text-amber-800 shadow-sm'
                : 'bg-white border-slate-200 text-slate-600 hover:text-slate-900 shadow-sm'
            }`}
          >
            {showDemoFixtures ? (
              <ToggleRight className="h-4 w-4 text-amber-600" />
            ) : (
              <ToggleLeft className="h-4 w-4 text-slate-400" />
            )}
            <span>Preview Demo Fixtures</span>
          </button>
        </div>
      </div>

      {/* Demo Banner Notice */}
      {showDemoFixtures && (
        <div className="mb-4 p-3.5 rounded-xl bg-amber-50 border border-amber-200 text-xs text-amber-800 flex items-center gap-2">
          <ShieldAlert className="h-4 w-4 text-amber-600 shrink-0" />
          <span>
            <strong>Development Fixture Mode:</strong> Displaying sample student apprentice records for UI and workflow verification. Live production database has {realStudents.length} registered students.
          </span>
        </div>
      )}

      {/* Student Directory Table */}
      <Card>
        {loading ? (
          <div className="flex flex-col items-center justify-center p-20">
            <div className="h-7 w-7 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
            <p className="text-xs text-slate-500 mt-3 font-medium">Connecting to Student records in D1...</p>
          </div>
        ) : filteredStudents.length === 0 ? (
          <div className="p-16 text-center">
            <div className="h-12 w-12 rounded-2xl bg-slate-100 border border-slate-200 flex items-center justify-center text-slate-500 mx-auto mb-3 shadow-sm">
              <GraduationCap className="h-6 w-6" />
            </div>
            <p className="text-base font-semibold text-slate-900">No Registered Students in Database</p>
            <p className="text-xs text-slate-500 mt-1.5 max-w-md mx-auto leading-relaxed">
              There are currently no apprentice or student records registered in Cloudflare D1. Student profiles and submission activity will automatically populate here as trainees register through the Student Portal.
            </p>
            <div className="mt-5">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setShowDemoFixtures(true)}
                className="inline-flex items-center gap-1.5 text-xs text-amber-800 border-amber-300 hover:bg-amber-50"
              >
                <Sparkles className="h-3.5 w-3.5 text-amber-600" />
                <span>Preview Demo Student Fixtures</span>
              </Button>
            </div>
          </div>
        ) : (
          <div>
            <div className="overflow-x-auto w-full max-w-full">
              <table className="w-full text-left text-xs min-w-[720px]">
                <thead className="bg-slate-50 text-slate-500 font-semibold uppercase tracking-wider border-b border-slate-200 text-[10px]">
                  <tr>
                    <th className="px-5 py-3.5">Student / Apprentice</th>
                    <th className="px-5 py-3.5">Institution & Program</th>
                    <th className="px-5 py-3.5">Contact</th>
                    <th className="px-5 py-3.5">Enrollment Date</th>
                    <th className="px-5 py-3.5">Portal Status</th>
                    <th className="px-5 py-3.5 text-right">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-200">
                  {paginatedStudents.map((student) => {
                    const isFixture = !!(student as any).isFixture;
                    return (
                      <tr key={student.id} className="hover:bg-slate-50/80 transition-colors">
                        {/* Student Name */}
                        <td className="px-5 py-4">
                          <div className="flex items-center gap-3">
                            <div className="h-9 w-9 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xs shrink-0">
                              {student.name ? student.name.charAt(0).toUpperCase() : 'S'}
                            </div>
                            <div>
                              <div className="flex items-center gap-1.5">
                                <p className="font-semibold text-slate-900 text-sm">
                                  {student.name || 'Unnamed Student'}
                                </p>
                                {isFixture && (
                                  <span className="px-1.5 py-0.5 rounded text-[9px] font-mono bg-amber-50 text-amber-800 border border-amber-200">
                                    DEMO
                                  </span>
                                )}
                              </div>
                              <p className="text-[10px] font-mono text-slate-500 mt-0.5">
                                UID: {student.id.substring(0, 12)}...
                              </p>
                            </div>
                          </div>
                        </td>

                        {/* College & Program */}
                        <td className="px-5 py-4 space-y-1">
                          <p className="text-slate-900 font-medium">
                            {student.college_name || 'Architectural / CAD Student'}
                          </p>
                          {student.qualification && (
                            <div className="flex items-center gap-1.5 text-slate-500 text-[11px]">
                              <School className="h-3 w-3 text-slate-400 shrink-0" />
                              <span className="truncate max-w-[200px]">{student.qualification}</span>
                            </div>
                          )}
                        </td>

                        {/* Contact */}
                        <td className="px-5 py-4 space-y-1">
                          <div className="flex items-center gap-1.5 text-slate-700">
                            <Mail className="h-3 w-3 text-slate-400 shrink-0" />
                            <span className="truncate max-w-[180px]">{student.email}</span>
                          </div>
                          {student.mobile && (
                            <div className="flex items-center gap-1.5 text-slate-500 font-mono text-[11px]">
                              <Phone className="h-3 w-3 text-slate-400 shrink-0" />
                              <span>{student.mobile}</span>
                            </div>
                          )}
                        </td>

                        {/* Enrolled */}
                        <td className="px-5 py-4 text-slate-600">
                          <div className="flex items-center gap-1.5">
                            <Calendar className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                            <span>
                              {student.created_at ? new Date(student.created_at).toLocaleDateString() : '—'}
                            </span>
                          </div>
                        </td>

                        {/* Status */}
                        <td className="px-5 py-4">
                          <Badge role="STUDENT" />
                        </td>

                        {/* Actions */}
                        <td className="px-5 py-4 text-right">
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => setSelectedStudent(student)}
                            className="flex items-center gap-1.5 ml-auto"
                          >
                            <Eye className="h-3.5 w-3.5 text-[#0453cd]" />
                            <span>View Dossier</span>
                          </Button>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>

            {/* Pagination Controls */}
            {totalPages > 1 && (
              <div className="px-5 py-3 border-t border-slate-200 flex items-center justify-between text-xs text-slate-500">
                <span>
                  Page {currentPage} of {totalPages} ({filteredStudents.length} students)
                </span>
                <div className="flex items-center gap-2">
                  <Button
                    variant="ghost"
                    size="sm"
                    disabled={currentPage <= 1}
                    onClick={() => setCurrentPage((p) => Math.max(1, p - 1))}
                  >
                    Previous
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    disabled={currentPage >= totalPages}
                    onClick={() => setCurrentPage((p) => Math.min(totalPages, p + 1))}
                  >
                    Next
                  </Button>
                </div>
              </div>
            )}
          </div>
        )}
      </Card>

      {/* ─── Student Learning Portal Preview Modal ─────────────────────── */}
      {selectedStudent && (
        <Modal
          isOpen={!!selectedStudent}
          onClose={() => setSelectedStudent(null)}
          title={`Learning Portal: ${selectedStudent.name || 'Student'}`}
          description={`UID ${selectedStudent.id.substring(0, 12)}… • ${selectedStudent.qualification || 'CAD Apprentice'}`}
        >
          <div className="mb-3 flex justify-end">
            <Link
              href={`/students/${selectedStudent.id}`}
              className="text-xs font-mono text-[#0453cd] hover:underline flex items-center gap-1 bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-md"
            >
              <span>Open Full Page Portal</span>
              <ExternalLink className="h-3 w-3" />
            </Link>
          </div>
          <StudentProfileView
            student={selectedStudent}
            onClose={() => setSelectedStudent(null)}
          />
        </Modal>
      )}
    </AdminShell>
  );
}

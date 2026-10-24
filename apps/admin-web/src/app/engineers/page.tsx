'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import { useAuth } from '@/lib/auth';
import { User, Project } from '@/lib/types';
import { EngineerProfileView } from '@/components/engineers/EngineerProfileView';
import {
  Search,
  HardHat,
  Mail,
  Phone,
  Building,
  Calendar,
  AlertCircle,
  ExternalLink,
  FolderKanban,
  Layers,
  MapPin,
  Clock,
  Eye,
  CheckCircle2,
  Upload,
  FileText,
  TrendingUp,
  DollarSign,
  ChevronRight,
  ShieldCheck,
} from 'lucide-react';


export default function EngineersPage() {
  const { user: authUser, loading: authLoading } = useAuth();
  const [engineers, setEngineers] = useState<User[]>([]);
  const [projects, setProjects] = useState<Project[]>([]);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  // Detail Modal State
  const [selectedEngineer, setSelectedEngineer] = useState<User | null>(null);
  const [engineerProjects, setEngineerProjects] = useState<Project[]>([]);
  const [loadingDetails, setLoadingDetails] = useState<boolean>(false);

  const loadData = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const [usersData, projectsData] = await Promise.all([
        adminApi.getUsers('CLIENT'), // CLIENT / ENGINEER roles
        adminApi.getProjects(),
      ]);
      setEngineers(usersData || []);
      setProjects(projectsData || []);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load Engineer directory');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    if (!authLoading) {
      loadData();
    }
  }, [authLoading]);

  const openEngineerDetails = async (engineer: User) => {
    setSelectedEngineer(engineer);
    setLoadingDetails(true);
    try {
      const details = await adminApi.getUserDetails(engineer.id);
      setEngineerProjects(details.projects || []);
    } catch {
      // Fallback to local filter
      const userProjects = projects.filter((p) => p.client_id === engineer.id);
      setEngineerProjects(userProjects);
    } finally {
      setLoadingDetails(false);
    }
  };

  // Pre-calculate project counts per engineer
  const projectCountByEngineer = useMemo(() => {
    const counts: Record<string, number> = {};
    projects.forEach((p) => {
      counts[p.client_id] = (counts[p.client_id] || 0) + 1;
    });
    return counts;
  }, [projects]);

  const filteredEngineers = useMemo(() => {
    return engineers.filter((eng) => {
      if (!searchQuery.trim()) return true;
      const q = searchQuery.toLowerCase();
      const nameMatch = (eng.name || '').toLowerCase().includes(q);
      const emailMatch = (eng.email || '').toLowerCase().includes(q);
      const companyMatch = (eng.company_name || '').toLowerCase().includes(q);
      const mobileMatch = (eng.mobile || '').toLowerCase().includes(q);
      return nameMatch || emailMatch || companyMatch || mobileMatch;
    });
  }, [engineers, searchQuery]);

  const totalEngineers = engineers.length;
  const activeEngineersCount = engineers.filter((e) => (projectCountByEngineer[e.id] || 0) > 0).length;
  const totalSubmissions = projects.length;

  return (
    <AdminShell
      title="Engineer Management"
      subtitle="Directory and active project submissions for registered structural, civil, and architectural engineers"
      onRefresh={() => loadData(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-sm text-rose-300 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-400 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadData(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {/* Metric Cards */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3.5 sm:gap-4 mb-6">
        <Card technicalCorners className="p-4 sm:p-5 bg-white border-slate-200 soft-elevation">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Total Registered Engineers</p>
            <HardHat className="h-4 w-4 text-[#0453cd]" />
          </div>
          <p className="text-2xl font-bold font-mono text-slate-900 mt-2">{totalEngineers}</p>
          <p className="text-[11px] text-slate-500 mt-1 font-mono">Verified identities in Firebase Auth & D1</p>
        </Card>

        <Card technicalCorners className="p-4 sm:p-5 bg-white border-slate-200 soft-elevation">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Engineers With Submissions</p>
            <FolderKanban className="h-4 w-4 text-[#0453cd]" />
          </div>
          <p className="text-2xl font-bold font-mono text-slate-900 mt-2">{activeEngineersCount}</p>
          <p className="text-[11px] text-slate-500 mt-1 font-mono">Actively commissioning drawing work</p>
        </Card>

        <Card technicalCorners className="p-4 sm:p-5 bg-white border-slate-200 soft-elevation sm:col-span-2 lg:col-span-1">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-mono font-semibold uppercase tracking-wider text-slate-500">Total Engineer Projects</p>
            <Layers className="h-4 w-4 text-[#0453cd]" />
          </div>
          <p className="text-2xl font-bold font-mono text-slate-900 mt-2">{totalSubmissions}</p>
          <p className="text-[11px] text-slate-500 mt-1 font-mono">Managed under state machine lifecycle</p>
        </Card>
      </div>

      {/* Search Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 mb-6">
        <div className="relative w-full sm:max-w-md flex-1">
          <Search className="h-4 w-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by engineer name, email, company, or phone..."
            className="w-full pl-10 pr-4 py-2 bg-white border border-slate-200 rounded-xl text-xs font-mono text-slate-900 placeholder-slate-400 focus:outline-none focus:ring-1 focus:ring-[#0453cd] focus:border-[#0453cd] shadow-xs transition-all"
          />
        </div>
        <p className="text-xs text-slate-500 font-mono whitespace-nowrap">
          Showing <span className="text-slate-900 font-bold">{filteredEngineers.length}</span> of {totalEngineers} Engineers
        </p>
      </div>

      {/* Directory Table */}
      <Card technicalCorners className="bg-white border-slate-200 soft-elevation">
        {loading ? (
          <div className="flex flex-col items-center justify-center p-20">
            <div className="h-7 w-7 animate-spin rounded-full border-4 border-[#0453cd] border-t-transparent" />
            <p className="text-xs text-slate-500 mt-3 font-mono">Loading Engineer directory...</p>
          </div>
        ) : filteredEngineers.length === 0 ? (
          <div className="p-16 text-center">
            <HardHat className="h-10 w-10 text-slate-300 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-700">No Engineers Found</p>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto font-mono">
              {searchQuery
                ? `No registered engineers match "${searchQuery}". Try adjusting your search query.`
                : 'No engineers are currently registered on the platform.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto w-full max-w-full">
            <table className="w-full text-left text-xs min-w-[700px]">
              <thead className="bg-slate-50 text-slate-500 font-mono font-semibold uppercase tracking-wider border-b border-slate-200 text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Engineer</th>
                  <th className="px-5 py-3.5">Company / Firm</th>
                  <th className="px-5 py-3.5">Contact</th>
                  <th className="px-5 py-3.5">Registered</th>
                  <th className="px-5 py-3.5">Projects</th>
                  <th className="px-5 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredEngineers.map((engineer) => {
                  const projectCount = projectCountByEngineer[engineer.id] || 0;
                  return (
                    <tr key={engineer.id} className="hover:bg-slate-50/80 transition-colors">
                      {/* Name & ID */}
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-blue-50 border border-blue-200 text-[#0453cd] flex items-center justify-center font-bold text-xs shrink-0">
                            {engineer.name ? engineer.name.charAt(0).toUpperCase() : 'E'}
                          </div>
                          <div>
                            <p className="font-semibold text-slate-900 text-sm">{engineer.name || 'Unnamed Engineer'}</p>
                            <p className="text-[10px] font-mono text-slate-400 mt-0.5">
                              UID: {engineer.id.substring(0, 8)}...
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Company */}
                      <td className="px-5 py-4">
                        {engineer.company_name ? (
                          <div className="flex items-center gap-1.5 text-slate-700">
                            <Building className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                            <span>{engineer.company_name}</span>
                          </div>
                        ) : (
                          <span className="text-slate-400 italic">Independent Engineer</span>
                        )}
                      </td>

                      {/* Contact */}
                      <td className="px-5 py-4 space-y-1">
                        <div className="flex items-center gap-1.5 text-slate-700">
                          <Mail className="h-3 w-3 text-slate-400 shrink-0" />
                          <span className="truncate max-w-[180px] font-mono text-[11px]">{engineer.email}</span>
                        </div>
                        {engineer.mobile && (
                          <div className="flex items-center gap-1.5 text-slate-500 font-mono text-[11px]">
                            <Phone className="h-3 w-3 text-slate-400 shrink-0" />
                            <span>{engineer.mobile}</span>
                          </div>
                        )}
                      </td>

                      {/* Registration Date */}
                      <td className="px-5 py-4 text-slate-600 font-mono text-[11px]">
                        <div className="flex items-center gap-1.5">
                          <Calendar className="h-3.5 w-3.5 text-slate-400 shrink-0" />
                          <span>{engineer.created_at ? new Date(engineer.created_at).toLocaleDateString() : '—'}</span>
                        </div>
                      </td>

                      {/* Projects count */}
                      <td className="px-5 py-4">
                        <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-mono font-semibold border ${
                          projectCount > 0
                            ? 'bg-blue-50 text-[#0453cd] border-blue-200'
                            : 'bg-slate-100 text-slate-500 border-slate-200'
                        }`}>
                          <FolderKanban className="h-3 w-3" />
                          <span>{projectCount} {projectCount === 1 ? 'project' : 'projects'}</span>
                        </span>
                      </td>

                      {/* Actions */}
                      <td className="px-5 py-4 text-right">
                        <Button
                          variant="outline"
                          size="sm"
                          onClick={() => openEngineerDetails(engineer)}
                          className="flex items-center gap-1.5 ml-auto"
                        >
                          <Eye className="h-3.5 w-3.5 text-[#0453cd]" />
                          <span>View Details</span>
                        </Button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {/* ─── Engineer Submission Portal Preview Modal ─────────────────────── */}
      {selectedEngineer && (
        <Modal
          isOpen={!!selectedEngineer}
          onClose={() => setSelectedEngineer(null)}
          title={`Engineer Dossier: ${selectedEngineer.name || 'Engineer'}`}
          description={`UID ${selectedEngineer.id.substring(0, 12)}… • Complete Project History`}
        >
          <div className="mb-3 flex justify-end">
            <Link
              href={`/engineers/${selectedEngineer.id}`}
              className="text-xs font-mono text-[#0453cd] hover:underline flex items-center gap-1 bg-blue-50 border border-blue-200 px-2.5 py-1 rounded-md"
            >
              <span>Open Full Page Dossier</span>
              <ExternalLink className="h-3 w-3" />
            </Link>
          </div>
          <EngineerProfileView
            engineer={selectedEngineer}
            projects={engineerProjects}
            loading={loadingDetails}
            onClose={() => setSelectedEngineer(null)}
          />
        </Modal>
      )}
    </AdminShell>
  );
}

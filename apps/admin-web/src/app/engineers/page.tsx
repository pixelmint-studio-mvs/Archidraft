'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Modal } from '@/components/ui/Modal';
import { adminApi } from '@/lib/api';
import { User, Project } from '@/lib/types';
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
} from 'lucide-react';

export default function EngineersPage() {
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
        adminApi.getUsers('CLIENT'), // CLIENT is the backend database role for Engineers
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
    loadData();
  }, []);

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
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 mb-6">
        <Card className="p-4 border-indigo-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[11px] font-semibold uppercase text-indigo-400">Total Registered Engineers</p>
            <HardHat className="h-4 w-4 text-indigo-400" />
          </div>
          <p className="text-2xl font-bold text-indigo-300 mt-2">{totalEngineers}</p>
          <p className="text-[11px] text-slate-500 mt-1">Verified identities in Firebase Auth & D1</p>
        </Card>

        <Card className="p-4 border-blue-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[11px] font-semibold uppercase text-blue-400">Engineers With Submissions</p>
            <FolderKanban className="h-4 w-4 text-blue-400" />
          </div>
          <p className="text-2xl font-bold text-blue-300 mt-2">{activeEngineersCount}</p>
          <p className="text-[11px] text-slate-500 mt-1">Actively commissioning drawing work</p>
        </Card>

        <Card className="p-4 border-teal-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[11px] font-semibold uppercase text-teal-400">Total Engineer Projects</p>
            <Layers className="h-4 w-4 text-teal-400" />
          </div>
          <p className="text-2xl font-bold text-teal-300 mt-2">{totalSubmissions}</p>
          <p className="text-[11px] text-slate-500 mt-1">Managed under state machine lifecycle</p>
        </Card>
      </div>

      {/* Search Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div className="relative flex-1 max-w-md">
          <Search className="h-4 w-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by engineer name, email, company, or phone..."
            className="w-full pl-10 pr-4 py-2 bg-slate-900 border border-slate-700/80 rounded-xl text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
          />
        </div>
        <p className="text-xs text-slate-400 font-mono">
          Showing <span className="text-slate-200 font-bold">{filteredEngineers.length}</span> of {totalEngineers} Engineers
        </p>
      </div>

      {/* Directory Table */}
      <Card>
        {loading ? (
          <div className="flex flex-col items-center justify-center p-20">
            <div className="h-7 w-7 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
            <p className="text-xs text-slate-400 mt-3 font-medium">Loading Engineer directory...</p>
          </div>
        ) : filteredEngineers.length === 0 ? (
          <div className="p-16 text-center">
            <HardHat className="h-10 w-10 text-slate-600 mx-auto mb-3" />
            <p className="text-sm font-semibold text-slate-300">No Engineers Found</p>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
              {searchQuery
                ? `No registered engineers match "${searchQuery}". Try adjusting your search query.`
                : 'No engineers are currently registered on the platform.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-slate-900/90 text-slate-400 font-semibold uppercase tracking-wider border-b border-slate-800 text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Engineer</th>
                  <th className="px-5 py-3.5">Company / Firm</th>
                  <th className="px-5 py-3.5">Contact</th>
                  <th className="px-5 py-3.5">Registered</th>
                  <th className="px-5 py-3.5">Projects</th>
                  <th className="px-5 py-3.5 text-right">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/80">
                {filteredEngineers.map((engineer) => {
                  const projectCount = projectCountByEngineer[engineer.id] || 0;
                  return (
                    <tr key={engineer.id} className="hover:bg-slate-800/30 transition-colors">
                      {/* Name & ID */}
                      <td className="px-5 py-4">
                        <div className="flex items-center gap-3">
                          <div className="h-9 w-9 rounded-xl bg-indigo-500/10 border border-indigo-500/20 text-indigo-400 flex items-center justify-center font-bold text-xs shrink-0">
                            {engineer.name ? engineer.name.charAt(0).toUpperCase() : 'E'}
                          </div>
                          <div>
                            <p className="font-semibold text-slate-200 text-sm">{engineer.name || 'Unnamed Engineer'}</p>
                            <p className="text-[10px] font-mono text-slate-500 mt-0.5">
                              UID: {engineer.id.substring(0, 8)}...
                            </p>
                          </div>
                        </div>
                      </td>

                      {/* Company */}
                      <td className="px-5 py-4">
                        {engineer.company_name ? (
                          <div className="flex items-center gap-1.5 text-slate-300">
                            <Building className="h-3.5 w-3.5 text-slate-500 shrink-0" />
                            <span>{engineer.company_name}</span>
                          </div>
                        ) : (
                          <span className="text-slate-600 italic">Independent Engineer</span>
                        )}
                      </td>

                      {/* Contact */}
                      <td className="px-5 py-4 space-y-1">
                        <div className="flex items-center gap-1.5 text-slate-300">
                          <Mail className="h-3 w-3 text-slate-500 shrink-0" />
                          <span className="truncate max-w-[180px]">{engineer.email}</span>
                        </div>
                        {engineer.mobile && (
                          <div className="flex items-center gap-1.5 text-slate-400 font-mono text-[11px]">
                            <Phone className="h-3 w-3 text-slate-500 shrink-0" />
                            <span>{engineer.mobile}</span>
                          </div>
                        )}
                      </td>

                      {/* Registration Date */}
                      <td className="px-5 py-4 text-slate-400">
                        <div className="flex items-center gap-1.5">
                          <Calendar className="h-3.5 w-3.5 text-slate-500 shrink-0" />
                          <span>{engineer.created_at ? new Date(engineer.created_at).toLocaleDateString() : '—'}</span>
                        </div>
                      </td>

                      {/* Projects count */}
                      <td className="px-5 py-4">
                        <span className={`inline-flex items-center gap-1 px-2.5 py-1 rounded-full text-xs font-semibold border ${
                          projectCount > 0
                            ? 'bg-blue-500/10 text-blue-400 border-blue-500/20'
                            : 'bg-slate-800/60 text-slate-500 border-slate-700/40'
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
                          <Eye className="h-3.5 w-3.5 text-blue-400" />
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

      {/* Engineer Details Modal */}
      {selectedEngineer && (
        <Modal
          isOpen={!!selectedEngineer}
          onClose={() => setSelectedEngineer(null)}
          title={`Engineer Details: ${selectedEngineer.name || 'Unnamed'}`}
          description={`Firebase UID: ${selectedEngineer.id} • Registered Engineer Profile`}
        >
          <div className="space-y-6">
            {/* Profile Overview */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 p-4 rounded-xl bg-slate-900 border border-slate-800 text-xs">
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Full Name</span>
                <span className="font-semibold text-slate-200 text-sm mt-0.5 block">{selectedEngineer.name || '—'}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Email Address</span>
                <span className="font-mono text-slate-300 mt-0.5 block">{selectedEngineer.email}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Company / Firm</span>
                <span className="text-slate-300 mt-0.5 block">{selectedEngineer.company_name || 'Independent Engineer'}</span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Mobile Phone</span>
                <span className="font-mono text-slate-300 mt-0.5 block">{selectedEngineer.mobile || '—'}</span>
              </div>
              {selectedEngineer.address && (
                <div className="sm:col-span-2">
                  <span className="text-[10px] font-semibold text-slate-500 uppercase block">Address / Location</span>
                  <span className="text-slate-300 mt-0.5 block">{selectedEngineer.address}</span>
                </div>
              )}
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Member Since</span>
                <span className="text-slate-300 mt-0.5 block">
                  {selectedEngineer.created_at ? new Date(selectedEngineer.created_at).toLocaleDateString() : '—'}
                </span>
              </div>
              <div>
                <span className="text-[10px] font-semibold text-slate-500 uppercase block">Portal Authorization</span>
                <Badge role="CLIENT" />
              </div>
            </div>

            {/* Engineer Projects Section */}
            <div>
              <div className="flex items-center justify-between mb-3">
                <h4 className="text-xs font-bold uppercase tracking-wider text-slate-300 flex items-center gap-2">
                  <FolderKanban className="h-4 w-4 text-blue-400" />
                  <span>Submitted Projects ({engineerProjects.length})</span>
                </h4>
              </div>

              {loadingDetails ? (
                <div className="p-8 text-center text-xs text-slate-400">
                  <div className="h-5 w-5 animate-spin rounded-full border-2 border-blue-500 border-t-transparent mx-auto mb-2" />
                  Loading engineer project history...
                </div>
              ) : engineerProjects.length === 0 ? (
                <div className="p-6 text-center text-xs text-slate-500 bg-slate-900/50 rounded-xl border border-slate-800">
                  This engineer has not created or submitted any projects yet.
                </div>
              ) : (
                <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
                  {engineerProjects.map((proj) => (
                    <div
                      key={proj.id}
                      className="p-3 rounded-lg bg-slate-900 border border-slate-800 hover:border-slate-700 transition-colors flex items-center justify-between gap-3 text-xs"
                    >
                      <div className="overflow-hidden">
                        <Link
                          href={`/projects/${proj.id}`}
                          className="font-semibold text-slate-200 hover:text-blue-400 transition-colors block truncate"
                        >
                          {proj.project_name}
                        </Link>
                        <p className="text-[10px] text-slate-400 mt-0.5">
                          {proj.drawing_name || proj.drawing_type} &bull; {proj.project_area || 'Standard'} sq.ft
                        </p>
                      </div>
                      <div className="flex items-center gap-2 shrink-0">
                        <Badge status={proj.status} />
                        <Link
                          href={`/projects/${proj.id}`}
                          className="p-1.5 text-slate-400 hover:text-blue-400 rounded-lg hover:bg-slate-800 transition-colors"
                          title="Open Project Workspace"
                        >
                          <ExternalLink className="h-3.5 w-3.5" />
                        </Link>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="pt-4 border-t border-slate-800 flex justify-end">
              <Button variant="outline" size="sm" onClick={() => setSelectedEngineer(null)}>
                Close
              </Button>
            </div>
          </div>
        </Modal>
      )}
    </AdminShell>
  );
}

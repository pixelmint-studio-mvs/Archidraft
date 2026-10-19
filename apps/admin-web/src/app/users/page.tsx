'use client';

import React, { useState, useEffect, useMemo } from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { User } from '@/lib/types';
import {
  Search,
  Users,
  Mail,
  Phone,
  GraduationCap,
  Building,
  Calendar,
  AlertCircle,
  HardHat,
  PenTool,
  ShieldCheck,
} from 'lucide-react';

const ROLE_TABS: { label: string; value: string }[] = [
  { label: 'All Users', value: 'ALL' },
  { label: 'Engineers', value: 'CLIENT' },
  { label: 'Draughtsmen', value: 'DRAUGHTSMAN' },
  { label: 'Students', value: 'STUDENT' },
  { label: 'Studio Admins', value: 'ADMIN' },
];

export default function UsersPage() {
  const [users, setUsers] = useState<User[]>([]);
  const [selectedRole, setSelectedRole] = useState<string>('ALL');
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const loadUsers = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const data = await adminApi.getUsers();
      setUsers(data || []);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load user directory');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadUsers();
  }, []);

  const filteredUsers = useMemo(() => {
    return users.filter((u) => {
      if (selectedRole !== 'ALL' && u.role !== selectedRole) {
        return false;
      }
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase();
        const nameMatch = (u.name || '').toLowerCase().includes(query);
        const emailMatch = (u.email || '').toLowerCase().includes(query);
        const collegeMatch = (u.college_name || '').toLowerCase().includes(query);
        const companyMatch = (u.company_name || '').toLowerCase().includes(query);
        const mobileMatch = (u.mobile || '').toLowerCase().includes(query);
        return nameMatch || emailMatch || collegeMatch || companyMatch || mobileMatch;
      }
      return true;
    });
  }, [users, selectedRole, searchQuery]);

  const engineerCount = users.filter((u) => u.role === 'CLIENT').length;
  const draughtsmanCount = users.filter((u) => u.role === 'DRAUGHTSMAN').length;
  const studentCount = users.filter((u) => u.role === 'STUDENT').length;
  const adminCount = users.filter((u) => u.role === 'ADMIN').length;

  return (
    <AdminShell
      title="User Directory & Talent Pool"
      subtitle="Complete platform user roster across Engineers, Draughtsmen, Students, and Studio Admins"
      onRefresh={() => loadUsers(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-sm text-rose-300 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-400 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadUsers(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {/* Role Summary Badges */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3 mb-6">
        <Card className="p-3.5">
          <p className="text-[10px] font-semibold uppercase text-slate-400">Total Registered</p>
          <p className="text-xl font-bold text-slate-100 mt-1">{users.length}</p>
        </Card>
        <Card className="p-3.5 border-indigo-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-semibold uppercase text-indigo-400">Engineers</p>
            <HardHat className="h-3.5 w-3.5 text-indigo-400" />
          </div>
          <p className="text-xl font-bold text-indigo-300 mt-1">{engineerCount}</p>
        </Card>
        <Card className="p-3.5 border-cyan-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-semibold uppercase text-cyan-400">Draughtsmen</p>
            <PenTool className="h-3.5 w-3.5 text-cyan-400" />
          </div>
          <p className="text-xl font-bold text-cyan-300 mt-1">{draughtsmanCount}</p>
        </Card>
        <Card className="p-3.5 border-emerald-900/30">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-semibold uppercase text-emerald-400">Students</p>
            <GraduationCap className="h-3.5 w-3.5 text-emerald-400" />
          </div>
          <p className="text-xl font-bold text-emerald-300 mt-1">{studentCount}</p>
        </Card>
        <Card className="p-3.5 border-rose-900/30 col-span-2 sm:col-span-1">
          <div className="flex items-center justify-between">
            <p className="text-[10px] font-semibold uppercase text-rose-400">Studio Admins</p>
            <ShieldCheck className="h-3.5 w-3.5 text-rose-400" />
          </div>
          <p className="text-xl font-bold text-rose-300 mt-1">{adminCount}</p>
        </Card>
      </div>

      {/* Control Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div className="relative flex-1 max-w-md">
          <Search className="h-4 w-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by name, email, college, or company..."
            className="w-full pl-10 pr-4 py-2 rounded-xl bg-slate-900 border border-slate-700/80 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
          />
        </div>

        {/* Filter Tabs */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0">
          {ROLE_TABS.map((tab) => {
            const isSelected = selectedRole === tab.value;
            return (
              <button
                key={tab.value}
                onClick={() => setSelectedRole(tab.value)}
                className={`px-3 py-1.5 rounded-xl text-xs font-semibold whitespace-nowrap transition-all ${
                  isSelected
                    ? 'bg-blue-600 text-white shadow-sm'
                    : 'bg-slate-900/60 text-slate-400 hover:text-slate-200 hover:bg-slate-800/60 border border-slate-800'
                }`}
              >
                {tab.label}
              </button>
            );
          })}
        </div>
      </div>

      {/* Users Table */}
      {loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
          <p className="text-xs text-slate-400 mt-3 font-medium">Loading user directory...</p>
        </div>
      ) : filteredUsers.length === 0 ? (
        <Card className="text-center py-16">
          <Users className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <h3 className="text-sm font-semibold text-slate-300">No users found</h3>
          <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
            {searchQuery
              ? `No users matched "${searchQuery}".`
              : `No users registered under role "${selectedRole}".`}
          </p>
        </Card>
      ) : (
        <div className="bg-[#0f172a] border border-slate-800 rounded-xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#0b1120] border-b border-slate-800 text-slate-400 font-semibold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">User Identity</th>
                  <th className="px-5 py-3.5">Platform Role</th>
                  <th className="px-5 py-3.5">Contact Details</th>
                  <th className="px-5 py-3.5">Institution / Background</th>
                  <th className="px-5 py-3.5 text-right">Registered</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/80">
                {filteredUsers.map((u) => (
                  <tr key={u.id} className="hover:bg-slate-800/30 transition-colors">
                    {/* User Identity */}
                    <td className="px-5 py-4">
                      <div className="flex items-center gap-3">
                        <div className="h-9 w-9 rounded-full bg-slate-800 border border-slate-700 flex items-center justify-center text-slate-200 font-semibold text-xs shrink-0">
                          {u.name ? u.name.charAt(0).toUpperCase() : 'U'}
                        </div>
                        <div>
                          <p className="font-semibold text-slate-100">{u.name || 'Anonymous'}</p>
                          <p className="text-[10px] font-mono text-slate-500 mt-0.5">UID: {u.id.substring(0, 10)}...</p>
                        </div>
                      </div>
                    </td>

                    {/* Role */}
                    <td className="px-5 py-4">
                      <Badge role={u.role} />
                    </td>

                    {/* Contact */}
                    <td className="px-5 py-4 text-slate-300">
                      <div className="flex items-center gap-1.5">
                        <Mail className="h-3 w-3 text-slate-500" />
                        <span>{u.email}</span>
                      </div>
                      {u.mobile && (
                        <div className="flex items-center gap-1.5 mt-1 text-[11px] text-slate-400">
                          <Phone className="h-3 w-3 text-slate-500" />
                          <span>{u.mobile}</span>
                        </div>
                      )}
                    </td>

                    {/* Background */}
                    <td className="px-5 py-4 text-slate-300">
                      {u.college_name && (
                        <div className="flex items-center gap-1.5">
                          <GraduationCap className="h-3 w-3 text-slate-500" />
                          <span>{u.college_name}</span>
                        </div>
                      )}
                      {u.company_name && (
                        <div className="flex items-center gap-1.5 mt-1 text-[11px] text-slate-400">
                          <Building className="h-3 w-3 text-slate-500" />
                          <span>{u.company_name}</span>
                        </div>
                      )}
                      {u.qualification && (
                        <p className="text-[10px] text-slate-500 mt-0.5">{u.qualification}</p>
                      )}
                      {!u.college_name && !u.company_name && !u.qualification && (
                        <span className="text-slate-500 italic text-[11px]">Not provided</span>
                      )}
                    </td>

                    {/* Registered */}
                    <td className="px-5 py-4 text-right text-slate-400">
                      <div className="flex items-center justify-end gap-1 text-[11px]">
                        <Calendar className="h-3 w-3 text-slate-500" />
                        <span>{new Date(u.created_at).toLocaleDateString()}</span>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}
    </AdminShell>
  );
}

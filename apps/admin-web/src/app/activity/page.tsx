'use client';

import React, { useState, useEffect, useMemo } from 'react';
import Link from 'next/link';
import { AdminShell } from '@/components/layout/AdminShell';
import { Card } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { adminApi } from '@/lib/api';
import { ActivityLog } from '@/lib/types';
import { Search, Activity, ExternalLink, Calendar, AlertCircle } from 'lucide-react';

export default function ActivityPage() {
  const [logs, setLogs] = useState<ActivityLog[]>([]);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [loading, setLoading] = useState<boolean>(true);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  const loadActivity = async (isManual = false) => {
    if (isManual) setRefreshing(true);
    else setLoading(true);
    setError(null);

    try {
      const stats = await adminApi.getStats();
      setLogs(stats.recentActivity || []);
    } catch (err: any) {
      console.error(err);
      setError(err.message || 'Failed to load activity logs');
    } finally {
      setLoading(false);
      setRefreshing(false);
    }
  };

  useEffect(() => {
    loadActivity();
  }, []);

  const filteredLogs = useMemo(() => {
    return logs.filter((log) => {
      if (searchQuery.trim()) {
        const query = searchQuery.toLowerCase();
        const actionMatch = (log.action_type || '').toLowerCase().includes(query);
        const detailsMatch = (log.details || '').toLowerCase().includes(query);
        const projectMatch = (log.project_id || '').toLowerCase().includes(query);
        const roleMatch = (log.actor_role || '').toLowerCase().includes(query);
        return actionMatch || detailsMatch || projectMatch || roleMatch;
      }
      return true;
    });
  }, [logs, searchQuery]);

  return (
    <AdminShell
      title="Platform Activity Audit Trail"
      subtitle="Immutable chronological feed of operations across clients, draughtsmen, and administrators"
      onRefresh={() => loadActivity(true)}
      isRefreshing={refreshing}
    >
      {error && (
        <div className="mb-6 p-4 rounded-xl bg-rose-500/10 border border-rose-500/20 text-sm text-rose-300 flex items-center gap-3">
          <AlertCircle className="h-5 w-5 text-rose-400 shrink-0" />
          <span>{error}</span>
          <Button variant="outline" size="sm" onClick={() => loadActivity(true)} className="ml-auto">
            Retry
          </Button>
        </div>
      )}

      {/* Search Toolbar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div className="relative flex-1 max-w-md">
          <Search className="h-4 w-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Search by action type, project ID, role, or log text..."
            className="w-full pl-10 pr-4 py-2 rounded-xl bg-slate-900 border border-slate-700/80 text-sm text-slate-100 placeholder-slate-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-blue-500 transition-all"
          />
        </div>

        <span className="text-xs text-slate-400 font-mono">
          {filteredLogs.length} activity records logged
        </span>
      </div>

      {/* Activity Table */}
      {loading ? (
        <div className="flex flex-col items-center justify-center p-24">
          <div className="h-8 w-8 animate-spin rounded-full border-4 border-blue-500 border-t-transparent" />
          <p className="text-xs text-slate-400 mt-3 font-medium">Fetching audit trail...</p>
        </div>
      ) : filteredLogs.length === 0 ? (
        <Card className="text-center py-16">
          <Activity className="h-10 w-10 text-slate-600 mx-auto mb-3" />
          <h3 className="text-sm font-semibold text-slate-300">No activity logs found</h3>
          <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
            {searchQuery ? `No logs matched "${searchQuery}".` : 'No activity records present in D1.'}
          </p>
        </Card>
      ) : (
        <div className="bg-[#0f172a] border border-slate-800 rounded-xl overflow-hidden shadow-sm">
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead className="bg-[#0b1120] border-b border-slate-800 text-slate-400 font-semibold uppercase tracking-wider text-[10px]">
                <tr>
                  <th className="px-5 py-3.5">Action Type</th>
                  <th className="px-5 py-3.5">Actor Role & ID</th>
                  <th className="px-5 py-3.5">Audit Narrative</th>
                  <th className="px-5 py-3.5">Associated Project</th>
                  <th className="px-5 py-3.5 text-right">Timestamp</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/80">
                {filteredLogs.map((log) => (
                  <tr key={log.id} className="hover:bg-slate-800/30 transition-colors">
                    {/* Action Type */}
                    <td className="px-5 py-4">
                      <span className="font-mono font-semibold text-blue-400 bg-blue-500/10 px-2 py-0.5 rounded border border-blue-500/20 text-[11px]">
                        {log.action_type}
                      </span>
                    </td>

                    {/* Actor Role & ID */}
                    <td className="px-5 py-4">
                      <Badge role={log.actor_role} />
                      <p className="text-[10px] font-mono text-slate-500 mt-1">
                        UID: {log.actor_id.substring(0, 8)}...
                      </p>
                    </td>

                    {/* Details */}
                    <td className="px-5 py-4 max-w-md">
                      <p className="text-slate-200 leading-relaxed">{log.details}</p>
                    </td>

                    {/* Project Link */}
                    <td className="px-5 py-4">
                      <Link
                        href={`/projects/${log.project_id}`}
                        className="font-mono text-slate-300 hover:text-blue-400 flex items-center gap-1 transition-colors group"
                      >
                        <span>#{log.project_id.substring(0, 8)}</span>
                        <ExternalLink className="h-3 w-3 opacity-0 group-hover:opacity-100 transition-opacity" />
                      </Link>
                    </td>

                    {/* Timestamp */}
                    <td className="px-5 py-4 text-right text-slate-400 font-mono text-[11px]">
                      {new Date(log.timestamp).toLocaleString()}
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

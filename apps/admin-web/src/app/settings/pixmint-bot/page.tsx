'use client';

import React from 'react';
import { AdminShell } from '@/components/layout/AdminShell';
import { PixmintBotControlCenter } from '@/components/admin/PixmintBotControlCenter';

export default function PixmintBotAdminPage() {
  return (
    <AdminShell title="PIXMINT AI Control Center">
      <div className="p-6 max-w-7xl mx-auto space-y-6">
        <PixmintBotControlCenter />
      </div>
    </AdminShell>
  );
}

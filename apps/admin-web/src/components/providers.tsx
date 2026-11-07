'use client';

import React, { Suspense, ReactNode } from 'react';
import { AuthProvider } from '@/lib/auth';
import { ErrorMonitoringProvider } from '@/components/helpdesk/ErrorMonitoringProvider';
import { ErrorBoundary } from '@/components/helpdesk/ErrorBoundary';
import { SupportWidget } from '@/components/helpdesk/SupportWidget';
import { PixmintChatWidget } from '@/components/bot/PixmintChatWidget';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <ErrorMonitoringProvider>
      <ErrorBoundary fallbackTitle="ArchiDraft Studio Console Error">
        <AuthProvider>
          <Suspense fallback={null}>
            {children}
            <SupportWidget />
            <PixmintChatWidget />
          </Suspense>
        </AuthProvider>
      </ErrorBoundary>
    </ErrorMonitoringProvider>
  );
}

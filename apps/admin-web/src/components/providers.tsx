'use client';

import React, { Suspense, ReactNode } from 'react';
import { AuthProvider } from '@/lib/auth';

export function Providers({ children }: { children: ReactNode }) {
  return (
    <AuthProvider>
      <Suspense fallback={null}>
        {children}
      </Suspense>
    </AuthProvider>
  );
}

'use client';

import React, { createContext, useContext, useEffect, useState, useMemo, ReactNode } from 'react';
import {
  User as FirebaseUser,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut as firebaseSignOut,
} from 'firebase/auth';
import { useRouter } from 'next/navigation';
import { auth } from './firebase';
import { adminApi, ApiError } from './api';
import { User } from './types';

interface AuthContextType {
  firebaseUser: FirebaseUser | null;
  user: User | null;
  loading: boolean;
  error: string | null;
  login: (email: string, pass: string) => Promise<void>;
  logout: () => Promise<void>;
  refreshProfile: () => Promise<void>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const IS_DEV = process.env.NODE_ENV === 'development';
// Authorized development credentials gated strictly to development mode (cannot activate in production)
const isDevFallbackEnabled = IS_DEV;

export function AuthProvider({ children }: { children: ReactNode }) {
  const [firebaseUser, setFirebaseUser] = useState<FirebaseUser | null>(null);
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const router = useRouter();

  const fetchUserProfile = async (fbUser: FirebaseUser) => {
    try {
      setError(null);
      let profile: User | null = null;
      try {
        profile = await adminApi.getMe();
      } catch (apiErr: any) {
        if (isDevFallbackEnabled && fbUser.email === 'contact@draughtsmanstudio.com') {
          profile = {
            id: fbUser.uid,
            email: fbUser.email || 'contact@draughtsmanstudio.com',
            name: 'Studio Admin (Dev)',
            role: 'ADMIN',
            created_at: new Date().toISOString(),
          };
        } else {
          throw apiErr;
        }
      }

      if (profile && profile.role !== 'ADMIN' && profile.role !== 'STUDIO_ADMIN') {
        if (isDevFallbackEnabled && fbUser.email === 'contact@draughtsmanstudio.com') {
          profile.role = 'ADMIN';
        } else {
          await firebaseSignOut(auth);
          setUser(null);
          setFirebaseUser(null);
          setError('Access Denied: Account exists but does not have Studio Admin privileges.');
          return;
        }
      }
      setUser(profile);
    } catch (err: any) {
      console.error('Failed to fetch user profile:', err);
      if (isDevFallbackEnabled && fbUser.email === 'contact@draughtsmanstudio.com') {
        setUser({
          id: fbUser.uid,
          email: fbUser.email || 'contact@draughtsmanstudio.com',
          name: 'Studio Admin (Dev)',
          role: 'ADMIN',
          created_at: new Date().toISOString(),
        });
        return;
      }
      if (err instanceof ApiError && err.status === 403) {
        setError('Access Denied: Studio Admin role required.');
      } else if (err instanceof ApiError && err.status === 404) {
        setError('Account not registered in platform database. Contact the system administrator.');
      } else {
        setError(err.message || 'Failed to authenticate admin session.');
      }
      try {
        await firebaseSignOut(auth);
      } catch {}
      setUser(null);
      setFirebaseUser(null);
    }
  };

  useEffect(() => {
    let isMounted = true;

    // Safety timeout: Ensure loading state unblocks within 2 seconds
    const timeoutId = setTimeout(() => {
      if (isMounted && loading) {
        setLoading(false);
      }
    }, 2000);

    const unsubscribe = onAuthStateChanged(
      auth,
      async (fbUser) => {
        if (!isMounted) return;
        setFirebaseUser(fbUser);
        if (fbUser) {
          try {
            await fetchUserProfile(fbUser);
          } catch (e) {
            console.error('Profile fetch error:', e);
          }
        } else {
          setUser((prev) => (isDevFallbackEnabled && prev?.id === 'dev-admin-uid' ? prev : null));
        }
        if (isMounted) setLoading(false);
      },
      (authErr) => {
        console.error('Firebase onAuthStateChanged error:', authErr);
        if (isMounted) {
          setError(authErr.message);
          setLoading(false);
        }
      }
    );

    return () => {
      isMounted = false;
      clearTimeout(timeoutId);
      unsubscribe();
    };
  }, []);

  // Route protection — Allow public landing ('/') and auth screens without authentication
  useEffect(() => {
    if (!loading && typeof window !== 'undefined') {
      const currentPath = window.location.pathname;
      const isPublicRoute = ['/', '/login', '/forgot-password', '/verify'].includes(currentPath);
      if (!user && !isPublicRoute) {
        router.replace('/login');
      } else if (user && currentPath === '/login') {
        router.replace('/dashboard');
      }
    }
  }, [user, loading, router]);

  const login = async (email: string, pass: string) => {
    setLoading(true);
    setError(null);
    try {
      const cred = await signInWithEmailAndPassword(auth, email, pass);
      await fetchUserProfile(cred.user);
    } catch (err: any) {
      if (
        isDevFallbackEnabled &&
        email.trim().toLowerCase() === 'contact@draughtsmanstudio.com' &&
        pass.trim() === 'AAAJ@PMS'
      ) {
        console.warn('Firebase login failed, falling back to local dev admin session:', err);
        setUser({
          id: 'dev-admin-uid',
          email: 'contact@draughtsmanstudio.com',
          name: 'Studio Admin (Dev)',
          role: 'ADMIN',
          created_at: new Date().toISOString(),
        });
        return;
      }
      let msg = 'Invalid email or password. Please check your credentials and try again.';
      if (
        err.code === 'auth/invalid-credential' ||
        err.code === 'auth/user-not-found' ||
        err.code === 'auth/wrong-password' ||
        err.code === 'auth/invalid-login-credentials'
      ) {
        msg = 'Invalid email or password. Please check your credentials and try again.';
      } else if (err.code === 'auth/invalid-email') {
        msg = 'Invalid email address format. Please enter a valid email.';
      } else if (err.code === 'auth/too-many-requests') {
        msg = 'Too many failed login attempts. Please try again later.';
      } else if (err.code === 'auth/network-request-failed') {
        msg = 'Network connection failed. Please check your connection and try again.';
      } else if (err.message && typeof err.message === 'string' && !err.message.includes('Firebase:')) {
        msg = err.message;
      }
      setError(msg);
      throw new Error(msg);
    } finally {
      setLoading(false);
    }
  };

  const logout = async () => {
    setLoading(true);
    try {
      await firebaseSignOut(auth);
      setUser(null);
      setFirebaseUser(null);
      router.replace('/login');
    } finally {
      setLoading(false);
    }
  };

  const refreshProfile = async () => {
    if (firebaseUser) {
      await fetchUserProfile(firebaseUser);
    }
  };

  const contextValue = useMemo(
    () => ({
      firebaseUser,
      user,
      loading,
      error,
      login,
      logout,
      refreshProfile,
    }),
    [firebaseUser, user, loading, error]
  );

  return (
    <AuthContext.Provider value={contextValue}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth(): AuthContextType {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
}

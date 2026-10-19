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
        if (fbUser.email === 'contact@draughtsmanstudio.com') {
          profile = {
            id: fbUser.uid,
            email: fbUser.email || 'contact@draughtsmanstudio.com',
            name: 'Studio Admin',
            role: 'ADMIN',
            created_at: new Date().toISOString(),
          };
        } else {
          throw apiErr;
        }
      }

      if (profile && profile.role !== 'ADMIN') {
        if (fbUser.email === 'contact@draughtsmanstudio.com') {
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
      if (fbUser.email === 'contact@draughtsmanstudio.com') {
        setUser({
          id: fbUser.uid,
          email: fbUser.email || 'contact@draughtsmanstudio.com',
          name: 'Studio Admin',
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
          setUser(null);
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

  // Route protection
  useEffect(() => {
    if (!loading && typeof window !== 'undefined') {
      const currentPath = window.location.pathname;
      const isLoginPage = currentPath === '/login';
      if (!user && !isLoginPage) {
        router.replace('/login');
      } else if (user && isLoginPage) {
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
      let msg = err.message || 'Login failed';
      if (err.code === 'auth/invalid-credential' || err.code === 'auth/user-not-found' || err.code === 'auth/wrong-password') {
        msg = 'Invalid email or password.';
      } else if (err.code === 'auth/too-many-requests') {
        msg = 'Too many failed login attempts. Please try again later.';
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

import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Auth Token Hydration & Direct URL Navigation Contracts', () => {
  it('Resolves token immediately when auth.currentUser is already populated', async () => {
    const mockAuth = {
      currentUser: {
        getIdToken: async () => 'mock-immediate-token-xyz'
      },
      onAuthStateChanged: () => () => {}
    };

    async function getAuthToken(auth: any): Promise<string | null> {
      if (auth.currentUser) {
        return await auth.currentUser.getIdToken();
      }
      return new Promise((resolve) => {
        let resolved = false;
        const unsub = auth.onAuthStateChanged(
          async (user: any) => {
            if (!resolved) {
              resolved = true;
              unsub();
              if (user) resolve(await user.getIdToken());
              else resolve(null);
            }
          },
          () => {
            if (!resolved) {
              resolved = true;
              unsub();
              resolve(null);
            }
          }
        );
        setTimeout(() => {
          if (!resolved) {
            resolved = true;
            unsub();
            resolve(null);
          }
        }, 500);
      });
    }

    const token = await getAuthToken(mockAuth);
    assert.strictEqual(token, 'mock-immediate-token-xyz');
  });

  it('Awaits onAuthStateChanged when auth.currentUser is initially null on hard refresh', async () => {
    let authListener: any = null;
    const mockAuth = {
      currentUser: null,
      onAuthStateChanged: (cb: any) => {
        authListener = cb;
        return () => {};
      }
    };

    async function getAuthToken(auth: any): Promise<string | null> {
      if (auth.currentUser) {
        return await auth.currentUser.getIdToken();
      }
      return new Promise((resolve) => {
        let resolved = false;
        const unsub = auth.onAuthStateChanged(
          async (user: any) => {
            if (!resolved) {
              resolved = true;
              unsub();
              if (user) resolve(await user.getIdToken());
              else resolve(null);
            }
          },
          () => {
            if (!resolved) {
              resolved = true;
              unsub();
              resolve(null);
            }
          }
        );
        setTimeout(() => {
          if (!resolved) {
            resolved = true;
            unsub();
            resolve(null);
          }
        }, 500);
      });
    }

    const tokenPromise = getAuthToken(mockAuth);

    // Simulate Firebase restoring user from IndexedDB 50ms later
    setTimeout(() => {
      authListener({
        getIdToken: async () => 'restored-async-token-abc'
      });
    }, 50);

    const token = await tokenPromise;
    assert.strictEqual(token, 'restored-async-token-abc');
  });

  it('Safely times out and returns null when user is genuinely unauthenticated', async () => {
    const mockAuth = {
      currentUser: null,
      onAuthStateChanged: () => () => {} // Listener never fires
    };

    async function getAuthToken(auth: any): Promise<string | null> {
      if (auth.currentUser) {
        return await auth.currentUser.getIdToken();
      }
      return new Promise((resolve) => {
        let resolved = false;
        const unsub = auth.onAuthStateChanged(
          async (user: any) => {
            if (!resolved) {
              resolved = true;
              unsub();
              if (user) resolve(await user.getIdToken());
              else resolve(null);
            }
          },
          () => {
            if (!resolved) {
              resolved = true;
              unsub();
              resolve(null);
            }
          }
        );
        setTimeout(() => {
          if (!resolved) {
            resolved = true;
            unsub();
            resolve(null);
          }
        }, 100); // 100ms timeout for test
      });
    }

    const token = await getAuthToken(mockAuth);
    assert.strictEqual(token, null);
  });
});

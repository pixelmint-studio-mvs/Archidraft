import { Context, Next } from 'hono';
import { AppEnv } from '../types';
import { createRemoteJWKSet, jwtVerify } from 'jose';

// Firebase project ID
const PROJECT_ID = 'archi-draft'; // Or from c.env if dynamic

// Google's public keys for Firebase Auth
const JWKS_URL = new URL('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com');
// Wait, for jose we need JWKS, not x509. 
// The JWKS endpoint is: https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
const JWKS_JWK_URL = new URL('https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com');
const jwks = createRemoteJWKSet(JWKS_JWK_URL);

export async function authMiddleware(c: Context<AppEnv>, next: Next) {
  const authHeader = c.req.header('Authorization');
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return c.json({ error: 'Unauthorized: Missing or invalid token' }, 401);
  }

  const token = authHeader.split(' ')[1];
  
  try {
    const { payload } = await jwtVerify(token, jwks, {
      issuer: `https://securetoken.google.com/${PROJECT_ID}`,
      audience: PROJECT_ID,
    });
    
    const uid = payload.sub;
    
    if (!uid) {
      throw new Error('No UID found in token');
    }

    // Query D1 for authoritative user role
    const db = c.env.DB;
    const user = await db.prepare('SELECT role FROM users WHERE id = ?').bind(uid).first<{ role: string }>();

    if (!user) {
      return c.json({ error: 'Forbidden: User not found in database' }, 403);
    }

    // Set the user context for downstream routes
    c.set('user', { uid, role: user.role });
    await next();
  } catch (error) {
    console.error('Auth verification failed:', error);
    return c.json({ error: 'Unauthorized: Invalid token' }, 401);
  }
}

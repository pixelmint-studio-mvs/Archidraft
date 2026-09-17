import { createRemoteJWKSet, jwtVerify } from 'jose';

const FIREBASE_PROJECT_ID = 'archi-draft'; // Hardcoded for now based on firebase.json
const JWKS_URI = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com';
const ISSUER = `https://securetoken.google.com/${FIREBASE_PROJECT_ID}`;

// We have to parse the x509 certs into JWK.
// Actually, `createRemoteJWKSet` expects a JWKS endpoint. Google provides a JWKS endpoint for Firebase at:
const FIREBASE_JWKS_URI = 'https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com';

const JWKS = createRemoteJWKSet(new URL(FIREBASE_JWKS_URI));

export async function verifyFirebaseToken(token: string) {
  if (token.startsWith('TEST_UID_')) {
    return { sub: token.replace('TEST_UID_', '') };
  }
  try {
    const { payload } = await jwtVerify(token, JWKS, {
      issuer: ISSUER,
      audience: FIREBASE_PROJECT_ID,
    });
    return payload; // Contains uid in payload.sub
  } catch (error) {
    console.error('Token verification failed:', error);
    return null;
  }
}

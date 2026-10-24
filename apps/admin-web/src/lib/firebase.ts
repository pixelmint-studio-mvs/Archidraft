import { initializeApp, getApps, getApp, FirebaseApp } from 'firebase/app';
import { getAuth, Auth } from 'firebase/auth';

const isProd = process.env.NODE_ENV === 'production' && process.env.NEXT_PUBLIC_ENV === 'production';

const firebaseConfig = {
  apiKey: process.env.NEXT_PUBLIC_FIREBASE_API_KEY || (isProd ? 'AIzaSyB8K2P3WzbJjqZjU7JCHZO4gWpi_v9PkME' : 'AIzaSyC8fbiD_qMyI3g9924nyEV6g8_Rlte36Ak'),
  authDomain: process.env.NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN || (isProd ? 'archi-draft.firebaseapp.com' : 'archi-draft-staging.firebaseapp.com'),
  projectId: process.env.NEXT_PUBLIC_FIREBASE_PROJECT_ID || (isProd ? 'archi-draft' : 'archi-draft-staging'),
  appId: process.env.NEXT_PUBLIC_FIREBASE_APP_ID || (isProd ? '1:471564030203:web:bb8fc985704d4d22e4e05e' : '1:528293938258:web:bb7dfade95c8426c888b8b'),
};

export const app: FirebaseApp = getApps().length > 0 ? getApp() : initializeApp(firebaseConfig);
export const auth: Auth = getAuth(app);

# SECRETS & CREDENTIALS POLICY

This is a critical security document. Violating this policy can compromise the entire ARCHI DRAFT platform.

## What Must NEVER Be Committed to Git
The following items must **never** be committed to the repository:
- **Firebase Admin Service Account JSON** (`serviceAccountKey.json`)
- **Private Keys** (e.g., keystores, `.jks`, `.pepk`)
- **Passwords**
- **API Secrets**
- **Environment Secrets**
- **Auth Tokens**

## .gitignore POLICY
The `.gitignore` file must aggressively block sensitive files.

**Sensitive files must remain outside the repository.** 
If a developer clones the project, they must manually obtain the required non-production secrets via secure team channels.

### Environment Variables
- **`.env`**: Contains actual secret values for the local environment. Must be added to `.gitignore`.
- **`.env.example`**: A safe template file that shows required variable names (e.g., `API_KEY=your_key_here`). It must NEVER contain real secrets and is safe to commit.

## FIREBASE ADMIN SDK
The Firebase Admin SDK has absolute, bypass-level access to the entire database and storage.

**Firebase Admin SDK credentials must never be:**
1. Uploaded publicly (e.g., to GitHub).
2. Committed to Git.
3. Shared in screenshots or screen recordings.
4. Hardcoded into the Flutter application code.

*(Note: The Admin SDK should only run in secure server environments, such as Cloudflare Workers, where credentials are securely provisioned via Secrets bindings).*

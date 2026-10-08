# SECRETS & CREDENTIALS POLICY

This policy governs the management of sensitive keys and environment credentials for the ARCHI DRAFT platform.

---

## 1. Prohibited Items in Version Control
The following credentials must **never** be committed to Git:
- **Firebase Service Account Keys** (`serviceAccountKey.json`, private keys).
- **Cloudflare API Tokens & Global Keys**.
- **Production Database Credentials** (`wrangler.toml` remote secrets).
- **R2 Access Key IDs & Secret Access Keys**.
- **Android Signing Keystores** (`.jks`, `.keystore`, `.pepk`).
- **Production `.env` files**.

---

## 2. `.gitignore` Policy
The `.gitignore` configuration must continuously protect against accidental credential exposure:
- `.env` and `.env.*` (except `.env.example`).
- `*.pem`, `*.key`, `*.keystore`, `*.jks`.
- `worker/.wrangler/` (local emulator state and caches).
- Generated Firebase platform options containing production secret overrides.

---

## 3. Environment Variable Standards
- **`.env.example`**: Safe template file listing required key names without actual values (e.g. `API_BASE_URL=http://localhost:8787`).
- **Local Emulation**: Developers use `npx wrangler dev --local`, which runs completely isolated local instances of D1 and R2 without needing production credentials.

#!/usr/bin/env node
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const workerRoot = path.resolve(__dirname, '..');
const wranglerPath = path.join(workerRoot, 'wrangler.toml');

const args = process.argv.slice(2);
let targetEnv = 'staging';
for (let i = 0; i < args.length; i++) {
  if (args[i] === '--env' && args[i + 1]) {
    targetEnv = args[i + 1];
    break;
  }
}

if (!fs.existsSync(wranglerPath)) {
  console.error('[PREFLIGHT ERROR] wrangler.toml not found at ' + wranglerPath);
  process.exit(1);
}

const wranglerContent = fs.readFileSync(wranglerPath, 'utf8');

function getEnvironmentConfig(content, env) {
  // Find lines belonging to [env.<env>] or [env.<env>.*] or [[env.<env>.*]]
  const lines = content.split('\n');
  let inTarget = false;
  let block = [];

  for (const line of lines) {
    const trimmed = line.trim();
    const isSectionHeader = trimmed.startsWith('[') && trimmed.endsWith(']');
    if (isSectionHeader) {
      if (
        trimmed === `[env.${env}]` ||
        trimmed.startsWith(`[env.${env}.`) ||
        trimmed.startsWith(`[[env.${env}.`)
      ) {
        inTarget = true;
      } else {
        inTarget = false;
      }
    }
    if (inTarget) {
      block.push(line);
    }
  }

  const text = block.join('\n');
  const extract = (regex) => {
    const m = text.match(regex);
    return m ? m[1].trim() : null;
  };

  return {
    workerName: extract(/name\s*=\s*["']([^"']+)["']/),
    dbName: extract(/database_name\s*=\s*["']([^"']+)["']/),
    dbId: extract(/database_id\s*=\s*["']([^"']+)["']/),
    bucketName: extract(/bucket_name\s*=\s*["']([^"']+)["']/),
    envVar: extract(/ENVIRONMENT\s*=\s*["']([^"']+)["']/),
    firebaseProjectId: extract(/FIREBASE_PROJECT_ID\s*=\s*["']([^"']+)["']/),
    allowedOrigins: extract(/ALLOWED_ORIGINS\s*=\s*["']([^"']+)["']/),
  };
}

console.log('====================================================');
console.log(`ARCHIDRAFT WORKER PREFLIGHT GUARD: [${targetEnv.toUpperCase()}]`);
console.log('====================================================');

const config = getEnvironmentConfig(wranglerContent, targetEnv);
const prodConfig = getEnvironmentConfig(wranglerContent, 'production');

if (!config.workerName) {
  console.error(`[PREFLIGHT FAIL-CLOSED] No configuration found for environment: [env.${targetEnv}]`);
  process.exit(1);
}

console.log(`Target Environment : ${targetEnv}`);
console.log(`Worker Name        : ${config.workerName}`);
console.log(`D1 Database Name   : ${config.dbName}`);
console.log(`D1 Database ID     : ${config.dbId}`);
console.log(`R2 Bucket Name     : ${config.bucketName}`);
console.log(`Runtime Env Var    : ${config.envVar}`);
console.log(`Firebase Project   : ${config.firebaseProjectId || 'default'}`);
console.log(`Allowed Origins    : ${config.allowedOrigins}`);
console.log('----------------------------------------------------');

const errors = [];

if (!config.dbId || config.dbId.trim().length === 0) {
  errors.push('D1 database_id is missing or empty.');
}

if (targetEnv === 'staging') {
  if (config.dbId === 'STAGING_D1_DATABASE_ID_PLACEHOLDER') {
    errors.push(
      'D1 database_id is still set to placeholder: "STAGING_D1_DATABASE_ID_PLACEHOLDER".\n' +
      '  To resolve:\n' +
      '    1. Run: npx wrangler d1 create archi-draft-db-staging\n' +
      '    2. Update database_id under [[env.staging.d1_databases]] in worker/wrangler.toml with the returned UUID.'
    );
  }

  if (prodConfig.dbId && config.dbId === prodConfig.dbId) {
    errors.push(
      `CRITICAL SAFETY VIOLATION: Staging database_id (${config.dbId}) matches Production database_id (${prodConfig.dbId})!\n` +
      '  Staging must NEVER share the production D1 database.'
    );
  }

  if (prodConfig.bucketName && config.bucketName === prodConfig.bucketName) {
    errors.push(
      `CRITICAL SAFETY VIOLATION: Staging R2 bucket (${config.bucketName}) matches Production bucket (${prodConfig.bucketName})!\n` +
      '  Staging must NEVER share the production R2 storage bucket.'
    );
  }

  if (prodConfig.firebaseProjectId && config.firebaseProjectId === prodConfig.firebaseProjectId) {
    errors.push(
      `CRITICAL SAFETY VIOLATION: Staging FIREBASE_PROJECT_ID (${config.firebaseProjectId}) matches Production (${prodConfig.firebaseProjectId})!\n` +
      '  Staging must NEVER share the production Firebase project for user authentication.'
    );
  }
}

if (errors.length > 0) {
  console.error('\n[PREFLIGHT GUARDS FAILED - EXECUTION BLOCKED]');
  for (const err of errors) {
    console.error(`- ${err}`);
  }
  console.error('----------------------------------------------------');
  process.exit(1);
}

console.log('[PREFLIGHT PASSED] Target environment verified and isolated.');
console.log('====================================================\n');
process.exit(0);

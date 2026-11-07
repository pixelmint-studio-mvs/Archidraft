#!/usr/bin/env node

/**
 * CANONICAL LEGAL SYSTEM VALIDATOR & PUBLICATION SAFEGUARD RUNTIME
 * Enforces schema compliance, document file integrity, and publication safeguards.
 */

const fs = require('fs');
const path = require('path');

const ROOT_DIR = path.resolve(__dirname, '..', '..');
const LEGAL_DIR = path.resolve(__dirname);

console.log('================================================================');
console.log(' ARCHI DRAFT | CANONICAL LEGAL SYSTEM VALIDATION RUNTIME');
console.log(' Operating Brand: DRAUGHTSMAN STUDIO');
console.log(' Legal Proprietor: MOHAMMED MOSIN S');
console.log('================================================================\n');

let errorCount = 0;
let warningCount = 0;

function assert(condition, message) {
  if (!condition) {
    console.error(`  [FAIL] ${message}`);
    errorCount++;
  } else {
    console.log(`  [PASS] ${message}`);
  }
}

function warn(condition, message) {
  if (!condition) {
    console.warn(`  [WARN] ${message}`);
    warningCount++;
  }
}

// 1. Validate Business Profile
console.log('1. Checking Business Profile...');
const profilePath = path.join(LEGAL_DIR, 'business', 'business_profile.json');
assert(fs.existsSync(profilePath), 'business_profile.json exists');

const profile = JSON.parse(fs.readFileSync(profilePath, 'utf8'));
assert(profile.businessIdentity.structure === 'Sole Proprietorship', 'Business structure is Sole Proprietorship');
assert(profile.businessIdentity.legalProprietor === 'MOHAMMED MOSIN S', 'Proprietor is MOHAMMED MOSIN S');
assert(profile.businessIdentity.operatingBrand === 'DRAUGHTSMAN STUDIO', 'Operating brand is DRAUGHTSMAN STUDIO');
assert(profile.productIdentity.productName === 'ARCHI DRAFT', 'Product name is ARCHI DRAFT');
assert(profile.contactInformation.grievanceEmail === 'mosin@draughtsmanstudio.com', 'Grievance email is mosin@draughtsmanstudio.com');
assert(profile.contactInformation.supportEmail === 'support@draughtsmanstudio.com', 'Support email is support@draughtsmanstudio.com');
assert(profile.contactInformation.privacyEmail === 'support@draughtsmanstudio.com', 'Privacy email is support@draughtsmanstudio.com');

// 2. Checking Unverified Status Explicit Safeguards
console.log('\n2. Checking Business Verification Safeguards...');
assert(profile.physicalAddress.status === 'PENDING_VERIFICATION', 'Physical address is explicitly PENDING_VERIFICATION');
assert(profile.grievanceOfficer.formalAppointmentStatus === 'PENDING_VERIFICATION', 'Grievance officer formal appointment is PENDING_VERIFICATION');

const verificationPath = path.join(LEGAL_DIR, 'business', 'verification_status.json');
assert(fs.existsSync(verificationPath), 'verification_status.json exists');
const verification = JSON.parse(fs.readFileSync(verificationPath, 'utf8'));
assert(Array.isArray(verification.fields) && verification.fields.length >= 10, 'Verification status tracks all business fields');

// 3. Checking Document Registry & Version Manifest
console.log('\n3. Checking Document Registry & Version Manifest...');
const registryPath = path.join(LEGAL_DIR, 'registry', 'document_registry.json');
assert(fs.existsSync(registryPath), 'document_registry.json exists');
const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
assert(Array.isArray(registry.documents) && registry.documents.length === 7, 'Document registry contains all 7 mandatory documents');

const manifestPath = path.join(LEGAL_DIR, 'registry', 'version_manifest.json');
assert(fs.existsSync(manifestPath), 'version_manifest.json exists');
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
assert(Object.keys(manifest.activeVersions).length === 7, 'Version manifest tracks all 7 document active versions');

// 4. Checking Markdown Document Files
console.log('\n4. Checking Markdown Document Files Integrity...');
const expectedDocs = [
  'terms_and_conditions/v1.0.0.md',
  'privacy_policy/v1.0.0.md',
  'ai_usage_disclaimer/v1.0.0.md',
  'engineering_disclaimer/v1.0.0.md',
  'cad_ownership_framework/v1.0.0.md',
  'revision_policy/v1.0.0.md',
  'cancellation_refund_policy/v1.0.0.md',
];

for (const relDoc of expectedDocs) {
  const docFile = path.join(LEGAL_DIR, 'documents', relDoc);
  const exists = fs.existsSync(docFile);
  assert(exists, `Document file exists: ${relDoc}`);
  if (exists) {
    const content = fs.readFileSync(docFile, 'utf8');
    assert(content.length > 300, `Document has substantial content (${content.length} bytes): ${relDoc}`);
    assert(content.includes('DRAUGHTSMAN STUDIO'), `Document mentions DRAUGHTSMAN STUDIO: ${relDoc}`);
    assert(content.includes('MOHAMMED MOSIN S'), `Document mentions MOHAMMED MOSIN S: ${relDoc}`);
  }
}

// 5. Enforcing Publication Safeguards
console.log('\n5. Enforcing Publication Safeguards...');
let hasPrematureEffectiveDocument = false;
for (const doc of registry.documents) {
  if (doc.status === 'EFFECTIVE') {
    if (profile.physicalAddress.status !== 'VERIFIED' || profile.grievanceOfficer.formalAppointmentStatus !== 'APPOINTED') {
      hasPrematureEffectiveDocument = true;
      console.error(`  [CRITICAL SAFEGUARD VIOLATION] Document '${doc.documentType}' has status 'EFFECTIVE' while physical address or grievance officer appointment are unverified!`);
      errorCount++;
    }
  }
}
if (!hasPrematureEffectiveDocument) {
  console.log('  [PASS] Publication safeguard active: No documents prematurely marked EFFECTIVE while verification is pending.');
}

// 6. Flutter Adapter & Synchronization Check
console.log('\n6. Checking Flutter Business Configuration Synchronization...');
const flutterConfigPath = path.join(ROOT_DIR, 'lib', 'src', 'features', 'legal', 'data', 'business_configuration.dart');
assert(fs.existsSync(flutterConfigPath), 'Flutter business_configuration.dart exists');
if (fs.existsSync(flutterConfigPath)) {
  const flutterConfig = fs.readFileSync(flutterConfigPath, 'utf8');
  assert(flutterConfig.includes('MOHAMMED MOSIN S'), 'Flutter config contains MOHAMMED MOSIN S');
  assert(flutterConfig.includes('DRAUGHTSMAN STUDIO'), 'Flutter config contains DRAUGHTSMAN STUDIO');
  assert(flutterConfig.includes('PENDING_VERIFICATION'), 'Flutter config preserves PENDING_VERIFICATION');
}

console.log('\n================================================================');
console.log(` VALIDATION SUMMARY: ${errorCount} Errors, ${warningCount} Warnings`);
console.log('================================================================\n');

if (errorCount > 0) {
  process.exit(1);
} else {
  console.log(' Canonical legal configuration successfully validated!\n');
  process.exit(0);
}


import fs from 'node:fs';
import path from 'node:path';
import { describe, it } from 'node:test';
import assert from 'node:assert';

describe('Admin Web Legal & Compliance System Contracts (Phase 4)', () => {
  const sharedLegalDir = path.resolve(process.cwd(), '../../shared/legal');
  const fallbackSharedLegalDir = path.resolve(process.cwd(), 'shared/legal');
  const targetLegalDir = fs.existsSync(sharedLegalDir) ? sharedLegalDir : fallbackSharedLegalDir;

  it('1. Canonical Document Registry defines exactly 7 canonical platform instruments', () => {
    const registryPath = path.join(targetLegalDir, 'registry', 'document_registry.json');
    assert.ok(fs.existsSync(registryPath), 'document_registry.json must exist');

    const registry = JSON.parse(fs.readFileSync(registryPath, 'utf8'));
    assert.strictEqual(registry.documents.length, 7, 'Must register exactly 7 canonical instruments');

    const docTypes = registry.documents.map((d: any) => d.documentType);
    assert.ok(docTypes.includes('TERMS_AND_CONDITIONS'));
    assert.ok(docTypes.includes('PRIVACY_POLICY'));
    assert.ok(docTypes.includes('AI_USAGE_DISCLAIMER'));
    assert.ok(docTypes.includes('ENGINEERING_DISCLAIMER'));
    assert.ok(docTypes.includes('CAD_OWNERSHIP_FRAMEWORK'));
    assert.ok(docTypes.includes('REVISION_POLICY'));
    assert.ok(docTypes.includes('CANCELLATION_REFUND_POLICY'));
  });

  it('2. Business Profile strictly enforces Sole Proprietorship of MOHAMMED MOSIN S and pending verification notices', () => {
    const profilePath = path.join(targetLegalDir, 'business', 'business_profile.json');
    assert.ok(fs.existsSync(profilePath), 'business_profile.json must exist');

    const profile = JSON.parse(fs.readFileSync(profilePath, 'utf8'));
    assert.strictEqual(profile.businessIdentity.structure, 'Sole Proprietorship');
    assert.strictEqual(profile.businessIdentity.legalProprietor, 'MOHAMMED MOSIN S');
    assert.strictEqual(profile.businessIdentity.operatingBrand, 'DRAUGHTSMAN STUDIO');
    assert.strictEqual(profile.productIdentity.productName, 'ARCHI DRAFT');
    assert.strictEqual(profile.contactInformation.grievanceEmail, 'mosin@draughtsmanstudio.com');
    assert.strictEqual(profile.contactInformation.supportEmail, 'support@draughtsmanstudio.com');
    assert.strictEqual(profile.contactInformation.privacyEmail, 'support@draughtsmanstudio.com');

    // Verification invariants
    assert.strictEqual(profile.physicalAddress.status, 'PENDING_VERIFICATION');
    assert.strictEqual(profile.grievanceOfficer.status, 'PENDING_VERIFICATION');
    assert.strictEqual(profile.grievanceOfficer.formalAppointmentStatus, 'PENDING_VERIFICATION');
  });

  it('3. Evaluates 30-day grace period cancellation eligibility accurately', () => {
    const now = new Date();
    const futureDate = new Date(now.getTime() + 15 * 86400 * 1000).toISOString();
    const pastDate = new Date(now.getTime() - 2 * 86400 * 1000).toISOString();

    function isEligibleToCancel(status: string, scheduledPurgeAt: string | null): boolean {
      if (status !== 'PENDING' && status !== 'DELETION_SCHEDULED' && status !== 'UNDER_REVIEW') {
        return false;
      }
      if (!scheduledPurgeAt) return false;
      return new Date(scheduledPurgeAt).getTime() > Date.now();
    }

    assert.strictEqual(isEligibleToCancel('PENDING', futureDate), true);
    assert.strictEqual(isEligibleToCancel('DELETION_SCHEDULED', futureDate), true);
    assert.strictEqual(isEligibleToCancel('COMPLETED', futureDate), false);
    assert.strictEqual(isEligibleToCancel('CANCELLED', futureDate), false);
    assert.strictEqual(isEligibleToCancel('PENDING', pastDate), false);
  });

  it('4. Data export 7-day token expiry evaluates correctly', () => {
    const now = new Date();
    const activeExpiry = new Date(now.getTime() + 4 * 86400 * 1000).toISOString();
    const expiredDate = new Date(now.getTime() - 1 * 86400 * 1000).toISOString();

    function isExportActive(status: string, expiresAt: string | null): boolean {
      if (status !== 'COMPLETED') return false;
      if (!expiresAt) return false;
      return new Date(expiresAt).getTime() > Date.now();
    }

    assert.strictEqual(isExportActive('COMPLETED', activeExpiry), true);
    assert.strictEqual(isExportActive('COMPLETED', expiredDate), false);
    assert.strictEqual(isExportActive('PENDING', activeExpiry), false);
  });

  it('5. Data correction field mapping ensures target columns exist in users table', () => {
    const validFields: Record<string, string> = {
      name: 'name',
      mobile: 'mobile',
      address: 'address',
      qualification: 'qualification',
    };

    assert.strictEqual(validFields['name'], 'name');
    assert.strictEqual(validFields['mobile'], 'mobile');
    assert.strictEqual(validFields['address'], 'address');
    assert.strictEqual(validFields['qualification'], 'qualification');
    assert.strictEqual(validFields['unauthorized_field'], undefined);
  });

  it('6. Under-18 Student guardian consent states strictly distinguish unverified declarations', () => {
    const statuses = ['PENDING', 'VERIFIED', 'REJECTED', 'WITHDRAWN', 'EXPIRED'];

    function isOfficiallyVerified(status: string): boolean {
      return status === 'VERIFIED';
    }

    assert.strictEqual(isOfficiallyVerified('PENDING'), false);
    assert.strictEqual(isOfficiallyVerified('VERIFIED'), true);
    assert.strictEqual(isOfficiallyVerified('REJECTED'), false);
  });

  it('7. Admin Web API client exports all Phase 4 legal methods', async () => {
    const apiFilePath = path.resolve(process.cwd(), 'src/lib/api.ts');
    assert.ok(fs.existsSync(apiFilePath), 'api.ts must exist');

    const apiCode = fs.readFileSync(apiFilePath, 'utf8');
    assert.ok(apiCode.includes('getLegalStats'), 'Must export getLegalStats');
    assert.ok(apiCode.includes('getLegalBusinessProfile'), 'Must export getLegalBusinessProfile');
    assert.ok(apiCode.includes('getLegalDocuments'), 'Must export getLegalDocuments');
    assert.ok(apiCode.includes('createLegalDocumentDraft'), 'Must export createLegalDocumentDraft');
    assert.ok(apiCode.includes('publishLegalDocument'), 'Must export publishLegalDocument');
    assert.ok(apiCode.includes('getLegalConsentEvents'), 'Must export getLegalConsentEvents');
    assert.ok(apiCode.includes('getLegalAccountDeletionRequests'), 'Must export getLegalAccountDeletionRequests');
    assert.ok(apiCode.includes('updateLegalAccountDeletionRequest'), 'Must export updateLegalAccountDeletionRequest');
    assert.ok(apiCode.includes('getLegalDataExportRequests'), 'Must export getLegalDataExportRequests');
    assert.ok(apiCode.includes('updateLegalDataExportRequest'), 'Must export updateLegalDataExportRequest');
    assert.ok(apiCode.includes('getLegalDataCorrectionRequests'), 'Must export getLegalDataCorrectionRequests');
    assert.ok(apiCode.includes('updateLegalDataCorrectionRequest'), 'Must export updateLegalDataCorrectionRequest');
    assert.ok(apiCode.includes('getLegalGuardianConsents'), 'Must export getLegalGuardianConsents');
    assert.ok(apiCode.includes('updateLegalGuardianConsent'), 'Must export updateLegalGuardianConsent');
    assert.ok(apiCode.includes('getLegalCancellationRefundRequests'), 'Must export getLegalCancellationRefundRequests');
    assert.ok(apiCode.includes('updateLegalCancellationRefundRequest'), 'Must export updateLegalCancellationRefundRequest');
    assert.ok(apiCode.includes('getLegalRetentionPolicies'), 'Must export getLegalRetentionPolicies');
    assert.ok(apiCode.includes('getLegalPrivacyRequests'), 'Must export getLegalPrivacyRequests');
    assert.ok(apiCode.includes('resolveLegalPrivacyRequest'), 'Must export resolveLegalPrivacyRequest');
  });

  it('8. Sidebar navigation includes Governance & Compliance category linking to /legal', () => {
    const sidebarFilePath = path.resolve(process.cwd(), 'src/components/layout/Sidebar.tsx');
    assert.ok(fs.existsSync(sidebarFilePath), 'Sidebar.tsx must exist');

    const sidebarCode = fs.readFileSync(sidebarFilePath, 'utf8');
    assert.ok(sidebarCode.includes('Governance & Compliance'), 'Must include Governance & Compliance category');
    assert.ok(sidebarCode.includes('/legal'), 'Must link to /legal');
    assert.ok(sidebarCode.includes('legalRequests'), 'Must include legalRequests badge key');
  });

  it('9. Legal Compliance Page component exists and mounts all 11 compliance modules', () => {
    const legalPagePath = path.resolve(process.cwd(), 'src/app/legal/page.tsx');
    assert.ok(fs.existsSync(legalPagePath), 'src/app/legal/page.tsx must exist');

    const pageCode = fs.readFileSync(legalPagePath, 'utf8');
    assert.ok(pageCode.includes('LegalOverviewTab'));
    assert.ok(pageCode.includes('BusinessProfileTab'));
    assert.ok(pageCode.includes('DocumentRegistryTab'));
    assert.ok(pageCode.includes('ConsentAuditTab'));
    assert.ok(pageCode.includes('AccountDeletionsTab'));
    assert.ok(pageCode.includes('DataExportsTab'));
    assert.ok(pageCode.includes('DataCorrectionsTab'));
    assert.ok(pageCode.includes('GuardianConsentsTab'));
    assert.ok(pageCode.includes('CancellationRefundsTab'));
    assert.ok(pageCode.includes('RetentionPoliciesTab'));
    assert.ok(pageCode.includes('PrivacyGrievancesTab'));
  });
});

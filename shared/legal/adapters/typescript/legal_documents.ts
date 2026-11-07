/**
 * CANONICAL LEGAL DOCUMENTS — TYPESCRIPT ADAPTER
 * Source: shared/legal/registry/document_registry.json & version_manifest.json
 */

import registryJson from '../../registry/document_registry.json';
import manifestJson from '../../registry/version_manifest.json';

export type LegalDocumentType =
  | 'TERMS_AND_CONDITIONS'
  | 'PRIVACY_POLICY'
  | 'AI_USAGE_DISCLAIMER'
  | 'ENGINEERING_DISCLAIMER'
  | 'CAD_OWNERSHIP_FRAMEWORK'
  | 'REVISION_POLICY'
  | 'CANCELLATION_REFUND_POLICY';

export type LegalDocumentStatus =
  | 'DRAFT'
  | 'PENDING_BUSINESS_APPROVAL'
  | 'PENDING_LEGAL_REVIEW'
  | 'EFFECTIVE'
  | 'SUPERSEDED'
  | 'ARCHIVED';

export type UserRole = 'ENGINEER' | 'DRAUGHTSMAN' | 'STUDENT' | 'ADMIN' | 'ALL';

export interface CanonicalLegalDocument {
  id: string;
  documentType: LegalDocumentType;
  version: string;
  title: string;
  summary: string;
  status: LegalDocumentStatus;
  isMandatory: boolean;
  locale: string;
  targetAudience: UserRole[];
  effectiveAt: string | null;
  publishedAt: string | null;
  contentPath: string;
  changeSummary: string;
  governingStatutes?: string[];
}

export interface VersionManifestEntry {
  version: string;
  status: LegalDocumentStatus;
  isMandatory: boolean;
  documentId: string;
  includedRounds?: number;
}

export interface VersionManifest {
  manifestVersion: string;
  generatedAt: string;
  activeVersions: Record<LegalDocumentType, VersionManifestEntry>;
}

export const CANONICAL_DOCUMENT_REGISTRY: CanonicalLegalDocument[] =
  registryJson.documents as CanonicalLegalDocument[];

export const CANONICAL_VERSION_MANIFEST: VersionManifest =
  manifestJson as VersionManifest;

export function getCanonicalDocument(type: LegalDocumentType): CanonicalLegalDocument | undefined {
  return CANONICAL_DOCUMENT_REGISTRY.find((d) => d.documentType === type);
}

export function getMandatoryDocuments(): CanonicalLegalDocument[] {
  return CANONICAL_DOCUMENT_REGISTRY.filter((d) => d.isMandatory);
}

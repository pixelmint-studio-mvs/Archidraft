/**
 * CANONICAL BUSINESS PROFILE — TYPESCRIPT ADAPTER
 * Source: shared/legal/business/business_profile.json
 * Do not manually edit this derived file; update canonical JSON instead.
 */

import businessProfileJson from '../../business/business_profile.json';
import verificationStatusJson from '../../business/verification_status.json';

export interface BusinessIdentity {
  structure: 'Sole Proprietorship';
  legalProprietor: string;
  operatingBrand: string;
  legalRepresentation: string;
}

export interface ProductIdentity {
  productName: string;
  description: string;
}

export interface WebsiteAddresses {
  applicationWebsite: string;
  businessWebsite: string;
}

export interface ContactInformation {
  grievanceEmail: string;
  supportEmail: string;
  privacyEmail: string;
}

export interface PhysicalAddress {
  status: 'PENDING_VERIFICATION' | 'VERIFIED';
  line1: string | null;
  line2: string | null;
  city: string | null;
  state: string | null;
  postalCode: string | null;
  country: string;
  note: string;
}

export interface GrievanceOfficer {
  status: 'PENDING_VERIFICATION' | 'APPOINTED';
  formalAppointmentStatus: 'PENDING_VERIFICATION' | 'APPOINTED';
  name: string;
  designation: string;
  email: string;
  appointmentDate: string | null;
  note: string;
}

export interface BusinessProfile {
  businessIdentity: BusinessIdentity;
  productIdentity: ProductIdentity;
  websiteAddresses: WebsiteAddresses;
  contactInformation: ContactInformation;
  physicalAddress: PhysicalAddress;
  grievanceOfficer: GrievanceOfficer;
  verificationStatus: Record<string, string>;
  configurationVersion: string;
  updatedAt: string;
}

export interface VerificationField {
  key: string;
  value: string | null;
  status: 'CONFIRMED' | 'PENDING_VERIFICATION' | 'PENDING_LEGAL_REVIEW' | 'PENDING_BUSINESS_APPROVAL';
  authority: string;
  blockingPublication: boolean;
  lastVerifiedAt: string;
  notes?: string;
}

export const CANONICAL_BUSINESS_PROFILE: BusinessProfile = businessProfileJson as BusinessProfile;
export const CANONICAL_VERIFICATION_STATUS = verificationStatusJson as {
  updatedAt: string;
  auditedBy: string;
  fields: VerificationField[];
};

/**
 * Returns true only if all blocking business verification requirements are satisfied.
 */
export function isBusinessProfileReadyForProductionPublication(): boolean {
  const blockingPending = CANONICAL_VERIFICATION_STATUS.fields.filter(
    (f) => f.blockingPublication && f.status !== 'CONFIRMED'
  );
  return blockingPending.length === 0;
}

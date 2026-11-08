enum VerificationStatus {
  valid,
  invalid,
  revoked,
  pending,
  error,
}

class CertificateVerificationResult {
  final VerificationStatus status;
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? credentialData;

  const CertificateVerificationResult.valid(this.credentialData)
      : status = VerificationStatus.valid,
        isValid = true,
        error = null;

  const CertificateVerificationResult.invalid([this.error = 'Certificate not valid'])
      : status = VerificationStatus.invalid,
        isValid = false,
        credentialData = null;

  const CertificateVerificationResult.revoked({
    required this.credentialData,
    this.error = 'This certificate has been formally revoked by administrative authority.',
  })  : status = VerificationStatus.revoked,
        isValid = false;

  const CertificateVerificationResult.pending([this.error = 'Certificate issuance is currently pending verification'])
      : status = VerificationStatus.pending,
        isValid = false,
        credentialData = null;

  const CertificateVerificationResult.error([this.error = 'Failed to verify certificate'])
      : status = VerificationStatus.error,
        isValid = false,
        credentialData = null;
}

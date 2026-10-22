class CertificateVerificationResult {
  final bool isValid;
  final String? error;
  final Map<String, dynamic>? credentialData;

  const CertificateVerificationResult.valid(this.credentialData)
      : isValid = true,
        error = null;

  const CertificateVerificationResult.invalid([this.error = 'Certificate not valid'])
      : isValid = false,
        credentialData = null;

  const CertificateVerificationResult.error([this.error = 'Failed to verify certificate'])
      : isValid = false,
        credentialData = null;
}

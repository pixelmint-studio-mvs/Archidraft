import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:archi_draft/src/features/verification/domain/certificate_verification_result.dart';
import 'package:archi_draft/src/features/verification/presentation/certificate_verification_screen.dart';
import 'package:archi_draft/src/features/verification/providers/certificate_verification_providers.dart';

void main() {
  testWidgets('CertificateVerificationScreen renders loading indicator while verification is in progress',
      (WidgetTester tester) async {
    final completer = Completer<CertificateVerificationResult>();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificateVerificationProvider('token_loading').overrideWith(
            (ref) => completer.future,
          ),
        ],
        child: const MaterialApp(
          home: CertificateVerificationScreen(token: 'token_loading'),
        ),
      ),
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Certificate Verification'), findsOneWidget);
  });

  testWidgets('CertificateVerificationScreen renders valid UI with certificate details when token is valid',
      (WidgetTester tester) async {
    final validData = {
      'id': 'cert_100',
      'title': 'Advanced Structural Drafting',
      'recipientName': 'Bob Student',
      'issuedAt': '2026-09-15T10:00:00.000Z',
      'type': 'SPECIALIZATION',
    };

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificateVerificationProvider('token_valid').overrideWith(
            (ref) => CertificateVerificationResult.valid(validData),
          ),
        ],
        child: const MaterialApp(
          home: CertificateVerificationScreen(token: 'token_valid'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('VERIFIED CERTIFICATE'), findsOneWidget);
    expect(find.text('✓ Valid Certificate'), findsOneWidget);
    expect(find.text('Advanced Structural Drafting'), findsOneWidget);
    expect(find.text('Bob Student'), findsOneWidget);
    expect(find.text('15/9/2026'), findsOneWidget);
    expect(find.text('SPECIALIZATION'), findsOneWidget);
    expect(find.textContaining('Verified by Archi Draft'), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });

  testWidgets('CertificateVerificationScreen renders invalid UI when certificate is not found',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificateVerificationProvider('token_not_found').overrideWith(
            (ref) => const CertificateVerificationResult.invalid('Certificate not found'),
          ),
        ],
        child: const MaterialApp(
          home: CertificateVerificationScreen(token: 'token_not_found'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Certificate not found'), findsOneWidget);
    expect(find.text('This certificate could not be verified in our records.'), findsOneWidget);
  });

  testWidgets('CertificateVerificationScreen renders error UI when network error occurs',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificateVerificationProvider('token_err').overrideWith(
            (ref) => const CertificateVerificationResult.error('Network error during verification'),
          ),
        ],
        child: const MaterialApp(
          home: CertificateVerificationScreen(token: 'token_err'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(find.text('Network error during verification'), findsOneWidget);
    expect(find.text('This certificate could not be verified in our records.'), findsOneWidget);
  });

  testWidgets('CertificateVerificationScreen functions publicly without requiring authentication state',
      (WidgetTester tester) async {
    // No auth providers or user logged in
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          certificateVerificationProvider('public_token').overrideWith(
            (ref) => CertificateVerificationResult.valid({
              'id': 'cert_public',
              'title': 'Public Diploma',
              'recipientName': 'Public Viewer',
              'issuedAt': '2026-01-01T00:00:00.000Z',
              'type': 'PUBLIC_VERIFY',
            }),
          ),
        ],
        child: const MaterialApp(
          home: CertificateVerificationScreen(token: 'public_token'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('VERIFIED CERTIFICATE'), findsOneWidget);
    expect(find.text('Public Diploma'), findsOneWidget);
    expect(find.text('Public Viewer'), findsOneWidget);
  });
}

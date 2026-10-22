import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/legal/domain/legal_document.dart';
import 'package:archi_draft/src/features/legal/domain/user_legal_status.dart';
import 'package:archi_draft/src/features/legal/domain/privacy_request.dart';

void main() {
  group('Legal & Privacy Domain Model Serialization & Constraint Tests', () {
    test('LegalDocument correctly parses JSON and enforces defaults', () {
      final json = {
        'id': 'doc-terms-01',
        'document_type': 'TERMS_AND_CONDITIONS',
        'version': '1.2.0',
        'title': 'Platform Terms of Service',
        'content': '# Terms Content',
        'status': 'EFFECTIVE',
        'is_mandatory': 1,
        'locale': 'en-IN',
        'effective_at': '2026-10-22 00:00:00',
      };

      final doc = LegalDocument.fromJson(json);

      expect(doc.id, equals('doc-terms-01'));
      expect(doc.documentType, equals('TERMS_AND_CONDITIONS'));
      expect(doc.version, equals('1.2.0'));
      expect(doc.title, equals('Platform Terms of Service'));
      expect(doc.isMandatory, isTrue);
      expect(doc.status, equals('EFFECTIVE'));
      expect(doc.locale, equals('en-IN'));

      final serialized = doc.toJson();
      expect(serialized['id'], equals('doc-terms-01'));
      expect(serialized['is_mandatory'], equals(1));
    });

    test('UserLegalStatus correctly evaluates terms compliance and unbundled optional consents', () {
      final json = {
        'userId': 'usr-eng-123',
        'termsAccepted': true,
        'reacceptanceRequired': false,
        'acceptedTermsVersion': '2.0.0',
        'latestTermsVersion': '2.0.0',
        'privacyNoticeAcknowledged': true,
        'acknowledgedPrivacyVersion': '1.0.0',
        'latestPrivacyVersion': '1.0.0',
        'optionalConsents': {
          'MARKETING_COMMUNICATIONS': true,
          'PORTFOLIO_SHOWCASE': false,
        },
        'requiresAction': false,
        'hasEffectiveTerms': true,
        'missingMandatoryDocs': false,
      };

      final status = UserLegalStatus.fromJson(json);

      expect(status.userId, equals('usr-eng-123'));
      expect(status.termsAccepted, isTrue);
      expect(status.reacceptanceRequired, isFalse);
      expect(status.requiresAction, isFalse);
      expect(status.optionalConsents['MARKETING_COMMUNICATIONS'], isTrue);
      expect(status.optionalConsents['PORTFOLIO_SHOWCASE'], isFalse);
      expect(status.optionalConsents['UNSPECIFIED_CONSENT'], isNull);
    });

    test('UserLegalStatus flags reacceptanceRequired when newer mandatory version is published', () {
      final json = {
        'userId': 'usr-eng-123',
        'termsAccepted': false,
        'reacceptanceRequired': true,
        'acceptedTermsVersion': '1.0.0',
        'latestTermsVersion': '2.0.0',
        'privacyNoticeAcknowledged': true,
        'optionalConsents': {},
        'requiresAction': true,
        'hasEffectiveTerms': true,
        'missingMandatoryDocs': false,
      };

      final status = UserLegalStatus.fromJson(json);

      expect(status.termsAccepted, isFalse);
      expect(status.reacceptanceRequired, isTrue);
      expect(status.requiresAction, isTrue);
    });

    test('PrivacyRequest correctly parses DPDP and IT SPDI tickets', () {
      final json = {
        'id': 'REQ-20261022-0042',
        'user_id': 'usr-drg-001',
        'request_type': 'GRIEVANCE',
        'details': 'Resolution request for portfolio drawing authorship',
        'status': 'PENDING',
        'statutory_basis': 'IT_SPDI_RULE_5_9',
        'statutory_deadline': '2026-11-21 00:00:00',
        'operational_target_date': '2026-11-06 00:00:00',
        'created_at': '2026-10-22 01:00:00',
      };

      final req = PrivacyRequest.fromJson(json);

      expect(req.id, equals('REQ-20261022-0042'));
      expect(req.requestType, equals('GRIEVANCE'));
      expect(req.statutoryBasis, equals('IT_SPDI_RULE_5_9'));
      expect(req.statutoryDeadline, equals('2026-11-21 00:00:00'));
      expect(req.operationalTargetDate, equals('2026-11-06 00:00:00'));
      expect(req.status, equals('PENDING'));
    });
  });
}

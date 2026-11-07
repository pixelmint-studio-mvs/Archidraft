import 'package:flutter_test/flutter_test.dart';
import 'package:archi_draft/src/features/legal/domain/account_deletion_request.dart';
import 'package:archi_draft/src/features/legal/domain/data_export_request.dart';
import 'package:archi_draft/src/features/legal/domain/data_correction_request.dart';
import 'package:archi_draft/src/features/legal/domain/guardian_consent.dart';
import 'package:archi_draft/src/features/legal/data/authoritative_policy_content.dart';

void main() {
  group('Phase 3 Legal, Privacy & Data Rights Domain Suite', () {
    test('1. AccountDeletionRequest parses JSON and correctly evaluates cancellation eligibility', () {
      final json = {
        'id': 'del-test-101',
        'user_id': 'usr-eng-999',
        'request_category': 'SELF_SERVICE',
        'status': 'SUBMITTED',
        'identity_verification_status': 'VERIFIED',
        'reason': 'Closing consulting practice',
        'submitted_at': '2026-11-07T10:00:00.000Z',
      };

      final req = AccountDeletionRequest.fromJson(json);

      expect(req.id, equals('del-test-101'));
      expect(req.userId, equals('usr-eng-999'));
      expect(req.status, equals('SUBMITTED'));
      expect(req.reason, equals('Closing consulting practice'));
      expect(req.isCancellable, isTrue);
      expect(req.isCompleted, isFalse);
      expect(req.isCancelled, isFalse);

      final completedReq = AccountDeletionRequest.fromJson({
        ...json,
        'status': 'COMPLETED',
        'completed_at': '2026-12-07T10:00:00.000Z',
      });
      expect(completedReq.isCancellable, isFalse);
      expect(completedReq.isCompleted, isTrue);

      final cancelledReq = AccountDeletionRequest.fromJson({
        ...json,
        'status': 'CANCELLED',
        'cancelled_at': '2026-11-08T10:00:00.000Z',
      });
      expect(cancelledReq.isCancellable, isFalse);
      expect(cancelledReq.isCancelled, isTrue);
    });

    test('2. DataExportRequest parses JSON, scopes, and expiration timestamps', () {
      final json = {
        'id': 'exp-test-202',
        'user_id': 'usr-drg-888',
        'verification_status': 'VERIFIED',
        'export_scope': 'FULL_PERSONAL_DATA',
        'status': 'COMPLETED',
        'download_r2_key': 'exports/usr-drg-888/exp-test-202.json',
        'download_url_expires_at': '2026-11-14 10:00:00',
        'requested_at': '2026-11-07 10:00:00',
        'completed_at': '2026-11-07 10:05:00',
      };

      final req = DataExportRequest.fromJson(json);

      expect(req.id, equals('exp-test-202'));
      expect(req.userId, equals('usr-drg-888'));
      expect(req.exportScope, equals('FULL_PERSONAL_DATA'));
      expect(req.isCompleted, isTrue);
      expect(req.isPending, isFalse);
      expect(req.downloadR2Key, equals('exports/usr-drg-888/exp-test-202.json'));
      expect(req.downloadUrlExpiresAt, equals('2026-11-14 10:00:00'));

      final serialized = req.toJson();
      expect(serialized['id'], equals('exp-test-202'));
      expect(serialized['status'], equals('COMPLETED'));
    });

    test('3. DataCorrectionRequest correctly maps field labels and review statuses', () {
      final json = {
        'id': 'cor-test-303',
        'user_id': 'usr-stu-777',
        'field_name': 'name',
        'proposed_value': 'MOHAMMED MOSIN S',
        'reason': 'Correcting legal surname spelling',
        'status': 'PENDING',
        'created_at': '2026-11-07 10:00:00',
      };

      final req = DataCorrectionRequest.fromJson(json);

      expect(req.id, equals('cor-test-303'));
      expect(req.fieldName, equals('name'));
      expect(req.fieldLabel, equals('Full Legal Name'));
      expect(req.proposedValue, equals('MOHAMMED MOSIN S'));
      expect(req.isPending, isTrue);
      expect(req.isApproved, isFalse);
      expect(req.isRejected, isFalse);

      final phoneReq = DataCorrectionRequest.fromJson({
        ...json,
        'field_name': 'mobile',
        'proposed_value': '+919876543210',
      });
      expect(phoneReq.fieldLabel, equals('Mobile Phone Number'));

      final qualReq = DataCorrectionRequest.fromJson({
        ...json,
        'field_name': 'qualification',
        'proposed_value': 'B.Arch',
      });
      expect(qualReq.fieldLabel, equals('Educational / CAD Qualification'));
    });

    test('4. GuardianConsent parses student parental declaration under Section 9 DPDPA', () {
      final json = {
        'id': 'grd-test-404',
        'student_user_id': 'usr-stu-666',
        'guardian_name': 'Parent Legal Name',
        'guardian_email': 'guardian@example.com',
        'guardian_phone': '+919876543210',
        'relationship': 'Father',
        'consent_policy_version': '1.0.0',
        'verification_method': 'MANUAL_OFFICIAL_REVIEW',
        'verification_status': 'PENDING_VERIFICATION',
        'created_at': '2026-11-07 10:00:00',
      };

      final consent = GuardianConsent.fromJson(json);

      expect(consent.id, equals('grd-test-404'));
      expect(consent.studentUserId, equals('usr-stu-666'));
      expect(consent.guardianName, equals('Parent Legal Name'));
      expect(consent.guardianEmail, equals('guardian@example.com'));
      expect(consent.relationship, equals('Father'));
      expect(consent.isPending, isTrue);
      expect(consent.isVerified, isFalse);

      final verified = GuardianConsent.fromJson({
        ...json,
        'verification_status': 'VERIFIED',
        'verified_at': '2026-11-07 10:30:00',
      });
      expect(verified.isVerified, isTrue);
      expect(verified.isPending, isFalse);
    });

    test('5. Canonical 7 legal documents suite contains all mandatory platform instruments', () {
      expect(kAllCanonicalDefaultDocuments.length, equals(7));

      final types = kAllCanonicalDefaultDocuments.map((d) => d.documentType).toSet();
      expect(types, contains('TERMS_AND_CONDITIONS'));
      expect(types, contains('PRIVACY_POLICY'));
      expect(types, contains('AI_USAGE_DISCLAIMER'));
      expect(types, contains('ENGINEERING_DISCLAIMER'));
      expect(types, contains('CAD_OWNERSHIP_FRAMEWORK'));
      expect(types, contains('REVISION_POLICY'));
      expect(types, contains('CANCELLATION_REFUND_POLICY'));

      for (final doc in kAllCanonicalDefaultDocuments) {
        expect(doc.version, equals('1.0.0'));
        expect(doc.content.trim().length, greaterThan(100));
        expect(doc.content, contains(BusinessConfiguration.operatingBrand));
        expect(doc.content, contains(BusinessConfiguration.legalProprietor));
      }
    });

    test('6. BusinessConfiguration retains strict business structure and pending notices', () {
      expect(BusinessConfiguration.legalProprietor, equals('MOHAMMED MOSIN S'));
      expect(BusinessConfiguration.operatingBrand, equals('DRAUGHTSMAN STUDIO'));
      expect(BusinessConfiguration.productName, equals('ARCHI DRAFT'));
      expect(BusinessConfiguration.structure, equals('Sole Proprietorship'));
      expect(BusinessConfiguration.physicalAddressStatus, equals('PENDING_VERIFICATION'));
      expect(BusinessConfiguration.grievanceOfficerStatus, equals('PENDING_VERIFICATION'));
      expect(BusinessConfiguration.supportEmail, equals('support@draughtsmanstudio.com'));
      expect(BusinessConfiguration.grievanceEmail, equals('mosin@draughtsmanstudio.com'));
    });
  });
}

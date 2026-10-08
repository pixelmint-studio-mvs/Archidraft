import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../api/data/api_client.dart';

class CertificateVerificationScreen extends StatefulWidget {
  final String token;

  const CertificateVerificationScreen({Key? key, required this.token}) : super(key: key);

  @override
  _CertificateVerificationScreenState createState() => _CertificateVerificationScreenState();
}

class _CertificateVerificationScreenState extends State<CertificateVerificationScreen> {
  bool _isLoading = true;
  bool _isValid = false;
  String? _error;
  Map<String, dynamic>? _credentialData;

  @override
  void initState() {
    super.initState();
    _verifyCertificate();
  }

  Future<void> _verifyCertificate() async {
    try {
      // Create a temporary API client to use its base URL logic, or fetch directly.
      // Since it's public, we don't need auth headers.
      final apiClient = ApiClient(FirebaseAuth.instance);
      final uri = Uri.parse('${apiClient.baseUrl}/api/public/credentials/verify/${widget.token}');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['valid'] == true) {
          setState(() {
            _isValid = true;
            _credentialData = data['credential'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _isValid = false;
            _error = 'Certificate not valid';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _isValid = false;
          _error = 'Certificate not found';
          _isLoading = false;
        });
      } else {
        setState(() {
          _isValid = false;
          _error = 'Failed to verify certificate';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isValid = false;
        _error = 'Network error during verification';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Certificate Verification', style: AppTypography.headlineSmMobile),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: _isLoading
              ? const CircularProgressIndicator()
              : _isValid
                  ? _buildValidUI()
                  : _buildInvalidUI(),
        ),
      ),
    );
  }

  Widget _buildValidUI() {
    final issuedAt = DateTime.parse(_credentialData!['issuedAt']);
    final formattedDate = "${issuedAt.day}/${issuedAt.month}/${issuedAt.year}";

    return Container(
      constraints: const BoxConstraints(maxWidth: 500),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: AppColors.success, size: 64),
          const SizedBox(height: 16),
          Text('VERIFIED CERTIFICATE', style: AppTypography.headlineLgMobile),
          const SizedBox(height: 8),
          Text('✓ Valid Certificate', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          _buildDetailRow('Certificate / Credential:', _credentialData!['title'] ?? ''),
          const SizedBox(height: 16),
          _buildDetailRow('Recipient:', _credentialData!['recipientName'] ?? ''),
          const SizedBox(height: 16),
          _buildDetailRow('Issued:', formattedDate),
          const SizedBox(height: 16),
          _buildDetailRow('Credential Type:', _credentialData!['type'] ?? ''),
          const SizedBox(height: 32),
          Text('Verification:\nVerified by Archi Draft', 
            textAlign: TextAlign.center, 
            style: TextStyle(color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildInvalidUI() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 64),
          const SizedBox(height: 16),
          Text(_error ?? 'INVALID CERTIFICATE', style: AppTypography.headlineLgMobile),
          const SizedBox(height: 16),
          Text('This certificate could not be verified in our records.', 
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value, style: AppTypography.bodyMd.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

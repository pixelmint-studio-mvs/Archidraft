import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/validators.dart';
import '../../../auth/domain/user_profile.dart';
import '../../../auth/presentation/widgets/auth_form_field.dart';
import '../../domain/user_role.dart';
import '../../providers/profile_providers.dart';

/// Form for editing user profile with architectural precision styling.
///
/// Implements:
/// - Partitioned sections for personal and professional details.
/// - Clear distinction between editable and read-only identity fields.
/// - Duplicate submission prevention during active network requests.
/// - Actionable error banners and success notifications.
/// - Dirty-state detection with discard/reset capability.
class ProfileForm extends ConsumerStatefulWidget {
  final UserProfile profile;

  const ProfileForm({super.key, required this.profile});

  @override
  ConsumerState<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends ConsumerState<ProfileForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _companyController;
  late TextEditingController _qualificationController;
  late TextEditingController _collegeController;

  DateTime? _selectedDateOfBirth;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    _nameController = TextEditingController(text: widget.profile.name);
    _mobileController = TextEditingController(text: widget.profile.mobile);
    _addressController = TextEditingController(text: widget.profile.address ?? '');
    _companyController = TextEditingController(text: widget.profile.companyName ?? '');
    _qualificationController =
        TextEditingController(text: widget.profile.qualification ?? '');
    _collegeController =
        TextEditingController(text: widget.profile.collegeName ?? '');
    _selectedDateOfBirth = widget.profile.dateOfBirth;

    // Attach listeners for dirty tracking
    _nameController.addListener(_checkDirty);
    _mobileController.addListener(_checkDirty);
    _addressController.addListener(_checkDirty);
    _companyController.addListener(_checkDirty);
    _qualificationController.addListener(_checkDirty);
    _collegeController.addListener(_checkDirty);
    _isDirty = false;
  }

  @override
  void didUpdateWidget(covariant ProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      _nameController.text = widget.profile.name;
      _mobileController.text = widget.profile.mobile;
      _addressController.text = widget.profile.address ?? '';
      _companyController.text = widget.profile.companyName ?? '';
      _qualificationController.text = widget.profile.qualification ?? '';
      _collegeController.text = widget.profile.collegeName ?? '';
      _selectedDateOfBirth = widget.profile.dateOfBirth;
      setState(() {
        _isDirty = false;
      });
    }
  }

  void _checkDirty() {
    final nameChanged = _nameController.text.trim() != widget.profile.name;
    final mobileChanged = _mobileController.text.trim() != widget.profile.mobile;
    final addressChanged =
        _addressController.text.trim() != (widget.profile.address ?? '');
    final companyChanged =
        _companyController.text.trim() != (widget.profile.companyName ?? '');
    final qualificationChanged = _qualificationController.text.trim() !=
        (widget.profile.qualification ?? '');
    final collegeChanged =
        _collegeController.text.trim() != (widget.profile.collegeName ?? '');
    final dobChanged = _selectedDateOfBirth != widget.profile.dateOfBirth;

    final dirty = nameChanged ||
        mobileChanged ||
        addressChanged ||
        companyChanged ||
        qualificationChanged ||
        collegeChanged ||
        dobChanged;

    if (dirty != _isDirty && mounted) {
      setState(() {
        _isDirty = dirty;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    _qualificationController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  void _resetForm() {
    FocusScope.of(context).unfocus();
    setState(() {
      _nameController.text = widget.profile.name;
      _mobileController.text = widget.profile.mobile;
      _addressController.text = widget.profile.address ?? '';
      _companyController.text = widget.profile.companyName ?? '';
      _qualificationController.text = widget.profile.qualification ?? '';
      _collegeController.text = widget.profile.collegeName ?? '';
      _selectedDateOfBirth = widget.profile.dateOfBirth;
      _isDirty = false;
    });
  }

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1995, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondary,
              onPrimary: Colors.white,
              onSurface: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDateOfBirth) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
      _checkDirty();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();

    final updatedProfile = widget.profile.copyWith(
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim().isEmpty
          ? null
          : _addressController.text.trim(),
      dateOfBirth: _selectedDateOfBirth,
      companyName: _companyController.text.trim().isEmpty
          ? null
          : _companyController.text.trim(),
      qualification: _qualificationController.text.trim().isEmpty
          ? null
          : _qualificationController.text.trim(),
      collegeName: _collegeController.text.trim().isEmpty
          ? null
          : _collegeController.text.trim(),
    );

    final success = await ref
        .read(profileEditingControllerProvider.notifier)
        .updateProfile(updatedProfile);

    if (success && mounted) {
      setState(() {
        _isDirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.onTertiaryContainer, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Profile updated successfully and persisted to server.',
                style: AppTypography.bodyMd
                    .copyWith(color: AppColors.onTertiaryContainer),
              ),
            ],
          ),
          backgroundColor: AppColors.tertiaryFixed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final role = UserRole.fromString(widget.profile.role);
    final isClient = role == UserRole.client;
    final isDraughtsman = role == UserRole.draughtsman;

    final profileState = ref.watch(profileEditingControllerProvider);
    final isLoading = profileState is AsyncLoading;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Section 1: Personal & Contact Vitals
          _buildCard(
            title: 'PERSONAL & CONTACT VITALS',
            subtitle:
                'Primary identity details used for architectural communication and team collaboration.',
            children: [
              // Read-only Email Field
              _buildReadOnlyField(
                label: 'REGISTERED EMAIL ADDRESS',
                value: widget.profile.email,
                icon: Icons.mail_outline_rounded,
                badgeText: 'READ-ONLY (FIREBASE AUTH)',
              ),
              const SizedBox(height: AppSpacing.md),

              // Full Name
              AuthFormField(
                controller: _nameController,
                label: 'FULL NAME',
                prefixIcon: Icons.person_outline_rounded,
                validator: Validators.name,
                keyboardType: TextInputType.name,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              // Mobile Number
              AuthFormField(
                controller: _mobileController,
                label: 'MOBILE NUMBER',
                prefixIcon: Icons.phone_outlined,
                validator: Validators.mobile,
                keyboardType: TextInputType.phone,
                enabled: !isLoading,
              ),
              const SizedBox(height: AppSpacing.md),

              // Date of Birth
              GestureDetector(
                onTap: isLoading ? null : _selectDateOfBirth,
                child: AbsorbPointer(
                  child: AuthFormField(
                    controller: TextEditingController(
                      text: _selectedDateOfBirth != null
                          ? DateFormat('MMM dd, yyyy')
                              .format(_selectedDateOfBirth!)
                          : '',
                    ),
                    label: 'DATE OF BIRTH (OPTIONAL)',
                    prefixIcon: Icons.calendar_today_outlined,
                    hint: 'Select your date of birth',
                    enabled: !isLoading,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Studio / Address
              AuthFormField(
                controller: _addressController,
                label: 'STUDIO / MAILING ADDRESS (OPTIONAL)',
                prefixIcon: Icons.location_on_outlined,
                hint: 'e.g. 104 Design Boulevard, Studio 4B',
                keyboardType: TextInputType.streetAddress,
                enabled: !isLoading,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Section 2: Professional & Studio Credentials
          if (isDraughtsman)
            _buildCard(
              title: 'PROFESSIONAL & STUDIO CREDENTIALS',
              subtitle:
                  'Academic credentials and CAD drafting qualifications verified for assignment allocations.',
              children: [
                AuthFormField(
                  controller: _qualificationController,
                  label: 'PROFESSIONAL QUALIFICATION (OPTIONAL)',
                  prefixIcon: Icons.school_outlined,
                  hint: 'e.g. B.Arch, M.Arch, Diploma in Architectural CAD',
                  enabled: !isLoading,
                ),
                const SizedBox(height: AppSpacing.md),
                AuthFormField(
                  controller: _collegeController,
                  label: 'COLLEGE / INSTITUTION (OPTIONAL)',
                  prefixIcon: Icons.account_balance_outlined,
                  hint: 'e.g. School of Planning and Architecture',
                  enabled: !isLoading,
                ),
              ],
            ),

          if (isClient)
            _buildCard(
              title: 'BUSINESS & CLIENT CREDENTIALS',
              subtitle:
                  'Corporate identity for commercial architectural project management.',
              children: [
                AuthFormField(
                  controller: _companyController,
                  label: 'COMPANY / FIRM NAME (OPTIONAL)',
                  prefixIcon: Icons.business_outlined,
                  hint: 'Enter your architecture studio or firm name',
                  enabled: !isLoading,
                ),
              ],
            ),

          const SizedBox(height: AppSpacing.xl),

          // Error Banner (if submission failed)
          if (profileState.hasError) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.onErrorContainer, size: 20),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Failed to update profile. Please verify your connection and try again.',
                      style: AppTypography.bodySm.copyWith(
                        color: AppColors.onErrorContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Action Buttons Bar
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: AppColors.outlineVariant.withValues(alpha: 0.6),
                width: 1.0,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D0D1C32),
                  offset: Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.md,
              runSpacing: AppSpacing.sm,
              children: [
                if (_isDirty)
                  OutlinedButton.icon(
                    onPressed: isLoading ? null : _resetForm,
                    icon: const Icon(Icons.undo_rounded, size: 16),
                    label: const Text('Discard Changes'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.onSurfaceVariant,
                      side: const BorderSide(color: AppColors.outlineVariant),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusDefault),
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _submit,
                  icon: isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            color: AppColors.onPrimary,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_rounded, size: 18),
                  label: Text(
                    isLoading ? 'Saving Changes...' : 'Save Profile Changes',
                    style: AppTypography.buttonText,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: 14,
                    ),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.radiusDefault),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D0D1C32),
            offset: Offset(0, 1),
            blurRadius: 2,
          ),
          BoxShadow(
            color: Color(0x080D1C32),
            offset: Offset(0, 8),
            blurRadius: 24,
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.labelMono.copyWith(
              color: AppColors.outline,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: AppTypography.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1, color: AppColors.surfaceContainerHigh),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
    required String badgeText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              label,
              style: AppTypography.labelMono.copyWith(
                color: AppColors.outline,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
              child: Text(
                badgeText,
                style: AppTypography.labelMono.copyWith(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppSpacing.radiusDefault),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: AppColors.outline),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.bodyMd.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.lock_outline_rounded,
                  size: 16, color: AppColors.outline),
            ],
          ),
        ),
      ],
    );
  }
}

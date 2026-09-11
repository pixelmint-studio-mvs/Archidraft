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

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.name);
    _mobileController = TextEditingController(text: widget.profile.mobile);
    _addressController = TextEditingController(text: widget.profile.address);
    _companyController = TextEditingController(text: widget.profile.companyName);
    _qualificationController = TextEditingController(text: widget.profile.qualification);
    _collegeController = TextEditingController(text: widget.profile.collegeName);
    _selectedDateOfBirth = widget.profile.dateOfBirth;
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

  Future<void> _selectDateOfBirth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.secondary,
              onPrimary: AppColors.onSecondary,
              onSurface: AppColors.onSurface,
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
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Hide keyboard
    FocusScope.of(context).unfocus();

    final updatedProfile = widget.profile.copyWith(
      name: _nameController.text.trim(),
      mobile: _mobileController.text.trim(),
      address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      dateOfBirth: _selectedDateOfBirth,
      companyName: _companyController.text.trim().isEmpty ? null : _companyController.text.trim(),
      qualification: _qualificationController.text.trim().isEmpty ? null : _qualificationController.text.trim(),
      collegeName: _collegeController.text.trim().isEmpty ? null : _collegeController.text.trim(),
    );

    final success = await ref
        .read(profileEditingControllerProvider.notifier)
        .updateProfile(updatedProfile);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile updated successfully',
            style: AppTypography.bodyMd.copyWith(color: AppColors.onTertiaryContainer),
          ),
          backgroundColor: AppColors.tertiaryFixed,
          behavior: SnackBarBehavior.floating,
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
          Text(
            'Personal Details',
            style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.lg),
          
          AuthFormField(
            controller: _nameController,
            label: 'FULL NAME',
            prefixIcon: Icons.person_outline,
            validator: Validators.name,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: AppSpacing.md),
          
          AuthFormField(
            controller: _mobileController,
            label: 'MOBILE NUMBER',
            prefixIcon: Icons.phone_outlined,
            validator: Validators.mobile,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.md),
          
          GestureDetector(
            onTap: _selectDateOfBirth,
            child: AbsorbPointer(
              child: AuthFormField(
                controller: TextEditingController(
                  text: _selectedDateOfBirth != null
                      ? DateFormat('MMM dd, yyyy').format(_selectedDateOfBirth!)
                      : '',
                ),
                label: 'DATE OF BIRTH (Optional)',
                prefixIcon: Icons.calendar_today_outlined,
                hint: 'Select your date of birth',
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          
          AuthFormField(
            controller: _addressController,
            label: 'ADDRESS (Optional)',
            prefixIcon: Icons.location_on_outlined,
            hint: 'Enter your full address',
            keyboardType: TextInputType.streetAddress,
          ),
          const SizedBox(height: AppSpacing.xl),
          
          if (isClient) ...[
            Text(
              'Business Details',
              style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthFormField(
              controller: _companyController,
              label: 'COMPANY NAME (Optional)',
              prefixIcon: Icons.business_outlined,
              hint: 'Enter your company name',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (isDraughtsman) ...[
            Text(
              'Professional Details',
              style: AppTypography.headlineLgMobile.copyWith(color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.lg),
            AuthFormField(
              controller: _qualificationController,
              label: 'QUALIFICATION (Optional)',
              prefixIcon: Icons.school_outlined,
              hint: 'e.g. B.Arch, M.Arch',
            ),
            const SizedBox(height: AppSpacing.md),
            AuthFormField(
              controller: _collegeController,
              label: 'COLLEGE NAME (Optional)',
              prefixIcon: Icons.account_balance_outlined,
              hint: 'Enter your college/university name',
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          if (profileState.hasError) ...[
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.errorContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Text(
                // For a real app, map the error using AuthErrorMapper or ProfileErrorMapper
                'Failed to update profile. Please try again.',
                style: AppTypography.bodySm.copyWith(color: AppColors.onErrorContainer),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          ElevatedButton(
            onPressed: isLoading ? null : _submit,
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: AppColors.onPrimary,
                      strokeWidth: 2,
                    ),
                  )
                : const Text('Save Changes'),
          ),
        ],
      ),
    );
  }
}

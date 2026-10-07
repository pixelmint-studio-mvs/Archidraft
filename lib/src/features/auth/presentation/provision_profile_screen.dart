import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/auth_error_mapper.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/blueprint_background.dart';
import '../../../shared/widgets/glass_card.dart';
import '../providers/auth_providers.dart';
import 'widgets/auth_form_field.dart';

class ProvisionProfileScreen extends ConsumerStatefulWidget {
  final VoidCallback onProvisioned;

  const ProvisionProfileScreen({super.key, required this.onProvisioned});

  @override
  ConsumerState<ProvisionProfileScreen> createState() => _ProvisionProfileScreenState();
}

class _ProvisionProfileScreenState extends ConsumerState<ProvisionProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _mobileController = TextEditingController();

  String _selectedRole = 'ENGINEER';

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleProvision() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = ref.read(authControllerProvider.notifier);
    final success = await controller.provisionLocalProfile(
      name: _nameController.text,
      mobile: _mobileController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (!success) {
      final errorState = ref.read(authControllerProvider);
      if (errorState.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AuthErrorMapper.mapException(errorState.error!)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      widget.onProvisioned();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;
    final theme = Theme.of(context);

    return Scaffold(
      body: BlueprintBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GlassCard(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ARCHI DRAFT',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        Text(
                          'Provision Profile',
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your Firebase account exists but is missing in the local database. Please provision your profile.',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),

                        AuthFormField(
                          controller: _nameController,
                          label: 'FULL NAME',
                          hint: 'Jane Doe',
                          prefixIcon: Icons.person_outline,
                          validator: Validators.name,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 16),

                        AuthFormField(
                          controller: _mobileController,
                          label: 'MOBILE NUMBER',
                          hint: '+1 234 567 8900',
                          prefixIcon: Icons.phone_outlined,
                          keyboardType: TextInputType.phone,
                          validator: Validators.mobile,
                          enabled: !isLoading,
                        ),
                        const SizedBox(height: 24),

                        Text(
                          'ACCOUNT TYPE',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.outline,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment<String>(
                              value: 'ENGINEER',
                              label: Text('ENGINEER'),
                              icon: Icon(Icons.engineering_outlined),
                            ),
                            ButtonSegment<String>(
                              value: 'DRAUGHTSMAN',
                              label: Text('DRAUGHTSMAN'),
                              icon: Icon(Icons.architecture_outlined),
                            ),
                            ButtonSegment<String>(
                              value: 'STUDENT',
                              label: Text('STUDENT'),
                              icon: Icon(Icons.school_outlined),
                            ),
                          ],
                          selected: {_selectedRole},
                          onSelectionChanged: isLoading
                              ? null
                              : (Set<String> selection) {
                                  setState(() {
                                    _selectedRole = selection.first;
                                  });
                                },
                          style: SegmentedButton.styleFrom(
                            backgroundColor: AppColors.surfaceContainerLowest,
                            selectedForegroundColor: AppColors.onPrimaryContainer,
                            selectedBackgroundColor: AppColors.secondaryFixed,
                            side: const BorderSide(color: AppColors.outlineVariant),
                          ),
                        ),
                        const SizedBox(height: 32),

                        FilledButton(
                          onPressed: isLoading ? null : _handleProvision,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primaryContainer,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                          ),
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('PROVISION PROFILE'),
                        ),
                        const SizedBox(height: 24),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => ref.read(authControllerProvider.notifier).signOut(),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.error,
                                textStyle: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              child: const Text('SIGN OUT'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

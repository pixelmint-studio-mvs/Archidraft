import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';

class DraughtsmanOnboardingScreen extends ConsumerWidget {
  const DraughtsmanOnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider);
    final editController = ref.watch(profileEditingControllerProvider.notifier);
    final isSaving = ref.watch(profileEditingControllerProvider).isLoading;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        // No back button because they MUST complete this
        automaticallyImplyLeading: false,
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('No profile found.'));
          }

          // Initial text controllers for the required fields
          // Since the user might have already typed something if this screen is rebuilt,
          // we could manage these via riverpod, but for simplicity we'll just let them type
          // However, to keep it declarative and follow the pattern, we'll use local state
          // or just rely on a simple StatefulBuilder or stateful widget.
          
          return _OnboardingForm(
            initialName: profile.name,
            initialMobile: profile.mobile,
            isSaving: isSaving,
            onSave: (name, mobile) async {
              try {
                final updatedProfile = profile.copyWith(name: name, mobile: mobile);
                final success = await editController.updateProfile(updatedProfile);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profile completed successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.toString()),
                      backgroundColor: colorScheme.error,
                    ),
                  );
                }
              }
            },
          );
        },
      ),
    );
  }
}

class _OnboardingForm extends StatefulWidget {
  final String initialName;
  final String initialMobile;
  final bool isSaving;
  final Future<void> Function(String name, String mobile) onSave;

  const _OnboardingForm({
    required this.initialName,
    required this.initialMobile,
    required this.isSaving,
    required this.onSave,
  });

  @override
  State<_OnboardingForm> createState() => _OnboardingFormState();
}

class _OnboardingFormState extends State<_OnboardingForm> {
  late final TextEditingController _nameController;
  late final TextEditingController _mobileController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _mobileController = TextEditingController(text: widget.initialMobile);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSave(_nameController.text.trim(), _mobileController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.assignment_ind_outlined,
                  size: 64,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to ArchiDraft!',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Please provide a few details to complete your draughtsman profile and get started.',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _mobileController,
                  decoration: const InputDecoration(
                    labelText: 'Mobile Number',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your mobile number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: widget.isSaving ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: widget.isSaving
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Text('Complete Profile'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

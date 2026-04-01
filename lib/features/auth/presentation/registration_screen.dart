import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
    required this.onLogin,
    required this.onBack,
  });

  final bool isLoading;
  final String? errorMessage;
  final Future<void> Function({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required bool isShopper,
  }) onSubmit;
  final VoidCallback onLogin;
  final VoidCallback onBack;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isShopper = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || widget.isLoading) return;

    await widget.onSubmit(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phoneNumber: _phoneController.text.trim(),
      password: _passwordController.text,
      isShopper: _isShopper,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFDEE8DC), Color(0xFFECEFEB)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),

                  // ── App icon ─────────────────────────────────────────
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.shopping_basket_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // ── Brand name ───────────────────────────────────────
                  Text(
                    'SwiftShopper',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // ── Heading ──────────────────────────────────────────
                  Text(
                    'Create Your\nAccount',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 36,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Subtitle ─────────────────────────────────────────
                  Text(
                    'Join the kinetic boutique of curated shopping.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Form card ─────────────────────────────────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.07),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Role toggle
                        Text(
                          'I AM A...',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _RoleToggle(
                          isShopper: _isShopper,
                          onChanged: (v) => setState(() => _isShopper = v),
                        ),
                        const SizedBox(height: 16),

                        // Full name
                        _SignupField(
                          label: 'FULL NAME',
                          controller: _fullNameController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.name,
                          hint: 'Adewale Johnson',
                          prefix: Icons.person_outline_rounded,
                          validator: (v) =>
                              (v ?? '').trim().isEmpty
                                  ? 'Full name is required'
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        // Email
                        _SignupField(
                          label: 'EMAIL ADDRESS',
                          controller: _emailController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.emailAddress,
                          hint: 'example@swiftshopper.ng',
                          prefix: Icons.mail_outline_rounded,
                          validator: (v) {
                            final input = (v ?? '').trim();
                            if (input.isEmpty || !input.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),

                        // Phone number
                        _SignupField(
                          label: 'PHONE NUMBER',
                          controller: _phoneController,
                          textInputAction: TextInputAction.next,
                          keyboardType: TextInputType.phone,
                          hint: '+234 800 000 0000',
                          prefix: Icons.phone_outlined,
                          validator: (v) =>
                              (v ?? '').trim().isEmpty
                                  ? 'Phone number is required'
                                  : null,
                        ),
                        const SizedBox(height: 14),

                        // Password
                        _SignupField(
                          label: 'PASSWORD',
                          controller: _passwordController,
                          textInputAction: TextInputAction.done,
                          keyboardType: TextInputType.visiblePassword,
                          hint: '••••••••',
                          prefix: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          suffix: GestureDetector(
                            onTap: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            child: Icon(
                              _obscurePassword
                                  ? Icons.remove_red_eye_outlined
                                  : Icons.visibility_off_outlined,
                              color: AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          validator: (v) =>
                              (v ?? '').length < 6
                                  ? 'Password must be at least 6 characters'
                                  : null,
                          onFieldSubmitted: (_) => _submit(),
                        ),

                        // Error message
                        if (widget.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],

                        const SizedBox(height: 20),

                        // Create Account button
                        SizedBox(
                          height: 56,
                          child: FilledButton(
                            onPressed: widget.isLoading ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: AppColors.primary
                                  .withValues(alpha: 0.55),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: Text(
                              widget.isLoading
                                  ? 'Creating account...'
                                  : 'Create Account',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Terms
                        Text.rich(
                          TextSpan(
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'By signing up, you agree to our ',
                              ),
                              TextSpan(
                                text: 'Terms',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const TextSpan(text: ' and\n'),
                              TextSpan(
                                text: 'Privacy Policy.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Already have an account
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: widget.onLogin,
                        child: Text(
                          'Login',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Role toggle
// ---------------------------------------------------------------------------
class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.isShopper, required this.onChanged});

  final bool isShopper;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3F1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleOption(
              label: 'Customer',
              selected: !isShopper,
              onTap: () => onChanged(false),
            ),
          ),
          Expanded(
            child: _RoleOption(
              label: 'Shopper',
              selected: isShopper,
              onTap: () => onChanged(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  const _RoleOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Signup field
// ---------------------------------------------------------------------------
class _SignupField extends StatelessWidget {
  const _SignupField({
    required this.label,
    required this.controller,
    required this.textInputAction,
    required this.keyboardType,
    required this.hint,
    required this.prefix,
    required this.validator,
    this.obscureText = false,
    this.suffix,
    this.onFieldSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final TextInputAction textInputAction;
  final TextInputType keyboardType;
  final String hint;
  final IconData prefix;
  final String? Function(String?) validator;
  final bool obscureText;
  final Widget? suffix;
  final ValueChanged<String>? onFieldSubmitted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          textInputAction: textInputAction,
          keyboardType: keyboardType,
          obscureText: obscureText,
          validator: validator,
          onFieldSubmitted: onFieldSubmitted,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary.withValues(alpha: 0.4),
            ),
            filled: true,
            fillColor: const Color(0xFFF2F3F1),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 16,
            ),
            prefixIcon: Icon(
              prefix,
              color: AppColors.textSecondary,
              size: 20,
            ),
            suffixIcon: suffix != null
                ? Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: suffix,
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.danger),
            ),
          ),
        ),
      ],
    );
  }
}

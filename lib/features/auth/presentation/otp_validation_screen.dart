import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class OtpValidationScreen extends StatefulWidget {
  const OtpValidationScreen({
    super.key,
    required this.email,
    required this.expiresAt,
    required this.isLoading,
    required this.errorMessage,
    required this.onSubmit,
    required this.onResend,
    required this.onBack,
    this.developmentOtpCode,
  });

  final String email;
  final DateTime expiresAt;
  final bool isLoading;
  final String? errorMessage;
  final String? developmentOtpCode;
  final Future<void> Function(String otpCode) onSubmit;
  final Future<void> Function() onResend;
  final VoidCallback onBack;

  @override
  State<OtpValidationScreen> createState() => _OtpValidationScreenState();
}

class _OtpValidationScreenState extends State<OtpValidationScreen> {
  static const int _otpLength = 4;
  static const int _fallbackResendSeconds = 60;

  String _otpCode = '';
  int _secondsRemaining = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _resetCountdownFromExpiry();
  }

  @override
  void didUpdateWidget(covariant OtpValidationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _resetCountdownFromExpiry();
    }
  }

  void _resetCountdownFromExpiry() {
    _countdownTimer?.cancel();
    final diff = widget.expiresAt.difference(DateTime.now()).inSeconds;
    _secondsRemaining = diff > 0 ? diff : 0;
    if (_secondsRemaining <= 0) {
      setState(() {});
      return;
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsRemaining <= 1) {
        setState(() => _secondsRemaining = 0);
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  void _appendDigit(String digit) {
    if (_otpCode.length >= _otpLength || widget.isLoading) return;
    setState(() => _otpCode += digit);
  }

  void _removeLastDigit() {
    if (_otpCode.isEmpty || widget.isLoading) return;
    setState(() => _otpCode = _otpCode.substring(0, _otpCode.length - 1));
  }

  Future<void> _resendCode() async {
    if (_secondsRemaining > 0 || widget.isLoading) return;
    await widget.onResend();
    if (!mounted) return;
    setState(() {
      _otpCode = '';
      _secondsRemaining = _fallbackResendSeconds;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_secondsRemaining <= 1) {
        setState(() => _secondsRemaining = 0);
        timer.cancel();
        return;
      }
      setState(() => _secondsRemaining -= 1);
    });
  }

  Future<void> _submit() async {
    if (_otpCode.length != _otpLength || widget.isLoading) return;
    await widget.onSubmit(_otpCode);
  }

  String _formatCountdown(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F1),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                  Text(
                    'Verification',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ── Content ──────────────────────────────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Heading
                    Text(
                      'Verify Your Number',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Subtitle
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                        children: [
                          const TextSpan(
                            text: 'Enter the 4-digit code sent to ',
                          ),
                          TextSpan(
                            text: widget.email,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 36),

                    // OTP circles
                    Row(
                      children: List.generate(_otpLength, (i) {
                        final filled = i < _otpCode.length;
                        final digit = filled ? _otpCode[i] : '–';
                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(
                              right: i == _otpLength - 1 ? 0 : 14,
                            ),
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFFE4E6E3),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              digit,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: filled
                                    ? AppColors.textPrimary
                                    : const Color(0xFFABADAA),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 32),

                    // Resend countdown pill
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                children: [
                                  const TextSpan(text: 'Resend code in '),
                                  TextSpan(
                                    text: _formatCountdown(_secondsRemaining),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Resend code text
                    Center(
                      child: GestureDetector(
                        onTap: _secondsRemaining == 0 && !widget.isLoading
                            ? _resendCode
                            : null,
                        child: Text(
                          'RESEND CODE',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: _secondsRemaining == 0
                                ? AppColors.primary
                                : AppColors.textSecondary
                                    .withValues(alpha: 0.4),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // Error
                    if (widget.errorMessage != null) ...[
                      const SizedBox(height: 10),
                      Center(
                        child: Text(
                          widget.errorMessage!,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.danger,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Verify & Continue button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: FilledButton(
                        onPressed:
                            _otpCode.length == _otpLength && !widget.isLoading
                                ? _submit
                                : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary
                              .withValues(alpha: 0.45),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isLoading
                                  ? 'Verifying...'
                                  : 'Verify & Continue',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (!widget.isLoading) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Numeric pad ───────────────────────────────────────────────
            _OtpNumericPad(
              enabled: !widget.isLoading,
              onDigitTap: _appendDigit,
              onBackspace: _removeLastDigit,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Numeric pad
// ---------------------------------------------------------------------------
class _OtpNumericPad extends StatelessWidget {
  const _OtpNumericPad({
    required this.enabled,
    required this.onDigitTap,
    required this.onBackspace,
  });

  final bool enabled;
  final ValueChanged<String> onDigitTap;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFFE8EAE7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 4,
          crossAxisSpacing: 0,
          childAspectRatio: 2.0,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];
          if (key.isEmpty) return const SizedBox.shrink();

          final isBackspace = key == '⌫';

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: !enabled
                ? null
                : () => isBackspace ? onBackspace() : onDigitTap(key),
            child: Center(
              child: isBackspace
                  ? Icon(
                      Icons.backspace_rounded,
                      size: 28,
                      color: enabled
                          ? AppColors.textPrimary
                          : AppColors.textSecondary.withValues(alpha: 0.35),
                    )
                  : Text(
                      key,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: enabled
                            ? AppColors.textPrimary
                            : AppColors.textSecondary.withValues(alpha: 0.35),
                        fontWeight: FontWeight.w400,
                        fontSize: 30,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'otp_validation_screen.dart';
import 'registration_screen.dart';

class AuthFlowScreen extends ConsumerWidget {
  const AuthFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    return switch (authState.view) {
      AuthView.onboarding => OnboardingScreen(
        onLogin: notifier.showLogin,
        onRegister: notifier.showRegister,
      ),
      AuthView.login => LoginScreen(
        isLoading: authState.isLoading,
        errorMessage: authState.errorMessage,
        onSubmit: (emailOrPhone, password) {
          return notifier.login(emailOrPhone: emailOrPhone, password: password);
        },
        onCreateAccount: notifier.showRegister,
        onBack: notifier.showOnboarding,
      ),
      AuthView.register => RegistrationScreen(
        isLoading: authState.isLoading,
        errorMessage: authState.errorMessage,
        onSubmit: ({
          required fullName,
          required email,
          required phoneNumber,
          required password,
          required isShopper,
        }) {
          return notifier.register(
            fullName: fullName,
            email: email,
            phoneNumber: phoneNumber,
            password: password,
            isShopper: isShopper,
          );
        },
        onLogin: notifier.showLogin,
        onBack: notifier.showOnboarding,
      ),
      AuthView.otp => OtpValidationScreen(
        email: authState.pendingOtpChallenge?.email ?? '',
        expiresAt:
            authState.pendingOtpChallenge?.expiresAt ??
            DateTime.now().add(const Duration(minutes: 10)),
        developmentOtpCode: authState.pendingOtpChallenge?.developmentOtpCode,
        isLoading: authState.isLoading,
        errorMessage: authState.errorMessage,
        onSubmit: (otpCode) => notifier.verifyOtp(otpCode: otpCode),
        onResend: notifier.resendOtp,
        onBack: notifier.showRegister,
      ),
    };
  }
}

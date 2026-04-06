import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'onboarding_screen.dart';
import 'otp_validation_screen.dart';
import 'registration_screen.dart';

class AuthFlowScreen extends ConsumerStatefulWidget {
  const AuthFlowScreen({super.key});

  @override
  ConsumerState<AuthFlowScreen> createState() => _AuthFlowScreenState();
}

class _AuthFlowScreenState extends ConsumerState<AuthFlowScreen> {
  AuthView _lastView = AuthView.onboarding;
  bool _isForward = true;
  ProviderSubscription<AuthView>? _viewSubscription;

  int _viewOrder(AuthView view) {
    return switch (view) {
      AuthView.onboarding => 0,
      AuthView.login => 1,
      AuthView.register => 2,
      AuthView.otp => 3,
    };
  }

  @override
  void initState() {
    super.initState();
    _viewSubscription = ref.listenManual<AuthView>(
      authProvider.select((state) => state.view),
      (_, next) {
        if (!mounted) return;
        setState(() {
          _isForward = _viewOrder(next) >= _viewOrder(_lastView);
          _lastView = next;
        });
      },
    );
  }

  @override
  void dispose() {
    _viewSubscription?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final notifier = ref.read(authProvider.notifier);

    final child = switch (authState.view) {
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

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (widget, animation) {
        final beginOffset = Offset(_isForward ? 0.14 : -0.14, 0);
        final slide = Tween<Offset>(
          begin: beginOffset,
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: slide,
            child: widget,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey(authState.view),
        child: child,
      ),
    );
  }
}

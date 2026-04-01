import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_client.dart';
import '../../shared/data/swift_shopper_repository.dart';
import '../models/auth_user.dart';
import '../models/signup_otp_challenge.dart';

enum AuthView { onboarding, login, register, otp }

class AuthState {
  const AuthState({
    required this.view,
    required this.isLoading,
    required this.isInitialized,
    required this.isAuthenticated,
    this.user,
    this.pendingOtpChallenge,
    this.errorMessage,
  });

  final AuthView view;
  final bool isLoading;
  final bool isInitialized;
  final bool isAuthenticated;
  final AuthUser? user;
  final SignupOtpChallenge? pendingOtpChallenge;
  final String? errorMessage;

  AuthState copyWith({
    AuthView? view,
    bool? isLoading,
    bool? isInitialized,
    bool? isAuthenticated,
    AuthUser? user,
    SignupOtpChallenge? pendingOtpChallenge,
    bool clearUser = false,
    bool clearPendingOtp = false,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AuthState(
      view: view ?? this.view,
      isLoading: isLoading ?? this.isLoading,
      isInitialized: isInitialized ?? this.isInitialized,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : user ?? this.user,
      pendingOtpChallenge:
          clearPendingOtp
              ? null
              : pendingOtpChallenge ?? this.pendingOtpChallenge,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  static const String _sessionKey = 'auth_user_session';

  @override
  AuthState build() {
    unawaited(_restoreSession());

    return const AuthState(
      view: AuthView.onboarding,
      isLoading: true,
      isInitialized: false,
      isAuthenticated: false,
    );
  }

  void showOnboarding() {
    state = state.copyWith(
      view: AuthView.onboarding,
      clearError: true,
      clearPendingOtp: true,
      isLoading: false,
    );
  }

  void showLogin() {
    state = state.copyWith(
      view: AuthView.login,
      clearError: true,
      clearPendingOtp: true,
    );
  }

  void showRegister() {
    state = state.copyWith(
      view: AuthView.register,
      clearError: true,
      clearPendingOtp: true,
    );
  }

  Future<void> login({
    required String emailOrPhone,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final user = await repository.login(
        emailOrPhone: emailOrPhone,
        password: password,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        isInitialized: true,
      );

      ApiClient.setAuthToken(user.accessToken);
      await _persistUser(user);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: _errorMessageFrom(error),
      );
    }
  }

  Future<void> register({
    required String fullName,
    required String email,
    required String phoneNumber,
    required String password,
    required bool isShopper,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final challenge = await repository.register(
        fullName: fullName,
        email: email,
        phoneNumber: phoneNumber,
        password: password,
        asShopper: isShopper,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: false,
        pendingOtpChallenge: challenge,
        view: AuthView.otp,
        isInitialized: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: _errorMessageFrom(error),
      );
    }
  }

  Future<void> verifyOtp({required String otpCode}) async {
    final challenge = state.pendingOtpChallenge;
    if (challenge == null) {
      state = state.copyWith(errorMessage: 'No pending OTP verification.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final user = await repository.verifySignupOtp(
        userId: challenge.userId,
        otpCode: otpCode,
      );

      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        user: user,
        clearPendingOtp: true,
        isInitialized: true,
      );

      ApiClient.setAuthToken(user.accessToken);
      await _persistUser(user);
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: _errorMessageFrom(error),
      );
    }
  }

  Future<void> resendOtp() async {
    final challenge = state.pendingOtpChallenge;
    if (challenge == null) {
      state = state.copyWith(errorMessage: 'No pending OTP verification.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(swiftShopperRepositoryProvider);
      final refreshedChallenge = await repository.resendSignupOtp(
        userId: challenge.userId,
      );

      state = state.copyWith(
        isLoading: false,
        pendingOtpChallenge: refreshedChallenge,
        view: AuthView.otp,
        isInitialized: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        errorMessage: _errorMessageFrom(error),
      );
    }
  }

  Future<void> updateAvatarUrl(String avatarUrl) async {
    final user = state.user;
    if (user == null) return;

    final updated = user.copyWith(avatarUrl: avatarUrl);
    state = state.copyWith(user: updated);
    await _persistUser(updated);
  }

  Future<void> logout() async {
    ApiClient.setAuthToken(null);

    state = const AuthState(
      view: AuthView.onboarding,
      isLoading: false,
      isInitialized: true,
      isAuthenticated: false,
      pendingOtpChallenge: null,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> _restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionKey);

      if (raw == null || raw.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isAuthenticated: false,
          clearUser: true,
          view: AuthView.onboarding,
          clearError: true,
        );
        ApiClient.setAuthToken(null);
        return;
      }

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isAuthenticated: false,
          clearUser: true,
          view: AuthView.onboarding,
          clearError: true,
        );
        await prefs.remove(_sessionKey);
        ApiClient.setAuthToken(null);
        return;
      }

      final user = AuthUser.fromJson(decoded);

      if (user.accessToken == null || user.accessToken!.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isAuthenticated: false,
          clearUser: true,
          view: AuthView.onboarding,
          clearError: true,
        );
        await prefs.remove(_sessionKey);
        ApiClient.setAuthToken(null);
        return;
      }

      final expiresAt = user.tokenExpiresAt?.toUtc();
      if (expiresAt == null || DateTime.now().toUtc().isAfter(expiresAt)) {
        state = state.copyWith(
          isLoading: false,
          isInitialized: true,
          isAuthenticated: false,
          clearUser: true,
          view: AuthView.onboarding,
          clearError: true,
        );
        await prefs.remove(_sessionKey);
        ApiClient.setAuthToken(null);
        return;
      }

      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        isAuthenticated: true,
        user: user,
        clearError: true,
      );
      ApiClient.setAuthToken(user.accessToken);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        isInitialized: true,
        isAuthenticated: false,
        clearUser: true,
        view: AuthView.onboarding,
        clearError: true,
      );
      ApiClient.setAuthToken(null);
    }
  }

  Future<void> _persistUser(AuthUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(user.toJson()));
  }

  String _errorMessageFrom(Object error) {
    final message = error.toString();

    if (message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Connection closed') ||
        message.contains('ClientException') ||
        message.contains('TimeoutException')) {
      return 'Cannot reach server. Check API URL and make sure the backend is running.';
    }

    if (message.contains('401')) {
      return 'Invalid credentials.';
    }

    if (message.contains('409')) {
      return 'This email or phone number already exists.';
    }

    if (message.contains('resend OTP') ||
        message.contains('Unable to resend OTP')) {
      return 'Unable to resend OTP right now. Please register again.';
    }

    if (message.contains('Invalid or expired OTP') || message.contains('400')) {
      return 'Invalid or expired OTP code.';
    }

    return 'Something went wrong. Please try again.';
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);

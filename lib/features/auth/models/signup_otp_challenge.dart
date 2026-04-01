class SignupOtpChallenge {
  const SignupOtpChallenge({
    required this.userId,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.expiresAt,
    this.developmentOtpCode,
  });

  final String userId;
  final String email;
  final String phoneNumber;
  final int role;
  final DateTime expiresAt;
  final String? developmentOtpCode;

  factory SignupOtpChallenge.fromJson(Map<String, dynamic> json) {
    return SignupOtpChallenge(
      userId: json['userId']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phoneNumber']?.toString() ?? '',
      role:
          json['role'] is int
              ? json['role'] as int
              : int.tryParse(json['role']?.toString() ?? '0') ?? 0,
      expiresAt:
          DateTime.tryParse(json['expiresAt']?.toString() ?? '') ??
          DateTime.now().add(const Duration(minutes: 10)),
      developmentOtpCode: json['developmentOtpCode']?.toString(),
    );
  }
}

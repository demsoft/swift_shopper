class AuthUser {
  const AuthUser({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.role,
    required this.createdAt,
    this.accessToken,
    this.tokenExpiresAt,
    this.avatarUrl,
  });

  final String userId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final int role;
  final DateTime createdAt;
  final String? accessToken;
  final DateTime? tokenExpiresAt;
  final String? avatarUrl;

  bool get isShopper => role == 1;

  AuthUser copyWith({String? avatarUrl}) {
    return AuthUser(
      userId: userId,
      fullName: fullName,
      email: email,
      phoneNumber: phoneNumber,
      role: role,
      createdAt: createdAt,
      accessToken: accessToken,
      tokenExpiresAt: tokenExpiresAt,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    final userJson =
        json['user'] is Map<String, dynamic>
            ? json['user'] as Map<String, dynamic>
            : json;

    return AuthUser(
      userId: userJson['userId']?.toString() ?? '',
      fullName: userJson['fullName']?.toString() ?? '',
      email: userJson['email']?.toString() ?? '',
      phoneNumber: userJson['phoneNumber']?.toString() ?? '',
      role:
          userJson['role'] is int
              ? userJson['role'] as int
              : int.tryParse(userJson['role']?.toString() ?? '0') ?? 0,
      createdAt:
          DateTime.tryParse(userJson['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      accessToken: json['accessToken']?.toString(),
      tokenExpiresAt: DateTime.tryParse(json['expiresAt']?.toString() ?? ''),
      avatarUrl: userJson['avatarUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'accessToken': accessToken,
      'expiresAt': tokenExpiresAt?.toIso8601String(),
      'avatarUrl': avatarUrl,
    };
  }
}

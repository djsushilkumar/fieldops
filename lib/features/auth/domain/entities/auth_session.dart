import 'user_entity.dart';
import '../../../organization/domain/entities/organization_entity.dart';

class AuthSession {
  final UserEntity user;
  final OrganizationEntity organization;
  final String? accessToken;
  final DateTime? expiresAt;

  const AuthSession({
    required this.user,
    required this.organization,
    this.accessToken,
    this.expiresAt,
  });

  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  AuthSession copyWith({
    UserEntity? user,
    OrganizationEntity? organization,
    String? accessToken,
    DateTime? expiresAt,
  }) {
    return AuthSession(
      user: user ?? this.user,
      organization: organization ?? this.organization,
      accessToken: accessToken ?? this.accessToken,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }
}

import '../entities/auth_session.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Stream<UserEntity?> get authStateChanges;
  Future<AuthSession?> getCurrentSession();
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
  Future<UserEntity> getCurrentUser();
  Future<UserEntity> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  });
}

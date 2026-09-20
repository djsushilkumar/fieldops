import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository repository;

  SignInUseCase(this.repository);

  Future<AuthSession> execute({
    required String email,
    required String password,
  }) async {
    final cleanEmail = email.trim();
    if (cleanEmail.isEmpty) {
      throw Exception('Email cannot be empty');
    }
    if (!cleanEmail.contains('@')) {
      throw Exception('Please enter a valid email address');
    }
    if (password.trim().isEmpty) {
      throw Exception('Password cannot be empty');
    }

    return await repository.signInWithEmailPassword(
      email: cleanEmail,
      password: password,
    );
  }
}

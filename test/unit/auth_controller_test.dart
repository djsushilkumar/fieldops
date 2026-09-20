import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:field_ops/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:field_ops/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';
import 'package:field_ops/features/auth/domain/usecases/reset_password_use_case.dart';
import 'package:field_ops/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:field_ops/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:field_ops/features/auth/presentation/controllers/auth_controller.dart';

void main() {
  group('AuthNotifier Tests', () {
    late MockAuthRemoteDataSource remoteDataSource;
    late AuthLocalDataSource localDataSource;
    late AuthRepositoryImpl repository;
    late SignInUseCase signInUseCase;
    late SignOutUseCase signOutUseCase;
    late ResetPasswordUseCase resetPasswordUseCase;
    late AuthNotifier authNotifier;

    setUp(() {
      remoteDataSource = MockAuthRemoteDataSource();
      localDataSource = AuthLocalDataSourceImpl();
      repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      signInUseCase = SignInUseCase(repository);
      signOutUseCase = SignOutUseCase(repository);
      resetPasswordUseCase = ResetPasswordUseCase(repository);

      authNotifier = AuthNotifier(
        signInUseCase: signInUseCase,
        signOutUseCase: signOutUseCase,
        resetPasswordUseCase: resetPasswordUseCase,
        repository: repository,
      );
    });

    tearDown(() {
      authNotifier.dispose();
      repository.dispose();
      remoteDataSource.dispose();
    });

    test('Initial check starts session check and sets unauthenticated if no cached user', () async {
      await authNotifier.checkInitialSession();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(authNotifier.state.user, isNull);
    });

    test('signIn with valid employee credentials sets authenticated state', () async {
      final success = await authNotifier.signIn(
        email: 'employee@fieldops.com',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(authNotifier.state.status, equals(AuthStatus.authenticated));
      expect(authNotifier.state.user?.role, equals(UserRole.employee));
      expect(authNotifier.state.organization?.name, equals('Apex Field Services Ltd'));
    });

    test('signIn with wrong credentials sets error state', () async {
      final success = await authNotifier.signIn(
        email: 'employee@fieldops.com',
        password: 'WRONG',
      );

      expect(success, isFalse);
      expect(authNotifier.state.status, equals(AuthStatus.error));
      expect(authNotifier.state.errorMessage, isNotNull);
    });

    test('signOut resets state to unauthenticated', () async {
      await authNotifier.signIn(
        email: 'manager@fieldops.com',
        password: 'password123',
      );
      expect(authNotifier.state.isAuthenticated, isTrue);

      await authNotifier.signOut();
      expect(authNotifier.state.status, equals(AuthStatus.unauthenticated));
      expect(authNotifier.state.user, isNull);
    });
  });
}

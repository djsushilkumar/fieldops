import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/core/errors/failures.dart';
import 'package:field_ops/features/auth/data/datasources/auth_local_datasource.dart';
import 'package:field_ops/features/auth/data/datasources/mock_auth_remote_datasource.dart';
import 'package:field_ops/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:field_ops/features/auth/domain/entities/user_role.dart';

void main() {
  group('AuthRepositoryImpl Tests', () {
    late MockAuthRemoteDataSource remoteDataSource;
    late AuthLocalDataSource localDataSource;
    late AuthRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockAuthRemoteDataSource();
      localDataSource = AuthLocalDataSourceImpl();
      repository = AuthRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
    });

    tearDown(() {
      repository.dispose();
      remoteDataSource.dispose();
    });

    test('Successful sign in returns AuthSession and caches locally', () async {
      final session = await repository.signInWithEmailPassword(
        email: 'admin@fieldops.com',
        password: 'password123',
      );

      expect(session.user.email, equals('admin@fieldops.com'));
      expect(session.user.role, equals(UserRole.admin));
      expect(session.organization.name, equals('Apex Field Services Ltd'));
      expect(session.accessToken, isNotNull);

      // Verify cached in local data source
      final cachedUser = await localDataSource.getCachedUser();
      expect(cachedUser?.email, equals('admin@fieldops.com'));

      final cachedOrg = await localDataSource.getCachedOrganization();
      expect(cachedOrg?.name, equals('Apex Field Services Ltd'));
    });

    test('Failed sign in with wrong password throws AuthFailure', () async {
      expect(
        () => repository.signInWithEmailPassword(
          email: 'admin@fieldops.com',
          password: 'WRONG_PASSWORD',
        ),
        throwsA(isA<AuthFailure>()),
      );
    });

    test('Sign out clears session locally', () async {
      await repository.signInWithEmailPassword(
        email: 'employee@fieldops.com',
        password: 'password123',
      );

      await repository.signOut();

      final cachedUser = await localDataSource.getCachedUser();
      expect(cachedUser, isNull);

      final session = await repository.getCurrentSession();
      expect(session, isNull);
    });

    test('Password reset request succeeds for existing user', () async {
      await expectLater(
        repository.sendPasswordResetEmail(email: 'manager@fieldops.com'),
        completes,
      );
    });

    test('Password reset request fails for non-existent user', () async {
      expect(
        () => repository.sendPasswordResetEmail(email: 'nonexistent@fieldops.com'),
        throwsA(isA<AuthFailure>()),
      );
    });
  });
}

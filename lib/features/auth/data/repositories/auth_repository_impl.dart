import 'dart:async';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../organization/data/models/organization_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;

  final _userStreamController = StreamController<UserEntity?>.broadcast();
  StreamSubscription? _remoteSub;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  }) {
    _initAuthListener();
  }

  void _initAuthListener() {
    _remoteSub = remoteDataSource.authUserIdChanges.listen((userId) async {
      if (_userStreamController.isClosed) return;
      if (userId == null) {
        await localDataSource.clearSession();
        if (!_userStreamController.isClosed) {
          _userStreamController.add(null);
        }
      } else {
        try {
          final profile = await remoteDataSource.getUserProfile(userId);
          final org = await remoteDataSource.getOrganization(profile.organizationId);
          await localDataSource.cacheSession(user: profile, organization: org);
          if (!_userStreamController.isClosed) {
            _userStreamController.add(profile.toEntity());
          }
        } catch (_) {
          // If offline, fallback to cached user
          final cached = await localDataSource.getCachedUser();
          if (!_userStreamController.isClosed) {
            _userStreamController.add(cached?.toEntity());
          }
        }
      }
    });
  }

  @override
  Stream<UserEntity?> get authStateChanges => _userStreamController.stream;

  @override
  Future<AuthSession?> getCurrentSession() async {
    try {
      final cachedUser = await localDataSource.getCachedUser();
      final cachedOrg = await localDataSource.getCachedOrganization();
      final cachedToken = await localDataSource.getCachedToken();

      if (cachedUser != null && cachedOrg != null) {
        return AuthSession(
          user: cachedUser.toEntity(),
          organization: cachedOrg.toEntity(),
          accessToken: cachedToken,
        );
      }
      return null;
    } catch (e) {
      throw const AuthFailure('Failed to retrieve current session');
    }
  }

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final result = await remoteDataSource.signIn(
        email: email,
        password: password,
      );

      // Cache session locally for offline resilience
      await localDataSource.cacheSession(
        user: result.user,
        organization: result.org,
        token: result.token,
      );

      final userEntity = result.user.toEntity();
      if (!_userStreamController.isClosed) {
        _userStreamController.add(userEntity);
      }

      return AuthSession(
        user: userEntity,
        organization: result.org.toEntity(),
        accessToken: result.token,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
    } on AuthException catch (e) {
      throw AuthFailure(e.message, code: e.code);
    } catch (e) {
      throw ServerFailure(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
      await localDataSource.clearSession();
      if (!_userStreamController.isClosed) {
        _userStreamController.add(null);
      }
    } catch (e) {
      // Still ensure local state is cleared
      await localDataSource.clearSession();
      if (!_userStreamController.isClosed) {
        _userStreamController.add(null);
      }
    }
  }

  @override
  Future<UserEntity> getCurrentUser() async {
    try {
      final cached = await localDataSource.getCachedUser();
      if (cached != null) {
        return cached.toEntity();
      }
      throw const NotFoundFailure('No authenticated user found');
    } catch (e) {
      if (e is Failure) rethrow;
      throw AuthFailure(e.toString());
    }
  }

  @override
  Future<UserEntity> updateProfile({
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final cached = await localDataSource.getCachedUser();
      if (cached == null) {
        throw const NotFoundFailure('No authenticated user session');
      }

      final updatedModel = await remoteDataSource.updateProfile(
        userId: cached.id,
        name: name,
        phone: phone,
        avatarUrl: avatarUrl,
      );

      final cachedOrg = await localDataSource.getCachedOrganization() ??
          OrganizationModel(
            id: updatedModel.organizationId,
            name: 'Organization',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      await localDataSource.cacheSession(
        user: updatedModel,
        organization: cachedOrg,
      );

      final entity = updatedModel.toEntity();
      if (!_userStreamController.isClosed) {
        _userStreamController.add(entity);
      }
      return entity;
    } on ServerException catch (e) {
      throw ServerFailure(e.message, e.code);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  void dispose() {
    _remoteSub?.cancel();
    _userStreamController.close();
  }
}

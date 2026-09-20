import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../../organization/data/models/organization_model.dart';

abstract class AuthRemoteDataSource {
  Stream<String?> get authUserIdChanges;
  Future<({UserModel user, OrganizationModel org, String token})> signIn({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
  Future<UserModel> getUserProfile(String userId);
  Future<OrganizationModel> getOrganization(String orgId);
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  });
}

class SupabaseAuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final supa.SupabaseClient client;

  SupabaseAuthRemoteDataSourceImpl(this.client);

  @override
  Stream<String?> get authUserIdChanges =>
      client.auth.onAuthStateChange.map((event) => event.session?.user.id);

  @override
  Future<({UserModel user, OrganizationModel org, String token})> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      final authUser = response.user;

      if (session == null || authUser == null) {
        throw const AuthException('Invalid email or password');
      }

      final userProfile = await getUserProfile(authUser.id);
      final organization = await getOrganization(userProfile.organizationId);

      return (
        user: userProfile,
        org: organization,
        token: session.accessToken,
      );
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await client.auth.resetPasswordForEmail(email);
    } on supa.AuthException catch (e) {
      throw AuthException(e.message, code: e.statusCode);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final data = await client
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to load user profile: ${e.toString()}');
    }
  }

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    try {
      final data = await client
          .from('organizations')
          .select()
          .eq('id', orgId)
          .single();
      return OrganizationModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to load organization: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phone != null) updates['phone'] = phone;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      updates['updated_at'] = DateTime.now().toIso8601String();

      final data = await client
          .from('users')
          .update(updates)
          .eq('id', userId)
          .select()
          .single();
      return UserModel.fromJson(data);
    } catch (e) {
      throw ServerException('Failed to update profile: ${e.toString()}');
    }
  }
}

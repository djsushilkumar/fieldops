import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';
import '../../../organization/data/models/organization_model.dart';

abstract class AuthLocalDataSource {
  Future<UserModel?> getCachedUser();
  Future<OrganizationModel?> getCachedOrganization();
  Future<String?> getCachedToken();
  Future<void> cacheSession({
    required UserModel user,
    required OrganizationModel organization,
    String? token,
  });
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  UserModel? _memUser;
  OrganizationModel? _memOrg;
  String? _memToken;

  @override
  Future<UserModel?> getCachedUser() async {
    if (_memUser != null) return _memUser;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString(AppConstants.prefKeyUser);
      if (userStr != null) {
        final Map<String, dynamic> map = jsonDecode(userStr);
        _memUser = UserModel.fromJson(map);
        return _memUser;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<OrganizationModel?> getCachedOrganization() async {
    if (_memOrg != null) return _memOrg;
    try {
      final prefs = await SharedPreferences.getInstance();
      final orgStr = prefs.getString(AppConstants.prefKeyOrg);
      if (orgStr != null) {
        final Map<String, dynamic> map = jsonDecode(orgStr);
        _memOrg = OrganizationModel.fromJson(map);
        return _memOrg;
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<String?> getCachedToken() async {
    if (_memToken != null) return _memToken;
    try {
      final prefs = await SharedPreferences.getInstance();
      _memToken = prefs.getString(AppConstants.prefKeyAuthToken);
      return _memToken;
    } catch (_) {}
    return null;
  }

  @override
  Future<void> cacheSession({
    required UserModel user,
    required OrganizationModel organization,
    String? token,
  }) async {
    _memUser = user;
    _memOrg = organization;
    _memToken = token;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.prefKeyUser, jsonEncode(user.toJson()));
      await prefs.setString(AppConstants.prefKeyOrg, jsonEncode(organization.toJson()));
      if (token != null) {
        await prefs.setString(AppConstants.prefKeyAuthToken, token);
      }
    } catch (_) {}
  }

  @override
  Future<void> clearSession() async {
    _memUser = null;
    _memOrg = null;
    _memToken = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.prefKeyUser);
      await prefs.remove(AppConstants.prefKeyOrg);
      await prefs.remove(AppConstants.prefKeyAuthToken);
    } catch (_) {}
  }
}

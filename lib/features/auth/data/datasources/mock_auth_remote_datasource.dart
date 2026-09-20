import 'dart:async';
import '../../../../core/errors/exceptions.dart';
import '../models/user_model.dart';
import '../../../organization/data/models/organization_model.dart';
import 'auth_remote_datasource.dart';

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final _authStreamController = StreamController<String?>.broadcast();
  String? _currentUserId;

  static final OrganizationModel mockOrg = OrganizationModel(
    id: 'org-acme-ops-001',
    name: 'Apex Field Services Ltd',
    timezone: 'America/New_York',
    currency: 'USD',
    createdAt: DateTime(2025, 1, 1),
    updatedAt: DateTime(2025, 1, 1),
  );

  static final Map<String, ({UserModel user, String password})> mockAccounts = {
    'admin@fieldops.com': (
      user: UserModel(
        id: 'usr-admin-001',
        organizationId: 'org-acme-ops-001',
        name: 'Sarah Connor (Owner/Admin)',
        email: 'admin@fieldops.com',
        phone: '+1 (555) 019-2834',
        role: 'admin',
        status: 'active',
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
      ),
      password: 'password123',
    ),
    'manager@fieldops.com': (
      user: UserModel(
        id: 'usr-manager-002',
        organizationId: 'org-acme-ops-001',
        name: 'Marcus Vance (Field Manager)',
        email: 'manager@fieldops.com',
        phone: '+1 (555) 014-9921',
        role: 'manager',
        status: 'active',
        createdAt: DateTime(2025, 1, 10),
        updatedAt: DateTime(2025, 1, 10),
      ),
      password: 'password123',
    ),
    'employee@fieldops.com': (
      user: UserModel(
        id: 'usr-emp-003',
        organizationId: 'org-acme-ops-001',
        name: 'David Miller (Technician)',
        email: 'employee@fieldops.com',
        phone: '+1 (555) 012-4488',
        role: 'employee',
        status: 'active',
        createdAt: DateTime(2025, 2, 1),
        updatedAt: DateTime(2025, 2, 1),
      ),
      password: 'password123',
    ),
  };

  late Map<String, UserModel> _users;

  MockAuthRemoteDataSource() {
    _users = {
      for (final entry in mockAccounts.entries) entry.value.user.id: entry.value.user,
    };
  }

  @override
  Stream<String?> get authUserIdChanges => _authStreamController.stream;

  @override
  Future<({UserModel user, OrganizationModel org, String token})> signIn({
    required String email,
    required String password,
  }) async {
    // Artificial latency to reflect realistic network behavior
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = email.trim().toLowerCase();
    final account = mockAccounts[normalizedEmail];

    if (account == null || account.password != password) {
      throw const AuthException('Invalid email or password');
    }

    _currentUserId = account.user.id;
    _authStreamController.add(_currentUserId);

    return (
      user: _users[account.user.id] ?? account.user,
      org: mockOrg,
      token: 'mock-jwt-token-for-${account.user.id}',
    );
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    await Future.delayed(const Duration(milliseconds: 250));
    final normalized = email.trim().toLowerCase();
    if (!mockAccounts.containsKey(normalized)) {
      throw const AuthException('No account found with this email address');
    }
  }

  @override
  Future<void> signOut() async {
    await Future.delayed(const Duration(milliseconds: 150));
    _currentUserId = null;
    _authStreamController.add(null);
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    final user = _users[userId];
    if (user == null) {
      throw ServerException('User $userId not found');
    }
    return user;
  }

  @override
  Future<OrganizationModel> getOrganization(String orgId) async {
    await Future.delayed(const Duration(milliseconds: 100));
    return mockOrg;
  }

  @override
  Future<UserModel> updateProfile({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final existing = _users[userId];
    if (existing == null) {
      throw ServerException('User $userId not found');
    }

    final updated = UserModel(
      id: existing.id,
      organizationId: existing.organizationId,
      name: name ?? existing.name,
      email: existing.email,
      phone: phone ?? existing.phone,
      role: existing.role,
      avatarUrl: avatarUrl ?? existing.avatarUrl,
      status: existing.status,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    _users[userId] = updated;
    return updated;
  }

  void dispose() {
    _authStreamController.close();
  }
}

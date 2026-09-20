import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/role_permission_entity.dart';
import '../../domain/usecases/manage_permissions_use_cases.dart';
import 'organization_settings_controller.dart';

// ============================================================================
// Providers
// ============================================================================

final getRolePermissionsUseCaseProvider = Provider<GetRolePermissionsUseCase>((ref) {
  return GetRolePermissionsUseCase(ref.watch(organizationRepositoryProvider));
});

final updateRolePermissionUseCaseProvider = Provider<UpdateRolePermissionUseCase>((ref) {
  return UpdateRolePermissionUseCase(ref.watch(organizationRepositoryProvider));
});

// ============================================================================
// State & Controller
// ============================================================================

class RolePermissionsState {
  final List<RolePermissionEntity> permissions;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const RolePermissionsState({
    this.permissions = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  RolePermissionEntity? forRole(UserRole role) {
    return permissions.cast<RolePermissionEntity?>().firstWhere(
          (p) => p?.role == role,
          orElse: () => null,
        );
  }

  RolePermissionsState copyWith({
    List<RolePermissionEntity>? permissions,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return RolePermissionsState(
      permissions: permissions ?? this.permissions,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage: successMessage ?? (clearMessages ? null : this.successMessage),
    );
  }
}

class RolePermissionsController extends StateNotifier<RolePermissionsState> {
  final GetRolePermissionsUseCase _getPermissionsUseCase;
  final UpdateRolePermissionUseCase _updatePermissionUseCase;
  final Ref _ref;

  RolePermissionsController({
    required GetRolePermissionsUseCase getPermissionsUseCase,
    required UpdateRolePermissionUseCase updatePermissionUseCase,
    required Ref ref,
  })  : _getPermissionsUseCase = getPermissionsUseCase,
        _updatePermissionUseCase = updatePermissionUseCase,
        _ref = ref,
        super(const RolePermissionsState()) {
    loadPermissions();
  }

  String _resolveOrgId() {
    final user = _ref.read(currentUserProvider);
    return user?.organizationId ?? 'org-acme-ops-001';
  }

  Future<void> loadPermissions() async {
    final orgId = _resolveOrgId();
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final list = await _getPermissionsUseCase(orgId);
      state = state.copyWith(
        isLoading: false,
        permissions: list,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load role permissions: $e',
      );
    }
  }

  void togglePermission({
    required UserRole role,
    required String permissionKey,
    required bool value,
  }) {
    final list = state.permissions.map((p) {
      if (p.role != role) return p;

      switch (permissionKey) {
        case 'canCreateTasks':
          return p.copyWith(canCreateTasks: value);
        case 'canManageCustomers':
          return p.copyWith(canManageCustomers: value);
        case 'canViewAllTeams':
          return p.copyWith(canViewAllTeams: value);
        case 'canExportReports':
          return p.copyWith(canExportReports: value);
        case 'canManageForms':
          return p.copyWith(canManageForms: value);
        case 'canManageUsers':
          return p.copyWith(canManageUsers: value);
        default:
          return p;
      }
    }).toList();

    state = state.copyWith(permissions: list);
  }

  Future<bool> savePermissions() async {
    final orgId = _resolveOrgId();
    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      for (final p in state.permissions) {
        await _updatePermissionUseCase(orgId: orgId, permission: p);
      }
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Role permissions saved successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save permissions: $e',
      );
      return false;
    }
  }

  void resetToDefaults() {
    state = state.copyWith(
      permissions: [
        RolePermissionEntity.defaultForRole(UserRole.owner),
        RolePermissionEntity.defaultForRole(UserRole.admin),
        RolePermissionEntity.defaultForRole(UserRole.manager),
        RolePermissionEntity.defaultForRole(UserRole.employee),
      ],
      clearMessages: true,
      successMessage: 'Reset to default permission matrix.',
    );
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final rolePermissionsControllerProvider =
    StateNotifierProvider<RolePermissionsController, RolePermissionsState>((ref) {
  return RolePermissionsController(
    getPermissionsUseCase: ref.watch(getRolePermissionsUseCaseProvider),
    updatePermissionUseCase: ref.watch(updateRolePermissionUseCaseProvider),
    ref: ref,
  );
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/organization_remote_datasource.dart';
import '../../data/repositories/organization_repository_impl.dart';
import '../../domain/entities/organization_entity.dart';
import '../../domain/repositories/organization_repository.dart';
import '../../domain/usecases/get_organization_use_case.dart';
import '../../domain/usecases/update_organization_settings_use_case.dart';

// ============================================================================
// Providers
// ============================================================================

final organizationRemoteDataSourceProvider = Provider<OrganizationRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseOrganizationRemoteDataSourceImpl(supabase);
  }
  return MockOrganizationRemoteDataSourceImpl();
});

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  return OrganizationRepositoryImpl(
    remoteDataSource: ref.watch(organizationRemoteDataSourceProvider),
  );
});

final getOrganizationUseCaseProvider = Provider<GetOrganizationUseCase>((ref) {
  return GetOrganizationUseCase(ref.watch(organizationRepositoryProvider));
});

final updateOrganizationSettingsUseCaseProvider = Provider<UpdateOrganizationSettingsUseCase>((ref) {
  return UpdateOrganizationSettingsUseCase(ref.watch(organizationRepositoryProvider));
});

// ============================================================================
// State & Controller
// ============================================================================

class OrganizationSettingsState {
  final OrganizationEntity? organization;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;
  final String? successMessage;

  const OrganizationSettingsState({
    this.organization,
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  OrganizationSettingsState copyWith({
    OrganizationEntity? organization,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return OrganizationSettingsState(
      organization: organization ?? this.organization,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? (clearMessages ? null : this.errorMessage),
      successMessage: successMessage ?? (clearMessages ? null : this.successMessage),
    );
  }
}

class OrganizationSettingsController extends StateNotifier<OrganizationSettingsState> {
  final GetOrganizationUseCase _getOrgUseCase;
  final UpdateOrganizationSettingsUseCase _updateOrgUseCase;
  final Ref _ref;

  OrganizationSettingsController({
    required GetOrganizationUseCase getOrgUseCase,
    required UpdateOrganizationSettingsUseCase updateOrgUseCase,
    required Ref ref,
  })  : _getOrgUseCase = getOrgUseCase,
        _updateOrgUseCase = updateOrgUseCase,
        _ref = ref,
        super(const OrganizationSettingsState()) {
    loadOrganization();
  }

  Future<void> loadOrganization() async {
    final user = _ref.read(currentUserProvider);
    final orgId = user?.organizationId ?? 'org-acme-ops-001';

    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final org = await _getOrgUseCase.execute(orgId);
      state = state.copyWith(isLoading: false, organization: org);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load organization settings: $e',
      );
    }
  }

  Future<bool> saveSettings({
    String? name,
    String? timezone,
    String? currency,
    String? industry,
    int? geofenceRadius,
    int? autoCheckoutHours,
    bool? requirePhoto,
    bool? requireGps,
  }) async {
    final current = state.organization;
    if (current == null) return false;

    state = state.copyWith(isSaving: true, clearMessages: true);
    try {
      final updated = await _updateOrgUseCase(
        orgId: current.id,
        name: name,
        timezone: timezone,
        currency: currency,
        industry: industry,
        geofenceDefaultRadius: geofenceRadius,
        autoCheckoutHours: autoCheckoutHours,
        requirePhotoOnCompletion: requirePhoto,
        requireGpsOnCheckin: requireGps,
      );

      state = state.copyWith(
        isSaving: false,
        organization: updated,
        successMessage: 'Organization settings updated successfully!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save settings: $e',
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearMessages: true);
  }
}

final organizationSettingsControllerProvider =
    StateNotifierProvider<OrganizationSettingsController, OrganizationSettingsState>((ref) {
  return OrganizationSettingsController(
    getOrgUseCase: ref.watch(getOrganizationUseCaseProvider),
    updateOrgUseCase: ref.watch(updateOrganizationSettingsUseCaseProvider),
    ref: ref,
  );
});

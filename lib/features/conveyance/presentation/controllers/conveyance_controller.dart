import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/conveyance_local_datasource.dart';
import '../../data/datasources/conveyance_remote_datasource.dart';
import '../../data/repositories/conveyance_repository_impl.dart';
import '../../domain/entities/conveyance_claim_entity.dart';
import '../../domain/entities/conveyance_status.dart';
import '../../domain/entities/odometer_reading_entity.dart';
import '../../domain/entities/vehicle_type.dart';
import '../../domain/repositories/conveyance_repository.dart';
import '../../domain/usecases/get_conveyance_claims_use_case.dart';
import '../../domain/usecases/record_end_odometer_use_case.dart';
import '../../domain/usecases/record_start_odometer_use_case.dart';
import '../../domain/usecases/review_conveyance_claim_use_case.dart';

// --- Data Layer Providers ---

final conveyanceLocalDataSourceProvider = Provider<ConveyanceLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ConveyanceLocalDataSourceImpl(db);
});

final conveyanceRemoteDataSourceProvider = Provider<ConveyanceRemoteDataSource>((ref) {
  return MockConveyanceRemoteDataSource();
});

final conveyanceRepositoryProvider = Provider<ConveyanceRepository>((ref) {
  final local = ref.watch(conveyanceLocalDataSourceProvider);
  final remote = ref.watch(conveyanceRemoteDataSourceProvider);
  return ConveyanceRepositoryImpl(localDataSource: local, remoteDataSource: remote);
});

// --- Use Case Providers ---

final recordStartOdometerUseCaseProvider = Provider<RecordStartOdometerUseCase>((ref) {
  final repo = ref.watch(conveyanceRepositoryProvider);
  return RecordStartOdometerUseCase(repo);
});

final recordEndOdometerUseCaseProvider = Provider<RecordEndOdometerUseCase>((ref) {
  final repo = ref.watch(conveyanceRepositoryProvider);
  return RecordEndOdometerUseCase(repo);
});

final getConveyanceClaimsUseCaseProvider = Provider<GetConveyanceClaimsUseCase>((ref) {
  final repo = ref.watch(conveyanceRepositoryProvider);
  return GetConveyanceClaimsUseCase(repo);
});

final reviewConveyanceClaimUseCaseProvider = Provider<ReviewConveyanceClaimUseCase>((ref) {
  final repo = ref.watch(conveyanceRepositoryProvider);
  return ReviewConveyanceClaimUseCase(repo);
});

// --- State Classes ---

class ConveyanceListState {
  final bool isLoading;
  final List<ConveyanceClaimEntity> claims;
  final ConveyanceStatus? filterStatus;
  final bool filterFlaggedOnly;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const ConveyanceListState({
    this.isLoading = false,
    this.claims = const [],
    this.filterStatus,
    this.filterFlaggedOnly = false,
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  List<ConveyanceClaimEntity> get filteredClaims {
    var result = claims;
    if (filterStatus != null) {
      result = result.where((c) => c.status == filterStatus).toList();
    }
    if (filterFlaggedOnly) {
      result = result.where((c) => c.isFlaggedForFraud).toList();
    }
    if (searchQuery.trim().isNotEmpty) {
      final q = searchQuery.toLowerCase().trim();
      result = result.where((c) {
        return c.userName.toLowerCase().contains(q) ||
            c.shiftDate.contains(q) ||
            c.vehicleType.displayName.toLowerCase().contains(q);
      }).toList();
    }
    return result;
  }

  int get flaggedCount => claims.where((c) => c.isFlaggedForFraud).length;
  int get pendingCount => claims.where((c) => c.status == ConveyanceStatus.pendingApproval).length;
  double get totalPayoutApproved => claims
      .where((c) => c.status == ConveyanceStatus.approved)
      .fold(0.0, (sum, c) => sum + c.approvedPayoutAmount);

  ConveyanceListState copyWith({
    bool? isLoading,
    List<ConveyanceClaimEntity>? claims,
    ConveyanceStatus? filterStatus,
    bool clearStatusFilter = false,
    bool? filterFlaggedOnly,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
  }) {
    return ConveyanceListState(
      isLoading: isLoading ?? this.isLoading,
      claims: claims ?? this.claims,
      filterStatus: clearStatusFilter ? null : (filterStatus ?? this.filterStatus),
      filterFlaggedOnly: filterFlaggedOnly ?? this.filterFlaggedOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

// --- Controller Notifiers ---

class ConveyanceListNotifier extends StateNotifier<ConveyanceListState> {
  final GetConveyanceClaimsUseCase _getClaimsUseCase;
  final ReviewConveyanceClaimUseCase _reviewClaimUseCase;
  final ConveyanceRepository _repository;
  final String? _currentUserId;
  final bool _isManagerOrAdmin;

  ConveyanceListNotifier({
    required GetConveyanceClaimsUseCase getClaimsUseCase,
    required ReviewConveyanceClaimUseCase reviewClaimUseCase,
    required ConveyanceRepository repository,
    String? currentUserId,
    bool isManagerOrAdmin = false,
  })  : _getClaimsUseCase = getClaimsUseCase,
        _reviewClaimUseCase = reviewClaimUseCase,
        _repository = repository,
        _currentUserId = currentUserId,
        _isManagerOrAdmin = isManagerOrAdmin,
        super(const ConveyanceListState()) {
    loadClaims();
  }

  Future<void> loadClaims() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final claims = await _getClaimsUseCase(
        userId: _isManagerOrAdmin ? null : _currentUserId,
        status: state.filterStatus,
        flaggedOnly: state.filterFlaggedOnly ? true : null,
        searchQuery: state.searchQuery,
      );
      state = state.copyWith(isLoading: false, claims: claims);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  void setStatusFilter(ConveyanceStatus? status) {
    if (status == null) {
      state = state.copyWith(clearStatusFilter: true);
    } else {
      state = state.copyWith(filterStatus: status);
    }
  }

  void toggleFlaggedOnly(bool? value) {
    state = state.copyWith(filterFlaggedOnly: value ?? !state.filterFlaggedOnly);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> reviewClaim({
    required String claimId,
    required ConveyanceStatus newStatus,
    required double approvedPayout,
    String? managerNotes,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _reviewClaimUseCase(
        claimId: claimId,
        newStatus: newStatus,
        approvedPayout: approvedPayout,
        managerNotes: managerNotes,
      );

      final updatedList = state.claims.map((c) => c.id == claimId ? updated : c).toList();
      state = state.copyWith(
        isLoading: false,
        claims: updatedList,
        successMessage: 'Claim ${newStatus == ConveyanceStatus.approved ? "approved" : "rejected"} successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<String?> exportCsv() async {
    try {
      return await _repository.exportClaimsCsv(state.filteredClaims);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to export CSV: $e');
      return null;
    }
  }
}

final conveyanceListNotifierProvider =
    StateNotifierProvider<ConveyanceListNotifier, ConveyanceListState>((ref) {
  final getClaims = ref.watch(getConveyanceClaimsUseCaseProvider);
  final reviewClaim = ref.watch(reviewConveyanceClaimUseCaseProvider);
  final repo = ref.watch(conveyanceRepositoryProvider);
  final authState = ref.watch(authNotifierProvider);

  final user = authState.user;
  final isManagerOrAdmin = authState.role?.isManager == true || authState.role?.isAdmin == true;

  return ConveyanceListNotifier(
    getClaimsUseCase: getClaims,
    reviewClaimUseCase: reviewClaim,
    repository: repo,
    currentUserId: user?.id,
    isManagerOrAdmin: isManagerOrAdmin,
  );
});

// --- Active Shift Claim Notifier (for Technician Field Home Screen) ---

class ActiveShiftClaimState {
  final bool isLoading;
  final ConveyanceClaimEntity? claim;
  final String? errorMessage;
  final String? successMessage;

  const ActiveShiftClaimState({
    this.isLoading = false,
    this.claim,
    this.errorMessage,
    this.successMessage,
  });

  bool get hasStartedOdometer => claim?.startReading != null;
  bool get hasCompletedOdometer => claim?.endReading != null;

  ActiveShiftClaimState copyWith({
    bool? isLoading,
    ConveyanceClaimEntity? claim,
    bool clearClaim = false,
    String? errorMessage,
    String? successMessage,
  }) {
    return ActiveShiftClaimState(
      isLoading: isLoading ?? this.isLoading,
      claim: clearClaim ? null : (claim ?? this.claim),
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

class ActiveShiftClaimNotifier extends StateNotifier<ActiveShiftClaimState> {
  final ConveyanceRepository _repository;
  final RecordStartOdometerUseCase _recordStartUseCase;
  final RecordEndOdometerUseCase _recordEndUseCase;
  final String? _userId;

  ActiveShiftClaimNotifier({
    required ConveyanceRepository repository,
    required RecordStartOdometerUseCase recordStartUseCase,
    required RecordEndOdometerUseCase recordEndUseCase,
    String? userId,
  })  : _repository = repository,
        _recordStartUseCase = recordStartUseCase,
        _recordEndUseCase = recordEndUseCase,
        _userId = userId,
        super(const ActiveShiftClaimState()) {
    loadActiveClaim();
  }

  String _todayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadActiveClaim() async {
    final userId = _userId;
    if (userId == null) return;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final claim = await _repository.getActiveShiftClaim(userId, _todayDateStr());
      state = state.copyWith(isLoading: false, claim: claim);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> recordStartOdometer({
    required String organizationId,
    required String userName,
    required VehicleType vehicleType,
    required double ratePerKm,
    required OdometerReadingEntity reading,
  }) async {
    final userId = _userId;
    if (userId == null) return false;
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final claim = await _recordStartUseCase(
        organizationId: organizationId,
        userId: userId,
        userName: userName,
        shiftDate: _todayDateStr(),
        vehicleType: vehicleType,
        ratePerKm: ratePerKm,
        reading: reading,
      );
      state = state.copyWith(
        isLoading: false,
        claim: claim,
        successMessage: 'Shift start odometer (${reading.reading} km) recorded successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> recordEndOdometer({
    required OdometerReadingEntity reading,
    required double gpsDistanceKm,
  }) async {
    final current = state.claim;
    if (current == null) {
      state = state.copyWith(errorMessage: 'No active shift start odometer record found.');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updated = await _recordEndUseCase(
        claimId: current.id,
        reading: reading,
        gpsDistanceKm: gpsDistanceKm,
      );
      state = state.copyWith(
        isLoading: false,
        claim: updated,
        successMessage: updated.isFlaggedForFraud
            ? 'Shift completed. Claim flagged for audit verification due to distance discrepancy.'
            : 'Shift completed & conveyance claim calculated: ${updated.claimedDistanceKm} km.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final activeShiftClaimNotifierProvider =
    StateNotifierProvider<ActiveShiftClaimNotifier, ActiveShiftClaimState>((ref) {
  final repo = ref.watch(conveyanceRepositoryProvider);
  final startUseCase = ref.watch(recordStartOdometerUseCaseProvider);
  final endUseCase = ref.watch(recordEndOdometerUseCaseProvider);
  final auth = ref.watch(authNotifierProvider);

  return ActiveShiftClaimNotifier(
    repository: repo,
    recordStartUseCase: startUseCase,
    recordEndUseCase: endUseCase,
    userId: auth.user?.id,
  );
});

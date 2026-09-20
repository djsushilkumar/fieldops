import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/supabase_config.dart';
import '../../../../core/database/app_database.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/datasources/reports_local_datasource.dart';
import '../../data/datasources/reports_remote_datasource.dart';
import '../../data/repositories/reports_repository_impl.dart';
import '../../data/services/csv_export_service.dart';
import '../../domain/entities/export_type.dart';
import '../../domain/entities/field_operations_report.dart';
import '../../domain/entities/report_date_range.dart';
import '../../domain/repositories/reports_repository.dart';
import '../../domain/usecases/generate_csv_export_use_case.dart';
import '../../domain/usecases/get_field_operations_report_use_case.dart';

// ============================================================================
// Providers
// ============================================================================

final csvExportServiceProvider = Provider<CsvExportService>((ref) {
  return CsvExportService();
});

final reportsRemoteDataSourceProvider = Provider<ReportsRemoteDataSource>((ref) {
  final supabase = SupabaseConfig.client;
  if (supabase != null) {
    return SupabaseReportsRemoteDataSource(supabase);
  }
  return MockReportsRemoteDataSource();
});

final reportsLocalDataSourceProvider = Provider<ReportsLocalDataSource>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ReportsLocalDataSourceImpl(db: db);
});

final reportsRepositoryProvider = Provider<ReportsRepository>((ref) {
  final user = ref.watch(currentUserProvider);
  return ReportsRepositoryImpl(
    remoteDataSource: ref.watch(reportsRemoteDataSourceProvider),
    localDataSource: ref.watch(reportsLocalDataSourceProvider),
    csvExportService: ref.watch(csvExportServiceProvider),
    getOrgId: () => user?.organizationId ?? 'org-demo-001',
  );
});

final getFieldOperationsReportUseCaseProvider = Provider<GetFieldOperationsReportUseCase>((ref) {
  return GetFieldOperationsReportUseCase(ref.watch(reportsRepositoryProvider));
});

final generateCsvExportUseCaseProvider = Provider<GenerateCsvExportUseCase>((ref) {
  return GenerateCsvExportUseCase(ref.watch(reportsRepositoryProvider));
});

// ============================================================================
// State & Controller
// ============================================================================

class ReportsState {
  final bool isLoading;
  final bool isExporting;
  final FieldOperationsReport? report;
  final ReportDateRange dateRange;
  final String? selectedTechnicianId;
  final String? errorMessage;
  final String? lastExportedContent;
  final ExportType? lastExportType;

  ReportsState({
    this.isLoading = false,
    this.isExporting = false,
    this.report,
    ReportDateRange? dateRange,
    this.selectedTechnicianId,
    this.errorMessage,
    this.lastExportedContent,
    this.lastExportType,
  }) : dateRange = dateRange ?? ReportDateRange.fromPreset(DateRangePreset.thisWeek);

  ReportsState copyWith({
    bool? isLoading,
    bool? isExporting,
    FieldOperationsReport? report,
    ReportDateRange? dateRange,
    String? selectedTechnicianId,
    bool clearTechnician = false,
    String? errorMessage,
    String? lastExportedContent,
    ExportType? lastExportType,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      isExporting: isExporting ?? this.isExporting,
      report: report ?? this.report,
      dateRange: dateRange ?? this.dateRange,
      selectedTechnicianId: clearTechnician ? null : (selectedTechnicianId ?? this.selectedTechnicianId),
      errorMessage: errorMessage,
      lastExportedContent: lastExportedContent ?? this.lastExportedContent,
      lastExportType: lastExportType ?? this.lastExportType,
    );
  }
}

class ReportsController extends StateNotifier<ReportsState> {
  final GetFieldOperationsReportUseCase _getReportUseCase;
  final GenerateCsvExportUseCase _exportCsvUseCase;

  ReportsController({
    required GetFieldOperationsReportUseCase getReportUseCase,
    required GenerateCsvExportUseCase exportCsvUseCase,
  })  : _getReportUseCase = getReportUseCase,
        _exportCsvUseCase = exportCsvUseCase,
        super(ReportsState()) {
    loadReport();
  }

  Future<void> loadReport() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final report = await _getReportUseCase(
        startDate: state.dateRange.startDate,
        endDate: state.dateRange.endDate,
        technicianId: state.selectedTechnicianId,
      );
      state = state.copyWith(
        isLoading: false,
        report: report,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load field operations report: $e',
      );
    }
  }

  void setDateRangePreset(DateRangePreset preset) {
    final newRange = ReportDateRange.fromPreset(preset);
    state = state.copyWith(dateRange: newRange);
    loadReport();
  }

  void setCustomDateRange(DateTime start, DateTime end) {
    final newRange = ReportDateRange.custom(start, end);
    state = state.copyWith(dateRange: newRange);
    loadReport();
  }

  void setTechnicianFilter(String? technicianId) {
    if (technicianId == null || technicianId.isEmpty) {
      state = state.copyWith(clearTechnician: true);
    } else {
      state = state.copyWith(selectedTechnicianId: technicianId);
    }
    loadReport();
  }

  Future<String?> exportCsv(ExportType type) async {
    state = state.copyWith(isExporting: true, errorMessage: null);
    try {
      final csv = await _exportCsvUseCase(
        type: type,
        startDate: state.dateRange.startDate,
        endDate: state.dateRange.endDate,
        technicianId: state.selectedTechnicianId,
      );
      state = state.copyWith(
        isExporting: false,
        lastExportedContent: csv,
        lastExportType: type,
      );
      return csv;
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        errorMessage: 'Failed to generate CSV export: $e',
      );
      return null;
    }
  }
}

final reportsControllerProvider = StateNotifierProvider<ReportsController, ReportsState>((ref) {
  return ReportsController(
    getReportUseCase: ref.watch(getFieldOperationsReportUseCaseProvider),
    exportCsvUseCase: ref.watch(generateCsvExportUseCaseProvider),
  );
});

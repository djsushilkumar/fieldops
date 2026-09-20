import 'package:flutter_test/flutter_test.dart';
import 'package:field_ops/features/dashboard/data/datasources/dashboard_remote_datasource.dart';
import 'package:field_ops/features/dashboard/data/models/activity_log_model.dart';
import 'package:field_ops/features/dashboard/data/models/field_technician_location_model.dart';
import 'package:field_ops/features/dashboard/data/models/operations_metrics_model.dart';
import 'package:field_ops/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:field_ops/features/dashboard/domain/entities/operations_metrics.dart';
import 'package:field_ops/features/dashboard/domain/entities/technician_duty_status.dart';
import 'package:field_ops/features/dashboard/domain/usecases/get_live_technicians_use_case.dart';
import 'package:field_ops/features/dashboard/domain/usecases/get_operations_metrics_use_case.dart';
import 'package:field_ops/features/dashboard/domain/usecases/get_recent_activity_logs_use_case.dart';

void main() {
  group('OperationsMetricsModel & Entity Tests', () {
    test('OperationsMetricsModel serialization and domain mapping', () {
      const model = OperationsMetricsModel(
        totalTechnicians: 10,
        onDutyTechnicians: 8,
        idleTechnicians: 1,
        offDutyTechnicians: 1,
        totalTasksToday: 20,
        assignedTasks: 5,
        inProgressTasks: 5,
        completedTasksToday: 8,
        overdueTasks: 2,
        completedVisitsToday: 12,
        totalProofsUploadedToday: 24,
        proofComplianceRate: 98.0,
        syncPendingQueueCount: 0,
      );

      final json = model.toJson();
      expect(json['total_technicians'], 10);
      expect(json['on_duty_technicians'], 8);
      expect(json['proof_compliance_rate'], 98.0);

      final fromJson = OperationsMetricsModel.fromJson(json);
      expect(fromJson.totalTechnicians, 10);
      expect(fromJson.proofComplianceRate, 98.0);

      final entity = model.toEntity();
      expect(entity.totalTechnicians, 10);
      expect(entity.onDutyPercentage, 80.0);
      expect(entity.taskCompletionRate, 40.0);

      final fromEntity = OperationsMetricsModel.fromEntity(entity);
      expect(fromEntity.totalTechnicians, 10);
    });

    test('OperationsMetrics copyWith operates correctly', () {
      const metrics = OperationsMetrics(totalTechnicians: 5, onDutyTechnicians: 3);
      final updated = metrics.copyWith(onDutyTechnicians: 4);
      expect(updated.totalTechnicians, 5);
      expect(updated.onDutyTechnicians, 4);
    });
  });

  group('FieldTechnicianLocationModel Tests', () {
    final now = DateTime.now();

    test('TechnicianDutyStatus fromString handles values', () {
      expect(TechnicianDutyStatus.fromString('ON_DUTY'), TechnicianDutyStatus.onDuty);
      expect(TechnicianDutyStatus.fromString('IN_TRANSIT'), TechnicianDutyStatus.inTransit);
      expect(TechnicianDutyStatus.fromString('ON_SITE'), TechnicianDutyStatus.onSite);
      expect(TechnicianDutyStatus.fromString('IDLE'), TechnicianDutyStatus.idle);
      expect(TechnicianDutyStatus.fromString('OFF_DUTY'), TechnicianDutyStatus.offDuty);
      expect(TechnicianDutyStatus.fromString(null), TechnicianDutyStatus.offDuty);
    });

    test('FieldTechnicianLocationModel serialization and entity conversion', () {
      final model = FieldTechnicianLocationModel(
        userId: 'tech-100',
        userName: 'John Doe',
        userPhone: '+1-555-1234',
        latitude: 37.7749,
        longitude: -122.4194,
        accuracyMeters: 5.0,
        speedKmh: 20.0,
        batteryLevel: 85,
        isCharging: true,
        dutyStatus: 'ON_SITE',
        activeTaskId: 'task-100',
        activeTaskTitle: 'Fix Chiller',
        activeCustomerName: 'Hospital A',
        lastPingAt: now,
      );

      final json = model.toJson();
      expect(json['user_id'], 'tech-100');
      expect(json['battery_level'], 85);
      expect(json['is_charging'], true);

      final fromJson = FieldTechnicianLocationModel.fromJson(json);
      expect(fromJson.userId, 'tech-100');
      expect(fromJson.dutyStatus, 'ON_SITE');

      final entity = model.toEntity();
      expect(entity.userId, 'tech-100');
      expect(entity.dutyStatus, TechnicianDutyStatus.onSite);
      expect(entity.isCharging, isTrue);

      final fromEntity = FieldTechnicianLocationModel.fromEntity(entity);
      expect(fromEntity.userId, 'tech-100');
    });
  });

  group('ActivityLogModel Tests', () {
    final now = DateTime.now();

    test('ActivityLogModel serialization and domain mapping', () {
      final model = ActivityLogModel(
        id: 'act-001',
        organizationId: 'org-001',
        userId: 'usr-001',
        userName: 'Tech A',
        action: 'PROOF_UPLOADED',
        entityType: 'attachment',
        entityId: 'task-001',
        details: 'Photo proof submitted',
        createdAt: now,
      );

      final json = model.toJson();
      expect(json['id'], 'act-001');
      expect(json['action'], 'PROOF_UPLOADED');

      final fromJson = ActivityLogModel.fromJson(json);
      expect(fromJson.id, 'act-001');
      expect(fromJson.details, 'Photo proof submitted');

      final entity = model.toEntity();
      expect(entity.id, 'act-001');
      expect(entity.icon, isNotNull);
      expect(entity.color, isNotNull);

      final fromEntity = ActivityLogModel.fromEntity(entity);
      expect(fromEntity.id, 'act-001');
    });
  });

  group('Dashboard Remote DataSource & Repository Tests', () {
    late MockDashboardRemoteDataSource remoteDataSource;
    late DashboardRepositoryImpl repository;

    setUp(() {
      remoteDataSource = MockDashboardRemoteDataSource();
      repository = DashboardRepositoryImpl(remoteDataSource: remoteDataSource);
    });

    test('getOperationsMetrics returns valid metrics', () async {
      final metrics = await repository.getOperationsMetrics('org-001');
      expect(metrics.totalTechnicians, greaterThan(0));
      expect(metrics.totalTasksToday, greaterThan(0));
      expect(metrics.proofComplianceRate, greaterThan(90.0));
    });

    test('getLiveTechnicianLocations returns list of active technicians', () async {
      final techs = await repository.getLiveTechnicianLocations('org-001');
      expect(techs.isNotEmpty, isTrue);
      expect(techs.any((t) => t.userName == 'Alex Rivera'), isTrue);
    });

    test('getRecentActivityLogs returns audit entries', () async {
      final logs = await repository.getRecentActivityLogs('org-001');
      expect(logs.isNotEmpty, isTrue);
      expect(logs.first.userName.isNotEmpty, isTrue);
    });

    test('Use cases execute successfully with repository', () async {
      final metricsUseCase = GetOperationsMetricsUseCase(repository);
      final techsUseCase = GetLiveTechniciansUseCase(repository);
      final logsUseCase = GetRecentActivityLogsUseCase(repository);

      final m = await metricsUseCase('org-001');
      final t = await techsUseCase('org-001');
      final l = await logsUseCase('org-001');

      expect(m.totalTechnicians, greaterThan(0));
      expect(t.isNotEmpty, isTrue);
      expect(l.isNotEmpty, isTrue);
    });
  });
}

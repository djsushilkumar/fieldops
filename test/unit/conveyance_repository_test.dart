import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:field_ops/core/database/app_database.dart';
import 'package:field_ops/core/database/sqlite_database.dart';
import 'package:field_ops/features/conveyance/data/datasources/conveyance_local_datasource.dart';
import 'package:field_ops/features/conveyance/data/datasources/conveyance_remote_datasource.dart';
import 'package:field_ops/features/conveyance/data/repositories/conveyance_repository_impl.dart';
import 'package:field_ops/features/conveyance/domain/entities/conveyance_status.dart';
import 'package:field_ops/features/conveyance/domain/entities/odometer_reading_entity.dart';
import 'package:field_ops/features/conveyance/domain/entities/vehicle_type.dart';

void main() {
  late SqliteDatabase db;
  late ConveyanceLocalDataSource localDataSource;
  late ConveyanceRemoteDataSource remoteDataSource;
  late ConveyanceRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    db = SqliteDatabaseImpl(name: 'test_conveyance_db', tables: AppDatabase.allTables, prefs: prefs);
    await db.open();

    localDataSource = ConveyanceLocalDataSourceImpl(db);
    remoteDataSource = MockConveyanceRemoteDataSource();
    repository = ConveyanceRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('ConveyanceRepositoryImpl Unit Tests', () {
    test('recordStartOdometer creates initial claim with start reading', () async {
      final startReading = OdometerReadingEntity(
        reading: 10500.0,
        readingType: OdometerReadingType.start,
        photoPath: 'start_odo.jpg',
        timestamp: DateTime(2026, 9, 25, 8, 30),
      );

      final claim = await repository.recordStartOdometer(
        organizationId: 'org-01',
        userId: 'user-100',
        userName: 'Taylor Vance',
        shiftDate: '2026-09-25',
        vehicleType: VehicleType.twoWheelerBike,
        ratePerKm: 3.50,
        reading: startReading,
      );

      expect(claim.userId, 'user-100');
      expect(claim.shiftDate, '2026-09-25');
      expect(claim.startReading?.reading, 10500.0);
      expect(claim.status, ConveyanceStatus.draft);
      expect(claim.isComplete, isFalse);
    });

    test('recordEndOdometer reconciles distances and flags fraud on high discrepancy', () async {
      final startReading = OdometerReadingEntity(
        reading: 10500.0,
        readingType: OdometerReadingType.start,
        photoPath: 'start.jpg',
        timestamp: DateTime(2026, 9, 25, 8, 30),
      );

      final claim = await repository.recordStartOdometer(
        organizationId: 'org-01',
        userId: 'user-100',
        userName: 'Taylor Vance',
        shiftDate: '2026-09-25',
        vehicleType: VehicleType.twoWheelerBike,
        ratePerKm: 3.50,
        reading: startReading,
      );

      // End reading: claimed 100km (10600 - 10500), but GPS recorded only 50km
      final endReading = OdometerReadingEntity(
        reading: 10600.0,
        readingType: OdometerReadingType.end,
        photoPath: 'end.jpg',
        timestamp: DateTime(2026, 9, 25, 17, 30),
      );

      final updatedClaim = await repository.recordEndOdometer(
        claimId: claim.id,
        reading: endReading,
        gpsDistanceKm: 50.0,
      );

      expect(updatedClaim.isComplete, isTrue);
      expect(updatedClaim.claimedDistanceKm, 100.0);
      expect(updatedClaim.gpsDistanceKm, 50.0);
      expect(updatedClaim.discrepancyPercentage, 50.0); // 50km diff / 100km = 50%
      expect(updatedClaim.isFlaggedForFraud, isTrue);
      expect(updatedClaim.status, ConveyanceStatus.pendingApproval);
      expect(updatedClaim.fraudReason, isNotNull);
    });

    test('reviewClaim updates claim status and approved payout with manager notes', () async {
      final claims = await repository.getAllClaims();
      final claimToReview = claims.first;

      final reviewed = await repository.reviewClaim(
        claimId: claimToReview.id,
        newStatus: ConveyanceStatus.approved,
        approvedPayout: 175.0,
        managerNotes: 'GPS route matches dispatched tickets.',
      );

      expect(reviewed.status, ConveyanceStatus.approved);
      expect(reviewed.approvedPayoutAmount, 175.0);
      expect(reviewed.managerNotes, 'GPS route matches dispatched tickets.');
    });

    test('exportClaimsCsv produces valid RFC-4180 CSV headers and data rows', () async {
      final claims = await repository.getAllClaims();
      final csv = await repository.exportClaimsCsv(claims);

      expect(csv, contains('Claim ID,Technician Name,Shift Date'));
      expect(csv, contains('Alex Chen'));
      expect(csv, contains('FLAGGED'));
    });
  });
}

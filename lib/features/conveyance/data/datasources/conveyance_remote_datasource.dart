import '../../domain/entities/conveyance_status.dart';
import '../../domain/entities/vehicle_type.dart';
import '../models/conveyance_claim_model.dart';

abstract class ConveyanceRemoteDataSource {
  Future<ConveyanceClaimModel?> getClaimById(String id);
  Future<List<ConveyanceClaimModel>> getUserClaims(String userId);
  Future<List<ConveyanceClaimModel>> getAllClaims();
  Future<ConveyanceClaimModel> upsertClaim(ConveyanceClaimModel claim);
}

class MockConveyanceRemoteDataSource implements ConveyanceRemoteDataSource {
  final Map<String, ConveyanceClaimModel> _claims = {};

  MockConveyanceRemoteDataSource() {
    _seedMockClaims();
  }

  void _seedMockClaims() {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final claim1 = ConveyanceClaimModel(
      id: 'claim-seed-1',
      organizationId: 'org-demo-01',
      userId: 'emp-001',
      userName: 'Alex Chen (Technician)',
      shiftDate: yesterdayStr,
      vehicleType: VehicleType.twoWheelerBike,
      ratePerKm: 3.50,
      claimedDistanceKm: 42.5,
      gpsDistanceKm: 41.8,
      discrepancyPercentage: 1.6,
      isFlaggedForFraud: false,
      status: ConveyanceStatus.approved,
      approvedPayoutAmount: 148.75,
      managerNotes: 'Route verified with GPS breadcrumbs.',
      createdAt: yesterday,
    );

    // Flagged claim for demonstration: claimed 85 km while GPS was only 40 km (52.9% discrepancy!)
    final claim2 = ConveyanceClaimModel(
      id: 'claim-seed-2',
      organizationId: 'org-demo-01',
      userId: 'emp-002',
      userName: 'Jordan Miller (HVAC Specialist)',
      shiftDate: yesterdayStr,
      vehicleType: VehicleType.fourWheelerCar,
      ratePerKm: 8.00,
      claimedDistanceKm: 85.0,
      gpsDistanceKm: 40.0,
      discrepancyPercentage: 52.9,
      isFlaggedForFraud: true,
      fraudReason:
          'Audit Flag: Claimed distance (85.0 km) exceeds GPS tracking (40.0 km) by 52.9% (+45.0 km).',
      status: ConveyanceStatus.pendingApproval,
      approvedPayoutAmount: 320.0, // conservative payout
      managerNotes: 'Pending manager interview regarding discrepancy.',
      createdAt: yesterday.add(const Duration(hours: 1)),
    );

    _claims[claim1.id] = claim1;
    _claims[claim2.id] = claim2;
  }

  @override
  Future<ConveyanceClaimModel?> getClaimById(String id) async {
    return _claims[id];
  }

  @override
  Future<List<ConveyanceClaimModel>> getUserClaims(String userId) async {
    return _claims.values.where((c) => c.userId == userId).toList();
  }

  @override
  Future<List<ConveyanceClaimModel>> getAllClaims() async {
    return _claims.values.toList();
  }

  @override
  Future<ConveyanceClaimModel> upsertClaim(ConveyanceClaimModel claim) async {
    _claims[claim.id] = claim;
    return claim;
  }
}

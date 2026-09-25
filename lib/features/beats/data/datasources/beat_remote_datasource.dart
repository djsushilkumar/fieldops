import '../../domain/entities/beat_frequency.dart';
import '../models/beat_execution_model.dart';
import '../models/beat_plan_model.dart';
import '../models/beat_stop_model.dart';

abstract class BeatRemoteDataSource {
  Future<List<BeatPlanModel>> getBeatPlans();
  Future<BeatPlanModel?> getBeatPlanById(String id);
  Future<BeatPlanModel> saveBeatPlan(BeatPlanModel plan);
  Future<BeatExecutionModel?> getTodayBeatExecution(String userId, String date);
  Future<BeatExecutionModel> saveBeatExecution(BeatExecutionModel execution);
  Future<List<BeatExecutionModel>> getAllBeatExecutions();
}

class MockBeatRemoteDataSource implements BeatRemoteDataSource {
  final Map<String, BeatPlanModel> _plans = {};
  final Map<String, BeatExecutionModel> _executions = {};

  MockBeatRemoteDataSource() {
    _seedMockBeats();
  }

  void _seedMockBeats() {
    final now = DateTime.now();

    final stops1 = [
      const BeatStopModel(
        id: 'stop-01',
        beatPlanId: 'beat-01',
        sequenceOrder: 1,
        customerId: 'cust-101',
        customerName: 'Metro Supermarket (Downtown)',
        locationId: 'loc-01',
        locationAddress: '100 Market St, Financial District',
        latitude: 37.7937,
        longitude: -122.3965,
        targetArrivalTime: '09:30',
        estimatedVisitMinutes: 30,
        isMandatory: true,
      ),
      const BeatStopModel(
        id: 'stop-02',
        beatPlanId: 'beat-01',
        sequenceOrder: 2,
        customerId: 'cust-102',
        customerName: 'Apex Electronics Hub',
        locationId: 'loc-02',
        locationAddress: '450 Mission St, SOMA',
        latitude: 37.7898,
        longitude: -122.3995,
        targetArrivalTime: '10:45',
        estimatedVisitMinutes: 45,
        isMandatory: true,
      ),
      const BeatStopModel(
        id: 'stop-03',
        beatPlanId: 'beat-01',
        sequenceOrder: 3,
        customerId: 'cust-103',
        customerName: 'Green Valley Pharmacy',
        locationId: 'loc-03',
        locationAddress: '780 Valencia St, Mission',
        latitude: 37.7601,
        longitude: -122.4215,
        targetArrivalTime: '12:00',
        estimatedVisitMinutes: 30,
        isMandatory: false,
      ),
      const BeatStopModel(
        id: 'stop-04',
        beatPlanId: 'beat-01',
        sequenceOrder: 4,
        customerId: 'cust-104',
        customerName: 'Bayview Commercial Plaza',
        locationId: 'loc-04',
        locationAddress: '1200 3rd St, Dogpatch',
        latitude: 37.7712,
        longitude: -122.3891,
        targetArrivalTime: '14:30',
        estimatedVisitMinutes: 40,
        isMandatory: true,
      ),
    ];

    final plan1 = BeatPlanModel(
      id: 'beat-01',
      organizationId: 'org-demo-01',
      code: 'BEAT-DOWNTOWN-01',
      name: 'Downtown Commercial FMCG Beat',
      description: 'Daily primary retail route for key commercial distributors and grocery chains.',
      assignedTechnicianId: 'emp-001',
      assignedTechnicianName: 'Alex Chen (Technician)',
      frequency: BeatFrequency.daily,
      dayOfWeek: 1,
      stops: stops1,
      isActive: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now.subtract(const Duration(days: 2)),
    );

    _plans[plan1.id] = plan1;
  }

  @override
  Future<List<BeatPlanModel>> getBeatPlans() async {
    return _plans.values.toList();
  }

  @override
  Future<BeatPlanModel?> getBeatPlanById(String id) async {
    return _plans[id];
  }

  @override
  Future<BeatPlanModel> saveBeatPlan(BeatPlanModel plan) async {
    _plans[plan.id] = plan;
    return plan;
  }

  @override
  Future<BeatExecutionModel?> getTodayBeatExecution(String userId, String date) async {
    final key = '${userId}_$date';
    return _executions[key];
  }

  @override
  Future<BeatExecutionModel> saveBeatExecution(BeatExecutionModel execution) async {
    final key = '${execution.userId}_${execution.date}';
    _executions[key] = execution;
    return execution;
  }

  @override
  Future<List<BeatExecutionModel>> getAllBeatExecutions() async {
    return _executions.values.toList();
  }
}

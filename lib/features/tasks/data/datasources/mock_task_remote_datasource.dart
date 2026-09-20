import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/task_model.dart';
import 'task_remote_datasource.dart';

class MockTaskRemoteDataSource implements TaskRemoteDataSource {
  final Map<String, TaskModel> _tasks = {};
  final Duration simulatedDelay;

  MockTaskRemoteDataSource({this.simulatedDelay = Duration.zero}) {
    _seedTasks();
  }

  Future<void> _delay() async {
    if (simulatedDelay > Duration.zero) {
      await Future.delayed(simulatedDelay);
    }
  }

  void _seedTasks() {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 9, 0);
    final todayEnd = DateTime(now.year, now.month, now.day, 11, 30);

    final seedList = [
      TaskModel(
        id: 'tsk-001',
        organizationId: 'org-acme-ops-001',
        title: 'AC Service & Coil Cleaning',
        description: 'Complete inspection and deep coil cleaning of master HVAC unit on roof.',
        priority: 'HIGH',
        status: 'ASSIGNED',
        assignedToUserId: 'usr-emp-003',
        assignedToUserName: 'David Miller (Technician)',
        customerId: 'cust-001',
        customerName: 'Metro Health Plaza',
        locationId: 'loc-001',
        locationName: 'North Wing Utility Room',
        createdBy: 'usr-admin-001',
        creatorName: 'Sarah Connor (Admin)',
        scheduledStart: todayStart,
        scheduledEnd: todayEnd,
        requiresGps: true,
        requiresPhoto: true,
        requiresForm: true,
        notes: 'Security gate code is #4092. Check with front desk before going to roof.',
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
      TaskModel(
        id: 'tsk-002',
        organizationId: 'org-acme-ops-001',
        title: 'Electrical Panel Thermal Audit',
        description: 'Perform IR thermal imaging on main switchboard and verify load balance.',
        priority: 'URGENT',
        status: 'IN_PROGRESS',
        assignedToUserId: 'usr-emp-003',
        assignedToUserName: 'David Miller (Technician)',
        customerId: 'cust-002',
        customerName: 'Omni Retail Mall',
        locationId: 'loc-002',
        locationName: 'Basement Electrical Substation',
        createdBy: 'usr-manager-002',
        creatorName: 'Marcus Vance (Manager)',
        scheduledStart: now.subtract(const Duration(hours: 1)),
        scheduledEnd: now.add(const Duration(hours: 1)),
        actualStart: now.subtract(const Duration(minutes: 45)),
        requiresGps: true,
        requiresPhoto: true,
        requiresForm: false,
        notes: 'PPE category 2 mandatory.',
        createdAt: now.subtract(const Duration(hours: 5)),
        updatedAt: now.subtract(const Duration(minutes: 45)),
      ),
      TaskModel(
        id: 'tsk-003',
        organizationId: 'org-acme-ops-001',
        title: 'Quarterly Fire Damper Inspection',
        description: 'Inspect mechanical operation of all duct fire dampers in zones 1 through 4.',
        priority: 'MEDIUM',
        status: 'COMPLETED',
        assignedToUserId: 'usr-emp-003',
        assignedToUserName: 'David Miller (Technician)',
        customerId: 'cust-003',
        customerName: 'TechHub Tower',
        locationId: 'loc-003',
        locationName: 'Tower Floor 4 Duct Shaft',
        createdBy: 'usr-manager-002',
        creatorName: 'Marcus Vance (Manager)',
        scheduledStart: now.subtract(const Duration(days: 1, hours: 4)),
        scheduledEnd: now.subtract(const Duration(days: 1, hours: 2)),
        actualStart: now.subtract(const Duration(days: 1, hours: 4)),
        actualEnd: now.subtract(const Duration(days: 1, hours: 2, minutes: 15)),
        requiresGps: true,
        requiresPhoto: true,
        requiresForm: true,
        notes: 'All dampers passed operational tension test.',
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 1, hours: 2)),
      ),
      TaskModel(
        id: 'tsk-004',
        organizationId: 'org-acme-ops-001',
        title: 'Chiller Water Pump Bearing Replacement',
        description: 'Replace degraded roller bearings on primary chilled water circulation pump #2.',
        priority: 'HIGH',
        status: 'ASSIGNED',
        assignedToUserId: 'usr-emp-003',
        assignedToUserName: 'David Miller (Technician)',
        customerId: 'cust-001',
        customerName: 'Metro Health Plaza',
        locationId: 'loc-001',
        locationName: 'Central Plant Room B',
        createdBy: 'usr-admin-001',
        creatorName: 'Sarah Connor (Admin)',
        scheduledStart: now.add(const Duration(hours: 3)),
        scheduledEnd: now.add(const Duration(hours: 6)),
        requiresGps: true,
        requiresPhoto: true,
        requiresForm: false,
        createdAt: now.subtract(const Duration(hours: 6)),
        updatedAt: now.subtract(const Duration(hours: 6)),
      ),
      TaskModel(
        id: 'tsk-005',
        organizationId: 'org-acme-ops-001',
        title: 'Emergency Generator Load Test',
        description: 'Run 100kW diesel backup generator under simulated 80% facility load for 60 mins.',
        priority: 'LOW',
        status: 'DRAFT',
        assignedToUserId: null,
        assignedToUserName: null,
        customerId: 'cust-002',
        customerName: 'Omni Retail Mall',
        locationId: 'loc-002',
        locationName: 'Generator Enclosure Exterior',
        createdBy: 'usr-admin-001',
        creatorName: 'Sarah Connor (Admin)',
        scheduledStart: now.add(const Duration(days: 2)),
        scheduledEnd: now.add(const Duration(days: 2, hours: 2)),
        requiresGps: true,
        requiresPhoto: false,
        requiresForm: true,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
    ];

    for (final task in seedList) {
      _tasks[task.id] = task;
    }
  }

  @override
  Future<List<TaskModel>> getTasks({
    String? organizationId,
    String? assignedUserId,
    String? status,
    String? priority,
  }) async {
    await _delay();
    var list = _tasks.values.toList();

    if (organizationId != null) {
      list = list.where((t) => t.organizationId == organizationId).toList();
    }
    if (assignedUserId != null) {
      list = list.where((t) => t.assignedToUserId == assignedUserId).toList();
    }
    if (status != null) {
      list = list.where((t) => t.status == status).toList();
    }
    if (priority != null) {
      list = list.where((t) => t.priority == priority).toList();
    }

    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  @override
  Future<TaskModel> getTask(String taskId) async {
    await _delay();
    final task = _tasks[taskId];
    if (task == null) {
      throw ServerException('Task $taskId not found');
    }
    return task;
  }

  @override
  Future<TaskModel> createTask(TaskModel task, {String? assignToUserId}) async {
    await _delay();
    final id = task.id.isNotEmpty ? task.id : 'tsk-${const Uuid().v4().substring(0, 8)}';
    
    final created = TaskModel(
      id: id,
      organizationId: task.organizationId,
      title: task.title,
      description: task.description,
      taskTypeId: task.taskTypeId,
      priority: task.priority,
      status: assignToUserId != null ? 'ASSIGNED' : task.status,
      assignedToUserId: assignToUserId ?? task.assignedToUserId,
      assignedToUserName: assignToUserId == 'usr-emp-003'
          ? 'David Miller (Technician)'
          : task.assignedToUserName,
      customerId: task.customerId,
      customerName: task.customerName ?? 'Metro Health Plaza',
      locationId: task.locationId,
      locationName: task.locationName ?? 'Main Facility',
      createdBy: task.createdBy,
      creatorName: task.creatorName,
      scheduledStart: task.scheduledStart,
      scheduledEnd: task.scheduledEnd,
      actualStart: task.actualStart,
      actualEnd: task.actualEnd,
      requiresGps: task.requiresGps,
      requiresPhoto: task.requiresPhoto,
      requiresForm: task.requiresForm,
      notes: task.notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _tasks[id] = created;
    return created;
  }

  @override
  Future<TaskModel> assignTask(String taskId, String userId) async {
    await _delay();
    final existing = _tasks[taskId];
    if (existing == null) {
      throw ServerException('Task $taskId not found');
    }

    final updated = TaskModel(
      id: existing.id,
      organizationId: existing.organizationId,
      title: existing.title,
      description: existing.description,
      taskTypeId: existing.taskTypeId,
      priority: existing.priority,
      status: 'ASSIGNED',
      assignedToUserId: userId,
      assignedToUserName: userId == 'usr-emp-003'
          ? 'David Miller (Technician)'
          : 'Team Member ($userId)',
      customerId: existing.customerId,
      customerName: existing.customerName,
      locationId: existing.locationId,
      locationName: existing.locationName,
      createdBy: existing.createdBy,
      creatorName: existing.creatorName,
      scheduledStart: existing.scheduledStart,
      scheduledEnd: existing.scheduledEnd,
      actualStart: existing.actualStart,
      actualEnd: existing.actualEnd,
      requiresGps: existing.requiresGps,
      requiresPhoto: existing.requiresPhoto,
      requiresForm: existing.requiresForm,
      notes: existing.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    _tasks[taskId] = updated;
    return updated;
  }

  @override
  Future<TaskModel> updateTaskStatus(
    String taskId,
    String status, {
    DateTime? actualStart,
    DateTime? actualEnd,
    String? notes,
  }) async {
    await _delay();
    final existing = _tasks[taskId];
    if (existing == null) {
      throw ServerException('Task $taskId not found');
    }

    final updated = TaskModel(
      id: existing.id,
      organizationId: existing.organizationId,
      title: existing.title,
      description: existing.description,
      taskTypeId: existing.taskTypeId,
      priority: existing.priority,
      status: status,
      assignedToUserId: existing.assignedToUserId,
      assignedToUserName: existing.assignedToUserName,
      customerId: existing.customerId,
      customerName: existing.customerName,
      locationId: existing.locationId,
      locationName: existing.locationName,
      createdBy: existing.createdBy,
      creatorName: existing.creatorName,
      scheduledStart: existing.scheduledStart,
      scheduledEnd: existing.scheduledEnd,
      actualStart: actualStart ?? existing.actualStart,
      actualEnd: actualEnd ?? existing.actualEnd,
      requiresGps: existing.requiresGps,
      requiresPhoto: existing.requiresPhoto,
      requiresForm: existing.requiresForm,
      notes: notes ?? existing.notes,
      createdAt: existing.createdAt,
      updatedAt: DateTime.now(),
    );

    _tasks[taskId] = updated;
    return updated;
  }
}

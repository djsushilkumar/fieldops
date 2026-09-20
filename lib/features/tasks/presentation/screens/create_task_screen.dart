import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/entities/task_priority.dart';
import '../../domain/entities/task_status.dart';
import '../controllers/task_controller.dart';

class CreateTaskScreen extends ConsumerStatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  ConsumerState<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends ConsumerState<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _customerController = TextEditingController(text: 'Metro Health Plaza');
  final _locationController = TextEditingController(text: 'North Wing Utility Room');
  final _notesController = TextEditingController();

  TaskPriority _priority = TaskPriority.medium;
  String? _assignedUserId = 'usr-emp-003';
  String? _assignedUserName = 'David Miller (Technician)';

  DateTime _scheduledStart = DateTime.now().add(const Duration(hours: 1));
  DateTime _scheduledEnd = DateTime.now().add(const Duration(hours: 3));

  bool _requiresGps = true;
  bool _requiresPhoto = true;
  bool _requiresForm = false;

  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _customerController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime({required bool isStart}) async {
    final initialDate = isStart ? _scheduledStart : _scheduledEnd;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );

    if (pickedTime == null || !mounted) return;

    final combined = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      if (isStart) {
        _scheduledStart = combined;
        if (_scheduledEnd.isBefore(_scheduledStart)) {
          _scheduledEnd = _scheduledStart.add(const Duration(hours: 2));
        }
      } else {
        _scheduledEnd = combined;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final user = ref.read(currentUserProvider);
      final org = ref.read(currentOrgProvider);

      final task = TaskEntity(
        id: '',
        organizationId: org?.id ?? 'org-acme-ops-001',
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        priority: _priority,
        status: _assignedUserId != null ? TaskStatus.assigned : TaskStatus.draft,
        assignedToUserId: _assignedUserId,
        assignedToUserName: _assignedUserName,
        customerName: _customerController.text.trim(),
        locationName: _locationController.text.trim(),
        createdBy: user?.id,
        creatorName: user?.name,
        scheduledStart: _scheduledStart,
        scheduledEnd: _scheduledEnd,
        requiresGps: _requiresGps,
        requiresPhoto: _requiresPhoto,
        requiresForm: _requiresForm,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await ref.read(createTaskUseCaseProvider).execute(
        task,
        assignToUserId: _assignedUserId,
      );

      // Refresh task list
      ref.read(taskListNotifierProvider.notifier).loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Task successfully created and dispatched!'),
            backgroundColor: AppColors.secondary,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, MMM d • h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Task'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.errorLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Title
                AppTextField(
                  controller: _titleController,
                  label: 'Task Title *',
                  hint: 'e.g. AC Filter Replacement & Inspection',
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return 'Please enter task title';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Description
                AppTextField(
                  controller: _descriptionController,
                  label: 'Description',
                  hint: 'Detailed instructions for the technician...',
                  maxLines: 3,
                ),
                const SizedBox(height: 20),

                // Priority
                const Text(
                  'Priority',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TaskPriority>(
                  segments: const [
                    ButtonSegment(value: TaskPriority.low, label: Text('Low')),
                    ButtonSegment(value: TaskPriority.medium, label: Text('Med')),
                    ButtonSegment(value: TaskPriority.high, label: Text('High')),
                    ButtonSegment(value: TaskPriority.urgent, label: Text('Urgent')),
                  ],
                  selected: {_priority},
                  onSelectionChanged: (set) {
                    setState(() {
                      _priority = set.first;
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Assignee
                const Text(
                  'Assign Technician / Field Employee',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _assignedUserId,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.person_outline, size: 20),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'usr-emp-003',
                      child: Text('David Miller (Technician)'),
                    ),
                    DropdownMenuItem(
                      value: 'usr-manager-002',
                      child: Text('Marcus Vance (Manager)'),
                    ),
                    DropdownMenuItem(
                      value: null,
                      child: Text('Unassigned (Draft)'),
                    ),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _assignedUserId = val;
                      if (val == 'usr-emp-003') {
                        _assignedUserName = 'David Miller (Technician)';
                      } else if (val == 'usr-manager-002') {
                        _assignedUserName = 'Marcus Vance (Manager)';
                      } else {
                        _assignedUserName = null;
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),

                // Customer & Location
                AppTextField(
                  controller: _customerController,
                  label: 'Client / Customer Name',
                  hint: 'Client company or person name',
                  prefixIcon: const Icon(Icons.business_outlined, size: 20),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _locationController,
                  label: 'Site / Location',
                  hint: 'Facility building or address',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                ),
                const SizedBox(height: 20),

                // Schedule window
                const Text(
                  'Schedule Window',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selectDateTime(isStart: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Start Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(_scheduledStart),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _selectDateTime(isStart: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                          alignment: Alignment.centerLeft,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('End Time', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text(
                              dateFormat.format(_scheduledEnd),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Required Proof of Work (PRD Section 10)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F9FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.verified_user_outlined, size: 18, color: AppColors.primary),
                          SizedBox(width: 8),
                          Text(
                            'Mandatory Proof of Work Requirements',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Employee cannot complete task until mandatory requirements are satisfied.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        value: _requiresGps,
                        onChanged: (val) => setState(() => _requiresGps = val),
                        title: const Text('GPS Check-in Required', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Verify technician location within allowed radius', style: TextStyle(fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      SwitchListTile(
                        value: _requiresPhoto,
                        onChanged: (val) => setState(() => _requiresPhoto = val),
                        title: const Text('Photo Proof Required', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Before and after execution photos', style: TextStyle(fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                      SwitchListTile(
                        value: _requiresForm,
                        onChanged: (val) => setState(() => _requiresForm = val),
                        title: const Text('Custom Form Submission', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: const Text('Checklist / inspection form attached to task type', style: TextStyle(fontSize: 11)),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Dispatch Notes
                AppTextField(
                  controller: _notesController,
                  label: 'Internal / Dispatch Notes',
                  hint: 'Gate codes, site contact, security remarks...',
                  maxLines: 2,
                ),
                const SizedBox(height: 32),

                // Submit Button
                AppButton(
                  label: 'Publish & Dispatch Task',
                  onPressed: _isSubmitting ? null : _submit,
                  isLoading: _isSubmitting,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../navigation/presentation/widgets/app_top_nav_bar.dart';
import '../../domain/entities/task_status.dart';
import '../controllers/task_controller.dart';
import '../widgets/task_card.dart';

import '../widgets/task_kanban_view.dart';

enum TaskViewMode { admin, manager, employee }

class TaskListScreen extends ConsumerStatefulWidget {
  final TaskViewMode mode;

  const TaskListScreen({
    super.key,
    this.mode = TaskViewMode.admin,
  });

  @override
  ConsumerState<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends ConsumerState<TaskListScreen> {
  final _searchController = TextEditingController();
  TaskStatus? _selectedStatus;
  bool _isKanbanView = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onStatusTabChanged(TaskStatus? status) {
    setState(() {
      _selectedStatus = status;
    });
    ref.read(taskListNotifierProvider.notifier).setStatusFilter(status);
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final canCreate = user?.role.canCreateTasks ?? false;

    return Scaffold(
      appBar: AppTopNavBar(
        title: widget.mode == TaskViewMode.employee ? 'My Field Tasks' : 'Task Operations',
        actions: [
          IconButton(
            icon: Icon(_isKanbanView ? Icons.view_list_rounded : Icons.view_kanban_outlined, size: 20),
            tooltip: _isKanbanView ? 'Switch to List View' : 'Switch to Kanban Board',
            onPressed: () {
              setState(() {
                _isKanbanView = !_isKanbanView;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            tooltip: 'Refresh tasks',
            onPressed: () => ref.read(taskListNotifierProvider.notifier).loadTasks(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    ref.read(taskListNotifierProvider.notifier).setSearchQuery(val);
                  },
                  decoration: InputDecoration(
                    hintText: 'Search tasks, clients, technicians...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(taskListNotifierProvider.notifier).setSearchQuery('');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  ),
                ),
                const SizedBox(height: 12),

                // Status Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'All',
                        isSelected: _selectedStatus == null,
                        onSelected: () => _onStatusTabChanged(null),
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Assigned',
                        isSelected: _selectedStatus == TaskStatus.assigned,
                        onSelected: () => _onStatusTabChanged(TaskStatus.assigned),
                        color: TaskStatus.assigned.color,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'In Progress',
                        isSelected: _selectedStatus == TaskStatus.inProgress,
                        onSelected: () => _onStatusTabChanged(TaskStatus.inProgress),
                        color: TaskStatus.inProgress.color,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        label: 'Completed',
                        isSelected: _selectedStatus == TaskStatus.completed,
                        onSelected: () => _onStatusTabChanged(TaskStatus.completed),
                        color: TaskStatus.completed.color,
                      ),
                      if (widget.mode != TaskViewMode.employee) ...[
                        const SizedBox(width: 8),
                        _buildFilterChip(
                          label: 'Draft',
                          isSelected: _selectedStatus == TaskStatus.draft,
                          onSelected: () => _onStatusTabChanged(TaskStatus.draft),
                          color: TaskStatus.draft.color,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Main Task List body with all states
          Expanded(
            child: _buildBody(taskState),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                context.push('/tasks/create');
              },
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task),
              label: const Text('New Task'),
            )
          : null,
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    Color? color,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      backgroundColor: Colors.white,
      selectedColor: (color ?? AppColors.primary).withOpacity(0.12),
      checkmarkColor: color ?? AppColors.primary,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        color: isSelected ? (color ?? AppColors.primary) : AppColors.textSecondary,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? (color ?? AppColors.primary) : AppColors.border,
        ),
      ),
    );
  }

  Widget _buildBody(TaskListState state) {
    if (state.isLoading) {
      return const LoadingView(message: 'Retrieving assigned tasks & status...');
    }

    if (state.hasError) {
      return ErrorStateView(
        title: 'Unable to Load Tasks',
        message: state.errorMessage ?? 'Something went wrong while fetching tasks.',
        onRetry: () => ref.read(taskListNotifierProvider.notifier).loadTasks(),
      );
    }

    if (state.isEmpty) {
      return EmptyStateView(
        icon: Icons.assignment_outlined,
        title: 'No Tasks Found',
        description: _selectedStatus != null
            ? 'There are no tasks currently in ${_selectedStatus!.label} status.'
            : 'No tasks scheduled yet. Create a new task to get started.',
        actionLabel: 'Clear Filter',
        onAction: () => _onStatusTabChanged(null),
      );
    }

    if (_isKanbanView) {
      return RefreshIndicator(
        onRefresh: () => ref.read(taskListNotifierProvider.notifier).loadTasks(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: TaskKanbanView(
            tasks: state.tasks,
            onTaskTap: (task) {
              context.push('/tasks/${task.id}');
            },
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(taskListNotifierProvider.notifier).loadTasks(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.tasks.length,
        itemBuilder: (context, index) {
          final task = state.tasks[index];
          return TaskCard(
            task: task,
            onTap: () {
              context.push('/tasks/${task.id}');
            },
          );
        },
      ),
    );
  }
}

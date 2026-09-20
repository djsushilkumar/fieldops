import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../domain/entities/conflict_resolution_strategy.dart';
import '../../domain/entities/sync_entity_type.dart';
import '../../domain/entities/sync_queue_item.dart';
import '../../domain/entities/sync_status.dart';
import '../controllers/sync_controller.dart';

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncNotifierProvider);
    final notifier = ref.read(syncNotifierProvider.notifier);

    final pendingItems = syncState.queueItems.where((i) => i.isPending || i.isSyncing).toList();
    final failedItems = syncState.queueItems.where((i) => i.isFailed).toList();
    final syncedItems = syncState.queueItems.where((i) => i.isSynced).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Offline Sync & Local Queue'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh Queue',
            onPressed: () => notifier.loadQueue(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => notifier.loadQueue(),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // 1. Connectivity & Simulation Card
            _buildConnectivityCard(context, ref, syncState, notifier),
            const SizedBox(height: 16),

            // 2. Overview Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    title: 'Pending',
                    value: '${pendingItems.length}',
                    color: AppColors.warning,
                    icon: Icons.hourglass_top_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Failed',
                    value: '${failedItems.length}',
                    color: AppColors.error,
                    icon: Icons.error_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    title: 'Synced',
                    value: '${syncedItems.length}',
                    color: AppColors.success,
                    icon: Icons.check_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Conflict Resolution Strategy Selector Card
            _buildConflictStrategyCard(context, syncState, notifier),
            const SizedBox(height: 20),

            // 4. Action Buttons Bar
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Sync Now',
                    icon: Icons.sync_rounded,
                    isLoading: syncState.isSyncing,
                    onPressed: syncState.isOnline
                        ? () => notifier.syncNow()
                        : null,
                  ),
                ),
                if (failedItems.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    onPressed: () => notifier.retryAllFailed(),
                    icon: const Icon(Icons.replay_rounded, size: 18),
                    label: const Text('Retry Failed'),
                  ),
                ],
                if (syncedItems.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Clear Synced History',
                    icon: const Icon(Icons.delete_sweep_rounded),
                    onPressed: () => notifier.clearSynced(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // 5. Queue Items Section Header
            Row(
              children: [
                const Text(
                  'Queued Mutations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Text(
                  '${syncState.queueItems.length} total',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6. Queue Items List or Empty View
            if (syncState.queueItems.isEmpty)
              const EmptyStateView(
                title: 'Queue is Empty',
                description: 'All local modifications are completely synchronized with the server.',
                icon: Icons.cloud_done_rounded,
              )
            else
              ...syncState.queueItems.map((item) => _buildQueueItemCard(context, item, notifier)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityCard(
    BuildContext context,
    WidgetRef ref,
    SyncState state,
    SyncNotifier notifier,
  ) {
    return Card(
      elevation: 0,
      color: state.isOnline ? Colors.green.shade50 : Colors.amber.shade50,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: state.isOnline ? Colors.green.shade200 : Colors.amber.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              state.isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded,
              size: 28,
              color: state.isOnline ? AppColors.success : AppColors.warning,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.isOnline ? 'Online (Connected)' : 'Offline Mode Active',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: state.isOnline ? Colors.green.shade900 : Colors.amber.shade900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.isOnline
                        ? 'Mutations push immediately to Supabase.'
                        : 'Changes persist locally in SQLite database.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                Switch.adaptive(
                  value: state.isOnline,
                  activeColor: AppColors.success,
                  onChanged: (_) => notifier.toggleOnlineSimulation(),
                ),
                Text(
                  state.isOnline ? 'Simulate Offline' : 'Go Online',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictStrategyCard(
    BuildContext context,
    SyncState state,
    SyncNotifier notifier,
  ) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.rule_rounded, size: 18, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'Conflict Resolution Strategy',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<ConflictResolutionStrategy>(
              value: state.strategy,
              decoration: const InputDecoration(
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: ConflictResolutionStrategy.values.map((strategy) {
                return DropdownMenuItem(
                  value: strategy,
                  child: Text(strategy.displayName, style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  notifier.setConflictStrategy(val);
                }
              },
            ),
            const SizedBox(height: 6),
            Text(
              state.strategy.description,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueItemCard(
    BuildContext context,
    SyncQueueItem item,
    SyncNotifier notifier,
  ) {
    Color statusColor;
    switch (item.status) {
      case SyncStatus.pending:
        statusColor = AppColors.warning;
        break;
      case SyncStatus.syncing:
        statusColor = AppColors.primary;
        break;
      case SyncStatus.synced:
        statusColor = AppColors.success;
        break;
      case SyncStatus.failed:
        statusColor = AppColors.error;
        break;
    }

    IconData entityIcon;
    switch (item.entityType) {
      case SyncEntityType.task:
        entityIcon = Icons.assignment_rounded;
        break;
      case SyncEntityType.visit:
        entityIcon = Icons.place_rounded;
        break;
      case SyncEntityType.attendance:
        entityIcon = Icons.access_time_rounded;
        break;
      case SyncEntityType.form:
      case SyncEntityType.formSubmission:
        entityIcon = Icons.description_rounded;
        break;
      case SyncEntityType.customer:
      case SyncEntityType.location:
        entityIcon = Icons.business_rounded;
        break;
      case SyncEntityType.attachment:
        entityIcon = Icons.attachment_rounded;
        break;
      case SyncEntityType.notification:
        entityIcon = Icons.notifications_rounded;
        break;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Icon(entityIcon, size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.entityType.displayName}: ${item.entityId.substring(0, item.entityId.length > 12 ? 12 : item.entityId.length)}...',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Queued at ${_formatTime(item.createdAt)} • ${item.attempts} attempts',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.status.code,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.operation.code,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.payload.keys.join(', '),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (item.isFailed)
                  IconButton(
                    icon: const Icon(Icons.replay_rounded, size: 18, color: AppColors.primary),
                    tooltip: 'Retry Now',
                    onPressed: () => notifier.retryItem(item.id),
                  ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.grey),
                  tooltip: 'Delete Item',
                  onPressed: () => notifier.deleteItem(item.id),
                ),
              ],
            ),
            if (item.lastError != null) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.lastError!,
                  style: const TextStyle(fontSize: 11, color: AppColors.error),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
  }
}

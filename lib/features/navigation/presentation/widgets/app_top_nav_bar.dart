import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/role_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../sync/presentation/controllers/sync_controller.dart';

class AppTopNavBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;

  const AppTopNavBar({
    super.key,
    required this.title,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final org = ref.watch(currentOrgProvider);

    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: Colors.white,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (org != null)
            Text(
              org.name,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      actions: [
        if (actions != null) ...actions!,
        Consumer(
          builder: (context, ref, _) {
            final syncState = ref.watch(syncNotifierProvider);
            return IconButton(
              icon: Badge(
                isLabelVisible: syncState.pendingCount > 0,
                label: Text('${syncState.pendingCount}'),
                backgroundColor: syncState.isOnline ? AppColors.primary : AppColors.warning,
                child: Icon(
                  !syncState.isOnline
                      ? Icons.cloud_off_rounded
                      : syncState.isSyncing
                          ? Icons.sync_rounded
                          : syncState.pendingCount > 0
                              ? Icons.sync_problem_rounded
                              : Icons.cloud_done_rounded,
                  color: !syncState.isOnline
                      ? AppColors.warning
                      : syncState.isSyncing
                          ? AppColors.primary
                          : syncState.pendingCount > 0
                              ? AppColors.warning
                              : AppColors.success,
                  size: 20,
                ),
              ),
              tooltip: !syncState.isOnline
                  ? 'Offline Mode - Tap for Sync'
                  : syncState.isSyncing
                      ? 'Syncing changes...'
                      : syncState.pendingCount > 0
                          ? '${syncState.pendingCount} changes pending'
                          : 'All changes synced',
              onPressed: () => context.push('/sync'),
            );
          },
        ),
        if (user != null) ...[
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              child: RoleBadge(role: user.role.value),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Sign Out',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogCtx) => AlertDialog(
                  title: const Text('Sign Out'),
                  content: const Text('Are you sure you want to sign out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogCtx);
                        ref.read(authNotifierProvider.notifier).signOut();
                      },
                      child: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
        const SizedBox(width: 8),
      ],
    );
  }
}

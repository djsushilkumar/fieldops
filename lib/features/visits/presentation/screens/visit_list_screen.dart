import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/visit_controller.dart';
import '../widgets/visit_card.dart';

class VisitListScreen extends ConsumerStatefulWidget {
  const VisitListScreen({super.key});

  @override
  ConsumerState<VisitListScreen> createState() => _VisitListScreenState();
}

class _VisitListScreenState extends ConsumerState<VisitListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(visitListNotifierProvider);
    final user = ref.watch(currentUserProvider);
    final isEmployee = user?.role.isEmployee ?? true;

    final allVisits = state.visits;
    final activeVisits = allVisits.where((v) => v.isActive).toList();
    final completedVisits = allVisits.where((v) => v.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isEmployee ? 'My Visits' : 'Live & Recent Visits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.read(visitListNotifierProvider.notifier).refresh(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'All (${allVisits.length})'),
            Tab(text: 'Active (${activeVisits.length})'),
            Tab(text: 'Completed (${completedVisits.length})'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(visitListNotifierProvider.notifier).refresh(),
        child: _buildBody(state, allVisits, activeVisits, completedVisits),
      ),
    );
  }

  Widget _buildBody(
    VisitListState state,
    List allVisits,
    List activeVisits,
    List completedVisits,
  ) {
    if (state.status == VisitListStatus.loading && state.visits.isEmpty) {
      return const LoadingView(message: 'Loading visits...');
    }

    if (state.status == VisitListStatus.error && state.visits.isEmpty) {
      return ErrorStateView(
        message: state.errorMessage ?? 'Failed to load visits',
        onRetry: () =>
            ref.read(visitListNotifierProvider.notifier).loadVisits(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildList(allVisits, 'No visits recorded yet'),
        _buildList(activeVisits, 'No active visits in progress'),
        _buildList(completedVisits, 'No completed visits yet'),
      ],
    );
  }

  Widget _buildList(List visits, String emptyMessage) {
    if (visits.isEmpty) {
      return EmptyStateView(
        icon: Icons.location_history_outlined,
        title: emptyMessage,
        description:
            'Visits are automatically logged when employees check in at client sites.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: visits.length,
      itemBuilder: (context, index) {
        final visit = visits[index];
        return VisitCard(
          visit: visit,
          onTap: () {
            context.push('/visits/${visit.id}');
          },
        );
      },
    );
  }
}

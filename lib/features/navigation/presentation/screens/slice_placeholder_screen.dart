import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/empty_state_view.dart';
import '../../../../core/widgets/error_state_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../widgets/app_top_nav_bar.dart';

enum ViewDisplayMode { content, loading, empty, error }

class SlicePlaceholderScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final String slicePhase;
  final IconData icon;
  final List<String> capabilities;

  const SlicePlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.slicePhase,
    required this.icon,
    required this.capabilities,
  });

  @override
  State<SlicePlaceholderScreen> createState() => _SlicePlaceholderScreenState();
}

class _SlicePlaceholderScreenState extends State<SlicePlaceholderScreen> {
  ViewDisplayMode _currentMode = ViewDisplayMode.content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppTopNavBar(
        title: widget.title,
        actions: [
          PopupMenuButton<ViewDisplayMode>(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textSecondary, size: 20),
            tooltip: 'Toggle States (Demo/QA)',
            onSelected: (mode) {
              setState(() {
                _currentMode = mode;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ViewDisplayMode.content,
                child: Text('Content State'),
              ),
              const PopupMenuItem(
                value: ViewDisplayMode.loading,
                child: Text('Loading State'),
              ),
              const PopupMenuItem(
                value: ViewDisplayMode.empty,
                child: Text('Empty State'),
              ),
              const PopupMenuItem(
                value: ViewDisplayMode.error,
                child: Text('Error State'),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_currentMode) {
      case ViewDisplayMode.loading:
        return const LoadingView(message: 'Loading records from local sync engine...');
      case ViewDisplayMode.empty:
        return EmptyStateView(
          icon: widget.icon,
          title: 'No ${widget.title} Found',
          description: 'Records created or synced will appear here.',
          actionLabel: 'Create New',
          onAction: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${widget.title} creation unlocks in next slice.')),
            );
          },
        );
      case ViewDisplayMode.error:
        return ErrorStateView(
          title: 'Connection Issue',
          message: 'Unable to reach the server. Local offline cache will be used.',
          onRetry: () {
            setState(() {
              _currentMode = ViewDisplayMode.content;
            });
          },
        );
      case ViewDisplayMode.content:
      default:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phase banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(widget.icon, size: 28, color: AppColors.primary),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  widget.slicePhase,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'Planned Capabilities & Schema Contract',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.capabilities.length,
                separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final cap = widget.capabilities[idx];
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cap,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // State tester notice
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F3F4),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, size: 18, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Use the filter icon in the top right to verify Loading, Empty, and Error state rendering.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

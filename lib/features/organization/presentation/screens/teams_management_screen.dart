import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../navigation/presentation/widgets/app_top_nav_bar.dart';
import '../../domain/entities/team_entity.dart';
import '../controllers/teams_controller.dart';

class TeamsManagementScreen extends ConsumerWidget {
  const TeamsManagementScreen({super.key});

  void _showTeamDialog(BuildContext context, WidgetRef ref, {TeamEntity? existingTeam}) {
    final nameController = TextEditingController(text: existingTeam?.name ?? '');
    final descController = TextEditingController(text: existingTeam?.description ?? '');
    String? leadManagerId = existingTeam?.leadManagerId;
    String selectedColor = existingTeam?.colorHex ?? '#0288D1';

    final colors = ['#0288D1', '#7B1FA2', '#00A86B', '#E65100', '#D93025', '#455A64'];

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final members = ref.watch(teamsControllerProvider).members;
            final managers = members.where((m) => m.role.isManager || m.role.isAdmin).toList();

            return AlertDialog(
              title: Text(existingTeam == null ? 'Create Dispatch Team' : 'Edit Team'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Team Name *',
                        hintText: 'e.g. SF Metro Rapid Response',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Description / Regional Scope',
                        hintText: 'e.g. Commercial chilling and emergency calls',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: leadManagerId,
                      decoration: const InputDecoration(
                        labelText: 'Lead Dispatcher / Manager',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('None (Unassigned)')),
                        ...managers.map((m) => DropdownMenuItem(value: m.userId, child: Text(m.name))),
                      ],
                      onChanged: (val) => setDialogState(() => leadManagerId = val),
                    ),
                    const SizedBox(height: 14),
                    const Text('Team Badge Color', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: colors.map((c) {
                        final isSelected = selectedColor == c;
                        final colorInt = int.parse(c.replaceAll('#', '0xFF'));
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = c),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Color(colorInt),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final controller = ref.read(teamsControllerProvider.notifier);
                    if (existingTeam == null) {
                      await controller.createTeam(
                        name: name,
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        leadManagerId: leadManagerId,
                        colorHex: selectedColor,
                      );
                    } else {
                      await controller.updateTeam(
                        teamId: existingTeam.id,
                        name: name,
                        description: descController.text.trim().isEmpty ? null : descController.text.trim(),
                        leadManagerId: leadManagerId,
                        colorHex: selectedColor,
                      );
                    }

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleAdmin,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(existingTeam == null ? 'Create' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, TeamEntity team) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${team.name}"? Technicians will be unassigned.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(teamsControllerProvider.notifier).deleteTeam(team.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(teamsControllerProvider);
    final teams = state.teams;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AppTopNavBar(
        title: 'Dispatch Teams',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTeamDialog(context, ref),
        backgroundColor: AppColors.roleAdmin,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Team'),
      ),
      body: state.isLoading && teams.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : teams.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: const BoxDecoration(color: AppColors.roleAdminBg, shape: BoxShape.circle),
                        child: const Icon(Icons.groups_rounded, size: 48, color: AppColors.roleAdmin),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Dispatch Teams Yet',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Organize your field operations by creating regional units.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    Color badgeColor;
                    try {
                      badgeColor = Color(int.parse(team.colorHex.replaceAll('#', '0xFF')));
                    } catch (_) {
                      badgeColor = AppColors.roleManager;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(color: badgeColor, shape: BoxShape.circle),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  team.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                onPressed: () => _showTeamDialog(context, ref, existingTeam: team),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                onPressed: () => _confirmDelete(context, ref, team),
                              ),
                            ],
                          ),
                          if (team.description != null && team.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              team.description!,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                          const Divider(height: 20),
                          Row(
                            children: [
                              const Icon(Icons.person_pin_rounded, size: 16, color: AppColors.roleAdmin),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Lead: ${team.leadManagerName ?? 'Unassigned'}',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${team.memberCount} Members',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeColor),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}

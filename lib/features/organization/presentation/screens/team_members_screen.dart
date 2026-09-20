import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../navigation/presentation/widgets/app_top_nav_bar.dart';
import '../../domain/entities/team_member_entity.dart';
import '../controllers/teams_controller.dart';

class TeamMembersScreen extends ConsumerStatefulWidget {
  const TeamMembersScreen({super.key});

  @override
  ConsumerState<TeamMembersScreen> createState() => _TeamMembersScreenState();
}

class _TeamMembersScreenState extends ConsumerState<TeamMembersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showInviteDialog(BuildContext context) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    UserRole selectedRole = UserRole.employee;
    String? selectedTeamId;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final teams = ref.watch(teamsControllerProvider).teams;

            return AlertDialog(
              title: const Text('Invite Team Member'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email Address *',
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: UserRole.admin, child: Text('Admin (Full Ops & Settings)')),
                        DropdownMenuItem(value: UserRole.manager, child: Text('Manager (Dispatch & Reports)')),
                        DropdownMenuItem(value: UserRole.employee, child: Text('Field Employee (Tasks & Visits)')),
                      ],
                      onChanged: (role) {
                        if (role != null) setDialogState(() => selectedRole = role);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedTeamId,
                      decoration: const InputDecoration(
                        labelText: 'Assign to Dispatch Team',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Unassigned / Float')),
                        ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (id) => setDialogState(() => selectedTeamId = id),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final email = emailController.text.trim();
                    if (name.isEmpty || email.isEmpty) return;

                    Navigator.of(ctx).pop();
                    await ref.read(teamsControllerProvider.notifier).inviteMember(
                      name: name,
                      email: email,
                      role: selectedRole,
                      teamId: selectedTeamId,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.roleAdmin,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send Invite'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMemberRoleSheet(BuildContext context, TeamMemberEntity member) {
    UserRole selectedRole = member.role;
    String? selectedTeamId = member.teamId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (bottomSheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final teams = ref.watch(teamsControllerProvider).teams;

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manage ${member.name}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(member.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<UserRole>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                        DropdownMenuItem(value: UserRole.manager, child: Text('Manager')),
                        DropdownMenuItem(value: UserRole.employee, child: Text('Field Employee')),
                      ],
                      onChanged: (role) {
                        if (role != null) setSheetState(() => selectedRole = role);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      value: selectedTeamId,
                      decoration: const InputDecoration(labelText: 'Team Assignment', border: OutlineInputBorder()),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                        ...teams.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))),
                      ],
                      onChanged: (id) => setSheetState(() => selectedTeamId = id),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.of(bottomSheetContext).pop();
                              await ref.read(teamsControllerProvider.notifier).updateMemberRole(
                                memberId: member.id,
                                role: selectedRole,
                                teamId: selectedTeamId,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.roleAdmin,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Update Permissions'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(teamsControllerProvider);
    final members = state.members.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(q) || m.email.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AppTopNavBar(
        title: 'Team Members',
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showInviteDialog(context),
        backgroundColor: AppColors.roleAdmin,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Invite Member'),
      ),
      body: Column(
        children: [
          // Search box
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search staff by name or email...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
              ),
            ),
          ),

          // Member List
          Expanded(
            child: state.isLoading && members.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: members.length,
                    itemBuilder: (context, index) {
                      final member = members[index];
                      Color roleColor = member.role.isAdmin
                          ? AppColors.roleAdmin
                          : member.role.isManager
                              ? AppColors.roleManager
                              : AppColors.roleEmployee;
                      Color roleBg = member.role.isAdmin
                          ? AppColors.roleAdminBg
                          : member.role.isManager
                              ? AppColors.roleManagerBg
                              : AppColors.roleEmployeeBg;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          onTap: () => _showMemberRoleSheet(context, member),
                          leading: CircleAvatar(
                            backgroundColor: roleBg,
                            child: Text(
                              member.name.isNotEmpty ? member.name[0].toUpperCase() : 'U',
                              style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                            ),
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  member.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: roleBg, borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  member.role.label,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: roleColor),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2),
                              Text(member.email, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                              if (member.teamName != null) ...[
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(Icons.groups_rounded, size: 12, color: AppColors.textTertiary),
                                    const SizedBox(width: 4),
                                    Text(
                                      member.teamName!,
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: member.status == MemberStatus.active ? AppColors.successLight : AppColors.warningLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              member.status.displayName,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: member.status == MemberStatus.active ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/user_role.dart';
import '../../../navigation/presentation/widgets/app_top_nav_bar.dart';
import '../controllers/role_permissions_controller.dart';

class RolePermissionsScreen extends ConsumerStatefulWidget {
  const RolePermissionsScreen({super.key});

  @override
  ConsumerState<RolePermissionsScreen> createState() => _RolePermissionsScreenState();
}

class _RolePermissionsScreenState extends ConsumerState<RolePermissionsScreen> {
  UserRole _selectedRole = UserRole.manager;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(rolePermissionsControllerProvider);
    final controller = ref.read(rolePermissionsControllerProvider.notifier);
    final perm = state.forRole(_selectedRole);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: const AppTopNavBar(
        title: 'Role Permissions Matrix',
      ),
      body: state.isLoading && perm == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Role Picker Bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        UserRole.admin,
                        UserRole.manager,
                        UserRole.employee,
                      ].map((role) {
                        final isSelected = _selectedRole == role;
                        Color roleColor = role.isAdmin
                            ? AppColors.roleAdmin
                            : role.isManager
                                ? AppColors.roleManager
                                : AppColors.roleEmployee;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              role.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: roleColor,
                            backgroundColor: const Color(0xFFF1F3F4),
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedRole = role);
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                // Permission Toggles List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Container(
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
                                const Icon(Icons.security_rounded, size: 20, color: AppColors.roleAdmin),
                                const SizedBox(width: 8),
                                Text(
                                  '${_selectedRole.label} Permissions',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Fine-tune capabilities and access restrictions for this role.',
                              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                            const Divider(height: 24),

                            // Toggle 1: Create & Schedule Tasks
                            _buildPermissionTile(
                              title: 'Create & Schedule Tasks',
                              subtitle: 'Permission to generate work orders, assign technicians, and dispatch calls.',
                              icon: Icons.assignment_outlined,
                              value: perm?.canCreateTasks ?? false,
                              onChanged: (val) {
                                controller.togglePermission(role: _selectedRole, permissionKey: 'canCreateTasks', value: val);
                              },
                            ),
                            const Divider(height: 20),

                            // Toggle 2: Manage Customers & Sites
                            _buildPermissionTile(
                              title: 'Manage Customers & Locations',
                              subtitle: 'Create customer records, set site GPS coordinates, and edit contacts.',
                              icon: Icons.business_outlined,
                              value: perm?.canManageCustomers ?? false,
                              onChanged: (val) {
                                controller.togglePermission(role: _selectedRole, permissionKey: 'canManageCustomers', value: val);
                              },
                            ),
                            const Divider(height: 20),

                            // Toggle 3: View All Teams
                            _buildPermissionTile(
                              title: 'Cross-Team Operations Visibility',
                              subtitle: 'Allow viewing tasks and live GPS radar across all dispatch teams (not just own unit).',
                              icon: Icons.groups_outlined,
                              value: perm?.canViewAllTeams ?? false,
                              onChanged: (val) {
                                controller.togglePermission(role: _selectedRole, permissionKey: 'canViewAllTeams', value: val);
                              },
                            ),
                            const Divider(height: 20),

                            // Toggle 4: Export Reports
                            _buildPermissionTile(
                              title: 'Reports & CSV Export Center',
                              subtitle: 'Access high-level operations analytics and export customer/payroll spreadsheets.',
                              icon: Icons.file_download_outlined,
                              value: perm?.canExportReports ?? false,
                              onChanged: (val) {
                                controller.togglePermission(role: _selectedRole, permissionKey: 'canExportReports', value: val);
                              },
                            ),
                            const Divider(height: 20),

                            // Toggle 5: Manage Forms
                            _buildPermissionTile(
                              title: 'Dynamic Form Builder Access',
                              subtitle: 'Design custom dynamic checklists, audit forms, and field questions.',
                              icon: Icons.dynamic_form_rounded,
                              value: perm?.canManageForms ?? false,
                              onChanged: (val) {
                                controller.togglePermission(role: _selectedRole, permissionKey: 'canManageForms', value: val);
                              },
                            ),
                            const Divider(height: 20),

                            // Toggle 6: Manage Users
                            _buildPermissionTile(
                              title: 'Organization Settings & User Management',
                              subtitle: 'Invite staff members, adjust role matrix, and change billing profiles.',
                              icon: Icons.admin_panel_settings_outlined,
                              value: perm?.canManageUsers ?? false,
                              onChanged: (val) {
                                controller.togglePermission(role: _selectedRole, permissionKey: 'canManageUsers', value: val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => controller.resetToDefaults(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              child: const Text('Reset Defaults'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: state.isSaving
                                  ? null
                                  : () async {
                                      final success = await controller.savePermissions();
                                      if (success && context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Permissions matrix updated!'),
                                            backgroundColor: AppColors.success,
                                          ),
                                        );
                                      }
                                    },
                              icon: state.isSaving
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.check_rounded, size: 18),
                              label: Text(state.isSaving ? 'Saving...' : 'Save Permissions'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.roleAdmin,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F3F4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          activeColor: AppColors.roleAdmin,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

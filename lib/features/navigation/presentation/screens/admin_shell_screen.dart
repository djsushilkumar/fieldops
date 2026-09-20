import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../tasks/presentation/screens/task_list_screen.dart';
import 'slice_placeholder_screen.dart';

class AdminShellScreen extends StatefulWidget {
  const AdminShellScreen({super.key});

  @override
  State<AdminShellScreen> createState() => _AdminShellScreenState();
}

class _AdminShellScreenState extends State<AdminShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SlicePlaceholderScreen(
      title: 'Admin Dashboard',
      subtitle: 'Organization-Wide Operations Overview',
      slicePhase: 'Slice 1 / Core',
      icon: Icons.analytics_rounded,
      capabilities: [
        'Total organization headcount & active field force',
        'Company-wide task status distribution',
        'Overdue tasks alert banner',
        'Live geolocated visits and team locations',
      ],
    ),
    TaskListScreen(mode: TaskViewMode.admin),
    SlicePlaceholderScreen(
      title: 'Customers & Sites',
      subtitle: 'Client Master & Geofenced Locations',
      slicePhase: 'Slice 3',
      icon: Icons.business_rounded,
      capabilities: [
        'Customer database with contact details',
        'Multiple site locations per customer',
        'Configurable allowed geofence radius (meters)',
        'Visit history by client',
      ],
    ),
    SlicePlaceholderScreen(
      title: 'Organization Settings',
      subtitle: 'Teams, Forms & System Configuration',
      slicePhase: 'Slice 1 / Core',
      icon: Icons.settings_rounded,
      capabilities: [
        'Manage Organization details, timezone & currency',
        'Manage Employees, Roles & Team assignments',
        'Custom Form Builder (Text, Date, Select, Checkbox)',
        'Multi-tenant Row-Level Security verification',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.roleAdminBg,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded, color: AppColors.roleAdmin),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_outlined),
            selectedIcon: Icon(Icons.task_rounded, color: AppColors.roleAdmin),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.business_outlined),
            selectedIcon: Icon(Icons.business_rounded, color: AppColors.roleAdmin),
            label: 'Customers',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: AppColors.roleAdmin),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

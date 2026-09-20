import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../attendance/presentation/screens/field_home_screen.dart';
import '../../../tasks/presentation/screens/task_list_screen.dart';
import '../../../visits/presentation/screens/visit_list_screen.dart';
import 'slice_placeholder_screen.dart';

class EmployeeShellScreen extends StatefulWidget {
  const EmployeeShellScreen({super.key});

  @override
  State<EmployeeShellScreen> createState() => _EmployeeShellScreenState();
}

class _EmployeeShellScreenState extends State<EmployeeShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    FieldHomeScreen(),
    TaskListScreen(mode: TaskViewMode.employee),
    VisitListScreen(),
    SlicePlaceholderScreen(
      title: 'Notifications',
      subtitle: 'Task Updates & Reminders',
      slicePhase: 'Slice 9',
      icon: Icons.notifications_rounded,
      capabilities: [
        'Task assignment alerts',
        'Schedule reminders & overdue warnings',
        'Manager review notes and feedback',
      ],
    ),
    SlicePlaceholderScreen(
      title: 'My Profile',
      subtitle: 'Account & Attendance History',
      slicePhase: 'Slice 1 / Core',
      icon: Icons.person_rounded,
      capabilities: [
        'Personal profile details & photo',
        'Organization membership info',
        'Monthly attendance log',
        'App version and local sync diagnostic',
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
        indicatorColor: AppColors.roleEmployeeBg,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: AppColors.roleEmployee),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist_rounded, color: AppColors.roleEmployee),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded, color: AppColors.roleEmployee),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded, color: AppColors.roleEmployee),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded, color: AppColors.roleEmployee),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

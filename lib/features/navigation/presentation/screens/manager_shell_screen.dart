import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../tasks/presentation/screens/task_list_screen.dart';
import '../../../visits/presentation/screens/visit_list_screen.dart';
import 'slice_placeholder_screen.dart';

class ManagerShellScreen extends StatefulWidget {
  const ManagerShellScreen({super.key});

  @override
  State<ManagerShellScreen> createState() => _ManagerShellScreenState();
}

class _ManagerShellScreenState extends State<ManagerShellScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    SlicePlaceholderScreen(
      title: 'Team Dashboard',
      subtitle: "Manager's Real-time Operations Cockpit",
      slicePhase: 'Slice 1 / Core',
      icon: Icons.dashboard_rounded,
      capabilities: [
        'Today\'s active field team count',
        'Present vs absent team members',
        'Live task status breakdown (Draft, In Progress, Completed)',
        'Active visits in progress with GPS coords',
      ],
    ),
    TaskListScreen(mode: TaskViewMode.manager),
    VisitListScreen(),
    SlicePlaceholderScreen(
      title: 'Attendance',
      subtitle: 'Daily Team Attendance Records',
      slicePhase: 'Slice 6',
      icon: Icons.event_available_rounded,
      capabilities: [
        'Team attendance summary for today',
        'Check-in and check-out GPS points',
        'Working duration calculation',
        'Historical attendance lookup',
      ],
    ),
    SlicePlaceholderScreen(
      title: 'Field Reports',
      subtitle: 'Performance & Operations Analytics',
      slicePhase: 'Slice 7',
      icon: Icons.bar_chart_rounded,
      capabilities: [
        'Task completion metrics per employee',
        'Visit duration and customer coverage',
        'CSV export of daily tasks and attendance',
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
        indicatorColor: AppColors.roleManagerBg,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: AppColors.roleManager),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded, color: AppColors.roleManager),
            label: 'Tasks',
          ),
          NavigationDestination(
            icon: Icon(Icons.pin_drop_outlined),
            selectedIcon: Icon(Icons.pin_drop_rounded, color: AppColors.roleManager),
            label: 'Visits',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_available_outlined),
            selectedIcon: Icon(Icons.event_available_rounded, color: AppColors.roleManager),
            label: 'Attendance',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded, color: AppColors.roleManager),
            label: 'Reports',
          ),
        ],
      ),
    );
  }
}

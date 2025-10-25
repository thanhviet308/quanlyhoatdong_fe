import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'teacher/ongoing_tab.dart';
import 'tabs/activities_tab.dart';
import 'tabs/profile_tab.dart';

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});

  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _index = 1; // mặc định ở giữa: Đang diễn ra

  final _titles = const ['Hoạt động', 'Đang diễn ra', 'Hồ sơ'];

  @override
  Widget build(BuildContext context) {
    final tabs = [
      const ActivitiesTab(readOnly: true),
      const OngoingTab(),
      const ProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: tabs[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Hoạt động',
          ),
          NavigationDestination(
            icon: Icon(Icons.play_circle_outline),
            selectedIcon: Icon(Icons.play_circle_filled),
            label: 'Đang diễn ra',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

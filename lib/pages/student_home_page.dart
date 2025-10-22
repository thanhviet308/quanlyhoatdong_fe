import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// 3 tab riêng
import 'tabs/activities_tab.dart';
import 'tabs/registered_tab.dart';
import 'tabs/profile_tab.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  int _index = 0;

  final _tabs = const [
    ActivitiesTab(), // Hoạt động
    RegisteredTab(), // Đã đăng ký
    ProfileTab(), // Hồ sơ
  ];

  final _titles = const ['Hoạt động', 'Đã đăng ký', 'Hồ sơ'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: Text(_titles[_index]),
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppTheme.primaryGreen,
      ),
      body: _tabs[_index],
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
            icon: Icon(Icons.how_to_reg_outlined),
            selectedIcon: Icon(Icons.how_to_reg),
            label: 'Đã đăng ký',
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

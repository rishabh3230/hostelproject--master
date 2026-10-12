import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'admin/feedback_screen.dart';
import 'admin/hostel_allotment_screen.dart';
import 'admin/student_details_screen.dart';
import 'admin/vacancy_screen.dart';
import 'admin/notices_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  final List<Widget> _screens = const <Widget>[
    HostelAllotmentScreen(),
    VacancyScreen(),
    StudentDetailsScreen(),
    NoticesScreen(),
    FeedbackScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems =
      const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment),
          label: 'Allotment',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.bed), label: 'Vacancy'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notices',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
      ];

  @override
  void initState() {
    super.initState();
    assert(
      _screens.length == _navItems.length,
      'screens and BottomNavigationBar items must have the same length',
    );

    if (_currentIndex >= _screens.length) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int safeIndex =
        (_currentIndex >= 0 && _currentIndex < _screens.length)
        ? _currentIndex
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: _screens[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: safeIndex,
        onTap: (int index) => setState(() {
          _currentIndex = (index >= 0 && index < _screens.length)
              ? index
              : (_screens.length - 1).clamp(0, _screens.length - 1);
        }),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF1B5E20),
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

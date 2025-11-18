import 'package:flutter/material.dart';
import 'admin/feedback_screen.dart';
import 'admin/hostel_allotment_screen.dart';
import 'admin/student_details_screen.dart';
import 'admin/vacancy_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _currentIndex = 0;

  // Keep these in sync (same length)
  final List<Widget> _screens = <Widget>[
    const HostelAllotmentScreen(),
    const VacancyScreen(),
    const StudentDetailsScreen(),
    const FeedbackScreen(),
  ];

  final List<BottomNavigationBarItem> _navItems = const <BottomNavigationBarItem>[
    BottomNavigationBarItem(icon: Icon(Icons.assignment), label: 'Allotment'),
    BottomNavigationBarItem(icon: Icon(Icons.bed), label: 'Vacancy'),
    BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Students'),
    BottomNavigationBarItem(icon: Icon(Icons.feedback), label: 'Feedback'),
  ];

  @override
  void initState() {
    super.initState();
    // Debug-time check to catch mismatches early
    assert(_screens.length == _navItems.length,
    'screens and BottomNavigationBar items must have the same length');

    // Safety: if state was preserved and index is out-of-range, clamp it
    if (_currentIndex >= _screens.length) {
      _currentIndex = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // final safeIndex ensures we never pass an invalid index into _screens
    final int safeIndex = (_currentIndex >= 0 && _currentIndex < _screens.length)
        ? _currentIndex
        : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: _screens[safeIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: _navItems,
        currentIndex: safeIndex,
        onTap: (int index) => setState(() {
          // extra safety in case of mismatch; choose a clamped value
          _currentIndex = (index >= 0 && index < _screens.length)
              ? index
              : (_screens.length - 1).clamp(0, _screens.length - 1);
        }),
        type: BottomNavigationBarType.fixed,
        unselectedItemColor: Colors.grey,
      ),
    );
  }
}

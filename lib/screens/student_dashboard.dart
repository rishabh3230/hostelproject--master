import 'package:flutter/material.dart';

import 'admin/complaint_screen.dart';
import 'admin/fee_details_screen.dart';
import 'admin/notices_screen.dart';
import 'admin/student_profile_screen.dart';

// Student Data Model
class StudentProfileData {
  final String rollNo;
  final String branch;
  final String roomAllotted;
  final String year;
  final String phone;
  final String feeDetails;
  final String casteCategory; // New field
  final String parentsContact; // New field

  const StudentProfileData({
    required this.rollNo,
    required this.branch,
    required this.roomAllotted,
    required this.year,
    required this.phone,
    required this.feeDetails,
    required this.casteCategory, // Required in constructor
    required this.parentsContact, // Required in constructor
  });
}

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currentIndex = 0; // Student Profile will be at index 0

  // Dummy student data - updated with new fields
  final StudentProfileData _dummyStudentData = const StudentProfileData(
    rollNo: '2021B1A7001P',
    branch: 'Computer Science',
    roomAllotted: 'H1-305',
    year: '3rd Year',
    phone: '+91 9876543210',
    feeDetails: 'Paid (Due: Jan 2025)',
    casteCategory: 'General', // Dummy value
    parentsContact: '+91 9988776655', // Dummy value
  );

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = <Widget>[
      StudentProfileScreen(
        studentData: _dummyStudentData,
      ), // Student Profile is now first
      const FeeDetailsScreen(),
      const ComplaintScreen(),
      const NoticesScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        // Background color now from theme
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (int index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
         // Ensure selected item is dark green
        unselectedItemColor: Colors.grey, // Optional: for contrast
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ), // Profile is now first
          BottomNavigationBarItem(icon: Icon(Icons.payment), label: 'Fees'),
          BottomNavigationBarItem(
            icon: Icon(Icons.report_problem),
            label: 'Complaints',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notices',
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';

import '../student_dashboard.dart';

class StudentProfileScreen extends StatelessWidget {
  final StudentProfileData studentData;

  const StudentProfileScreen({super.key, required this.studentData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          StudentProfileCard(
            rollNo: studentData.rollNo,
            branch: studentData.branch,
            roomAllotted: studentData.roomAllotted,
            year: studentData.year,
            phone: studentData.phone,
            feeDetails: studentData.feeDetails,
            casteCategory: studentData.casteCategory, // Pass new field
            parentsContact: studentData.parentsContact, // Pass new field
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'This is your detailed student profile.',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class StudentProfileCard extends StatelessWidget {
  final String rollNo;
  final String branch;
  final String roomAllotted;
  final String year;
  final String phone;
  final String feeDetails;
  final String casteCategory; // New field
  final String parentsContact; // New field

  const StudentProfileCard({
    super.key,
    required this.rollNo,
    required this.branch,
    required this.roomAllotted,
    required this.year,
    required this.phone,
    required this.feeDetails,
    required this.casteCategory, // Required in constructor
    required this.parentsContact, // Required in constructor
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
       // Light background color, adjusted
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                 // Changed avatar background to dark green
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            _profileRow("Roll No.", rollNo),
            _profileRow("Branch", branch),
            _profileRow("Room Allotted", roomAllotted),
            _profileRow("Year", year),
            _profileRow("Phone No.", phone),
            _profileRow("Caste Category", casteCategory), // Display new field
            _profileRow("Parents Contact", parentsContact), // Display new field
            _profileRow("Fee Details", feeDetails),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Text(
            "$label: ",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
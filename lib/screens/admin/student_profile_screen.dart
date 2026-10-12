import 'package:flutter/material.dart';
import '../../models/student.dart';

class StudentProfileScreen extends StatelessWidget {
  final Student studentData;

  const StudentProfileScreen({super.key, required this.studentData});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          StudentProfileCard(student: studentData),
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
  final Student student;

  const StudentProfileCard({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final String allotmentStatus = student.roomAllotted.isEmpty
        ? 'Not Allotted'
        : 'Room ${student.roomAllotted} (${student.hostelBlock})';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFF1B5E20),
                child: Icon(Icons.person, size: 50, color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            _profileRow("Name", student.name),
            _profileRow("Email", student.email),
            _profileRow("Roll No / ID", student.rollNo),
            _profileRow("Branch", student.branch),
            _profileRow("Room Allotted", allotmentStatus),
            _profileRow("Academic Year", student.year),
            _profileRow("Phone No.", student.phone),
            _profileRow("Caste Category", student.casteCategory),
            _profileRow("Parents Contact", student.parentsContact),
            _profileRow("Fee Status", student.feeStatus),
          ],
        ),
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              "$label: ",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'N/A' : value,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              softWrap: true,
            ),
          ),
        ],
      ),
    );
  }
}

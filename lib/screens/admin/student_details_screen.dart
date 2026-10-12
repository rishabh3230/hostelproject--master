import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/student.dart';
import 'student_profile_screen.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _viewStudentProfile(Student student) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: Text('${student.name}\'s Profile')),
          body: StudentProfileScreen(studentData: student),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Student Details',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search Students by Name, ID, or Branch',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Student>>(
            stream: _firestoreService.studentsStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading students: ${snapshot.error}'),
                );
              }

              final allStudents = snapshot.data ?? [];

              // Filter students
              final filteredStudents = allStudents.where((student) {
                final name = student.name.toLowerCase();
                final roll = student.rollNo.toLowerCase();
                final branch = student.branch.toLowerCase();
                return name.contains(_searchQuery) ||
                    roll.contains(_searchQuery) ||
                    branch.contains(_searchQuery);
              }).toList();

              if (filteredStudents.isEmpty) {
                return const Center(
                  child: Text(
                    'No students found.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              return ListView.builder(
                itemCount: filteredStudents.length,
                itemBuilder: (BuildContext context, int index) {
                  final student = filteredStudents[index];
                  final String roomInfo = student.roomAllotted.isEmpty
                      ? 'Room: Not Allotted'
                      : 'Room: ${student.roomAllotted} - ${student.hostelBlock}';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    child: ListTile(
                      title: Text(
                        student.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ID: ${student.rollNo}'),
                          Text('Branch: ${student.branch}'),
                          Text('Year: ${student.year}'),
                          Text(roomInfo),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(
                          Icons.visibility,
                          color: Color(0xFF1B5E20),
                        ),
                        onPressed: () => _viewStudentProfile(student),
                      ),
                      onTap: () => _viewStudentProfile(student),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

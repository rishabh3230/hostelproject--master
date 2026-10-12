import 'package:flutter/material.dart';
import '../../services/firestore_service.dart';
import '../../models/room.dart';
import '../../models/student.dart';
import 'student_profile_screen.dart';

class StudentsListScreen extends StatefulWidget {
  final String blockName;

  const StudentsListScreen({super.key, required this.blockName});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  void _viewStudentProfileByRoll(String rollNo, List<Student> students) {
    // Find student doc with this roll number
    final student = students.firstWhere(
      (s) => s.rollNo == rollNo,
      orElse: () => Student(
        id: '',
        rollNo: rollNo,
        name: 'Unknown Student',
        email: '',
        branch: '',
        year: '',
        roomAllotted: '',
        hostelBlock: '',
        phone: '',
        parentsContact: '',
        casteCategory: '',
        feeStatus: '',
        authUid: '',
      ),
    );

    if (student.id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Profile for student ID $rollNo details not found in database.',
          ),
        ),
      );
      return;
    }

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
    return Scaffold(
      appBar: AppBar(title: Text('${widget.blockName} - Room Allocation')),
      body: StreamBuilder<List<Room>>(
        stream: _firestoreService.getRoomsInBlockStream(widget.blockName),
        builder: (context, roomSnapshot) {
          if (roomSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
            );
          }
          if (roomSnapshot.hasError) {
            return Center(
              child: Text('Error loading rooms: ${roomSnapshot.error}'),
            );
          }

          final rooms = roomSnapshot.data ?? [];
          if (rooms.isEmpty) {
            return const Center(
              child: Text(
                'No rooms configured for this block.\nPlease run the seeding tool.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Sort rooms by roomNumber
          rooms.sort((a, b) => a.roomNumber.compareTo(b.roomNumber));

          return StreamBuilder<List<Student>>(
            stream: _firestoreService.studentsStream,
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                );
              }
              if (studentSnapshot.hasError) {
                return Center(
                  child: Text(
                    'Error loading students: ${studentSnapshot.error}',
                  ),
                );
              }

              final studentsList = studentSnapshot.data ?? [];

              // Helper to map rollNo to student name
              Map<String, String> rollNoToName = {
                for (var s in studentsList) s.rollNo: s.name,
              };

              return Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  itemCount: rooms.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.85,
                  ),
                  itemBuilder: (context, index) {
                    final room = rooms[index];
                    final bool hasOccupants =
                        room.occupantStudentIds.isNotEmpty;

                    return Card(
                      color: hasOccupants
                          ? Colors.green[300]
                          : Colors.grey[200],
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                'Room ${room.roomNumber}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.black26),
                            Expanded(
                              child: ListView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: room.capacity,
                                itemBuilder: (context, sIndex) {
                                  final bool occupied =
                                      sIndex < room.occupantStudentIds.length;
                                  final String roll = occupied
                                      ? room.occupantStudentIds[sIndex]
                                      : '';
                                  final String name = occupied
                                      ? (rollNoToName[roll] ?? roll)
                                      : 'Empty';

                                  return GestureDetector(
                                    onTap: occupied
                                        ? () => _viewStudentProfileByRoll(
                                            roll,
                                            studentsList,
                                          )
                                        : null,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${sIndex + 1}. ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Expanded(
                                            child: Text(
                                              name,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: occupied
                                                    ? Colors.black
                                                    : Colors.black54,
                                                fontWeight: occupied
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                                decoration: occupied
                                                    ? TextDecoration.underline
                                                    : TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

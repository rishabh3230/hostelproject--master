import 'package:flutter/material.dart';

class StudentsListScreen extends StatelessWidget {
  final String blockName;

  const StudentsListScreen({super.key, required this.blockName});

  @override
  Widget build(BuildContext context) {
    // Year-wise multiple student per room data
    Map<String, List<Map<String, dynamic>>> yearStudents = {
      '1st Year': [
        {'name': 'Aman Gupta', 'room': '101'},
        {'name': 'Rohit Kumar', 'room': '101'},
        {'name': 'Priya Singh', 'room': '101'},
        {'name': 'Vasu Mehra', 'room': '102'},
      ],
      '2nd Year': [
        {'name': 'Kunal Mehra', 'room': '201'},
        {'name': 'Simran Kaur', 'room': '201'},
      ],
      '3rd Year': [
        {'name': 'Mohit Sharma', 'room': '301'},
      ],
      '4th Year': [
        {'name': 'Aman Yadav', 'room': '401'},
        {'name': 'Sahil Khan', 'room': '401'},
      ],
    };

    // Available rooms — you can modify or load from DB
    List<String> allRooms = [
      '101', '102', '103', '104', '105',
      '201', '202', '203', '204', '205',
      '301', '302', '303', '304', '305',
      '401', '402', '403', '404', '405',
    ];

    // Fetch students for this year
    List<Map<String, dynamic>> students = yearStudents[blockName] ?? [];

    // room → list of students
    Map<String, List<String>> roomStudents = {};

    for (var room in allRooms) {
      roomStudents[room] = [];
    }

    // Fill mapping
    for (var s in students) {
      String room = s['room'];
      String name = s['name'];

      if (roomStudents.containsKey(room)) {
        roomStudents[room]!.add(name);
      }
    }

    // Ensure each room has exactly 3 slots
    for (var room in roomStudents.keys) {
      while (roomStudents[room]!.length < 3) {
        roomStudents[room]!.add("Empty");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('$blockName - Room Allocation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          itemCount: allRooms.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, // 2 rooms per row
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemBuilder: (context, index) {
            String room = allRooms[index];
            List<String> threeStudents = roomStudents[room]!;

            // Check if room has at least one student
            bool filled = threeStudents.any((s) => s != "Empty");

            return Card(
              color: filled ? Colors.green[300] : Colors.grey[200],
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room number
                    Center(
                      child: Text(
                        room,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Divider(),

                    // 3 student slots
                    for (int i = 0; i < 3; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          '${i + 1}. ${threeStudents[i]}',
                          style: TextStyle(
                            fontSize: 14,
                            color: threeStudents[i] == "Empty"
                                ? Colors.black54
                                : Colors.black,
                            fontWeight: threeStudents[i] == "Empty"
                                ? FontWeight.normal
                                : FontWeight.w600,
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
    );
  }
}

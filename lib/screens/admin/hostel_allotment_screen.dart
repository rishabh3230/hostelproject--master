import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../models/student.dart';

class HostelAllotmentScreen extends StatefulWidget {
  const HostelAllotmentScreen({super.key});

  @override
  State<HostelAllotmentScreen> createState() => _HostelAllotmentScreenState();
}

class _HostelAllotmentScreenState extends State<HostelAllotmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _studentIdController = TextEditingController();
  final TextEditingController _roomNumberController = TextEditingController();

  String _selectedBlock = '1st Year';
  bool _isAllotting = false;

  final FirestoreService _firestoreService = FirestoreService();

  @override
  void dispose() {
    _studentIdController.dispose();
    _roomNumberController.dispose();
    super.dispose();
  }

  void _allotRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isAllotting = true;
    });

    final String rawStudentId = _studentIdController.text.trim();
    final String roomNo = _roomNumberController.text.trim();
    final String block = _selectedBlock;

    try {
      // 1. Look up student by rollNo specifically
      final studentQuery = await FirebaseFirestore.instance
          .collection('students')
          .where('rollNo', isEqualTo: rawStudentId)
          .limit(1)
          .get();

      if (studentQuery.docs.isEmpty) {
        throw Exception(
          'Student ID / Roll No "$rawStudentId" not found in registration.',
        );
      }

      final studentDoc = studentQuery.docs.first;
      final String studentDocId = studentDoc.id;

      // 2. Perform allotment transaction
      await _firestoreService.allotRoom(
        studentId: studentDocId,
        roomNumber: roomNo,
        hostelBlock: block,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Room $roomNo allotted successfully to $rawStudentId!'),
          backgroundColor: Colors.green,
        ),
      );

      _studentIdController.clear();
      _roomNumberController.clear();
      setState(() {
        _selectedBlock = '1st Year';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Allotment failed: ${e.toString().replaceAll('Exception: ', '')}',
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAllotting = false;
        });
      }
    }
  }

  void _vacate(Student student) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vacate Student'),
        content: Text(
          'Are you sure you want to vacate ${student.name} (${student.rollNo}) from Room ${student.roomAllotted}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _firestoreService.vacateStudent(student.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${student.name} vacated successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Vacate failed: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Vacate'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hostel Allotment',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _studentIdController,
                        decoration: const InputDecoration(
                          labelText: 'Student ID / Roll No',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter Student ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _roomNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Room Number (e.g. 101)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter Room Number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedBlock,
                        decoration: const InputDecoration(
                          labelText: 'Hostel Block / Year group',
                          border: OutlineInputBorder(),
                        ),
                        items: const <DropdownMenuItem<String>>[
                          DropdownMenuItem<String>(
                            value: '1st Year',
                            child: Text('1st Year'),
                          ),
                          DropdownMenuItem<String>(
                            value: '2nd Year',
                            child: Text('2nd Year'),
                          ),
                          DropdownMenuItem<String>(
                            value: '3rd Year',
                            child: Text('3rd Year'),
                          ),
                          DropdownMenuItem<String>(
                            value: '4th Year',
                            child: Text('4th Year'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedBlock = val;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      _isAllotting
                          ? const CircularProgressIndicator(
                              color: Color(0xFF1B5E20),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _allotRoom,
                                child: const Text('Allot Room'),
                              ),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Current Allotments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            StreamBuilder<List<Student>>(
              stream: _firestoreService.studentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(
                        color: Color(0xFF1B5E20),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Text('Error loading allotments: ${snapshot.error}');
                }

                final students = snapshot.data ?? [];
                final allottedStudents = students
                    .where((s) => s.roomAllotted.isNotEmpty)
                    .toList();

                if (allottedStudents.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        'No room allotments found.',
                        style: TextStyle(color: Colors.grey, fontSize: 15),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: allottedStudents.length,
                  itemBuilder: (BuildContext context, int index) {
                    final student = allottedStudents[index];

                    return Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.person,
                          color: Color(0xFF1B5E20),
                        ),
                        title: Text(student.name),
                        subtitle: Text(
                          'Room ${student.roomAllotted} - ${student.hostelBlock} (${student.rollNo})',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          tooltip: 'Vacate Student',
                          onPressed: () => _vacate(student),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

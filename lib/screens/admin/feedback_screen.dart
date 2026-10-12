import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/feedback_model.dart';
import '../../models/student.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  bool _isAdmin = false;
  bool _isLoadingRole = true;

  // Form fields
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _messageController = TextEditingController();
  double _rating = 5.0;
  String _selectedCategory = 'Cleanliness';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _checkRole() async {
    final user = _authService.currentUser;
    if (user != null) {
      final isAdm = await _authService.isAdmin(user.uid);
      if (mounted) {
        setState(() {
          _isAdmin = isAdm;
          _isLoadingRole = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoadingRole = false;
        });
      }
    }
  }

  void _submitFeedback(Student student) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final feedback = FeedbackModel(
        id: '',
        studentId: student.rollNo,
        studentName: student.name,
        roomNo: student.roomAllotted.isEmpty ? 'N/A' : student.roomAllotted,
        message: _messageController.text.trim(),
        rating: _rating,
        category: _selectedCategory,
        createdAt: DateTime.now(),
      );

      await _firestoreService.submitFeedback(feedback);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Feedback submitted successfully! Thank you.'),
          backgroundColor: Colors.green,
        ),
      );

      _messageController.clear();
      setState(() {
        _rating = 5.0;
        _selectedCategory = 'Cleanliness';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit feedback: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Widget _buildStudentForm() {
    return StreamBuilder<Student?>(
      stream: _authService.currentStudentProfile,
      builder: (context, studentSnapshot) {
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
          );
        }

        final student = studentSnapshot.data;
        if (student == null) {
          return const Center(
            child: Text('Failed to retrieve student context.'),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Submit Feedback',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _selectedCategory,
                          decoration: const InputDecoration(
                            labelText: 'Feedback Category',
                            border: OutlineInputBorder(),
                          ),
                          items: const <DropdownMenuItem<String>>[
                            DropdownMenuItem<String>(
                              value: 'Cleanliness',
                              child: Text('Cleanliness'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Food Quality',
                              child: Text('Food Quality'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Staff Behavior',
                              child: Text('Staff Behavior'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Infrastructure',
                              child: Text('Infrastructure'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Security',
                              child: Text('Security'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'WiFi',
                              child: Text('WiFi / Internet'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Maintenance',
                              child: Text('Maintenance'),
                            ),
                            DropdownMenuItem<String>(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedCategory = val;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Rating:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            final double starValue = index + 1.0;
                            return IconButton(
                              icon: Icon(
                                starValue <= _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 36,
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating = starValue;
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _messageController,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            labelText: 'Your Feedback Description',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please describe your request/satisfaction';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        _isSubmitting
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF1B5E20),
                                ),
                              )
                            : SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () => _submitFeedback(student),
                                  child: const Text('Submit Feedback'),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAdminList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Student Feedback',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<FeedbackModel>>(
            stream: _firestoreService.feedbackStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error loading feedback: ${snapshot.error}'),
                );
              }

              final feedbacks = snapshot.data ?? [];
              if (feedbacks.isEmpty) {
                return const Center(
                  child: Text(
                    'No feedback submissions found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                );
              }

              return ListView.builder(
                itemCount: feedbacks.length,
                itemBuilder: (BuildContext context, int index) {
                  final feedback = feedbacks[index];
                  final String studentHeader = feedback.studentName;
                  final String roomHeader = feedback.roomNo == 'N/A'
                      ? 'No room allotted'
                      : 'Room ${feedback.roomNo}';

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    studentHeader,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    roomHeader,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Chip(
                                label: Text(feedback.category),
                                backgroundColor: const Color(
                                  0xFF1B5E20,
                                ).withValues(alpha: 0.1),
                                labelStyle: const TextStyle(
                                  color: Color(0xFF1B5E20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            feedback.message,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: List.generate(5, (starIdx) {
                              return Icon(
                                starIdx < feedback.rating
                                    ? Icons.star
                                    : Icons.star_border,
                                color: Colors.amber,
                                size: 20,
                              );
                            }),
                          ),
                        ],
                      ),
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

  @override
  Widget build(BuildContext context) {
    if (_isLoadingRole) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF1B5E20)),
        ),
      );
    }

    return Scaffold(body: _isAdmin ? _buildAdminList() : _buildStudentForm());
  }
}

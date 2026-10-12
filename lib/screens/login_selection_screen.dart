import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import 'admin_login_screen.dart';
import 'student_login_screen.dart';

class LoginSelectionScreen extends StatefulWidget {
  const LoginSelectionScreen({super.key});

  @override
  State<LoginSelectionScreen> createState() => _LoginSelectionScreenState();
}

class _LoginSelectionScreenState extends State<LoginSelectionScreen> {
  bool _isSeeding = false;

  Future<void> _handleSeeding() async {
    setState(() {
      _isSeeding = true;
    });

    try {
      await FirestoreService().seedDatabase();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Success! Seeded test Admins, Students, and Rooms in Firestore. Password: password123',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seeding failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSeeding = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.apartment, size: 100, color: Color(0xFF1B5E20)),
              const SizedBox(height: 20),
              const Text(
                'IERT Hostel',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B5E20),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hostel Management System',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Admin Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<AdminLoginScreen>(
                        builder: (context) => const AdminLoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Admin Login',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Student Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<StudentLoginScreen>(
                        builder: (context) => const StudentLoginScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Student Login',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              const Divider(),
              const SizedBox(height: 16),

              // Diagnostic Seeding utility
              _isSeeding
                  ? const CircularProgressIndicator(color: Color(0xFF1B5E20))
                  : TextButton.icon(
                      onPressed: _handleSeeding,
                      icon: const Icon(
                        Icons.cloud_download,
                        color: Color(0xFF1B5E20),
                      ),
                      label: const Text(
                        'Seed Firebase Test Data',
                        style: TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
              const SizedBox(height: 8),
              const Text(
                'Note: Click this once to seed Firebase Auth + Firestore profiles (admin@hostel.com, student1@hostel.com, etc.).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

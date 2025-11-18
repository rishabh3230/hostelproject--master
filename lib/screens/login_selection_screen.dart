import 'package:flutter/material.dart';
import 'admin_login_screen.dart';
import 'student_login_screen.dart';

class LoginSelectionScreen extends StatelessWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.apartment,
                size: 120, // Changed icon color to dark green
              ),
              const SizedBox(height: 30),
              const Text(
                'IERT Hostel', // Changed app name here as well
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  // Changed text color to dark green
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Choose your login type',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 50),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<AdminLoginScreen>(
                        builder: (context) => const AdminLoginScreen(),
                      ),
                    );
                  },
                  // Style inherited from theme now, removed explicit backgroundColor
                  child: const Text(
                    'Admin Login',
                    style: TextStyle(fontSize: 18), // Color is white from theme
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<StudentLoginScreen>(
                        builder: (context) => const StudentLoginScreen(),
                      ),
                    );
                  },
                  // Style inherited from theme now, removed explicit backgroundColor
                  child: const Text(
                    'Student Login',
                    style: TextStyle(fontSize: 18), // Color is white from theme
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
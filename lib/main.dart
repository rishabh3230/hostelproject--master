import 'package:flutter/material.dart';
import 'package:hms/screens/admin_dashboard.dart';
import 'package:hms/screens/login_selection_screen.dart';
import 'package:hms/screens/student_dashboard.dart';

import 'package:firebase_core/firebase_core.dart'; // Add this import
import 'firebase_options.dart'; // Mak
// Define a consistent dark green color for the theme
const Color _darkGreen = Color(
  0xFF1B5E20,
); // A dark shade of green, equivalent to Colors.green[800]


void main() async {
  WidgetsFlutterBinding.ensureInitialized();u
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(const HostelManagementApp());
}


class HostelManagementApp extends StatelessWidget {
  const HostelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IERT Hostel', // Changed app name
      theme: ThemeData(
        primaryColor: _darkGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _darkGreen,
          primary: _darkGreen,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkGreen, // Dark green app bar
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor:
            _darkGreen, // Dark green elevated buttons by default
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15),
          ),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginSelectionScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/studentDashboard': (context) => const StudentDashboard(),
      },
    );
  }
}
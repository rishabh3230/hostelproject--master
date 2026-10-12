import 'package:flutter/material.dart';
import 'package:hms/screens/admin_dashboard.dart';
import 'package:hms/screens/login_selection_screen.dart';
import 'package:hms/screens/student_dashboard.dart';
import 'package:hms/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

const Color _darkGreen = Color(0xFF1B5E20);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const HostelManagementApp());
}

class HostelManagementApp extends StatelessWidget {
  const HostelManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IERT Hostel',
      theme: ThemeData(
        primaryColor: _darkGreen,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _darkGreen,
          primary: _darkGreen,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _darkGreen,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _darkGreen,
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
        '/': (context) => const AuthGate(),
        '/loginSelection': (context) => const LoginSelectionScreen(),
        '/adminDashboard': (context) => const AdminDashboard(),
        '/studentDashboard': (context) => const StudentDashboard(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // Auth state loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: _darkGreen)),
          );
        }

        final User? user = snapshot.data;
        if (user == null) {
          return const LoginSelectionScreen();
        }

        // Authenticated. Check if admin or student.
        return FutureBuilder<bool>(
          future: authService.isAdmin(user.uid),
          builder: (context, adminSnapshot) {
            if (adminSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: _darkGreen),
                ),
              );
            }
            final bool isAdminProfile = adminSnapshot.data ?? false;

            if (isAdminProfile) {
              return const AdminDashboard();
            } else {
              return const StudentDashboard();
            }
          },
        );
      },
    );
  }
}

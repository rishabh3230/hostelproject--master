import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'providers/session_provider.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kIsWeb) await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);
    if (!kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS)) {
      FirebaseMessaging.onBackgroundMessage(backgroundMessage);
    }
    runApp(
      ChangeNotifierProvider(
        create: (_) => SessionProvider(),
        child: const HostelManagementApp(),
      ),
    );
  } catch (error) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SelectableText(
                'Firebase setup failed. Run flutterfire configure for this platform.\n\n$error',
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HostelManagementApp extends StatelessWidget {
  const HostelManagementApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'IERT Hostel',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF176B52)),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    ),
    home: const AuthGate(),
  );
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    if (session.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (session.user == null) return const AuthScreen();
    if (session.error != null ||
        session.account == null ||
        session.account!.provisioning) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  session.error ??
                      'Your account is still being provisioned. Ask the administrator to retry the allotment.',
                ),
                TextButton(
                  onPressed: session.signOut,
                  child: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (session.account!.mustChangePassword) {
      return const PasswordScreen(forced: true);
    }
    // A keyed Navigator removes every old role/user route when authentication changes.
    return Navigator(
      key: ValueKey('${session.account!.uid}:${session.account!.role}'),
      onGenerateRoute: (_) =>
          MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }
}

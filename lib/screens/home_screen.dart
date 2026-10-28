import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/session_provider.dart';
import '../widgets/live_list.dart';
import 'auth_screen.dart';
import 'students_screen.dart';
import 'rooms_screen.dart';
import 'posts_screen.dart';
import 'payments_screen.dart';
import 'feedback_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selected = 0;
  StreamSubscription<RemoteMessage>? messages;
  @override
  void initState() {
    super.initState();
    messages = FirebaseMessaging.onMessage.listen((message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.title ?? 'Hostel update'),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    messages?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>(),
        admin = session.account!.isAdmin;
    final labels = [
      admin ? 'Students' : 'My fees',
      'Rooms',
      'Notices',
      'Complaints',
      'Feedback',
    ];
    const icons = [
      Icons.people_outline,
      Icons.apartment,
      Icons.campaign_outlined,
      Icons.support_agent,
      Icons.rate_review_outlined,
    ];
    final pages = <Widget>[
      admin
          ? const StudentsScreen()
          : PaymentsScreen(uid: session.account!.uid),
      RoomsScreen(admin: admin),
      PostsScreen(notice: true, admin: admin),
      PostsScreen(notice: false, admin: admin),
      FeedbackScreen(admin: admin),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 800;
        return Scaffold(
          appBar: AppBar(
            title: Text('IERT • ${labels[selected]}'),
            actions: [
              IconButton(
                tooltip: 'Enable notifications',
                onPressed: () => runAction(
                  context,
                  session.notifications.enable,
                  success: 'Notifications enabled',
                ),
                icon: const Icon(Icons.notifications_outlined),
              ),
              if (!admin)
                IconButton(
                  tooltip: 'Change password',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PasswordScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.password),
                ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: () => runAction(context, session.signOut),
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
          body: Row(
            children: [
              if (wide)
                NavigationRail(
                  selectedIndex: selected,
                  onDestinationSelected: (i) => setState(() => selected = i),
                  labelType: NavigationRailLabelType.all,
                  destinations: List.generate(
                    labels.length,
                    (i) => NavigationRailDestination(
                      icon: Icon(icons[i]),
                      label: Text(labels[i]),
                    ),
                  ),
                ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: IndexedStack(index: selected, children: pages),
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: selected,
                  onDestinationSelected: (i) => setState(() => selected = i),
                  destinations: List.generate(
                    labels.length,
                    (i) => NavigationDestination(
                      icon: Icon(icons[i]),
                      label: labels[i],
                    ),
                  ),
                ),
        );
      },
    );
  }
}

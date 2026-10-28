import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/account.dart';
import '../services/hms_service.dart';
import '../services/notification_service.dart';

class SessionProvider extends ChangeNotifier {
  final FirebaseAuth _auth;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  final notifications = NotificationService();
  Account? account;
  bool loading = true;
  String? error;
  int _generation = 0;
  SessionProvider() : _auth = FirebaseAuth.instance {
    _authSubscription = _auth.authStateChanges().listen(
      _loadUser,
      onError: (Object e) {
        error = friendlyError(e);
        loading = false;
        notifyListeners();
      },
    );
  }
  User? get user => _auth.currentUser;
  Future<void> _loadUser(User? user) async {
    final generation = ++_generation;
    await _profileSubscription?.cancel();
    account = null;
    error = null;
    loading = user != null;
    notifyListeners();
    if (user == null) return;
    try {
      final claims = (await user.getIdTokenResult(true)).claims;
      if (generation != _generation) return;
      _profileSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen(
            (snapshot) {
              if (generation != _generation) return;
              loading = false;
              if (!snapshot.exists) {
                account = null;
                error =
                    'No hostel account is assigned to this login. Contact the administrator.';
              } else {
                final next = Account.fromMap(user.uid, snapshot.data()!);
                if (!['admin', 'student'].contains(next.role) ||
                    claims?['role'] != next.role) {
                  account = null;
                  error =
                      'Your account role is not configured. Contact the administrator, then sign in again.';
                } else {
                  account = next;
                  error = null;
                }
              }
              notifyListeners();
            },
            onError: (Object e) {
              if (generation == _generation) {
                account = null;
                error = friendlyError(e);
                loading = false;
                notifyListeners();
              }
            },
          );
    } catch (e) {
      if (generation == _generation) {
        error = friendlyError(e);
        loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> signIn({
    required bool admin,
    required String login,
    required String password,
  }) async {
    final normalized = login.trim().toLowerCase();
    if (!admin && !RegExp(r'^[a-z0-9][a-z0-9_-]{1,39}$').hasMatch(normalized)) {
      throw Exception('Enter a valid roll number.');
    }
    await _auth.signInWithEmailAndPassword(
      email: admin ? normalized : '$normalized@hms.app',
      password: password,
    );
  }

  Future<void> changePassword(String current, String password) async {
    final user = _auth.currentUser!;
    await user.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: current),
    );
    await HmsService().call('changePassword', {'password': password});
    await signOut();
  }

  Future<void> signOut() async {
    await notifications.disable();
    await _auth.signOut();
  }

  @override
  void dispose() {
    _generation++;
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    notifications.dispose();
    super.dispose();
  }
}

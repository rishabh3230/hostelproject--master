import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Sign in as student using Student ID/Roll Number
  Future<User?> signInWithStudentId(String rollNo, String password) async {
    // 1. Look up student by rollNo (case-insensitive query is ideal, or exact match)
    final query = await _firestore
        .collection('students')
        .where('rollNo', isEqualTo: rollNo.trim())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No student profile found with Roll No: $rollNo',
      );
    }

    final studentDoc = query.docs.single;
    final String email = studentDoc.get('email') as String? ?? '';

    if (email.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Email associated with this Roll No is missing.',
      );
    }

    // 2. Perform FirebaseAuth sign in
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // 3. Update the student document authUid with current UID if it's missing or changed
    if (userCredential.user != null) {
      final String uid = userCredential.user!.uid;
      if (studentDoc.get('authUid') != uid) {
        await studentDoc.reference.update({'authUid': uid});
      }
    }

    return userCredential.user;
  }

  // Sign in as admin with Email and Password
  Future<User?> signInAdmin(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final User? user = userCredential.user;
    if (user != null) {
      final adminRef = _firestore.collection('admins').doc(user.uid);
      final adminDoc = await adminRef.get();

      if (!adminDoc.exists) {
        // Doc is missing — attempt to create it (allowed by security rules
        // when adminId == request.auth.uid).
        // This self-heals the first-time seeding race condition.
        try {
          await adminRef.set({
            'name': 'System Administrator',
            'email': user.email ?? email,
            'authUid': user.uid,
          });
        } catch (_) {
          // If the set also fails, the user is truly not an admin.
          await _auth.signOut();
          throw FirebaseAuthException(
            code: 'operation-not-allowed',
            message:
                'Access denied. You are not registered as an Administrator.',
          );
        }
      }
    }
    return user;
  }

  // Check if a UID belongs to an admin
  Future<bool> isAdmin(String uid) async {
    try {
      final doc = await _firestore.collection('admins').doc(uid).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  // Get current logged-in student's live profile
  Stream<Student?> get currentStudentProfile {
    final User? user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    // Query by authUid
    return _firestore
        .collection('students')
        .where('authUid', isEqualTo: user.uid)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Student.fromFirestore(snapshot.docs.first);
        });
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}

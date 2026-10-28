import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import '../models/room_input.dart';

typedef Data = Map<String, dynamic>;

class HmsService {
  final db = FirebaseFirestore.instance;
  final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');
  String get uid => FirebaseAuth.instance.currentUser!.uid;
  Future<void> saveRoom(RoomInput input) async {
    if (input.error != null) throw Exception(input.error);
    final ref = db.collection('rooms').doc(input.id);
    await db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) {
        transaction.set(ref, {
          'block': input.block,
          'number': input.number,
          'capacity': input.capacity,
          'occupied': 0,
          'occupantIds': <String>[],
        });
        return;
      }
      final data = snapshot.data()!;
      final occupants = data['occupantIds'];
      if (occupants is! List || data['occupied'] != occupants.length) {
        throw Exception(
          'This room needs occupancy reconciliation before editing.',
        );
      }
      if (input.capacity < occupants.length) {
        throw Exception('Capacity cannot be below the number of occupants.');
      }
      transaction.update(ref, {'capacity': input.capacity});
    });
  }

  Future<Data> call(String name, Data data) async => Map<String, dynamic>.from(
    (await functions.httpsCallable(name).call(data)).data as Map,
  );
  Stream<DocumentSnapshot<Data>> profile(String uid) =>
      db.collection('students').doc(uid).snapshots();
  Stream<QuerySnapshot<Data>> students() =>
      db.collection('students').orderBy('name').snapshots();
  Stream<QuerySnapshot<Data>> rooms() =>
      db.collection('rooms').orderBy('block').snapshots();
  Stream<QuerySnapshot<Data>> notices() => db
      .collection('notices')
      .orderBy('createdAt', descending: true)
      .snapshots();
  Stream<QuerySnapshot<Data>> complaints(bool admin) {
    Query<Data> query = db.collection('complaints');
    if (!admin) query = query.where('studentId', isEqualTo: uid);
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot<Data>> payments(String studentUid) => db
      .collection('payments')
      .where('uid', isEqualTo: studentUid)
      .orderBy('createdAt', descending: true)
      .snapshots();
  Future<PlatformFile?> pickAttachment() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'txt'],
      withData: true,
    );
    if (result == null) return null;
    final file = result.files.single;
    if (file.size > 5 * 1024 * 1024 || file.bytes == null) {
      throw Exception('Choose a readable file smaller than 5 MB.');
    }
    return file;
  }

  Future<void> publish({
    required bool notice,
    required String title,
    required String body,
    PlatformFile? file,
  }) async {
    final ref = db.collection(notice ? 'notices' : 'complaints').doc();
    final path = file == null
        ? ''
        : notice
        ? 'notices/${ref.id}/attachment'
        : 'complaints/$uid/${ref.id}/attachment';
    if (file != null) {
      final mime = switch (file.extension?.toLowerCase()) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'pdf' => 'application/pdf',
        _ => 'text/plain',
      };
      await FirebaseStorage.instance
          .ref(path)
          .putData(file.bytes!, SettableMetadata(contentType: mime));
    }
    // Keep an uploaded object on an ambiguous network failure: the Firestore write may have committed.
    // Storage lifecycle cleanup can remove genuinely orphaned objects after reconciliation.
    await ref.set({
      'title': title.trim(),
      if (notice) 'body': body.trim() else 'description': body.trim(),
      'attachmentPath': path,
      'createdAt': FieldValue.serverTimestamp(),
      if (notice)
        'postedBy': uid
      else ...{
        'studentId': uid,
        'status': 'open',
        'remark': '',
      },
    });
  }

  Future<Uint8List?> attachment(String path) =>
      FirebaseStorage.instance.ref(path).getData(5 * 1024 * 1024);
  Future<void> resolve(String id, String remark) =>
      db.collection('complaints').doc(id).update({
        'status': 'resolved',
        'remark': remark.trim(),
        'resolvedAt': FieldValue.serverTimestamp(),
      });
}

String friendlyError(Object error) {
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Incorrect login or password.',
      'network-request-failed' =>
        'Cannot connect. Check your internet connection.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'user-disabled' =>
        'This account is disabled. Contact the hostel administrator.',
      'invalid-email' => 'Enter a valid email or roll number.',
      _ => error.message ?? 'Sign-in failed.',
    };
  }
  if (error is FirebaseFunctionsException) {
    if (['internal', 'not-found', 'unavailable'].contains(error.code)) {
      return 'The backend service is unavailable. Check that Cloud Functions is deployed for hostel-iert in asia-south1.';
    }
    return error.message ?? 'The request failed. Try again.';
  }
  if (error is FirebaseException) {
    return error.message ??
        'Unable to load data. Check your connection and access.';
  }
  return error.toString().replaceFirst('Exception: ', '');
}

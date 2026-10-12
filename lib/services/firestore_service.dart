import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/student.dart';
import '../models/complaint.dart';
import '../models/fee.dart';
import '../models/notice.dart';
import '../models/feedback_model.dart';
import '../models/room.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // -------------------------------------------------------------
  // STUDENTS
  // -------------------------------------------------------------

  // Stream of all students
  Stream<List<Student>> get studentsStream {
    return _db.collection('students').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
    });
  }

  // Get a specific student's profile stream
  Stream<Student?> getStudentStream(String studentId) {
    return _db.collection('students').doc(studentId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return Student.fromFirestore(doc);
    });
  }

  // Add/Update student
  Future<void> saveStudent(Student student) async {
    await _db
        .collection('students')
        .doc(student.id)
        .set(student.toFirestore(), SetOptions(merge: true));
  }

  // -------------------------------------------------------------
  // COMPLAINTS
  // -------------------------------------------------------------

  // Stream complaints for a student ordered by createdAt descending
  Stream<List<Complaint>> studentComplaintsStream(String studentId) {
    return _db
        .collection('complaints')
        .where('studentId', isEqualTo: studentId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Complaint.fromFirestore(doc))
              .toList();
        });
  }

  // Stream all complaints (for admin)
  Stream<List<Complaint>> get allComplaintsStream {
    return _db
        .collection('complaints')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => Complaint.fromFirestore(doc))
              .toList();
        });
  }

  // File new complaint
  Future<void> submitComplaint(Complaint complaint) async {
    await _db.collection('complaints').add(complaint.toFirestore());
  }

  // Update complaint status (Admin only)
  Future<void> updateComplaintStatus(
    String complaintId,
    String newStatus,
  ) async {
    await _db.collection('complaints').doc(complaintId).update({
      'status': newStatus,
    });
  }

  // -------------------------------------------------------------
  // FEES
  // -------------------------------------------------------------

  // Stream fees for a student
  Stream<List<Fee>> studentFeesStream(String studentId) {
    return _db
        .collection('fees')
        .where('studentId', isEqualTo: studentId)
        .orderBy('dueDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Fee.fromFirestore(doc)).toList();
        });
  }

  // Stream all fees (Admin)
  Stream<List<Fee>> get allFeesStream {
    return _db.collection('fees').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Fee.fromFirestore(doc)).toList();
    });
  }

  // Submit/Add fee record
  Future<void> addFeeRecord(Fee fee) async {
    await _db.collection('fees').add(fee.toFirestore());
  }

  // Update fee status (Admin or Student payment simulation)
  Future<void> updateFeeStatus(
    String feeId,
    String status, {
    DateTime? paidOn,
    String paymentMethod = 'Online',
  }) async {
    await _db.collection('fees').doc(feeId).update({
      'status': status,
      'paidOn': paidOn != null ? Timestamp.fromDate(paidOn) : null,
      'paymentMethod': paymentMethod,
    });
  }

  // -------------------------------------------------------------
  // NOTICES
  // -------------------------------------------------------------

  // Stream notices sorted by newest first
  Stream<List<Notice>> get noticesStream {
    return _db
        .collection('notices')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Notice.fromFirestore(doc)).toList();
        });
  }

  // Submit Notice (Admin)
  Future<void> postNotice(Notice notice) async {
    await _db.collection('notices').add(notice.toFirestore());
  }

  // -------------------------------------------------------------
  // FEEDBACK
  // -------------------------------------------------------------

  // Stream feedbacks (Admin only)
  Stream<List<FeedbackModel>> get feedbackStream {
    return _db
        .collection('feedback')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FeedbackModel.fromFirestore(doc))
              .toList();
        });
  }

  // Submit feedback (Student)
  Future<void> submitFeedback(FeedbackModel feedback) async {
    await _db.collection('feedback').add(feedback.toFirestore());
  }

  // -------------------------------------------------------------
  // ROOMS
  // -------------------------------------------------------------

  // Stream rooms list
  Stream<List<Room>> get roomsStream {
    return _db.collection('rooms').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
    });
  }

  // Stream rooms for a specific block
  Stream<List<Room>> getRoomsInBlockStream(String block) {
    return _db
        .collection('rooms')
        .where('hostelBlock', isEqualTo: block)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => Room.fromFirestore(doc)).toList();
        });
  }

  // Allot Room Transaction:
  // Coordinates room occupant change & updates student profile.
  Future<void> allotRoom({
    required String
    studentId, // references the student doc ID (e.g. rollNo or uid)
    required String roomNumber,
    required String hostelBlock,
  }) async {
    // 1. We must find the room matching the block & roomNumber
    final roomQuery = await _db
        .collection('rooms')
        .where('roomNumber', isEqualTo: roomNumber)
        .where('hostelBlock', isEqualTo: hostelBlock)
        .limit(1)
        .get();

    if (roomQuery.docs.isEmpty) {
      throw Exception('Room $roomNumber in block $hostelBlock not found.');
    }

    final DocumentReference roomRef = roomQuery.docs.first.reference;
    final DocumentReference studentRef = _db
        .collection('students')
        .doc(studentId);

    // Fetch student's current room assignment to see if we need to vacate them from an old room
    final studentSnapshotOuter = await studentRef.get();
    if (!studentSnapshotOuter.exists) {
      throw Exception('Student snapshot does not exist.');
    }
    final Student studentOuter = Student.fromFirestore(studentSnapshotOuter);

    DocumentReference? oldRoomRef;
    if (studentOuter.roomAllotted.isNotEmpty &&
        studentOuter.hostelBlock.isNotEmpty) {
      // Find the old room
      final oldRoomQuery = await _db
          .collection('rooms')
          .where('roomNumber', isEqualTo: studentOuter.roomAllotted)
          .where('hostelBlock', isEqualTo: studentOuter.hostelBlock)
          .limit(1)
          .get();
      if (oldRoomQuery.docs.isNotEmpty) {
        oldRoomRef = oldRoomQuery.docs.first.reference;
      }
    }

    await _db.runTransaction((transaction) async {
      final roomSnapshot = await transaction.get(roomRef);
      final studentSnapshot = await transaction.get(studentRef);
      final DocumentSnapshot? oldRoomSnapshot =
          oldRoomRef != null ? await transaction.get(oldRoomRef) : null;

      if (!roomSnapshot.exists) {
        throw Exception('Room snapshot does not exist.');
      }
      if (!studentSnapshot.exists) {
        throw Exception('Student snapshot does not exist.');
      }

      final Room room = Room.fromFirestore(roomSnapshot);
      final Student student = Student.fromFirestore(studentSnapshot);

      // Verify availability
      if (room.isFull && !room.occupantStudentIds.contains(student.rollNo)) {
        throw Exception('Room $roomNumber is already full.');
      }

      // If student was already in a different room, vacate them first
      if (oldRoomSnapshot != null && oldRoomSnapshot.exists) {
        final Room oldRoom = Room.fromFirestore(oldRoomSnapshot);
        if (oldRoom.roomNumber != roomNumber ||
            oldRoom.hostelBlock != hostelBlock) {
          List<String> oldOccupants = List<String>.from(
            oldRoom.occupantStudentIds,
          );
          if (oldOccupants.contains(student.rollNo)) {
            oldOccupants.remove(student.rollNo);
            transaction.update(oldRoomRef!, {
              'occupantStudentIds': oldOccupants,
              'occupiedCount': oldOccupants.length,
            });
          }
        }
      }

      List<String> occupants = List<String>.from(room.occupantStudentIds);

      // If student is already in this room, do nothing
      if (!occupants.contains(student.rollNo)) {
        occupants.add(student.rollNo);

        transaction.update(roomRef, {
          'occupantStudentIds': occupants,
          'occupiedCount': occupants.length,
        });
      }

      // Update student profile
      transaction.update(studentRef, {
        'roomAllotted': roomNumber,
        'hostelBlock': hostelBlock,
      });
    });
  }

  // Vacate student from room
  Future<void> vacateStudent(String studentId) async {
    final studentRef = _db.collection('students').doc(studentId);
    final studentSnapshot = await studentRef.get();
    if (!studentSnapshot.exists) return;

    final studentObj = Student.fromFirestore(studentSnapshot);
    if (studentObj.roomAllotted.isEmpty) return;

    final roomQuery = await _db
        .collection('rooms')
        .where('roomNumber', isEqualTo: studentObj.roomAllotted)
        .where('hostelBlock', isEqualTo: studentObj.hostelBlock)
        .limit(1)
        .get();

    if (roomQuery.docs.isEmpty) {
      // Just clear student fields
      await studentRef.update({'roomAllotted': '', 'hostelBlock': ''});
      return;
    }

    final DocumentReference roomRef = roomQuery.docs.first.reference;

    await _db.runTransaction((transaction) async {
      final roomSnap = await transaction.get(roomRef);
      if (!roomSnap.exists) return;

      final roomObj = Room.fromFirestore(roomSnap);
      List<String> occupants = List<String>.from(roomObj.occupantStudentIds);

      if (occupants.contains(studentObj.rollNo)) {
        occupants.remove(studentObj.rollNo);
        transaction.update(roomRef, {
          'occupantStudentIds': occupants,
          'occupiedCount': occupants.length,
        });
      }

      transaction.update(studentRef, {'roomAllotted': '', 'hostelBlock': ''});
    });
  }

  // Seed Database with test data
  // Strategy: create admin Auth account → sign in → write all Firestore data
  // (security rules require authentication for writes)
  Future<void> seedDatabase() async {
    final auth = FirebaseAuth.instance;

    // ── STEP 1: Create admin Firebase Auth account ──────────────────────────
    String adminUid;
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: 'admin@hostel.com',
        password: 'password123',
      );
      adminUid = cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // Admin already exists — sign in to get their UID
        final cred = await auth.signInWithEmailAndPassword(
          email: 'admin@hostel.com',
          password: 'password123',
        );
        adminUid = cred.user!.uid;
      } else {
        rethrow;
      }
    }

    // ── STEP 2: Ensure admin is signed in (satisfies Firestore security rules) ─
    if (auth.currentUser == null || auth.currentUser!.uid != adminUid) {
      await auth.signInWithEmailAndPassword(
        email: 'admin@hostel.com',
        password: 'password123',
      );
    }

    // ── STEP 3: Write admin doc to Firestore (now authenticated) ────────────
    await _db.collection('admins').doc(adminUid).set({
      'name': 'System Administrator',
      'email': 'admin@hostel.com',
      'authUid': adminUid,
    }, SetOptions(merge: true));

    // ── STEP 4: Seed Rooms ───────────────────────────────────────────────────
    final roomsCount = await _db.collection('rooms').limit(1).get();
    if (roomsCount.docs.isEmpty) {
      final blocks = ['1st Year', '2nd Year', '3rd Year', '4th Year'];
      for (final block in blocks) {
        for (int i = 101; i <= 105; i++) {
          await _db.collection('rooms').add({
            'roomNumber': i.toString(),
            'capacity': 3,
            'occupiedCount': 0,
            'occupantStudentIds': <String>[],
            'hostelBlock': block,
          });
        }
      }
    }

    // ── STEP 5: Seed Notice ──────────────────────────────────────────────────
    final noticesCount = await _db.collection('notices').limit(1).get();
    if (noticesCount.docs.isEmpty) {
      await _db.collection('notices').add({
        'title': 'Welcome to IERT Hostel',
        'body':
            'This is the new hostel management system powered by Firebase. '
            'Please complete your registration and fee payments.',
        'postedBy': 'System Admin',
        'createdAt': Timestamp.now(),
      });
    }

    // ── STEP 6: Seed Students (Auth + Firestore) ─────────────────────────────
    final studentsData = [
      {
        'rollNo': 'STU001',
        'name': 'Rahul Sharma',
        'email': 'student1@hostel.com',
        'branch': 'Computer Science',
        'year': '1st Year',
        'phone': '+91 9999911111',
        'parentsContact': '+91 8888822222',
        'casteCategory': 'General',
        'feeStatus': 'Due',
      },
      {
        'rollNo': 'STU002',
        'name': 'Aditya Verma',
        'email': 'student2@hostel.com',
        'branch': 'Information Technology',
        'year': '2nd Year',
        'phone': '+91 9999933333',
        'parentsContact': '+91 8888844444',
        'casteCategory': 'OBC',
        'feeStatus': 'Paid',
      },
    ];

    for (final s in studentsData) {
      final roll = s['rollNo']!;

      // Create student Auth account (this signs the session over to the student)
      String stuUid;
      try {
        final cred = await auth.createUserWithEmailAndPassword(
          email: s['email']!,
          password: 'password123',
        );
        stuUid = cred.user!.uid;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Already created — sign in to grab UID, then re-sign in as admin
          final cred = await auth.signInWithEmailAndPassword(
            email: s['email']!,
            password: 'password123',
          );
          stuUid = cred.user!.uid;
        } else {
          rethrow;
        }
      }

      // Re-sign in as admin so security rules allow writing student docs
      await auth.signInWithEmailAndPassword(
        email: 'admin@hostel.com',
        password: 'password123',
      );

      // Write student Firestore document
      final existing = await _db
          .collection('students')
          .where('rollNo', isEqualTo: roll)
          .limit(1)
          .get();

      if (existing.docs.isEmpty) {
        await _db.collection('students').doc(roll).set({
          'rollNo': roll,
          'name': s['name'],
          'email': s['email'],
          'branch': s['branch'],
          'year': s['year'],
          'roomAllotted': '',
          'hostelBlock': '',
          'phone': s['phone'],
          'parentsContact': s['parentsContact'],
          'casteCategory': s['casteCategory'],
          'feeStatus': s['feeStatus'],
          'authUid': stuUid,
        });
      } else {
        await existing.docs.first.reference.update({'authUid': stuUid});
      }

      // Seed fee record if none exists
      final feeQuery = await _db
          .collection('fees')
          .where('studentId', isEqualTo: roll)
          .limit(1)
          .get();

      if (feeQuery.docs.isEmpty) {
        await _db.collection('fees').add({
          'studentId': roll,
          'amount': 50000.0,
          'dueDate': Timestamp.fromDate(DateTime(2025, 12, 15)),
          'status': s['feeStatus'],
          'paidOn': s['feeStatus'] == 'Paid'
              ? Timestamp.fromDate(DateTime.now())
              : null,
          'paymentMethod': s['feeStatus'] == 'Paid' ? 'Online' : 'Pending',
        });
      }
    }

    // ── STEP 7: Sign out after seeding — user returns to login screen ────────
    await auth.signOut();
  }
}

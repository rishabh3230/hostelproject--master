import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String
  id; // Document ID (could be rollNo or authUid, we will use document ID as rollNo/authUid)
  final String rollNo;
  final String name;
  final String email;
  final String branch;
  final String year; // e.g. '1st Year', '2nd Year', '3rd Year', '4th Year'
  final String roomAllotted; // e.g. '101'
  final String hostelBlock; // e.g. 'Block A'
  final String phone;
  final String parentsContact;
  final String casteCategory;
  final String feeStatus; // 'Paid', 'Due', 'Overdue'
  final String authUid;

  Student({
    required this.id,
    required this.rollNo,
    required this.name,
    required this.email,
    required this.branch,
    required this.year,
    required this.roomAllotted,
    required this.hostelBlock,
    required this.phone,
    required this.parentsContact,
    required this.casteCategory,
    required this.feeStatus,
    required this.authUid,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Student(
      id: doc.id,
      rollNo: data['rollNo'] ?? '',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      branch: data['branch'] ?? '',
      year: data['year'] ?? '',
      roomAllotted: data['roomAllotted'] ?? '',
      hostelBlock: data['hostelBlock'] ?? '',
      phone: data['phone'] ?? '',
      parentsContact: data['parentsContact'] ?? '',
      casteCategory: data['casteCategory'] ?? '',
      feeStatus: data['feeStatus'] ?? 'Due',
      authUid: data['authUid'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rollNo': rollNo,
      'name': name,
      'email': email,
      'branch': branch,
      'year': year,
      'roomAllotted': roomAllotted,
      'hostelBlock': hostelBlock,
      'phone': phone,
      'parentsContact': parentsContact,
      'casteCategory': casteCategory,
      'feeStatus': feeStatus,
      'authUid': authUid,
    };
  }

  // Helper logic to return values compatible with StudentProfileData if needed
  String get feeDetails => '$feeStatus (Due: Jan 2025)';
}

import 'package:cloud_firestore/cloud_firestore.dart';

class Complaint {
  final String id;
  final String studentId;
  final String studentName;
  final String title;
  final String category;
  final String description;
  final String status; // 'Pending', 'In Progress', 'Resolved'
  final DateTime createdAt;

  Complaint({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.title,
    required this.category,
    required this.description,
    required this.status,
    required this.createdAt,
  });

  factory Complaint.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    // Support Timestamp -> DateTime mapping
    DateTime parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate =
          DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return Complaint(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Student',
      title: data['title'] ?? '',
      category: data['category'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'Pending',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'title': title,
      'category': category,
      'description': description,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String id;
  final String studentId;
  final String studentName;
  final String roomNo;
  final String message;
  final double rating;
  final String category;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.roomNo,
    required this.message,
    required this.rating,
    required this.category,
    required this.createdAt,
  });

  factory FeedbackModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDate;
    if (data['createdAt'] is Timestamp) {
      parsedDate = (data['createdAt'] as Timestamp).toDate();
    } else if (data['createdAt'] is String) {
      parsedDate =
          DateTime.tryParse(data['createdAt'] as String) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    double parsedRating = 5.0;
    if (data['rating'] is num) {
      parsedRating = (data['rating'] as num).toDouble();
    }

    return FeedbackModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      studentName: data['studentName'] ?? 'Anonymous',
      roomNo: data['roomNo'] ?? '',
      message: data['message'] ?? '',
      rating: parsedRating,
      category: data['category'] ?? 'General',
      createdAt: parsedDate,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'roomNo': roomNo,
      'message': message,
      'rating': rating,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

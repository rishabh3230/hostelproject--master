import 'package:cloud_firestore/cloud_firestore.dart';

class Fee {
  final String id;
  final String studentId;
  final double amount;
  final DateTime dueDate;
  final String status; // 'Paid', 'Due', 'Overdue'
  final DateTime? paidOn;
  final String paymentMethod; // 'Online', 'Cash', 'Cheque', or 'Pending'

  Fee({
    required this.id,
    required this.studentId,
    required this.amount,
    required this.dueDate,
    required this.status,
    this.paidOn,
    required this.paymentMethod,
  });

  factory Fee.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    DateTime parsedDueDate;
    if (data['dueDate'] is Timestamp) {
      parsedDueDate = (data['dueDate'] as Timestamp).toDate();
    } else if (data['dueDate'] is String) {
      parsedDueDate =
          DateTime.tryParse(data['dueDate'] as String) ?? DateTime.now();
    } else {
      parsedDueDate = DateTime.now();
    }

    DateTime? parsedPaidOn;
    if (data['paidOn'] is Timestamp) {
      parsedPaidOn = (data['paidOn'] as Timestamp).toDate();
    } else if (data['paidOn'] is String) {
      parsedPaidOn = DateTime.tryParse(data['paidOn'] as String);
    }

    double parsedAmount = 0.0;
    if (data['amount'] is num) {
      parsedAmount = (data['amount'] as num).toDouble();
    }

    return Fee(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      amount: parsedAmount,
      dueDate: parsedDueDate,
      status: data['status'] ?? 'Due',
      paidOn: parsedPaidOn,
      paymentMethod: data['paymentMethod'] ?? 'Online',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentId': studentId,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'status': status,
      'paidOn': paidOn != null ? Timestamp.fromDate(paidOn!) : null,
      'paymentMethod': paymentMethod,
    };
  }
}

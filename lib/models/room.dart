import 'package:cloud_firestore/cloud_firestore.dart';

class Room {
  final String id;
  final String roomNumber;
  final int capacity;
  final int occupiedCount;
  final List<String> occupantStudentIds;
  final String hostelBlock; // e.g. '1st Year', '2nd Year', or 'Block A'

  Room({
    required this.id,
    required this.roomNumber,
    required this.capacity,
    required this.occupiedCount,
    required this.occupantStudentIds,
    required this.hostelBlock,
  });

  factory Room.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};

    List<String> parsedOccupants = [];
    if (data['occupantStudentIds'] is List) {
      parsedOccupants = List<String>.from(data['occupantStudentIds'] as List);
    }

    return Room(
      id: doc.id,
      roomNumber: data['roomNumber'] ?? '',
      capacity: data['capacity'] ?? 3,
      occupiedCount: data['occupiedCount'] ?? 0,
      occupantStudentIds: parsedOccupants,
      hostelBlock: data['hostelBlock'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'roomNumber': roomNumber,
      'capacity': capacity,
      'occupiedCount': occupiedCount,
      'occupantStudentIds': occupantStudentIds,
      'hostelBlock': hostelBlock,
    };
  }

  int get vacantCount => capacity - occupiedCount;
  bool get isFull => occupiedCount >= capacity;
}

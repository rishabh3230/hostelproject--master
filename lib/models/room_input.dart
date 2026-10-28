import 'dart:convert';
import 'package:crypto/crypto.dart';

class RoomInput {
  final String block, number;
  final int capacity;
  RoomInput(String block, String number, String capacity)
    : block = block.trim(),
      number = number.trim(),
      capacity = int.tryParse(capacity.trim()) ?? 0;
  String? get error {
    if (block.isEmpty || block.length > 60) {
      return 'Enter a block name (up to 60 characters).';
    }
    if (number.isEmpty || number.length > 20) {
      return 'Enter a room number (up to 20 characters).';
    }
    if (capacity < 1 || capacity > 20) {
      return 'Capacity must be a whole number from 1 to 20.';
    }
    return null;
  }

  String get id => sha256
      .convert(utf8.encode('${block.toLowerCase()}|${number.toLowerCase()}'))
      .toString()
      .substring(0, 32);
}

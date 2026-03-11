import 'package:cloud_firestore/cloud_firestore.dart';
import 'restroom_model.dart';

enum Status { pending, approved, rejected }

class RequestModel {
  final String requestId;
  final RestroomModel restroom;
  final String userId;
  final String? adminId;
  final Status status;
  // ✅ FIX #2: Use DateTime consistently (was Timestamp, inconsistent with all other models)
  final DateTime createdAt;

  RequestModel({
    required this.requestId,
    required this.restroom,
    required this.userId,
    this.adminId,
    this.status = Status.pending,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // 1. Convert Firestore → RequestModel
  factory RequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    final restroomMap = map['restroom'] as Map<String, dynamic>;

    return RequestModel(
      requestId: documentId,
      restroom: RestroomModel.fromMap(restroomMap, restroomMap['restroomId'] ?? ''),
      userId: map['userId'] ?? '',
      adminId: map['adminId'],
      status: Status.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => Status.pending,
      ),
      // ✅ Convert Timestamp → DateTime on read
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // 2. Convert RequestModel → Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'restroom': restroom.toMap(),
      'userId': userId,
      'adminId': adminId,
      'status': status.name,
      // ✅ Convert DateTime → Timestamp on write
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

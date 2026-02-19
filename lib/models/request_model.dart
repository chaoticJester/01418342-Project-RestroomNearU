import 'package:cloud_firestore/cloud_firestore.dart';
import 'restroom_model.dart';

enum Status { pending, approved, rejected }

class RequestModel {
  final String requestId;
  final RestroomModel restroom;
  final String userId;
  final String? adminId;
  final Status status;
  final Timestamp createdAt; 

  RequestModel({
    required this.requestId,
    required this.restroom,
    required this.userId,
    this.adminId,
    this.status = Status.pending, 
    required this.createdAt,
  });

  // 1. เมธอดสำหรับดึงข้อมูลจาก Firestore มาแปลงเป็น RequestModel
  factory RequestModel.fromMap(Map<String, dynamic> map, String documentId) {
    // ดึง Map ของ restroom ออกมาก่อนเพื่อความสะอาดของโค้ด
    final restroomMap = map['restroom'] as Map<String, dynamic>;

    return RequestModel(
      requestId: documentId, 
      // ดึง ID ออกมาจาก restroomMap โดยตรง 
      restroom: RestroomModel.fromMap(restroomMap, restroomMap['restroomId'] ?? ''),
      userId: map['userId'] ?? '',
      adminId: map['adminId'],
      status: Status.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => Status.pending, 
      ),
      createdAt: map['createdAt'] as Timestamp? ?? Timestamp.now(),
    );
  }

  // 2. เมธอดสำหรับแปลง RequestModel เป็น Map เพื่อนำไปบันทึกลง Firestore
  Map<String, dynamic> toMap() {
    return {
      'restroom': restroom.toMap(), 
      'userId': userId,
      'adminId': adminId,
      // แปลง enum Status กลับไปเป็น String ก่อนบันทึกเข้า Firestore
      'status': status.name, 
      'createdAt': createdAt,
    };
  }
}
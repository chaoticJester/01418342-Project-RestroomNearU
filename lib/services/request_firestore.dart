import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/request_model.dart';

class RequestService {
  final CollectionReference _requestCollection = FirebaseFirestore.instance.collection('requests');

  // CREATE
  Future<void> createRequest(RequestModel request) async {
    try {
      // วิธีที่ 1: ถ้า Model มี ID มาแล้ว (กำหนดเอง)
      if (request.requestId.isNotEmpty) {
        await _requestCollection.doc(request.requestId).set(request.toMap());
      } 
      // วิธีที่ 2: ถ้ายังไม่มี ID (ให้ Firestore Gen ให้)
      else {
        DocumentReference docRef = _requestCollection.doc(); // สร้าง ID อัตโนมัติ
        // บันทึกโดยแนบ ID ที่ Gen ได้เข้าไปในข้อมูลด้วย เพื่อให้ตรงกัน
        Map<String, dynamic> data = request.toMap();
        data['requestId'] = docRef.id; 
        await docRef.set(data);
      }
    } catch (e) {
      print("Error creating request: $e");
      rethrow;
    }
  }

  // READ
  Stream<List<RequestModel>> getRequestsStream() {
    return _requestCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RequestModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  Future<RequestModel?> getRequestById(String requestId) async {
    try {
      DocumentSnapshot doc = await _requestCollection.doc(requestId).get();
      if (doc.exists) {
        return RequestModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print("Error getting request: $e");
      return null;
    }
  }

  // UPDATE
  Future<void> updateRequest(RequestModel request) async {
    try {
      await _requestCollection.doc(request.requestId).update(request.toMap());
    } catch (e) {
      print("Error updating request: $e");
      rethrow;
    }
  }

  Future<void> updateSpecificField(String docId, Map<String, dynamic> data) async {
    try {
      await _requestCollection.doc(docId).update(data);
    } catch (e) {
      print("Error updating field: $e");
      rethrow;
    }
  }

  // DELETE
  Future<void> deleteRequest(String requestId) async {
    try {
      await _requestCollection.doc(requestId).delete();
    } catch (e) {
      print("Error deleting restroom: $e");
      rethrow;
    }
  }
}
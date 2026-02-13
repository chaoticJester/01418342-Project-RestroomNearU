import 'package:cloud_firestore/cloud_firestore.dart';
import '/models/restroom_model.dart';

class RestroomService {
  final CollectionReference _restroomCollection =
      FirebaseFirestore.instance.collection('restrooms');

  // CREATE: สร้างข้อมูลห้องน้ำใหม่
  Future<void> createRestroom(RestroomModel restroom) async {
    try {
      // วิธีที่ 1: ถ้า Model มี ID มาแล้ว (กำหนดเอง)
      if (restroom.restroomId.isNotEmpty) {
        await _restroomCollection.doc(restroom.restroomId).set(restroom.toMap());
      } 
      // วิธีที่ 2: ถ้ายังไม่มี ID (ให้ Firestore Gen ให้)
      else {
        DocumentReference docRef = _restroomCollection.doc(); // สร้าง ID อัตโนมัติ
        // บันทึกโดยแนบ ID ที่ Gen ได้เข้าไปในข้อมูลด้วย เพื่อให้ตรงกัน
        Map<String, dynamic> data = restroom.toMap();
        data['restroomId'] = docRef.id; 
        await docRef.set(data);
      }
    } catch (e) {
      print("Error creating restroom: $e");
      rethrow;
    }
  }

  // READ: อ่านข้อมูล 
  // 1. ดึงข้อมูลทั้งหมดแบบ Realtime (ใช้กับ StreamBuilder ในหน้า List)
  Stream<List<RestroomModel>> getRestroomsStream() {
    return _restroomCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RestroomModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();
    });
  }

  // 2. ดึงข้อมูลห้องเดียว (เช่น หน้า Detail)
  Future<RestroomModel?> getRestroomById(String restroomId) async {
    try {
      DocumentSnapshot doc = await _restroomCollection.doc(restroomId).get();
      if (doc.exists) {
        return RestroomModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print("Error getting restroom: $e");
      return null;
    }
  }

  // UPDATE: แก้ไขข้อมูล
  // 1. แก้ไขข้อมูลทั้งก้อน (Replace/Merge)
  Future<void> updateRestroom(RestroomModel restroom) async {
    try {
      await _restroomCollection.doc(restroom.restroomId).update(restroom.toMap());
    } catch (e) {
      print("Error updating restroom: $e");
      rethrow;
    }
  }

  // 2. แก้ไขเฉพาะบาง Field (เช่น อัปเดตแค่ราคา หรือ คะแนนรีวิว)
  // วิธีใช้: service.updateSpecificField('id_123', {'price': 10.0, 'isFree': false});
  Future<void> updateSpecificField(String docId, Map<String, dynamic> data) async {
    try {
      await _restroomCollection.doc(docId).update(data);
    } catch (e) {
      print("Error updating field: $e");
      rethrow;
    }
  }

  // DELETE: ลบข้อมูล
  Future<void> deleteRestroom(String restroomId) async {
    try {
      await _restroomCollection.doc(restroomId).delete();
    } catch (e) {
      print("Error deleting restroom: $e");
      rethrow;
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '/models/restroom_model.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class RestroomService {
  final CollectionReference _restroomCollection =
      FirebaseFirestore.instance.collection('restrooms');

  // CREATE: สร้างข้อมูลห้องน้ำใหม่
  Future<void> createRestroom(RestroomModel restroom) async {
    try {
      if (restroom.restroomId.isEmpty) {
        throw Exception("Restroom ID cannot be empty. Please pre-generate the ID.");
      }
      await _restroomCollection.doc(restroom.restroomId).set(restroom.toMap());
    } catch (e) {
      debugPrint("Error creating restroom: $e"); // ✅ FIX #12: was print()
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
      debugPrint("Error getting restroom: $e"); // ✅ FIX #12: was print()
      return null;
    }
  }

  // UPDATE: แก้ไขข้อมูล
  // 1. แก้ไขข้อมูลทั้งก้อน (Replace/Merge)
  Future<void> updateRestroom(RestroomModel restroom) async {
    try {
      await _restroomCollection.doc(restroom.restroomId).update(restroom.toMap());
    } catch (e) {
      debugPrint("Error updating restroom: $e"); // ✅ FIX #12: was print()
      rethrow;
    }
  }

  // 2. แก้ไขเฉพาะบาง Field
  Future<void> updateSpecificField(String docId, Map<String, dynamic> data) async {
    try {
      await _restroomCollection.doc(docId).update(data);
    } catch (e) {
      debugPrint("Error updating field: $e"); // ✅ FIX #12: was print()
      rethrow;
    }
  }

  // DELETE: ลบข้อมูล
  Future<void> deleteRestroom(String restroomId) async {
    try {
      await _restroomCollection.doc(restroomId).delete();
    } catch (e) {
      debugPrint("Error deleting restroom: $e"); // ✅ FIX #12: was print()
      rethrow;
    }
  }

  bool checkIfOpen(RestroomModel r) {
    if (r.is24hrs) return true;
    if (r.openTime == null || r.closeTime == null) return false;

    try {
      final format = DateFormat.Hm();

      final DateTime parsedOpen  = format.parse(r.openTime!);
      final DateTime parsedClose = format.parse(r.closeTime!);
      final DateTime now         = DateTime.now();

      final int openMinutes  = parsedOpen.hour  * 60 + parsedOpen.minute;
      final int closeMinutes = parsedClose.hour * 60 + parsedClose.minute;
      final int nowMinutes   = now.hour          * 60 + now.minute;

      if (closeMinutes < openMinutes) {
        return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
      }

      return nowMinutes >= openMinutes && nowMinutes < closeMinutes;

    } catch (e) {
      debugPrint("checkIfOpen parse error: $e"); // ✅ FIX #12: was print()
      return false;
    }
  }

  String getDistance(double startLat, double startLng, double endLat, double endLng) {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat, startLng,
      endLat, endLng,
    );
    
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }
}

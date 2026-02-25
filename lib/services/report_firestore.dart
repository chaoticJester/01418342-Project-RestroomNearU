import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/report_model.dart';

class ReportService {
  // Exposed so pages can pre-generate a doc ID before uploading photos etc.
  final CollectionReference reportsCollection =
      FirebaseFirestore.instance.collection('reports');

  CollectionReference get _reportCollection => reportsCollection;

  // ── CREATE ───────────────────────────────────────────────────────────

  Future<void> createReport(ReportModel report) async {
    try {
      if (report.reportId.isNotEmpty) {
        await _reportCollection.doc(report.reportId).set(report.toMap());
      } else {
        final docRef = _reportCollection.doc();
        final data = report.toMap();
        data['reportId'] = docRef.id;
        await docRef.set(data);
      }
    } catch (e) {
      print('Error creating report: $e');
      rethrow;
    }
  }

  // ── READ ─────────────────────────────────────────────────────────────

  // All reports — real-time stream (used by admin page)
  Stream<List<ReportModel>> getReportsStream() {
    return _reportCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // Only pending (not yet reviewed) reports
  Stream<List<ReportModel>> getPendingReportsStream() {
    return _reportCollection
        .where('reviewed', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReportModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  // Single report by ID
  Future<ReportModel?> getReportById(String reportId) async {
    try {
      final doc = await _reportCollection.doc(reportId).get();
      if (doc.exists) {
        return ReportModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error getting report: $e');
      return null;
    }
  }

  // ── UPDATE ───────────────────────────────────────────────────────────

  // Mark a report as reviewed by admin
  Future<void> markAsReviewed(String reportId) async {
    try {
      await _reportCollection.doc(reportId).update({'reviewed': true});
    } catch (e) {
      print('Error marking report as reviewed: $e');
      rethrow;
    }
  }

  // Generic partial update
  Future<void> updateField(String reportId, Map<String, dynamic> data) async {
    try {
      await _reportCollection.doc(reportId).update(data);
    } catch (e) {
      print('Error updating report field: $e');
      rethrow;
    }
  }

  // ── DELETE ───────────────────────────────────────────────────────────

  Future<void> deleteReport(String reportId) async {
    try {
      await _reportCollection.doc(reportId).delete();
    } catch (e) {
      print('Error deleting report: $e');
      rethrow;
    }
  }
}
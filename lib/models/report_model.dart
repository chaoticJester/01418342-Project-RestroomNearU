import 'package:cloud_firestore/cloud_firestore.dart';

/// Severity levels for a report
enum ReportSeverity { low, medium, high }

class ReportModel {
  final String reportId;
  final String restroomId;
  final String restroomName;

  // Issue info
  final String issueType;   // e.g. 'location', 'closed', 'price', 'hours', 'amenities', 'duplicate', 'other'
  final String title;       // Human-readable label derived from issueType
  final String description;
  final ReportSeverity severity;

  // Reporter info
  final String reportedById;    // UID of the reporter (empty if anonymous)
  final String reportedByName;  // Display name (empty if anonymous)
  final String reportedByEmail; // Contact email (optional)
  final bool isAnonymous;

  // Photos attached to the report
  final List<String> photos;

  // If this report is about a specific review (issueType == 'review')
  final String reviewId;

  // Admin workflow
  final bool reviewed;

  // Timestamps
  final DateTime createdAt;

  ReportModel({
    required this.reportId,
    required this.restroomId,
    required this.restroomName,
    required this.issueType,
    required this.title,
    required this.description,
    this.severity = ReportSeverity.low,
    this.reportedById = '',
    this.reportedByName = '',
    this.reportedByEmail = '',
    this.isAnonymous = false,
    this.photos = const [],
    this.reviewId = '',
    this.reviewed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // ── Firestore → Object ───────────────────────────────────────────────
  factory ReportModel.fromMap(Map<String, dynamic> map, String id) {
    return ReportModel(
      reportId:        id,
      restroomId:      map['restroomId']      ?? '',
      restroomName:    map['restroomName']     ?? '',
      issueType:       map['issueType']        ?? 'other',
      title:           map['title']            ?? 'Untitled Report',
      description:     map['description']      ?? '',
      severity: ReportSeverity.values.firstWhere(
        (e) => e.name == (map['severity'] ?? 'low'),
        orElse: () => ReportSeverity.low,
      ),
      reportedById:    map['reportedById']     ?? '',
      reportedByName:  map['reportedByName']   ?? '',
      reportedByEmail: map['reportedByEmail']  ?? '',
      isAnonymous:     map['isAnonymous']      ?? false,
      photos:          List<String>.from(map['photos'] ?? []),
      reviewId:        map['reviewId']         ?? '',
      reviewed:        map['reviewed']         ?? false,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // ── Object → Firestore ───────────────────────────────────────────────
  Map<String, dynamic> toMap() {
    return {
      'restroomId':      restroomId,
      'restroomName':    restroomName,
      'issueType':       issueType,
      'title':           title,
      'description':     description,
      'severity':        severity.name,           // 'low' | 'medium' | 'high'
      'reportedById':    reportedById,
      'reportedByName':  reportedByName,
      'reportedByEmail': reportedByEmail,
      'isAnonymous':     isAnonymous,
      'photos':          photos,
      'reviewId':        reviewId,
      'reviewed':        reviewed,
      'createdAt':       Timestamp.fromDate(createdAt),
    };
  }

  // ── Helper: derive severity from issueType ───────────────────────────
  /// Call this when creating a report so severity is set automatically.
  static ReportSeverity severityFromIssueType(String issueType) {
    switch (issueType) {
      case 'closed':
      case 'duplicate':
        return ReportSeverity.high;
      case 'location':
      case 'price':
      case 'hours':
      case 'review':
        return ReportSeverity.medium;
      default:
        return ReportSeverity.low;
    }
  }

  // ── Helper: derive human-readable title from issueType ───────────────
  static String titleFromIssueType(String issueType) {
    const map = {
      'location':  'Incorrect Location',
      'closed':    'Permanently Closed',
      'price':     'Incorrect Price',
      'hours':     'Incorrect Opening Hours',
      'amenities': 'Incorrect Amenities Info',
      'duplicate': 'Duplicate Entry',
      'review':    'Inappropriate Review',
      'other':     'Other Issue',
    };
    return map[issueType] ?? 'Other Issue';
  }
}
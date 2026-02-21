import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage> {
  String _selectedFilter = 'All';

  Stream<List<Map<String, dynamic>>> _getReportsStream() {
    Query query = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true);

    if (_selectedFilter == 'Reviewed') {
      query = query.where('reviewed', isEqualTo: true);
    } else if (_selectedFilter == 'Pending') {
      query = query.where('reviewed', isEqualTo: false);
    }

    return query.snapshots().map((snap) => snap.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 12),
            Expanded(child: _buildReportList()),
          ],
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Report Management',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black),
                ),
                Text(
                  '6 reports to review',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ),
          _buildFilterTabs(),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final filters = ['All', 'Pending', 'Reviewed'];
    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = f),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.black.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              f == 'All' ? 'All' : f,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── Report List ──────────────────────────────────────────────────────────
  Widget _buildReportList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getReportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data ?? [];

        if (reports.isEmpty) {
          return const Center(
            child: Text('No reports found.',
                style: TextStyle(color: Colors.black54)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _buildReportCard(context, reports[index]),
        );
      },
    );
  }

  // ─── Report Card ──────────────────────────────────────────────────────────
  Widget _buildReportCard(
      BuildContext context, Map<String, dynamic> report) {
    final reportId = report['id'] ?? '';
    final title = report['title'] ?? 'Fake Restroom Location';
    final reportedByName = report['reportedByName'] ?? 'Unknown';
    final description = report['description'] ?? '';
    final severity = report['severity'] ?? 'low'; // low / medium / high
    final reviewed = report['reviewed'] ?? false;
    final photoCount = (report['photos'] as List?)?.length ?? 0;
    final createdAt = report['createdAt'];
    final restroomName = report['restroomName'] ?? '';

    String formattedDate = '';
    if (createdAt != null && createdAt is Timestamp) {
      final dt = createdAt.toDate();
      formattedDate =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
          '${dt.hour.toString().padLeft(2, '0')}.${dt.minute.toString().padLeft(2, '0')}';
    }

    return GestureDetector(
      onTap: () => _showReportDetail(context, report),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9EA),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Flag icon + Report ID + severity badge + attachment
            Row(
              children: [
                Icon(
                  Icons.flag,
                  size: 15,
                  color: _severityIconColor(severity),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Report ID : $reportId',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                ),
                _buildSeverityBadge(severity),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.attach_file,
                        size: 12, color: Colors.black45),
                    const SizedBox(width: 2),
                    Text(
                      '$photoCount',
                      style: const TextStyle(
                          fontSize: 9, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Restroom / Location
            if (restroomName.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 10, color: Colors.black54),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      restroomName,
                      style: const TextStyle(
                          fontSize: 9, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
            ],

            // Title / issue
            Row(
              children: [
                const Icon(Icons.flag_outlined,
                    size: 10, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style:
                        const TextStyle(fontSize: 9, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Reported by
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 10, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  'Reported By $reportedByName',
                  style:
                      const TextStyle(fontSize: 9, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 3),

            // Timestamp
            Text(
              formattedDate,
              style:
                  const TextStyle(fontSize: 7, color: Colors.black38),
            ),

            // Description
            if (description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                description,
                style:
                    const TextStyle(fontSize: 8, color: Colors.black87),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Reviewed badge
            if (reviewed) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFF10B981).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Reviewed',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF10B981)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── Severity Badge ───────────────────────────────────────────────────────
  Widget _buildSeverityBadge(String severity) {
    Color bg;
    Color border;
    Color text;
    String label;

    switch (severity.toLowerCase()) {
      case 'medium':
        bg = const Color(0xFFFFDE00).withOpacity(0.4);
        border = const Color(0xFFFFDE00);
        text = const Color(0xFFBDA713);
        label = 'Medium';
        break;
      case 'high':
        bg = const Color(0xFFE8753D).withOpacity(0.3);
        border = const Color(0xFFE8753D);
        text = const Color(0xFFE8753D);
        label = 'High';
        break;
      case 'low':
      default:
        bg = Colors.white;
        border = Colors.black.withOpacity(0.4);
        text = Colors.black;
        label = 'Low';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 8, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }

  Color _severityIconColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return const Color(0xFFE8753D);
      case 'medium':
        return const Color(0xFFBDA713);
      case 'low':
      default:
        return Colors.black45;
    }
  }

  // ─── Report Detail Bottom Sheet ───────────────────────────────────────────
  void _showReportDetail(
      BuildContext context, Map<String, dynamic> report) {
    final reportId = report['id'] ?? '';
    final title = report['title'] ?? 'Fake Restroom Location';
    final reportedByName = report['reportedByName'] ?? 'Unknown';
    final reportedByEmail = report['reportedByEmail'] ?? '';
    final description = report['description'] ?? '';
    final severity = report['severity'] ?? 'low';
    final restroomName = report['restroomName'] ?? '';
    final createdAt = report['createdAt'];

    String formattedDate = '';
    if (createdAt != null && createdAt is Timestamp) {
      final dt = createdAt.toDate();
      formattedDate =
          '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        builder: (ctx, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCF9EA),
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Report ID : $reportId',
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: Colors.black45),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSeverityBadge(severity),
                        ],
                      ),
                      const SizedBox(height: 16),

                      if (restroomName.isNotEmpty) ...[
                        _detailRow(
                            Icons.location_on_outlined, restroomName),
                        const SizedBox(height: 8),
                      ],

                      // Description
                      if (description.isNotEmpty) ...[
                        const Text('Description',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            description,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Reporter info
                      const Text('Reported By',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.black)),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(reportedByName,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                                if (reportedByEmail.isNotEmpty)
                                  Text(reportedByEmail,
                                      style: const TextStyle(
                                          fontSize: 8,
                                          color: Colors.black45)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                const Text('Submitted',
                                    style: TextStyle(
                                        fontSize: 8,
                                        color: Colors.black45)),
                                Text(formattedDate,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _markReviewed(context, reportId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                              child: const Text('Mark as Reviewed',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () =>
                                  _dismissReport(context, reportId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                        BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12),
                              ),
                              child: const Text('Dismiss',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style:
                  const TextStyle(fontSize: 11, color: Colors.black87)),
        ),
      ],
    );
  }

  Future<void> _markReviewed(
      BuildContext context, String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .update({'reviewed': true});

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report marked as reviewed.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _dismissReport(
      BuildContext context, String reportId) async {
    try {
      await FirebaseFirestore.instance
          .collection('reports')
          .doc(reportId)
          .delete();

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report dismissed.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }
}

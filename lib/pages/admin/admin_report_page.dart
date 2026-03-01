import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/utils/helpers.dart';
import 'package:restroom_near_u/services/report_firestore.dart';
import 'package:restroom_near_u/models/report_model.dart';

// ─────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFFCF9EA);
  static const card      = Color(0xFFF7F4E6);
  static const teal      = Color(0xFFBADFDB);
  static const tealDark  = Color(0xFF7BBFBA);
  static const orange    = Color(0xFFE8753D);
  static const green     = Color(0xFF34A853);
  static const red       = Color(0xFFB3261E);
  static const redLight  = Color(0xFFEF4444);
  static const yellow    = Color(0xFFF0A500);
  static const textDark  = Color(0xFF1C1B1F);
  static const textMid   = Color(0xFF6B6874);
  static const textLight = Color(0xFFAEABB8);
  static const divider   = Color(0xFFECE9DA);
  static const fieldFill = Color(0xFFEEEBDA);
}

class AdminReportPage extends StatefulWidget {
  const AdminReportPage({super.key});

  @override
  State<AdminReportPage> createState() => _AdminReportPageState();
}

class _AdminReportPageState extends State<AdminReportPage>
    with SingleTickerProviderStateMixin {
  final ReportService _reportService = ReportService();
  String _selectedFilter = 'All';

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Stream<List<ReportModel>> _getReportsStream() {
    return _reportService.getReportsStream().map((list) {
      if (_selectedFilter == 'Reviewed') {
        return list.where((r) => r.reviewed).toList();
      } else if (_selectedFilter == 'Pending') {
        return list.where((r) => !r.reviewed).toList();
      }
      return list;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 12),
                Expanded(child: _buildReportList()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BackButton(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Report Management',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark),
                    ),
                    Text(
                      'Review and manage user reports',
                      style:
                          TextStyle(fontSize: 12, color: _C.textMid),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
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
        Color chipColor;
        if (f == 'Reviewed') chipColor = _C.green;
        else if (f == 'Pending') chipColor = _C.orange;
        else chipColor = _C.tealDark;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFilter = f);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? chipColor : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: isSelected ? chipColor : _C.divider, width: 1),
              boxShadow: [
                BoxShadow(
                    color: isSelected
                        ? chipColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              f,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : _C.textMid,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Report List ───────────────────────────────────────────────────────
  Widget _buildReportList() {
    return StreamBuilder<List<ReportModel>>(
      stream: _getReportsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _C.tealDark));
        }

        final reports = snapshot.data ?? [];
        if (reports.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          itemCount: reports.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _ReportCard(
                report: reports[index],
                onTap: () =>
                    _showReportDetail(context, reports[index]),
              ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flag_outlined,
                size: 36, color: _C.tealDark),
          ),
          const SizedBox(height: 14),
          const Text('No reports found',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark)),
          const SizedBox(height: 4),
          const Text('All clear!',
              style: TextStyle(fontSize: 12, color: _C.textMid)),
        ],
      ),
    );
  }

  // ── Report Detail Bottom Sheet ────────────────────────────────────────
  void _showReportDetail(
      BuildContext context, ReportModel report) {
    final reportId      = report.reportId;
    final title         = report.title;
    final reportedBy    = report.reportedByName;
    final reportedEmail = report.reportedByEmail;
    final description   = report.description;
    final severity      = report.severity;
    final restroomName  = report.restroomName;
    final createdAt     = report.createdAt;

    String formattedDate = AppHelpers.formatDateOnly(createdAt);

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
            color: _C.bg,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                      color: _C.divider,
                      borderRadius: BorderRadius.circular(99)),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + severity
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: _C.textDark)),
                                const SizedBox(height: 2),
                                Text('ID: $reportId',
                                    style: const TextStyle(
                                        fontSize: 10,
                                        color: _C.textLight)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _SeverityBadge(severity: severity),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Location
                      if (restroomName.isNotEmpty) ...[
                        _detailRow(Icons.location_on_rounded,
                            restroomName),
                        const SizedBox(height: 12),
                      ],

                      // Description
                      if (description.isNotEmpty) ...[
                        _sectionLabel('Description',
                            Icons.description_rounded),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _C.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: _C.divider, width: 1),
                          ),
                          child: Text(description,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: _C.textMid,
                                  height: 1.5)),
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Reporter
                      _sectionLabel(
                          'Reported By', Icons.person_rounded),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _C.card,
                          borderRadius: BorderRadius.circular(14),
                          border:
                              Border.all(color: _C.divider, width: 1),
                        ),
                        child: Row(
                          mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(reportedBy,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: _C.textDark)),
                                if (reportedEmail.isNotEmpty)
                                  Text(reportedEmail,
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: _C.textLight)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.end,
                              children: [
                                const Text('Submitted',
                                    style: TextStyle(
                                        fontSize: 9,
                                        color: _C.textLight)),
                                Text(formattedDate,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: _C.textDark)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Mark as Reviewed',
                              color: _C.green,
                              onTap: () =>
                                  _markReviewed(context, reportId),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Dismiss',
                              color: _C.redLight,
                              onTap: () =>
                                  _dismissReport(context, reportId),
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

  Widget _sectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: _C.teal.withOpacity(0.25),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 13, color: _C.tealDark),
        ),
        const SizedBox(width: 7),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _C.textDark)),
      ],
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _C.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: _C.textMid)),
        ),
      ],
    );
  }

  Future<void> _markReviewed(
      BuildContext context, String reportId) async {
    try {
      await _reportService.markAsReviewed(reportId);
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'Report marked as reviewed.', _C.green);
      }
    } catch (e) {
      if (context.mounted) {
        _snack(context, 'Error: $e', _C.redLight);
      }
    }
  }

  Future<void> _dismissReport(
      BuildContext context, String reportId) async {
    try {
      await _reportService.deleteReport(reportId);
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'Report dismissed.', _C.redLight);
      }
    } catch (e) {
      if (context.mounted) {
        _snack(context, 'Error: $e', _C.redLight);
      }
    }
  }

  void _snack(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }
}

// ─────────────────────────────────────────────
// Report Card
// ─────────────────────────────────────────────
class _ReportCard extends StatefulWidget {
  final ReportModel report;
  final VoidCallback onTap;
  const _ReportCard({required this.report, required this.onTap});

  @override
  State<_ReportCard> createState() => _ReportCardState();
}

class _ReportCardState extends State<_ReportCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color _severityColor(ReportSeverity severity) {
    switch (severity) {
      case ReportSeverity.high:
        return _C.redLight;
      case ReportSeverity.medium:
        return _C.yellow;
      default:
        return _C.textLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final r            = widget.report;
    final title        = r.title;
    final reportedBy   = r.reportedByName;
    final description  = r.description;
    final severity     = r.severity;
    final reviewed     = r.reviewed;
    final restroomName = r.restroomName;
    final photoCount   = r.photos.length;
    final createdAt    = r.createdAt;
    final severityColor = _severityColor(severity);

    String formattedDate = AppHelpers.formatDateTime(createdAt);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider, width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: severityColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.flag_rounded,
                              size: 18, color: severityColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textDark),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(formattedDate,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      color: _C.textLight)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _SeverityBadge(severity: severity),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: _C.divider, height: 1, thickness: 1),
                    const SizedBox(height: 10),

                    // Location
                    if (restroomName.isNotEmpty) ...[
                      _infoRow(
                          Icons.location_on_rounded, restroomName),
                      const SizedBox(height: 5),
                    ],
                    _infoRow(Icons.person_rounded, reportedBy),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      _infoRow(Icons.notes_rounded, description,
                          maxLines: 2),
                    ],
                    if (photoCount > 0) ...[
                      const SizedBox(height: 8),
                      Row(children: [
                        Icon(Icons.photo_library_rounded,
                            size: 12, color: _C.textLight),
                        const SizedBox(width: 4),
                        Text('$photoCount photos',
                            style: const TextStyle(
                                fontSize: 10, color: _C.textLight)),
                      ]),
                    ],
                  ],
                ),
              ),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: reviewed
                      ? _C.green.withOpacity(0.1)
                      : _C.orange.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(16)),
                ),
                child: Center(
                  child: Text(
                    reviewed ? '✓  Reviewed' : 'Tap to review →',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: reviewed ? _C.green : _C.orange,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {int maxLines = 1}) {
    return Row(
      crossAxisAlignment: maxLines > 1
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 12, color: _C.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: _C.textMid),
            maxLines: maxLines,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Severity Badge
// ─────────────────────────────────────────────
class _SeverityBadge extends StatelessWidget {
  final ReportSeverity severity;
  const _SeverityBadge({required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (severity) {
      case ReportSeverity.high:
        color = _C.redLight;
        label = 'High';
        break;
      case ReportSeverity.medium:
        color = _C.yellow;
        label = 'Medium';
        break;
      default:
        color = _C.textLight;
        label = 'Low';
    }
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action button
// ─────────────────────────────────────────────
class _ActionButton extends StatefulWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionButton(
      {required this.label, required this.color, required this.onTap});

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.95)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.mediumImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [widget.color, widget.color.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                  color: widget.color.withOpacity(0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 5)),
            ],
          ),
          child: Center(
            child: Text(
              widget.label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Circle back button
// ─────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: _C.textDark),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/request_model.dart';
import 'package:restroom_near_u/services/request_firestore.dart';
import 'package:restroom_near_u/services/restroom_firestore.dart';

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
  static const textDark  = Color(0xFF1C1B1F);
  static const textMid   = Color(0xFF6B6874);
  static const textLight = Color(0xFFAEABB8);
  static const divider   = Color(0xFFECE9DA);
  static const fieldFill = Color(0xFFEEEBDA);
}

class AdminRequestPage extends StatefulWidget {
  const AdminRequestPage({super.key});

  @override
  State<AdminRequestPage> createState() => _AdminRequestPageState();
}

class _AdminRequestPageState extends State<AdminRequestPage>
    with SingleTickerProviderStateMixin {
  final RequestService _requestService = RequestService();
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

  Stream<List<RequestModel>> _getRequestsStream() {
    return _requestService.getRequestsStream().map((list) {
      if (_selectedFilter == 'Approved') {
        return list.where((r) => r.status == Status.approved).toList();
      } else if (_selectedFilter == 'Rejected') {
        return list.where((r) => r.status == Status.rejected).toList();
      }
      return list;
    });
  }

  int _pendingCount(List<RequestModel> all) =>
      all.where((r) => r.status == Status.pending).length;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: StreamBuilder<List<RequestModel>>(
              stream: _requestService.getRequestsStream(),
              builder: (context, allSnap) {
                final allRequests = allSnap.data ?? [];
                final pendingCount = _pendingCount(allRequests);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, pendingCount),
                    const SizedBox(height: 12),
                    Expanded(child: _buildRequestList()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _BackButton(onTap: () => Navigator.pop(context)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Toilet Requests',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark),
                    ),
                    Text(
                      '$pendingCount pending',
                      style: const TextStyle(
                          fontSize: 12, color: _C.textMid),
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
    final filters = ['All', 'Approved', 'Rejected'];
    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f;
        Color chipColor;
        if (f == 'Approved') chipColor = _C.green;
        else if (f == 'Rejected') chipColor = _C.redLight;
        else chipColor = _C.tealDark;

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _selectedFilter = f);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? chipColor : Colors.white.withOpacity(0.8),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: isSelected
                        ? chipColor.withOpacity(0.3)
                        : Colors.black.withOpacity(0.05),
                    blurRadius: isSelected ? 8 : 4,
                    offset: const Offset(0, 2)),
              ],
              border: Border.all(
                color: isSelected ? chipColor : _C.divider,
                width: 1,
              ),
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

  // ── Request List ──────────────────────────────────────────────────────
  Widget _buildRequestList() {
    return StreamBuilder<List<RequestModel>>(
      stream: _getRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: _C.tealDark));
        }

        final requests = snapshot.data ?? [];
        if (requests.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) =>
              _RequestCard(
                request: requests[index],
                requestService: _requestService,
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
            child: const Icon(Icons.inbox_rounded,
                size: 36, color: _C.tealDark),
          ),
          const SizedBox(height: 14),
          const Text('No requests found',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark)),
          const SizedBox(height: 4),
          const Text('Check back later',
              style: TextStyle(fontSize: 12, color: _C.textMid)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Request Card
// ─────────────────────────────────────────────
class _RequestCard extends StatefulWidget {
  final RequestModel request;
  final RequestService requestService;

  const _RequestCard(
      {required this.request, required this.requestService});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard>
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

  @override
  Widget build(BuildContext context) {
    final r        = widget.request;
    final restroom = r.restroom;
    final status   = r.status;
    final createdAt = r.createdAt.toDate();

    final formattedDate =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')}  '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.selectionClick();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => _RequestPopup(
            request: r,
            requestService: widget.requestService,
          ),
        );
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
                    // ID row
                    Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: _C.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt_long_rounded,
                              size: 18, color: _C.orange),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.requestId,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _C.textDark),
                              ),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                    fontSize: 10, color: _C.textLight),
                              ),
                            ],
                          ),
                        ),
                        _statusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Divider(color: _C.divider, height: 1, thickness: 1),
                    const SizedBox(height: 10),

                    // Location
                    _infoRow(Icons.wc_rounded, restroom.restroomName),
                    const SizedBox(height: 5),
                    _infoRow(
                        Icons.location_on_rounded, restroom.address),
                    const SizedBox(height: 5),
                    _infoRow(
                        Icons.person_rounded, r.userId),

                    // Photos count
                    if (restroom.photos.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.photo_library_rounded,
                              size: 12, color: _C.textLight),
                          const SizedBox(width: 4),
                          Text(
                            '${restroom.photos.length} photos attached',
                            style: const TextStyle(
                                fontSize: 10, color: _C.textLight),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Footer: tap to review
              if (status == Status.pending)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _C.teal.withOpacity(0.15),
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(16)),
                  ),
                  child: const Center(
                    child: Text(
                      'Tap to review →',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _C.tealDark),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(Status status) {
    Color color;
    String label;
    if (status == Status.approved) {
      color = _C.green;
      label = 'Approved';
    } else if (status == Status.rejected) {
      color = _C.redLight;
      label = 'Rejected';
    } else {
      color = _C.orange;
      label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _C.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: _C.textMid),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Request Detail Popup (bottom sheet)
// ─────────────────────────────────────────────
class _RequestPopup extends StatelessWidget {
  final RequestModel request;
  final RequestService requestService;

  const _RequestPopup(
      {required this.request, required this.requestService});

  Future<void> _approve(BuildContext context) async {
    try {
      await RestroomService().createRestroom(request.restroom);
      await requestService.updateSpecificField(
          request.requestId, {'status': Status.approved.name});
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'Request approved — toilet added!', _C.green);
      }
    } catch (e) {
      if (context.mounted) {
        _snack(context, 'Error: $e', _C.redLight);
      }
    }
  }

  Future<void> _reject(BuildContext context) async {
    try {
      await requestService.updateSpecificField(
          request.requestId, {'status': Status.rejected.name});
      if (context.mounted) {
        Navigator.pop(context);
        _snack(context, 'Request rejected.', _C.redLight);
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final r         = request.restroom;
    final createdAt = request.createdAt.toDate();
    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.year}';
    final hoursText = r.is24hrs
        ? '24 Hours'
        : (r.openTime != null && r.closeTime != null
            ? '${r.openTime} – ${r.closeTime}'
            : 'N/A');

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: _C.bg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
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
                    // Title
                    Text(r.restroomName,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: _C.textDark)),
                    const SizedBox(height: 2),
                    Text('ID: ${request.requestId}',
                        style: const TextStyle(
                            fontSize: 10, color: _C.textLight)),
                    const SizedBox(height: 16),

                    // Price & Hours
                    Row(
                      children: [
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.payments_rounded,
                            iconColor: _C.tealDark,
                            label: 'Price',
                            value: r.isFree
                                ? 'Free'
                                : '฿${r.price?.toStringAsFixed(0)}',
                            color: _C.teal,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoCard(
                            icon: Icons.access_time_rounded,
                            iconColor: _C.orange,
                            label: 'Hours',
                            value: hoursText,
                            color: _C.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Address
                    _detailRow(Icons.location_on_rounded, r.address),
                    const SizedBox(height: 16),

                    // Photos
                    _popupSectionLabel('Photos (${r.photos.length})',
                        Icons.photo_library_rounded),
                    const SizedBox(height: 10),
                    _buildPhotoGrid(r.photos),
                    const SizedBox(height: 16),

                    // Amenities
                    _popupSectionLabel(
                        'Amenities', Icons.check_circle_outline_rounded),
                    const SizedBox(height: 8),
                    _buildAmenities(r.amenities),
                    const SizedBox(height: 16),

                    // Submitted by
                    _popupSectionLabel(
                        'Submitted By', Icons.person_rounded),
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
                          Text(request.userId,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _C.textDark)),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text('Submitted',
                                  style: TextStyle(
                                      fontSize: 9, color: _C.textLight)),
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

                    // Action buttons
                    if (request.status == Status.pending)
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Approve',
                              color: _C.green,
                              onTap: () => _approve(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _ActionButton(
                              label: 'Reject',
                              color: _C.redLight,
                              onTap: () => _reject(context),
                            ),
                          ),
                        ],
                      )
                    else
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: (request.status == Status.approved
                                    ? _C.green
                                    : _C.redLight)
                                .withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.status == Status.approved
                                ? '✓  Already Approved'
                                : '✗  Already Rejected',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: request.status == Status.approved
                                    ? _C.green
                                    : _C.redLight),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _popupSectionLabel(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _C.teal.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 14, color: _C.tealDark),
        ),
        const SizedBox(width: 8),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: _C.textLight),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text,
              style: const TextStyle(
                  fontSize: 12, color: _C.textMid)),
        ),
      ],
    );
  }

  Widget _buildPhotoGrid(List<String> photos) {
    final displayPhotos = photos.take(2).toList();
    final remaining     = photos.length - 2;
    return Row(
      children: [
        ...displayPhotos.map((url) => Container(
              width: 84,
              height: 62,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _C.divider,
                borderRadius: BorderRadius.circular(10),
                image: DecorationImage(
                    image: NetworkImage(url), fit: BoxFit.cover),
              ),
            )),
        Container(
          width: 84,
          height: 62,
          decoration: BoxDecoration(
            border: Border.all(color: _C.divider, width: 1.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              remaining > 0 ? '+$remaining' : '+',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: _C.textLight),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(Map<String, bool> amenities) {
    final defaults = {
      'Toilet Paper': false, 'Hand Dryer': false,
      'Baby Changing': false, 'WiFi': false,
      'Soap': false, 'Wheelchair': false,
      'Hot Water': false, 'Power Outlet': false,
    };
    final merged = {...defaults, ...amenities};
    final keys   = merged.keys.toList();
    final half   = (keys.length / 2).ceil();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _amenityCol(keys.take(half).toList(), merged)),
        const SizedBox(width: 8),
        Expanded(child: _amenityCol(keys.skip(half).toList(), merged)),
      ],
    );
  }

  Widget _amenityCol(List<String> keys, Map<String, bool> m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys.map((k) {
        final has = m[k] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Row(
            children: [
              Icon(
                has ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 14,
                color: has ? _C.green : _C.textLight,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(k,
                    style: TextStyle(
                        fontSize: 11,
                        color: has ? _C.textDark : _C.textLight,
                        fontWeight: has
                            ? FontWeight.w600
                            : FontWeight.w400)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Small info card (Price / Hours)
// ─────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color color;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: iconColor),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: iconColor)),
            ],
          ),
          const SizedBox(height: 5),
          Text(value,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: iconColor)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action button (Approve / Reject)
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
              colors: [
                widget.color,
                widget.color.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
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

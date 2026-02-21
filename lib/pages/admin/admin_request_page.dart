import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/request_model.dart';
import 'package:restroom_near_u/services/request_firestore.dart';
import 'package:restroom_near_u/services/restroom_firestore.dart';

class AdminRequestPage extends StatefulWidget {
  const AdminRequestPage({super.key});

  @override
  State<AdminRequestPage> createState() => _AdminRequestPageState();
}

class _AdminRequestPageState extends State<AdminRequestPage> {
  final RequestService _requestService = RequestService();
  String _selectedFilter = 'All';

  Stream<List<RequestModel>> _getRequestsStream() {
    // RequestService.getRequestsStream() returns all; filter client-side
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
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      body: SafeArea(
        child: StreamBuilder<List<RequestModel>>(
          // Use unfiltered stream for the count in the header
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
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context, int pendingCount) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 16, 16, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: const Icon(Icons.arrow_back, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toilet Requests',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black),
                ),
                Text(
                  '$pendingCount pending requests',
                  style: const TextStyle(fontSize: 11, color: Colors.black54),
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
    final filters = ['All', 'Approved', 'Rejected'];
    return Row(
      children: filters.map((f) {
        final isSelected = _selectedFilter == f;
        return GestureDetector(
          onTap: () => setState(() => _selectedFilter = f),
          child: Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.black.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              f,
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

  // ─── Request List ─────────────────────────────────────────────────────
  Widget _buildRequestList() {
    return StreamBuilder<List<RequestModel>>(
      stream: _getRequestsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final requests = snapshot.data ?? [];

        if (requests.isEmpty) {
          return const Center(
            child: Text('No requests found.',
                style: TextStyle(color: Colors.black54)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) =>
              _buildRequestCard(context, requests[index]),
        );
      },
    );
  }

  // ─── Request Card ─────────────────────────────────────────────────────
  Widget _buildRequestCard(BuildContext context, RequestModel request) {
    final restroom = request.restroom;
    final requestId = request.requestId;
    final status = request.status;
    final createdAt = request.createdAt.toDate();
    final photoCount = restroom.photos.length;

    final formattedDate =
        '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.day.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}.${createdAt.minute.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _RequestPopup(
          request: request,
          requestService: _requestService,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9EA),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 2,
                offset: const Offset(0, 1)),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top: Request ID + attachments
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Request ID : $requestId',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black),
                ),
                Row(
                  children: [
                    const Icon(Icons.attach_file,
                        size: 12, color: Colors.black45),
                    const SizedBox(width: 2),
                    Text('$photoCount',
                        style: const TextStyle(
                            fontSize: 9, color: Colors.black54)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.map_outlined,
                    size: 10, color: Colors.black54),
                const SizedBox(width: 4),
                Text('Area : ${restroom.address}',
                    style: const TextStyle(
                        fontSize: 9, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 10, color: Colors.black54),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Location : ${restroom.restroomName}',
                    style: const TextStyle(
                        fontSize: 9, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 10, color: Colors.black54),
                const SizedBox(width: 4),
                Text(
                  'Requested By : ${request.userId}',
                  style: const TextStyle(
                      fontSize: 9, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(formattedDate,
                style: const TextStyle(
                    fontSize: 7, color: Colors.black38)),

            // Status badge (only for non-pending)
            if (status != Status.pending) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (status == Status.approved
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444))
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  status == Status.approved ? 'Approved' : 'Rejected',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: status == Status.approved
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Request Detail Popup
// ─────────────────────────────────────────────
class _RequestPopup extends StatelessWidget {
  final RequestModel request;
  final RequestService requestService;

  const _RequestPopup({
    required this.request,
    required this.requestService,
  });

  Future<void> _approve(BuildContext context) async {
    try {
      // 1. Add restroom to restrooms collection
      await RestroomService().createRestroom(request.restroom);
      // 2. Update request status
      await requestService.updateSpecificField(
          request.requestId, {'status': Status.approved.name});

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved — toilet added!'),
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

  Future<void> _reject(BuildContext context) async {
    try {
      await requestService.updateSpecificField(
          request.requestId, {'status': Status.rejected.name});

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected.'),
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

  @override
  Widget build(BuildContext context) {
    final r = request.restroom;
    final createdAt = request.createdAt.toDate();
    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}-${createdAt.month.toString().padLeft(2, '0')}-${createdAt.year}';

    final hoursText = r.is24hrs
        ? '24 Hours'
        : (r.openTime != null && r.closeTime != null
            ? '${r.openTime} - ${r.closeTime}'
            : 'N/A');

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
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
                    borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(r.restroomName,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                      const SizedBox(height: 2),
                      Text('RequestID : ${request.requestId}',
                          style: const TextStyle(
                              fontSize: 9, color: Colors.black45)),
                      const SizedBox(height: 16),

                      // Price & Hours cards
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.attach_money,
                              iconColor: const Color(0xFF91B1AD),
                              label: 'Price',
                              value: r.isFree
                                  ? 'Free'
                                  : '฿${r.price?.toStringAsFixed(0)}',
                              borderColor: const Color(0xFFBADFDB),
                              bgColor: const Color(0xFFBADFDB)
                                  .withOpacity(0.3),
                              valueColor: const Color(0xFF91B1AD),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.access_time,
                              iconColor: const Color(0xFFFFA4A4),
                              label: 'Hours',
                              value: hoursText,
                              borderColor: const Color(0xFFFFA4A4),
                              bgColor: const Color(0xFFFFA4A4)
                                  .withOpacity(0.3),
                              valueColor: const Color(0xFFFFA4A4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Address
                      _detailRow(
                          Icons.location_on_outlined, r.address),
                      const SizedBox(height: 16),

                      // Photos
                      Row(
                        children: const [
                          Icon(Icons.photo_outlined,
                              size: 16, color: Colors.black),
                          SizedBox(width: 6),
                          Text('Photos',
                              style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildPhotoGrid(r.photos),
                      const SizedBox(height: 16),

                      // Amenities
                      const Text('Amenities',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.black)),
                      const SizedBox(height: 8),
                      _buildAmenities(r.amenities),
                      const SizedBox(height: 16),

                      // Submitter info
                      const Text('Submitted By',
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
                            Text(request.userId,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black)),
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

                      // Action buttons (only show for pending)
                      if (request.status == Status.pending)
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _approve(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 12),
                                ),
                                child: const Text('Approve',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _reject(context),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color(0xFFEF4444),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(8)),
                                  padding:
                                      const EdgeInsets.symmetric(
                                          vertical: 12),
                                ),
                                child: const Text('Reject',
                                    style: TextStyle(
                                        fontWeight:
                                            FontWeight.w700)),
                              ),
                            ),
                          ],
                        )
                      else
                        // Already processed — show status
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: (request.status == Status.approved
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444))
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              request.status == Status.approved
                                  ? '✓ Already Approved'
                                  : '✗ Already Rejected',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: request.status ==
                                          Status.approved
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444)),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.black54),
        const SizedBox(width: 6),
        Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 11, color: Colors.black87))),
      ],
    );
  }

  Widget _buildPhotoGrid(List<String> photos) {
    final displayPhotos = photos.take(2).toList();
    final remaining = photos.length - 2;
    return Row(
      children: [
        ...displayPhotos.map((url) => Container(
              width: 80,
              height: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 0.5),
                image: DecorationImage(
                    image: NetworkImage(url), fit: BoxFit.cover),
              ),
            )),
        Container(
          width: 80,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(
                color: Colors.grey.shade400, width: 1,
                style: BorderStyle.solid),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              remaining > 0 ? '+$remaining' : '+',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenities(Map<String, bool> amenities) {
    final defaults = {
      'Toilet paper': false,
      'Hand Dryer': false,
      'Baby Changing Station': false,
      'WiFi': false,
      'Soap': false,
      'Wheelchair Accessible': false,
      'Hot water': false,
      'Power Outlet': false,
    };
    final merged = {...defaults, ...amenities};
    final keys = merged.keys.toList();
    final half = (keys.length / 2).ceil();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
            child: _amenityColumn(
                keys.take(half).toList(), merged)),
        const SizedBox(width: 8),
        Expanded(
            child: _amenityColumn(
                keys.skip(half).toList(), merged)),
      ],
    );
  }

  Widget _amenityColumn(
      List<String> keys, Map<String, bool> amenities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys.map((key) {
        final has = amenities[key] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                has
                    ? Icons.check_box_outlined
                    : Icons.disabled_by_default_outlined,
                size: 12,
                color: has
                    ? const Color(0xFF10B981)
                    : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Expanded(
                  child: Text(key,
                      style: const TextStyle(
                          fontSize: 10, color: Colors.black87))),
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
  final Color borderColor;
  final Color bgColor;
  final Color valueColor;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.borderColor,
    required this.bgColor,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 10, color: iconColor),
              const SizedBox(width: 3),
              Text(label,
                  style: TextStyle(
                      fontSize: 9,
                      color: iconColor,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: valueColor)),
        ],
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:restroom_near_u/services/restroom_firestore.dart';
import 'package:restroom_near_u/services/request_firestore.dart';
import 'package:restroom_near_u/services/user_firestore.dart';
import 'package:restroom_near_u/models/restroom_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// EmailJS config — fill these in after setting up your EmailJS account
// See: https://www.emailjs.com/docs/tutorial/overview/
// ─────────────────────────────────────────────────────────────────────────────
const _kEmailJsServiceId          = 'service_649fgic';
const _kEmailJsTemplateIdApproved = 'template_8j1e3cb';
const _kEmailJsTemplateIdRejected = 'template_9l01srl';
const _kEmailJsPublicKey          = 'uUFWNA5xDdm-szEYB';

class AdminRequestPopup extends StatelessWidget {
  final Map<String, dynamic> requestData;
  final String requestDocId;

  const AdminRequestPopup({
    super.key,
    required this.requestData,
    required this.requestDocId,
  });

  // ── EmailJS helper ────────────────────────────────────────────────────────
  Future<void> _sendEmail({
    required String templateId,
    required Map<String, String> templateParams,
  }) async {
    const url = 'https://api.emailjs.com/api/v1.0/email/send';
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id':      _kEmailJsServiceId,
          'template_id':     templateId,
          'user_id':         _kEmailJsPublicKey,
          'template_params': templateParams,
        }),
      );
      if (response.statusCode == 200) {
        debugPrint('EmailJS ✅ email sent successfully');
      } else {
        debugPrint('EmailJS ❌ ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('EmailJS exception: $e');
    }
  }

  // ── Approve ───────────────────────────────────────────────────────────────
  Future<void> _approveRequest(BuildContext context) async {
    final requestId    = requestDocId;
    final newRestroomId = FirebaseFirestore.instance.collection('restrooms').doc().id;

    try {
      final restroom = RestroomModel(
        restroomId:   newRestroomId,
        restroomName: requestData['restroomName']  ?? '',
        address:      requestData['address']        ?? '',
        latitude:     (requestData['latitude']  ?? 0.0).toDouble(),
        longitude:    (requestData['longitude'] ?? 0.0).toDouble(),
        openTime:     requestData['openTime'],
        closeTime:    requestData['closeTime'],
        isFree:       requestData['isFree']     ?? true,
        price:        requestData['price']?.toDouble(),
        is24hrs:      requestData['is24hrs']    ?? false,
        phoneNumber:  requestData['phoneNumber'] ?? '',
        amenities:    Map<String, bool>.from(requestData['amenities'] ?? {}),
        photos:       List<String>.from(requestData['photos'] ?? []),
        createdBy:    requestData['requestedBy'] ?? '',
      );

      await RestroomService().createRestroom(restroom);
      await RequestService().updateSpecificField(requestId, {
        'status':     'approved',
        'restroomId': newRestroomId,
      });

      // ✅ Increment totalAdded for the user who submitted this request
      final requestedBy = requestData['requestedBy'] as String? ?? '';
      if (requestedBy.isNotEmpty) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(requestedBy)
            .update({'totalAdded': FieldValue.increment(1)});
      }

      // ✅ Send approval email (fire-and-forget — won't block the UI)
      final recipientEmail = requestData['requestedByEmail'] as String? ?? '';
      final recipientName  = requestData['requestedByName']  as String? ?? 'User';
      final restroomName   = requestData['restroomName']     as String? ?? 'Your Restroom';

      if (recipientEmail.isNotEmpty) {
        _sendEmail(
          templateId: _kEmailJsTemplateIdApproved,
          templateParams: {
            'to_email':      recipientEmail,
            'to_name':       recipientName,
            'restroom_name': restroomName,
          },
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved! User will be notified by email.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Reject ────────────────────────────────────────────────────────────────
  Future<void> _rejectRequest(BuildContext context) async {
    final requestId = requestDocId;

    // Ask admin for an optional rejection reason before confirming
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFCF9EA),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Reject Request',
          style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1C1B1F)),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The user will be notified by email. You can optionally add a reason.',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B6874)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason (optional)',
                filled: true,
                fillColor: const Color(0xFFF2EFE0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: Color(0xFF6B6874), fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Reject',
                style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final reason = reasonController.text.trim();
      final updateData = <String, dynamic>{'status': 'rejected'};
      if (reason.isNotEmpty) updateData['rejectionReason'] = reason;

      await RequestService().updateSpecificField(requestId, updateData);

      // ✅ Send rejection email (fire-and-forget)
      final recipientEmail = requestData['requestedByEmail'] as String? ?? '';
      final recipientName  = requestData['requestedByName']  as String? ?? 'User';
      final restroomName   = requestData['restroomName']     as String? ?? 'Your Restroom';

      if (recipientEmail.isNotEmpty) {
        _sendEmail(
          templateId: _kEmailJsTemplateIdRejected,
          templateParams: {
            'to_email':      recipientEmail,
            'to_name':       recipientName,
            'restroom_name': restroomName,
            'reason':        reason.isNotEmpty ? reason : 'No reason provided.',
          },
        );
      }

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request rejected. User will be notified by email.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final requestId         = requestDocId;
    final restroomName      = requestData['restroomName']      ?? '3rd floor Siam Paragon';
    final isFree            = requestData['isFree']            ?? true;
    final price             = requestData['price'];
    final openTime          = requestData['openTime']          ?? '08:00';
    final closeTime         = requestData['closeTime']         ?? '18:00';
    final is24hrs           = requestData['is24hrs']           ?? false;
    final photos            = List<String>.from(requestData['photos'] ?? []);
    final amenities         = Map<String, bool>.from(requestData['amenities'] ?? {});
    final comment           = requestData['description']       ?? '"Clean and good"';
    final requestedByName   = requestData['requestedByName']   ?? 'Pheeraphat Jumnong';
    final requestedByEmail  = requestData['requestedByEmail']  ?? '';
    final createdAt         = requestData['createdAt'];

    String formattedDate = '';
    if (createdAt != null && createdAt is Timestamp) {
      final dt = createdAt.toDate();
      formattedDate =
          '${dt.day.toString().padLeft(2, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.year}';
    }

    final hoursText = is24hrs ? '24 Hours' : '$openTime - $closeTime';

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFFCF9EA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
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
                      Text(
                        restroomName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'RequestID : $requestId',
                        style: const TextStyle(fontSize: 9, color: Colors.black45),
                      ),
                      const SizedBox(height: 16),

                      // Price & Hours cards
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBADFDB).withOpacity(0.3),
                                border: Border.all(color: const Color(0xFFBADFDB)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: const [
                                    Icon(Icons.attach_money, size: 10, color: Color(0xFF91B1AD)),
                                    SizedBox(width: 3),
                                    Text('Price',
                                        style: TextStyle(fontSize: 9, color: Color(0xFF91B1AD), fontWeight: FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    isFree ? 'Free' : '฿${price?.toStringAsFixed(0)}',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF91B1AD)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFA4A4).withOpacity(0.3),
                                border: Border.all(color: const Color(0xFFFFA4A4)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: const [
                                    Icon(Icons.access_time, size: 10, color: Color(0xFFFFA4A4)),
                                    SizedBox(width: 3),
                                    Text('Hours',
                                        style: TextStyle(fontSize: 9, color: Color(0xFFFFA4A4), fontWeight: FontWeight.w600)),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                    hoursText,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFFFA4A4)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      const Text('Photos', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                      const SizedBox(height: 8),
                      _buildPhotoGrid(photos),
                      const SizedBox(height: 16),

                      const Text('Amenities', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                      const SizedBox(height: 8),
                      _buildAmenities(amenities),
                      const SizedBox(height: 16),

                      const Text('Comments', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black)),
                      const SizedBox(height: 8),
                      _buildComment(comment),
                      const SizedBox(height: 6),
                      _buildSubmitterInfo(requestedByName, requestedByEmail, formattedDate),
                      const SizedBox(height: 24),

                      // Approve / Reject buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _approveRequest(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => _rejectRequest(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFEF4444),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
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
        );
      },
    );
  }

  // ─── Photo Grid ───────────────────────────────────────────────────────────
  Widget _buildPhotoGrid(List<String> photos) {
    final displayPhotos = photos.take(2).toList();
    final remaining = photos.length - 2;

    return Row(
      children: [
        ...displayPhotos.map(
          (url) => Container(
            width: 80,
            height: 56,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.black, width: 0.5),
              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
          ),
        ),
        Container(
          width: 80,
          height: 56,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade400, width: 1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              remaining > 0 ? '+$remaining' : '+',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.grey.shade400),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Amenities ────────────────────────────────────────────────────────────
  Widget _buildAmenities(Map<String, bool> amenities) {
    final defaultAmenities = {
      'Toilet paper': false,
      'Hand Dryer': false,
      'Baby Changing Station': false,
      'WiFi': false,
      'Soap': false,
      'Wheelchair Accessible': false,
      'Hot water': false,
      'Power Outlet': false,
    };
    final merged = {...defaultAmenities, ...amenities};
    final keys   = merged.keys.toList();
    final half   = (keys.length / 2).ceil();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildAmenityColumn(keys.take(half).toList(), merged)),
        const SizedBox(width: 8),
        Expanded(child: _buildAmenityColumn(keys.skip(half).toList(), merged)),
      ],
    );
  }

  Widget _buildAmenityColumn(List<String> keys, Map<String, bool> amenities) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: keys.map((key) {
        final hasIt = amenities[key] ?? false;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                hasIt ? Icons.check_box_outlined : Icons.disabled_by_default_outlined,
                size: 12,
                color: hasIt ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(key, style: const TextStyle(fontSize: 10, color: Colors.black87)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ─── Comment ──────────────────────────────────────────────────────────────
  Widget _buildComment(String comment) {
    return Row(
      children: [
        Container(width: 4, height: 22, color: const Color(0xFFE8753D)),
        Expanded(
          child: Container(
            height: 22,
            color: const Color(0xFFE8753D).withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.centerLeft,
            child: Text('"$comment"',
                style: const TextStyle(fontSize: 12, color: Colors.black87)),
          ),
        ),
      ],
    );
  }

  // ─── Submitter Info ───────────────────────────────────────────────────────
  Widget _buildSubmitterInfo(String name, String email, String date) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
              if (email.isNotEmpty)
                Text(email, style: const TextStyle(fontSize: 8, color: Colors.black45)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('Submitted', style: TextStyle(fontSize: 8, color: Colors.black45)),
              Text(date,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black)),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/restroom_model.dart';
import 'package:restroom_near_u/pages/user/restroom_detail_page.dart';
import 'package:restroom_near_u/services/restroom_firestore.dart';

// ─────────────────────────────────────────────
// Design tokens (matches project theme)
// ─────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFFCF9EA);
  static const card       = Color(0xFFFFFDFA);
  static const teal       = Color(0xFFBADFDB);
  static const tealDark   = Color(0xFF7BBFBA);
  static const pink       = Color(0xFFEC9B9B);
  static const pinkLight  = Color(0xFFF5D4D4);
  static const orange     = Color(0xFFE8753D);
  static const openGreen  = Color(0xFF34A853);
  static const closeRed   = Color(0xFFE53935);
  static const textDark   = Color(0xFF1C1B1F);
  static const textMid    = Color(0xFF6B6874);
  static const textLight  = Color(0xFFAEABB8);
  static const divider    = Color(0xFFECE9DA);
  static const searchFill = Color(0xFFEEEBDA);
}

class AdminTotalToiletsPage extends StatefulWidget {
  const AdminTotalToiletsPage({super.key});

  @override
  State<AdminTotalToiletsPage> createState() => _AdminTotalToiletsPageState();
}

class _AdminTotalToiletsPageState extends State<AdminTotalToiletsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final RestroomService _restroomService = RestroomService();

  String _searchQuery = '';
  String _selectedFilter = 'All';
  late AnimationController _listEntryController;

  final filters = ['All', 'Free', 'Paid', 'Open', 'Closed'];

  @override
  void initState() {
    super.initState();
    _listEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _listEntryController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<RestroomModel> _applyFilters(List<RestroomModel> restrooms) {
    return restrooms.where((r) {
      final matchesSearch = _searchQuery.isEmpty ||
          r.restroomName.toLowerCase().contains(_searchQuery) ||
          r.address.toLowerCase().contains(_searchQuery);

      final now = TimeOfDay.now();
      bool isOpen = true;
      if (!r.is24hrs && r.openTime != null && r.closeTime != null) {
        try {
          final open = _parseTime(r.openTime!);
          final close = _parseTime(r.closeTime!);
          final nowMins = now.hour * 60 + now.minute;
          final openMins = open.hour * 60 + open.minute;
          final closeMins = close.hour * 60 + close.minute;
          isOpen = nowMins >= openMins && nowMins < closeMins;
        } catch (_) {}
      }

      final matchesFilter = switch (_selectedFilter) {
        'Free'   => r.isFree,
        'Paid'   => !r.isFree,
        'Open'   => isOpen,
        'Closed' => !isOpen,
        _        => true,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  bool _isOpen(RestroomModel r) {
    if (r.is24hrs) return true;
    if (r.openTime == null || r.closeTime == null) return true;
    try {
      final now = TimeOfDay.now();
      final open = _parseTime(r.openTime!);
      final close = _parseTime(r.closeTime!);
      final nowMins = now.hour * 60 + now.minute;
      return nowMins >= (open.hour * 60 + open.minute) &&
          nowMins < (close.hour * 60 + close.minute);
    } catch (_) {
      return true;
    }
  }

  Future<void> _confirmDelete(BuildContext context, RestroomModel restroom) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Toilet',
            style: TextStyle(fontWeight: FontWeight.w800, color: _C.textDark)),
        content: Text(
          'Are you sure you want to delete "${restroom.restroomName}"? This cannot be undone.',
          style: const TextStyle(fontSize: 13, color: _C.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: _C.textMid, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(color: _C.closeRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _restroomService.deleteRestroom(restroom.restroomId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${restroom.restroomName}" deleted.'),
              backgroundColor: _C.closeRed,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
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
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(context),
              _buildSearchBar(),
              _buildFilterChips(),
              const SizedBox(height: 4),
              Expanded(child: _buildToiletList()),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
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
              child: const Icon(Icons.arrow_back_rounded,
                  size: 20, color: _C.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('restrooms')
                  .snapshots(),
              builder: (context, snapshot) {
                final count = snapshot.data?.size ?? 0;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'All Toilets',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark),
                    ),
                    Text(
                      '$count toilets registered',
                      style: const TextStyle(
                          fontSize: 12, color: _C.textMid),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── Search Bar ───────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        height: 46,
        decoration: BoxDecoration(
          color: _C.searchFill,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search_rounded, color: _C.textLight, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                    fontSize: 14,
                    color: _C.textDark,
                    fontWeight: FontWeight.w500),
                decoration: const InputDecoration(
                  hintText: 'Search by name or address…',
                  hintStyle: TextStyle(
                      color: _C.textLight,
                      fontSize: 14,
                      fontWeight: FontWeight.w400),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.close_rounded,
                      size: 18, color: _C.textLight),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ─── Filter Chips ─────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = filters[i];
          final selected = _selectedFilter == f;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _selectedFilter = f;
                _listEntryController.forward(from: 0);
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? _C.tealDark : Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: selected
                          ? _C.tealDark.withOpacity(0.3)
                          : Colors.black.withOpacity(0.06),
                      blurRadius: selected ? 8 : 4,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                f,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : _C.textMid,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Toilet List ──────────────────────────────────────────────────────
  Widget _buildToiletList() {
    return StreamBuilder<List<RestroomModel>>(
      stream: _restroomService.getRestroomsStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: _C.tealDark));
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error loading toilets',
                style: const TextStyle(color: _C.textMid)),
          );
        }

        final all = snapshot.data ?? [];
        final filtered = _applyFilters(all);

        if (filtered.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final delay = (index * 0.06).clamp(0.0, 0.55);
            final itemAnim = CurvedAnimation(
              parent: _listEntryController,
              curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
                  curve: Curves.easeOutCubic),
            );
            return AnimatedBuilder(
              animation: itemAnim,
              builder: (_, child) => Transform.translate(
                offset: Offset(0, 20 * (1 - itemAnim.value)),
                child: Opacity(opacity: itemAnim.value, child: child),
              ),
              child: _ToiletCard(
                restroom: filtered[index],
                isOpen: _isOpen(filtered[index]),
                onDelete: () => _confirmDelete(context, filtered[index]),
              ),
            );
          },
        );
      },
    );
  }

  // ─── Empty State ──────────────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.wc_rounded, size: 40, color: _C.tealDark),
          ),
          const SizedBox(height: 16),
          const Text('No toilets found',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark)),
          const SizedBox(height: 6),
          const Text('Try adjusting your search or filter',
              style: TextStyle(fontSize: 13, color: _C.textMid)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Toilet Card
// ─────────────────────────────────────────────
class _ToiletCard extends StatefulWidget {
  final RestroomModel restroom;
  final bool isOpen;
  final VoidCallback onDelete;

  const _ToiletCard({
    required this.restroom,
    required this.isOpen,
    required this.onDelete,
  });

  @override
  State<_ToiletCard> createState() => _ToiletCardState();
}

class _ToiletCardState extends State<_ToiletCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.968)
        .animate(CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.restroom;
    final hours = r.is24hrs
        ? '24 Hours'
        : (r.openTime != null && r.closeTime != null
            ? '${r.openTime} – ${r.closeTime}'
            : 'N/A');

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          _smoothRoute(RestroomDetailPage(restroom: r)),
        );
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _C.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: _C.divider, width: 1),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
              BoxShadow(
                  color: Colors.white.withOpacity(0.8),
                  blurRadius: 0),
            ],
          ),
          child: Column(
            children: [
              // ── Main content row ──
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon thumbnail
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.teal.withOpacity(0.4),
                            _C.teal.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                              color: _C.teal.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3)),
                        ],
                      ),
                      child: r.photos.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: Image.network(r.photos.first,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                      Icons.wc_rounded,
                                      color: _C.tealDark,
                                      size: 28)),
                            )
                          : const Icon(Icons.wc_rounded,
                              color: _C.tealDark, size: 28),
                    ),
                    const SizedBox(width: 12),

                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name + Open/Closed badge
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  r.restroomName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _C.textDark,
                                      height: 1.2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              _StatusBadge(isOpen: widget.isOpen),
                            ],
                          ),
                          const SizedBox(height: 4),

                          // Address
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  size: 11, color: _C.textLight),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  r.address,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: _C.textMid,
                                      height: 1.3),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Chips row
                          Row(
                            children: [
                              _MiniChip(
                                icon: Icons.star_rounded,
                                iconColor: _C.orange,
                                label: r.avgRating.toStringAsFixed(1),
                              ),
                              const SizedBox(width: 6),
                              _MiniChip(
                                icon: r.isFree
                                    ? Icons.money_off_rounded
                                    : Icons.paid_rounded,
                                iconColor: _C.tealDark,
                                label: r.isFree ? 'Free' : 'Paid',
                              ),
                              const SizedBox(width: 6),
                              _MiniChip(
                                icon: Icons.access_time_rounded,
                                iconColor: _C.textMid,
                                label: hours,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Divider ──
              Divider(color: _C.divider, height: 1, thickness: 1),

              // ── Footer: stats + delete ──
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  children: [
                    // Reviews count
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 13, color: _C.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '${r.totalRatings} reviews',
                      style: const TextStyle(
                          fontSize: 11,
                          color: _C.textMid,
                          fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 12),
                    // Amenities count
                    Icon(Icons.check_circle_outline_rounded,
                        size: 13, color: _C.textLight),
                    const SizedBox(width: 4),
                    Text(
                      '${r.amenities.values.where((v) => v).length} amenities',
                      style: const TextStyle(
                          fontSize: 11,
                          color: _C.textMid,
                          fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    // Delete button
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        widget.onDelete();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: _C.closeRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.delete_outline_rounded,
                                size: 13, color: _C.closeRed),
                            SizedBox(width: 4),
                            Text('Delete',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _C.closeRed)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Mini info chip (reused from user homepage)
// ─────────────────────────────────────────────
class _MiniChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _MiniChip({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _C.searchFill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 12),
          const SizedBox(width: 3),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _C.textDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Open / Closed badge
// ─────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isOpen ? _C.openGreen : _C.closeRed).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Open' : 'Closed',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isOpen ? _C.openGreen : _C.closeRed,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Smooth iOS-style route transition
// ─────────────────────────────────────────────
Route<dynamic> _smoothRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, animation, __) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

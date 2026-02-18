import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/restroom_model.dart';
import '../../services/restroom_service.dart';
import 'restroom_detail_page.dart';

// ─────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFFCF9EA);
  static const sheet      = Color(0xFFFAF7E8);
  static const teal       = Color(0xFFBADFDB);
  static const tealDark   = Color(0xFF7BBFBA);
  static const orange     = Color(0xFFE8753D);
  static const textDark   = Color(0xFF1C1B1F);
  static const textMid    = Color(0xFF6B6874);
  static const textLight  = Color(0xFFAEABB8);
  static const openGreen  = Color(0xFF34A853);
  static const closeRed   = Color(0xFFE53935);
  static const divider    = Color(0xFFECE9DA);
  static const pill       = Color(0xFFD8D4C4);
  static const searchFill = Color(0xFFEEEBDA);
}

// ─────────────────────────────────────────────
// UserHomePage
// ─────────────────────────────────────────────
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with TickerProviderStateMixin {
  static const _initialCamera = CameraPosition(
    target: LatLng(13.8476, 100.5696),
    zoom: 16.0,
  );

  late List<RestroomModel> restrooms;
  late AnimationController _listEntryController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  @override
  void initState() {
    super.initState();
    restrooms = RestroomService.getMockRestrooms();
    _listEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _listEntryController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  void _toggleSheet() {
    HapticFeedback.mediumImpact();
    final current = _sheetController.size;
    final target = current <= 0.2 ? 0.45 : 0.14;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Stack(
          children: [
            // ── Map ──────────────────────────────────────
            GoogleMap(
              initialCameraPosition: _initialCamera,
              zoomControlsEnabled: false,
              onMapCreated: (_) {},
            ),

            // ── Top pill button: Add New Restroom ─────────
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 16),
                  child: _PillButton(
                    label: 'Add New Restroom',
                    icon: Icons.add_rounded,
                    onTap: () => Navigator.pushNamed(context, '/add_new_restroom'),
                  ),
                ),
              ),
            ),

            // ── Bottom sheet ──────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.45,
              minChildSize: 0.14,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: const [0.14, 0.45, 0.92],
              builder: (context, scrollController) {
                return _BottomSheetContent(
                  scrollController: scrollController,
                  restrooms: restrooms,
                  listEntryController: _listEntryController,
                  onHandleTap: _toggleSheet,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Bottom Sheet Content (extracted for cleanliness)
// ─────────────────────────────────────────────
class _BottomSheetContent extends StatelessWidget {
  final ScrollController scrollController;
  final List<RestroomModel> restrooms;
  final AnimationController listEntryController;
  final VoidCallback onHandleTap;

  const _BottomSheetContent({
    required this.scrollController,
    required this.restrooms,
    required this.listEntryController,
    required this.onHandleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.sheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      // One CustomScrollView owns the scrollController — the handle,
      // search bar, section label, and list items are all slivers so
      // dragging anywhere (including the handle) moves the sheet.
      child: CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          // ── Handle + buttons ──────────────────────────
          SliverToBoxAdapter(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onHandleTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(
                  children: [
                    _CircleIconButton(
                      icon: Icons.person_rounded,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pushNamed(context, '/profile');
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 4.5,
                          decoration: BoxDecoration(
                            color: _C.pill,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                      ),
                    ),
                    _CircleIconButton(
                      icon: Icons.near_me_rounded,
                      onTap: () => HapticFeedback.lightImpact(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Search bar ─────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _SearchBar(),
            ),
          ),

          // ── Section label ──────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Row(
                children: [
                  Text(
                    'Nearby',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textMid,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.teal.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${restrooms.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _C.tealDark,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Restroom list items ───────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final delay = (index * 0.07).clamp(0.0, 0.6);
                final itemAnim = CurvedAnimation(
                  parent: listEntryController,
                  curve: Interval(
                    delay,
                    (delay + 0.4).clamp(0.0, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                );
                return AnimatedBuilder(
                  animation: itemAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 22 * (1 - itemAnim.value)),
                    child: Opacity(opacity: itemAnim.value, child: child),
                  ),
                  child: _RestroomCard(restroom: restrooms[index]),
                );
              },
              childCount: restrooms.length,
            ),
          ),

          // ── Bottom padding ─────────────────────────
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Search Bar
// ─────────────────────────────────────────────
class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _C.searchFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Icon(Icons.search_rounded, color: _C.textLight, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              style: TextStyle(
                fontSize: 14,
                color: _C.textDark,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Search restrooms…',
                hintStyle: TextStyle(
                  color: _C.textLight,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Restroom Card — iOS springy press feedback
// ─────────────────────────────────────────────
class _RestroomCard extends StatefulWidget {
  final RestroomModel restroom;
  const _RestroomCard({required this.restroom});

  @override
  State<_RestroomCard> createState() => _RestroomCardState();
}

class _RestroomCardState extends State<_RestroomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.968).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressController.forward();
  void _onTapUp(_) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    final restroom = widget.restroom;
    final isOpen = RestroomService.isOpen(restroom);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          _smoothRoute(RestroomDetailPage(restroom: restroom)),
        );
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider, width: 1),
          ),
          child: Row(
            children: [
              // ── Thumbnail ────────────────────────
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _C.teal.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.wc_rounded,
                  color: _C.tealDark,
                  size: 26,
                ),
              ),

              const SizedBox(width: 12),

              // ── Text ─────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restroom.restroomName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      restroom.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _C.textMid,
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 7),
                    Row(
                      children: [
                        // Rating chip
                        _MiniChip(
                          icon: Icons.star_rounded,
                          iconColor: _C.orange,
                          label: restroom.avgRating.toStringAsFixed(1),
                        ),
                        const SizedBox(width: 6),
                        // Free/Paid chip
                        _MiniChip(
                          icon: restroom.isFree
                              ? Icons.money_off_rounded
                              : Icons.paid_rounded,
                          iconColor: _C.tealDark,
                          label: restroom.isFree ? 'Free' : 'Paid',
                        ),
                        const Spacer(),
                        // Open/Closed badge
                        _StatusBadge(isOpen: isOpen),
                      ],
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
// Mini info chip
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
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _C.textDark,
            ),
          ),
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isOpen ? _C.openGreen : _C.closeRed,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Circular icon button (profile / nav)
// ─────────────────────────────────────────────
class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
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
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(widget.icon, size: 20, color: _C.textDark),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top pill button (Add New Restroom)
// ─────────────────────────────────────────────
class _PillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PillButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
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
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 18, color: _C.tealDark),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark,
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
// Smooth iOS-style page route
// ─────────────────────────────────────────────
Route<dynamic> _smoothRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1.0, 0.0),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

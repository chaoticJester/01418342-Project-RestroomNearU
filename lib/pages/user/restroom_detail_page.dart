import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/restroom_model.dart';
import '../../models/review_model.dart';
import '../../services/restroom_service.dart';
import '../../services/review_service.dart';
import 'photo_gallery_page.dart';
import 'report_issue_page.dart';
import 'write_review_page.dart';

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
  static const textDark  = Color(0xFF1C1B1F);
  static const textMid   = Color(0xFF6B6874);
  static const textLight = Color(0xFFAEABB8);
  static const divider   = Color(0xFFECE9DA);
  static const fieldFill = Color(0xFFF2EFE0);
}

class RestroomDetailPage extends StatefulWidget {
  final RestroomModel restroom;
  const RestroomDetailPage({Key? key, required this.restroom}) : super(key: key);

  @override
  State<RestroomDetailPage> createState() => _RestroomDetailPageState();
}

class _RestroomDetailPageState extends State<RestroomDetailPage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  late List<ReviewModel> reviews;
  late Map<String, int> ratingBreakdown;
  late bool isOpen;
  late String distance;
  String selectedFilter = 'Recent';
  final Set<String> helpfulReviewIds = {};

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;

  final List<String> filterOptions = [
    'Recent',
    'Highest Rating',
    'Lowest Rating',
    'Most Helpful',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
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

  void _loadData() {
    reviews       = ReviewService.getReviewsByRestroomId(widget.restroom.restroomId);
    ratingBreakdown = RestroomService.getRatingBreakdown(widget.restroom.restroomId);
    isOpen        = RestroomService.isOpen(widget.restroom);
    distance      = RestroomService.getDistance(
      widget.restroom.latitude, widget.restroom.longitude);
  }

  void _sortReviews(String filter) {
    setState(() {
      selectedFilter = filter;
      switch (filter) {
        case 'Recent':
          reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp)); break;
        case 'Highest Rating':
          reviews.sort((a, b) => b.rating.compareTo(a.rating)); break;
        case 'Lowest Rating':
          reviews.sort((a, b) => a.rating.compareTo(b.rating)); break;
        case 'Most Helpful':
          reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount)); break;
      }
    });
  }

  // ── Navigation helpers ──────────────────────────────────────────────
  void _openGallery({int index = 0}) {
    if (widget.restroom.photos.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PhotoGalleryPage(
        restroomId: widget.restroom.restroomId,
        restroomName: widget.restroom.restroomName,
        photos: widget.restroom.photos,
        initialIndex: index,
      ),
    ));
  }

  void _openWriteReview() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => WriteReviewPage(
        restroomId: widget.restroom.restroomId,
        restroomName: widget.restroom.restroomName,
      ),
    )).then((_) => setState(_loadData));
  }

  // ── Build ────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildTitleBar()),
              SliverToBoxAdapter(child: _buildInfoCards()),
              SliverToBoxAdapter(child: _buildRatingBreakdownCard()),
              SliverToBoxAdapter(child: _buildAmenitiesCard()),
              SliverToBoxAdapter(child: _buildPhotosCard()),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(child: _buildReviewsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header image ─────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Stack(
      children: [
        // Photo / placeholder
        GestureDetector(
          onTap: _openGallery,
          child: Container(
            height: 260,
            width: double.infinity,
            color: _C.teal.withOpacity(0.35),
            child: widget.restroom.photos.isNotEmpty
                ? Image.network(
                    widget.restroom.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.wc_rounded, size: 72, color: _C.tealDark),
                  )
                : const Icon(Icons.wc_rounded, size: 72, color: _C.tealDark),
          ),
        ),

        // Gradient scrim at bottom so title bar feels connected
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [_C.bg, _C.bg.withOpacity(0)],
              ),
            ),
          ),
        ),

        // Back button
        Positioned(
          top: 52, left: 12,
          child: _CircleButton(
            icon: Icons.arrow_back,
            onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          ),
        ),

        // Favourite button
        Positioned(
          top: 52, right: 12,
          child: _CircleButton(
            icon: isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            iconColor: isFavorite ? _C.red : _C.textDark,
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => isFavorite = !isFavorite);
            },
          ),
        ),
      ],
    );
  }

  // ── Title + rating bar ────────────────────────────────────────────────
  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.restroom.restroomName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Rating chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _C.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: _C.orange, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            widget.restroom.avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _C.orange,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${widget.restroom.totalRatings})',
                            style: const TextStyle(fontSize: 11, color: _C.textMid),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Open / closed chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isOpen ? _C.green : _C.red).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isOpen ? 'Open' : 'Closed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isOpen ? _C.green : _C.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Info cards row (Location / Hours / Price) ────────────────────────
  Widget _buildInfoCards() {
    final hours = widget.restroom.is24hrs
        ? '24 Hours'
        : '${widget.restroom.openTime} – ${widget.restroom.closeTime}';
    final price = widget.restroom.isFree
        ? 'Free'
        : widget.restroom.price != null
            ? '${widget.restroom.price} THB'
            : 'Paid';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _SectionCard(
        title: 'Details',
        icon: Icons.info_outline_rounded,
        child: Column(
          children: [
            _InfoRow(icon: Icons.location_on_rounded, iconColor: _C.red,
                label: 'Location', value: widget.restroom.address, sub: distance),
            const _Divider(),
            _InfoRow(icon: Icons.access_time_rounded, iconColor: _C.tealDark,
                label: 'Hours', value: hours,
                sub: isOpen ? 'Currently Open' : 'Currently Closed',
                subColor: isOpen ? _C.green : _C.red),
            const _Divider(),
            _InfoRow(icon: Icons.payments_rounded, iconColor: _C.orange,
                label: 'Price', value: price),
          ],
        ),
      ),
    );
  }

  // ── Rating breakdown card ─────────────────────────────────────────────
  Widget _buildRatingBreakdownCard() {
    final categories = [
      ('Cleanliness',  ratingBreakdown['cleanliness']  ?? 0, Icons.cleaning_services_rounded),
      ('Availability', ratingBreakdown['availability'] ?? 0, Icons.door_front_door_rounded),
      ('Amenities',    ratingBreakdown['amenities']    ?? 0, Icons.chair_rounded),
      ('Smell',        ratingBreakdown['smell']        ?? 0, Icons.air_rounded),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _SectionCard(
        title: 'Rating Breakdown',
        icon: Icons.bar_chart_rounded,
        child: Column(
          children: categories.map((c) {
            final (label, stars, icon) = c;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: _C.teal.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: _C.tealDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _C.textDark)),
                        const SizedBox(height: 4),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: stars / 5,
                            minHeight: 5,
                            backgroundColor: _C.divider,
                            valueColor:
                                const AlwaysStoppedAnimation<Color>(_C.tealDark),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: List.generate(5, (i) => Icon(
                      i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 13,
                      color: i < stars ? _C.orange : _C.textLight,
                    )),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Amenities card ────────────────────────────────────────────────────
  Widget _buildAmenitiesCard() {
    final amenities = widget.restroom.amenities.entries.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _SectionCard(
        title: 'Amenities',
        icon: Icons.check_circle_outline_rounded,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((e) {
            final available = e.value;
            final name = e.key.replaceAllMapped(
              RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}').trim();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: available
                    ? _C.teal.withOpacity(0.2)
                    : _C.fieldFill,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: available ? _C.tealDark.withOpacity(0.35) : _C.divider,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    available ? Icons.check_rounded : Icons.close_rounded,
                    size: 12,
                    color: available ? _C.tealDark : _C.textLight,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: available ? _C.textDark : _C.textLight,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── Photos card ───────────────────────────────────────────────────────
  Widget _buildPhotosCard() {
    final photos = widget.restroom.photos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _SectionCard(
        title: 'Photos (${photos.length})',
        icon: Icons.photo_library_rounded,
        trailing: GestureDetector(
          onTap: _openGallery,
          child: const Text(
            'View All',
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _C.tealDark),
          ),
        ),
        child: photos.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(children: const [
                    Icon(Icons.add_photo_alternate_rounded,
                        size: 36, color: _C.textLight),
                    SizedBox(height: 6),
                    Text('No photos yet',
                        style: TextStyle(fontSize: 12, color: _C.textLight)),
                  ]),
                ),
              )
            : GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: photos.length > 6 ? 6 : photos.length,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                  childAspectRatio: 1,
                ),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _openGallery(index: i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(fit: StackFit.expand, children: [
                      Container(color: _C.teal.withOpacity(0.2),
                          child: const Icon(Icons.photo, color: _C.tealDark)),
                      if (i < photos.length)
                        Image.network(photos[i], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox()),
                      // "more" overlay on last tile
                      if (i == 5 && photos.length > 6)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Text('+${photos.length - 6}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                          ),
                        ),
                    ]),
                  ),
                ),
              ),
      ),
    );
  }

  // ── Action buttons ────────────────────────────────────────────────────
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.navigation_rounded,
            label: 'Direction',
            color: _C.tealDark,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Opening directions to ${widget.restroom.restroomName}'),
                backgroundColor: _C.tealDark,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.rate_review_rounded,
            label: 'Review',
            color: _C.orange,
            onTap: _openWriteReview,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.add_a_photo_rounded,
            label: 'Add Photo',
            color: _C.tealDark,
            onTap: _openGallery,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.flag_rounded,
            label: 'Report',
            color: _C.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ReportIssuePage(
                restroomId: widget.restroom.restroomId,
                restroomName: widget.restroom.restroomName,
              ),
            )),
          ),
        ],
      ),
    );
  }

  // ── Reviews section ───────────────────────────────────────────────────
  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: _SectionCard(
        title: 'Reviews (${widget.restroom.totalRatings})',
        icon: Icons.chat_bubble_outline_rounded,
        trailing: GestureDetector(
          onTap: _openWriteReview,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _C.tealDark,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Add Review',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sort filter chip
            GestureDetector(
              onTap: _showSortSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _C.fieldFill,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _C.divider),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded,
                        size: 15, color: _C.tealDark),
                    const SizedBox(width: 6),
                    Text(selectedFilter,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark)),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: _C.textMid),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...reviews.map((r) => _ReviewCard(
                  review: r,
                  isHelpful: helpfulReviewIds.contains(r.reviewId),
                  onHelpfulTap: () => setState(() {
                    if (helpfulReviewIds.contains(r.reviewId)) {
                      helpfulReviewIds.remove(r.reviewId);
                    } else {
                      helpfulReviewIds.add(r.reviewId);
                      HapticFeedback.lightImpact();
                    }
                  }),
                  onReadMore: () => _showFullReview(r),
                )),
          ],
        ),
      ),
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _C.divider,
                    borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            const Text('Sort Reviews',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark)),
            const SizedBox(height: 12),
            ...filterOptions.map((opt) {
              final sel = selectedFilter == opt;
              return ListTile(
                leading: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: sel
                        ? _C.teal.withOpacity(0.3)
                        : _C.fieldFill,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.sort_rounded,
                      size: 16,
                      color: sel ? _C.tealDark : _C.textLight),
                ),
                title: Text(opt,
                    style: TextStyle(
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: sel ? _C.tealDark : _C.textDark,
                        fontSize: 14)),
                trailing: sel
                    ? const Icon(Icons.check_rounded,
                        color: _C.tealDark, size: 18)
                    : null,
                onTap: () {
                  _sortReviews(opt);
                  Navigator.pop(ctx);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showFullReview(ReviewModel review) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _C.bg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(review.reviewerName,
            style: const TextStyle(
                fontWeight: FontWeight.w800, color: _C.textDark)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _C.orange.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.star_rounded,
                        color: _C.orange, size: 14),
                    const SizedBox(width: 3),
                    Text(review.rating.toStringAsFixed(1),
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.orange)),
                  ]),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: _C.teal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text(ReviewService.getRatingBadge(review.rating),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.tealDark)),
                ),
              ]),
              const SizedBox(height: 12),
              Text(review.comment,
                  style: const TextStyle(
                      fontSize: 14, color: _C.textMid, height: 1.5)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close',
                style: TextStyle(
                    color: _C.tealDark, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Card (reusable — same as profile/add)
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _C.divider),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: _C.teal.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: _C.tealDark),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(color: _C.divider, height: 1, thickness: 1),
          Padding(padding: const EdgeInsets.all(14), child: child),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info Row (inside Details card)
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        color: _C.textLight,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _C.textDark)),
                if (sub != null)
                  Text(sub!,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: subColor ?? _C.textMid)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Thin divider
// ─────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(color: _C.divider, height: 1, thickness: 1);
}

// ─────────────────────────────────────────────
// Action button (Direction / Review / Photo / Report)
// ─────────────────────────────────────────────
class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 200));
    _scale = Tween(begin: 1.0, end: 0.92)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: widget.color.withOpacity(0.3), width: 1.2),
            ),
            child: Column(
              children: [
                Icon(widget.icon, size: 20, color: widget.color),
                const SizedBox(height: 4),
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: widget.color)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Review card
// ─────────────────────────────────────────────
class _ReviewCard extends StatelessWidget {
  final ReviewModel review;
  final bool isHelpful;
  final VoidCallback onHelpfulTap;
  final VoidCallback onReadMore;

  const _ReviewCard({
    required this.review,
    required this.isHelpful,
    required this.onHelpfulTap,
    required this.onReadMore,
  });

  String _timeAgo(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays >= 1) return '${diff.inDays}d ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _C.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              // Avatar
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: _C.teal.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 20, color: _C.tealDark),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.reviewerName,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark)),
                    Text(_timeAgo(review.timestamp),
                        style: const TextStyle(
                            fontSize: 10, color: _C.textLight)),
                  ],
                ),
              ),
              // Rating chip
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: _C.orange.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded,
                      color: _C.orange, size: 12),
                  const SizedBox(width: 2),
                  Text(review.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _C.orange)),
                ]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.25),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(ReviewService.getRatingBadge(review.rating),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.tealDark)),
          ),
          const SizedBox(height: 8),
          // Comment
          Text(review.comment,
              style: const TextStyle(
                  fontSize: 12, color: _C.textMid, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          // Footer
          Row(
            children: [
              // Helpful button
              GestureDetector(
                onTap: onHelpfulTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isHelpful
                        ? _C.teal.withOpacity(0.3)
                        : _C.divider.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isHelpful
                            ? _C.tealDark.withOpacity(0.4)
                            : _C.divider),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isHelpful
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 12,
                      color: isHelpful ? _C.tealDark : _C.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${review.helpfulCount + (isHelpful ? 1 : 0)})',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isHelpful ? _C.tealDark : _C.textLight),
                    ),
                  ]),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onReadMore,
                child: const Text('Read more',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _C.tealDark,
                        decoration: TextDecoration.underline,
                        decorationColor: _C.tealDark)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// White circle button (back / favourite)
// ─────────────────────────────────────────────
class _CircleButton extends StatefulWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const _CircleButton({required this.icon, required this.onTap, this.iconColor});

  @override
  State<_CircleButton> createState() => _CircleButtonState();
}

class _CircleButtonState extends State<_CircleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 80),
        reverseDuration: const Duration(milliseconds: 220));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: Icon(widget.icon,
              size: 22, color: widget.iconColor ?? _C.textDark),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/restroom_model.dart';
import '../../models/review_model.dart';
import '../../services/restroom_firestore.dart';
import '../../services/review_firestore.dart';
import '../../services/user_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_ui.dart';
import '../../services/location_service.dart';
import '../../widgets/spring_button.dart';
import '../../widgets/section_card.dart';
import '../../widgets/chips.dart';
import '../../widgets/rating_widgets.dart';
import '../../widgets/photo_source_button.dart';
import '../../widgets/review_card.dart';
import 'photo_gallery_page.dart';
import 'report_issue_page.dart';
import 'write_review_page.dart';
import 'navigation_page.dart';

class RestroomDetailPage extends StatefulWidget {
  final RestroomModel restroom;
  const RestroomDetailPage({Key? key, required this.restroom})
      : super(key: key);

  @override
  State<RestroomDetailPage> createState() => _RestroomDetailPageState();
}

class _RestroomDetailPageState extends State<RestroomDetailPage>
    with SingleTickerProviderStateMixin {
  bool isFavorite = false;
  bool isAdmin = false;
  final _userService = UserService();
  List<ReviewModel> reviews = [];
  Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  bool isOpen = true;
  String distance = '...';
  String selectedFilter = 'Recent';
  final Set<String> helpfulReviewIds = {};
  bool _isUploadingPhoto = false;
  late RestroomModel _restroom;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;

  static const List<String> _filterOptions = [
    'Recent',
    'Highest Rating',
    'Lowest Rating',
    'Most Helpful',
  ];

  // ── Lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _restroom = widget.restroom;
    _loadFavoriteState();
    _checkAdminStatus();
    _loadData();
    _logSearchEvent();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnim =
        CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────

  Future<void> _loadFavoriteState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await _userService.getUserById(uid);
    if (user != null && mounted) {
      setState(() {
        isFavorite =
            user.favoriteRestrooms.contains(widget.restroom.restroomId);
      });
    }
  }

  Future<void> _checkAdminStatus() async {
    final isUserAdmin = await _userService.isAdmin();
    if (mounted) setState(() => isAdmin = isUserAdmin);
  }

  Future<void> _logSearchEvent() async {
    try {
      final address = widget.restroom.address;
      final parts = address.split(',').map((s) => s.trim()).toList();
      final area = parts.length > 1 ? parts[1] : parts.first;
      if (area.isEmpty) return;
      await FirebaseFirestore.instance.collection('search_logs').add({
        'restroomId': widget.restroom.restroomId,
        'restroomName': widget.restroom.restroomName,
        'area': area,
        'searchedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  void _loadData() async {
    isOpen = RestroomService().checkIfOpen(widget.restroom);

    final position = await LocationService.getCurrentPosition();
    if (position != null && mounted) {
      setState(() {
        distance = RestroomService().getDistance(
          position.latitude, position.longitude,
          widget.restroom.latitude, widget.restroom.longitude,
        );
      });
    }

    FirebaseFirestore.instance
        .collection('restrooms')
        .doc(widget.restroom.restroomId)
        .snapshots()
        .listen((snap) {
      if (mounted && snap.exists) {
        setState(() {
          _restroom = RestroomModel.fromMap(
            snap.data() as Map<String, dynamic>,
            snap.id,
          );
        });
      }
    });

    ReviewService()
        .getReviewsByRestroomId(widget.restroom.restroomId)
        .listen((data) {
      if (mounted) {
        setState(() {
          reviews = data;
          starDistribution = _calculateStarDistribution(data);
          _sortReviews(selectedFilter);
        });
      }
    });
  }

  // ── Business logic ────────────────────────────────────────────

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    final newVal = !isFavorite;
    setState(() => isFavorite = newVal);
    if (newVal) {
      await _userService.addFavoriteRestroom(widget.restroom.restroomId);
    } else {
      await _userService
          .removeFavoriteRestroom(widget.restroom.restroomId);
    }
  }

  Map<int, int> _calculateStarDistribution(
      List<ReviewModel> currentReviews) {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in currentReviews) {
      final star = r.rating.round().clamp(1, 5);
      dist[star] = (dist[star] ?? 0) + 1;
    }
    return dist;
  }

  void _sortReviews(String filter) {
    setState(() {
      selectedFilter = filter;
      switch (filter) {
        case 'Recent':
          reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          break;
        case 'Highest Rating':
          reviews.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Lowest Rating':
          reviews.sort((a, b) => a.rating.compareTo(b.rating));
          break;
        case 'Most Helpful':
          reviews
              .sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
          break;
      }
    });
  }

  Future<void> _handleDeleteReview(ReviewModel review) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Review?'),
        content: const Text(
            'Are you sure you want to delete this review? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ReviewService().deleteReview(review);
        if (mounted) {
          AppUI.showSnackBar(context, 'Review deleted successfully');
        }
      } catch (e) {
        if (mounted) {
          AppUI.showSnackBar(context, 'Failed to delete review: $e',
              isError: true);
        }
      }
    }
  }

  Future<void> _pickAndUploadPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final file = File(picked.path);
      final fileName =
          'restrooms/${_restroom.restroomId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child(fileName);
      final uploadTask = await storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final downloadUrl = await uploadTask.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('restrooms')
          .doc(_restroom.restroomId)
          .update({
        'photos': FieldValue.arrayUnion([downloadUrl]),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      if (mounted) {
        setState(() => _restroom.photos.add(downloadUrl));
        AppUI.showSnackBar(context, 'Photo uploaded successfully!',
            icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        AppUI.showSnackBar(context, 'Upload failed: ${e.toString()}',
            isError: true, icon: Icons.error_rounded);
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Navigation helpers ────────────────────────────────────────

  void _openGallery({int index = 0}) {
    if (_restroom.photos.isEmpty) return;
    Navigator.push(
      context,
      AppUI.smoothRoute(
        PhotoGalleryPage(
          restroomId: _restroom.restroomId,
          restroomName: _restroom.restroomName,
          photos: _restroom.photos,
          initialIndex: index,
        ),
      ),
    );
  }

  void _openWriteReview() {
    Navigator.push(
      context,
      AppUI.smoothRoute(
        WriteReviewPage(
          restroomId: _restroom.restroomId,
          restroomName: _restroom.restroomName,
        ),
      ),
    ).then((_) => _loadData());
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: CustomScrollView(
            physics: const ClampingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildTitleBar()),
              SliverToBoxAdapter(child: _buildInfoCard()),
              SliverToBoxAdapter(child: _buildRatingBreakdownCard()),
              SliverToBoxAdapter(child: _buildCategoryRatingsCard()),
              SliverToBoxAdapter(child: _buildAmenitiesCard()),
              SliverToBoxAdapter(child: _buildPhotosCard()),
              SliverToBoxAdapter(child: _buildActionButtons()),
              SliverToBoxAdapter(
                  child: _buildReviewsSection(currentUserId)),
              const SliverToBoxAdapter(child: SizedBox(height: 40)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section builders ──────────────────────────────────────────

  Widget _buildHeader() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _openGallery,
          child: Container(
            height: 260,
            width: double.infinity,
            color: AppColors.pinkLight.withOpacity(0.5),
            child: widget.restroom.photos.isNotEmpty
                ? Image.network(
                    widget.restroom.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.wc_rounded,
                      size: 72,
                      color: AppColors.pink,
                    ),
                  )
                : const Icon(
                    Icons.wc_rounded,
                    size: 72,
                    color: AppColors.pink,
                  ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [AppColors.bg, AppColors.bg.withOpacity(0)],
              ),
            ),
          ),
        ),
        Positioned(
          top: 52,
          left: 12,
          child: AppBackButton(),
        ),
        Positioned(
          top: 52,
          right: 12,
          child: _FavouriteButton(
              isFavorite: isFavorite, onTap: _toggleFavorite),
        ),
      ],
    );
  }

  Widget _buildTitleBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _restroom.restroomName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _RatingPill(rating: _restroom.avgRating,
                  total: _restroom.totalRatings),
              const SizedBox(width: 8),
              StatusBadge(isOpen: isOpen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final hours = _restroom.is24hrs
        ? '24 Hours'
        : '${_restroom.openTime} – ${_restroom.closeTime}';
    final price = _restroom.isFree
        ? 'Free'
        : _restroom.price != null
            ? '${_restroom.price} THB'
            : 'Paid';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SectionCard(
        title: 'Details',
        icon: Icons.info_outline_rounded,
        child: Column(
          children: [
            _InfoRow(
              icon: Icons.location_on_rounded,
              iconColor: AppColors.pink,
              label: 'Location',
              value: widget.restroom.address,
              sub: distance,
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.access_time_rounded,
              iconColor: AppColors.mint,
              label: 'Hours',
              value: hours,
              sub: isOpen ? 'Currently Open' : 'Currently Closed',
              subColor: isOpen ? AppColors.green : AppColors.red,
            ),
            const _RowDivider(),
            _InfoRow(
              icon: Icons.payments_rounded,
              iconColor: AppColors.orangeAlt,
              label: 'Price',
              value: price,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBreakdownCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SectionCard(
        title: 'Rating Breakdown',
        icon: Icons.bar_chart_rounded,
        child: RatingBreakdown(
          avgRating: _restroom.avgRating,
          totalReviews: reviews.length,
          starDistribution: starDistribution,
        ),
      ),
    );
  }

  Widget _buildCategoryRatingsCard() {
    if (_restroom.totalRatings == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SectionCard(
        title: 'Category Ratings',
        icon: Icons.category_rounded,
        child: Column(
          children: [
            CategoryRatingRow(
              label: 'Cleanliness',
              score: _restroom.avgCleanliness,
              icon: Icons.cleaning_services_rounded,
              color: AppColors.mint,
            ),
            const SizedBox(height: 12),
            CategoryRatingRow(
              label: 'Availability',
              score: _restroom.avgAvailability,
              icon: Icons.door_front_door_rounded,
              color: AppColors.pink,
            ),
            const SizedBox(height: 12),
            CategoryRatingRow(
              label: 'Amenities',
              score: _restroom.avgAmenities,
              icon: Icons.chair_rounded,
              color: AppColors.orangeAlt,
            ),
            const SizedBox(height: 12),
            CategoryRatingRow(
              label: 'Scent',
              score: _restroom.avgScent,
              icon: Icons.air_rounded,
              color: AppColors.mintDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    final amenities = _restroom.amenities.entries.toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SectionCard(
        title: 'Amenities',
        icon: Icons.check_circle_outline_rounded,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((e) {
            final available = e.value;
            final name = e.key
                .replaceAllMapped(
                    RegExp(r'([A-Z])'), (m) => ' ${m.group(0)}')
                .trim();
            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                gradient: available
                    ? LinearGradient(
                        colors: [
                          AppColors.pinkLight,
                          AppColors.pink.withOpacity(0.15),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: available ? null : AppColors.fieldFill,
                borderRadius: BorderRadius.circular(12),
                boxShadow: available
                    ? [
                        BoxShadow(
                          color: AppColors.pink.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    available
                        ? Icons.check_rounded
                        : Icons.close_rounded,
                    size: 12,
                    color: available
                        ? AppColors.pink
                        : AppColors.textLight,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: available
                          ? AppColors.textDark
                          : AppColors.textLight,
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

  Widget _buildPhotosCard() {
    final photos = _restroom.photos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: SectionCard(
        title: 'Photos (${photos.length})',
        icon: Icons.photo_library_rounded,
        trailing: GestureDetector(
          onTap: _openGallery,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.mint.withOpacity(0.22),
                  AppColors.mint.withOpacity(0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.mint,
              ),
            ),
          ),
        ),
        child: photos.isEmpty
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.add_photo_alternate_rounded,
                          size: 36, color: AppColors.textLight),
                      SizedBox(height: 6),
                      Text(
                        'No photos yet',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textLight),
                      ),
                    ],
                  ),
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
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          color: AppColors.pinkLight.withOpacity(0.4),
                          child: const Icon(Icons.photo,
                              color: AppColors.pink),
                        ),
                        if (i < photos.length)
                          Image.network(
                            photos[i],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox(),
                          ),
                        if (i == 5 && photos.length > 6)
                          Container(
                            color: Colors.black54,
                            child: Center(
                              child: Text(
                                '+${photos.length - 6}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.navigation_rounded,
            label: 'Direction',
            color: AppColors.mint,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                AppUI.smoothRoute(NavigationPage(restroom: _restroom)),
              );
            },
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.rate_review_rounded,
            label: 'Review',
            color: AppColors.pink,
            onTap: _openWriteReview,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: _isUploadingPhoto
                ? Icons.hourglass_top_rounded
                : Icons.add_a_photo_rounded,
            label: _isUploadingPhoto ? 'Uploading...' : 'Add Photo',
            color: AppColors.orangeAlt,
            onTap: _isUploadingPhoto
                ? () {}
                : () => showPhotoSourceSheet(
                      context,
                      onCamera: () =>
                          _pickAndUploadPhoto(ImageSource.camera),
                      onGallery: () =>
                          _pickAndUploadPhoto(ImageSource.gallery),
                    ),
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.flag_rounded,
            label: 'Report',
            color: AppColors.red,
            onTap: () => Navigator.push(
              context,
              AppUI.smoothRoute(
                ReportIssuePage(
                  restroomId: _restroom.restroomId,
                  restroomName: _restroom.restroomName,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection(String? currentUserId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: SectionCard(
        title: 'Reviews (${_restroom.totalRatings})',
        icon: Icons.chat_bubble_outline_rounded,
        trailing: GestureDetector(
          onTap: _openWriteReview,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.mint, AppColors.mintDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.mint.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Text(
              'Add Review',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GestureDetector(
              onTap: _showSortSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.fieldFill,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.sort_rounded,
                        size: 15, color: AppColors.mint),
                    const SizedBox(width: 6),
                    Text(
                      selectedFilter,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.keyboard_arrow_down_rounded,
                        size: 16, color: AppColors.textMid),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ...reviews.map(
              (r) => ReviewCard(
                review: r,
                isOwnerOrAdmin:
                    currentUserId == r.reviewerId || isAdmin,
                isHelpful: helpfulReviewIds.contains(r.reviewId),
                onHelpfulTap: () => setState(() {
                  if (helpfulReviewIds.contains(r.reviewId)) {
                    helpfulReviewIds.remove(r.reviewId);
                  } else {
                    helpfulReviewIds.add(r.reviewId);
                    HapticFeedback.lightImpact();
                  }
                }),
                onDeleteTap: () => _handleDeleteReview(r),
                onReadMore: () => _showFullReview(r),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom sheets & dialogs ───────────────────────────────────

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sort Reviews',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 12),
            ..._filterOptions.map((opt) {
              final sel = selectedFilter == opt;
              return ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(
                            colors: [
                              AppColors.pinkLight,
                              AppColors.pink.withOpacity(0.2),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: sel ? null : AppColors.fieldFill,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: AppColors.pink.withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.sort_rounded,
                    size: 16,
                    color: sel ? AppColors.pink : AppColors.textLight,
                  ),
                ),
                title: Text(
                  opt,
                  style: TextStyle(
                    fontWeight:
                        sel ? FontWeight.w700 : FontWeight.w500,
                    color:
                        sel ? AppColors.pink : AppColors.textDark,
                    fontSize: 14,
                  ),
                ),
                trailing: sel
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.pink, size: 18)
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
        backgroundColor: AppColors.bg,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: Text(
          review.reviewerName,
          style: const TextStyle(
              fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _RatingPill(rating: review.rating),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.pinkLight,
                          AppColors.pink.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      ReviewService().getRatingBadge(review.rating),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                review.comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMid,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(
                  color: AppColors.mint, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Local private widgets (page-specific, not worth sharing) ────────────────

class _RatingPill extends StatelessWidget {
  final double rating;
  final int? total;
  const _RatingPill({required this.rating, this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.orangeAlt.withOpacity(0.22),
            AppColors.orangeAlt.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: AppColors.orangeAlt.withOpacity(0.2),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              color: AppColors.orangeAlt, size: 14),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.orangeAlt,
            ),
          ),
          if (total != null) ...[
            const SizedBox(width: 3),
            Text(
              '($total)',
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textMid),
            ),
          ],
        ],
      ),
    );
  }
}

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
            width: 34,
            height: 34,
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
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textLight,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                if (sub != null)
                  Text(
                    sub!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: subColor ?? AppColors.textMid,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RowDivider extends StatelessWidget {
  const _RowDivider();
  @override
  Widget build(BuildContext context) =>
      Divider(color: AppColors.divider, height: 1, thickness: 1);
}

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
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.92).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: AnimatedBuilder(
          animation: _scale,
          builder: (_, child) =>
              Transform.scale(scale: _scale.value, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.color.withOpacity(0.18),
                  widget.color.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Icon(widget.icon, size: 22, color: widget.color),
                const SizedBox(height: 6),
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: widget.color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatefulWidget {
  final bool isFavorite;
  final Future<void> Function() onTap;
  const _FavouriteButton(
      {required this.isFavorite, required this.onTap});

  @override
  State<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<_FavouriteButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _burstAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.35, end: 0.90)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.90, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_ctrl);
    _burstAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap();
    _ctrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) => SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (_ctrl.isAnimating)
                Opacity(
                  opacity: (1 - _burstAnim.value).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 0.6 + _burstAnim.value * 0.8,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.isFavorite
                              ? AppColors.red.withOpacity(0.5)
                              : AppColors.textLight.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: widget.isFavorite
                      ? AppColors.red.withOpacity(0.12)
                      : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
              Transform.scale(
                scale: _scaleAnim.value,
                child: Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 24,
                  color: widget.isFavorite
                      ? AppColors.red
                      : AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

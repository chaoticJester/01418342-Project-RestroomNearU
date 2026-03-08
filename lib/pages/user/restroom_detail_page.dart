import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/restroom_model.dart';
import '../../models/review_model.dart';
import '../../services/restroom_firestore.dart';
import '../../services/review_firestore.dart';
import 'photo_gallery_page.dart';
import 'report_issue_page.dart';
import 'write_review_page.dart';
import 'navigation_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/user_firestore.dart';

// ─────────────────────────────────────────────
// Design tokens - Figma inspired theme
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF5F1E8);  // Warm cream background
  static const card      = Color(0xFFFFFDFA);  // Lighter card surface
  static const pink      = Color(0xFFEC9B9B);  // Soft pink accent
  static const pinkLight = Color(0xFFF5D4D4);  // Light pink for backgrounds
  static const mint      = Color(0xFFA8D5D5);  // Mint/teal accent
  static const mintDark  = Color(0xFF88B5B5);  // Darker mint
  static const orange    = Color(0xFFF5A162);  // Warm orange
  static const green     = Color(0xFF7CB87C);  // Soft green
  static const red       = Color(0xFFD77A7A);  // Soft red
  static const textDark  = Color(0xFF2C2C2C);  // Near black
  static const textMid   = Color(0xFF6B6B6B);  // Medium gray
  static const textLight = Color(0xFFA5A5A5);  // Light gray
  static const divider   = Color(0xFFE8E4DB);  // Soft divider
  static const fieldFill = Color(0xFFFFFBF5);  // Input field background
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
  final _userService = UserService();
  List<ReviewModel> reviews = [];
  Map<int, int> starDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  bool isOpen = true;
  String distance = "...";
  String selectedFilter = 'Recent';
  final Set<String> helpfulReviewIds = {};
  bool _isUploadingPhoto = false;

  late RestroomModel _restroom;

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
    _restroom = widget.restroom;
    _loadFavoriteState();
    _loadData();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  }

  Future<void> _loadFavoriteState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await _userService.getUserById(uid);
    if (user != null && mounted) {
      setState(() {
        isFavorite = user.favoriteRestrooms.contains(widget.restroom.restroomId);
      });
    }
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    final newVal = !isFavorite;
    setState(() => isFavorite = newVal);
    if (newVal) {
      await _userService.addFavoriteRestroom(widget.restroom.restroomId);
    } else {
      await _userService.removeFavoriteRestroom(widget.restroom.restroomId);
    }
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  void _loadData() async {
    isOpen = RestroomService().checkIfOpen(widget.restroom);

    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        )
      );

      double userLat = position.latitude;
      double userLng = position.longitude;
      if (mounted) {
        setState(() {
          distance = RestroomService().getDistance(userLat, userLng, widget.restroom.latitude, widget.restroom.longitude);
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }

    FirebaseFirestore.instance
        .collection('restrooms')
        .doc(widget.restroom.restroomId)
        .snapshots()
        .listen((snap) {
      if (mounted && snap.exists) {
        setState(() {
          _restroom = RestroomModel.fromMap(
              snap.data() as Map<String, dynamic>, snap.id);
        });
      }
    });

    ReviewService().getReviewsByRestroomId(widget.restroom.restroomId).listen((data) {
      if (mounted) {
        setState(() {
          reviews = data;
          starDistribution = _calculateStarDistribution(data);
          _sortReviews(selectedFilter);
        });
      }
    });
  }

  Map<int, int> _calculateStarDistribution(List<ReviewModel> currentReviews) {
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

  void _openGallery({int index = 0}) {
    if (_restroom.photos.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => PhotoGalleryPage(
        restroomId: _restroom.restroomId,
        restroomName: _restroom.restroomName,
        photos: _restroom.photos,
        initialIndex: index,
      ),
    ));
  }

  void _openWriteReview() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => WriteReviewPage(
        restroomId: _restroom.restroomId,
        restroomName: _restroom.restroomName,
      ),
    )).then((_) => _loadData());
  }

  void _showAddPhotoSheet() {
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
            const Text('Add Photo',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark)),
            const SizedBox(height: 4),
            const Text('Share a photo of this restroom',
                style: TextStyle(fontSize: 12, color: _C.textMid)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoSourceButton(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: _C.mint,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.camera);
                  },
                ),
                _PhotoSourceButton(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: _C.orange,
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAndUploadPhoto(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
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
      final fileName = 'restrooms/${_restroom.restroomId}/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);

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
        setState(() {
          _restroom.photos.add(downloadUrl);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Photo uploaded successfully!'),
            ]),
            backgroundColor: _C.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.error_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Expanded(child: Text('Upload failed: ${e.toString()}')),
            ]),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

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
              SliverToBoxAdapter(child: _buildCategoryRatingsCard()), // Added
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

  Widget _buildHeader() {
    return Stack(
      children: [
        GestureDetector(
          onTap: _openGallery,
          child: Container(
            height: 260,
            width: double.infinity,
            color: _C.pinkLight.withOpacity(0.5),
            child: widget.restroom.photos.isNotEmpty
                ? Image.network(
                    widget.restroom.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.wc_rounded, size: 72, color: _C.pink),
                  )
                : const Icon(Icons.wc_rounded, size: 72, color: _C.pink),
          ),
        ),
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
        Positioned(
          top: 52, left: 12,
          child: _CircleButton(
            icon: Icons.arrow_back,
            onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          ),
        ),
        Positioned(
          top: 52, right: 12,
          child: _FavouriteButton(
            isFavorite: isFavorite,
            onTap: _toggleFavorite,
          ),
        ),
      ],
    );
  }

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
                  _restroom.restroomName,
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _C.orange.withOpacity(0.22),
                            _C.orange.withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: _C.orange.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: _C.orange, size: 14),
                          const SizedBox(width: 3),
                          Text(
                            _restroom.avgRating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _C.orange,
                            ),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            '(${_restroom.totalRatings})',
                            style: const TextStyle(fontSize: 11, color: _C.textMid),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            (isOpen ? _C.green : _C.red).withOpacity(0.22),
                            (isOpen ? _C.green : _C.red).withOpacity(0.1),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (isOpen ? _C.green : _C.red).withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
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

  Widget _buildInfoCards() {
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
      child: _SectionCard(
        title: 'Details',
        icon: Icons.info_outline_rounded,
        child: Column(
          children: [
            _InfoRow(icon: Icons.location_on_rounded, iconColor: _C.pink,
                label: 'Location', value: widget.restroom.address, sub: distance),
            const _Divider(),
            _InfoRow(icon: Icons.access_time_rounded, iconColor: _C.mint,
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

  Widget _buildRatingBreakdownCard() {
    final total = reviews.length;
    final avg   = _restroom.avgRating;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _SectionCard(
        title: 'Rating Breakdown',
        icon: Icons.bar_chart_rounded,
        child: total == 0
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: Column(children: const [
                    Icon(Icons.star_border_rounded, size: 32, color: _C.textLight),
                    SizedBox(height: 6),
                    Text('No ratings yet',
                        style: TextStyle(fontSize: 12, color: _C.textLight)),
                  ]),
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        avg.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (i) {
                          if (i < avg.floor()) {
                            return const Icon(Icons.star_rounded, size: 14, color: _C.orange);
                          } else if (i < avg && (avg - avg.floor()) >= 0.5) {
                            return const Icon(Icons.star_half_rounded, size: 14, color: _C.orange);
                          } else {
                            return const Icon(Icons.star_outline_rounded, size: 14, color: _C.textLight);
                          }
                        }),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$total review${total == 1 ? '' : 's'}',
                        style: const TextStyle(fontSize: 10, color: _C.textLight),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 90, color: _C.divider),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: [5, 4, 3, 2, 1].map((star) {
                        final count = starDistribution[star] ?? 0;
                        final fraction = total > 0 ? count / total : 0.0;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Text('$star',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: _C.textMid)),
                              const SizedBox(width: 4),
                              const Icon(Icons.star_rounded, size: 11, color: _C.orange),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(99),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 7,
                                    backgroundColor: _C.divider,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      star >= 4 ? _C.mint
                                          : star == 3 ? _C.orange
                                          : _C.pink,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              SizedBox(
                                width: 24,
                                child: Text('$count',
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                        fontSize: 10, color: _C.textLight)),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── Category ratings card (New!) ─────────────────────────────────────
  Widget _buildCategoryRatingsCard() {
    if (_restroom.totalRatings == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _SectionCard(
        title: 'Category Ratings',
        icon: Icons.category_rounded,
        child: Column(
          children: [
            _CategoryRatingRow(
              label: 'Cleanliness',
              score: _restroom.avgCleanliness,
              icon: Icons.cleaning_services_rounded,
              color: _C.mint,
            ),
            const SizedBox(height: 12),
            _CategoryRatingRow(
              label: 'Availability',
              score: _restroom.avgAvailability,
              icon: Icons.door_front_door_rounded,
              color: _C.pink,
            ),
            const SizedBox(height: 12),
            _CategoryRatingRow(
              label: 'Amenities',
              score: _restroom.avgAmenities,
              icon: Icons.chair_rounded,
              color: _C.orange,
            ),
            const SizedBox(height: 12),
            _CategoryRatingRow(
              label: 'Scent',
              score: _restroom.avgScent,
              icon: Icons.air_rounded,
              color: _C.mintDark,
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
                gradient: available
                    ? LinearGradient(
                        colors: [_C.pinkLight, _C.pink.withOpacity(0.15)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: available ? null : _C.fieldFill,
                borderRadius: BorderRadius.circular(12),
                boxShadow: available
                    ? [
                        BoxShadow(
                          color: _C.pink.withOpacity(0.15),
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
                    available ? Icons.check_rounded : Icons.close_rounded,
                    size: 12,
                    color: available ? _C.pink : _C.textLight,
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

  Widget _buildPhotosCard() {
    final photos = _restroom.photos;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: _SectionCard(
        title: 'Photos (${photos.length})',
        icon: Icons.photo_library_rounded,
        trailing: GestureDetector(
          onTap: _openGallery,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.mint.withOpacity(0.22), _C.mint.withOpacity(0.08)],
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
                  color: _C.mint),
            ),
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
                      Container(color: _C.pinkLight.withOpacity(0.4),
                          child: const Icon(Icons.photo, color: _C.pink)),
                      if (i < photos.length)
                        Image.network(photos[i], fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox()),
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

  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Row(
        children: [
          _ActionBtn(
            icon: Icons.navigation_rounded,
            label: 'Direction',
            color: _C.mint,
            onTap: () {
              HapticFeedback.mediumImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NavigationPage(restroom: _restroom),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.rate_review_rounded,
            label: 'Review',
            color: _C.pink,
            onTap: _openWriteReview,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: _isUploadingPhoto ? Icons.hourglass_top_rounded : Icons.add_a_photo_rounded,
            label: _isUploadingPhoto ? 'Uploading...' : 'Add Photo',
            color: _C.orange,
            onTap: _isUploadingPhoto ? () {} : _showAddPhotoSheet,
          ),
          const SizedBox(width: 10),
          _ActionBtn(
            icon: Icons.flag_rounded,
            label: 'Report',
            color: _C.red,
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ReportIssuePage(
                restroomId: _restroom.restroomId,
                restroomName: _restroom.restroomName,
              ),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: _SectionCard(
        title: 'Reviews (${_restroom.totalRatings})',
        icon: Icons.chat_bubble_outline_rounded,
        trailing: GestureDetector(
          onTap: _openWriteReview,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.mint, _C.mintDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _C.mint.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
            GestureDetector(
              onTap: _showSortSheet,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _C.fieldFill,
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
                        size: 15, color: _C.mint),
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
                  width: 34, height: 34,
                  decoration: BoxDecoration(
                    gradient: sel
                        ? LinearGradient(
                            colors: [_C.pinkLight, _C.pink.withOpacity(0.2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: sel ? null : _C.fieldFill,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: sel
                        ? [
                            BoxShadow(
                              color: _C.pink.withOpacity(0.18),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(Icons.sort_rounded,
                      size: 16,
                      color: sel ? _C.pink : _C.textLight),
                ),
                title: Text(opt,
                    style: TextStyle(
                        fontWeight: sel
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: sel ? _C.pink : _C.textDark,
                        fontSize: 14)),
                trailing: sel
                    ? const Icon(Icons.check_rounded,
                        color: _C.pink, size: 18)
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _C.orange.withOpacity(0.22),
                          _C.orange.withOpacity(0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _C.orange.withOpacity(0.18),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]),
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
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_C.pinkLight, _C.pink.withOpacity(0.2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: _C.pink.withOpacity(0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ]),
                  child: Text(ReviewService().getRatingBadge(review.rating),
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _C.pink)),
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
                    color: _C.mint, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Category Rating Row Widget
// ─────────────────────────────────────────────
class _CategoryRatingRow extends StatelessWidget {
  final String label;
  final double score;
  final IconData icon;
  final Color color;

  const _CategoryRatingRow({
    required this.label,
    required this.score,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 15, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _C.textDark,
                ),
              ),
            ),
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            const Text('/5.0', style: TextStyle(fontSize: 10, color: _C.textLight)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: score / 5.0,
            minHeight: 6,
            backgroundColor: _C.divider.withOpacity(0.5),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4)),
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
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_C.pinkLight, _C.pink.withOpacity(0.25)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 16, color: _C.pink),
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

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      Divider(color: _C.divider, height: 1, thickness: 1);
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
                Text(widget.label,
                    style: TextStyle(
                        fontSize: 11,
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.fieldFill,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_C.pinkLight, _C.pink.withOpacity(0.3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    size: 20, color: _C.pink),
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
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _C.orange.withOpacity(0.18),
                      _C.orange.withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.pinkLight, _C.pink.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(ReviewService().getRatingBadge(review.rating),
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _C.pink)),
          ),
          const SizedBox(height: 8),
          Text(review.comment,
              style: const TextStyle(
                  fontSize: 12, color: _C.textMid, height: 1.5),
              maxLines: 3,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          Row(
            children: [
              GestureDetector(
                onTap: onHelpfulTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: isHelpful
                        ? LinearGradient(
                            colors: [_C.pinkLight, _C.pink.withOpacity(0.2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isHelpful ? null : _C.divider.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      isHelpful
                          ? Icons.thumb_up_rounded
                          : Icons.thumb_up_outlined,
                      size: 12,
                      color: isHelpful ? _C.pink : _C.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Helpful (${review.helpfulCount + (isHelpful ? 1 : 0)})',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: isHelpful ? _C.pink : _C.textLight),
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
                        color: _C.mint,
                        decoration: TextDecoration.underline,
                        decorationColor: _C.mint)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoSourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _PhotoSourceButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.25), color.withOpacity(0.12)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 10),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
      ),
    );
  }
}

class _FavouriteButton extends StatefulWidget {
  final bool isFavorite;
  final Future<void> Function() onTap;
  const _FavouriteButton({required this.isFavorite, required this.onTap});

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
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35)
          .chain(CurveTween(curve: Curves.easeOut)), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.90)
          .chain(CurveTween(curve: Curves.easeIn)), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.0)
          .chain(CurveTween(curve: Curves.elasticOut)), weight: 30),
    ]).animate(_ctrl);
    _burstAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

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
        builder: (_, __) {
          return SizedBox(
            width: 56, height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_ctrl.isAnimating)
                  Opacity(
                    opacity: (1 - _burstAnim.value).clamp(0.0, 1.0),
                    child: Transform.scale(
                      scale: 0.6 + _burstAnim.value * 0.8,
                      child: Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isFavorite
                                ? _C.red.withOpacity(0.5)
                                : _C.textLight.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: widget.isFavorite
                        ? _C.red.withOpacity(0.12)
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
                    color: widget.isFavorite ? _C.red : _C.textDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

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

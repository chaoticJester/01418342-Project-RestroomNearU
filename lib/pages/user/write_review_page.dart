import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:restroom_near_u/services/review_firestore.dart';
import 'package:restroom_near_u/services/user_firestore.dart';
import 'package:restroom_near_u/models/review_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_ui.dart';
import '../../widgets/spring_button.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/photo_source_button.dart';

class WriteReviewPage extends StatefulWidget {
  final String restroomId;
  final String restroomName;

  const WriteReviewPage({
    Key? key,
    required this.restroomId,
    required this.restroomName,
  }) : super(key: key);

  @override
  State<WriteReviewPage> createState() => _WriteReviewPageState();
}

class _WriteReviewPageState extends State<WriteReviewPage>
    with SingleTickerProviderStateMixin {
  double cleanlinessRating  = 0;
  double availabilityRating = 0;
  double amenitiesRating    = 0;
  double smellRating        = 0;

  double get overallRating {
    final ratings = [cleanlinessRating, availabilityRating, amenitiesRating, smellRating]
        .where((r) => r > 0)
        .toList();
    if (ratings.isEmpty) return 0;
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }

  final Map<String, bool> amenitiesFound = {
    'Has Toilet Paper':      false,
    'Has Soap':              false,
    'Has Paper Towels':      false,
    'Clean':                 false,
    'Has Warm Water':        false,
    'Wheelchair Accessible': false,
  };

  final TextEditingController _commentController = TextEditingController();
  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool isSubmitting = false;

  late AnimationController _enterCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // ── Photo helpers ─────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 10) {
      AppUI.showSnackBar(context, 'Maximum 10 photos allowed', isError: true);
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedPhotos.add(File(image.path)));
  }

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= 10) {
      AppUI.showSnackBar(context, 'Maximum 10 photos allowed', isError: true);
      return;
    }
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) setState(() => _selectedPhotos.add(File(photo.path)));
  }

  void _removePhoto(int index) => setState(() => _selectedPhotos.removeAt(index));

  Future<List<String>> _uploadPhotos(String reviewId) async {
    final urls = <String>[];
    for (final file in _selectedPhotos) {
      final fileName =
          'reviews/$reviewId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref  = FirebaseStorage.instance.ref().child(fileName);
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitReview() async {
    if (cleanlinessRating == 0 && availabilityRating == 0 &&
        amenitiesRating == 0 && smellRating == 0) {
      AppUI.showSnackBar(context, 'Please rate at least one category', isError: true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => isSubmitting = true);

    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        AppUI.showSnackBar(context, 'You must be logged in to submit a review',
            isError: true);
        setState(() => isSubmitting = false);
        return;
      }

      final userModel = await UserService().getUserById(firebaseUser.uid);
      final reviewRef = FirebaseFirestore.instance.collection('reviews').doc();
      final tempId    = reviewRef.id;

      List<String> uploadedUrls = [];
      if (_selectedPhotos.isNotEmpty) uploadedUrls = await _uploadPhotos(tempId);

      final review = ReviewModel(
        reviewId:          tempId,
        restroomId:        widget.restroomId,
        reviewerId:        firebaseUser.uid,
        reviewerName:      userModel?.displayName ?? firebaseUser.displayName ?? 'Anonymous',
        reviewerPhotoUrl:  firebaseUser.photoURL ?? '',
        rating:            overallRating,
        cleanlinessRating: cleanlinessRating,
        availabilityRating: availabilityRating,
        amenitiesRating:   amenitiesRating,
        smellRating:       smellRating,
        amenitiesFound:    amenitiesFound,
        comment:           _commentController.text.trim(),
        photos:            uploadedUrls,
      );

      await ReviewService().addReviewWithRatingUpdate(review);

      if (!mounted) return;
      setState(() => isSubmitting = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: AppColors.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  color: AppColors.greenAlt.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: AppColors.greenAlt, size: 42),
              ),
              const SizedBox(height: 16),
              const Text('Review Submitted',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: AppColors.textDark)),
              const SizedBox(height: 8),
              const Text('Thank you for sharing your experience!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: AppColors.textMid)),
              const SizedBox(height: 20),
              SpringButton(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.mintLight, AppColors.tealDark],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [BoxShadow(
                        color: AppColors.tealDark.withOpacity(0.3),
                        blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Center(
                    child: Text('Done',
                        style: TextStyle(fontSize: 15,
                            fontWeight: FontWeight.w700, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isSubmitting = false);
      AppUI.showSnackBar(context, 'Failed to submit review. Please try again.',
          isError: true);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeroHeader()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _RestroomInfoCard(name: widget.restroomName),
                        const SizedBox(height: 24),

                        _sectionLabel('Detailed Ratings'),
                        const SizedBox(height: 12),
                        _DetailedRatingCard(
                          label: 'Cleanliness',
                          icon: Icons.cleaning_services_rounded,
                          rating: cleanlinessRating,
                          onChanged: (v) =>
                              setState(() => cleanlinessRating = v),
                        ),
                        const SizedBox(height: 10),
                        _DetailedRatingCard(
                          label: 'Availability',
                          icon: Icons.door_front_door_rounded,
                          rating: availabilityRating,
                          onChanged: (v) =>
                              setState(() => availabilityRating = v),
                        ),
                        const SizedBox(height: 10),
                        _DetailedRatingCard(
                          label: 'Amenities',
                          icon: Icons.chair_rounded,
                          rating: amenitiesRating,
                          onChanged: (v) =>
                              setState(() => amenitiesRating = v),
                        ),
                        const SizedBox(height: 10),
                        _DetailedRatingCard(
                          label: 'Smell',
                          icon: Icons.air_rounded,
                          rating: smellRating,
                          onChanged: (v) => setState(() => smellRating = v),
                        ),
                        const SizedBox(height: 16),
                        _OverallRatingDisplay(rating: overallRating),
                        const SizedBox(height: 24),

                        _sectionLabel('What did you find?'),
                        const SizedBox(height: 12),
                        _AmenitiesFoundCard(
                          amenities: amenitiesFound,
                          onChanged: (key, val) =>
                              setState(() => amenitiesFound[key] = val),
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel('Comment (Optional)'),
                        const SizedBox(height: 10),
                        _styledTextField(
                          controller: _commentController,
                          hint: 'Share your experience…',
                          maxLines: 5,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 24),

                        _sectionLabel('Add Photos (max 10)'),
                        const SizedBox(height: 12),
                        _PhotoRow(
                          photos: _selectedPhotos,
                          onAdd: _showPhotoSheet,
                          onRemove: _removePhoto,
                        ),
                        const SizedBox(height: 36),

                        // ── Submit button ──────────────────────────────────
                        SpringButton(
                          onTap: isSubmitting ? () {} : _submitReview,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [AppColors.mintLight, AppColors.tealDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [BoxShadow(
                                  color: AppColors.tealDark.withOpacity(0.4),
                                  blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: Center(
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20, width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white, strokeWidth: 2))
                                  : const Text('Submit Review',
                                      style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                          letterSpacing: 0.3)),
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
        ),
      ),
    );
  }

  // ── Private builders ──────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.mintLight, AppColors.tealDark],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                child: const Icon(Icons.rate_review_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text('Write a Review',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                      color: Colors.white)),
              const SizedBox(height: 4),
              Text('Help others find the best restrooms',
                  style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8))),
            ],
          ),
        ),
        Positioned(
          top: 40, left: 6,
          child: const SafeArea(child: AppBackButton()),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.textDark, letterSpacing: 0.2),
      );

  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
        filled: true,
        fillColor: AppColors.fieldFill,
        counterStyle: const TextStyle(fontSize: 11, color: AppColors.textLight),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.tealDark, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showPhotoSheet() {
    showPhotoSourceSheet(
      context,
      title: 'Add Photo',
      subtitle: 'Share a photo of this restroom',
      onCamera: _takePhoto,
      onGallery: _pickImage,
    );
  }
}

// ─── Local-only widgets ───────────────────────────────────────────────────────

class _RestroomInfoCard extends StatelessWidget {
  final String name;
  const _RestroomInfoCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
              color: AppColors.mintLight.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.wc_rounded, color: AppColors.tealDark, size: 24),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                  color: AppColors.textDark)),
        ),
      ]),
    );
  }
}

class _DetailedRatingCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final double rating;
  final ValueChanged<double> onChanged;

  const _DetailedRatingCard({
    required this.label, required this.icon,
    required this.rating, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: AppColors.mintLight.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 16, color: AppColors.tealDark),
        ),
        const SizedBox(width: 12),
        Text(label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const Spacer(),
        StarRating(
          rating: rating,
          size: 24,
          activeColor: AppColors.orangeAlt,
          inactiveColor: AppColors.textLight,
          onRatingChanged: onChanged,
        ),
      ]),
    );
  }
}

class _AmenitiesFoundCard extends StatelessWidget {
  final Map<String, bool> amenities;
  final void Function(String key, bool value) onChanged;
  const _AmenitiesFoundCard({required this.amenities, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardAlt,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider, width: 1),
      ),
      child: Column(
        children: amenities.keys.map((key) {
          final isChecked = amenities[key] ?? false;
          return InkWell(
            onTap: () { HapticFeedback.selectionClick(); onChanged(key, !isChecked); },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isChecked ? AppColors.tealDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                        color: isChecked ? AppColors.tealDark : AppColors.textLight,
                        width: 2),
                  ),
                  child: isChecked
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(key,
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w500,
                        color: isChecked ? AppColors.textDark : AppColors.textMid)),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OverallRatingDisplay extends StatelessWidget {
  final double rating;
  const _OverallRatingDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    final hasRating = rating > 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.orangeAlt.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.orangeAlt.withOpacity(0.25), width: 1),
      ),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
              color: AppColors.orangeAlt.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.star_rounded, size: 18, color: AppColors.orangeAlt),
        ),
        const SizedBox(width: 12),
        const Text('Overall Rating',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                color: AppColors.textDark)),
        const Spacer(),
        if (hasRating) ...
          List.generate(5, (i) {
            final full = i < rating.floor();
            final half = !full && i < rating;
            return Icon(
              full ? Icons.star_rounded : half ? Icons.star_half_rounded : Icons.star_outline_rounded,
              size: 22,
              color: AppColors.orangeAlt,
            );
          })
        else
          const Text('Rate categories above',
              style: TextStyle(fontSize: 11, color: AppColors.textLight)),
        if (hasRating) ...[const SizedBox(width: 6),
          Text(rating.toStringAsFixed(1),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                  color: AppColors.orangeAlt))],
      ]),
    );
  }
}

class _PhotoRow extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _PhotoRow({required this.photos, required this.onAdd, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          GestureDetector(
            onTap: () { HapticFeedback.lightImpact(); onAdd(); },
            child: Container(
              width: 80, height: 80,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppColors.mintLight.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.tealDark.withOpacity(0.3), width: 1.5),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 26, color: AppColors.tealDark),
                  SizedBox(height: 4),
                  Text('Add',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                          color: AppColors.tealDark)),
                ],
              ),
            ),
          ),
          ...photos.asMap().entries.map((e) => Stack(children: [
            Container(
              width: 80, height: 80,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14), color: AppColors.divider),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(e.value, fit: BoxFit.cover)),
            ),
            Positioned(
              top: 4, right: 14,
              child: GestureDetector(
                onTap: () => onRemove(e.key),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                      color: AppColors.redAlt, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
                ),
              ),
            ),
          ])),
        ],
      ),
    );
  }
}

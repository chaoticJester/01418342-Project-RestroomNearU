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

// ─────────────────────────────────────────────
// Design tokens (ตรงกับ user_homepage / profile_page)
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
  static const fieldFill = Color(0xFFEEEBDA);
}

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
  double overallRating     = 0;
  double cleanlinessRating = 0;
  double availabilityRating = 0;
  double amenitiesRating   = 0;
  double smellRating       = 0;

  final Map<String, bool> amenitiesFound = {
    'Has Toilet Paper':     false,
    'Has Soap':             false,
    'Has Paper Towels':     false,
    'Clean':                false,
    'Has Warm Water':       false,
    'Wheelchair Accessible': false,
  };

  final TextEditingController _commentController = TextEditingController();
  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();
  bool isSubmitting = false;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 10) {
      _showSnack('Maximum 10 photos allowed', isError: true);
      return;
    }
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) setState(() => _selectedPhotos.add(File(image.path)));
  }

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= 10) {
      _showSnack('Maximum 10 photos allowed', isError: true);
      return;
    }
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) setState(() => _selectedPhotos.add(File(photo.path)));
  }

  void _removePhoto(int index) =>
      setState(() => _selectedPhotos.removeAt(index));

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _C.red : _C.tealDark,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<List<String>> _uploadPhotos(String reviewId) async {
    final urls = <String>[];
    for (final file in _selectedPhotos) {
      final fileName = 'reviews/$reviewId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  Future<void> _submitReview() async {
    if (overallRating == 0) {
      _showSnack('Please provide an overall rating', isError: true);
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => isSubmitting = true);
    
    try {
      final firebaseUser = FirebaseAuth.instance.currentUser;
      if(firebaseUser == null) {
        _showSnack("You must be logged in to submit a review", isError: true);
        setState(() {
          isSubmitting = false;
        });
        return;
      }


      final userModel = await UserService().getUserById(firebaseUser.uid);

      final reviewRef = FirebaseFirestore.instance.collection("reviews").doc();
      final tempId = reviewRef.id;


      List<String> uploadedUrls = [];
      if(_selectedPhotos.isNotEmpty) {
        uploadedUrls = await _uploadPhotos(tempId);
      }

      final review = ReviewModel(
        reviewId: tempId,
        restroomId: widget.restroomId,
        reviewerId: firebaseUser.uid,
        reviewerName: userModel?.displayName ?? firebaseUser.displayName ?? 'Anonymous',
        reviewerPhotoUrl: firebaseUser.photoURL ?? '',
        rating: overallRating,
        cleanlinessRating: cleanlinessRating,
        availabilityRating: availabilityRating,
        amenitiesRating: amenitiesRating,
        smellRating: smellRating,
        amenitiesFound: amenitiesFound,
        comment: _commentController.text.trim(),
        photos: uploadedUrls,
      );

      await ReviewService().addReviewWithRatingUpdate(review);

      await UserService().incrementReviewCount(tempId);

      if (!mounted) return;
      setState(() => isSubmitting = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: _C.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: _C.green.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded,
                    color: _C.green, size: 42),
              ),
              const SizedBox(height: 16),
              const Text(
                'Review Submitted',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for sharing your experience!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _C.textMid),
              ),
              const SizedBox(height: 20),
              _SpringButton(
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_C.teal, _C.tealDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                          color: _C.tealDark.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: const Center(
                    child: Text('Done',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if(!mounted) return;
      setState(() {
        isSubmitting = false;
      });
      _showSnack("Failed to submit review. Please try again.", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // ── Hero header ────────────────────────────
                SliverToBoxAdapter(child: _buildHeroHeader()),

                // ── Form body ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Restroom info card
                        _RestroomInfoCard(name: widget.restroomName),
                        const SizedBox(height: 24),

                        // Overall rating
                        _sectionLabel('Overall Rating *'),
                        const SizedBox(height: 12),
                        Center(
                          child: _StarRating(
                            rating: overallRating,
                            size: 40,
                            onChanged: (v) =>
                                setState(() => overallRating = v),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Detailed ratings
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
                        const SizedBox(height: 24),

                        // What did you find
                        _sectionLabel('What did you find?'),
                        const SizedBox(height: 12),
                        _AmenitiesFoundCard(
                          amenities: amenitiesFound,
                          onChanged: (key, val) =>
                              setState(() => amenitiesFound[key] = val),
                        ),
                        const SizedBox(height: 24),

                        // Comment
                        _sectionLabel('Comment (Optional)'),
                        const SizedBox(height: 10),
                        _styledTextField(
                          controller: _commentController,
                          hint: 'Share your experience…',
                          maxLines: 5,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 24),

                        // Photos
                        _sectionLabel(
                            'Add Photos (max 10)'),
                        const SizedBox(height: 12),
                        _PhotoRow(
                          photos: _selectedPhotos,
                          onAdd: () => _showPhotoSheet(),
                          onRemove: _removePhoto,
                        ),
                        const SizedBox(height: 36),

                        // Submit
                        _SpringButton(
                          onTap: isSubmitting ? () {} : _submitReview,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_C.teal, _C.tealDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.tealDark.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Submit Review',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
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

  // ── Hero header ───────────────────────────────────────────────────────
  Widget _buildHeroHeader() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.teal, _C.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.rate_review_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Write a Review',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Help others find the best restrooms',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        Positioned(
          top: 40,
          left: 6,
          child: SafeArea(
            child: _BackButton(onTap: () => Navigator.pop(context)),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _C.textDark,
          letterSpacing: 0.2,
        ),
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
      style: const TextStyle(fontSize: 13, color: _C.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: _C.textLight),
        filled: true,
        fillColor: _C.fieldFill,
        counterStyle:
            const TextStyle(fontSize: 11, color: _C.textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.tealDark, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showPhotoSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: _C.divider,
                    borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            _sheetTile(Icons.camera_alt_rounded, 'Take Photo', _takePhoto),
            _sheetTile(Icons.photo_library_rounded, 'Choose from Gallery',
                _pickImage),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  ListTile _sheetTile(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _C.teal.withOpacity(0.25),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: _C.tealDark),
      ),
      title: Text(label,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _C.textDark)),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}

// ─────────────────────────────────────────────
// Restroom info chip
// ─────────────────────────────────────────────
class _RestroomInfoCard extends StatelessWidget {
  final String name;
  const _RestroomInfoCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wc_rounded, color: _C.tealDark, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _C.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Star rating widget
// ─────────────────────────────────────────────
class _StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<double> onChanged;

  const _StarRating({
    required this.rating,
    required this.onChanged,
    this.size = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            onChanged((i + 1).toDouble());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: i < rating ? _C.orange : _C.textLight,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────
// Detailed rating card
// ─────────────────────────────────────────────
class _DetailedRatingCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final double rating;
  final ValueChanged<double> onChanged;

  const _DetailedRatingCard({
    required this.label,
    required this.icon,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: _C.tealDark),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _C.textDark),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onChanged((i + 1).toDouble());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    size: 24,
                    color: i < rating ? _C.orange : _C.textLight,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Amenities found card (checkboxes)
// ─────────────────────────────────────────────
class _AmenitiesFoundCard extends StatelessWidget {
  final Map<String, bool> amenities;
  final void Function(String key, bool value) onChanged;

  const _AmenitiesFoundCard(
      {required this.amenities, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1),
      ),
      child: Column(
        children: amenities.keys.map((key) {
          final isChecked = amenities[key] ?? false;
          return InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(key, !isChecked);
            },
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: isChecked ? _C.tealDark : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isChecked ? _C.tealDark : _C.textLight,
                        width: 2,
                      ),
                    ),
                    child: isChecked
                        ? const Icon(Icons.check_rounded,
                            size: 14, color: Colors.white)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    key,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color:
                          isChecked ? _C.textDark : _C.textMid,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Photo row
// ─────────────────────────────────────────────
class _PhotoRow extends StatelessWidget {
  final List<File> photos;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _PhotoRow(
      {required this.photos,
      required this.onAdd,
      required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // Add button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onAdd();
            },
            child: Container(
              width: 80,
              height: 80,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _C.teal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: _C.tealDark.withOpacity(0.3), width: 1.5),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 26, color: _C.tealDark),
                  SizedBox(height: 4),
                  Text('Add',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _C.tealDark)),
                ],
              ),
            ),
          ),
          // Selected photos
          ...photos.asMap().entries.map((e) => Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: _C.divider,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.file(e.value, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 14,
                    child: GestureDetector(
                      onTap: () => onRemove(e.key),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFFB3261E),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ),
                ],
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Circle back button (shared style)
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
          width: 48,
          height: 48,
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
          child: const Icon(Icons.arrow_back,
              size: 22, color: _C.textDark),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Spring press wrapper
// ─────────────────────────────────────────────
class _SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringButton({required this.child, required this.onTap});

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton>
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
    _scale = Tween(begin: 1.0, end: 0.96)
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
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

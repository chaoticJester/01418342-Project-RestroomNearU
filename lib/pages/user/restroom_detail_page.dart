import 'package:flutter/material.dart';
import '../../models/restroom_model.dart';
import '../../models/review_model.dart';
import '../../services/restroom_service.dart';
import '../../services/review_service.dart';
import 'photo_gallery_page.dart';
import 'report_issue_page.dart';
import 'write_review_page.dart';

class RestroomDetailPage extends StatefulWidget {
  final RestroomModel restroom;

  const RestroomDetailPage({
    Key? key,
    required this.restroom,
  }) : super(key: key);

  @override
  State<RestroomDetailPage> createState() => _RestroomDetailPageState();
}

class _RestroomDetailPageState extends State<RestroomDetailPage> {
  bool isFavorite = false;
  late List<ReviewModel> reviews;
  late Map<String, int> ratingBreakdown;
  late bool isOpen;
  late String distance;
  String selectedFilter = 'Recent';
  Set<String> helpfulReviewIds = {}; // Track which reviews user marked as helpful

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
  }

  void _loadData() {
    // Load reviews
    reviews = ReviewService.getReviewsByRestroomId(widget.restroom.restroomId);
    
    // Get rating breakdown
    ratingBreakdown = RestroomService.getRatingBreakdown(widget.restroom.restroomId);
    
    // Check if open
    isOpen = RestroomService.isOpen(widget.restroom);
    
    // Get distance
    distance = RestroomService.getDistance(
      widget.restroom.latitude,
      widget.restroom.longitude,
    );
  }

  void _sortReviews(String filter) {
    setState(() {
      selectedFilter = filter;
      
      switch (filter) {
        case 'Recent':
          // Sort by date (most recent first)
          reviews.sort((a, b) => b.timestamp.compareTo(a.timestamp));
          break;
        case 'Highest Rating':
          reviews.sort((a, b) => b.rating.compareTo(a.rating));
          break;
        case 'Lowest Rating':
          reviews.sort((a, b) => a.rating.compareTo(b.rating));
          break;
        case 'Most Helpful':
          reviews.sort((a, b) => b.helpfulCount.compareTo(a.helpfulCount));
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content
          SingleChildScrollView(
            child: Column(
              children: [
                // Top Image
                _buildHeaderImage(),

                // Content Card
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCF9EA),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitleAndRating(),
                        const SizedBox(height: 16),
                        _buildLocationSection(),
                        const SizedBox(height: 16),
                        _buildOpenCloseSection(),
                        const SizedBox(height: 16),
                        _buildPriceSection(),
                        const SizedBox(height: 16),
                        _buildRatingBreakdownSection(),
                        const SizedBox(height: 16),
                        _buildAmenitiesSection(),
                        const SizedBox(height: 24),
                        _buildPhotoGallerySection(),
                        const SizedBox(height: 24),
                        _buildActionButtons(),
                        const SizedBox(height: 24),
                        _buildReviewsSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            // Open photo gallery when tapping on header image
            if (widget.restroom.photos.isNotEmpty) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoGalleryPage(
                    restroomId: widget.restroom.restroomId,
                    restroomName: widget.restroom.restroomName,
                    photos: widget.restroom.photos,
                    initialIndex: 0,
                  ),
                ),
                  );
            }
          },
          child: Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[300],
            ),
            child: widget.restroom.photos.isNotEmpty
                ? Image.network(
                    widget.restroom.photos.first,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.wc, size: 80, color: Colors.grey[400]);
                    },
                  )
                : Icon(Icons.wc, size: 80, color: Colors.grey[400]),
          ),
        ),
        // Back button
        Positioned(
          top: 40,
          left: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.arrow_back, size: 24),
              ),
            ),
          ),
        ),
        // Favorite button
        Positioned(
          top: 40,
          right: 6,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                setState(() {
                  isFavorite = !isFavorite;
                });
              },
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.black,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleAndRating() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.restroom.restroomName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.star, color: Colors.orange, size: 16),
            const SizedBox(width: 4),
            Text(
              widget.restroom.avgRating.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return _buildInfoSection(
      icon: Icons.location_pin,
      title: 'Location',
      content: widget.restroom.address,
      subtitle: distance,
      subtitleColor: const Color(0xFFFFA4A4),
    );
  }

  Widget _buildOpenCloseSection() {
    final openCloseText = widget.restroom.is24hrs
        ? '24 Hours'
        : '${widget.restroom.openTime} - ${widget.restroom.closeTime}';
    
    return _buildInfoSection(
      icon: Icons.access_time,
      title: 'Open/Close',
      content: openCloseText,
      subtitle: isOpen ? 'Open' : 'Closed',
      subtitleColor: const Color(0xFFFFA4A4),
    );
  }

  Widget _buildPriceSection() {
    final priceText = widget.restroom.isFree
        ? 'Free'
        : widget.restroom.price != null
            ? '${widget.restroom.price} THB'
            : 'Paid';
    
    return _buildInfoSection(
      icon: Icons.attach_money,
      title: 'Price',
      content: '',
      subtitle: priceText,
      subtitleColor: const Color(0xFFFFA4A4),
    );
  }

  Widget _buildRatingBreakdownSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.star, size: 15),
            SizedBox(width: 4),
            Text(
              'Rating Breakdown',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildRatingBreakdown('Cleanliness', ratingBreakdown['cleanliness'] ?? 0),
        const SizedBox(height: 4),
        _buildRatingBreakdown('Availability', ratingBreakdown['availability'] ?? 0),
        const SizedBox(height: 4),
        _buildRatingBreakdown('Amenities', ratingBreakdown['amenities'] ?? 0),
        const SizedBox(height: 4),
        _buildRatingBreakdown('Smell', ratingBreakdown['smell'] ?? 0),
      ],
    );
  }

  Widget _buildAmenitiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Icon(Icons.check_circle_outline, size: 15),
            SizedBox(width: 4),
            Text(
              'Amenities',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAmenitiesGrid(),
      ],
    );
  }

  Widget _buildPhotoGallerySection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.photo_library, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Photo (${widget.restroom.photos.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                // Navigate to photo gallery
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoGalleryPage(
                      restroomId: widget.restroom.restroomId,
                      restroomName: widget.restroom.restroomName,
                      photos: widget.restroom.photos,
                      initialIndex: 0,
                    ),
                  ),
                );
              },
              child: const Text(
                'View All Photos',
                style: TextStyle(
                  fontSize: 10,
                  color: Color(0xFFFFA4A4),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildPhotoGrid(),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.navigation,
                label: 'Direction',
                onTap: () {
                  // TODO: Open maps with lat/lng
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Opening directions to ${widget.restroom.restroomName}',
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.rate_review,
                label: 'Review',
                onTap: () {
                  // Navigate to write review page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WriteReviewPage(
                        restroomId: widget.restroom.restroomId,
                        restroomName: widget.restroom.restroomName,
                      ),
                    ),
                  ).then((_) {
                    // Reload reviews after returning from write review page
                    setState(() {
                      _loadData();
                    });
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_a_photo,
                label: 'Add Photo',
                onTap: () {
                  // Navigate to photo gallery (which has add photo functionality)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoGalleryPage(
                        restroomId: widget.restroom.restroomId,
                        restroomName: widget.restroom.restroomName,
                        photos: widget.restroom.photos,
                        initialIndex: 0,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                icon: Icons.flag,
                label: 'Report',
                onTap: () {
                  // Navigate to report issue page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ReportIssuePage(
                        restroomId: widget.restroom.restroomId,
                        restroomName: widget.restroom.restroomName,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.rate_review, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Review (${widget.restroom.totalRatings})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                // Navigate to write review page
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WriteReviewPage(
                      restroomId: widget.restroom.restroomId,
                      restroomName: widget.restroom.restroomName,
                    ),
                  ),
                ).then((_) {
                  // Reload reviews after returning from write review page
                  setState(() {
                    _loadData();
                  });
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFD9D9D9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Add Review',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Filter dropdown
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFFFCF9EA),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              builder: (context) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'Sort Reviews',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...filterOptions.map((option) {
                      final isSelected = selectedFilter == option;
                      return ListTile(
                        title: Text(
                          option,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFFBADFDB) : Colors.black,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Color(0xFFBADFDB),
                              )
                            : null,
                        onTap: () {
                          _sortReviews(option);
                          Navigator.pop(context);
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  selectedFilter,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_drop_down, size: 24),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Reviews List
        ...reviews.map((review) => _buildReviewItem(review)),
      ],
    );
  }

  // Helper widgets
  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String content,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (content.isNotEmpty)
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: subtitleColor ?? Colors.black,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingBreakdown(String label, int stars) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13),
        ),
        Row(
          children: List.generate(
            5,
            (index) => Icon(
              index < stars ? Icons.star : Icons.star_border,
              size: 16,
              color: Colors.orange,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmenitiesGrid() {
    final amenities = widget.restroom.amenities.entries.map((entry) {
      return {
        'name': _formatAmenityName(entry.key),
        'available': entry.value,
      };
    }).toList();

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: amenities.map((amenity) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              amenity['available'] as bool ? Icons.check_box : Icons.cancel,
              size: 10,
              color: amenity['available'] as bool ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 4),
            Text(
              amenity['name'] as String,
              style: const TextStyle(fontSize: 10),
            ),
          ],
        );
      }).toList(),
    );
  }

  String _formatAmenityName(String key) {
    // Convert camelCase to Title Case
    return key.replaceAllMapped(
      RegExp(r'([A-Z])'),
      (match) => ' ${match.group(0)}',
    ).trim();
  }

  Widget _buildPhotoGrid() {
    return Wrap(
      spacing: 2,
      runSpacing: 2,
      children: List.generate(
        widget.restroom.photos.length > 8 ? 8 : widget.restroom.photos.length,
        (index) {
          return GestureDetector(
            onTap: () {
              // Navigate to photo gallery with specific photo
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PhotoGalleryPage(
                    restroomId: widget.restroom.restroomId,
                    restroomName: widget.restroom.restroomName,
                    photos: widget.restroom.photos,
                    initialIndex: index,
                  ),
                ),
              );
            },
            child: Container(
              width: 78,
              height: 54,
              decoration: BoxDecoration(
                color: const Color(0xFFD9D9D9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.black, width: 0.5),
              ),
              child: widget.restroom.photos.isNotEmpty && index < widget.restroom.photos.length
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(7),
                      child: Image.network(
                        widget.restroom.photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.broken_image, color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.photo, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFFD9D9D9)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewItem(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            review.reviewerName,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFBADFDB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 8, color: Colors.orange),
                    const SizedBox(width: 2),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFBADFDB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  ReviewService.getRatingBadge(review.rating),
                  style: const TextStyle(fontSize: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            review.comment,
            style: TextStyle(
              fontSize: 8,
              color: Colors.black.withOpacity(0.8),
              height: 1.2,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Helpful button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      if (helpfulReviewIds.contains(review.reviewId)) {
                        helpfulReviewIds.remove(review.reviewId);
                        // TODO: Decrease helpful count in Firebase
                      } else {
                        helpfulReviewIds.add(review.reviewId);
                        // TODO: Increase helpful count in Firebase
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Marked as helpful'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: helpfulReviewIds.contains(review.reviewId)
                          ? const Color(0xFFBADFDB)
                          : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: helpfulReviewIds.contains(review.reviewId)
                            ? const Color(0xFFBADFDB)
                            : Colors.grey.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          helpfulReviewIds.contains(review.reviewId)
                              ? Icons.thumb_up
                              : Icons.thumb_up_outlined,
                          size: 12,
                          color: helpfulReviewIds.contains(review.reviewId)
                              ? Colors.black
                              : Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Helpful',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: helpfulReviewIds.contains(review.reviewId)
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: helpfulReviewIds.contains(review.reviewId)
                                ? Colors.black
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${review.helpfulCount + (helpfulReviewIds.contains(review.reviewId) ? 1 : 0)})',
                          style: TextStyle(
                            fontSize: 8,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Read more button
              GestureDetector(
                onTap: () {
                  // TODO: Expand review or show full review dialog
                  showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: const Color(0xFFFCF9EA),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: Text(
                    review.reviewerName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  content: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.star, size: 16, color: Colors.orange),
                            const SizedBox(width: 4),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFBADFDB),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                ReviewService.getRatingBadge(review.rating),
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          review.comment,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
                },
                child: const Text(
                  'read More .',
                  style: TextStyle(
                    fontSize: 8,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

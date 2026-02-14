import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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

class _WriteReviewPageState extends State<WriteReviewPage> {
  // Ratings
  double overallRating = 0;
  double cleanlinessRating = 0;
  double availabilityRating = 0;
  double amenitiesRating = 0;
  double smellRating = 0;

  // Amenities found
  final Map<String, bool> amenitiesFound = {
    'Has Toilet Paper': false,
    'Has Soap': false,
    'Has Paper Towels': false,
    'Clean': false,
    'Has Warm Water': false,
    'Wheelchair Accessible': false,
  };

  // Comment
  final TextEditingController _commentController = TextEditingController();

  // Photos
  final List<File> _selectedPhotos = [];
  final ImagePicker _picker = ImagePicker();

  bool isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_selectedPhotos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 photos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedPhotos.add(File(image.path));
      });
    }
  }

  Future<void> _takePhoto() async {
    if (_selectedPhotos.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 10 photos allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedPhotos.add(File(photo.path));
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _selectedPhotos.removeAt(index);
    });
  }

  Future<void> _submitReview() async {
    if (overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an overall rating'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // TODO: Submit review to Firebase
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFCF9EA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Review Submitted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Thank you for sharing your experience!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close review page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBADFDB),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBADFDB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Write Review',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Restroom Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.wc, color: Colors.grey),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.restroomName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Overall Rating
              const Text(
                'Overall Rating *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildStarRating(
                rating: overallRating,
                onRatingChanged: (rating) {
                  setState(() {
                    overallRating = rating;
                  });
                },
                size: 40,
              ),

              const SizedBox(height: 24),

              // Detailed Ratings
              const Text(
                'Detailed Ratings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              _buildDetailedRating(
                label: 'Cleanliness',
                rating: cleanlinessRating,
                onRatingChanged: (rating) {
                  setState(() {
                    cleanlinessRating = rating;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildDetailedRating(
                label: 'Availability',
                rating: availabilityRating,
                onRatingChanged: (rating) {
                  setState(() {
                    availabilityRating = rating;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildDetailedRating(
                label: 'Amenities',
                rating: amenitiesRating,
                onRatingChanged: (rating) {
                  setState(() {
                    amenitiesRating = rating;
                  });
                },
              ),
              const SizedBox(height: 12),
              _buildDetailedRating(
                label: 'Smell',
                rating: smellRating,
                onRatingChanged: (rating) {
                  setState(() {
                    smellRating = rating;
                  });
                },
              ),

              const SizedBox(height: 24),

              // Amenities Found
              const Text(
                'What did you find?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...amenitiesFound.keys.map((amenity) {
                return CheckboxListTile(
                  value: amenitiesFound[amenity],
                  onChanged: (value) {
                    setState(() {
                      amenitiesFound[amenity] = value ?? false;
                    });
                  },
                  title: Text(
                    amenity,
                    style: const TextStyle(fontSize: 14),
                  ),
                  activeColor: const Color(0xFFBADFDB),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                );
              }).toList(),

              const SizedBox(height: 24),

              // Comment
              const Text(
                'Comment (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBADFDB), width: 2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Photo Upload
              const Text(
                'Add Photos (Maximum 10 photos)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    // Add Photo Button
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
                                ListTile(
                                  leading: const Icon(Icons.camera_alt),
                                  title: const Text('Take Photo'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _takePhoto();
                                  },
                                ),
                                ListTile(
                                  leading: const Icon(Icons.photo_library),
                                  title: const Text('Choose from Gallery'),
                                  onTap: () {
                                    Navigator.pop(context);
                                    _pickImage();
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      child: Container(
                        width: 100,
                        height: 100,
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.add_a_photo,
                              size: 32,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Selected Photos
                    ..._selectedPhotos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final photo = entry.value;
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(photo),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removePhoto(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBADFDB),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Submit Review',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStarRating({
    required double rating,
    required Function(double) onRatingChanged,
    double size = 32,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return GestureDetector(
          onTap: () {
            onRatingChanged((index + 1).toDouble());
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              index < rating ? Icons.star : Icons.star_border,
              size: size,
              color: Colors.orange,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDetailedRating({
    required String label,
    required double rating,
    required Function(double) onRatingChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(5, (index) {
              return GestureDetector(
                onTap: () {
                  onRatingChanged((index + 1).toDouble());
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    index < rating ? Icons.star : Icons.star_border,
                    size: 28,
                    color: Colors.orange,
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

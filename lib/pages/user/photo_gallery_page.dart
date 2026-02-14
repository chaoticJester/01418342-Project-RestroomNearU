import 'package:flutter/material.dart';

class PhotoGalleryPage extends StatefulWidget {
  final String restroomId;
  final String restroomName;
  final List<String> photos;
  final int initialIndex;

  const PhotoGalleryPage({
    Key? key,
    required this.restroomId,
    required this.restroomName,
    required this.photos,
    this.initialIndex = 0,
  }) : super(key: key);

  @override
  State<PhotoGalleryPage> createState() => _PhotoGalleryPageState();
}

class _PhotoGalleryPageState extends State<PhotoGalleryPage> {
  late int currentIndex;
  late PageController _pageController;
  bool isFullscreen = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _toggleFullscreen() {
    setState(() {
      isFullscreen = !isFullscreen;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: isFullscreen ? Colors.black : const Color(0xFFFCF9EA),
      body: SafeArea(
        child: Column(
          children: [
            // Header (hidden in fullscreen)
            if (!isFullscreen) _buildHeader(),

            // Main Photo View
            Expanded(
              child: Stack(
                children: [
                  // PageView for swipeable photos
                  PageView.builder(
                    controller: _pageController,
                    itemCount: widget.photos.length,
                    onPageChanged: (index) {
                      setState(() {
                        currentIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: _toggleFullscreen,
                        child: Container(
                          color: isFullscreen ? Colors.black : const Color(0xFFFCF9EA),
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Center(
                              child: Hero(
                                tag: 'photo_${widget.photos[index]}',
                                child: Image.network(
                                  widget.photos[index],
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[300],
                                      child: const Icon(
                                        Icons.broken_image,
                                        size: 80,
                                        color: Colors.grey,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // Navigation Arrows
                  if (!isFullscreen && widget.photos.length > 1) ...[
                    // Previous Arrow
                    if (currentIndex > 0)
                      Positioned(
                        left: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _pageController.previousPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.chevron_left,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    // Next Arrow
                    if (currentIndex < widget.photos.length - 1)
                      Positioned(
                        right: 16,
                        top: 0,
                        bottom: 0,
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                );
                              },
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.chevron_right,
                                  size: 32,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],

                  // Photo Counter (Overlay)
                  if (!isFullscreen)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${currentIndex + 1} / ${widget.photos.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Photo Info (hidden in fullscreen)
            if (!isFullscreen) _buildPhotoInfo(),

            // Thumbnail Grid (hidden in fullscreen)
            if (!isFullscreen) _buildThumbnailGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: const Color(0xFFBADFDB),
      child: Row(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(24),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.restroomName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // TODO: Add photo action
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Add Photo'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '+ Add Photo',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Photo Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Uploaded by',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'John Doe',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Upload date',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '2 days ago',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Like photo
                  },
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: const Text(
                    'Like this photo',
                    style: TextStyle(fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBADFDB),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Report photo
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Report Photo'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.flag_outlined, size: 18),
                label: const Text(
                  'Report',
                  style: TextStyle(fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailGrid() {
    return Container(
      height: 120,
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'All Photos',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: widget.photos.length,
              itemBuilder: (context, index) {
                final isSelected = index == currentIndex;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      currentIndex = index;
                    });
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 70,
                    height: 70,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFBADFDB)
                            : Colors.grey.withOpacity(0.3),
                        width: isSelected ? 3 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        widget.photos[index],
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Icon(
                              Icons.broken_image,
                              size: 24,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

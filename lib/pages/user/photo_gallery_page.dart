import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// Design tokens — matches restroom_detail_page
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF5F1E8);
  static const card      = Color(0xFFFFFDFA);
  static const pink      = Color(0xFFEC9B9B);
  static const pinkLight = Color(0xFFF5D4D4);
  static const mint      = Color(0xFFA8D5D5);
  static const mintDark  = Color(0xFF88B5B5);
  static const textDark  = Color(0xFF2C2C2C);
  static const textMid   = Color(0xFF6B6B6B);
  static const textLight = Color(0xFFA5A5A5);
  static const divider   = Color(0xFFE8E4DB);
}

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
  bool _isFullscreen = false;

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
    HapticFeedback.lightImpact();
    setState(() => _isFullscreen = !_isFullscreen);
  }

  void _goTo(int index) {
    setState(() => currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _isFullscreen
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _isFullscreen ? Colors.black : _C.bg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              if (!_isFullscreen) _buildHeader(),

              // ── Main photo viewer ────────────────────────
              Expanded(child: _buildPhotoViewer()),

              // ── Counter + thumbnails ─────────────────────
              if (!_isFullscreen) _buildBottom(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: const BoxDecoration(
        color: _C.mint,
      ),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back, size: 20, color: _C.textDark),
            ),
          ),
          const SizedBox(width: 12),

          // Title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  widget.restroomName,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Photo count badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${currentIndex + 1} / ${widget.photos.length}',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Main photo viewer ────────────────────────────────────────────────
  Widget _buildPhotoViewer() {
    return Stack(
      children: [
        // Swipeable pages
        PageView.builder(
          controller: _pageController,
          itemCount: widget.photos.length,
          onPageChanged: (i) => setState(() => currentIndex = i),
          itemBuilder: (_, i) => GestureDetector(
            onTap: _toggleFullscreen,
            child: Container(
              color: _isFullscreen ? Colors.black : _C.bg,
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.photos[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          value: progress.expectedTotalBytes != null
                              ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                              : null,
                          color: _C.mint,
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.broken_image_rounded,
                            size: 64,
                            color: _isFullscreen
                                ? Colors.white38
                                : _C.textLight),
                        const SizedBox(height: 8),
                        Text(
                          'Failed to load photo',
                          style: TextStyle(
                            fontSize: 13,
                            color: _isFullscreen
                                ? Colors.white54
                                : _C.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Fullscreen hint (tap to exit)
        if (_isFullscreen)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Tap to exit fullscreen',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ),

        // Fullscreen back button
        if (_isFullscreen)
          Positioned(
            top: 12,
            left: 12,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.pop(context);
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    size: 20, color: Colors.white),
              ),
            ),
          ),

        // Left / Right nav arrows
        if (!_isFullscreen && widget.photos.length > 1) ...[
          if (currentIndex > 0)
            Positioned(
              left: 12,
              top: 0,
              bottom: 0,
              child: Center(child: _NavArrow(
                icon: Icons.chevron_left,
                onTap: () => _goTo(currentIndex - 1),
              )),
            ),
          if (currentIndex < widget.photos.length - 1)
            Positioned(
              right: 12,
              top: 0,
              bottom: 0,
              child: Center(child: _NavArrow(
                icon: Icons.chevron_right,
                onTap: () => _goTo(currentIndex + 1),
              )),
            ),
        ],
      ],
    );
  }

  // ── Bottom: dot indicators + thumbnail strip ─────────────────────────
  Widget _buildBottom() {
    return Container(
      color: _C.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dot indicators
          if (widget.photos.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.photos.length, (i) {
                  final selected = i == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: selected ? 20 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: selected ? _C.mint : _C.divider,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  );
                }),
              ),
            ),

          // Thumbnail strip
          if (widget.photos.length > 1)
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                itemCount: widget.photos.length,
                itemBuilder: (_, i) {
                  final selected = i == currentIndex;
                  return GestureDetector(
                    onTap: () => _goTo(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 56,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? _C.mint : Colors.transparent,
                          width: 2.5,
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color: _C.mint.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          widget.photos[i],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: _C.divider,
                            child: const Icon(Icons.broken_image_rounded,
                                size: 20, color: _C.textLight),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Nav arrow button ─────────────────────────────────────────────────
class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 28, color: _C.textDark),
      ),
    );
  }
}

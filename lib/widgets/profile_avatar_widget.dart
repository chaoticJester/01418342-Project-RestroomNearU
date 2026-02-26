import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/user_firestore.dart';

/// Reusable profile avatar with camera-button overlay.
/// Shows network image if [photoUrl] is set, otherwise falls back to icon.
class ProfileAvatarWidget extends StatefulWidget {
  final String? photoUrl;
  final double size;
  final bool showEditButton;
  final bool isAdmin;

  const ProfileAvatarWidget({
    super.key,
    this.photoUrl,
    this.size = 84,
    this.showEditButton = true,
    this.isAdmin = false,
  });

  @override
  State<ProfileAvatarWidget> createState() => _ProfileAvatarWidgetState();
}

class _ProfileAvatarWidgetState extends State<ProfileAvatarWidget> {
  final _userService = UserService();
  bool _uploading = false;

  Future<void> _pickAndUpload(BuildContext context) async {
    // Show bottom sheet with options
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFFFCF9EA),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Color(0xFF7BBFBA)),
                title: const Text('Take a photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Color(0xFF7BBFBA)),
                title: const Text('Choose from gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              if (widget.photoUrl != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Color(0xFFB3261E)),
                  title: const Text('Remove photo',
                      style: TextStyle(color: Color(0xFFB3261E), fontWeight: FontWeight.w600)),
                  onTap: () => Navigator.pop(context, null),
                ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return;

    // Handle remove
    if (source == null && widget.photoUrl != null) {
      setState(() => _uploading = true);
      await _userService.removeProfilePhoto();
      setState(() => _uploading = false);
      return;
    }

    if (source == null) return;

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );

    if (picked == null || !mounted) return;

    setState(() => _uploading = true);
    final url = await _userService.uploadProfilePhoto(File(picked.path));
    if (mounted) {
      setState(() => _uploading = false);
      if (url == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload photo. Please try again.'),
            backgroundColor: Color(0xFFB3261E),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminGold = const Color(0xFFF0A500);
    final borderColor = widget.isAdmin
        ? adminGold.withOpacity(0.85)
        : Colors.white.withOpacity(0.6);

    return GestureDetector(
      onTap: widget.showEditButton ? () => _pickAndUpload(context) : null,
      child: Stack(
        children: [
          // Avatar circle
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.25),
              border: Border.all(color: borderColor, width: widget.isAdmin ? 3 : 2.5),
            ),
            child: ClipOval(
              child: _uploading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : widget.photoUrl != null
                      ? Image.network(
                          widget.photoUrl!,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.person_rounded,
                            size: widget.size * 0.52,
                            color: Colors.white,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: widget.size * 0.52,
                          color: Colors.white,
                        ),
            ),
          ),
          // Camera edit button
          if (widget.showEditButton && !_uploading)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: widget.isAdmin ? adminGold : const Color(0xFF7BBFBA),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.camera_alt_rounded,
                    size: 13, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_colors.dart';

/// A pressable button that scales down on tap (spring feel).
/// Replaces the private `_SpringButton` in write_review_page and
/// add_new_restroom_page, and `_ActionBtn` / `_PillButton` variants.
class SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  /// How much the widget shrinks on press. Default 0.96.
  final double scaleFactor;

  const SpringButton({
    Key? key,
    required this.child,
    required this.onTap,
    this.scaleFactor = 0.96,
  }) : super(key: key);

  @override
  State<SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<SpringButton>
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
    _scale = Tween(begin: 1.0, end: widget.scaleFactor)
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

/// A white circular back button used at the top of hero headers.
/// Replaces `_BackButton` (write_review_page) and `_CircleButton` (detail page).
class AppBackButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Color iconColor;

  const AppBackButton({
    Key? key,
    this.onTap,
    this.iconColor = AppColors.textDark,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SpringButton(
      scaleFactor: 0.88,
      onTap: () {
        HapticFeedback.lightImpact();
        if (onTap != null) {
          onTap!();
        } else {
          Navigator.pop(context);
        }
      },
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
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.arrow_back, size: 22, color: iconColor),
      ),
    );
  }
}

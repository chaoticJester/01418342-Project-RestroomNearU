import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';
import '../../models/review_model.dart';
import '../../services/user_firestore.dart';
import '../../services/review_firestore.dart';

// ─────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────
class _C {
  static const bg         = Color(0xFFFCF9EA);
  static const card       = Color(0xFFF7F4E6);
  static const teal       = Color(0xFFBADFDB);
  static const tealDark   = Color(0xFF7BBFBA);
  static const orange     = Color(0xFFE8753D);
  static const green      = Color(0xFF34A853);
  static const red        = Color(0xFFB3261E);
  static const textDark   = Color(0xFF1C1B1F);
  static const textMid    = Color(0xFF6B6874);
  static const textLight  = Color(0xFFAEABB8);
  static const divider    = Color(0xFFECE9DA);
  static const fieldFill  = Color(0xFFF2EFE0);
}

// ─────────────────────────────────────────────
// ProfilePage
// ─────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  final _userService   = UserService();
  final _reviewService = ReviewService();
  final _auth          = FirebaseAuth.instance;

  late AnimationController _enterCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogOut(BuildContext context) async {
    HapticFeedback.mediumImpact();
    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _C.bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out',
            style: TextStyle(fontWeight: FontWeight.w800, color: _C.textDark)),
        content: const Text('Are you sure you want to log out?',
            style: TextStyle(color: _C.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: _C.textMid, fontWeight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Log Out',
                style: TextStyle(
                    color: _C.red, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) {
        Navigator.popUntil(context, (route) => route.isFirst); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: StreamBuilder<UserModel?>(
          stream: _userService.getCurrentUserStream(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: _C.tealDark),
              );
            }
            final user = userSnap.data;
            if (user == null) {
              return const Center(child: Text('User not found'));
            }
            final currentUser = _auth.currentUser;

            return StreamBuilder<List<ReviewModel>>(
              stream: _reviewService.getReviewsByUser(user.userId),
              builder: (context, reviewSnap) {
                final reviews = reviewSnap.data ?? [];

                return FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      slivers: [
                        // ── Hero header ──────────────────────
                        SliverToBoxAdapter(
                          child: _HeroHeader(
                            displayName: user.displayName,
                            email: user.email,
                            onBack: () => Navigator.of(context).pop(),
                          ),
                        ),

                        // ── Stats row ────────────────────────
                        SliverToBoxAdapter(
                          child: _StatsRow(
                            totalReviews: user.totalReviews,
                            totalAdded: 20,
                            totalHelpful: reviews.fold(
                                0, (s, r) => s + r.helpfulCount),
                          ),
                        ),

                        // ── Recent reviews ───────────────────
                        SliverToBoxAdapter(
                          child: _SectionCard(
                            title: 'Recent Reviews',
                            icon: Icons.rate_review_rounded,
                            child: reviews.isEmpty
                                ? _emptyState('No reviews yet',
                                    Icons.edit_note_rounded)
                                : Column(
                                    children: reviews
                                        .take(3)
                                        .map((r) => _ReviewTile(review: r))
                                        .toList(),
                                  ),
                          ),
                        ),

                        // ── Account info ─────────────────────
                        SliverToBoxAdapter(
                          child: _SectionCard(
                            title: 'Account',
                            icon: Icons.manage_accounts_rounded,
                            child: _AccountInfo(
                              email: user.email,
                              createdAt: currentUser?.metadata.creationTime,
                            ),
                          ),
                        ),

                        // ── Log out ───────────────────────────
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                            child: _LogOutButton(
                              onTap: () => _handleLogOut(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _emptyState(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(icon, size: 36, color: _C.textLight),
          const SizedBox(height: 8),
          Text(text,
              style: const TextStyle(fontSize: 13, color: _C.textLight)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero Header
// ─────────────────────────────────────────────
class _HeroHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final VoidCallback onBack;

  const _HeroHeader({
    required this.displayName,
    required this.email,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          height: 240,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: Color(0xFF7BBFBA),
          ),
          child: Stack(
            children: [
              // Avatar + name
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 28),
                    // Avatar circle
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.25),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.6), width: 2.5),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 42, color: Colors.white),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Back button — same style as RestroomDetailPage
        Positioned(
          top: 40,
          left: 6,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onBack();
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
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back,
                      size: 22, color: _C.textDark),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

}

// ─────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────
class _StatsRow extends StatelessWidget {
  final int totalReviews;
  final int totalAdded;
  final int totalHelpful;

  const _StatsRow({
    required this.totalReviews,
    required this.totalAdded,
    required this.totalHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _StatCard(
            count: totalReviews,
            label: 'Reviews',
            icon: Icons.star_rounded,
            iconColor: _C.orange,
            bgColor: _C.orange.withOpacity(0.12),
          ),
          const SizedBox(width: 12),
          _StatCard(
            count: totalAdded,
            label: 'Added',
            icon: Icons.add_location_alt_rounded,
            iconColor: _C.tealDark,
            bgColor: _C.teal.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          _StatCard(
            count: totalHelpful,
            label: 'Helpful',
            icon: Icons.thumb_up_rounded,
            iconColor: _C.green,
            bgColor: _C.green.withOpacity(0.12),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _StatCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _C.textDark,
                height: 1,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11,
                  color: _C.textMid,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Reusable Section Card
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _C.divider, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: _C.teal.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 16, color: _C.tealDark),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: _C.textDark,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: _C.divider, height: 1, thickness: 1),
            // Content
            Padding(
              padding: const EdgeInsets.all(14),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Review Tile
// ─────────────────────────────────────────────
class _ReviewTile extends StatelessWidget {
  final ReviewModel review;
  const _ReviewTile({required this.review});

  String _timeAgo(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inDays >= 1) return '${d.inDays}d ago';
    if (d.inHours >= 1) return '${d.inHours}h ago';
    return '${d.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _C.fieldFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _C.teal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.wc_rounded, size: 22, color: _C.tealDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.restroomId,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _C.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Star + rating chip
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: _C.orange.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded,
                                color: _C.orange, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              review.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _C.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.comment,
                    style: const TextStyle(
                        fontSize: 12, color: _C.textMid, height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 11, color: _C.textLight),
                      const SizedBox(width: 3),
                      Text(_timeAgo(review.timestamp),
                          style: const TextStyle(
                              fontSize: 10, color: _C.textLight)),
                      const SizedBox(width: 12),
                      Icon(Icons.thumb_up_alt_outlined,
                          size: 11, color: _C.textLight),
                      const SizedBox(width: 3),
                      Text('${review.totalLikes}',
                          style: const TextStyle(
                              fontSize: 10, color: _C.textLight)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Account Info
// ─────────────────────────────────────────────
class _AccountInfo extends StatelessWidget {
  final String email;
  final DateTime? createdAt;

  const _AccountInfo({required this.email, this.createdAt});

  @override
  Widget build(BuildContext context) {
    final memberSince = createdAt != null
        ? AppHelpers.formatDateOnly(createdAt!)
        : '—';

    return Column(
      children: [
        _InfoRow(
          icon: Icons.calendar_today_rounded,
          label: 'Member since',
          value: memberSince,
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.email_rounded,
          label: 'Email',
          value: email,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _C.fieldFill,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: _C.tealDark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10,
                      color: _C.textLight,
                      fontWeight: FontWeight.w500)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      color: _C.textDark,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Log Out Button
// ─────────────────────────────────────────────
class _LogOutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogOutButton({required this.onTap});

  @override
  State<_LogOutButton> createState() => _LogOutButtonState();
}

class _LogOutButtonState extends State<_LogOutButton>
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
    _scale = Tween(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeIn),
    );
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
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _C.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.red.withOpacity(0.3), width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, size: 18, color: _C.red),
              const SizedBox(width: 8),
              Text(
                'Log Out',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _C.red,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

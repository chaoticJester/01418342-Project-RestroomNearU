import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/review_model.dart';
import '../../services/user_firestore.dart';
import '../../services/review_firestore.dart';

// ─────────────────────────────────────────────
// App Colors
// ─────────────────────────────────────────────
class AppColors {
  static const background = Color(0xFFFCF9EA);
  static const cardSurface = Color(0xFFFCF9EA);
  static const teal = Color(0xFFBADFDB);
  static const orange = Color(0xFFE8753D);
  static const green = Color(0xFF34A853);
  static const red = Color(0xFFB3261E);
  static const textDark = Color(0xFF1C1B1F);
  static const textLight = Color(0xFF49454F);
  static const starColor = Color(0xFFE8753D);
}

// ─────────────────────────────────────────────
// Profile Page (StatefulWidget entry point)
// ─────────────────────────────────────────────
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final UserService _userService = UserService();
  final ReviewService _reviewService = ReviewService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: StreamBuilder<UserModel?>(
          stream: _userService.getCurrentUserStream(),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = userSnapshot.data;
            if (user == null) {
              return const Center(child: Text('User not found'));
            }

            final currentUser = _auth.currentUser;

            return StreamBuilder<List<ReviewModel>>(
              stream: _reviewService.getReviewsByUser(user.userId),
              builder: (context, reviewSnapshot) {
                final reviews = reviewSnapshot.data ?? [];

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHeader(displayName: user.displayName),
                      const SizedBox(height: 16),
                      _StatsCard(
                        totalReviews: user.totalReviews,
                        totalAdded: 20, // placeholder – wire when model has it
                        totalHelpful: reviews.fold(0, (sum, r) => sum + r.helpfulCount),
                      ),
                      const SizedBox(height: 12),
                      _RecentReviewsCard(reviews: reviews.take(3).toList()),
                      const SizedBox(height: 12),
                      _AccountCard(
                        email: user.email,
                        createdAt: currentUser?.metadata.creationTime,
                      ),
                      const SizedBox(height: 32),
                      _LogOutButton(onLogOut: () => _handleLogOut(context)),
                      const SizedBox(height: 32),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleLogOut(BuildContext context) async {
    await _auth.signOut();
    if (context.mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login_page', (_) => false);
    }
  }
}

// ─────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String displayName;
  const _ProfileHeader({required this.displayName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios, size: 22, color: AppColors.textDark),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profile',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stats Card (Reviews / Added / Helpful)
// ─────────────────────────────────────────────
class _StatsCard extends StatelessWidget {
  final int totalReviews;
  final int totalAdded;
  final int totalHelpful;

  const _StatsCard({
    required this.totalReviews,
    required this.totalAdded,
    required this.totalHelpful,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              bgColor: AppColors.orange.withOpacity(0.4),
              icon: Icons.star_outline_rounded,
              iconColor: AppColors.orange,
              count: totalReviews,
              label: 'Reviews',
            ),
            _StatItem(
              bgColor: AppColors.teal.withOpacity(0.4),
              icon: Icons.location_on_outlined,
              iconColor: AppColors.teal.withOpacity(1.0),
              count: totalAdded,
              label: 'Added',
            ),
            _StatItem(
              bgColor: AppColors.green.withOpacity(0.4),
              icon: Icons.check_rounded,
              iconColor: AppColors.green,
              count: totalHelpful,
              label: 'Helpful',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final Color bgColor;
  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;

  const _StatItem({
    required this.bgColor,
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 53,
          height: 50,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 6),
        Text(
          '$count',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppColors.textLight),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Recent Reviews Card
// ─────────────────────────────────────────────
class _RecentReviewsCard extends StatelessWidget {
  final List<ReviewModel> reviews;
  const _RecentReviewsCard({required this.reviews});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Reviews',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            if (reviews.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No reviews yet',
                    style: TextStyle(fontSize: 12, color: AppColors.textLight),
                  ),
                ),
              )
            else
              ...reviews.map((r) => _ReviewListItem(review: r)).toList(),
          ],
        ),
      ),
    );
  }
}

class _ReviewListItem extends StatelessWidget {
  final ReviewModel review;
  const _ReviewListItem({required this.review});

  String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays >= 1) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours >= 1) return '${diff.inHours}h ago';
    return '${diff.inMinutes}m ago';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.15),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 10),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          review.restroomId, // ideally restroom name – wire later
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(Icons.star_rounded, color: AppColors.starColor, size: 12),
                      const SizedBox(width: 2),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    review.comment,
                    style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        _timeAgo(review.timestamp),
                        style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.thumb_up_alt_outlined, size: 11, color: AppColors.textLight),
                      const SizedBox(width: 3),
                      Text(
                        '${review.totalLikes}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textLight),
                      ),
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
// Account Info Card
// ─────────────────────────────────────────────
class _AccountCard extends StatelessWidget {
  final String email;
  final DateTime? createdAt;

  const _AccountCard({required this.email, this.createdAt});

  @override
  Widget build(BuildContext context) {
    final memberSince = createdAt != null
        ? DateFormat('MMM d, yyyy').format(createdAt!)
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            _AccountRow(label: 'Member since', value: memberSince),
            _AccountRow(label: 'Email', value: email),
            _AccountRow(label: 'Phone', value: '+66 8* *** ****'),
          ],
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final String label;
  final String value;
  const _AccountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textLight)),
          Text(value, style: const TextStyle(fontSize: 11, color: AppColors.textDark)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Log Out Button
// ─────────────────────────────────────────────
class _LogOutButton extends StatelessWidget {
  final VoidCallback onLogOut;
  const _LogOutButton({required this.onLogOut});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: onLogOut,
        child: Container(
          width: 94,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.red.withOpacity(0.4),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: const Text(
            'Log Out',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/user_model.dart';
import 'package:restroom_near_u/utils/helpers.dart';
import 'package:restroom_near_u/services/user_firestore.dart';

// ─────────────────────────────────────────────
// Design tokens — matches project theme
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
  static const fieldFill = Color(0xFFF2EFE0);
  static const adminGold = Color(0xFFF0A500);
}

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage>
    with SingleTickerProviderStateMixin {
  final _userService = UserService();
  final _auth = FirebaseAuth.instance;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(
      CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogOut(BuildContext context) async {
    HapticFeedback.mediumImpact();
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
            child: const Text('Log Out',
                style: TextStyle(color: _C.red, fontWeight: FontWeight.w700)),
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
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator(color: _C.tealDark));
            }
            final user = snap.data;
            if (user == null) {
              return const Center(child: Text('User not found'));
            }
            final currentUser = _auth.currentUser;

            return FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: CustomScrollView(
                  physics: const ClampingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _HeroHeader(
                        displayName: user.displayName,
                        email: user.email,
                        onBack: () => Navigator.of(context).pop(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _AdminStatsRow(userId: user.userId),
                    ),
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Account',
                        icon: Icons.manage_accounts_rounded,
                        child: _AccountInfo(
                          email: user.email,
                          createdAt: currentUser?.metadata.creationTime,
                          displayName: user.displayName,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: _SectionCard(
                        title: 'Admin Permissions',
                        icon: Icons.admin_panel_settings_rounded,
                        child: const _PermissionsCard(),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 48),
                        child: _LogOutButton(
                            onTap: () => _handleLogOut(context)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Hero Header — gold admin ring
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
        Container(
          height: 250,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF5A9E9A), Color(0xFF7BBFBA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Stack(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.25),
                        border: Border.all(
                            color: _C.adminGold.withOpacity(0.85), width: 3),
                      ),
                      child: const Icon(Icons.person_rounded,
                          size: 44, color: Colors.white),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _C.adminGold,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2)),
                          ],
                        ),
                        child: const Text('ADMIN',
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(displayName,
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text(email,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.85),
                        fontWeight: FontWeight.w400)),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: _C.adminGold.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _C.adminGold.withOpacity(0.6), width: 1),
                  ),
                  child: const Text('System Administrator',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 40,
          left: 6,
          child: SafeArea(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onBack();
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
                        offset: const Offset(0, 2)),
                  ],
                ),
                child: const Icon(Icons.arrow_back,
                    size: 22, color: _C.textDark),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Admin Stats Row — live counts from Firestore
// ─────────────────────────────────────────────
class _AdminStatsRow extends StatelessWidget {
  final String userId;
  const _AdminStatsRow({required this.userId});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(
        children: [
          _LiveStatCard(
            stream: FirebaseFirestore.instance
                .collection('requests')
                .where('status', isEqualTo: 'pending')
                .snapshots()
                .map((s) => s.size),
            label: 'Pending',
            icon: Icons.access_time_rounded,
            iconColor: _C.orange,
            bgColor: _C.orange.withOpacity(0.12),
          ),
          const SizedBox(width: 12),
          _LiveStatCard(
            stream: FirebaseFirestore.instance
                .collection('restrooms')
                .snapshots()
                .map((s) => s.size),
            label: 'Toilets',
            icon: Icons.wc_rounded,
            iconColor: _C.tealDark,
            bgColor: _C.teal.withOpacity(0.3),
          ),
          const SizedBox(width: 12),
          _LiveStatCard(
            stream: FirebaseFirestore.instance
                .collection('reports')
                .where('reviewed', isEqualTo: false)
                .snapshots()
                .map((s) => s.size),
            label: 'Reports',
            icon: Icons.flag_rounded,
            iconColor: _C.red,
            bgColor: _C.red.withOpacity(0.1),
          ),
        ],
      ),
    );
  }
}

class _LiveStatCard extends StatelessWidget {
  final Stream<int> stream;
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _LiveStatCard({
    required this.stream,
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
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(height: 8),
            StreamBuilder<int>(
              stream: stream,
              builder: (_, snap) => Text(
                '${snap.data ?? 0}',
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _C.textDark,
                    height: 1),
              ),
            ),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: _C.textMid,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Section Card
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SectionCard(
      {required this.title, required this.icon, required this.child});

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
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                        color: _C.teal.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, size: 16, color: _C.tealDark),
                  ),
                  const SizedBox(width: 10),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _C.textDark)),
                ],
              ),
            ),
            Divider(color: _C.divider, height: 1, thickness: 1),
            Padding(padding: const EdgeInsets.all(14), child: child),
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
  final String displayName;
  final DateTime? createdAt;

  const _AccountInfo(
      {required this.email, required this.displayName, this.createdAt});

  @override
  Widget build(BuildContext context) {
    final memberSince =
        createdAt != null ? AppHelpers.formatDateOnly(createdAt!) : '—';
    return Column(
      children: [
        _InfoRow(
            icon: Icons.person_rounded,
            label: 'Display Name',
            value: displayName),
        const SizedBox(height: 10),
        _InfoRow(icon: Icons.email_rounded, label: 'Email', value: email),
        const SizedBox(height: 10),
        _InfoRow(
            icon: Icons.calendar_today_rounded,
            label: 'Admin Since',
            value: memberSince),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Admin Permissions Card
// ─────────────────────────────────────────────
class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard();

  @override
  Widget build(BuildContext context) {
    const permissions = [
      'Approve / Reject toilet requests',
      'Review and dismiss user reports',
      'Delete existing toilets',
      'View all registered users',
    ];
    return Column(
      children: permissions.map((label) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: _C.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13,
                        color: _C.textDark,
                        fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────
// Info Row
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: _C.fieldFill, borderRadius: BorderRadius.circular(8)),
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
        reverseDuration: const Duration(milliseconds: 220));
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
              Text('Log Out',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _C.red)),
            ],
          ),
        ),
      ),
    );
  }
}

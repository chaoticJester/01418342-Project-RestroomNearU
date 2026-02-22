import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/services/user_firestore.dart';
import 'package:restroom_near_u/models/user_model.dart';
import 'package:restroom_near_u/pages/admin/admin_request_page.dart';
import 'package:restroom_near_u/pages/admin/admin_profile_page.dart';

// ─────────────────────────────────────────────
// Design tokens (ตรงกับทั้ง project)
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFFCF9EA);
  static const card      = Color(0xFFF7F4E6);
  static const teal      = Color(0xFFBADFDB);
  static const tealDark  = Color(0xFF7BBFBA);
  static const orange    = Color(0xFFE8753D);
  static const green     = Color(0xFF34A853);
  static const red       = Color(0xFFB3261E);
  static const redLight  = Color(0xFFEF4444);
  static const textDark  = Color(0xFF1C1B1F);
  static const textMid   = Color(0xFF6B6874);
  static const textLight = Color(0xFFAEABB8);
  static const divider   = Color(0xFFECE9DA);
  static const fieldFill = Color(0xFFEEEBDA);
  static const adminGold = Color(0xFFF0A500);
}

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  UserModel? _adminUser;

  int _pendingRequests = 0;
  int _reportsToReview = 0;
  int _totalToilets   = 0;
  int _activeUsers    = 0;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Recent Activity (mock)
  final List<Map<String, dynamic>> _recentActivity = [
    {'user': 'Pheeraphat Jumnong', 'action': 'submitted new toilet',        'time': '5 min ago', 'color': Color(0xFFE8753D)},
    {'user': 'Admin',              'action': 'approved new toilet request', 'time': '8 min ago', 'color': Color(0xFF34A853)},
    {'user': 'Admin',              'action': 'deleted fake toilet',         'time': '12 min ago','color': Color(0xFFB3261E)},
    {'user': 'Admin',              'action': 'banned user @pasulol',        'time': '20 min ago','color': Color(0xFFB3261E)},
    {'user': 'Somchai Dee',        'action': 'submitted new toilet',        'time': '1 hr ago',  'color': Color(0xFFE8753D)},
  ];

  // Most reviewed (mock)
  final List<Map<String, dynamic>> _topToilets = [
    {'name': 'Siam Paragon 3F',      'location': 'Siam Paragon',   'rating': 5.0, 'reviews': 189},
    {'name': 'CentralWorld B1',      'location': 'CentralWorld',   'rating': 4.8, 'reviews': 152},
    {'name': 'MBK 4F East Wing',     'location': 'MBK Center',     'rating': 4.7, 'reviews': 134},
    {'name': 'Terminal21 2F',        'location': 'Terminal 21',    'rating': 4.6, 'reviews': 121},
    {'name': 'Icon Siam 1F',         'location': 'Icon Siam',      'rating': 4.5, 'reviews': 98},
    {'name': 'Emporium 3F',          'location': 'The Emporium',   'rating': 4.4, 'reviews': 87},
  ];

  // Trending locations (mock)
  final List<Map<String, dynamic>> _trendingLocations = [
    {'name': 'Siam Area',     'searches': 1234, 'trend': 12, 'up': true},
    {'name': 'Sukhumvit',     'searches': 987,  'trend': 8,  'up': true},
    {'name': 'Silom',         'searches': 856,  'trend': 5,  'up': false},
    {'name': 'Chatuchak',     'searches': 743,  'trend': 3,  'up': false},
    {'name': 'Siam Paragon',  'searches': 698,  'trend': 15, 'up': true},
    {'name': 'Asiatique',     'searches': 512,  'trend': 7,  'up': true},
  ];

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.03), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _loadData();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userModel = await _userService.getUserById(user.uid);
      if (mounted) setState(() => _adminUser = userModel);
    }

    final toiletsSnap  = await FirebaseFirestore.instance.collection('restrooms').get();
    final usersSnap    = await FirebaseFirestore.instance.collection('users').get();
    final pendingSnap  = await FirebaseFirestore.instance
        .collection('restrooms').where('status', isEqualTo: 'pending').get();
    final reportsSnap  = await FirebaseFirestore.instance
        .collection('reports').where('reviewed', isEqualTo: false).get();

    if (mounted) {
      setState(() {
        _totalToilets    = toiletsSnap.size;
        _activeUsers     = usersSnap.size;
        _pendingRequests = pendingSnap.size;
        _reportsToReview = reportsSnap.size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 20),
                    _buildStatCards(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Recent Activity', Icons.history_rounded),
                    const SizedBox(height: 10),
                    _buildRecentActivity(),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Analytics', Icons.bar_chart_rounded),
                    const SizedBox(height: 10),
                    _buildBottomPanels(),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: _C.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _adminUser?.email ?? 'RestroomNearU Management',
                style: const TextStyle(fontSize: 12, color: _C.textMid),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Admin name + avatar
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, a, __) => const AdminProfilePage(),
                transitionDuration: const Duration(milliseconds: 380),
                transitionsBuilder: (_, a, __, child) => SlideTransition(
                  position: Tween<Offset>(
                          begin: const Offset(1.0, 0.0), end: Offset.zero)
                      .animate(CurvedAnimation(
                          parent: a, curve: Curves.easeOutCubic)),
                  child: child,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _adminUser?.displayName ?? 'Admin',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _C.adminGold.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'ADMIN',
                      style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          color: _C.adminGold,
                          letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _C.teal.withOpacity(0.35),
                  border: Border.all(color: _C.adminGold.withOpacity(0.6), width: 2),
                ),
                child: const Icon(Icons.person_rounded,
                    size: 22, color: _C.tealDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Stat Cards ────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final stats = [
      {
        'label': 'Pending Requests',
        'value': _pendingRequests,
        'color': _C.orange,
        'icon': Icons.access_time_rounded,
        'route': '/admin_requests',
        'bgColor': _C.orange.withOpacity(0.1),
      },
      {
        'label': 'Reports to Review',
        'value': _reportsToReview,
        'color': _C.redLight,
        'icon': Icons.flag_rounded,
        'route': '/admin_reports',
        'bgColor': _C.redLight.withOpacity(0.1),
      },
      {
        'label': 'Total Toilets',
        'value': _totalToilets,
        'color': _C.green,
        'icon': Icons.wc_rounded,
        'route': '/admin_toilets',
        'bgColor': _C.green.withOpacity(0.1),
      },
      {
        'label': 'Active Users',
        'value': _activeUsers,
        'color': _C.tealDark,
        'icon': Icons.people_rounded,
        'route': null,
        'bgColor': _C.teal.withOpacity(0.25),
      },
    ];

    return Column(
      children: stats.map((stat) {
        final color    = stat['color'] as Color;
        final bgColor  = stat['bgColor'] as Color;
        final route    = stat['route'] as String?;
        return _StatRow(
          label:    stat['label'] as String,
          value:    stat['value'] as int,
          icon:     stat['icon'] as IconData,
          color:    color,
          bgColor:  bgColor,
          onTap:    route != null
              ? () => Navigator.pushNamed(context, route)
              : null,
        );
      }).toList(),
    );
  }

  // ── Section title ─────────────────────────────────────────────────────
  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: _C.teal.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: _C.tealDark),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _C.textDark),
        ),
      ],
    );
  }

  // ── Recent Activity ───────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Container(
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: _recentActivity.asMap().entries.map((e) {
          final isLast = e.key == _recentActivity.length - 1;
          return Column(
            children: [
              _ActivityRow(activity: e.value),
              if (!isLast)
                Divider(
                    color: _C.divider,
                    height: 1,
                    thickness: 1,
                    indent: 46,
                    endIndent: 14),
            ],
          );
        }).toList(),
      ),
    );
  }

  // ── Bottom Panels ─────────────────────────────────────────────────────
  Widget _buildBottomPanels() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildMostReviewedPanel()),
        const SizedBox(width: 12),
        Expanded(child: _buildTrendingLocationsPanel()),
      ],
    );
  }

  Widget _buildMostReviewedPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(Icons.chat_bubble_outline_rounded,
                  size: 13, color: _C.tealDark),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Most Reviewed',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('This week',
              style: TextStyle(fontSize: 9, color: _C.textLight)),
          const SizedBox(height: 10),
          ..._topToilets.map((t) => _TopToiletRow(toilet: t)),
        ],
      ),
    );
  }

  Widget _buildTrendingLocationsPanel() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 13, color: _C.tealDark),
              const SizedBox(width: 5),
              const Expanded(
                child: Text(
                  'Trending Areas',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          const Text('Most searched',
              style: TextStyle(fontSize: 9, color: _C.textLight)),
          const SizedBox(height: 10),
          ..._trendingLocations.map((l) => _TrendingRow(location: l)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Stat Row card
// ─────────────────────────────────────────────
class _StatRow extends StatefulWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback? onTap;

  const _StatRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.onTap,
  });

  @override
  State<_StatRow> createState() => _StatRowState();
}

class _StatRowState extends State<_StatRow>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scale = Tween(begin: 1.0, end: 0.97)
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
      onTapDown: widget.onTap != null ? (_) => _ctrl.forward() : null,
      onTapUp: widget.onTap != null
          ? (_) {
              _ctrl.reverse();
              HapticFeedback.selectionClick();
              widget.onTap!();
            }
          : null,
      onTapCancel: widget.onTap != null ? () => _ctrl.reverse() : null,
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          child: Row(
            children: [
              // Left accent bar
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 14),
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 20),
              ),
              const SizedBox(width: 14),
              // Label
              Expanded(
                child: Text(
                  widget.label,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _C.textDark),
                ),
              ),
              // Value
              Text(
                '${widget.value}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: widget.color,
                ),
              ),
              if (widget.onTap != null) ...[
                const SizedBox(width: 8),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: _C.textLight),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Activity Row
// ─────────────────────────────────────────────
class _ActivityRow extends StatelessWidget {
  final Map<String, dynamic> activity;
  const _ActivityRow({required this.activity});

  @override
  Widget build(BuildContext context) {
    final dotColor = activity['color'] as Color;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: dotColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.circle, size: 8, color: dotColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                        fontSize: 12, color: _C.textDark),
                    children: [
                      TextSpan(
                        text: activity['user'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      TextSpan(
                          text: '  ${activity['action']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time'] as String,
                  style: const TextStyle(fontSize: 10, color: _C.textLight),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Top Toilet Row
// ─────────────────────────────────────────────
class _TopToiletRow extends StatelessWidget {
  final Map<String, dynamic> toilet;
  const _TopToiletRow({required this.toilet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: _C.fieldFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    toilet['name'] as String,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    toilet['location'] as String,
                    style: const TextStyle(
                        fontSize: 8, color: _C.textLight),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 9, color: _C.orange),
                    const SizedBox(width: 2),
                    Text(
                      '${toilet['rating']}',
                      style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: _C.textDark),
                    ),
                  ],
                ),
                Text(
                  '${toilet['reviews']} reviews',
                  style: const TextStyle(
                      fontSize: 7, color: _C.textLight),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Trending Location Row
// ─────────────────────────────────────────────
class _TrendingRow extends StatelessWidget {
  final Map<String, dynamic> location;
  const _TrendingRow({required this.location});

  @override
  Widget build(BuildContext context) {
    final isUp       = location['up'] as bool;
    final trendColor = isUp ? _C.green : _C.red;
    final trendBg    = isUp
        ? _C.green.withOpacity(0.12)
        : _C.red.withOpacity(0.12);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          color: _C.fieldFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.location_on_rounded,
                size: 11, color: _C.textLight),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location['name'] as String,
                    style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark),
                  ),
                  Text(
                    '${location['searches']} searches',
                    style: const TextStyle(
                        fontSize: 8, color: _C.textLight),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: trendBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isUp
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 8,
                    color: trendColor,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    isUp
                        ? '+${location['trend']}%'
                        : '-${location['trend']}%',
                    style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        color: trendColor),
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

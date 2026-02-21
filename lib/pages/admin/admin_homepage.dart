import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/services/user_firestore.dart';
import 'package:restroom_near_u/models/user_model.dart';
import 'package:restroom_near_u/pages/admin/admin_request_page.dart';
import 'package:restroom_near_u/pages/admin/admin_profile_page.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  final UserService _userService = UserService();
  UserModel? _adminUser;

  // Stats
  int _pendingRequests = 0;
  int _reportsToReview = 0;
  int _totalToilets = 0;
  int _activeUsers = 0;

  // Recent Activity (mock for now)
  final List<Map<String, dynamic>> _recentActivity = [
    {'user': 'Pheeraphat Jumnong', 'action': 'submitted new toilet', 'time': '5 min ago', 'color': Color(0xFFF97316)},
    {'user': 'Admin', 'action': 'approved new toilet request', 'time': '5 min ago', 'color': Color(0xFF10B981)},
    {'user': 'Admin', 'action': 'deleted fake toilet', 'time': '5 min ago', 'color': Color(0xFFEF4444)},
    {'user': 'Admin', 'action': 'banned user @pasulol', 'time': '5 min ago', 'color': Color(0xFFEF4444)},
    {'user': 'Pheeraphat Jumnong', 'action': 'submitted new toilet', 'time': '5 min ago', 'color': Color(0xFFF97316)},
  ];

  // Most reviewed toilets (mock)
  final List<Map<String, dynamic>> _topToilets = [
    {'name': 'Siam Paragon 3F Restroom', 'location': 'Siam Paragon', 'rating': 5.0, 'reviews': 189},
    {'name': 'Siam Paragon 3F Restroom', 'location': 'Siam Paragon', 'rating': 5.0, 'reviews': 189},
    {'name': 'Siam Paragon 3F Restroom', 'location': 'Siam Paragon', 'rating': 5.0, 'reviews': 189},
    {'name': 'Siam Paragon 3F Restroom', 'location': 'Siam Paragon', 'rating': 5.0, 'reviews': 189},
    {'name': 'Siam Paragon 3F Restroom', 'location': 'Siam Paragon', 'rating': 5.0, 'reviews': 189},
    {'name': 'Siam Paragon 3F Restroom', 'location': 'Siam Paragon', 'rating': 5.0, 'reviews': 189},
  ];

  // Trending locations (mock)
  final List<Map<String, dynamic>> _trendingLocations = [
    {'name': 'Siam Area', 'searches': 1234, 'trend': 12, 'up': true},
    {'name': 'Sukhumvit', 'searches': 1234, 'trend': 12, 'up': true},
    {'name': 'Silom', 'searches': 1234, 'trend': 12, 'up': false},
    {'name': 'Chatuchak', 'searches': 1234, 'trend': 12, 'up': false},
    {'name': 'Siam Paragon', 'searches': 1234, 'trend': 12, 'up': true},
    {'name': 'Siam Paragon', 'searches': 1234, 'trend': 12, 'up': true},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userModel = await _userService.getUserById(user.uid);
      setState(() => _adminUser = userModel);
    }

    // Load real counts from Firestore
    final toiletsSnap = await FirebaseFirestore.instance.collection('restrooms').get();
    final usersSnap = await FirebaseFirestore.instance.collection('users').get();
    final pendingSnap = await FirebaseFirestore.instance
        .collection('restrooms')
        .where('status', isEqualTo: 'pending')
        .get();
    final reportsSnap = await FirebaseFirestore.instance
        .collection('reports')
        .where('reviewed', isEqualTo: false)
        .get();

    setState(() {
      _totalToilets = toiletsSnap.size;
      _activeUsers = usersSnap.size;
      _pendingRequests = pendingSnap.size;
      _reportsToReview = reportsSnap.size;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              _buildStatCards(),
              const SizedBox(height: 20),
              _buildRecentActivity(),
              const SizedBox(height: 16),
              _buildBottomPanels(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              const Text(
                'RestroomNearU Management',
                style: TextStyle(fontSize: 11, color: Colors.black54),
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _adminUser?.displayName ?? 'Admin User',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
            Text(
              _adminUser?.email ?? 'admin@restroomnearu.com',
              style: const TextStyle(fontSize: 9, color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (_, a, __) => const AdminProfilePage(),
              transitionDuration: const Duration(milliseconds: 380),
              transitionsBuilder: (_, a, __, child) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1.0, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
                child: child,
              ),
            ),
          ),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFBADFDB),
            child: const Icon(Icons.person, size: 18, color: Color(0xFF7BBFBA)),
          ),
        ),
      ],
    );
  }

  // ─── Stat Cards ──────────────────────────────────────────────────────────
  Widget _buildStatCards() {
    final stats = [
      {'label': 'Pending Requests', 'value': _pendingRequests, 'color': const Color(0xFFF97316), 'icon': Icons.access_time, 'route': '/admin_requests'},
      {'label': 'Report to Review', 'value': _reportsToReview, 'color': const Color(0xFFEF4444), 'icon': Icons.flag_outlined, 'route': '/admin_reports'},
      {'label': 'Total Toilets', 'value': _totalToilets, 'color': const Color(0xFF10B981), 'icon': Icons.location_on_outlined, 'route': '/admin_toilets'},
      {'label': 'Active Users', 'value': _activeUsers, 'color': const Color(0xFF3B82F6), 'icon': Icons.people_outline, 'route': null},
    ];

    return Column(
      children: stats.map((stat) {
        final color = stat['color'] as Color;
        final route = stat['route'] as String?;
        return GestureDetector(
          onTap: route != null ? () => Navigator.pushNamed(context, route) : null,
          child: Container(
          margin: const EdgeInsets.only(bottom: 7),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: Stack(
            children: [
              // Colored left accent bar
              Positioned(
                left: 0, top: 0, bottom: 0,
                child: Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Icon(stat['icon'] as IconData, color: color, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stat['label'] as String,
                        style: const TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ),
                    Text(
                      '${stat['value']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      }).toList(),
    );
  }

  // ─── Recent Activity ─────────────────────────────────────────────────────
  Widget _buildRecentActivity() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9EA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Activity',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black),
          ),
          const SizedBox(height: 10),
          ..._recentActivity.map((activity) => _buildActivityRow(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityRow(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: activity['color'] as Color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 11, color: Colors.black),
                    children: [
                      TextSpan(
                        text: activity['user'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      TextSpan(text: ' ${activity['action']}'),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity['time'] as String,
                  style: const TextStyle(fontSize: 10, color: Colors.black45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Panels ───────────────────────────────────────────────────────
  Widget _buildBottomPanels() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _buildMostReviewedPanel()),
        const SizedBox(width: 5),
        Expanded(child: _buildTrendingLocationsPanel()),
      ],
    );
  }

  Widget _buildMostReviewedPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9EA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.chat_bubble_outline, size: 10, color: Colors.black54),
              SizedBox(width: 3),
              Expanded(
                child: Text(
                  'Most Reviewed Toilets(This Week)',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._topToilets.map((toilet) => _buildToiletRow(toilet)),
        ],
      ),
    );
  }

  Widget _buildToiletRow(Map<String, dynamic> toilet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  toilet['name'] as String,
                  style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: Colors.black),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  toilet['location'] as String,
                  style: const TextStyle(fontSize: 5, color: Colors.black45),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.star, size: 8, color: Color(0xFFF59E0B)),
          const SizedBox(width: 2),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${toilet['rating']}',
                style: const TextStyle(fontSize: 6, color: Colors.black87),
              ),
              Text(
                '${toilet['reviews']} reviews',
                style: const TextStyle(fontSize: 4, color: Colors.black45),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingLocationsPanel() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFFCF9EA),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 3, offset: const Offset(0, 1)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.trending_up, size: 10, color: Colors.black54),
              SizedBox(width: 3),
              Expanded(
                child: Text(
                  'Trending Locations (Most Searched)',
                  style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Colors.black),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._trendingLocations.map((loc) => _buildLocationRow(loc)),
        ],
      ),
    );
  }

  Widget _buildLocationRow(Map<String, dynamic> loc) {
    final isUp = loc['up'] as bool;
    final trendColor = isUp ? const Color(0xFF34A853) : const Color(0xFFDC3545);
    final trendBg = isUp ? const Color(0x4D34A853) : const Color(0x4DDC3545);

    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        children: [
          const Icon(Icons.location_on, size: 10, color: Colors.black45),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  loc['name'] as String,
                  style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.black),
                ),
                Text(
                  '${loc['searches']} searches this week',
                  style: const TextStyle(fontSize: 5, color: Colors.black45),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(
              color: trendBg,
              borderRadius: BorderRadius.circular(2),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isUp ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 7,
                  color: trendColor,
                ),
                const SizedBox(width: 1),
                Text(
                  isUp ? '+${loc['trend']}%' : '-${loc['trend']}%',
                  style: TextStyle(
                    fontSize: 6,
                    fontWeight: FontWeight.w800,
                    color: trendColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

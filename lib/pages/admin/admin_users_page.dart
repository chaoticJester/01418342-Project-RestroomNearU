import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/user_model.dart';
import 'package:intl/intl.dart';

// ─────────────────────────────────────────────
// Design tokens (matches project palette)
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

// ─────────────────────────────────────────────
// Filter enum
// ─────────────────────────────────────────────
enum _Filter { all, active, suspended, banned }

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  _Filter _filter = _Filter.all;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _enterCtrl.dispose();
    super.dispose();
  }

  List<UserModel> _applyFilters(List<UserModel> users) {
    return users.where((u) {
      final matchesSearch =
          u.displayName.toLowerCase().contains(_searchQuery) ||
          u.email.toLowerCase().contains(_searchQuery);
      final matchesFilter = switch (_filter) {
        _Filter.all       => true,
        _Filter.active    => !u.isBanned && !u.isSuspended,
        _Filter.suspended => u.isSuspended,
        _Filter.banned    => u.isBanned,
      };
      return matchesSearch && matchesFilter;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        appBar: AppBar(
          title: const Text(
            'Manage Users',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: _C.textDark,
            ),
          ),
          backgroundColor: _C.bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: _C.textDark, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: _C.tealDark),
              );
            }

            final allUsers = snapshot.data!.docs
                .map((doc) =>
                    UserModel.fromMap(doc.data() as Map<String, dynamic>))
                .where((u) => u.role != Role.admin)
                .toList();

            final totalCount     = allUsers.length;
            final bannedCount    = allUsers.where((u) => u.isBanned).length;
            final suspendedCount = allUsers.where((u) => u.isSuspended).length;
            final activeCount    = totalCount - bannedCount - suspendedCount;

            final filtered = _applyFilters(allUsers);

            return FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  // ── Summary strip ──────────────────────────────────
                  _SummaryStrip(
                    total: totalCount,
                    active: activeCount,
                    suspended: suspendedCount,
                    banned: bannedCount,
                  ),
                  const SizedBox(height: 4),

                  // ── Search bar ─────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _searchQuery = v.toLowerCase()),
                      decoration: InputDecoration(
                        hintText: 'Search by name or email…',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: _C.textLight),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 18, color: _C.textLight),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    size: 16, color: _C.textLight),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: _C.fieldFill,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),

                  // ── Filter chips ───────────────────────────────────
                  _FilterRow(
                    current: _filter,
                    counts: {
                      _Filter.all:       totalCount,
                      _Filter.active:    activeCount,
                      _Filter.suspended: suspendedCount,
                      _Filter.banned:    bannedCount,
                    },
                    onChanged: (f) => setState(() => _filter = f),
                  ),

                  const SizedBox(height: 8),

                  // ── User list ──────────────────────────────────────
                  Expanded(
                    child: filtered.isEmpty
                        ? _EmptyState(query: _searchQuery)
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            itemCount: filtered.length,
                            itemBuilder: (ctx, i) =>
                                _UserCard(user: filtered[i]),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Summary strip (4 quick-stat pills)
// ─────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  final int total, active, suspended, banned;
  const _SummaryStrip({
    required this.total,
    required this.active,
    required this.suspended,
    required this.banned,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatPill(label: 'Total',     value: total,     color: _C.tealDark),
          _Divider(),
          _StatPill(label: 'Active',    value: active,    color: _C.green),
          _Divider(),
          _StatPill(label: 'Suspended', value: suspended, color: _C.orange),
          _Divider(),
          _StatPill(label: 'Banned',    value: banned,    color: _C.redLight),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 28, color: _C.divider);
}

class _StatPill extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatPill(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: _C.textMid)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Filter chips row
// ─────────────────────────────────────────────
class _FilterRow extends StatelessWidget {
  final _Filter current;
  final Map<_Filter, int> counts;
  final ValueChanged<_Filter> onChanged;
  const _FilterRow(
      {required this.current,
      required this.counts,
      required this.onChanged});

  static const _labels = {
    _Filter.all:       'All',
    _Filter.active:    'Active',
    _Filter.suspended: 'Suspended',
    _Filter.banned:    'Banned',
  };

  static const _colors = {
    _Filter.all:       _C.tealDark,
    _Filter.active:    _C.green,
    _Filter.suspended: _C.orange,
    _Filter.banned:    _C.redLight,
  };

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: _Filter.values.map((f) {
          final selected = f == current;
          final color    = _colors[f]!;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onChanged(f);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(right: 8),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: selected ? color : _C.fieldFill,
                borderRadius: BorderRadius.circular(99),
                border: Border.all(
                  color: selected ? color : _C.divider,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _labels[f]!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : _C.textMid,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withOpacity(0.25)
                          : _C.divider,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '${counts[f]}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: selected ? Colors.white : _C.textMid,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// User card
// ─────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  // Badge colour per level
  Color _levelColor(int level) {
    switch (level) {
      case 1: return _C.textLight;
      case 2: return _C.tealDark;
      case 3: return _C.green;
      case 4: return _C.orange;
      default: return _C.adminGold;
    }
  }

  // Status indicator
  Widget _statusBadge() {
    if (user.isBanned) {
      return _Badge(label: 'BANNED', color: _C.redLight);
    }
    if (user.isSuspended) {
      final until = DateFormat('d MMM, HH:mm').format(user.suspendedUntil!);
      return _Badge(label: 'SUSPENDED · $until', color: _C.orange);
    }
    return _Badge(label: 'ACTIVE', color: _C.green);
  }

  void _showActions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: _C.divider,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _C.teal.withOpacity(0.3),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? const Icon(Icons.person_rounded,
                            color: _C.tealDark, size: 22)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                color: _C.textDark)),
                        Text(user.email,
                            style: const TextStyle(
                                fontSize: 11, color: _C.textMid)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: _C.divider, height: 1),
              const SizedBox(height: 8),
              // Ban / Unban
              _ActionTile(
                icon: user.isBanned
                    ? Icons.undo_rounded
                    : Icons.gavel_rounded,
                label:
                    user.isBanned ? 'Unban User' : 'Permanently Ban User',
                color: _C.redLight,
                onTap: () async {
                  Navigator.pop(ctx);
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.userId)
                      .update({'isBanned': !user.isBanned});
                },
              ),
              // Suspend / Lift
              if (!user.isBanned)
                _ActionTile(
                  icon: user.isSuspended
                      ? Icons.lock_open_rounded
                      : Icons.timer_outlined,
                  label: user.isSuspended
                      ? 'Lift Suspension'
                      : 'Suspend for 24 Hours',
                  color: _C.orange,
                  onTap: () async {
                    Navigator.pop(ctx);
                    final until = user.isSuspended
                        ? null
                        : DateTime.now().add(const Duration(hours: 24));
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.userId)
                        .update({
                      'suspendedUntil': until != null
                          ? Timestamp.fromDate(until)
                          : null,
                    });
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lvl       = user.level;
    final lvlColor  = _levelColor(lvl);

    return GestureDetector(
      onTap: () => _showActions(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Avatar + level ring ──────────────────────────────────
            Stack(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: lvlColor, width: 2.5),
                  ),
                  child: CircleAvatar(
                    backgroundColor: _C.teal.withOpacity(0.25),
                    backgroundImage: user.photoUrl != null
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null
                        ? const Icon(Icons.person_rounded,
                            color: _C.tealDark, size: 26)
                        : null,
                  ),
                ),
                // Level badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: lvlColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: _C.card, width: 2),
                    ),
                    child: Center(
                      child: Text(
                        '$lvl',
                        style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 12),

            // ── Name, email, badge ───────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          user.displayName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _C.textDark),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _statusBadge(),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(user.email,
                      style: const TextStyle(
                          fontSize: 11, color: _C.textMid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  // ── Stats row ──────────────────────────────────────
                  Row(
                    children: [
                      _MiniStat(
                          icon: Icons.star_rounded,
                          value: '${user.points} pts',
                          color: _C.adminGold),
                      const SizedBox(width: 10),
                      _MiniStat(
                          icon: Icons.rate_review_rounded,
                          value: '${user.totalReviews}',
                          color: _C.tealDark),
                      const SizedBox(width: 10),
                      _MiniStat(
                          icon: Icons.add_location_alt_rounded,
                          value: '${user.totalAdded}',
                          color: _C.green),
                      const Spacer(),
                      // Badge name
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: lvlColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.badgeName,
                          style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: lvlColor),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── More icon ────────────────────────────────────────────
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 2),
              child: Icon(Icons.more_vert_rounded,
                  size: 18, color: _C.textLight),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Mini stat (icon + value)
// ─────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.icon, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: color),
        const SizedBox(width: 3),
        Text(value,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color)),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// Status badge pill
// ─────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.3),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Action tile in bottom sheet
// ─────────────────────────────────────────────
class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(label,
          style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color)),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final String query;
  const _EmptyState({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_search_rounded,
                size: 36, color: _C.tealDark),
          ),
          const SizedBox(height: 16),
          Text(
            query.isEmpty ? 'No users found' : 'No results for "$query"',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _C.textDark),
          ),
          const SizedBox(height: 6),
          const Text('Try adjusting your search or filter',
              style: TextStyle(fontSize: 12, color: _C.textLight)),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:restroom_near_u/models/user_model.dart';
import 'package:restroom_near_u/services/user_firestore.dart';
import 'package:intl/intl.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      appBar: AppBar(
        title: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1C1B1F))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1C1B1F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search by name or email...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final users = snapshot.data!.docs
                    .map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>))
                    .where((u) => u.role != Role.admin) // Hide other admins
                    .where((u) => u.displayName.toLowerCase().contains(_searchQuery) || u.email.toLowerCase().contains(_searchQuery))
                    .toList();

                if (users.isEmpty) return const Center(child: Text('No users found.'));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: users.length,
                  itemBuilder: (context, i) => _UserCard(user: users[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  const _UserCard({required this.user});

  void _showActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(user.isBanned ? Icons.undo_rounded : Icons.gavel_rounded, color: Colors.red),
              title: Text(user.isBanned ? 'Unban User' : 'Permanently Ban User'),
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseFirestore.instance.collection('users').doc(user.userId).update({'isBanned': !user.isBanned});
              },
            ),
            if (!user.isBanned)
              ListTile(
                leading: const Icon(Icons.timer_outlined, color: Colors.orange),
                title: Text(user.isSuspended ? 'Lift Suspension' : 'Suspend for 24 Hours'),
                onTap: () async {
                  Navigator.pop(ctx);
                  final until = user.isSuspended ? null : DateTime.now().add(const Duration(hours: 24));
                  await FirebaseFirestore.instance.collection('users').doc(user.userId).update({
                    'suspendedUntil': until != null ? Timestamp.fromDate(until) : null,
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFFBADFDB),
          backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
          child: user.photoUrl == null ? const Icon(Icons.person, color: Color(0xFF7BBFBA)) : null,
        ),
        title: Text(user.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            if (user.isBanned)
              const Text('BANNED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10))
            else if (user.isSuspended)
              Text('SUSPENDED until ${DateFormat('HH:mm').format(user.suspendedUntil!)}', 
                  style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 10)),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showActions(context),
        ),
      ),
    );
  }
}

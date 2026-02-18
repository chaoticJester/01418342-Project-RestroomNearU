import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/restroom_model.dart';
import '../../services/restroom_service.dart';
import 'restroom_detail_page.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  static final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(13.8476, 100.5696),
    zoom: 16.0,
  );

  late List<RestroomModel> restrooms;

  @override
  void initState() {
    super.initState();
    _loadRestrooms();
  }

  void _loadRestrooms() {
    restrooms = RestroomService.getMockRestrooms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ------------------------------------
          // 1. Map Section (Bottom Layer)
          // ------------------------------------
          GoogleMap(
            initialCameraPosition: _kGooglePlex,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {},
          ),

          // ------------------------------------
          // 2. Add New Restroom Button (Top Right)
          // ------------------------------------
          Positioned(
            top: 60,
            right: 20,
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/add_new_restroom'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFB2D8D8),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(blurRadius: 5, color: Colors.black26)],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20),
                    SizedBox(width: 8),
                    Text("Add New Restroom", style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),

          // ------------------------------------
          // 3. Bottom Sheet with buttons baked in
          // ------------------------------------
          DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.9,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFFFFBE6),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Column(
                  children: [
                    // ── Buttons row + drag handle ──────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          // Profile button (left)
                          _MapFloatingButton(
                            onTap: () => Navigator.pushNamed(context, '/profile'),
                            child: const Icon(
                              Icons.person_outline_rounded,
                              size: 22,
                              color: Color(0xFF49454F),
                            ),
                          ),

                          // Drag handle (center)
                          Expanded(
                            child: Center(
                              child: Container(
                                width: 50,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),

                          // Navigation button (right)
                          _MapFloatingButton(
                            onTap: () {
                              // TODO: center map on user location
                            },
                            child: const Icon(
                              Icons.navigation_rounded,
                              size: 22,
                              color: Color(0xFF49454F),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Search Bar ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search Maps",
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: const Color(0xFFCDE8E5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ── Restroom List ──────────────────────────────
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        itemCount: restrooms.length,
                        separatorBuilder: (context, index) =>
                            Divider(color: Colors.grey[300]),
                        itemBuilder: (context, index) =>
                            _buildRestroomItem(restrooms[index]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRestroomItem(RestroomModel restroom) {
    final isOpen = RestroomService.isOpen(restroom);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestroomDetailPage(restroom: restroom),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name and description
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restroom.restroomName,
                    style: const TextStyle(
                      fontFamily: 'Serif',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    restroom.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Rating
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.orange, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    restroom.avgRating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // Status and price
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    restroom.isFree ? "Price : Free" : "Price : Paid",
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isOpen ? "Open" : "Closed",
                    style: TextStyle(color: Colors.red[300], fontSize: 12),
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
// Reusable floating circular button for the map
// ─────────────────────────────────────────────
class _MapFloatingButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;

  const _MapFloatingButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFFCF9EA),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(child: child),
      ),
    );
  }
}

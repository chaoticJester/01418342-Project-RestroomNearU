import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/restroom_model.dart';
import '../../services/restroom_service.dart';
import '../restroom_detail_page.dart';

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

  // Get list of restrooms from service
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
            //myLocationEnabled: true, 
            zoomControlsEnabled: false, 
            onMapCreated: (GoogleMapController controller) {
              // Store controller for later use
            },
          ),

          // ------------------------------------
          // 2. Add New Restroom Button (Top Right)
          // ------------------------------------
          Positioned(
            top: 60, 
            right: 20, 
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(context, '/add_new_restroom');
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFFB2D8D8), 
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(blurRadius: 5, color: Colors.black26)],
                ),
                child: Row(
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
          // 3. Bottom List Sheet (Top Layer)
          // ------------------------------------
          DraggableScrollableSheet(
            initialChildSize: 0.4, 
            minChildSize: 0.2, 
            maxChildSize: 0.9, 
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFFFBE6), 
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
                ),
                child: Column(
                  children: [
                    // Handle bar
                    SizedBox(height: 10),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    
                    // Search Bar
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search Maps",
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Color(0xFFCDE8E5), 
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 0),
                        ),
                      ),
                    ),

                    // Restroom List
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController, 
                        padding: EdgeInsets.zero,
                        itemCount: restrooms.length,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          return _buildRestroomItem(restrooms[index]);
                        },
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
    // Calculate if restroom is currently open
    final isOpen = RestroomService.isOpen(restroom);
    final distance = RestroomService.getDistance(restroom.latitude, restroom.longitude);

    return InkWell(
      onTap: () {
        // Navigate to detail page with restroom model
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
                    style: TextStyle(
                      fontFamily: 'Serif', 
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    restroom.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            // Rating stars
            Expanded(
              flex: 1,
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.orange, size: 16),
                  SizedBox(width: 4),
                  Text(
                    restroom.avgRating.toStringAsFixed(1),
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                  SizedBox(height: 4),
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

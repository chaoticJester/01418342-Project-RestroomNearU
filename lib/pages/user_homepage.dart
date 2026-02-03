import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ------------------------------------
          // 1. ส่วนแผนที่ (Layer ล่างสุด)
          // ------------------------------------
          GoogleMap(
            initialCameraPosition: _kGooglePlex,
            //myLocationEnabled: true, 
            zoomControlsEnabled: false, 
            onMapCreated: (GoogleMapController controller) {
              // เก็บ controller ไว้ใช้ภายหลังได้
            },
          ),

          // ------------------------------------
          // 2. ปุ่ม Add New Restroom (มุมขวาบน)
          // ------------------------------------
          Positioned(
            top: 60, 
            right: 20, 
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

          // ------------------------------------
          // 3. ส่วนรายการด้านล่าง (Layer บนสุด)
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
                    // ขีดเทาๆ ตรงกลาง (Handle)
                    SizedBox(height: 10),
                    Container(
                      width: 50,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    
                    // ช่องค้นหา (Search Bar)
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

                    // รายการห้องน้ำ (ListView)
                    Expanded(
                      child: ListView.separated(
                        controller: scrollController, 
                        padding: EdgeInsets.zero,
                        itemCount: 5,
                        separatorBuilder: (context, index) => Divider(color: Colors.grey[300]),
                        itemBuilder: (context, index) {
                          return _buildRestroomItem();
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

  Widget _buildRestroomItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ชื่อและรายละเอียด
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Engineer 2nd floor toilet",
                  style: TextStyle(
                    fontFamily: 'Serif', 
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Lorem ipsum dolor sit amet.",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // ดาว (Rating)
          Expanded(
            flex: 1,
            child: Row(
              children: [
                Icon(Icons.star, color: Colors.orange, size: 16),
                SizedBox(width: 4),
                Text("5.0", style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),

          // สถานะและราคา
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "Price : Free",
                  style: TextStyle(color: Colors.red[300], fontSize: 12),
                ),
                SizedBox(height: 4),
                Text(
                  "Open", 
                  style: TextStyle(color: Colors.red[300], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
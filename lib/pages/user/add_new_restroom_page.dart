import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:restroom_near_u/models/request_model.dart';
import 'package:restroom_near_u/models/restroom_model.dart';
import 'package:restroom_near_u/services/request_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// ─────────────────────────────────────────────
// Design tokens - Figma inspired theme
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFF5F1E8);  // Warm cream background
  static const card      = Color(0xFFFFFDFA);  // Lighter card surface
  static const pink      = Color(0xFFEC9B9B);  // Soft pink accent
  static const pinkLight = Color(0xFFF5D4D4);  // Light pink for backgrounds
  static const mint      = Color(0xFFA8D5D5);  // Mint/teal accent
  static const mintDark  = Color(0xFF88B5B5);  // Darker mint
  static const orange    = Color(0xFFF5A162);  // Warm orange
  static const textDark  = Color(0xFF2C2C2C);  // Near black
  static const textMid   = Color(0xFF6B6B6B);  // Medium gray
  static const textLight = Color(0xFFA5A5A5);  // Light gray
  static const divider   = Color(0xFFE8E4DB);  // Soft divider
  static const fieldFill = Color(0xFFFFFBF5);  // Input field background
}

class AddNewRestroomPage extends StatefulWidget {
  const AddNewRestroomPage({Key? key}) : super(key: key);

  @override
  State<AddNewRestroomPage> createState() => _AddNewRestroomPageState();
}

class _AddNewRestroomPageState extends State<AddNewRestroomPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController    = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController   = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _currentMapPosition = const LatLng(13.8478, 100.5696);
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _hasLocationPermission = false;

  bool isFree = true;
  bool is24Hours = true;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  // Amenities
  final Map<String, bool> _amenities = {
    'Toilet Paper':          true,
    'Soap':                  true,
    'Hand Dryer':            false,
    'Wheelchair Accessible': true,
    'Baby Changing Station': false,
    'Hot Water':             true,
    'WiFi':                  true,
    'Power Outlet':          true,
  };

  final Map<String, IconData> _amenityIcons = {
    'Toilet Paper':          Icons.dry_cleaning_rounded,
    'Soap':                  Icons.soap_rounded,
    'Hand Dryer':            Icons.air_rounded,
    'Wheelchair Accessible': Icons.accessible_rounded,
    'Baby Changing Station': Icons.child_care_rounded,
    'Hot Water':             Icons.water_drop_rounded,
    'WiFi':                  Icons.wifi_rounded,
    'Power Outlet':          Icons.electric_bolt_rounded,
  };

  List<String> photoUrls = [];
  List<File> _localPhotos = [];   // local files staged before upload
  bool _isUploadingPhotos = false;

  // Entry animation
  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  Future<void> _getInitialLocation() async {
    try {
      // 1. เช็ค GPS และ Permission 
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return; 

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      setState(() {
        _hasLocationPermission = true;
      });

      // 2. ดึงพิกัดปัจจุบัน
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        )
      );
      // 3. อัปเดตตัวแปรตำแหน่ง
      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;
        _currentMapPosition = LatLng(position.latitude, position.longitude);
      });

      // 4. สั่งให้กล้องของแผนที่วิ่งไปที่ตำแหน่งผู้ใช้ทันที
      if (_mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(_currentMapPosition, 16.0),
        );
      }
    } catch (e) {
      print("Error getting initial location: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _enterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fadeAnim  = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

    _getInitialLocation();
  }

  @override
  void dispose() {
    _enterCtrl.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        // Force 24-hour format regardless of device locale
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _C.mint,
              onPrimary: Colors.white,
              surface: _C.bg,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) setState(() => isOpen ? openTime = picked : closeTime = picked);
  }

  /// Format TimeOfDay as HH:mm (24-hour) — e.g. "08:30", "14:00"
  String _formatTime24(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _getCurrentLocation() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Getting current location..."),
        backgroundColor: _C.mint,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadiusGeometry.circular(12)),
      )
    );

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if(!serviceEnabled) throw Exception("Location services are disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if(permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if(permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      if(permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied.");
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        )
      );

      setState(() {
        _selectedLatitude = position.latitude;
        _selectedLongitude = position.longitude;

        _currentMapPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentMapPosition, 16.0),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location found! Lat: ${_selectedLatitude!.toStringAsFixed(4)}...'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: _C.pink,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();

      if (_selectedLatitude == null || _selectedLongitude == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Please set the restroom location first.'),
            backgroundColor: _C.pink,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return; // หยุดการทำงานถ้ายังไม่มีพิกัด
      }

      final User? currentUser = FirebaseAuth.instance.currentUser;
      if(currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Please login to submit a restroom."),
            backgroundColor: _C.pink,
            behavior: SnackBarBehavior.floating,
          )
        );
        return ;
      }
      
      final String currentUserId = currentUser.uid;
      // แสดง SnackBar แจ้งว่ากำลังโหลด
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Submitting request...'),
          backgroundColor: _C.mint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      try {
        // 1. นำข้อมูลจากฟอร์มมาสร้างเป็น RestroomModel ก่อน
        // Pre-generate a doc ID so we can use it for Storage paths
        final docRef = FirebaseFirestore.instance.collection('requests').doc();
        final tempId = docRef.id;
        final String generatedId = FirebaseFirestore.instance.collection('restrooms').doc().id;

        // Upload photos to Firebase Storage (if any)
        List<String> uploadedUrls = [];
        if (_localPhotos.isNotEmpty) {
          setState(() => _isUploadingPhotos = true);
          uploadedUrls = await _uploadPhotos(tempId);
          setState(() => _isUploadingPhotos = false);
        }

        final newRestroom = RestroomModel(
          restroomId: generatedId,
          restroomName: _nameController.text,
          address: _locationController.text,
          latitude: _selectedLatitude!,
          longitude: _selectedLongitude!,
          openTime: openTime != null ? _formatTime24(openTime!) : null,
          closeTime: closeTime != null ? _formatTime24(closeTime!) : null,
          isFree: isFree,
          is24hrs: is24Hours,
          phoneNumber: _phoneController.text,
          amenities: _amenities,
          photos: uploadedUrls,   // real Firebase Storage URLs
          createdBy: currentUserId,
        );

        // 2. นำ RestroomModel มาห่อด้วย RequestModel อีกชั้น
        final newRequest = RequestModel(
          requestId: tempId,
          restroom: newRestroom,
          userId: currentUserId,
          createdAt: Timestamp.now(),
        );

        // 3. ส่งข้อมูลขึ้น Firestore ผ่าน RequestService
        await RequestService().createRequest(newRequest);

        // 4. บันทึกสำเร็จ ให้เด้งกลับไปหน้าก่อนหน้า
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request sent to admin successfully!'),
              backgroundColor: Colors.green, 
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        print("Error submitting request: $e");
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to submit request. Please try again.'),
              backgroundColor: _C.pink,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                // ── Hero header ────────────────────────────
                SliverToBoxAdapter(child: _buildHeroHeader(context)),

                // ── Form body ──────────────────────────────
                SliverToBoxAdapter(
                  child: Form(
                    key: _formKey,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionLabel('Location on Map'),
                          const SizedBox(height: 10),
                          _mapPreview(),
                          const SizedBox(height: 8),
                          _useLocationButton(),
                          const SizedBox(height: 24),

                          _sectionLabel('Restroom Name'),
                          const SizedBox(height: 10),
                          _styledField(
                            controller: _nameController,
                            hint: 'e.g. 2nd Floor Engineering Building',
                            icon: Icons.wc_rounded,
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Please enter a name' : null,
                          ),
                          const SizedBox(height: 20),

                          _sectionLabel('Address'),
                          const SizedBox(height: 10),
                          _styledField(
                            controller: _locationController,
                            hint: 'e.g. Kasetsart University, Bangkok',
                            icon: Icons.location_on_rounded,
                          ),
                          const SizedBox(height: 20),

                          _sectionLabel('Phone Number'),
                          const SizedBox(height: 10),
                          _styledField(
                            controller: _phoneController,
                            hint: '02-123-4567',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 24),

                          _sectionLabel('Price'),
                          const SizedBox(height: 12),
                          _priceToggle(),
                          const SizedBox(height: 24),

                          _sectionLabel('Opening Hours'),
                          const SizedBox(height: 12),
                          _hoursSection(context),
                          const SizedBox(height: 24),

                          _sectionLabel('Amenities'),
                          const SizedBox(height: 12),
                          _amenitiesGrid(),
                          const SizedBox(height: 24),

                          _sectionLabel('Photos'),
                          const SizedBox(height: 12),
                          _photoRow(),
                          const SizedBox(height: 36),

                          _submitButton(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Hero header with back button ──────────────────────────────────────
  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        // Background image placeholder
        Container(
          height: 220,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_C.mint, _C.mintDark],
            ),
          ),
          child: Stack(
            children: [
              // Center icon
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.add_location_alt_rounded,
                        size: 36,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Add New Restroom',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Help others find clean restrooms nearby',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Back button — same style as RestroomDetailPage ──
        Positioned(
          top: 40,
          left: 6,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
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
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back, size: 24, color: _C.textDark),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Section label ─────────────────────────────────────────────────────
  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: _C.textDark,
        letterSpacing: 0.2,
      ),
    );
  }

  // ── Map preview ───────────────────────────────────────────────────────
  Widget _mapPreview() {
    return Container(
      width: double.infinity,
      height: 200, 
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 1. ตัวแผนที่ Google Map
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _currentMapPosition,
                zoom: 16.0,
              ),
              onMapCreated: (controller) => _mapController = controller,
              // เมื่อผู้ใช้เลื่อนแผนที่ ให้อัปเดตตำแหน่งปัจจุบัน
              onCameraMove: (position) {
                _currentMapPosition = position.target;
              },
              // เมื่อผู้ใช้หยุดเลื่อนแผนที่ ให้บันทึกพิกัดลงตัวแปรที่จะส่งฟอร์ม
              onCameraIdle: () {
                setState(() {
                  _selectedLatitude = _currentMapPosition.latitude;
                  _selectedLongitude = _currentMapPosition.longitude;
                });
              },
              zoomControlsEnabled: false,
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: false,
              // Allow map gestures to win over the parent ScrollView
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<EagerGestureRecognizer>(
                  () => EagerGestureRecognizer(),
                ),
              },
            ),
            
            // 2. หมุดตรงกลาง (จะอยู่กับที่เสมอขณะที่แผนที่ขยับ)
            const Padding(
              padding: EdgeInsets.only(bottom: 24), // ดันขึ้นนิดนึงให้ปลายหมุดแตะตรงกลางพอดี
              child: Icon(
                Icons.location_on_rounded, 
                size: 40, 
                color: _C.pink,
              ),
            ),
            
            // 3. จุดวงกลมเงาใต้หมุด (เพื่อความสวยงาม)
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Use current location button ───────────────────────────────────────
  Widget _useLocationButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _getCurrentLocation();
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.orange.withOpacity(0.25), _C.orange.withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _C.orange.withOpacity(0.15),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(Icons.my_location_rounded, size: 15, color: _C.orange),
          ),
          const SizedBox(width: 8),
          const Text(
            'Use Current Location',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: _C.orange,
            ),
          ),
        ],
      ),
    );
  }

  // ── Styled text field ─────────────────────────────────────────────────
  Widget _styledField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: _C.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: _C.textLight),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 18, color: _C.mint),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: _C.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.mint, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _C.pink, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Price toggle ──────────────────────────────────────────────────────
  Widget _priceToggle() {
    return Row(
      children: [
        _toggleChip(
          label: 'Free',
          icon: Icons.money_off_rounded,
          selected: isFree,
          onTap: () => setState(() => isFree = true),
          activeColor: _C.mint,
        ),
        const SizedBox(width: 12),
        _toggleChip(
          label: 'Paid',
          icon: Icons.paid_rounded,
          selected: !isFree,
          onTap: () => setState(() => isFree = false),
          activeColor: _C.pink,
        ),
      ],
    );
  }

  Widget _toggleChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
                  colors: [activeColor.withOpacity(0.22), activeColor.withOpacity(0.08)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: selected ? null : _C.fieldFill,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: activeColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? activeColor : _C.textLight),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? activeColor : _C.textMid,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hours section ─────────────────────────────────────────────────────
  Widget _hoursSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 24 hrs toggle
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => is24Hours = !is24Hours);
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 46,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  gradient: is24Hours
                      ? LinearGradient(
                          colors: [_C.mint, _C.mintDark],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: is24Hours ? null : _C.divider,
                  boxShadow: is24Hours
                      ? [
                          BoxShadow(
                            color: _C.mint.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                  alignment: is24Hours ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Open 24 hours',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: is24Hours ? _C.mint : _C.textMid,
                ),
              ),
            ],
          ),
        ),

        // Open / Close time pickers
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: is24Hours
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(
                    children: [
                      Expanded(child: _timePicker('Open', openTime, () => _selectTime(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _timePicker('Close', closeTime, () => _selectTime(false))),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _timePicker(String label, TimeOfDay? time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _C.fieldFill,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.access_time_rounded, size: 16, color: _C.mint),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 10, color: _C.textLight)),
                Text(
                  time != null ? _formatTime24(time) : '--:--',
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Amenities grid ────────────────────────────────────────────────────
  Widget _amenitiesGrid() {
    final entries = _amenities.entries.toList();
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3.0,
      ),
      itemBuilder: (context, i) {
        final key   = entries[i].key;
        final value = entries[i].value;
        final icon  = _amenityIcons[key] ?? Icons.check_circle_rounded;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _amenities[key] = !value);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              gradient: value
                  ? LinearGradient(
                      colors: [_C.pinkLight, _C.pink.withOpacity(0.15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: value ? null : _C.fieldFill,
              borderRadius: BorderRadius.circular(14),
              boxShadow: value
                  ? [
                      BoxShadow(
                        color: _C.pink.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: value ? _C.pink : _C.textLight,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    key,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: value ? _C.textDark : _C.textLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (value)
                  const Icon(Icons.check_rounded, size: 14, color: _C.pink),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Photo picker helpers ─────────────────────────────────────────
  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _C.bg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _C.divider, borderRadius: BorderRadius.circular(99))),
            const SizedBox(height: 16),
            const Text('Add Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: _C.textDark)),
            const SizedBox(height: 4),
            const Text('Add photos of the restroom',
                style: TextStyle(fontSize: 12, color: _C.textMid)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _PhotoSourceBtn(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  color: _C.mint,
                  onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.camera); },
                ),
                _PhotoSourceBtn(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: _C.orange,
                  onTap: () { Navigator.pop(ctx); _pickPhoto(ImageSource.gallery); },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1200,
      maxHeight: 1200,
    );
    if (picked == null) return;
    setState(() => _localPhotos.add(File(picked.path)));
  }

  void _removePhoto(int index) {
    setState(() => _localPhotos.removeAt(index));
  }

  Future<List<String>> _uploadPhotos(String requestId) async {
    final urls = <String>[];
    for (final file in _localPhotos) {
      final fileName = 'requests/$requestId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance.ref().child(fileName);
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  // ── Photo row ─────────────────────────────────────────────────────────
  Widget _photoRow() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        // Local photo previews with remove button
        ..._localPhotos.asMap().entries.map((e) {
          final i = e.key;
          final file = e.value;
          return Stack(
            children: [
              Container(
                width: 72, height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _C.pinkLight.withOpacity(0.3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(file, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 2, right: 2,
                child: GestureDetector(
                  onTap: () => _removePhoto(i),
                  child: Container(
                    width: 20, height: 20,
                    decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 13, color: Colors.red),
                  ),
                ),
              ),
            ],
          );
        }),

        // Add photo button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            _showPhotoSourceSheet();
          },
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.mint.withOpacity(0.15), _C.mint.withOpacity(0.05)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: _C.mint.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.add_photo_alternate_rounded, size: 26, color: _C.mint),
                SizedBox(height: 4),
                Text('Add', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _C.mint)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Submit button ─────────────────────────────────────────────────────
  Widget _submitButton() {
    return _SpringButton(
      onTap: _submitForm,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_C.mint, _C.mintDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _C.mint.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Submit Restroom',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Photo source button (Camera / Gallery)
// ─────────────────────────────────────────────
class _PhotoSourceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _PhotoSourceBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withOpacity(0.18), color.withOpacity(0.08)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.25), color.withOpacity(0.12)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(icon, size: 26, color: color),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Spring press button wrapper
// ─────────────────────────────────────────────
class _SpringButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _SpringButton({required this.child, required this.onTap});

  @override
  State<_SpringButton> createState() => _SpringButtonState();
}

class _SpringButtonState extends State<_SpringButton>
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
        builder: (_, child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Map grid painter (decorative)
// ─────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFA8D5D5).withOpacity(0.25)
      ..strokeWidth = 1;
    const step = 28.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}

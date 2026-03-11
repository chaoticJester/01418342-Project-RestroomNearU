import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:restroom_near_u/models/request_model.dart';
import 'package:restroom_near_u/models/restroom_model.dart';
import 'package:restroom_near_u/services/request_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/location_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/app_ui.dart';
import '../../widgets/spring_button.dart';
import '../../widgets/photo_source_button.dart';

class AddNewRestroomPage extends StatefulWidget {
  const AddNewRestroomPage({Key? key}) : super(key: key);

  @override
  State<AddNewRestroomPage> createState() => _AddNewRestroomPageState();
}

class _AddNewRestroomPageState extends State<AddNewRestroomPage>
    with SingleTickerProviderStateMixin {
  final _formKey             = GlobalKey<FormState>();
  final _nameController      = TextEditingController();
  final _locationController  = TextEditingController();
  final _phoneController     = TextEditingController();
  final _priceController     = TextEditingController();
  final _addressFocusNode    = FocusNode();

  // Places Autocomplete
  List<_PlaceSuggestion> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  GoogleMapController? _mapController;
  LatLng _currentMapPosition = const LatLng(13.8478, 100.5696);
  double? _selectedLatitude;
  double? _selectedLongitude;
  bool _hasLocationPermission = false;

  bool isFree    = true;
  bool is24Hours = true;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

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

  List<File> _localPhotos     = [];
  bool _isUploadingPhotos     = false;
  bool _isSubmitting           = false;

  late AnimationController _enterCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

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

    _locationController.addListener(_onAddressChanged);
    _addressFocusNode.addListener(() {
      if (!_addressFocusNode.hasFocus) {
        setState(() => _showSuggestions = false);
      }
    });

    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _enterCtrl.dispose();
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _priceController.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  // ── Places Autocomplete ───────────────────────────────────────────────────

  void _onAddressChanged() {
    final query = _locationController.text.trim();
    if (query.length < 3) {
      setState(() { _suggestions = []; _showSuggestions = false; });
      return;
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _fetchSuggestions(query));
  }

  Future<void> _fetchSuggestions(String query) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? '';

    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': query,
      'key': apiKey,
      'language': 'th',
      'components': 'country:th',
      'types': 'establishment',
    });

    try {
      final response = await http.get(uri);
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'] as String? ?? '';
        final predictions = data['predictions'] as List<dynamic>? ?? [];
        setState(() {
          _suggestions = predictions
              .map((p) => _PlaceSuggestion(
                    placeId: p['place_id'] as String,
                    mainText: (p['structured_formatting']?['main_text'] ?? p['description']) as String,
                    secondaryText: (p['structured_formatting']?['secondary_text'] ?? '') as String,
                  ))
              .toList();
          _showSuggestions = _suggestions.isNotEmpty;
        });
      }
    } catch (_) {}
  }

  Future<void> _selectSuggestion(_PlaceSuggestion suggestion) async {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY_ANDROID'] ?? '';
    // Fill in address text
    final fullAddress = suggestion.secondaryText.isNotEmpty
        ? '${suggestion.mainText}, ${suggestion.secondaryText}'
        : suggestion.mainText;

    _locationController.removeListener(_onAddressChanged);
    _locationController.text = fullAddress;
    _locationController.addListener(_onAddressChanged);

    setState(() { _suggestions = []; _showSuggestions = false; });
    _addressFocusNode.unfocus();

    // Fetch lat/lng from Place Details
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json'
          '?place_id=${suggestion.placeId}'
          '&fields=geometry'
          '&key=$apiKey';
      final response = await http.get(Uri.parse(url));
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final loc  = data['result']?['geometry']?['location'];
        if (loc != null) {
          final lat = (loc['lat'] as num).toDouble();
          final lng = (loc['lng'] as num).toDouble();
          setState(() {
            _selectedLatitude  = lat;
            _selectedLongitude = lng;
            _currentMapPosition = LatLng(lat, lng);
          });
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(LatLng(lat, lng), 17.0),
          );
        }
      }
    } catch (_) {}
  }

  // ── Location — now uses LocationService ───────────────────────────────────

  Future<void> _initLocation() async {
    final position = await LocationService.getCurrentPosition();
    if (position == null || !mounted) return;
    setState(() {
      _hasLocationPermission  = true;
      _selectedLatitude       = position.latitude;
      _selectedLongitude      = position.longitude;
      _currentMapPosition     = LatLng(position.latitude, position.longitude);
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentMapPosition, 16.0),
    );
  }

  Future<void> _getCurrentLocation() async {
    AppUI.showSnackBar(context, 'Getting current location…');
    final position = await LocationService.getCurrentPosition();
    if (!mounted) return;

    if (position == null) {
      AppUI.replaceSnackBar(context, 'Could not get location. Check permissions.',
          isError: true);
      return;
    }

    setState(() {
      _hasLocationPermission  = true;
      _selectedLatitude       = position.latitude;
      _selectedLongitude      = position.longitude;
      _currentMapPosition     = LatLng(position.latitude, position.longitude);
    });
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(_currentMapPosition, 16.0),
    );
    AppUI.replaceSnackBar(
      context,
      'Location found! Lat: ${_selectedLatitude!.toStringAsFixed(4)}…',
    );
  }

  // ── Time picker ───────────────────────────────────────────────────────────

  Future<void> _selectTime(bool isOpen) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.mint,
              onPrimary: Colors.white,
              surface: AppColors.bg,
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (picked != null) {
      setState(() => isOpen ? openTime = picked : closeTime = picked);
    }
  }

  String _formatTime24(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> _submitForm() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    if (_selectedLatitude == null || _selectedLongitude == null) {
      AppUI.showSnackBar(
          context, 'Please set the restroom location on the map first.',
          isError: true);
      return;
    }

    final User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      AppUI.showSnackBar(context, 'Please login to submit a restroom.',
          isError: true);
      return;
    }

    AppUI.showSnackBar(context, 'Submitting request…');

    try {
      final docRef      = FirebaseFirestore.instance.collection('requests').doc();
      final tempId      = docRef.id;
      final generatedId = FirebaseFirestore.instance.collection('restrooms').doc().id;

      List<String> uploadedUrls = [];
      if (_localPhotos.isNotEmpty) {
        setState(() => _isUploadingPhotos = true);
        uploadedUrls = await _uploadPhotos(tempId);
        setState(() => _isUploadingPhotos = false);
      }

      final newRestroom = RestroomModel(
        restroomId:   generatedId,
        restroomName: _nameController.text,
        address:      _locationController.text,
        latitude:     _selectedLatitude!,
        longitude:    _selectedLongitude!,
        openTime:     openTime  != null ? _formatTime24(openTime!)  : null,
        closeTime:    closeTime != null ? _formatTime24(closeTime!) : null,
        isFree:       isFree,
        price:        isFree ? null : double.tryParse(_priceController.text.trim()),
        is24hrs:      is24Hours,
        phoneNumber:  _phoneController.text,
        amenities:    _amenities,
        photos:       uploadedUrls,
        createdBy:    currentUser.uid,
      );

      final newRequest = RequestModel(
        requestId: tempId,
        restroom:  newRestroom,
        userId:    currentUser.uid,
        createdAt: DateTime.now(),
      );

      await RequestService().createRequest(newRequest);

      if (mounted) {
        AppUI.replaceSnackBar(context, 'Request sent to admin successfully!',
            icon: Icons.check_circle_rounded);
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('AddNewRestroomPage._submitForm error: $e');
      if (mounted) {
        AppUI.replaceSnackBar(context, 'Failed to submit request. Please try again.',
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Photo helpers ─────────────────────────────────────────────────────────

  Future<void> _pickPhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 80, maxWidth: 1200, maxHeight: 1200);
    if (picked == null) return;
    setState(() => _localPhotos.add(File(picked.path)));
  }

  void _removePhoto(int index) => setState(() => _localPhotos.removeAt(index));

  Future<List<String>> _uploadPhotos(String requestId) async {
    final urls = <String>[];
    for (final file in _localPhotos) {
      final fileName =
          'requests/$requestId/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref  = FirebaseStorage.instance.ref().child(fileName);
      final task = await ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      urls.add(await task.ref.getDownloadURL());
    }
    return urls;
  }

  void _showPhotoSourceSheet() {
    showPhotoSourceSheet(
      context,
      title: 'Add Photo',
      subtitle: 'Add photos of the restroom',
      onCamera:  () => _pickPhoto(ImageSource.camera),
      onGallery: () => _pickPhoto(ImageSource.gallery),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(child: _buildHeroHeader(context)),
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
                          _addressFieldWithAutocomplete(),
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
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            child: isFree
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: TextFormField(
                                      controller: _priceController,
                                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
                                      validator: (v) {
                                        if (isFree) return null;
                                        if (v == null || v.trim().isEmpty) return 'Please enter a price';
                                        if (double.tryParse(v.trim()) == null) return 'Enter a valid number';
                                        return null;
                                      },
                                      decoration: InputDecoration(
                                        hintText: '0.00',
                                        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
                                        prefixIcon: Padding(
                                          padding: const EdgeInsets.only(left: 14, right: 10),
                                          child: const Icon(Icons.paid_rounded, size: 18, color: AppColors.pink),
                                        ),
                                        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                        prefix: const Text('฿ ', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.pink)),
                                        filled: true,
                                        fillColor: AppColors.fieldFill,
                                        border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                        enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                        focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: AppColors.pink, width: 2)),
                                        errorBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(16),
                                            borderSide: const BorderSide(color: AppColors.pink, width: 2)),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                      ),
                                    ),
                                  ),
                          ),
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

  // ── Section builders ──────────────────────────────────────────────────────

  Widget _buildHeroHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [AppColors.mint, AppColors.mintDark],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18), shape: BoxShape.circle),
                  child: const Icon(Icons.add_location_alt_rounded,
                      size: 36, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text('Add New Restroom',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 0.2)),
                const SizedBox(height: 4),
                Text('Help others find clean restrooms nearby',
                    style: TextStyle(
                        fontSize: 12, color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
        ),
        Positioned(
          top: 40, left: 6,
          child: const SafeArea(child: AppBackButton()),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w700,
            color: AppColors.textDark, letterSpacing: 0.2),
      );

  Widget _mapPreview() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GoogleMap(
              initialCameraPosition:
                  CameraPosition(target: _currentMapPosition, zoom: 16.0),
              onMapCreated: (c) => _mapController = c,
              onCameraMove: (p) => _currentMapPosition = p.target,
              onCameraIdle: () => setState(() {
                _selectedLatitude  = _currentMapPosition.latitude;
                _selectedLongitude = _currentMapPosition.longitude;
              }),
              zoomControlsEnabled: false,
              myLocationEnabled: _hasLocationPermission,
              myLocationButtonEnabled: false,
              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
              },
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Icon(Icons.location_on_rounded, size: 40, color: AppColors.pink),
            ),
            Container(
              width: 10, height: 10,
              decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2), shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _useLocationButton() {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); _getCurrentLocation(); },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.orange.withOpacity(0.25),
                AppColors.orange.withOpacity(0.1)
              ], begin: Alignment.topLeft, end: Alignment.bottomRight),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: AppColors.orange.withOpacity(0.15),
                  blurRadius: 4, offset: const Offset(0, 2))],
            ),
            child: const Icon(Icons.my_location_rounded,
                size: 15, color: AppColors.orange),
          ),
          const SizedBox(width: 8),
          const Text('Use Current Location',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: AppColors.orange)),
        ],
      ),
    );
  }

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
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(icon, size: 18, color: AppColors.mint),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        filled: true,
        fillColor: AppColors.fieldFill,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.mint, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: AppColors.pink, width: 2)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _priceToggle() => Row(children: [
    _toggleChip(label: 'Free',  icon: Icons.money_off_rounded,
        selected: isFree,  onTap: () => setState(() => isFree = true),
        activeColor: AppColors.mint),
    const SizedBox(width: 12),
    _toggleChip(label: 'Paid',  icon: Icons.paid_rounded,
        selected: !isFree, onTap: () => setState(() => isFree = false),
        activeColor: AppColors.pink),
  ]);

  Widget _toggleChip({
    required String label, required IconData icon,
    required bool selected, required VoidCallback onTap, required Color activeColor,
  }) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onTap(); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected ? LinearGradient(colors: [
            activeColor.withOpacity(0.22), activeColor.withOpacity(0.08)
          ], begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
          color: selected ? null : AppColors.fieldFill,
          borderRadius: BorderRadius.circular(14),
          boxShadow: selected ? [BoxShadow(color: activeColor.withOpacity(0.2),
              blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 16,
              color: selected ? activeColor : AppColors.textLight),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
              color: selected ? activeColor : AppColors.textMid)),
        ]),
      ),
    );
  }

  Widget _hoursSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => is24Hours = !is24Hours);
          },
          child: Row(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46, height: 26,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(99),
                gradient: is24Hours ? const LinearGradient(
                    colors: [AppColors.mint, AppColors.mintDark],
                    begin: Alignment.centerLeft, end: Alignment.centerRight) : null,
                color: is24Hours ? null : AppColors.divider,
                boxShadow: is24Hours ? [BoxShadow(color: AppColors.mint.withOpacity(0.3),
                    blurRadius: 6, offset: const Offset(0, 2))] : null,
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                alignment: is24Hours ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                    margin: const EdgeInsets.all(3),
                    width: 18, height: 18,
                    decoration: const BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle)),
              ),
            ),
            const SizedBox(width: 10),
            Text('Open 24 hours',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: is24Hours ? AppColors.mint : AppColors.textMid)),
          ]),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: is24Hours
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: Row(children: [
                    Expanded(
                        child: _timePicker('Open', openTime,
                            () => _selectTime(true))),
                    const SizedBox(width: 12),
                    Expanded(
                        child: _timePicker('Close', closeTime,
                            () => _selectTime(false))),
                  ]),
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
          color: AppColors.fieldFill,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          const Icon(Icons.access_time_rounded, size: 16, color: AppColors.mint),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(fontSize: 10, color: AppColors.textLight)),
            Text(time != null ? _formatTime24(time) : '--:--',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
          ]),
        ]),
      ),
    );
  }

  Widget _amenitiesGrid() {
    final entries = _amenities.entries.toList();
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 10,
          mainAxisSpacing: 10, childAspectRatio: 3.0),
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
              gradient: value ? LinearGradient(
                  colors: [AppColors.pinkLight, AppColors.pink.withOpacity(0.15)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight) : null,
              color: value ? null : AppColors.fieldFill,
              borderRadius: BorderRadius.circular(14),
              boxShadow: value ? [BoxShadow(color: AppColors.pink.withOpacity(0.15),
                  blurRadius: 4, offset: const Offset(0, 2))] : null,
            ),
            child: Row(children: [
              Icon(icon, size: 16,
                  color: value ? AppColors.pink : AppColors.textLight),
              const SizedBox(width: 8),
              Expanded(child: Text(key,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                      color: value ? AppColors.textDark : AppColors.textLight),
                  maxLines: 1, overflow: TextOverflow.ellipsis)),
              if (value) const Icon(Icons.check_rounded,
                  size: 14, color: AppColors.pink),
            ]),
          ),
        );
      },
    );
  }

  Widget _photoRow() {
    return Wrap(
      spacing: 10, runSpacing: 10,
      children: [
        ..._localPhotos.asMap().entries.map((e) => Stack(children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: AppColors.pinkLight.withOpacity(0.3)),
            child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(e.value, fit: BoxFit.cover)),
          ),
          Positioned(
            top: 2, right: 2,
            child: GestureDetector(
              onTap: () => _removePhoto(e.key),
              child: Container(
                width: 20, height: 20,
                decoration: const BoxDecoration(
                    color: Colors.white, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    size: 13, color: Colors.red),
              ),
            ),
          ),
        ])),
        GestureDetector(
          onTap: () { HapticFeedback.lightImpact(); _showPhotoSourceSheet(); },
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  colors: [AppColors.mint.withOpacity(0.15),
                    AppColors.mint.withOpacity(0.05)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: AppColors.mint.withOpacity(0.15),
                  blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: const Column(
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.add_photo_alternate_rounded,
                  size: 26, color: AppColors.mint),
              SizedBox(height: 4),
              Text('Add', style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w600, color: AppColors.mint)),
            ]),
          ),
        ),
      ],
    );
  }

  // ── Address field with Places Autocomplete dropdown ─────────────────────

  Widget _addressFieldWithAutocomplete() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _locationController,
          focusNode: _addressFocusNode,
          style: const TextStyle(fontSize: 14, color: AppColors.textDark),
          decoration: InputDecoration(
            hintText: 'e.g. Kasetsart University, Bangkok',
            hintStyle: const TextStyle(fontSize: 13, color: AppColors.textLight),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: const Icon(Icons.location_on_rounded, size: 18, color: AppColors.mint),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: _locationController.text.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _locationController.clear();
                      setState(() { _suggestions = []; _showSuggestions = false; });
                    },
                    child: const Icon(Icons.close_rounded, size: 16, color: AppColors.textLight),
                  )
                : null,
            filled: true,
            fillColor: AppColors.fieldFill,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.mint, width: 2)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        // Dropdown suggestions
        if (_showSuggestions && _suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.10),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Column(
                children: _suggestions.asMap().entries.map((entry) {
                  final i = entry.key;
                  final s = entry.value;
                  final isLast = i == _suggestions.length - 1;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      _selectSuggestion(s);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: isLast ? null : Border(
                          bottom: BorderSide(color: AppColors.divider, width: 0.8),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.mint.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                size: 16, color: AppColors.mint),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  s.mainText,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (s.secondaryText.isNotEmpty)
                                  Text(
                                    s.secondaryText,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textLight,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.north_west_rounded,
                              size: 14, color: AppColors.textLight),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }

  Widget _submitButton() {
    return SpringButton(
      onTap: _isSubmitting ? () {} : _submitForm,
      child: AnimatedOpacity(
        opacity: _isSubmitting ? 0.6 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.mint, AppColors.mintDark],
                begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [BoxShadow(color: AppColors.mint.withOpacity(0.4),
                blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Center(
            child: _isSubmitting
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Submit Restroom',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700,
                        color: Colors.white, letterSpacing: 0.3)),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Places Autocomplete data model
// ─────────────────────────────────────────────
class _PlaceSuggestion {
  final String placeId;
  final String mainText;       // e.g. "Kasetsart University"
  final String secondaryText; // e.g. "Bangkok, Thailand"
  const _PlaceSuggestion({
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });
}

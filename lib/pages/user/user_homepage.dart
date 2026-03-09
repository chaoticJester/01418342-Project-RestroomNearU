import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/restroom_model.dart';
import '../../services/restroom_firestore.dart';
import '../../services/user_firestore.dart';
import 'restroom_detail_page.dart';
import 'navigation_page.dart';
import 'package:geolocator/geolocator.dart';

// ─────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────/
class _C {
  static const bg         = Color(0xFFFCF9EA);
  static const sheet      = Color(0xFFFAF7E8);
  static const teal       = Color(0xFFBADFDB);
  static const tealDark   = Color(0xFF7BBFBA);
  static const orange     = Color(0xFFE8753D);
  static const textDark   = Color(0xFF1C1B1F);
  static const textMid    = Color(0xFF6B6874);
  static const textLight  = Color(0xFFAEABB8);
  static const openGreen  = Color(0xFF34A853);
  static const closeRed   = Color(0xFFE53935);
  static const divider    = Color(0xFFECE9DA);
  static const pill       = Color(0xFFD8D4C4);
  static const searchFill = Color(0xFFEEEBDA);
}

// ─────────────────────────────────────────────
// Marker size tiers — maps zoom → logical dp card size
// ─────────────────────────────────────────────
class _MarkerTier {
  final double minZoom;
  final double cardDp;   // square card side in logical pixels
  final double borderDp;
  final double radiusDp;
  final double iconFontDp;
  final double pillWDp;
  final double pillHDp;
  final double pillFontDp;

  const _MarkerTier({
    required this.minZoom,
    required this.cardDp,
    required this.borderDp,
    required this.radiusDp,
    required this.iconFontDp,
    required this.pillWDp,
    required this.pillHDp,
    required this.pillFontDp,
  });
}

const _tiers = [
  _MarkerTier(   // zoomed way out — tiny dot-like pin
    minZoom: 0,
    cardDp: 14, borderDp: 2, radiusDp: 4,
    iconFontDp: 0, pillWDp: 0, pillHDp: 0, pillFontDp: 0,
  ),
  _MarkerTier(   // medium zoom — card without pill
    minZoom: 13,
    cardDp: 22, borderDp: 2, radiusDp: 6,
    iconFontDp: 11, pillWDp: 0, pillHDp: 0, pillFontDp: 0,
  ),
  _MarkerTier(   // close zoom — full card + rating pill
    minZoom: 15,
    cardDp: 34, borderDp: 3, radiusDp: 8,
    iconFontDp: 17, pillWDp: 26, pillHDp: 11, pillFontDp: 6,
  ),
  _MarkerTier(   // very close — large card + pill
    minZoom: 17,
    cardDp: 42, borderDp: 3, radiusDp: 10,
    iconFontDp: 21, pillWDp: 31, pillHDp: 13, pillFontDp: 7,
  ),
];

_MarkerTier _tierForZoom(double zoom) {
  _MarkerTier result = _tiers.first;
  for (final t in _tiers) {
    if (zoom >= t.minZoom) result = t;
  }
  return result;
}

// ─────────────────────────────────────────────
// UserHomePage
// ─────────────────────────────────────────────
class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage>
    with TickerProviderStateMixin {
  static const _initialZoom = 16.0;
  static const _initialCamera = CameraPosition(
    target: LatLng(13.8476, 100.5696),
    zoom: _initialZoom,
  );

  bool _myLocationEnabled = false;

  List<RestroomModel> restrooms = [];
  StreamSubscription? _restroomSub;
  late AnimationController _listEntryController;
  final DraggableScrollableController _sheetController =
      DraggableScrollableController();

  // Map & markers
  final Completer<GoogleMapController> _mapCompleter = Completer();
  final Map<MarkerId, Marker> _markers = {};
  RestroomModel? _selectedRestroom;

  // Zoom tracking + debounce
  double _currentZoom = _initialZoom;
  _MarkerTier _currentTier = _tierForZoom(_initialZoom);
  Timer? _zoomDebounce;

  // Search
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Filter tab: 'Nearby' or 'Favorites'
  String _activeTab = 'Nearby';

  // Favorites — loaded from Firestore, synced on toggle
  final Set<String> _favoriteIds = {};
  final _userService = UserService();

  // Device pixel ratio
  double _dpr = 1.0;
  bool _dprInitialized = false;

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await _userService.getUserById(uid);
    if (user != null && mounted) {
      setState(() {
        _favoriteIds
          ..clear()
          ..addAll(user.favoriteRestrooms);
      });
    }
  }

  Future<void> _toggleFavorite(String restroomId) async {
    HapticFeedback.lightImpact();
    final isFav = _favoriteIds.contains(restroomId);
    setState(() {
      if (isFav) {
        _favoriteIds.remove(restroomId);
      } else {
        _favoriteIds.add(restroomId);
      }
    });
    if (isFav) {
      await _userService.removeFavoriteRestroom(restroomId);
    } else {
      await _userService.addFavoriteRestroom(restroomId);
    }
  }

  List<RestroomModel> get _filteredRestrooms {
    var list = restrooms;
    if (_activeTab == 'Favorites') {
      list = list.where((r) => _favoriteIds.contains(r.restroomId)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((r) => r.restroomName.toLowerCase().contains(q)).toList();
    }
    return list;
  }

  void _onSearchChanged(String val) {
    setState(() => _searchQuery = val);
    _buildAllMarkers();
  }

  final Map<String, BitmapDescriptor> _bitmapCache = {};

  late AnimationController _popupCtrl;
  late Animation<double> _popupFade;
  late Animation<Offset> _popupSlide;

  @override
  void initState() {
    super.initState();
    
    _listEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();

    _popupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _popupFade  = CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOut);
    _popupSlide = Tween<Offset>(
            begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _popupCtrl, curve: Curves.easeOutCubic));

    _restroomSub = RestroomService().getRestroomsStream().listen((data) {
      if (mounted) {
        setState(() {
          restrooms = data;
          if (_dprInitialized) _buildAllMarkers(); 
        });
      }
    });
    
    _loadFavorites();
    _checkLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Get DPR safely from context
    final newDpr = MediaQuery.of(context).devicePixelRatio;
    if (!_dprInitialized || _dpr != newDpr) {
      _dpr = newDpr;
      _dprInitialized = true;
      _buildAllMarkers();
    }
  }

  Future<void> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    if (mounted) {
      setState(() => _myLocationEnabled = true);
      _goToCurrentLocation(); 
    }
  }

  Future<void> _goToCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high)
      );

      final GoogleMapController controller = await _mapCompleter.future;
      controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        16.5,
      ));
    } catch (e) {
      debugPrint("Error locating user: $e");
    }
  }

  @override
  void dispose() {
    _restroomSub?.cancel();
    _zoomDebounce?.cancel();
    _listEntryController.dispose();
    _sheetController.dispose();
    _popupCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onCameraMove(CameraPosition pos) {
    final newZoom = pos.zoom;
    if ((newZoom - _currentZoom).abs() < 0.3) return; 
    _currentZoom = newZoom;

    _zoomDebounce?.cancel();
    _zoomDebounce = Timer(const Duration(milliseconds: 120), () {
      final newTier = _tierForZoom(_currentZoom);
      if (newTier.minZoom != _currentTier.minZoom) {
        _currentTier = newTier;
        _buildAllMarkers();
      }
    });
  }

  Future<void> _buildAllMarkers() async {
    if (!_dprInitialized) return;
    final Map<MarkerId, Marker> fresh = {};
    for (final r in _filteredRestrooms) {
      final isSelected = _selectedRestroom?.restroomId == r.restroomId;
      final icon = await _iconForTier(r, _currentTier, isSelected: isSelected);
      final id = MarkerId(r.restroomId);
      fresh[id] = _makeMarker(r, icon);
    }
    if (mounted) setState(() { _markers
      ..clear()
      ..addAll(fresh); });
  }

  Future<void> _refreshSelectionMarkers({
    RestroomModel? prev,
    RestroomModel? next,
  }) async {
    if (!_dprInitialized) return;
    final updates = <MarkerId, Marker>{};
    for (final r in [prev, next]) {
      if (r == null) continue;
      final isSelected = next?.restroomId == r.restroomId;
      final icon = await _iconForTier(r, _currentTier, isSelected: isSelected);
      final id = MarkerId(r.restroomId);
      updates[id] = _makeMarker(r, icon);
    }
    if (mounted) setState(() => _markers.addAll(updates));
  }

  Marker _makeMarker(RestroomModel r, BitmapDescriptor icon) {
    return Marker(
      markerId: MarkerId(r.restroomId),
      position: LatLng(r.latitude, r.longitude),
      icon: icon,
      anchor: _currentTier.pillHDp > 0
          ? const Offset(0.5, 0.60)
          : const Offset(0.5, 0.5),
      zIndex: _selectedRestroom?.restroomId == r.restroomId ? 1.0 : 0.0,
      onTap: () => _onMarkerTap(r),
    );
  }

  Future<BitmapDescriptor> _iconForTier(
      RestroomModel r, _MarkerTier tier, {bool isSelected = false}) async {
    final key = '${r.restroomId}:${tier.minZoom}:${isSelected ? 's' : 'n'}';
    if (_bitmapCache.containsKey(key)) return _bitmapCache[key]!;
    final bmp = await _renderMarker(r, tier, _dpr, isSelected: isSelected);
    _bitmapCache[key] = bmp;
    return bmp;
  }

  static Future<BitmapDescriptor> _renderMarker(
      RestroomModel r, _MarkerTier t, double dpr,
      {bool isSelected = false}) async {
    final bool showPill = t.pillHDp > 0;
    const double gapDp  = 3.0;
    const double padDp  = 2.0;
    final double canvasWDp = t.cardDp + t.borderDp * 2 + padDp * 2;
    final double canvasHDp = padDp
        + t.borderDp * 2
        + t.cardDp
        + (showPill ? gapDp + t.pillHDp : 0)
        + padDp;

    final double s       = dpr;
    final double cardSz  = t.cardDp  * s;
    final double border  = t.borderDp * s;
    final double radius  = t.radiusDp * s;
    final double pad     = padDp * s;
    final double gap     = gapDp * s;
    final double pillH   = t.pillHDp * s;
    final double pillW   = t.pillWDp * s;
    final double canvasW = canvasWDp * s;
    final double canvasH = canvasHDp * s;

    final recorder = ui.PictureRecorder();
    final canvas   = Canvas(recorder);
    final double cx       = canvasW / 2;
    final double cardLeft = cx - cardSz / 2;
    final double cardTop  = pad + border;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cardLeft - border, cardTop - border,
            cardSz + border * 2, cardSz + border * 2),
        Radius.circular(radius + border),
      ),
      Paint()..color = isSelected
          ? const Color(0xFFE8753D)   
          : Colors.white,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cardLeft, cardTop, cardSz, cardSz),
        Radius.circular(radius),
      ),
      Paint()..color = isSelected
          ? const Color(0xFF4AADA7)   
          : const Color(0xFFBADFDB), 
    );

    if (t.iconFontDp >= 14) {
      final iconTp = TextPainter(
        text: TextSpan(
          text: '🚻',
          style: TextStyle(fontSize: t.iconFontDp * s),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      iconTp.paint(canvas, Offset(
        cardLeft + (cardSz - iconTp.width) / 2,
        cardTop  + (cardSz - iconTp.height) / 2,
      ));
    }

    if (showPill) {
      final double pillTop  = cardTop + cardSz + border + gap;
      final double pillLeft = cx - pillW / 2;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(pillLeft, pillTop, pillW, pillH),
          Radius.circular(pillH / 2),
        ),
        Paint()..color = Colors.white,
      );

      final starTp = TextPainter(
        text: TextSpan(
          text: '⭐',
          style: TextStyle(fontSize: t.pillFontDp * 0.85 * s),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      starTp.paint(canvas, Offset(
        pillLeft + 6 * s,
        pillTop + (pillH - starTp.height) / 2,
      ));

      final ratingTp = TextPainter(
        text: TextSpan(
          text: r.avgRating.toStringAsFixed(1),
          style: TextStyle(
            fontSize: t.pillFontDp * s,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF3B566E),
            letterSpacing: 0.2 * s,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ratingTp.paint(canvas, Offset(
        pillLeft + pillW - ratingTp.width - 7 * s,
        pillTop  + (pillH - ratingTp.height) / 2,
      ));
    }

    final picture  = recorder.endRecording();
    final image    = await picture.toImage(canvasW.round(), canvasH.round());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(
      byteData!.buffer.asUint8List(),
      size: Size(canvasWDp, canvasHDp),
    );
  }

  void _onMarkerTap(RestroomModel r) {
    HapticFeedback.selectionClick();
    final prev = _selectedRestroom;
    setState(() => _selectedRestroom = r);
    _refreshSelectionMarkers(prev: prev, next: r);

    _sheetController.animateTo(
      0.14,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );

    _mapCompleter.future.then((ctrl) {
      ctrl.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(r.latitude, r.longitude),
        17.5,
      ));
    });

    _popupCtrl.forward(from: 0);
  }

  void _dismissPopup() {
    _popupCtrl.reverse().then((_) {
      if (!mounted) return;
      final prev = _selectedRestroom;
      setState(() => _selectedRestroom = null);
      _refreshSelectionMarkers(prev: prev, next: null);
    });
  }

  void _toggleSheet() {
    HapticFeedback.mediumImpact();
    _dismissPopup();
    final current = _sheetController.size;
    final target  = current <= 0.2 ? 0.45 : 0.14;
    _sheetController.animateTo(
      target,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: Stack(
          children: [
            // ── Map Container ──────────────────────────
            Container(
              color: _C.bg, // Fallback color while map loads
              child: GoogleMap(
                initialCameraPosition: _initialCamera,
                zoomControlsEnabled: false,
                myLocationEnabled: _myLocationEnabled, 
                myLocationButtonEnabled: false,        
                markers: Set<Marker>.of(_markers.values),
                onMapCreated: (ctrl) => _mapCompleter.complete(ctrl),
                onCameraMove: _onCameraMove,
                onTap: (_) => _dismissPopup(),
              ),
            ),

            // ── Marker popup card ─────────────────────────────
            if (_selectedRestroom != null)
              _MarkerPopup(
                restroom: _selectedRestroom!,
                fadeAnim: _popupFade,
                slideAnim: _popupSlide,
                onDismiss: _dismissPopup,
                onNavigate: () {
                  _dismissPopup();
                  Navigator.push(
                    context,
                    _smoothRoute(RestroomDetailPage(restroom: _selectedRestroom!)),
                  );
                },
                onGoNav: () {
                  _dismissPopup();
                  Navigator.push(
                    context,
                    _smoothRoute(NavigationPage(restroom: _selectedRestroom!)),
                  );
                },
              ),

            // ── Add New Restroom pill ─────────────────────────
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 12, right: 16),
                  child: _PillButton(
                    label: 'Add New Restroom',
                    icon: Icons.add_rounded,
                    onTap: () =>
                        Navigator.pushNamed(context, '/add_new_restroom'),
                  ),
                ),
              ),
            ),

            // ── Bottom sheet ──────────────────────────────────
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.45,
              minChildSize: 0.14,
              maxChildSize: 0.92,
              snap: true,
              snapSizes: const [0.14, 0.45, 0.92],
              builder: (context, scrollController) {
                return _BottomSheetContent(
                  scrollController: scrollController,
                  restrooms: _filteredRestrooms,
                  listEntryController: _listEntryController,
                  onHandleTap: _toggleSheet,
                  onRestroomTap: _onMarkerTap,
                  onLocateTap: _goToCurrentLocation,
                  onSearchChanged: _onSearchChanged,
                  searchController: _searchController,
                  activeTab: _activeTab,
                  onTabChanged: (tab) => setState(() => _activeTab = tab),
                  favoriteIds: _favoriteIds,
                  onToggleFavorite: _toggleFavorite,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Marker Popup Card
// ─────────────────────────────────────────────
class _MarkerPopup extends StatelessWidget {
  final RestroomModel restroom;
  final Animation<double> fadeAnim;
  final Animation<Offset> slideAnim;
  final VoidCallback onDismiss;
  final VoidCallback onNavigate;
  final VoidCallback onGoNav;

  const _MarkerPopup({
    required this.restroom,
    required this.fadeAnim,
    required this.slideAnim,
    required this.onDismiss,
    required this.onNavigate,
    required this.onGoNav,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = RestroomService().checkIfOpen(restroom);

    return Positioned(
      bottom: MediaQuery.of(context).size.height * 0.15 + 12,
      left: 16,
      right: 16,
      child: FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(
          position: slideAnim,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.14),
                    blurRadius: 24,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFBADFDB), Color(0xFF7BBFBA)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.wc_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(restroom.restroomName,
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _C.textDark,
                                      height: 1.2),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 3),
                              Row(children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 11, color: _C.textLight),
                                const SizedBox(width: 3),
                                Expanded(
                                  child: Text(restroom.address,
                                      style: const TextStyle(
                                          fontSize: 11, color: _C.textMid),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ]),
                              const SizedBox(height: 8),
                              Row(children: [
                                _MiniChip(
                                    icon: Icons.star_rounded,
                                    iconColor: _C.orange,
                                    label: restroom.avgRating.toStringAsFixed(1)),
                                const SizedBox(width: 6),
                                _MiniChip(
                                    icon: restroom.isFree
                                        ? Icons.money_off_rounded
                                        : Icons.paid_rounded,
                                    iconColor: _C.tealDark,
                                    label: restroom.isFree ? 'Free' : 'Paid'),
                                const SizedBox(width: 6),
                                _StatusBadge(isOpen: isOpen),
                              ]),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: onDismiss,
                          child: Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                                color: _C.searchFill, shape: BoxShape.circle),
                            child: const Icon(Icons.close_rounded,
                                size: 15, color: _C.textMid),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: _AmenitiesRow(amenities: restroom.amenities),
                  ),
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 5,
                          child: GestureDetector(
                            onTap: onGoNav,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFF7BBFBA), Color(0xFF4AADA7)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.navigation_rounded,
                                      size: 15, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Navigate',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(width: 1, height: 44, color: Colors.white24),
                        Expanded(
                          flex: 5,
                          child: GestureDetector(
                            onTap: onNavigate,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Color(0xFFBADFDB), Color(0xFF9DCFCA)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.info_outline_rounded,
                                      size: 15, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Details',
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AmenitiesRow extends StatelessWidget {
  final Map<String, bool> amenities;
  const _AmenitiesRow({required this.amenities});

  static const _icons = {
    'toiletPaper': Icons.newspaper_rounded,
    'soap': Icons.soap_rounded,
    'handDryer': Icons.dry_rounded,
    'wheelchairAccessible': Icons.accessible_rounded,
    'babyChangingStation': Icons.child_friendly_rounded,
    'hotWater': Icons.water_drop_rounded,
    'wifi': Icons.wifi_rounded,
    'powerOutlet': Icons.electrical_services_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final active = amenities.entries.where((e) => e.value).take(6).toList();
    if (active.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6, runSpacing: 4,
      children: active.map((e) {
        final icon = _icons[e.key] ?? Icons.check_rounded;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: BoxDecoration(
            color: _C.teal.withOpacity(0.18),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 13, color: _C.tealDark),
        );
      }).toList(),
    );
  }
}

class _BottomSheetContent extends StatelessWidget {
  final ScrollController scrollController;
  final List<RestroomModel> restrooms;
  final AnimationController listEntryController;
  final VoidCallback onHandleTap;
  final ValueChanged<RestroomModel> onRestroomTap;
  final VoidCallback onLocateTap;
  final ValueChanged<String> onSearchChanged;
  final TextEditingController searchController;
  final String activeTab;
  final ValueChanged<String> onTabChanged;
  final Set<String> favoriteIds;
  final Future<void> Function(String) onToggleFavorite;

  const _BottomSheetContent({
    required this.scrollController,
    required this.restrooms,
    required this.listEntryController,
    required this.onHandleTap,
    required this.onRestroomTap,
    required this.onLocateTap,
    required this.onSearchChanged,
    required this.searchController,
    required this.activeTab,
    required this.onTabChanged,
    required this.favoriteIds,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _C.sheet,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 24, spreadRadius: -4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: CustomScrollView(
        controller: scrollController,
        physics: const ClampingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onHandleTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: Row(children: [
                  _CircleIconButton(
                    icon: Icons.person_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, '/profile');
                    },
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 36, height: 4.5,
                        decoration: BoxDecoration(
                          color: _C.pill,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  _CircleIconButton(
                    icon: Icons.near_me_rounded,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onLocateTap(); 
                    },
                  ),
                ]),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
              child: _SearchBar(
                onChanged: onSearchChanged,
                controller: searchController,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: _FilterTabBar(
                activeTab: activeTab,
                nearbyCount: activeTab == 'Nearby' ? restrooms.length : favoriteIds.length,
                favCount: favoriteIds.length,
                onTabChanged: onTabChanged,
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final delay = (index * 0.07).clamp(0.0, 0.6);
                final itemAnim = CurvedAnimation(
                  parent: listEntryController,
                  curve: Interval(delay, (delay + 0.4).clamp(0.0, 1.0),
                      curve: Curves.easeOutCubic),
                );
                return AnimatedBuilder(
                  animation: itemAnim,
                  builder: (context, child) => Transform.translate(
                    offset: Offset(0, 22 * (1 - itemAnim.value)),
                    child: Opacity(opacity: itemAnim.value, child: child),
                  ),
                  child: _RestroomCard(
                    restroom: restrooms[index],
                    onPinTap: () => onRestroomTap(restrooms[index]),
                    isFavorite: favoriteIds.contains(restrooms[index].restroomId),
                    onToggleFavorite: () async => onToggleFavorite(restrooms[index].restroomId),
                  ),
                );
              },
              childCount: restrooms.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController controller;

  const _SearchBar({required this.onChanged, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _C.searchFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        const SizedBox(width: 12),
        Icon(Icons.search_rounded, color: _C.textLight, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            style: const TextStyle(
                fontSize: 14, color: _C.textDark, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              hintText: 'Search restrooms…',
              hintStyle: TextStyle(
                  color: _C.textLight, fontSize: 14, fontWeight: FontWeight.w400),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
        const SizedBox(width: 12),
      ]),
    );
  }
}

class _RestroomCard extends StatefulWidget {
  final RestroomModel restroom;
  final VoidCallback onPinTap;
  final bool isFavorite;
  final Future<void> Function() onToggleFavorite;
  const _RestroomCard({
    required this.restroom,
    required this.onPinTap,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  @override
  State<_RestroomCard> createState() => _RestroomCardState();
}

class _RestroomCardState extends State<_RestroomCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
      reverseDuration: const Duration(milliseconds: 200),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.968).animate(
        CurvedAnimation(parent: _pressCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pressCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.restroom;
    final isOpen = RestroomService().checkIfOpen(r);

    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) => _pressCtrl.reverse(),
      onTapCancel: () => _pressCtrl.reverse(),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(context, _smoothRoute(RestroomDetailPage(restroom: r)));
      },
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.72),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _C.divider, width: 1),
          ),
          child: Row(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _C.teal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.wc_rounded, color: _C.tealDark, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.restroomName,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700,
                        color: _C.textDark, height: 1.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 3),
                Text(r.address,
                    style: const TextStyle(
                        fontSize: 12, color: _C.textMid, height: 1.3),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 7),
                Row(children: [
                  _MiniChip(
                      icon: Icons.star_rounded,
                      iconColor: _C.orange,
                      label: r.avgRating.toStringAsFixed(1)),
                  const SizedBox(width: 6),
                  _MiniChip(
                      icon: r.isFree
                          ? Icons.money_off_rounded
                          : Icons.paid_rounded,
                      iconColor: _C.tealDark,
                      label: r.isFree ? 'Free' : 'Paid'),
                  const Spacer(),
                  _StatusBadge(isOpen: isOpen),
                ]),
              ]),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onToggleFavorite,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: widget.isFavorite
                      ? const Color(0xFFD77A7A).withOpacity(0.15)
                      : _C.searchFill,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  size: 18,
                  color: widget.isFavorite
                      ? const Color(0xFFD77A7A)
                      : _C.textLight,
                ),
              ),
            ),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  _smoothRoute(NavigationPage(restroom: r)),
                );
              },
              child: Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7BBFBA), Color(0xFF4AADA7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4AADA7).withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.navigation_rounded,
                    size: 20, color: Colors.white),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _FilterTabBar extends StatefulWidget {
  final String activeTab;
  final int nearbyCount;
  final int favCount;
  final ValueChanged<String> onTabChanged;

  const _FilterTabBar({
    required this.activeTab,
    required this.nearbyCount,
    required this.favCount,
    required this.onTabChanged,
  });

  @override
  State<_FilterTabBar> createState() => _FilterTabBarState();
}

class _FilterTabBarState extends State<_FilterTabBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: widget.activeTab == 'Favorites' ? 1.0 : 0.0,
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic);
  }

  @override
  void didUpdateWidget(_FilterTabBar old) {
    super.didUpdateWidget(old);
    if (old.activeTab != widget.activeTab) {
      widget.activeTab == 'Favorites' ? _ctrl.forward() : _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const activeRed = Color(0xFFD77A7A);
    final isNearby = widget.activeTab == 'Nearby';

    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _C.searchFill,
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          final totalW = box.maxWidth;
          final pillW  = totalW / 2;
          return AnimatedBuilder(
            animation: _anim,
            builder: (context, _) {
              final pillLeft = _anim.value * pillW;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    top: 4, bottom: 4,
                    left: pillLeft + 4,
                    width: pillW - 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.10),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onTabChanged('Nearby');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.location_on_rounded,
                                    size: 15,
                                    color: isNearby ? _C.tealDark : _C.textLight),
                                const SizedBox(width: 6),
                                Text('Nearby',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isNearby ? FontWeight.w700 : FontWeight.w500,
                                      color: isNearby ? _C.tealDark : _C.textLight,
                                    )),
                                if (widget.nearbyCount > 0) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isNearby
                                          ? _C.tealDark.withOpacity(0.14)
                                          : _C.pill.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text('${widget.nearbyCount}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: isNearby ? _C.tealDark : _C.textLight,
                                        )),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              widget.onTabChanged('Favorites');
                            },
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.favorite_rounded,
                                    size: 15,
                                    color: !isNearby ? activeRed : _C.textLight),
                                const SizedBox(width: 6),
                                Text('Favorites',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: !isNearby ? FontWeight.w700 : FontWeight.w500,
                                      color: !isNearby ? activeRed : _C.textLight,
                                    )),
                                if (widget.favCount > 0) ...[
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: !isNearby
                                          ? activeRed.withOpacity(0.14)
                                          : _C.pill.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text('${widget.favCount}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: !isNearby ? activeRed : _C.textLight,
                                        )),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _MiniChip({required this.icon, required this.iconColor, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: _C.searchFill, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 12),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: _C.textDark)),
      ]),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isOpen;
  const _StatusBadge({required this.isOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (isOpen ? _C.openGreen : _C.closeRed).withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(isOpen ? 'Open' : 'Closed',
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isOpen ? _C.openGreen : _C.closeRed)),
    );
  }
}

class _CircleIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  State<_CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<_CircleIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 10, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(widget.icon, size: 20, color: _C.textDark),
        ),
      ),
    );
  }
}

class _PillButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _PillButton({required this.label, required this.icon, required this.onTap});

  @override
  State<_PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<_PillButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _scaleAnim = Tween(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) =>
            Transform.scale(scale: _scaleAnim.value, child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 12, offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 18, color: _C.tealDark),
            const SizedBox(width: 6),
            Text(widget.label,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark)),
          ]),
        ),
      ),
    );
  }
}

Route<dynamic> _smoothRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (_, a, __) => page,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (_, animation, __, child) {
      final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic);
      return SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(1.0, 0.0), end: Offset.zero)
            .animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  bool isFree     = true;
  bool is24Hours  = true;
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

  // Entry animation
  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.mint,
            onPrimary: Colors.white,
            surface: _C.bg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => isOpen ? openTime = picked : closeTime = picked);
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Submitting restroom…'),
          backgroundColor: _C.mint,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
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
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [_C.pinkLight.withOpacity(0.4), _C.mint.withOpacity(0.15)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
            // Grid pattern for map-like appearance
            CustomPaint(size: const Size(double.infinity, 148), painter: _GridPainter()),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_C.pink, _C.pink.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _C.pink.withOpacity(0.4),
                    blurRadius: 16,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(Icons.location_on_rounded, color: Colors.white, size: 26),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Getting current location…'),
            backgroundColor: _C.mint,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
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
                  time?.format(context) ?? '--:--',
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

  // ── Photo row ─────────────────────────────────────────────────────────
  Widget _photoRow() {
    return Row(
      children: [
        // Add photo button
        GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Opening camera/gallery…'),
                backgroundColor: _C.mint,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          },
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_C.mint.withOpacity(0.15), _C.mint.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _C.mint.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
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
        const SizedBox(width: 10),
        // Photo previews
        ...photoUrls.take(4).map((url) => Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: _C.pinkLight.withOpacity(0.3),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.network(url, fit: BoxFit.cover),
            ),
          ),
        )),
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

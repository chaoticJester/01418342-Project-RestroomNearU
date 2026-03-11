import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/restroom_model.dart';
import '../../services/restroom_firestore.dart';

// ─────────────────────────────────────────────
// Design tokens
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFFCF9EA);
  static const card      = Color(0xFFFFFDFA);
  static const teal      = Color(0xFFBADFDB);
  static const tealDark  = Color(0xFF7BBFBA);
  static const orange    = Color(0xFFE8753D);
  static const green     = Color(0xFF34A853);
  static const red       = Color(0xFFE53935);
  static const textDark  = Color(0xFF1C1B1F);
  static const textMid   = Color(0xFF6B6874);
  static const textLight = Color(0xFFAEABB8);
  static const divider   = Color(0xFFECE9DA);
  static const fieldFill = Color(0xFFEEEBDA);
}

class AdminEditToiletPage extends StatefulWidget {
  final RestroomModel restroom;
  const AdminEditToiletPage({Key? key, required this.restroom}) : super(key: key);

  @override
  State<AdminEditToiletPage> createState() => _AdminEditToiletPageState();
}

class _AdminEditToiletPageState extends State<AdminEditToiletPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;

  // State
  late bool _isFree;
  late bool _is24hrs;
  late String? _openTime;
  late String? _closeTime;
  late Map<String, bool> _amenities;

  bool _isSubmitting = false;

  // Amenity display name map
  static const _amenityLabels = {
    'wheelchairAccessible': 'Wheelchair Accessible',
    'hasSoap':              'Has Soap',
    'hasToiletPaper':       'Has Toilet Paper',
    'hasPaperTowels':       'Has Paper Towels',
    'hasWarmWater':         'Has Warm Water',
    'isClean':              'Clean',
  };

  @override
  void initState() {
    super.initState();
    final r = widget.restroom;
    _nameCtrl    = TextEditingController(text: r.restroomName);
    _addressCtrl = TextEditingController(text: r.address);
    _phoneCtrl   = TextEditingController(text: r.phoneNumber);
    _priceCtrl   = TextEditingController(
        text: r.price != null ? r.price!.toStringAsFixed(0) : '');
    _latCtrl     = TextEditingController(text: r.latitude.toString());
    _lngCtrl     = TextEditingController(text: r.longitude.toString());
    _isFree      = r.isFree;
    _is24hrs     = r.is24hrs;
    _openTime    = r.openTime;
    _closeTime   = r.closeTime;
    _amenities   = Map<String, bool>.from(r.amenities);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _priceCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }

  // ── Time picker ──────────────────────────────────────────────────────
  Future<void> _pickTime(bool isOpen) async {
    final initial = _parseTimeOrNull(isOpen ? _openTime : _closeTime) ??
        TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _C.tealDark,
            onPrimary: Colors.white,
            surface: _C.card,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isOpen) _openTime = formatted;
        else _closeTime = formatted;
      });
    }
  }

  TimeOfDay? _parseTimeOrNull(String? t) {
    if (t == null) return null;
    try {
      final parts = t.split(':');
      return TimeOfDay(
          hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    } catch (_) {
      return null;
    }
  }

  // ── Save ─────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      final updated = widget.restroom.copyWith(
        restroomName: _nameCtrl.text.trim(),
        address:      _addressCtrl.text.trim(),
        phoneNumber:  _phoneCtrl.text.trim(),
        latitude:     double.tryParse(_latCtrl.text) ?? widget.restroom.latitude,
        longitude:    double.tryParse(_lngCtrl.text) ?? widget.restroom.longitude,
        isFree:       _isFree,
        price:        _isFree ? null : double.tryParse(_priceCtrl.text),
        is24hrs:      _is24hrs,
        openTime:     _is24hrs ? null : _openTime,
        closeTime:    _is24hrs ? null : _closeTime,
        amenities:    _amenities,
        updatedAt:    DateTime.now(),
        updatedBy:    uid,
      );

      await RestroomService().updateRestroom(updated);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text('Toilet updated successfully'),
            ]),
            backgroundColor: _C.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context, true); // return true = was edited
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: _C.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: _C.bg,
        body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                    children: [
                      _sectionCard(
                        title: 'Basic Info',
                        icon: Icons.info_outline_rounded,
                        children: [
                          _field(
                            controller: _nameCtrl,
                            label: 'Toilet Name',
                            icon: Icons.wc_rounded,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _addressCtrl,
                            label: 'Address',
                            icon: Icons.location_on_rounded,
                            maxLines: 2,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Address is required'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          _field(
                            controller: _phoneCtrl,
                            label: 'Phone Number (optional)',
                            icon: Icons.phone_rounded,
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _sectionCard(
                        title: 'Location',
                        icon: Icons.map_rounded,
                        children: [
                          Row(children: [
                            Expanded(
                              child: _field(
                                controller: _latCtrl,
                                label: 'Latitude',
                                icon: Icons.explore_rounded,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _field(
                                controller: _lngCtrl,
                                label: 'Longitude',
                                icon: Icons.explore_outlined,
                                keyboardType: const TextInputType.numberWithOptions(
                                    decimal: true, signed: true),
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (double.tryParse(v) == null) return 'Invalid';
                                  return null;
                                },
                              ),
                            ),
                          ]),
                        ],
                      ),
                      const SizedBox(height: 16),

                      _sectionCard(
                        title: 'Hours',
                        icon: Icons.access_time_rounded,
                        children: [
                          _toggleRow(
                            label: 'Open 24 Hours',
                            value: _is24hrs,
                            onChanged: (v) => setState(() => _is24hrs = v),
                          ),
                          if (!_is24hrs) ...[
                            const SizedBox(height: 12),
                            Row(children: [
                              Expanded(
                                  child: _timeTile(
                                      label: 'Open Time',
                                      time: _openTime,
                                      onTap: () => _pickTime(true))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: _timeTile(
                                      label: 'Close Time',
                                      time: _closeTime,
                                      onTap: () => _pickTime(false))),
                            ]),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      _sectionCard(
                        title: 'Pricing',
                        icon: Icons.payments_rounded,
                        children: [
                          _toggleRow(
                            label: 'Free to Use',
                            value: _isFree,
                            onChanged: (v) => setState(() => _isFree = v),
                          ),
                          if (!_isFree) ...[
                            const SizedBox(height: 12),
                            _field(
                              controller: _priceCtrl,
                              label: 'Price (THB)',
                              icon: Icons.attach_money_rounded,
                              keyboardType: TextInputType.number,
                              validator: (v) {
                                if (_isFree) return null;
                                if (v == null || v.isEmpty) return 'Enter price';
                                if (double.tryParse(v) == null) return 'Invalid';
                                return null;
                              },
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),

                      _sectionCard(
                        title: 'Amenities',
                        icon: Icons.check_circle_outline_rounded,
                        children: _amenityLabels.entries.map((e) {
                          final key = e.key;
                          final label = e.value;
                          final checked = _amenities[key] ?? false;
                          return _amenityRow(
                            label: label,
                            value: checked,
                            onChanged: (v) =>
                                setState(() => _amenities[key] = v),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 28),

                      // Save button
                      GestureDetector(
                        onTap: _isSubmitting ? null : _save,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 17),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isSubmitting
                                  ? [_C.teal, _C.teal]
                                  : [_C.teal, _C.tealDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: _isSubmitting
                                ? []
                                : [
                                    BoxShadow(
                                      color: _C.tealDark.withOpacity(0.4),
                                      blurRadius: 20,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2.5),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
      decoration: const BoxDecoration(color: _C.teal),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 6,
                      offset: const Offset(0, 2)),
                ],
              ),
              child:
                  const Icon(Icons.arrow_back, size: 20, color: _C.textDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Toilet',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white),
                ),
                Text(
                  widget.restroom.restroomName,
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card wrapper ──────────────────────────────────────────────
  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: _C.teal.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(icon, size: 16, color: _C.tealDark),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _C.textDark)),
              ],
            ),
          ),
          Divider(color: _C.divider, height: 1, thickness: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children),
          ),
        ],
      ),
    );
  }

  // ── Text field ────────────────────────────────────────────────────────
  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: _C.textDark),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: _C.textMid),
        prefixIcon: Icon(icon, size: 18, color: _C.tealDark),
        filled: true,
        fillColor: _C.fieldFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.tealDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.red, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _C.red, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  // ── Toggle row ────────────────────────────────────────────────────────
  Widget _toggleRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _C.textDark)),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: _C.tealDark,
        ),
      ],
    );
  }

  // ── Time tile ─────────────────────────────────────────────────────────
  Widget _timeTile({
    required String label,
    required String? time,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: _C.fieldFill,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded,
                size: 18, color: _C.tealDark),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 11, color: _C.textLight)),
                  Text(
                    time ?? 'Not set',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: time != null ? _C.textDark : _C.textLight,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit_rounded, size: 14, color: _C.textLight),
          ],
        ),
      ),
    );
  }

  // ── Amenity checkbox row ──────────────────────────────────────────────
  Widget _amenityRow({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: value ? _C.tealDark : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: value ? _C.tealDark : _C.textLight, width: 2),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: value ? _C.textDark : _C.textMid)),
          ],
        ),
      ),
    );
  }
}

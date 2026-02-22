import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─────────────────────────────────────────────
// Design tokens (ตรงกับ user_homepage / profile_page)
// ─────────────────────────────────────────────
class _C {
  static const bg        = Color(0xFFFCF9EA);
  static const card      = Color(0xFFF7F4E6);
  static const teal      = Color(0xFFBADFDB);
  static const tealDark  = Color(0xFF7BBFBA);
  static const orange    = Color(0xFFE8753D);
  static const green     = Color(0xFF34A853);
  static const red       = Color(0xFFB3261E);
  static const textDark  = Color(0xFF1C1B1F);
  static const textMid   = Color(0xFF6B6874);
  static const textLight = Color(0xFFAEABB8);
  static const divider   = Color(0xFFECE9DA);
  static const fieldFill = Color(0xFFEEEBDA);
}

class ReportIssuePage extends StatefulWidget {
  final String restroomId;
  final String restroomName;

  const ReportIssuePage({
    Key? key,
    required this.restroomId,
    required this.restroomName,
  }) : super(key: key);

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage>
    with SingleTickerProviderStateMixin {
  String? selectedIssue;
  final _descriptionController = TextEditingController();
  final _emailController       = TextEditingController();
  bool isAnonymous  = false;
  bool isSubmitting = false;

  late AnimationController _enterCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  final List<Map<String, dynamic>> issueTypes = [
    {'value': 'location',  'label': 'Incorrect Location',         'icon': Icons.location_off_rounded},
    {'value': 'closed',    'label': 'Permanently Closed',         'icon': Icons.block_rounded},
    {'value': 'price',     'label': 'Incorrect Price',            'icon': Icons.payments_rounded},
    {'value': 'hours',     'label': 'Incorrect Opening Hours',    'icon': Icons.access_time_rounded},
    {'value': 'amenities', 'label': 'Incorrect Amenities Info',   'icon': Icons.wc_rounded},
    {'value': 'duplicate', 'label': 'Duplicate Entry',            'icon': Icons.copy_rounded},
    {'value': 'other',     'label': 'Other',                      'icon': Icons.help_outline_rounded},
  ];

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
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? _C.red : _C.tealDark,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (selectedIssue == null) {
      _showSnack('Please select an issue type', isError: true);
      return;
    }
    if (_descriptionController.text.trim().length < 20) {
      _showSnack('Please provide at least 20 characters of description',
          isError: true);
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => isSubmitting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => isSubmitting = false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: _C.bg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _C.green.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: _C.green, size: 42),
            ),
            const SizedBox(height: 16),
            const Text(
              'Report Submitted',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _C.textDark),
            ),
            const SizedBox(height: 8),
            const Text(
              'Our team will review and take action soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: _C.textMid),
            ),
            const SizedBox(height: 20),
            _SpringButton(
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_C.teal, _C.tealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: _C.tealDark.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: const Center(
                  child: Text('Back to Home',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                SliverToBoxAdapter(child: _buildHeroHeader()),

                // ── Form body ──────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Info banner
                        _InfoBanner(),
                        const SizedBox(height: 16),

                        // Restroom name
                        _RestroomChip(name: widget.restroomName),
                        const SizedBox(height: 24),

                        // Issue type
                        _sectionLabel('Issue Type *'),
                        const SizedBox(height: 12),
                        ...issueTypes.map((issue) => _IssueOption(
                              icon: issue['icon'] as IconData,
                              label: issue['label'] as String,
                              value: issue['value'] as String,
                              selected:
                                  selectedIssue == issue['value'],
                              onTap: () => setState(
                                  () => selectedIssue =
                                      issue['value'] as String),
                            )),

                        const SizedBox(height: 24),

                        // Description
                        _sectionLabel('Additional Details *'),
                        const SizedBox(height: 10),
                        _styledTextField(
                          controller: _descriptionController,
                          hint: 'Please describe the issue in detail…',
                          maxLines: 5,
                          maxLength: 500,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'At least 20 characters',
                          style: TextStyle(
                              fontSize: 11, color: _C.textLight),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        _sectionLabel('Contact Email (Optional)'),
                        const SizedBox(height: 10),
                        _styledTextField(
                          controller: _emailController,
                          hint: 'your.email@example.com',
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'We will contact you if we need more information',
                          style: TextStyle(
                              fontSize: 11, color: _C.textLight),
                        ),
                        const SizedBox(height: 20),

                        // Anonymous toggle
                        _AnonymousToggle(
                          value: isAnonymous,
                          onChanged: (v) =>
                              setState(() => isAnonymous = v),
                        ),
                        const SizedBox(height: 20),

                        // Guidelines
                        _GuidelinesCard(),
                        const SizedBox(height: 32),

                        // Submit
                        _SpringButton(
                          onTap: isSubmitting ? () {} : _submitReport,
                          child: Container(
                            width: double.infinity,
                            padding:
                                const EdgeInsets.symmetric(vertical: 17),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_C.teal, _C.tealDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: _C.tealDark.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Center(
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2),
                                    )
                                  : const Text(
                                      'Submit Report',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Cancel
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                                foregroundColor: _C.textMid),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600),
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
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Stack(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_C.teal, _C.tealDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 28),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.flag_rounded,
                    size: 32, color: Colors.white),
              ),
              const SizedBox(height: 12),
              const Text(
                'Report Issue',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Help us improve restroom information',
                style: TextStyle(
                    fontSize: 12, color: Colors.white.withOpacity(0.8)),
              ),
            ],
          ),
        ),
        Positioned(
          top: 40,
          left: 6,
          child: SafeArea(
            child: _BackButton(onTap: () => Navigator.pop(context)),
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _C.textDark,
          letterSpacing: 0.2,
        ),
      );

  Widget _styledTextField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 13, color: _C.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle:
            const TextStyle(fontSize: 13, color: _C.textLight),
        filled: true,
        fillColor: _C.fieldFill,
        counterStyle:
            const TextStyle(fontSize: 11, color: _C.textLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _C.tealDark, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Info banner
// ─────────────────────────────────────────────
class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.teal.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.tealDark.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _C.tealDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.info_rounded,
                size: 18, color: _C.tealDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Help us improve',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark),
                ),
                SizedBox(height: 3),
                Text(
                  'Your report helps make information more accurate and useful for everyone.',
                  style:
                      TextStyle(fontSize: 11, color: _C.textMid),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Restroom chip
// ─────────────────────────────────────────────
class _RestroomChip extends StatelessWidget {
  final String name;
  const _RestroomChip({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _C.divider, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _C.teal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wc_rounded,
                size: 20, color: _C.tealDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reporting about',
                  style: TextStyle(
                      fontSize: 10,
                      color: _C.textLight,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _C.textDark),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Issue option
// ─────────────────────────────────────────────
class _IssueOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _IssueOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? _C.teal.withOpacity(0.25)
              : _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _C.tealDark : _C.divider,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: selected
                    ? _C.tealDark.withOpacity(0.2)
                    : _C.fieldFill,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                  size: 18,
                  color: selected ? _C.tealDark : _C.textLight),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: selected ? _C.textDark : _C.textMid,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: _C.tealDark,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    size: 14, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Anonymous toggle
// ─────────────────────────────────────────────
class _AnonymousToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  const _AnonymousToggle(
      {required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _C.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _C.divider, width: 1),
        ),
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
                  color: value ? _C.tealDark : _C.textLight,
                  width: 2,
                ),
              ),
              child: value
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Report Anonymously',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _C.textDark),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your name will not be shown in the report',
                    style:
                        TextStyle(fontSize: 11, color: _C.textMid),
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
// Guidelines card
// ─────────────────────────────────────────────
class _GuidelinesCard extends StatelessWidget {
  static const _lines = [
    'Provide accurate and honest information',
    'Do not use offensive or inappropriate language',
    'Provide sufficient details for us to verify the issue',
    'False reports may result in penalties',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _C.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _C.divider, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.gavel_rounded, size: 14, color: _C.textMid),
              const SizedBox(width: 6),
              const Text(
                'Reporting Guidelines',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _C.textDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ..._lines.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 5),
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                          color: _C.tealDark,
                          shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(t,
                          style: const TextStyle(
                              fontSize: 11, color: _C.textMid)),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Circle back button
// ─────────────────────────────────────────────
class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton>
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
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
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
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.arrow_back,
              size: 22, color: _C.textDark),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Spring press wrapper
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
    _scale = Tween(begin: 1.0, end: 0.96)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
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
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (_, child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

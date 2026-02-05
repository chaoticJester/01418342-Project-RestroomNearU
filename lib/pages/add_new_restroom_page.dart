import 'package:flutter/material.dart';

class AddNewRestroomPage extends StatefulWidget {
  const AddNewRestroomPage({Key? key}) : super(key: key);

  @override
  State<AddNewRestroomPage> createState() => _AddNewRestroomPageState();
}

class _AddNewRestroomPageState extends State<AddNewRestroomPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool isFree = true;
  bool isPaid = false;
  bool is24Hours = true;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;
  
  // Amenities
  bool hasToiletPaper = true;
  bool hasSoap = true;
  bool hasWarmWater = true;
  bool hasWifi = true;
  bool hasElectricOutlet = true;
  bool isWheelchairAccessible = true;
  
  List<String> photoUrls = [];

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(BuildContext context, bool isOpenTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isOpenTime) {
          openTime = picked;
        } else {
          closeTime = picked;
        }
      });
    }
  }

  void _useCurrentLocation() {
    // TODO: Implement location picker with geolocator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Getting current location...')),
    );
  }

  void _addPhoto() {
    // TODO: Implement image picker
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Opening camera/gallery...')),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement form submission to Firebase Firestore
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submitting restroom data...')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with animated back button
                  Row(
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => Navigator.pop(context),
                          borderRadius: BorderRadius.circular(20),
                          splashColor: Colors.black.withOpacity(0.1),
                          highlightColor: Colors.black.withOpacity(0.05),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black, width: 1),
                            ),
                            child: const Icon(
                              Icons.arrow_back,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Add New Restroom',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Location In Map
                  const Text(
                    'Location In Map',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Map Preview (Placeholder)
                  Container(
                    width: double.infinity,
                    height: 152,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[300],
                    ),
                    child: const Center(
                      child: Icon(Icons.map, size: 48, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Use Current Location with hover effect
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _useCurrentLocation,
                      borderRadius: BorderRadius.circular(8),
                      splashColor: const Color(0xFFFFA4A4).withOpacity(0.2),
                      highlightColor: const Color(0xFFFFA4A4).withOpacity(0.1),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.location_pin, color: Color(0xFFFFA4A4), size: 24),
                            SizedBox(width: 3),
                            Text(
                              'Use Current Location',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFFFA4A4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name Field
                  const Text(
                    'Name',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2nd Floor Engineering Building Restroom',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.withOpacity(0.8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFFA4A4), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Location Field
                  const Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 2nd Floor Engineering Building Restroom',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.withOpacity(0.8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFFA4A4), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 16),

                  // Price
                  const Text(
                    'Price',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Free Checkbox with ripple effect
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isFree = true;
                              isPaid = false;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          splashColor: const Color(0xFFFFA4A4).withOpacity(0.2),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isFree ? const Color(0xFFFFA4A4) : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isFree ? const Color(0xFFFFA4A4) : Colors.black,
                                    ),
                                  ),
                                  child: isFree
                                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Free',
                                  style: TextStyle(fontSize: 13, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Paid Checkbox with ripple effect
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              isFree = false;
                              isPaid = true;
                            });
                          },
                          borderRadius: BorderRadius.circular(8),
                          splashColor: const Color(0xFF2C2C2C).withOpacity(0.2),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                            child: Row(
                              children: [
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isPaid ? const Color(0xFF2C2C2C) : Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.black),
                                  ),
                                  child: isPaid
                                      ? const Icon(Icons.check, size: 10, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Paid',
                                  style: TextStyle(fontSize: 13, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Open/Close Time
                  const Text(
                    'Open/Close Time',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Open Time with hover effect
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectTime(context, true),
                            borderRadius: BorderRadius.circular(8),
                            splashColor: const Color(0xFFBADFDB).withOpacity(0.3),
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFD9D9D9)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    openTime?.format(context) ?? '--:--',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.access_time, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      // Close Time with hover effect
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _selectTime(context, false),
                            borderRadius: BorderRadius.circular(8),
                            splashColor: const Color(0xFFBADFDB).withOpacity(0.3),
                            child: Container(
                              height: 32,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFD9D9D9)),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    closeTime?.format(context) ?? '--:--',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.access_time, size: 16),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 24 Hrs Checkbox with ripple effect
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          is24Hours = !is24Hours;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      splashColor: const Color(0xFFFFA4A4).withOpacity(0.2),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: is24Hours ? const Color(0xFFFFA4A4) : Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: is24Hours ? const Color(0xFFFFA4A4) : Colors.black,
                                ),
                              ),
                              child: is24Hours
                                  ? const Icon(Icons.check, size: 10, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '24 Hrs',
                              style: TextStyle(fontSize: 13, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  const Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      hintText: '02-123-4567',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.withOpacity(0.8),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFFFFA4A4), width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Amenities
                  const Text(
                    'Amenities',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Amenities Grid
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildAmenityCheckbox(
                              'Toilet paper',
                              hasToiletPaper,
                              (value) => setState(() => hasToiletPaper = value),
                            ),
                          ),
                          Expanded(
                            child: _buildAmenityCheckbox(
                              'WiFi',
                              hasWifi,
                              (value) => setState(() => hasWifi = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAmenityCheckbox(
                              'Soap',
                              hasSoap,
                              (value) => setState(() => hasSoap = value),
                            ),
                          ),
                          Expanded(
                            child: _buildAmenityCheckbox(
                              'Electric OutLet',
                              hasElectricOutlet,
                              (value) => setState(() => hasElectricOutlet = value),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildAmenityCheckbox(
                              'Warm Water',
                              hasWarmWater,
                              (value) => setState(() => hasWarmWater = value),
                            ),
                          ),
                          Expanded(
                            child: _buildAmenityCheckbox(
                              'Wheelchair Accessible',
                              isWheelchairAccessible,
                              (value) => setState(() => isWheelchairAccessible = value),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Photo
                  const Text(
                    'Photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Add Photo Button with hover effect
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _addPhoto,
                          borderRadius: BorderRadius.circular(6),
                          splashColor: const Color(0xFFBADFDB).withOpacity(0.3),
                          child: Container(
                            width: 68,
                            height: 45,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: const Color(0xFFD9D9D9).withOpacity(0.87),
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Photo Preview (if available)
                      if (photoUrls.isNotEmpty)
                        Container(
                          width: 68,
                          height: 45,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[300],
                          ),
                          child: const Icon(Icons.image, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button with enhanced hover effect
                  Align(
                    alignment: Alignment.centerRight,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _submitForm,
                        borderRadius: BorderRadius.circular(8),
                        splashColor: const Color(0xFF8BC9C3),
                        highlightColor: const Color(0xFFA8D8D3),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 29, vertical: 11),
                          decoration: BoxDecoration(
                            color: const Color(0xFFBADFDB),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFD9D9D9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAmenityCheckbox(String label, bool value, Function(bool) onChanged) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFFFFA4A4).withOpacity(0.2),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: value ? const Color(0xFFFFA4A4) : Colors.white,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: value ? const Color(0xFFFFA4A4) : Colors.black,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check, size: 10, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 13, color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

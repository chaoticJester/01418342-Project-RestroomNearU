import 'package:flutter/material.dart';

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

class _ReportIssuePageState extends State<ReportIssuePage> {
  String? selectedIssue;
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  bool isAnonymous = false;
  bool isSubmitting = false;

  final List<Map<String, dynamic>> issueTypes = [
    {'value': 'location', 'label': 'Incorrect Location', 'icon': '📍'},
    {'value': 'closed', 'label': 'Permanently Closed', 'icon': '🚫'},
    {'value': 'price', 'label': 'Incorrect Price', 'icon': '💰'},
    {'value': 'hours', 'label': 'Incorrect Opening Hours', 'icon': '🕐'},
    {'value': 'amenities', 'label': 'Incorrect Amenities Information', 'icon': '🚽'},
    {'value': 'duplicate', 'label': 'Duplicate Entry', 'icon': '📋'},
    {'value': 'other', 'label': 'Other', 'icon': '❓'},
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (selectedIssue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an issue type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_descriptionController.text.trim().length < 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide at least 20 characters of description'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    // TODO: Submit report to Firebase
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        isSubmitting = false;
      });

      // Show success dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFFFCF9EA),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Report Submitted',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We have received your report. Our team will review and take action soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    Navigator.of(context).pop(); // Close report page
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBADFDB),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Back to Home',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF9EA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFBADFDB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Report Issue',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Box
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Help us improve',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your report will help make information more accurate and useful',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[800],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Restroom Info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reporting an issue about',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.restroomName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Issue Type Selection
              const Text(
                'Issue Type *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              ...issueTypes.map((issue) {
                final isSelected = selectedIssue == issue['value'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIssue = issue['value'] as String;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFBADFDB) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFFBADFDB)
                            : Colors.grey.withOpacity(0.2),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          issue['icon'] as String,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            issue['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),

              const SizedBox(height: 24),

              // Description
              const Text(
                'Additional Details *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                maxLines: 5,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Please describe the issue in detail...',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBADFDB), width: 2),
                  ),
                ),
              ),
              const Text(
                'At least 20 characters',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // Optional Email
              const Text(
                'Contact Email (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'your.email@example.com',
                  hintStyle: const TextStyle(fontSize: 13),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFBADFDB), width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'We will contact you if we need more information',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 24),

              // Anonymous Option
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: isAnonymous,
                      onChanged: (value) {
                        setState(() {
                          isAnonymous = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFFBADFDB),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Report Anonymously',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Your name will not be shown in the report',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Guidelines
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reporting Guidelines:',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...const [
                      'Provide accurate and honest information',
                      'Do not use offensive or inappropriate language',
                      'Provide sufficient details for us to verify the issue',
                      'False reports may result in penalties',
                    ].map((text) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(fontSize: 11)),
                          Expanded(
                            child: Text(
                              text,
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBADFDB),
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : const Text(
                          'Submit Report',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 12),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

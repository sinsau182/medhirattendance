import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SalaryAdvanceForm extends StatefulWidget {
  const SalaryAdvanceForm({Key? key}) : super(key: key);

  @override
  _SalaryAdvanceFormState createState() => _SalaryAdvanceFormState();
}

class _SalaryAdvanceFormState extends State<SalaryAdvanceForm> {
  final _amountController = TextEditingController();
  final _reasonController = TextEditingController();
  final _commentController = TextEditingController();
  final _documentController = TextEditingController();
  String? _selectedReason;
  String? _selectedRepaymentPlan = 'Lump Sum (One-time)';
  final List<String> _reasons = ['Medical Emergency', 'Education', 'Personal', 'Other'];
  final List<String> _repaymentPlans = ['Lump Sum (One-time)', 'Installments'];
  String? _documentPath;

  Future<void> _submitAdvanceRequest() async {
    final String apiUrl = 'http://192.168.0.200:8084/payroll/advance';
    final Map<String, dynamic> advanceData = {
      "employeeId": "emp123", // Replace with actual employee ID
      "requestedAmount": double.tryParse(_amountController.text) ?? 0.0,
      "reason": _selectedReason ?? "",
      "repaymentPlan": _selectedRepaymentPlan ?? "",
      "comments": _commentController.text,
      "documentUrl": _documentPath ?? "",
      "status": "PENDING"
    };

    print('Sending advance data: ${jsonEncode(advanceData)}');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(advanceData),
      );

      if (response.statusCode == 200) {
        // Handle successful submission
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Advance request submitted successfully!')),
        );
      } else {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit advance request.')),
        );
      }
    } catch (e) {
      // Handle exception
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Request Salary Advance',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            const Text('Requested Amount (₹)'),
            const SizedBox(height: 6),
            _buildInputBox(controller: _amountController, hintText: '0.00'),
            const SizedBox(height: 10),
            const Text('Reason for Advance'),
            const SizedBox(height: 6),
            _buildDropdown(
              value: _selectedReason,
              items: _reasons,
              hint: 'Select a reason',
              onChanged: (value) => setState(() => _selectedReason = value),
            ),
            const SizedBox(height: 10),
            const Text('Repayment Plan'),
            const SizedBox(height: 6),
            _buildDropdown(
              value: _selectedRepaymentPlan,
              items: _repaymentPlans,
              onChanged: (value) => setState(() => _selectedRepaymentPlan = value),
            ),
            const SizedBox(height: 10),
            const Text('Additional Comments'),
            const SizedBox(height: 6),
            _buildInputBox(
              controller: _commentController,
              hintText: 'Provide any additional details to support your request',
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            const Text('Supporting Document (Optional)'),
            const SizedBox(height: 6),
            _buildUploadBox(),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitAdvanceRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Submit Advance Request',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: const Color(0xFFF4FBFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.teal,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    String? hint,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      hint: Text(hint ?? ''),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF4FBFB),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey[200]!),
          borderRadius: BorderRadius.circular(14),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: Colors.teal,
            width: 2.0,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg'],
        );
        if (result != null) {
          String fileName = result.files.single.name;
          _documentPath = result.files.single.path;
          setState(() {
            _documentController.text = fileName;
          });
        }
      },
      child: Container(
        height: 90,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF4FBFB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.upload,
                size: 20,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                _documentController.text.isEmpty
                    ? 'Click to upload document'
                    : _documentController.text,
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
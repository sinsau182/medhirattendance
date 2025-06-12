import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ExpenseForm extends StatefulWidget {
  const ExpenseForm({super.key});

  @override
  _ExpenseFormState createState() => _ExpenseFormState();
}

class _ExpenseFormState extends State<ExpenseForm> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _receiptController = TextEditingController();
  String? _receiptPath;

  Future<void> _submitExpense() async {
    final String apiUrl = 'http://192.168.0.200:8084/payroll/expenses';

    try {
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));

      // Add form fields
      request.fields['employeeId'] = 'emp123'; // Replace with actual employee ID
      request.fields['category'] = _categoryController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['amount'] = (_amountController.text.isNotEmpty)
          ? _amountController.text
          : '0.0';

      // Add receipt file if selected
      if (_receiptPath != null) {
        request.files.add(
          await http.MultipartFile.fromPath('receipt', _receiptPath!),
        );
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense submitted successfully!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit expense: ${response.body}')),
        );
      }
    } catch (e) {
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
            // Submit New Expense Heading
            Text(
              'Submit New Expense',
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),

            // Amount and Category Row
            Row(
              children: [
                // Amount Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Amount (₹)'),
                      const SizedBox(height: 6),
                      _buildInputBox(
                        controller: _amountController,
                        hintText: '0.0',
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Category Field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Category'),
                      const SizedBox(height: 6),
                      _buildInputBox(
                        controller: _categoryController,
                        hintText: 'Travels, meals',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Description Field (Increased Height)
            const Text('Description'),
            const SizedBox(height: 6),
            _buildInputBox(
              controller: _descriptionController,
              hintText: 'Provide details',
              maxLines: 3, // Increased height
            ),
            const SizedBox(height: 10),

            // Upload Receipt Field (Same Height as Description)
            const Text('Upload Receipt'),
            const SizedBox(height: 6),
            _buildUploadBox(), // New upload box
            const SizedBox(height: 18),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitExpense,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Submit Expense',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input Box Builder
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

  // Upload Box with Icon
  Widget _buildUploadBox() {
    return GestureDetector(
      onTap: () async {
        FilePickerResult? result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['jpg'],
        );
        if (result != null) {
          String fileName = result.files.single.name;
          _receiptPath = result.files.single.path;
          setState(() {
            _receiptController.text = fileName;
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
                _receiptController.text.isEmpty ? 'Upload Receipt' : _receiptController.text,
                style: GoogleFonts.inter(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

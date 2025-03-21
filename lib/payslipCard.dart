import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PayslipScreen extends StatefulWidget {
  final String month;

  const PayslipScreen({required this.month, Key? key}) : super(key: key);

  @override
  _PayslipScreenState createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  Map<String, dynamic>? payslipData;

  @override
  void initState() {
    super.initState();
    _fetchPayslipData();
  }

  Future<void> _fetchPayslipData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/payroll/payslips/emp123'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          payslipData = data;
        });
      } else {
        print('Failed to fetch payslip data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching payslip data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (payslipData == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0, left: 10.0, right: 10.0, bottom: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.teal.shade800),
                  onPressed: () => Navigator.pop(context),
                ),
                Text(
                  'Salary & Payroll',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                children: [
                  Icon(Icons.arrow_back, color: Colors.teal),
                  SizedBox(width: 5),
                  Text("Back to Payroll", style: TextStyle(color: Colors.teal, fontSize: 16)),
                ],
              ),
            ),
            SizedBox(height: 10),
            Card(
              color: Color(0xFFFDFEFE),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Payslip: ${widget.month}", style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(LucideIcons.download, size: 16),
                          label: Text("Download"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF19B5A5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F9F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("Net Salary", style: GoogleFonts.inter(color: Color(0xFF6B7473), fontWeight: FontWeight.w500)),
                                  SizedBox(height: 5),
                                  Text("₹${payslipData!['netSalary']}", style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text("Credited", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text("Credited on ${payslipData!['creditedDate']}", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                    Text("Earnings", style: GoogleFonts.inter(color: Color(0xFF858D8C), fontSize: 15, fontWeight: FontWeight.bold)),
                    _salaryRow("Basic Salary", "₹${payslipData!['basicSalary']}"),
                    _salaryRow("HRA", "₹${payslipData!['hra']}"),
                    _salaryRow("Conveyance Allowance", "₹${payslipData!['conveyanceAllowance']}"),
                    _salaryRow("Medical Allowance", "₹${payslipData!['medicalAllowance']}"),
                    _salaryRow("Special Allowance", "₹${payslipData!['specialAllowance']}"),
                    Divider(),
                    _salaryRow("Gross Salary", "₹${payslipData!['grossSalary']}", isBold: true),
                    SizedBox(height: 10),
                    Text("Deductions", style: GoogleFonts.inter(color: Color(0xFF858D8C), fontSize: 15, fontWeight: FontWeight.bold)),
                    _salaryRow("Provident Fund", "₹${payslipData!['providentFund']}"),
                    _salaryRow("Income Tax", "₹${payslipData!['incomeTax']}"),
                    Divider(),
                    _salaryRow("Total Deductions", "₹${payslipData!['totalDeductions']}", isBold: true),
                    Divider(),
                    _salaryRow("Net Salary", "₹${payslipData!['netSalary']}", isBold: true, color: Colors.teal),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _salaryRow(String title, String amount, {bool isBold = false, Color color = Colors.black}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.inter(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color, fontSize: 15)),
          Text(amount, style: GoogleFonts.inter(fontWeight: isBold ? FontWeight.bold : FontWeight.w500, color: color, fontSize: 15)),
        ],
      ),
    );
  }
}
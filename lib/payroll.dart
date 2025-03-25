import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'ExpenseForm.dart';
import 'AdvanceForm.dart';
import 'payslipCard.dart';
import 'package:intl/intl.dart';


class SalaryPayrollPage extends StatefulWidget {
  const SalaryPayrollPage({super.key});

  @override
  _SalaryPayrollPageState createState() => _SalaryPayrollPageState();
}

class _SalaryPayrollPageState extends State<SalaryPayrollPage> {
  int _selectedIndex = 0;
  final bool _showPaySlip = true;

  @override
  Widget build(BuildContext context) {
    double containerWidth = (MediaQuery.of(context).size.width - 20) / 3;

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
        onPressed: () => (
        Navigator.pop(context)
        ),
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
            const SizedBox(height: 16),
            // Tab Selector
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF1F4),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    left: _selectedIndex * containerWidth + 4,
                    top: 4,
                    child: Container(
                      width: containerWidth - 8,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      _buildTabItem(0, LucideIcons.creditCard, "Payslips"),
                      _buildTabItem(1, LucideIcons.receipt, "Expenses"),
                      _buildTabItem(2, LucideIcons.handCoins, "Advance"),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Payslips Section
            Expanded(
              child: _selectedIndex == 0
                  ? SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Padding(padding: const EdgeInsets.all(2.0),
                  child:
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MainCard(title: "This Month's Salary", amount: "₹31,000", icon: LucideIcons.creditCard),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SalaryCard(title: "Annual CTC", amount: "₹4,20,000", icon: LucideIcons.dollarSign),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SalaryCard(title: "Next Credit", amount: "31 Jul 2023", icon: LucideIcons.calendar),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      PayslipWidget(),
                    ],
                  ),
                ),
              )
                  : _selectedIndex == 1
                  ? SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExpenseForm(), // Your expense form widget
                    const SizedBox(height: 16),
                    ExpenseHistoryWidget(), // Your expense history widget
                  ],
                ),
              )
                  : SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Replace with actual widget for index 2
                    SalaryAdvanceForm(),
                    const SizedBox(height: 16),
                    RecentAdvanceRequests(),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(int index, IconData icon, String label) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
        },
        child: Container(
          alignment: Alignment.center,
          height: 48,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: _selectedIndex == index ? Colors.black : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: _selectedIndex == index ? Colors.black : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}




class MainCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;

  const MainCard({required this.title, required this.amount, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
    elevation: 0.1,
        borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.teal[50],
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.teal, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

class SalaryCard extends StatelessWidget {
  final String title;
  final String amount;
  final IconData icon;

  const SalaryCard({required this.title, required this.amount, required this.icon, super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 0.1,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // Ensures everything is left-aligned
        children: [
          // Row for Icon + Title
          Row(
            children: [
              Icon(
                icon,
                color: Colors.teal,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4), // Space between rows
          // Row for Amount/Date
          Text(
            amount,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
      ),
    );
  }
}




class PayslipWidget extends StatefulWidget {
  const PayslipWidget({super.key});

  @override
  _PayslipWidgetState createState() => _PayslipWidgetState();
}

class _PayslipWidgetState extends State<PayslipWidget> {
  List<Map<String, dynamic>> payslips = [];

  @override
  void initState() {
    super.initState();
    _fetchPayslips();
  }

  Future<void> _fetchPayslips() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/payroll/payslips/employee/emp123'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print(response.body);
        setState(() {
          payslips = data.map((payslip) {
            return {
              "payslipId": payslip['payslipId'],
              "month": "${payslip['month']} ${payslip['year']}",
              "date": payslip['creditedDate'],
              "amount": "₹${payslip['netSalary']}",
            };
          }).toList();
        });
      } else {
        print('Failed to fetch payslips. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching payslips: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Previous Payslips",
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: ListView.separated(
                shrinkWrap: true,
                physics: BouncingScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: payslips.length,
                separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey[300]),
                itemBuilder: (context, index) {
                  final payslip = payslips[index];
                  return ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    title: Text(
                      payslip["month"]!,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                    ),
                    subtitle: Text(
                      "Credited: ${payslip["date"]}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          payslip["amount"]!,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        SizedBox(width: 8),
                        Icon(LucideIcons.arrowRight, size: 16, color: Colors.grey),
                      ],
                    ),
                    onTap: () {
                      print('Payslip ID: ${payslip["payslipId"]}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PayslipScreen(payslipId: payslip["payslipId"]!)
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}




class ExpenseHistoryWidget extends StatefulWidget {
  const ExpenseHistoryWidget({super.key});

  @override
  _ExpenseHistoryWidgetState createState() => _ExpenseHistoryWidgetState();
}

class _ExpenseHistoryWidgetState extends State<ExpenseHistoryWidget> {
  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    _fetchExpenses();
  }

  Future<void> _fetchExpenses() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/payroll/expenses/emp123'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          expenses = data.map((expense) {
            return {
              "category": expense['category'],
              "date": _formatTimestamp(expense['timestamp']),
              "amount": "₹${expense['amount']}",
              "status": expense['status'],
            };
          }).toList();
        });
      } else {
        print('Failed to fetch expenses. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching expenses: $e');
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime date = DateTime.parse(timestamp);
      return DateFormat('dd MMM yyyy').format(date); // Output: "15 Jun 2023"
    } catch (e) {
      return timestamp; // Fallback in case of error
    }
  }
@override
  Widget build(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(2.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Expense History",
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 4,
                spreadRadius: 1,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: expenses.map((expense) {
              return Container(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, color: Colors.grey[700]),
                        SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense["category"]!,
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "${expense["date"]} • ${expense["amount"]}",
                              style: TextStyle(color: Colors.grey[600], fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: expense["status"] == "Approved" ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        expense["status"]!,
                        style: TextStyle(
                          color: expense["status"] == "Approved" ? Colors.green[700] : Colors.orange[700],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    ),
  );
}
}




class RecentAdvanceRequests extends StatefulWidget {
  const RecentAdvanceRequests({super.key});

    @override
    _RecentAdvanceRequestsState createState() => _RecentAdvanceRequestsState();
  }

  class _RecentAdvanceRequestsState extends State<RecentAdvanceRequests> {
    List<Map<String, dynamic>> requests = [];

    @override
    void initState() {
      super.initState();
      _fetchAdvanceRequests();
    }

    Future<void> _fetchAdvanceRequests() async {
      try {
        final response = await http.get(Uri.parse('http://192.168.0.200:8084/payroll/advance/emp123'));
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          setState(() {
            requests = data.map((request) {
              return {
                "date": _formatTimestamp(request['timestamp']),
                "amount": "₹${request['requestedAmount']}",
                "purpose": request['reason'],
                "status": request['status'],
              };
            }).toList();
          });
        } else {
          print('Failed to fetch advance requests. Status code: ${response.statusCode}');
        }
      } catch (e) {
        print('Error fetching advance requests: $e');
      }
    }

    String _formatTimestamp(String timestamp) {
      try {
        DateTime date = DateTime.parse(timestamp);
        return DateFormat('dd MMM yyyy').format(date); // Output: "15 Jun 2023"
      } catch (e) {
        return timestamp; // Fallback in case of error
      }
    }

    @override
    Widget build(BuildContext context) {
      return Padding(
        padding: const EdgeInsets.all(2.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Recent Advance Requests",
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    spreadRadius: 1,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: requests.map((request) {
                  return Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      border: requests.last == request ? null : Border(bottom: BorderSide(color: Colors.grey[300]!)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(LucideIcons.handCoins, color: Colors.grey[700]),
                            SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${request["amount"]} Advance",
                                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "${request["date"]} • ${request["purpose"]}",
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: request["status"] == "Approved" ? Colors.green[100] : Colors.orange[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            request["status"]!,
                            style: TextStyle(
                              color: request["status"] == "Approved" ? Colors.green[700] : Colors.orange[700],
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      );
    }
  }

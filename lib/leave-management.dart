import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'ApplyLeave.dart';

class LeaveManagementScreen extends StatefulWidget {
  const LeaveManagementScreen({Key? key}) : super(key: key);

  @override
  _LeaveManagementScreenState createState() => _LeaveManagementScreenState();
}

class _LeaveManagementScreenState extends State<LeaveManagementScreen> {
  bool _showApplyLeaveForm = false;
  Map<String, int> _leaveBalance = {
    'casualLeave': 0,
    'sickLeave': 0,
    'privilegeLeave': 0,
  };

  List<Map<String, dynamic>> _leaveHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchLeaveBalance();
    _fetchLeaveHistory();
  }

  Future<void> _fetchLeaveBalance() async {
    try {
      print('Fetching leave balance...');
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/leaves/balance/emp123'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Leave balance fetched successfully: $data');
        setState(() {
          _leaveBalance = {
            'casualLeave': data['casualLeave'],
            'sickLeave': data['sickLeave'],
            'privilegeLeave': data['privilegeLeave'],
          };
        });
      } else {
        print('Failed to fetch leave balance. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leave balance: $e');
    }
  }

  Future<void> _fetchLeaveHistory() async {
    try {
      print('Fetching leave history...');
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/leaves/emp123'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Leave history fetched successfully: $data');
        setState(() {
          _leaveHistory = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print('Failed to fetch leave history. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching leave history: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4FBFB),
      body: Padding(
        padding: const EdgeInsets.only(top: 60.0, left: 16.0, right: 16.0, bottom: 16.0),
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
                  'Leave Management',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_showApplyLeaveForm)
              ApplyLeaveScreen()
            else ...[
              _buildLeaveBalanceCard(context),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showApplyLeaveForm = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Apply for Leave', style: TextStyle(color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Leave History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: _leaveHistory.map((leave) {
                    return _buildLeaveHistoryCard(
                      leave['leaveType'],
                      '${leave['startDate']} - ${leave['endDate']}',
                      leave['reason'],
                      leave['status'] == "Approved",
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveBalanceCard(BuildContext context) {
    return Card(
      color: Color(0xFFFDFEFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Leave Balance',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildLeaveProgressRow('Casual Leave', _leaveBalance['casualLeave']!, 12),
            _buildLeaveProgressRow('Sick Leave', _leaveBalance['sickLeave']!, 7),
            _buildLeaveProgressRow('Privilege Leave', _leaveBalance['privilegeLeave']!, 15),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveProgressRow(String title, int used, int total) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              Text(
                '$used / $total days',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: used / total,
            backgroundColor: Colors.grey.shade300,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.teal),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveHistoryCard(String title, String dateRange, String reason, bool approved) {
    return Card(
      color: Color(0xFFFDFEFE),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 0.2,
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: approved ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        approved ? Icons.check_circle : Icons.hourglass_empty,
                        color: approved ? Colors.green : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        approved ? 'Approved' : 'Pending',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: approved ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              dateRange,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 4),
            Text(
              reason,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
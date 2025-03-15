import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';
import 'check-in.dart';
import 'register.dart';
import 'view_attendance.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String username = "";
  int registeredUsers = 0;
  int checkInsToday = 0;

  @override
  void initState() {
    super.initState();
    fetchTotalUsers(); // Fetch total users on screen load
    fetchCheckInsToday();
  }

  Future<void> fetchTotalUsers() async {
    final url = Uri.parse('http://192.168.0.200:8082/api/users');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> users = json.decode(response.body);
        setState(() {
          registeredUsers = users.length;
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  Future<void> fetchCheckInsToday() async {
    final url = Uri.parse('http://192.168.0.200:8082/attendance/all');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        List<dynamic> attendanceList = json.decode(response.body);

        DateTime nowUtc = DateTime.now().toUtc();
        String formattedDate = nowUtc.toIso8601String().split('T')[0]; // "YYYY-MM-DD"

        int checkIns = attendanceList.where((entry) {
          if (entry.containsKey('timestamp') && entry['timestamp'] is String) {
            try {
              DateTime entryTime = DateTime.parse(entry['timestamp']).toUtc();
              String entryDate = entryTime.toIso8601String().split('T')[0];
              return entryDate == formattedDate;
            } catch (e) {
              print('Error parsing timestamp: $e');
              return false;
            }
          }
          return false;
        }).length;

        setState(() {
          checkInsToday = checkIns;
        });
      } else {
        throw Exception('Failed to load attendance');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
    }
  }


  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD9F9EC), // Light mint green background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Medhir',
          style: TextStyle(
            color: Colors.teal,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.teal),
            onPressed: _logout,
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // User Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, $username',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Registered Users and Check-Ins Today
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoBlock("Registered Users", registeredUsers),
                        ),
                        const SizedBox(width: 16), // Added space between boxes
                        Expanded(
                          child: _buildInfoBlock("Check-ins Today", checkInsToday),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Face Recognition Status
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green),
                          SizedBox(width: 8),
                          Text(
                            'Face recognition ready',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Check-In and Register User Tabs
            Row(
              children: [
                Expanded(
                  child: _buildButton(
                    icon: Icons.camera_alt_outlined,
                    label: "Quick Check-In",
                    color: Colors.teal,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CheckInScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 16), // Space between buttons
                Expanded(
                  child: _buildButton(
                    icon: Icons.person_add_alt_1_outlined,
                    label: "Register User",
                    color: Colors.teal,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => RegisterUserScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Attendance Tab (Styled like Face Recognition Tab)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.teal,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.bar_chart, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => ViewAttendanceScreen()),
                        );
                      },
                      child: const Text(
                        'View Attendance',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Info Block Widget
  Widget _buildInfoBlock(String label, int value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFDAF2F1),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "$value",
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.teal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // Reusable Button Widget
  Widget _buildButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }
}

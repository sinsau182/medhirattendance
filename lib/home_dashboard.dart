import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'login_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'attendance.dart';
import 'check-in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'manager_screen.dart';

class HomeDashboard extends StatefulWidget {
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class TimeDisplay extends StatefulWidget {
  @override
  _TimeDisplayState createState() => _TimeDisplayState();
}

class _TimeDisplayState extends State<TimeDisplay> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      DateFormat('HH:mm:ss').format(_now),
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }
}

class _HomeDashboardState extends State<HomeDashboard> {
  String employeeName = "";
  Map<String, dynamic>? dailyAttendance;
  bool isLoadingAttendance = false;

  // Attendance session state
  bool isCheckedIn = false;
  DateTime? sessionStartTime;
  Duration sessionDuration = Duration.zero;
  Timer? sessionTimer;

  final int dailyGoalSeconds = 8 * 60 * 60; // 8 hours

  String? employeeId;

  @override
  void initState() {
    super.initState();
    _loadEmployeeName();
    _loadDailyAttendance();
    _loadEmployeeId();
  }

  @override
  void dispose() {
    sessionTimer?.cancel();
    super.dispose();
  }

  // Add this method to handle page focus
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when page comes into focus
    _loadDailyAttendance();
  }

  Future<void> _loadEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final employeeId = prefs.getString('employeeId');
    if (token != null) {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      setState(() {
        employeeName = payload['name'] ?? "";
      });
    }
  }

  Future<void> _loadDailyAttendance() async {
    if (isLoadingAttendance) return;

    setState(() {
      isLoadingAttendance = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final employeeId = prefs.getString('employeeId');
      if (token == null) return;

      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

      final response = await http.get(
        Uri.parse('http://192.168.0.200:8082/employee/daily/$employeeId/$today'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final dailyAttendance = data['dailyAttendance'];
        final logs = dailyAttendance['logs'] as List;
        for (var log in logs) {
          final original = DateTime.parse(log['timestamp']);
          final adjusted = original.add(Duration(hours: 5, minutes: 30));
          log['timestamp'] = adjusted.toIso8601String();
        }
        setState(() {
          this.dailyAttendance = dailyAttendance;
          final logs = dailyAttendance['logs'] as List<dynamic>?;
          isCheckedIn = logs != null && logs.isNotEmpty && logs.last['type'] == 'checkin';
          if (isCheckedIn && logs != null && logs.isNotEmpty) {
            sessionStartTime = DateTime.parse(logs.last['timestamp']);
          } else {
            sessionStartTime = null;
          }
        });
      } else {
        setState(() {
          dailyAttendance = {
            'logs': [],
            'employeeId': employeeId,
            'date': today,
          };
        });
      }
    } catch (e) {
      setState(() {
        dailyAttendance = {
          'logs': [],
          'employeeId': employeeId,
          'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        };
      });
    } finally {
      setState(() {
        isLoadingAttendance = false;
      });
    }
  }

  // Add refresh function for button clicks
  Future<void> _refreshAttendance() async {
    await _loadDailyAttendance();
  }

  Future<void> _performCheckout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final employeeId = prefs.getString('employeeId');
      if (token == null) return;

      var uri = Uri.parse('http://192.168.0.200:8082/employee/checkout');
      var request = http.MultipartRequest('POST', uri);
      request.fields['employeeId'] = employeeId!;
      request.headers['Authorization'] = 'Bearer $token';

      var response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          isCheckedIn = false;
          sessionStartTime = null;
          sessionDuration = Duration.zero;
        });
        _loadDailyAttendance();
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Check-out failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during check-out. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startSession() {
    setState(() {
      isCheckedIn = true;
      sessionStartTime = DateTime.now();
      sessionDuration = Duration.zero;
    });
    _loadDailyAttendance(); // Reload data after check-in
  }

  void _endSession() {
    _performCheckout(); // Call the new checkout function
  }

  String _formatTime(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('hh:mm a').format(dateTime);
  }

  Duration _calculateTotalTime() {
    if (dailyAttendance == null || dailyAttendance!['logs'] == null) {
      return Duration.zero;
    }

    final logs = dailyAttendance!['logs'] as List;
    Duration total = Duration.zero;
    
    for (int i = 0; i < logs.length - 1; i += 2) {
      if (i + 1 < logs.length) {
        final checkIn = DateTime.parse(logs[i]['timestamp']);
        final checkOut = DateTime.parse(logs[i + 1]['timestamp']);
        total += checkOut.difference(checkIn);
      }
    }

    // If last log is check-in, add time until now
    if (logs.isNotEmpty && logs.last['type'] == 'checkin') {
      final lastCheckIn = DateTime.parse(logs.last['timestamp']);
      total += DateTime.now().difference(lastCheckIn);
    }

    return total;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      employeeId = prefs.getString('employeeId');
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<dynamic>? logs = dailyAttendance?['logs'] as List<dynamic>?;
    final bool isCurrentlyCheckedIn = logs != null && logs.isNotEmpty && logs.last['type'] == 'checkin';
    
    // Calculate total time from all sessions
    Duration totalSessionTime = Duration.zero;
    if (logs != null) {
      for (int i = 0; i < logs.length - 1; i += 2) {
        if (i + 1 < logs.length) {
          final checkIn = DateTime.parse(logs[i]['timestamp']);
          final checkOut = DateTime.parse(logs[i + 1]['timestamp']);
          totalSessionTime += checkOut.difference(checkIn);
        }
      }
      // Add current session time if last log is check-in
      if (isCurrentlyCheckedIn && sessionStartTime != null) {
        totalSessionTime += DateTime.now().difference(sessionStartTime!);
      }
    }

    final double progress = totalSessionTime.inSeconds / dailyGoalSeconds;
    final int hours = totalSessionTime.inHours;
    final int minutes = totalSessionTime.inMinutes.remainder(60);
    final int secondsLeft = (dailyGoalSeconds - totalSessionTime.inSeconds).clamp(0, dailyGoalSeconds);
    final int hoursLeft = secondsLeft ~/ 3600;
    final int minutesLeft = (secondsLeft % 3600) ~/ 60;
    final bool goalAchieved = progress >= 1.0;

    // --- Bottom NavBar logic ---
    Future<bool> isManager() async {
      final prefs = await SharedPreferences.getInstance();
      final rolesString = prefs.getString('roles');
      if (rolesString != null) {
        final roles = List<String>.from(json.decode(rolesString));
        return roles.contains('MANAGER');
      }
      return false;
    }

    return Scaffold(
      backgroundColor: Color(0xFFF7F8FA),
      body: RefreshIndicator(
        onRefresh: _refreshAttendance,
        child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // AppBar
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(0xFFE3E6F6),
                    child: Icon(Icons.business, color: Color(0xFF5B6BFF)),
                  ),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Text("Medhir Attendance",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          )),
                        Text(
                          "Employee: $employeeName",
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                  Spacer(),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.account_circle, color: Colors.black54),
                      onSelected: (value) async {
                        if (value == 'logout') {
                        final confirm = await showModalBottomSheet<bool>(
                          context: context,
                          backgroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                          ),
                          builder: (context) => Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 40,
                                  height: 4,
                                  margin: EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                Icon(Icons.logout, color: Colors.red, size: 36),
                                SizedBox(height: 12),
                                Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                SizedBox(height: 8),
                                Text('Are you sure you want to logout?', style: TextStyle(color: Colors.black54, fontSize: 15)),
                                SizedBox(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: Text('Cancel'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: BorderSide(color: Colors.grey[300]!),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ),
                                        icon: Icon(Icons.logout),
                                        label: Text('Logout'),
                                        onPressed: () => Navigator.pop(context, true),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                        if (confirm == true) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('authToken');
                          await prefs.remove('employeeId');
                          await prefs.remove('employeeName');
                          await prefs.remove('roles');

                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (context) => LoginScreen()),
                              (route) => false,
                            );
                          }
                        }
                      }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                padding: EdgeInsets.all(4),
                                child: Icon(Icons.logout, color: Colors.red, size: 20),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Logout',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                ],
              ),
              SizedBox(height: 18),
                  ],
                ),
                SizedBox(height: 24),


              // Time Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TimeDisplay(),
                    SizedBox(height: 4),
                    Text(
                        DateFormat('EEEE, MMMM d, y').format(DateTime.now()),
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    SizedBox(height: 10),
                      // Checked In/Out Badge
                      Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: isCheckedIn ? Color(0xFFE6F9ED) : Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: isCheckedIn ? Color(0xFF34D399) : Color(0xFFD1D5DB),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                isCheckedIn ? "Checked In" : "Checked Out",
                                style: TextStyle(
                                  color: isCheckedIn ? Color(0xFF059669) : Color(0xFF4B5563),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                  ],
                ),
              ),
              SizedBox(height: 16),
                            // Progress Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text("Today's Progress",
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            )),
                        Spacer(),
                          if (!goalAchieved)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Color(0xFFE3EDFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "${hoursLeft}h ${minutesLeft}m to go",
                                style: TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          if (goalAchieved)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0xFFE6F9ED),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            "Goal Achieved!",
                            style: TextStyle(
                              color: Color(0xFF1DBF73),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                            "${hours}h ${minutes}m",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                        Spacer(),
                        Text(
                            "${(progress * 100).clamp(0, 100).toStringAsFixed(0)}%",
                          style: TextStyle(
                              color: Color(0xFF2563EB),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 7,
                      backgroundColor: Color(0xFFE3E6F6),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5B6BFF)),
                    ),
                    SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("0h", style: TextStyle(color: Colors.black38)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              // Check-In/Out Buttons

              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCheckedIn
                              ? [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)]
                              : [Color(0xFF1DBF73).withOpacity(0.1), Color(0xFF1DBF73).withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCheckedIn ? Colors.grey : Color(0xFF1DBF73),
                        ),
                      ),
                      child: OutlinedButton.icon(
                        onPressed: isCheckedIn
                            ? null
                            : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => CheckInScreen()),
                                );
                                _loadDailyAttendance();
                              },
                        icon: Icon(Icons.login, color: isCheckedIn ? Colors.grey : Color(0xFF1DBF73)),
                        label: Text("Check-In"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isCheckedIn ? Colors.grey : Color(0xFF1DBF73),
                          side: BorderSide.none,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isCheckedIn 
                            ? [Colors.red.withOpacity(0.1), Colors.red.withOpacity(0.05)]
                            : [Colors.grey.withOpacity(0.1), Colors.grey.withOpacity(0.05)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCheckedIn ? Colors.red : Colors.grey,
                        ),
                      ),
                      child: OutlinedButton.icon(
                        onPressed: isCheckedIn
                            ? () async {
                                await _performCheckout();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white),
                                          SizedBox(width: 8),
                                          Text('Check-out successful!'),
                                        ],
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: Icon(Icons.logout, color: isCheckedIn ? Colors.red : Colors.grey),
                        label: Text("Check-Out"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isCheckedIn ? Colors.red : Colors.grey,
                          side: BorderSide.none,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Monthly Summary Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AttendanceScreen()),
                      );
                    },
                  icon: Icon(Icons.insert_chart_outlined, color: Color(0xFF232B55)),
                  label: Text(
                    "Monthly Summary",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF232B55),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Color(0xFFE3E6F6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Time Entries
              Text(
                "Time Entries",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 10),
              if (isLoadingAttendance)
                Center(child: CircularProgressIndicator())
              else if (dailyAttendance == null || (dailyAttendance!['logs'] as List).isEmpty)
                Center(child: Text("No attendance data available"))
              else
                Column(
                  children: [
                    ...List.generate(
                      (dailyAttendance!['logs'] as List).length ~/ 2 + ((dailyAttendance!['logs'] as List).length % 2),
                      (index) {
                        final logs = dailyAttendance!['logs'] as List;
                        final checkInIndex = index * 2;
                        final checkOutIndex = checkInIndex + 1;
                        
                        // Calculate session duration
                        Duration sessionDuration = Duration.zero;
                        if (checkOutIndex < logs.length) {
                          final checkIn = DateTime.parse(logs[checkInIndex]['timestamp']);
                          final checkOut = DateTime.parse(logs[checkOutIndex]['timestamp']);
                          sessionDuration = checkOut.difference(checkIn);
                        } else if (checkInIndex < logs.length) {
                          // If last log is check-in, calculate until now
                          final checkIn = DateTime.parse(logs[checkInIndex]['timestamp']);
                          sessionDuration = DateTime.now().difference(checkIn);
                        }

                        return Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("In", style: TextStyle(color: Colors.black54)),
                                    SizedBox(height: 4),
                                    Text(
                                      _formatTime(logs[checkInIndex]['timestamp']),
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                SizedBox(width: 24),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Out", style: TextStyle(color: Colors.black54)),
                                    SizedBox(height: 4),
                                    Text(
                                      checkOutIndex < logs.length
                                          ? _formatTime(logs[checkOutIndex]['timestamp'])
                                          : "--:--",
                                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                Spacer(),
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: checkOutIndex < logs.length
                                        ? Color(0xFFF3F4F6)
                                        : Color(0xFFE3EDFF),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (checkOutIndex >= logs.length)
                                        Icon(Icons.access_time, size: 16, color: Color(0xFF2563EB)),
                                      if (checkOutIndex >= logs.length)
                                        SizedBox(width: 4),
                                      Text(
                                        _formatDuration(sessionDuration),
                                        style: TextStyle(
                                          color: checkOutIndex < logs.length
                                              ? Color(0xFF232B55)
                                              : Color(0xFF2563EB),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              SizedBox(height: 24),
            ],
            ),
          ),
        ),
      ),
      // Show bottom nav only if manager
      bottomNavigationBar: FutureBuilder<bool>(
        future: isManager(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done || !snapshot.hasData || !snapshot.data!) {
            return SizedBox.shrink();
          }
          return BottomNavigationBar(
            currentIndex: 0, // Personal
            onTap: (index) {
              if (index == 0) {
                // Already on HomeDashboard
              } else if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => ManagerScreen()),
                );
              }
            },
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF4F8CFF),
            unselectedItemColor: Colors.grey[400],
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                label: 'Personal',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.groups),
                label: 'Team',
              ),
            ],
          );
        },
      ),
    );
  }
}
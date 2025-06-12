import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jwt_decode/jwt_decode.dart';
import 'login_screen.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'attendance.dart';
import 'check-in.dart';

class HomeDashboard extends StatefulWidget {
  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  String employeeName = "";
  DateTime _now = DateTime.now();
  Timer? _timer;

  // Attendance session state
  bool isCheckedIn = false;
  DateTime? sessionStartTime;
  Duration sessionDuration = Duration.zero;
  Timer? sessionTimer;

  final int dailyGoalSeconds = 8 * 60 * 60; // 8 hours

  @override
  void initState() {
    super.initState();
    _loadEmployeeName();
    _now = DateTime.now();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _now = DateTime.now();
        if (isCheckedIn && sessionStartTime != null) {
          sessionDuration = DateTime.now().difference(sessionStartTime!);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    sessionTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    if (token != null) {
      Map<String, dynamic> payload = Jwt.parseJwt(token);
      setState(() {
        employeeName = payload['name'] ?? "";
      });
    }
  }

  void _startSession() {
    setState(() {
      isCheckedIn = true;
      sessionStartTime = DateTime.now();
      sessionDuration = Duration.zero;
    });
  }

  void _endSession() {
    setState(() {
      isCheckedIn = false;
      sessionStartTime = null;
      sessionDuration = Duration.zero;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double progress = sessionDuration.inSeconds / dailyGoalSeconds;
    final int hours = sessionDuration.inHours;
    final int minutes = sessionDuration.inMinutes.remainder(60);
    final int secondsLeft = (dailyGoalSeconds - sessionDuration.inSeconds).clamp(0, dailyGoalSeconds);
    final int hoursLeft = secondsLeft ~/ 3600;
    final int minutesLeft = (secondsLeft % 3600) ~/ 60;
    final bool goalAchieved = progress >= 1.0;

    return Scaffold(
      backgroundColor: Color(0xFFF7F8FA),
      body: SafeArea(
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
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                            content: Text('Are you sure you want to logout?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text('Cancel'),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: Icon(Icons.logout),
                                label: Text('Logout'),
                                onPressed: () => Navigator.pop(context, true),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('authToken');
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
                    Text(
                      DateFormat('hh:mm a').format(_now),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(_now),
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
                    // Session Timer Card
                    if (isCheckedIn && sessionStartTime != null) ...[
                      SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFF1F6FE),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.access_time, color: Color(0xFF2563EB)),
                                SizedBox(width: 6),
                                Text(
                                  "Current Session",
                                  style: TextStyle(
                                    color: Color(0xFF2563EB),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6),
                            Text(
                              _formatDuration(sessionDuration),
                              style: TextStyle(
                                color: Color(0xFF232B55),
                                fontWeight: FontWeight.bold,
                                fontSize: 28,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    SizedBox(height: 2),
                    Text(
                      "Location verified",
                      style: TextStyle(
                        color: Colors.black38,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Check-In/Out Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => CheckInScreen()),
                        );
                      },
                      icon: Icon(Icons.login, color: Colors.white),
                      label: Text("Check-In"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF1DBF73),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: isCheckedIn ? _endSession : null,
                      icon: Icon(Icons.logout, color: Colors.white),
                      label: Text("Check-Out"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isCheckedIn ? Color(0xFF232B55) : Color(0xFFE9E9E9),
                        foregroundColor: isCheckedIn ? Colors.white : Colors.black26,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        textStyle: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
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
                        Text("Daily Goal: 8h 0m", style: TextStyle(color: Colors.black38)),
                      ],
                    ),
                    SizedBox(height: 10),
                    if (!goalAchieved)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                        decoration: BoxDecoration(
                          color: Color(0xFFFFF9E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Text("💪", style: TextStyle(fontSize: 20)),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "You're almost there! Keep it up.",
                                style: TextStyle(
                                  color: Color(0xFFB08800),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
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
              Container(
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
                        Text("9:00 AM", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    SizedBox(width: 24),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Out", style: TextStyle(color: Colors.black54)),
                        SizedBox(height: 4),
                        Text("12:30 PM", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Spacer(),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        "3h 30m",
                        style: TextStyle(
                          color: Color(0xFF232B55),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
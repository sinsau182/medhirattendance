import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:medhir/leave-management.dart';
import 'package:medhir/payroll.dart';
import 'attendance.dart';
import 'myprofile.dart';
import 'notification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medhir/check-in.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      body: SingleChildScrollView(
        child: EmployeeDashboard(),
      ),
    ),
  ));
}

class EmployeeDashboard extends StatefulWidget {
  const EmployeeDashboard({super.key});

  @override
  _EmployeeDashboardState createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  bool isCheckedIn = false;
  DateTime? checkInTime;
  OverlayEntry? _overlayEntry;
  bool showAllUpdates = false;

  void handleCheckInOut() {
    if (isCheckedIn) {
      handleCheckOut();
      setState(() {
        isCheckedIn = false;
      });
    } else {
      handleCheckIn();
    }
  }

  void showTopPopup(String message, String subMessage) {
    _overlayEntry?.remove();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 10,
        right: 10,
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(8),
          color: Colors.white,
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.black),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _overlayEntry?.remove();
                    _overlayEntry = null;
                  },
                  child: Text(
                    "OK",
                    style: TextStyle(color: Colors.black),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);

    Future.delayed(Duration(seconds: 5), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void handleCheckIn() async {
    DateTime now = DateTime.now();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CheckInScreen()),
    );

    if (result == true) {
      setState(() {
        isCheckedIn = true;
        checkInTime = now;
      });
      showTopPopup(
        'Successfully checked in!',
        'Check-in time: ${now.hour}:${now.minute}:${now.second}',
      );
    }
  }

  void handleCheckOut() {
    if (checkInTime != null) {
      final duration = DateTime.now().difference(checkInTime!);
      final workedHours = duration.inHours + (duration.inMinutes % 60) / 60;
      showTopPopup(
        'Checked out successfully!',
        'You worked for ${workedHours.toStringAsFixed(2)} hours today.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xFFF4FBFB),
        child: SingleChildScrollView(

        child: Padding(

          padding: const EdgeInsets.only(top: 60, left: 16, right: 16, bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // Good Morning Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: 'Good Morning, ',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            TextSpan(
                              text: 'Alex',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black38,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => NotificationScreen()),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none, // Allows the Positioned widget to go out of bounds
                                children: [
                                  Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.black,
                                    size: 28,
                                  ),
                                  Positioned(
                                    top: -3,
                                    right: -3,
                                    child: Container(
                                      width: 12,
                                      height: 12,
                                      decoration: BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: 8),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 10), // ✅ Moved inside the Row's children
                      GestureDetector(
                        onTap: () {
                          print('Profile Picture Clicked');
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => MyProfileScreen()),
                          );
                        },
                        child: CircleAvatar(
                          backgroundColor: Colors.grey.shade300,
                          backgroundImage: AssetImage('assets/avatar.png'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 30),

              // Today's Status Card
              Card(
                color: Color(0xFFFFDFEFE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 18, left: 18, right: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Today's Status",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(
                                isCheckedIn ? Icons.circle : Icons.circle,
                                size: 12,
                                color: isCheckedIn ? Colors.teal : Colors.grey.shade600,
                              ),
                              SizedBox(width: 8),
                              Text(
                                isCheckedIn
                                    ? 'Checked in at ${checkInTime!.hour}:${checkInTime!.minute.toString().padLeft(2, '0')}'
                                    : 'Not checked in yet',
                                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: handleCheckInOut,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isCheckedIn ? Colors.red.shade400 : Color(0xFF04AF9E),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 1,
                        ),
                        child: Text(
                          isCheckedIn ? 'Check Out' : 'Check In',
                          style: GoogleFonts.inter(
                            color: Color(0xFFF5FCFB),
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 14),

              // Quick Actions
              Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  'Quick Actions',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(height: 12),
              _buildQuickActions(context),
              SizedBox(height: 20),

              // Agenda of the Day
              _buildAgendaOfTheDay(),
              SizedBox(height: 20),

              // Latest Updates
              _buildLatestUpdates(),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _quickActionItem('Leave', LucideIcons.calendar, Colors.blue, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => LeaveManagementScreen()),
          );
        }),
        _quickActionItem('Attendance', LucideIcons.clock, Colors.purple, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AttendanceScreen()),
          );
        }),
        _quickActionItem('Payroll', LucideIcons.creditCard, Colors.orange, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SalaryPayrollPage()),
          );
        }),
      ],
    );
  }

  Widget _quickActionItem(String label, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            radius: 24,
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaOfTheDay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1), // Light shadow
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4), // Shadow at the bottom
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(LucideIcons.calendarClock, color: Colors.teal),
              const SizedBox(width: 10),
              Text(
                'Agenda of the Day',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

            ],
          ),

          const SizedBox(height: 12),
          _agendaItem('Team Standup', '10:00 AM', LucideIcons.users, Colors.blue),
          _agendaItem('Lunch Break', '12:30 PM', LucideIcons.coffee, Colors.orange),
          _agendaItem('Quarterly Review', '02:00 PM', LucideIcons.calendarClock, Colors.purple),
          _agendaItem('Submit Weekly Report', '04:30 PM', LucideIcons.bookOpen, Colors.green),
        ],
      ),
    );
  }

  Widget _agendaItem(String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Space between items
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Padding inside the container
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0), // Light grey background
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Light shadow for depth
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2), // Subtle shadow below
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16), // Space between icon and text
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatestUpdates() {
    List<Widget> updates = [
      _updateItem('Your leave has been approved', 'Today, 09:45 AM', LucideIcons.checkCircle2, Colors.green),
      _updateItem('New company policy update', 'Yesterday, 03:30 PM', LucideIcons.alertCircle, Colors.red),
      _updateItem('Your payroll is processed', '2 days ago', LucideIcons.dollarSign, Colors.orange),
      if (showAllUpdates) ...[
        _updateItem('Team meet rescheduled to 4 PM', '2 days ago', LucideIcons.alertCircle, Colors.blue),
        _updateItem('Quarterly targets announced', '3 days ago', LucideIcons.alertCircle, Colors.purple),
      ]
    ];

    return _playCard(
      'Latest Updates',
      updates,
      footer: GestureDetector(
        onTap: () {
          setState(() {
            showAllUpdates = !showAllUpdates;
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                showAllUpdates ? 'Show Less' : 'See More',
                style: const TextStyle(color: Colors.teal, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Icon(
                showAllUpdates ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                color: Colors.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _updateItem(String title, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12), // Space between items
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12), // Padding inside the container
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Light shadow for depth
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4), // Shadow at the bottom
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16), // Space between icon and text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _playCard(String title, List<Widget> items, {Widget? footer}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...items,
          if (footer != null) footer,
        ],
      ),
    );
  }
}
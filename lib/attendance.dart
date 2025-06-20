import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _currentDate = DateTime.now();
  DateTime? _selectedDate; // Track which date's card is open
  bool _isLoading = true;
  Map<String, dynamic>? _attendanceData;

  // Legend/status mapping for demo
  final List<Map<String, dynamic>> legendList = [
    {'abbr': 'P', 'color': Color(0xFFC8F7D8), 'circle': Color(0xFF34C759), 'label': 'Present'},
    {'abbr': 'PH', 'color': Color(0xFFC8F7F7), 'circle': Color(0xFF4DD0E1), 'label': 'Present on Holiday'},
    {'abbr': 'P/A', 'color': Color(0xFFFFF6E0), 'circle': Color(0xFFFFB300), 'label': 'Half Day'},
    {'abbr': 'PH/A', 'color': Color(0xFFFFF6E0), 'circle': Color(0xFFFFB300), 'label': 'Half Day on Holiday'},
    {'abbr': 'A', 'color': Color(0xFFFFD6D6), 'circle': Color(0xFFFF3B30), 'label': 'Absent'},
    {'abbr': 'LOP', 'color': Color(0xFFFFE0E0), 'circle': Color(0xFFD32F2F), 'label': 'Loss of Pay'},
    {'abbr': 'H', 'color': Color(0xFFF3F3F3), 'circle': Color(0xFFBDBDBD), 'label': 'Holiday'},
    {'abbr': 'P/LOP', 'color': Color(0xFFE6E6FA), 'circle': Color(0xFF9575CD), 'label': 'Present Half Day on Loss of Pay'},
  ];

  // Map for calendar lookup - will be populated from API data
  Map<String, Map<String, dynamic>> statusMap = {};

  // Dummy work hours data for demonstration
  Map<String, Map<String, String>> workHoursData = {};

  @override
  void initState() {
    super.initState();
    _fetchAttendanceData();
  }

  Future<void> _fetchAttendanceData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final employeeId = prefs.getString('employeeId');
      final token = prefs.getString('authToken');

      if (employeeId == null || token == null) {
        print('Error: No employee ID or token found');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final year = _currentDate.year;
      final month = _currentDate.month;

      final response = await http.get(
        Uri.parse('http://192.168.0.200:8082/attendance-summary/$employeeId/$year/$month'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _attendanceData = data;
          _updateStatusMap(data);
          _updateWorkHoursData(data);
          _isLoading = false;
        });
      } else {
        print('Error fetching attendance data: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching attendance data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateStatusMap(Map<String, dynamic> data) {
    statusMap.clear();

    // Map present dates
    if (data['presentDates'] != null) {
      for (String date in data['presentDates']) {
        statusMap[date] = {
          'status': 'Present',
          'abbr': 'P',
          'color': Color(0xFFC8F7D8),
          'circle': Color(0xFF34C759)
        };
      }
    }

    // Map full leave dates (Absent)
    if (data['fullLeaveDates'] != null) {
      for (String date in data['fullLeaveDates']) {
        statusMap[date] = {
          'status': 'Absent',
          'abbr': 'A',
          'color': Color(0xFFFFD6D6),
          'circle': Color(0xFFFF3B30)
        };
      }
    }

    // Map half day leave dates (P/A)
    if (data['halfDayLeaveDates'] != null) {
      for (String date in data['halfDayLeaveDates']) {
        statusMap[date] = {
          'status': 'Half Day',
          'abbr': 'P/A',
          'color': Color(0xFFFFF6E0),
          'circle': Color(0xFFFFB300)
        };
      }
    }

    // Map full compoff dates (PH)
    if (data['fullCompoffDates'] != null) {
      for (String date in data['fullCompoffDates']) {
        statusMap[date] = {
          'status': 'Present on Holiday',
          'abbr': 'PH',
          'color': Color(0xFFC8F7F7),
          'circle': Color(0xFF4DD0E1)
        };
      }
    }

    // Map half compoff dates (PH/A)
    if (data['halfCompoffDates'] != null) {
      for (String date in data['halfCompoffDates']) {
        statusMap[date] = {
          'status': 'Half Day on Holiday',
          'abbr': 'PH/A',
          'color': Color(0xFFFFF6E0),
          'circle': Color(0xFFFFB300)
        };
      }
    }

    // Map weekly off dates (Holiday)
    if (data['weeklyOffDates'] != null) {
      for (String date in data['weeklyOffDates']) {
        statusMap[date] = {
          'status': 'Holiday',
          'abbr': 'H',
          'color': Color(0xFFF3F3F3),
          'circle': Color(0xFFBDBDBD)
        };
      }
    }

    // Map absent dates (Absent)
    if (data['absentDates'] != null) {
      for (String date in data['absentDates']) {
        statusMap[date] = {
          'status': 'Absent',
          'abbr': 'A',
          'color': Color(0xFFFFD6D6),
          'circle': Color(0xFFFF3B30)
        };
      }
    }

    // Add today's status if it's the current month
    final today = DateTime.now();
    if (today.year == _currentDate.year && today.month == _currentDate.month) {
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (!statusMap.containsKey(todayKey)) {
        statusMap[todayKey] = {
          'status': 'In Progress',
          'abbr': 'P',
          'color': Colors.orange,
          'circle': Colors.orange
        };
      }
    }
  }

  void _updateWorkHoursData(Map<String, dynamic> data) {
    workHoursData.clear();

    // Add present dates with default work hours
    if (data['presentDates'] != null) {
      for (String date in data['presentDates']) {
        workHoursData[date] = {
          'checkIn': '9:00 AM',
          'checkOut': '5:30 PM',
          'total': '8h 30m',
          'status': 'Present'
        };
      }
    }

    // Add half day leave dates
    if (data['halfDayLeaveDates'] != null) {
      for (String date in data['halfDayLeaveDates']) {
        workHoursData[date] = {
          'checkIn': '9:00 AM',
          'checkOut': '1:00 PM',
          'total': '4h 0m',
          'status': 'Half Day'
        };
      }
    }

    // Add full compoff dates
    if (data['fullCompoffDates'] != null) {
      for (String date in data['fullCompoffDates']) {
        workHoursData[date] = {
          'checkIn': '9:00 AM',
          'checkOut': '5:30 PM',
          'total': '8h 30m',
          'status': 'Present on Holiday'
        };
      }
    }

    // Add half compoff dates
    if (data['halfCompoffDates'] != null) {
      for (String date in data['halfCompoffDates']) {
        workHoursData[date] = {
          'checkIn': '9:00 AM',
          'checkOut': '1:00 PM',
          'total': '4h 0m',
          'status': 'Half Day on Holiday'
        };
      }
    }

    // Add absent dates
    if (data['absentDates'] != null) {
      for (String date in data['absentDates']) {
        workHoursData[date] = {
          'status': 'Absent'
        };
      }
    }

    // Add full leave dates
    if (data['fullLeaveDates'] != null) {
      for (String date in data['fullLeaveDates']) {
        workHoursData[date] = {
          'status': 'Absent'
        };
      }
    }

    // Add weekly off dates
    if (data['weeklyOffDates'] != null) {
      for (String date in data['weeklyOffDates']) {
        workHoursData[date] = {
          'status': 'Holiday'
        };
      }
    }

    // Add today's status if it's the current month
    final today = DateTime.now();
    if (today.year == _currentDate.year && today.month == _currentDate.month) {
      final todayKey = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (!workHoursData.containsKey(todayKey)) {
        workHoursData[todayKey] = {
          'checkIn': '10:00 AM',
          'status': 'In Progress'
        };
      }
    }
  }

  String _monthName(int month) {
    const List<String> monthNames = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return monthNames[month - 1];
  }

  void _previousWeek() {
    setState(() {
      _currentDate = _currentDate.subtract(Duration(days: 7));
    });
  }

  void _nextWeek() {
    setState(() {
      _currentDate = _currentDate.add(Duration(days: 7));
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime today = DateTime.now();
    DateTime? visibleDate = _selectedDate;
    String? visibleDateKey = visibleDate != null ? _dateKey(visibleDate) : null;
    Map<String, String>? visibleData = visibleDateKey != null ? workHoursData[visibleDateKey] : null;

    return Scaffold(
      backgroundColor: Color(0xFFF4FBFB),
      appBar: AppBar(
        title: const Text(
          'Attendance',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLegend(),
            const SizedBox(height: 20),
            _buildMonthlyCalendar(),
            const SizedBox(height: 10),
            if (visibleDate != null && visibleData != null && visibleData.isNotEmpty)
              _buildPlayCard(visibleDate, visibleData),
            SizedBox(height: 40), // Add bottom space to avoid overflow
          ],
        ),
      ),
    );
  }

  String _dateKey(DateTime date) => '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: legendList.map((legend) {
          final abbr = legend['abbr'];
          final color = legend['color'];
          final circle = legend['circle'];
          final label = legend['label'] ?? '';
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: circle,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 6),
                Text(abbr, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                SizedBox(width: 6),
                Text(label, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyCalendar() {
    DateTime firstDayOfMonth = DateTime(_currentDate.year, _currentDate.month, 1);
    DateTime lastDayOfMonth = DateTime(_currentDate.year, _currentDate.month + 1, 0);
    int startingWeekday = firstDayOfMonth.weekday;

    List<DateTime?> calendarDays = List.generate(42, (index) {
      int dayOffset = index - (startingWeekday - 1);
      DateTime? day;
      if (dayOffset >= 0 && dayOffset < lastDayOfMonth.day) {
        day = DateTime(_currentDate.year, _currentDate.month, dayOffset + 1);
      }
      return day;
    });

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 18, color: Colors.black),
                onPressed: _isLoading ? null : _previousMonth,
              ),
              Text(
                '${_monthName(firstDayOfMonth.month)} ${firstDayOfMonth.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black),
                onPressed: _isLoading ? null : _nextMonth,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Text(day, style: const TextStyle(fontWeight: FontWeight.bold)))
                .toList(),
          ),
          const SizedBox(height: 8),
          if (_isLoading)
            Container(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading attendance data...', style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 42,
              itemBuilder: (context, index) {
                DateTime? day = calendarDays[index];
                String dateKey = day != null ? _dateKey(day) : '';
                var legend = statusMap[dateKey];
                Color? color = legend != null ? (legend['circle'] ?? Colors.orange) : null;
                bool isSelected = _selectedDate != null && day != null &&
                  day.day == _selectedDate!.day &&
                  day.month == _selectedDate!.month &&
                  day.year == _selectedDate!.year;
                bool isToday = day != null &&
                  day.day == DateTime.now().day &&
                  day.month == DateTime.now().month &&
                  day.year == DateTime.now().year;

                return day == null
                    ? const SizedBox.shrink()
                    : GestureDetector(
                        onTap: () {
                          setState(() {
                            if (_selectedDate != null && _selectedDate!.day == day.day && _selectedDate!.month == day.month && _selectedDate!.year == day.year) {
                              _selectedDate = null; // Toggle off
                            } else {
                              _selectedDate = day;
                            }
                          });
                        },
                        child: Center(
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 120),
                            width: isSelected ? 34 : 28,
                            height: isSelected ? 34 : 28,
                            decoration: BoxDecoration(
                              color: color ?? Colors.transparent,
                              shape: BoxShape.circle,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))]
                                  : [],
                              border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
                            ),
                            child: Center(
                              child: Text(
                                day.day.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.black,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
              },
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
    _fetchAttendanceData();
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
    _fetchAttendanceData();
  }

  Widget _buildPlayCard(DateTime date, Map<String, String> data) {
    String status = data['status'] ?? 'In Progress';
    String? checkIn = data['checkIn'];
    String? checkOut = data['checkOut'];
    String? total = data['total'];
    Color statusColor;
    String abbr = '';
    IconData statusIcon;
    // Map status to color, abbr, and icon
    switch (status) {
      case 'Present':
        statusColor = Colors.green;
        abbr = 'P';
        statusIcon = Icons.check_circle;
        break;
      case 'Present on Holiday':
        statusColor = Color(0xFF4DD0E1);
        abbr = 'PH';
        statusIcon = Icons.celebration;
        break;
      case 'Half Day':
        statusColor = Colors.orange;
        abbr = 'P/A';
        statusIcon = Icons.adjust;
        break;
      case 'Half Day on Holiday':
        statusColor = Colors.orange;
        abbr = 'PH/A';
        statusIcon = Icons.adjust;
        break;
      case 'Absent':
        statusColor = Colors.red;
        abbr = 'A';
        statusIcon = Icons.cancel;
        break;
      case 'Loss of Pay':
        statusColor = Color(0xFFD32F2F);
        abbr = 'LOP';
        statusIcon = Icons.money_off;
        break;
      case 'Holiday':
        statusColor = Colors.grey;
        abbr = 'H';
        statusIcon = Icons.beach_access;
        break;
      case 'Present Half Day on Loss of Pay':
        statusColor = Color(0xFF9575CD);
        abbr = 'P/LOP';
        statusIcon = Icons.timelapse;
        break;
      case 'In Progress':
        statusColor = Colors.orange;
        abbr = 'P';
        statusIcon = Icons.timelapse;
        break;
      default:
        statusColor = Colors.grey;
        abbr = '';
        statusIcon = Icons.info;
    }
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(statusIcon, color: statusColor, size: 24),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          status,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: statusColor),
                        ),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(abbr, style: TextStyle(fontWeight: FontWeight.bold, color: statusColor)),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      DateFormat('EEEE, dd MMM yyyy').format(date),
                      style: TextStyle(fontWeight: FontWeight.w500, color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Divider(height: 28, thickness: 1, color: Colors.grey[200]),
          Row(
            children: [
              Icon(Icons.login, color: Colors.green),
              SizedBox(width: 8),
              Text('Check-In:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Text(checkIn ?? '--', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.logout, color: Colors.red),
              SizedBox(width: 8),
              Text('Check-Out:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Text(checkOut ?? '--', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.blue),
              SizedBox(width: 8),
              Text('Total:', style: TextStyle(fontWeight: FontWeight.w500)),
              SizedBox(width: 8),
              Text(total ?? '--', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

class HalfCirclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..arcToPoint(
        Offset(size.width / 2, size.height),
        radius: Radius.circular(size.width / 2),
        clockwise: false,
      )
      ..close();

    canvas.drawPath(path, paint);

    paint.color = Colors.green;
    final path2 = Path()
      ..moveTo(size.width / 2, 0)
      ..arcToPoint(
        Offset(size.width / 2, size.height),
        radius: Radius.circular(size.width / 2),
        clockwise: true,
      )
      ..close();

    canvas.drawPath(path2, paint);

    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
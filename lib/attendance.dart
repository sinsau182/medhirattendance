import 'package:flutter/material.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  _AttendanceScreenState createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  DateTime _currentDate = DateTime.now();
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
            _buildMonthlyCalendar(),
            const SizedBox(height: 20),
            const Text(
              'Work Hours Timeline',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildWorkHoursList(),
          ],
        ),
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
                onPressed: _previousMonth,
              ),
              Text(
                '${_monthName(firstDayOfMonth.month)} ${firstDayOfMonth.year}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Colors.black),
                onPressed: _nextMonth,
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
              bool isSelected = day != null &&
                  day.day == DateTime.now().day &&
                  day.month == DateTime.now().month &&
                  day.year == DateTime.now().year;

              return day == null
                  ? const SizedBox.shrink()
                  : Column(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: isSelected ? Colors.green : Colors.grey.shade200,
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSelected ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSummaryTile('Present', '0 days'),
              _buildSummaryTile('Absent', '0 days'),
              _buildSummaryTile('Leaves', '0 days'),
            ],
          )
        ],
      ),
    );
  }

  void _previousMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _currentDate = DateTime(_currentDate.year, _currentDate.month + 1, 1);
    });
  }


  Widget _buildSummaryTile(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildWorkHoursList() {
    final workHours = [
      {'date': '30 June 2023', 'status': 'Present', 'hours': '8.2 hrs'},
      {'date': '29 June 2023', 'status': 'Present', 'hours': '8.1 hrs'},
      {'date': '28 June 2023', 'status': 'Present', 'hours': '8.3 hrs'},
      {'date': '27 June 2023', 'status': 'Present', 'hours': '8.5 hrs'},
      {'date': '26 June 2023', 'status': 'Present', 'hours': '8.2 hrs'},
      {'date': '23 June 2023', 'status': 'Present', 'hours': '8.3 hrs'},
      {'date': '22 June 2023', 'status': 'Absent', 'hours': '--'},
      {'date': '21 June 2023', 'status': 'Present', 'hours': '8.6 hrs'},
      {'date': '20 June 2023', 'status': 'Present', 'hours': '8.4 hrs'},
      {'date': '19 June 2023', 'status': 'Present', 'hours': '8.1 hrs'},
    ];

    return Column(
      children: workHours.map((data) {
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopRow(data['date']!, data['status']!),
              const SizedBox(height: 4),
              const Text(
                'Work Hours',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 6),
              _buildProgressBar(data['hours']!, data['status']!),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopRow(String date, String status) {
    bool isPresent = status == 'Present';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              isPresent ? Icons.check_circle : Icons.cancel,
              color: isPresent ? Colors.green : Colors.red,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              date,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        Text(
          status,
          style: TextStyle(
            color: isPresent ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(String hours, String status) {
    bool isPresent = status == 'Present';
    double value = isPresent ? (double.tryParse(hours.split(' ')[0])! / 10) : 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: value,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(
          isPresent ? Colors.green : Colors.red,
        ),
        minHeight: 8,
      ),
    );
  }
}
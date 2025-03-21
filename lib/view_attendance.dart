import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ViewAttendanceScreen extends StatefulWidget {
  @override
  _ViewAttendanceScreenState createState() => _ViewAttendanceScreenState();
}

class _ViewAttendanceScreenState extends State<ViewAttendanceScreen> {
  Map<String, List<Map<String, String>>> groupedAttendance = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAttendance();
  }

  Future<void> _fetchAttendance() async {
    try {
      final response =
      await http.get(Uri.parse('http://192.168.0.200:8082/attendance/all'));
      if (response.statusCode == 200) {
        List<dynamic> attendanceList = json.decode(response.body);

        Map<String, List<Map<String, String>>> tempGroupedData = {};

        for (var entry in attendanceList) {
          String fullTimestamp = entry['timestampIST'];
          DateTime dateTime = DateTime.parse(fullTimestamp);

          String date =
          DateFormat('EEEE, MMMM d, yyyy').format(dateTime); // Formatted Date
          String time = DateFormat('h:mm a').format(dateTime); // Formatted Time

          if (!tempGroupedData.containsKey(date)) {
            tempGroupedData[date] = [];
          }
          tempGroupedData[date]!.add({
            "name": entry['name'],
            "time": time,
          });
        }

        setState(() {
          groupedAttendance = tempGroupedData;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load attendance');
      }
    } catch (e) {
      print('Error fetching attendance: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE6F7F2), // Light Green Background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.teal.shade800),
          onPressed: () => Navigator.pop(context),
        ), // Back Icon
        title: Text(
          'Attendance Records',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 22, color: Colors.teal),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView(
        children: groupedAttendance.keys.map((date) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.teal, size: 18),
                    SizedBox(width: 8),
                    Text(
                      date,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.teal),
                    ),
                  ],
                ),
              ),
              // Attendance Cards
              ...groupedAttendance[date]!.map((entry) {
                return Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.teal[100],
                        child: Icon(Icons.person, color: Colors.teal),
                      ),
                      title: Text(
                        entry["name"]!,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(Icons.access_time, color: Colors.teal, size: 16),
                          SizedBox(width: 4),
                          Text(entry["time"]!),
                          SizedBox(width: 10),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.check_circle,
                                    color: Colors.green, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  "Verified",
                                  style: TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          );
        }).toList(),
      ),
    );
  }
}

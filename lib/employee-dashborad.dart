import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medhir/leave-management.dart';
import 'package:medhir/payroll.dart';
import 'attendance.dart';
import 'myprofile.dart';
import 'notification.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medhir/check-in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';

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
  List<dynamic> updates = [];// List to store updates from the API
  List<dynamic> users = [];
  Timer? _timer;

  List<CameraDescription> cameras = [];
  CameraController? _cameraController;
  String? selectedUser;
  String? _capturedImagePath;

  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning, ';
    } else if (hour < 17) {
      return 'Good Afternoon, ';
    } else {
      return 'Good Evening, ';
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUpdates(); // Fetch updates when the widget is initialized
    fetchUsers();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      fetchUpdates(); // Fetch updates every minute
    });
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();// Cancel the timer when the widget is disposed
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    cameras = await availableCameras();
    _cameraController = CameraController(
      cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front),
      ResolutionPreset.medium,
    );
    await _cameraController!.initialize();
    setState(() {});
  }


  void showCameraPopup(BuildContext context, String user) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 350,
                width: 400,
                child: _cameraController != null && _cameraController!.value.isInitialized
                    ? CameraPreview(_cameraController!)
                    : Center(child: CircularProgressIndicator()),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () => _capturePhoto(user),
                child: Text('Capture'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _capturePhoto(String user) async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      // Turn off the flashlight before capturing the photo
      await _cameraController!.setFlashMode(FlashMode.off);

      final XFile file = await _cameraController!.takePicture();
      setState(() {
        _capturedImagePath = file.path;
      });

      print('Captured Image Path: $_capturedImagePath');
      print('Selected User: $user');

      // Show verifying dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing while verifying
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Verifying...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Please wait while we verify the photo...')
              ],
            ),
          );
        },
      );

      try {
        // Send the image and user to the API endpoint
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.0.200:8082/attendance/checkin'),
        );

        request.fields['employeeId'] = user;

        // Determine MIME type
        String? mimeType = lookupMimeType(_capturedImagePath!) ?? 'image/jpeg';
        var mediaType = MediaType.parse(mimeType);

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _capturedImagePath!,
          contentType: mediaType,
        ));

        // Send request
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        print('Response: $responseBody');

        // Close the verifying dialog before showing the result
        Navigator.pop(context);

        String statusMessage = responseBody;
        if (response.statusCode == 200) {
          if (responseBody.contains('Present')) {
            statusMessage = 'User is Present';
          } else if (responseBody.contains('Absent')) {
            statusMessage = 'User is Absent';
          }
        }

        // Show the attendance result dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Attendance Status'),
              content: Text(statusMessage),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            );
          },
        );
      } catch (e) {
        Navigator.pop(context); // Close the verifying dialog in case of error
        print('Error: $e');
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text('Failed to verify attendance. Please try again.'),
              actions: <Widget>[
                TextButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    }
  }


  void showTeamInPopup(BuildContext context, List<Map<String, String>> workers) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Team Check-In'),
          ),
          body: StatefulBuilder(
            builder: (context, setState) {
              bool isPendingSelected = true;
              // Declare filteredWorkers outside the builder function
              List<String> filteredWorkers = workers.map((worker) => worker['name']!).toList();

              return StatefulBuilder( // Add another StatefulBuilder to maintain state
                builder: (context, innerSetState) {
                  return Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          autofocus: true,
                          onChanged: (value) {
                            innerSetState(() {
                              filteredWorkers = workers
                                  .where((worker) =>
                                  worker['name']!.toLowerCase().contains(value.toLowerCase()))
                                  .map((worker) => worker['name']!)
                                  .toList();
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'Search workers by name',
                            prefixIcon: Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        SizedBox(height: 16),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isPendingSelected = true;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isPendingSelected ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: isPendingSelected
                                          ? [BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 1)]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text('Pending', style: TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      isPendingSelected = false;
                                    });
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !isPendingSelected ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(4),
                                      boxShadow: !isPendingSelected
                                          ? [BoxShadow(color: Colors.black12, blurRadius: 2, spreadRadius: 1)]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text('Checked-Out', style: TextStyle(color: Colors.black)),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 16),

                        Expanded(
                          child: ListView.builder(
                            itemCount: filteredWorkers.length,
                            itemBuilder: (context, index) {
                              String worker = filteredWorkers[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                              child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(child: Icon(Icons.person)),
                                title: Text(worker),
                                trailing: ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    showCameraPopup(context, workers.firstWhere((element) => element['name'] == worker)['employeeId']!);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text('Check In',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ),
                              ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }




  void showTeamOutPopup(BuildContext context, List<String> workers) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setState) {
            bool isPendingSelected = true;
            List<String> filteredWorkers = List.from(workers);

            void handleCheckInOut() {
              print("Check-In/Out handled");
            }

            return Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(20),
                  width: MediaQuery.of(context).size.width * 0.9,
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.9,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Team Check-Out',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      // Search Field
                      TextField(
                        onChanged: (value) {
                          setState(() {
                            filteredWorkers = workers
                                .where((worker) =>
                                worker.toLowerCase().contains(value.toLowerCase()))
                                .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search workers by name',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),

                      // Workers List with Scrollable View
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredWorkers.length,
                          itemBuilder: (context, index) {
                            String worker = filteredWorkers[index];
                            return ListTile(
                              leading: Icon(Icons.person),
                              title: Text(worker),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  handleCheckInOut();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isPendingSelected ? Colors.teal : Colors.red,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: Text(
                                  isPendingSelected ? 'Check In' : 'Check Out',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                              subtitle: !isPendingSelected
                                  ? Row(
                                children: [
                                  Icon(Icons.access_time, size: 16),
                                  SizedBox(width: 4),
                                  Text('Checked in at 10:00 AM'),
                                ],
                              )
                                  : null,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.200:8082/api/users'));

      if (response.statusCode == 200) {

        setState(() {
          users = json.decode(response.body);
        });


        print(users); // Print the API response
      } else {
        print('Failed to load users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  // Function to fetch updates from the API
  Future<void> fetchUpdates() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.200:8084/updates/emp123'));

      if (response.statusCode == 200) {
        print('API Response: ${response.body}'); // Print the API response
        setState(() {
          updates = json.decode(response.body); // Parse and store the updates
        });
      } else {
        print('Failed to load updates. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching updates: $e');
    }
  }

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
        child: Padding(

          padding: const EdgeInsets.only(top: 60, left: 10, right: 10, bottom: 2),
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
                              text: _getGreetingMessage(),
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
                          child: Stack(
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
                        ),
                      ),
                      SizedBox(width: 10), // ✅ Moved inside the
                      Row(
                        children: [
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
                ],
              ),
              SizedBox(height: 30),

              // Today's Status Card

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Card(
                        color: Color(0xFFFFDFEFE),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
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
                                    Icons.circle,
                                    size: 12,
                                    color: isCheckedIn ? Colors.teal : Colors.grey.shade600,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    isCheckedIn
                                        ? 'Checked in at ${checkInTime!.hour}:${checkInTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Not checked in yet',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              // Self Check-In Button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: handleCheckInOut,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isCheckedIn ? Colors.red.shade400 : Color(0xFF04AF9E),
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 1,
                                  ),
                                  child: Text(
                                    isCheckedIn ? 'Check Out' : 'Self Check-In',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showTeamInPopup(context, users.map((user) => {'name': user['name'] as String, 'employeeId': user['employeeId'] as String}).toList());
                                    },
                                    icon: Icon(Icons.people, size: 18),
                                    label: Text("Team In"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade100,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: Colors.transparent),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  ElevatedButton.icon(
                                    onPressed: () {
                                      showTeamOutPopup(context, ['Alice', 'Bob', 'Charlie', 'David', 'Eve']);
                                    },
                                    icon: Icon(Icons.exit_to_app, size: 18),
                                    label: Text("Team Out"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey.shade100,
                                      foregroundColor: Colors.black87,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(color: Colors.transparent),
                                      ),
                                      padding: EdgeInsets.symmetric(horizontal: 35, vertical: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
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
                      _buildAgendaOfTheDay(),
                      SizedBox(height: 20),
                      _buildLatestUpdates(),
                    ],
                  ),
                ),
              ),
            ],
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
    List displayedUpdates = showAllUpdates ? updates : updates.take(3).toList();

    return _playCard(
      'Latest Updates',
      displayedUpdates.map((update) {
        String title = update['message'] ?? 'No Title';
        String time = update['timestamp'] != null ? DateFormat('EEEE, hh:mm a').format(DateTime.parse(update['timestamp'])) : 'No Time';
        return _updateItem(title, time, _getIconFromFlag(update['flag']), _getColourFromFlag(update['flag']));
      }).toList(),
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
                showAllUpdates ? 'Show Less' : 'Show More',
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
        color: const Color(0xFFF0F0F0), // Light grey background
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
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 16), // Space between icon and text
          Flexible(
            child: Column(
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
        border: Border.all(color: Colors.grey.withOpacity(0.2)), // Added border property
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

Color _getColourFromFlag(String flag) {
  switch (flag) {
    case 'leave':
      return Colors.blue;
    case 'expense':
      return Colors.green;
    case 'advance':
      return Colors.orange;
    default:
      return Colors.black;
  }
}

IconData _getIconFromFlag(String flag) {
  switch (flag) {
    case 'leave':
      return LucideIcons.calendar;
    case 'expense':
      return LucideIcons.receipt;
    case 'advance':
      return LucideIcons.handCoins;
    default:
      return Icons.info;
  }
}
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:medhir/leave-management.dart';
import 'package:medhir/payroll.dart';
import 'attendance.dart';
import 'login_screen.dart';
import 'myprofile.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:medhir/check-in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';

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
  List<dynamic> users = [];
  Timer? _timer;

  List<CameraDescription> cameras = [];
  CameraController? _cameraController;
  String? selectedUser;
  String? _capturedImagePath;

  // Role switching
  int _selectedRole = 0; // 0: Employee, 1: Manager, 2: HR
  final List<String> _roles = ['Employee', 'Manager', 'HR'];

  // Company selection for HR
  String _selectedCompany = 'Medhir Technologies';
  final List<Map<String, dynamic>> _companies = [
    {
      'name': 'Medhir Technologies',
      'id': 'MT001',
      'stats': {
        'totalEmployees': 150,
        'onLeave': 12,
        'presentToday': 138,
        'halfDay': 5,
      }
    },
    {
      'name': 'Medhir Healthcare',
      'id': 'MH001',
      'stats': {
        'totalEmployees': 85,
        'onLeave': 8,
        'presentToday': 75,
        'halfDay': 2,
      }
    },
    {
      'name': 'Medhir Solutions',
      'id': 'MS001',
      'stats': {
        'totalEmployees': 120,
        'onLeave': 10,
        'presentToday': 108,
        'halfDay': 2,
      }
    },
  ];

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
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.white,
      statusBarIconBrightness: Brightness.dark, // dark icons for Android
      statusBarBrightness: Brightness.light, // dark icons for iOS
    ));
    fetchUsers();
    _initializeCamera();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cameraController?.dispose();
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

  Future<void> fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.200:8082/api/users'));
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        print('Failed to load users. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching users: $e');
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
          Uri.parse('http://localhost:8082/attendance/checkin'),
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
      backgroundColor: const Color(0xFFF7FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Sticky Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFF3B82F6).withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
        child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                      // Top Row: Greeting, Date, Profile
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                            Expanded(
                              child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                                  Text(
                                    _getGreetingMessage(),
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Alex',
                              style: GoogleFonts.inter(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1.2,
                              ),
                            ),
                                      const SizedBox(width: 8),
                                      AnimatedSmiley(),
                          ],
                        ),
                                  const SizedBox(height: 4),
                      Text(
                        DateFormat('EEEE, d MMMM y').format(DateTime.now()),
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                            ),
                            const SizedBox(width: 12),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (context) => MyProfileScreen()));
                        },
                        child: Container(
                                    // decoration: BoxDecoration(
                                    //   shape: BoxShape.circle,
                                    //   border: Border.all(color: Colors.white, width: 3),
                                    //   boxShadow: [
                                    //     BoxShadow(
                                    //       color: Colors.black12,
                                    //       blurRadius: 8,
                                    //       offset: Offset(0, 4),
                                    //     ),
                                    //   ],
                                    // ),
                                    // child: CircleAvatar(
                                    //   radius: 32,
                                    //   backgroundImage: AssetImage('assets/avatar.png'),
                                    // ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                      context,
                                      MaterialPageRoute(builder: (context) => LoginScreen()),
                                      (route) => false,
                                    );
                                  },
                                  icon: Icon(Icons.logout, color: Colors.white, size: 28),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      // Full-width Role Switcher
                      // Padding(
                      //   padding: const EdgeInsets.symmetric(horizontal: 20),
                      //   child: Container(
                      //     width: double.infinity,
                      //     padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                      //     decoration: BoxDecoration(
                      //       color: Colors.white.withOpacity(0.18),
                      //       borderRadius: BorderRadius.circular(22),
                      //       boxShadow: [
                      //         BoxShadow(
                      //           color: Colors.black12.withOpacity(0.04),
                      //           blurRadius: 8,
                      //           offset: const Offset(0, 2),
                      //         ),
                      //       ],
                      //     ),
                      //     child: LayoutBuilder(
                      //       builder: (context, constraints) {
                      //         final tabCount = _roles.length;
                      //         final tabWidth = (constraints.maxWidth - (tabCount - 1) * 4) / tabCount;
                      //         return Stack(
                      //           children: [
                      //             // Sliding pill indicator
                      //             AnimatedPositioned(
                      //               left: _selectedRole * (tabWidth + 4),
                      //               top: 0,
                      //               duration: const Duration(milliseconds: 250),
                      //               curve: Curves.easeInOut,
                      //               child: Container(
                      //                 width: tabWidth,
                      //                 height: 44,
                      //                 decoration: BoxDecoration(
                      //                   color: Colors.white,
                      //                   borderRadius: BorderRadius.circular(16),
                      //                   boxShadow: [
                      //                     BoxShadow(
                      //                       color: Colors.blue.withOpacity(0.08),
                      //                       blurRadius: 6,
                      //                       offset: const Offset(0, 2),
                      //                     ),
                      //                   ],
                      //                 ),
                      //               ),
                      //             ),
                      //             Row(
                      //               children: List.generate(_roles.length, (i) {
                      //                 final bool selected = _selectedRole == i;
                      //                 IconData icon;
                      //                 switch (i) {
                      //                   case 0:
                      //                     icon = Icons.person_outline;
                      //                     break;
                      //                   case 1:
                      //                     icon = Icons.manage_accounts_outlined;
                      //                     break;
                      //                   case 2:
                      //                     icon = Icons.admin_panel_settings_outlined;
                      //                     break;
                      //                   default:
                      //                     icon = Icons.person_outline;
                      //                 }
                      //                 return GestureDetector(
                      //                   onTap: () => setState(() => _selectedRole = i),
                      //                   child: Container(
                      //                     width: tabWidth,
                      //                     height: 44,
                      //                     alignment: Alignment.center,
                      //                     child: Row(
                      //                       mainAxisAlignment: MainAxisAlignment.center,
                      //                       children: [
                      //                         Icon(
                      //                           icon,
                      //                           size: 18,
                      //                           color: selected ? Color(0xFF3B82F6) : Colors.white,
                      //                         ),
                      //                         const SizedBox(width: 6),
                      //                         Text(
                      //                           _roles[i],
                      //                           style: GoogleFonts.inter(
                      //                             fontWeight: FontWeight.w600,
                      //                             color: selected ? Color(0xFF3B82F6) : Colors.white,
                      //                             fontSize: 15,
                      //                           ),
                      //                         ),
                      //                       ],
                      //                     ),
                      //                   ),
                      //                 );
                      //               }),
                      //             ),
                      //           ],
                      //         );
                      //       },
                      //     ),
                      //   ),
                      // ),
                            ],
                          ),
                        ),
                      ),
            ),
            // Sticky Company Selector (only for HR role)
            if (_selectedRole == 2)
              Container(
                color: const Color(0xFFF7FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.teal.withOpacity(0.07),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                            onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (context) => _buildCompanySelector(),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Icon(LucideIcons.building2, color: const Color(0xFF04AF9E), size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Selected Company',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _selectedCompany,
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                      ),
                    ],
                  ),
                            ),
                            Icon(LucideIcons.chevronDown, color: const Color(0xFF04AF9E)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            // Scrollable Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    const SizedBox(height: 24),
                    // Main content for selected role
                    Builder(
                      builder: (context) {
                        if (_selectedRole == 0) {
                          return _buildEmployeeContent(context);
                        } else if (_selectedRole == 1) {
                          return _buildManagerContent(context);
                        } else {
                          return _buildHRContent(context);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
                          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Row(
                            children: [
                              Text(
                  'Select Company',
                                style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          ListView.builder(
            shrinkWrap: true,
            itemCount: _companies.length,
            itemBuilder: (context, index) {
              final company = _companies[index];
              final isSelected = company['name'] == _selectedCompany;
              return ListTile(
                leading: Icon(
                  LucideIcons.building2,
                  color: isSelected ? const Color(0xFF04AF9E) : Colors.grey,
                ),
                title: Text(
                  company['name'],
                  style: GoogleFonts.inter(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? const Color(0xFF04AF9E) : Colors.black87,
                  ),
                ),
                trailing: isSelected
                    ? Icon(Icons.check_circle, color: const Color(0xFF04AF9E))
                    : null,
                onTap: () {
                  setState(() {
                    _selectedCompany = company['name'];
                  });
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // Modernized Employee Content
  Widget _buildEmployeeContent(BuildContext context) {
    final bool checkedIn = isCheckedIn;
    final Color accent = const Color(0xFF04AF9E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Modern, unified Attendance/Status Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status Row
                              Row(
                                children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: checkedIn ? accent.withOpacity(0.12) : Colors.grey[200],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          checkedIn ? Icons.check : Icons.radio_button_unchecked,
                          color: checkedIn ? accent : Colors.grey[500],
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                                  Text(
                        checkedIn
                                ? 'Checked in at \t	t${checkInTime!.hour}:${checkInTime!.minute.toString().padLeft(2, '0')}'
                                        : 'Not checked in yet',
                                    style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                  const SizedBox(height: 14),
                  // Check-In/Out Button
                              SizedBox(
                                width: double.infinity,
                    child: OutlinedButton.icon(
                                  onPressed: handleCheckInOut,
                      icon: Icon(checkedIn ? Icons.logout : Icons.login, color: Colors.teal),
                      label: Text(
                        checkedIn ? 'Check Out' : 'Self Check-In',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.teal,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.teal, width: 1.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.transparent,
                        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // _buildQuickActionsSection(context, [
        //   {
        //     'label': 'Leave',
        //     'icon': LucideIcons.calendar,
        //     'color': Colors.blue,
        //     'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => LeaveManagementScreen())),
        //   },
        //   {
        //     'label': 'Attendance',
        //     'icon': LucideIcons.clock,
        //     'color': Colors.purple,
        //     'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen())),
        //   },
        //   {
        //     'label': 'Pay Slip',
        //     'icon': Icons.receipt_long,
        //     'color': Colors.orange,
        //     'onTap': () => print('Pay Slip tapped'),
        //   },
        //   {
        //     'label': 'Income',
        //     'icon': Icons.trending_up,
        //     'color': Colors.green,
        //     'onTap': () => print('Income tapped'),
        //   },
        //   {
        //     'label': 'Expense',
        //     'icon': Icons.trending_down,
        //     'color': Colors.red,
        //     'onTap': () => print('Expense tapped'),
        //   },
        //   {
        //     'label': 'Leads',
        //     'icon': LucideIcons.users,
        //     'color': Colors.teal,
        //     'onTap': () {},
        //   },
        // ]),
      ],
    );
  }

  // Manager Content
  Widget _buildManagerContent(BuildContext context) {
    final Color accent = const Color(0xFF04AF9E);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Team Attendance Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade200, width: 1.5),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Team Attendance',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                                children: [
                      Expanded(
                        child: OutlinedButton.icon(
                                    onPressed: () {
                                      showTeamInPopup(context, users.map((user) => {'name': user['name'] as String, 'employeeId': user['employeeId'] as String}).toList());
                                    },
                          icon: Icon(Icons.people, color: accent, size: 20),
                          label: Text('Team In', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: accent)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: accent, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                                    onPressed: () {
                                      showTeamOutPopup(context, ['Alice', 'Bob', 'Charlie', 'David', 'Eve']);
                                    },
                          icon: Icon(Icons.exit_to_app, color: Colors.red, size: 20),
                          label: Text('Team Out', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.red)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red, width: 1.2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
        ),
        const SizedBox(height: 32),
        // Open Requests with new design
                      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Implement open requests navigation
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(LucideIcons.bell, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Open Requests',
                  style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                            const SizedBox(height: 4),
                            Text(
                              '3 pending approvals',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                    ],
                  ),
                ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
              ),
            ],
          ),
        ),
      ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildQuickActionsSection(context, [
          {
            'label': 'Team',
            'icon': LucideIcons.users,
            'color': Colors.blue,
            'onTap': () {},
          },
          {
            'label': 'Attendance',
            'icon': LucideIcons.clock,
            'color': Colors.purple,
            'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen())),
          },
          {
            'label': 'Leads',
            'icon': LucideIcons.target,
            'color': Colors.green,
            'onTap': () {},
          },
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  // HR Content
  Widget _buildHRContent(BuildContext context) {
    final Color accent = const Color(0xFF04AF9E);
    final selectedCompanyData = _companies.firstWhere((company) => company['name'] == _selectedCompany);
    final stats = selectedCompanyData['stats'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // HR Overview Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
      child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                  Text(
                    'HR Overview',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Employees',
                          stats['totalEmployees'].toString(),
                          LucideIcons.users,
                          Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'On Leave',
                          stats['onLeave'].toString(),
                          LucideIcons.umbrella,
                          Colors.purple,
                        ),
                      ),
                    ],
          ),
          const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Present Today',
                          stats['presentToday'].toString(),
                          LucideIcons.check,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildStatCard(
                          'Half Day',
                          stats['halfDay'].toString(),
                          LucideIcons.clock,
                          const Color(0xFF04AF9E),
                        ),
          ),
        ],
      ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Open Requests with new design
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  // TODO: Implement open requests navigation
                },
                borderRadius: BorderRadius.circular(24),
                child: Padding(
      padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(LucideIcons.bell, color: Colors.red, size: 20),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Text(
                              'Open Requests',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '8 pending approvals',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
              ),
            ],
          ),
                      ),
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(Icons.arrow_forward_ios, color: Colors.red, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        _buildQuickActionsSection(context, [
          {
            'label': 'Employees',
            'icon': LucideIcons.users,
            'color': Colors.blue,
            'onTap': () {},
          },
          {
            'label': 'Attendance',
            'icon': LucideIcons.clock,
            'color': Colors.purple,
            'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => AttendanceScreen())),
          },
          {
            'label': 'Payroll',
            'icon': LucideIcons.creditCard,
            'color': Colors.orange,
            'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (context) => SalaryPayrollPage())),
          },
          {
            'label': 'Settings',
            'icon': LucideIcons.settings,
            'color': Colors.grey,
            'onTap': () {},
          },
        ]),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
              color: Colors.black54,
                  ),
                  overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
          const SizedBox(height: 6),
              Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernQuickAction(BuildContext context, {required String label, required IconData icon, required Color color, required VoidCallback onTap, bool isImportant = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 85,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF7FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
                Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
                ),
              ],
            ),
      ),
    );
  }

  // Helper method to build Quick Actions section
  Widget _buildQuickActionsSection(BuildContext context, List<Map<String, dynamic>> actions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
            color: const Color(0xFFF7FAFC),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
      child: Column(
        children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: actions.take(3).map((action) => _modernQuickAction(
                    context,
                    label: action['label'],
                    icon: action['icon'],
                    color: action['color'],
                    onTap: action['onTap'],
                  )).toList(),
                ),
                if (actions.length > 3) ...[
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: actions.skip(3).map((action) => _modernQuickAction(
                      context,
                      label: action['label'],
                      icon: action['icon'],
                      color: action['color'],
                      onTap: action['onTap'],
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
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

class AnimatedSmiley extends StatefulWidget {
  @override
  State<AnimatedSmiley> createState() => _AnimatedSmileyState();
}

class _AnimatedSmileyState extends State<AnimatedSmiley> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Create a sequence of animations
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.1),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.1, end: 1.0),
        weight: 1,
      ),
    ]).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // Play animation twice then stop
    _controller.forward().then((_) {
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _controller.forward().then((_) {
            _controller.stop();
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _animation.value,
          child: Text(
            '🙂',
            style: TextStyle(fontSize: 26),
          ),
        );
      },
    );
  }
}
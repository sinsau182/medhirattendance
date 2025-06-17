import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_dashboard.dart';
import 'package:http/http.dart' as http;

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({Key? key}) : super(key: key);

  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {

  int _selectedNavIndex = 1; // 0: Employee, 1: Manager
  int _selectedStatIndex = 0; // 0: Total, 1: Checked In, 2: Checked Out
  String _searchQuery = '';

  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;

  static const Color kPrimaryBlue = Color(0xFF4F8CFF);
  static const Color kLightBlue = Color(0xFFF5F6FA);

    String employeeName = "";

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

  Future<void> _loadEmployeeName() async {
    final prefs = await SharedPreferences.getInstance();
    final employeeName = prefs.getString('employeeName');
    setState(() {
      this.employeeName = employeeName ?? "Employee";
    });
  }

  @override
  void initState() {
    super.initState();
    _loadEmployeeName();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employeeId');
    final token = prefs.getString('authToken');
    print('Fetching employees for manager ID: $empId');
    
    if (token == null) {
      print('Error: No authentication token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.0.200:8080/employees/manager/$empId'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    print('API Response Status Code: ${response.statusCode}');
    print('API Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> jsonData = json.decode(response.body);
      final List<Map<String, dynamic>> employeeData = jsonData.map((item) {
        final Map<String, dynamic> employee = Map<String, dynamic>.from(item);
        employee['checkedIn'] = false; // Add default value for checkedIn
        return employee;
      }).toList();
      print('Parsed Data: $employeeData');
      setState(() {
        _employees = employeeData;
      });
    } else {
      print('Error: Failed to fetch employees. Status code: ${response.statusCode}');
    }
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: kLightBlue,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: kLightBlue,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kLightBlue,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 18),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: kPrimaryBlue.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.groups, color: kPrimaryBlue, size: 32),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Medhir Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.black)),
                        SizedBox(height: 2),
                        Text('Manager: $employeeName', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 22),
              // Team Check-In Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CameraPopupScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: kPrimaryBlue,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withOpacity(0.13),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.groups, color: Colors.white, size: 26),
                        SizedBox(width: 10),
                        Text('Team Check-In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 19)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 18),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, employee ID, or role',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    filled: true,
                    fillColor: kLightBlue,
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              SizedBox(height: 18),
              // Stats Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    _buildStatsTab('Total', 0, kPrimaryBlue),
                    SizedBox(width: 8),
                    _buildStatsTab('Checked In', 1, Colors.green),
                    SizedBox(width: 8),
                    _buildStatsTab('Checked Out', 2, Colors.deepPurple),
                  ],
                ),
              ),
              SizedBox(height: 18),
              // Employee List
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _buildEmployeeListModern(),
                ),
              ),
            ],
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
              currentIndex: 1, // Team
              onTap: (index) {
                if (index == 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomeDashboard()),
                  );
                } else if (index == 1) {
                  // Already on ManagerScreen
                }
              },
              backgroundColor: Colors.white,
              selectedItemColor: kPrimaryBlue,
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
      ),
    );
  }

  Widget _buildStatsTab(String label, int index, Color color) {
    final bool isSelected = _selectedStatIndex == index;
    int count = 0;
    if (index == 0) {
      count = _employees.length;
    } else if (index == 1) {
      count = _employees.where((e) => e['checkedIn']).length;
    } else {
      count = _employees.where((e) => !e['checkedIn']).length;
    }
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedStatIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isSelected ? color : kPrimaryBlue.withOpacity(0.18), width: 2),
          ),
          child: Column(
            children: [
              Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : color)),
              SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 15, color: isSelected ? Colors.white : color, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeListModern() {
    // Filter employees based on selected stat
    List<Map<String, dynamic>> filteredEmployees;
    if (_selectedStatIndex == 0) {
      filteredEmployees = _employees;
    } else if (_selectedStatIndex == 1) {
      filteredEmployees = _employees.where((e) => e['checkedIn']).toList();
    } else {
      filteredEmployees = _employees.where((e) => !e['checkedIn']).toList();
    }
    // Apply search filter
    filteredEmployees = filteredEmployees.where((e) =>
      e['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e['id'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e['role'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (filteredEmployees.isEmpty) {
      return Center(
        child: Text('No employees found', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
      );
    }

    return ListView.separated(
      itemCount: filteredEmployees.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = filteredEmployees[index];
        final initials = emp['name'].split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kPrimaryBlue.withOpacity(0.10),
                  child: Text(
                    initials,
                    style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue, fontSize: 16),
                  ),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(emp['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                      SizedBox(height: 2),
                      Text('${emp['employeeId']} • ${emp['departmentName']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                if (_selectedStatIndex == 1)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kPrimaryBlue,
                      side: BorderSide(color: kPrimaryBlue),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () {
                      setState(() {
                        emp['checkedIn'] = false;
                      });
                    },
                    icon: Icon(Icons.logout, size: 16),
                    label: Text('Check Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Camera popup/screen
class CameraPopupScreen extends StatefulWidget {
  @override
  State<CameraPopupScreen> createState() => _CameraPopupScreenState();
}

class _CameraPopupScreenState extends State<CameraPopupScreen> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  XFile? _capturedFile;
  bool _isCameraReady = false;
  bool _isError = false;
  bool _flashOn = false;
  int _selectedCameraIdx = 0;
  List<CameraDescription> _cameras = [];

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([int cameraIdx = 0]) async {
    try {
      _cameras = await availableCameras();
      final camera = _cameras[cameraIdx];
      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      _initializeControllerFuture = _controller!.initialize();
      await _initializeControllerFuture;
      setState(() {
        _isCameraReady = true;
        _selectedCameraIdx = cameraIdx;
        _flashOn = false;
      });
      await _controller!.setFlashMode(FlashMode.off);
    } catch (e) {
      setState(() {
        _isError = true;
      });
    }
  }

  void _toggleFlash() async {
    if (_controller == null) return;
    setState(() {
      _flashOn = !_flashOn;
    });
    await _controller!.setFlashMode(_flashOn ? FlashMode.torch : FlashMode.off);
  }

  void _toggleCamera() async {
    if (_cameras.length < 2) return;
    int newIdx = (_selectedCameraIdx + 1) % _cameras.length;
    setState(() {
      _isCameraReady = false;
      _isError = false;
    });
    await _initCamera(newIdx);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double screenHeight = MediaQuery.of(context).size.height;
    final double topPadding = MediaQuery.of(context).padding.top;
    final double cardMargin = 18.0;
    final double cardRadius = 28.0;
    final double previewWidth = screenWidth - cardMargin * 2;
    final double previewHeight = previewWidth * 4 / 3;
    final Color kPrimaryBlue = Color(0xFF4F8CFF);
    final Color kLightBlue = Color(0xFFF5F6FA);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: kLightBlue,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: kLightBlue,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: kLightBlue,
        body: SafeArea(
          child: Stack(
            children: [
              // Back button (top left, always visible)
              Positioned(
                top: topPadding + 8,
                left: 8,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryBlue, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Main card with preview and controls
              Center(
                child: Container(
                  width: previewWidth,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(cardRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.symmetric(vertical: 18, horizontal: 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(height: 8),
                      Text('Team Check-In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: kPrimaryBlue)),
                      SizedBox(height: 8),
                      Text('Position your face in the frame', style: TextStyle(fontSize: 15, color: Colors.grey[700])),
                      SizedBox(height: 14),
                      // Camera preview or image preview
                      Container(
                        width: previewWidth - 24,
                        height: (previewWidth - 24) * 4 / 3,
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: _capturedFile != null
                                ? Image.file(
                                    File(_capturedFile!.path),
                                    fit: BoxFit.cover,
                                  )
                                : _isError
                                    ? Center(child: Text('Camera not available', style: TextStyle(color: Colors.white)))
                                    : _isCameraReady && _controller != null
                                        ? CameraPreview(_controller!)
                                        : Center(child: CircularProgressIndicator(color: kPrimaryBlue)),
                          ),
                        ),
                      ),
                      SizedBox(height: 18),
                      // Controls
                      if (_capturedFile == null && _isCameraReady)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Camera switch toggle
                            IconButton(
                              icon: Icon(Icons.cameraswitch, color: kPrimaryBlue, size: 30),
                              onPressed: _toggleCamera,
                            ),
                            SizedBox(width: 18),
                            // Flash toggle
                            IconButton(
                              icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off, color: kPrimaryBlue, size: 30),
                              onPressed: _toggleFlash,
                            ),
                          ],
                        ),
                      if (_capturedFile == null && _isCameraReady)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kPrimaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                padding: EdgeInsets.symmetric(vertical: 16),
                                elevation: 2,
                              ),
                              onPressed: () async {
                                try {
                                  await _initializeControllerFuture;
                                  final file = await _controller!.takePicture();
                                  setState(() {
                                    _capturedFile = file;
                                  });
                                } catch (e) {}
                              },
                              child: Text('Capture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                          ),
                        ),
                      if (_capturedFile != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: kPrimaryBlue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: kPrimaryBlue),
                                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _capturedFile = null;
                                  });
                                },
                                child: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                              SizedBox(width: 24),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: Text('Send', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              ),
                            ],
                          ),
                        ),
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
}

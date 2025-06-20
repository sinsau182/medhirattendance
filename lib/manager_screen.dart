import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home_dashboard.dart';
import 'package:http/http.dart' as http;
import 'register.dart';

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
  Set<String> _checkingOutEmployees = {}; // Track employees being checked out
  Set<String> _registeredEmployeeIds = {}; // Track registered employee IDs

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
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employeeId');
    final token = prefs.getString('authToken');
    print('Fetching employees for manager ID: $empId');
    
    if (token == null) {
      print('Error: No authentication token found');
      setState(() {
        _isLoading = false;
      });
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
      
      // Fetch team status to update checkedIn property
      await _fetchTeamStatus(employeeData);
      
      // Fetch registered team members
      await _fetchRegisteredTeamMembers(empId!);
      
      setState(() {
        _employees = employeeData;
        _isLoading = false;
      });
    } else {
      print('Error: Failed to fetch employees. Status code: ${response.statusCode}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchTeamStatus(List<Map<String, dynamic>> employees) async {
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employeeId');
    final token = prefs.getString('authToken');
    
    if (token == null || empId == null) {
      print('Error: No authentication token or employee ID found');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.200:8082/manager/team-status/$empId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('Team Status API Response Status Code: ${response.statusCode}');
      print('Team Status API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        // Extract teamStatus array from the response
        if (responseData.containsKey('teamStatus')) {
          final List<dynamic> teamStatusData = responseData['teamStatus'] as List<dynamic>;
          
          // Create a map of employee IDs to their check-in status
          Map<String, bool> checkedInMap = {};
          for (var status in teamStatusData) {
            if (status is Map<String, dynamic>) {
              final employeeId = status['empId']?.toString(); // Using 'empId' from the API response
              if (employeeId != null) {
                // Check if status is "checked_in" (from the API response)
                final statusValue = status['status']?.toString();
                checkedInMap[employeeId] = statusValue == 'checked_in';
              }
            }
          }
          
          // Update the checkedIn property for each employee
          for (var employee in employees) {
            final employeeId = employee['employeeId']?.toString();
            if (employeeId != null && checkedInMap.containsKey(employeeId)) {
              employee['checkedIn'] = checkedInMap[employeeId]!;
            }
          }
          
          print('Updated employees with team status: $employees');
        } else {
          print('Error: No teamStatus field found in response');
        }
      } else {
        print('Error: Failed to fetch team status. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching team status: $e');
    }
  }

  Future<void> _fetchRegisteredTeamMembers(String managerId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    
    if (token == null) {
      print('Error: No authentication token found');
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.200:8082/manager/registered-team-members/$managerId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      print('Registered Team Members API Response Status Code: ${response.statusCode}');
      print('Registered Team Members API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData.containsKey('registeredEmpIds')) {
          final List<dynamic> registeredIds = responseData['registeredEmpIds'] as List<dynamic>;
          setState(() {
            _registeredEmployeeIds = registeredIds.map((id) => id.toString()).toSet();
          });
          print('Registered employee IDs: $_registeredEmployeeIds');
        }
      } else {
        print('Error: Failed to fetch registered team members. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching registered team members: $e');
    }
  }

  Future<void> _checkoutEmployee(String employeeId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    
    if (token == null) {
      print('Error: No authentication token found');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication error. Please try again.')),
      );
      return;
    }

    // Set loading state for this employee
    setState(() {
      _checkingOutEmployees.add(employeeId);
    });

    try {
      // Create multipart request for checkout
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.200:8082/employee/checkout'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add employee ID as form data
      request.fields['employeeId'] = employeeId;

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      // Log the response
      print('Checkout API Response Status: ${response.statusCode}');
      print('Checkout API Response Body: $responseData');

      if (response.statusCode == 200) {
        // Success - update local state
        setState(() {
          final employee = _employees.firstWhere(
            (emp) => emp['employeeId'].toString() == employeeId,
            orElse: () => {},
          );
          if (employee.isNotEmpty) {
            employee['checkedIn'] = false;
          }
          _checkingOutEmployees.remove(employeeId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Employee checked out successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        // Error
        print('Checkout Failed. Status: ${response.statusCode}, Response: $responseData');
        setState(() {
          _checkingOutEmployees.remove(employeeId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check out employee. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error during checkout: $e');
      setState(() {
        _checkingOutEmployees.remove(employeeId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during checkout. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
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
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CameraPopupScreen()),
                    );
                    // Refresh data when returning from team check-in
                    _fetchEmployees();
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
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _fetchEmployees();
                    },
                  child: _buildEmployeeListModern(),
                  ),
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
      // Count only registered employees who are not checked in
      count = _employees.where((e) => 
        !e['checkedIn'] && _registeredEmployeeIds.contains(e['employeeId'].toString())
      ).length;
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
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: kPrimaryBlue),
            SizedBox(height: 16),
            Text('Loading team data...', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
          ],
        ),
      );
    }
    
    // Filter employees based on selected stat
    List<Map<String, dynamic>> filteredEmployees;
    if (_selectedStatIndex == 0) {
      filteredEmployees = _employees;
    } else if (_selectedStatIndex == 1) {
      filteredEmployees = _employees.where((e) => e['checkedIn']).toList();
    } else {
      // For checked out tab, only show registered employees who are not checked in
      filteredEmployees = _employees.where((e) => 
        !e['checkedIn'] && _registeredEmployeeIds.contains(e['employeeId'].toString())
      ).toList();
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
        final bool isCheckedIn = emp['checkedIn'] ?? false;
        
        return Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                Stack(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: kPrimaryBlue.withOpacity(0.10),
                  child: Text(
                    initials,
                    style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue, fontSize: 16),
                  ),
                    ),
                    if (isCheckedIn)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Icon(
                            Icons.check,
                            size: 10,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                    children: [
                      Text(emp['name'], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black)),
                          SizedBox(width: 8),
                          if (isCheckedIn && _selectedStatIndex == 0)
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.withOpacity(0.3)),
                              ),
                              child: Text(
                                'Checked In',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          // if (_selectedStatIndex == 0 && !_registeredEmployeeIds.contains(emp['employeeId'].toString()))
                          //   Container(
                          //     padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          //     decoration: BoxDecoration(
                          //       color: Colors.orange.withOpacity(0.1),
                          //       borderRadius: BorderRadius.circular(12),
                          //       border: Border.all(color: Colors.orange.withOpacity(0.3)),
                          //     ),
                              // child: Text(
                              //   'Not Registered',
                              //   style: TextStyle(
                              //     color: Colors.orange,
                              //     fontSize: 11,
                              //     fontWeight: FontWeight.w600,
                              //   ),
                              // ),
                            // ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text('${emp['employeeId']} • ${emp['departmentName']}', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    ],
                  ),
                ),
                // Show register button for non-registered employees in total tab
                if (_selectedStatIndex == 0 && !_registeredEmployeeIds.contains(emp['employeeId'].toString()))
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [kPrimaryBlue, kPrimaryBlue.withOpacity(0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: kPrimaryBlue.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RegisterUserScreen(
                                roles: ['EMPLOYEE'], // Default role for team members
                                employeeId: emp['employeeId'],
                                employeeName: emp['name'],
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.person_add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Register',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (_selectedStatIndex == 1 && isCheckedIn)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _checkingOutEmployees.contains(emp['employeeId'].toString())
                            ? [Colors.grey.shade400, Colors.grey.shade500]
                            : [Colors.red.shade400, Colors.red.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (_checkingOutEmployees.contains(emp['employeeId'].toString()) 
                              ? Colors.grey 
                              : Colors.red).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _checkingOutEmployees.contains(emp['employeeId'].toString())
                            ? null
                            : () => _checkoutEmployee(emp['employeeId'].toString()),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_checkingOutEmployees.contains(emp['employeeId'].toString()))
                                SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              SizedBox(width: 2),
                              Text(
                                _checkingOutEmployees.contains(emp['employeeId'].toString())
                                    ? 'Checking Out...'
                                    : 'Check Out',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
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
  bool _isProcessing = false;
  bool _faceRecognitionFailed = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera([int cameraIdx = 0]) async {
    try {
      _cameras = await availableCameras();
      
      // Find front camera index
      int frontCameraIdx = _cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.front);
      
      // Use front camera if available, otherwise use the provided index
      int selectedIdx = frontCameraIdx != -1 ? frontCameraIdx : cameraIdx;
      
      final camera = _cameras[selectedIdx];
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
        _selectedCameraIdx = selectedIdx;
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

  Future<void> _processTeamCheckIn() async {
    if (_capturedFile == null) return;

    setState(() {
      _isProcessing = true;
      _faceRecognitionFailed = false;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final managerId = prefs.getString('employeeId');
      
      if (token == null || managerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error. Please try again.')),
        );
        return;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.200:8082/manager/checkin'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add manager ID
      request.fields['managerId'] = managerId;

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          _capturedFile!.path,
        ),
      );

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      // Log the response
      print('Team Check-in API Response Status: ${response.statusCode}');
      print('Team Check-in API Response Body: $responseData');
      print('Response length: ${responseData.length}');
      print('Response contains "face": ${responseData.toLowerCase().contains('face')}');
      print('Response contains "error": ${responseData.toLowerCase().contains('error')}');
      print('Response contains "failed": ${responseData.toLowerCase().contains('failed')}');

      // Always check the response body for failure, regardless of status code
      try {
        final responseJson = json.decode(responseData);
        bool isFailure = false;
        if (responseJson is Map<String, dynamic>) {
          final status = responseJson['status']?.toString().toLowerCase();
          final message = responseJson['message']?.toString().toLowerCase();
          if (status == 'not found' ||
              (message != null && (message.contains('not recognized') || message.contains('not found')))) {
            isFailure = true;
          }
        }
        if (isFailure) {
          setState(() {
            _faceRecognitionFailed = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Face recognition failed. Please try manual check-in.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          return;
        }
        // Otherwise, treat as success
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Team check-in successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } catch (e) {
        // If parsing fails, treat as failure
        setState(() {
          _faceRecognitionFailed = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Face recognition failed. Please try manual check-in.'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error during team check-in: $e');
      setState(() {
        _faceRecognitionFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during team check-in. Please try manual check-in.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _navigateToManualCheckIn() {
    if (_capturedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ManualCheckInScreen(capturedImage: _capturedFile!),
        ),
      );
    }
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
                        height: 440,
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
                      if (_capturedFile != null && !_faceRecognitionFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                          child: Column(
                            children: [
                              Row(
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
                                    onPressed: _isProcessing ? null : () {
                                      setState(() {
                                        _capturedFile = null;
                                        _faceRecognitionFailed = false;
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
                                    onPressed: _isProcessing ? null : _processTeamCheckIn,
                                    child: _isProcessing
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Text('Processing...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                            ],
                                          )
                                        : Text('Send', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
                              ),
                              // Debug button for testing face recognition failure
                              SizedBox(height: 12),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _faceRecognitionFailed = true;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Debug: Simulating face recognition failure'),
                                      backgroundColor: Colors.red,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                                child: Text('Debug: Simulate Failure', style: TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      // Manual and Retry buttons when face recognition fails
                      if (_capturedFile != null && _faceRecognitionFailed)
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0, bottom: 6.0),
                          child: Column(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                                ),
                                child: Text(
                                  'Face recognition failed. Please try manual check-in.',
                                  style: TextStyle(
                                    color: Colors.orange[700],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              SizedBox(height: 16),
                              Row(
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
                                        _faceRecognitionFailed = false;
                                      });
                                    },
                                    child: Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                  SizedBox(width: 24),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                                    ),
                                    onPressed: _navigateToManualCheckIn,
                                    child: Text('Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  ),
                                ],
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

// Manual Check-in Screen
class ManualCheckInScreen extends StatefulWidget {
  final XFile capturedImage;
  
  const ManualCheckInScreen({Key? key, required this.capturedImage}) : super(key: key);

  @override
  State<ManualCheckInScreen> createState() => _ManualCheckInScreenState();
}

class _ManualCheckInScreenState extends State<ManualCheckInScreen> {
  List<Map<String, dynamic>> _employees = [];
  bool _isLoading = true;
  String _searchQuery = '';
  bool _isSubmitting = false;

  static const Color kPrimaryBlue = Color(0xFF4F8CFF);
  static const Color kLightBlue = Color(0xFFF5F6FA);

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
    });
    
    final prefs = await SharedPreferences.getInstance();
    final empId = prefs.getString('employeeId');
    final token = prefs.getString('authToken');
    
    if (token == null) {
      print('Error: No authentication token found');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('http://192.168.0.200:8080/employees/manager/$empId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = json.decode(response.body);
        final List<Map<String, dynamic>> employeeData = jsonData.map((item) {
          return Map<String, dynamic>.from(item);
        }).toList();
        
        setState(() {
          _employees = employeeData;
          _isLoading = false;
        });
      } else {
        print('Error: Failed to fetch employees. Status code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching employees: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _manualCheckIn(String employeeId, String employeeName) async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final managerId = prefs.getString('employeeId');
      
      if (token == null || managerId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Authentication error. Please try again.')),
        );
        return;
      }

      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.200:8082/employee/manual-checkin'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add manager ID, employee ID, and employee name
      request.fields['empId'] = employeeId;

      // Add image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          widget.capturedImage.path,
        ),
      );

      // Send request
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      
      print('Manual Check-in API Response Status: ${response.statusCode}');
      print('Manual Check-in API Response Body: $responseData');

      if (response.statusCode == 200) {
        // Success
        Navigator.pop(context); // Close manual screen
        Navigator.pop(context); // Close camera screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Manual check-in successful!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        // Error
        print('Manual Check-in Failed. Status: ${response.statusCode}, Response: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to check-in employee. Please try again.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      print('Error during manual check-in: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during manual check-in. Please try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
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
        appBar: AppBar(
          backgroundColor: kLightBlue,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new_rounded, color: kPrimaryBlue),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'Manual Check-In',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 16),
              // Captured Image Preview
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(
                      File(widget.capturedImage.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name, employee ID, or department',
                    prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: kPrimaryBlue, width: 2),
                    ),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),
              SizedBox(height: 16),
              // Employee List
              Expanded(
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: kPrimaryBlue),
                            SizedBox(height: 16),
                            Text('Loading team members...', style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        ),
                      )
                    : _buildEmployeeList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmployeeList() {
    // Filter employees based on search query
    List<Map<String, dynamic>> filteredEmployees = _employees.where((e) =>
      e['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e['employeeId'].toString().toLowerCase().contains(_searchQuery.toLowerCase()) ||
      e['departmentName'].toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    if (filteredEmployees.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
            SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No team members found' : 'No matching team members',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: filteredEmployees.length,
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemBuilder: (context, index) {
        final emp = filteredEmployees[index];
        final initials = emp['name'].split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join().toUpperCase();
        
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _isSubmitting ? null : () => _manualCheckIn(
              emp['employeeId'].toString(),
              emp['name'],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: kPrimaryBlue.withOpacity(0.10),
                    child: Text(
                      initials,
                      style: TextStyle(fontWeight: FontWeight.bold, color: kPrimaryBlue, fontSize: 18),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp['name'],
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${emp['employeeId']} • ${emp['departmentName']}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  if (_isSubmitting)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryBlue),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios,
                      color: kPrimaryBlue,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


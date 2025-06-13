import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'attendance_popup.dart';
import 'dropdown.dart';
import 'home_dashboard.dart';

class CheckInScreen extends StatefulWidget {
  final String? prefilledUser;
  final VoidCallback? onCheckInSuccess; // Callback function

  const CheckInScreen({super.key, this.prefilledUser, this.onCheckInSuccess});

  @override
  _CheckInScreenState createState() => _CheckInScreenState();
}


class _CheckInScreenState extends State<CheckInScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeCameraController;
  List<CameraDescription> cameras = [];
  int selectedCameraIndex = 0;
  bool isFlashOn = false;
  List<String> users = [];
  String? selectedUser;
  String? _capturedImagePath;
  bool _isConfirming = false;
  bool _isNotRecognized = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _loadEmployeeId();
  }

  Future<void> _loadEmployeeId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedUser = prefs.getString('employeeId') ?? 'emp001';
    });
  }

  void _initializeCamera({int? cameraIndex}) async {
    cameras = await availableCameras();

    // Select front camera by default if no index is provided
    selectedCameraIndex = cameraIndex ??
        cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    // If no front camera is found, fallback to the first available camera
    if (selectedCameraIndex == -1) {
      selectedCameraIndex = 0;
    }

    _cameraController = CameraController(cameras[selectedCameraIndex], ResolutionPreset.medium);

    _initializeCameraController = _cameraController.initialize();
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    int newIndex = (selectedCameraIndex + 1) % cameras.length;
    _initializeCamera(cameraIndex: newIndex);
  }

  void _toggleFlash() async {
    if (_cameraController.value.flashMode == FlashMode.off) {
      await _cameraController.setFlashMode(FlashMode.torch);
      setState(() {
        isFlashOn = true;
      });
    } else {
      await _cameraController.setFlashMode(FlashMode.off);
      setState(() {
        isFlashOn = false;
      });
    }
  }

  // Future<void> _fetchUsers() async {
  //   try {
  //     final response = await http.get(Uri.parse('http://192.168.0.200:8082/api/users'));
  //     if (response.statusCode == 200) {
  //       List<dynamic> data = json.decode(response.body);
  //       List<String> sortedUsers = data.map((user) => user['name'].toString()).toList();
  //       sortedUsers.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  //       if (mounted) {
  //         setState(() {
  //           users = sortedUsers;
  //         });
  //       }
  //     } else {
  //       throw Exception('Failed to load users');
  //     }
  //   } catch (e) {
  //     print('Error fetching users: $e');
  //   }
  // }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController.value.isInitialized) {
      final XFile file = await _cameraController.takePicture();
      File imageFile = File(file.path);

      // Read image bytes
      List<int> imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(Uint8List.fromList(imageBytes));

      if (image != null) {
        // Flip image horizontally if using front camera
        img.Image processedImage = cameras[selectedCameraIndex].lensDirection == CameraLensDirection.front
            ? img.flipHorizontal(image)
            : image;

        await imageFile.writeAsBytes(img.encodeJpg(processedImage));

        setState(() {
          _capturedImagePath = imageFile.path;
          _isConfirming = true; // Set to confirmation mode
        });
      }
    }
  }

  void _retryCapture() {
    setState(() {
      _capturedImagePath = null;
      _isConfirming = false;
      _isNotRecognized = false;
    });
  }

  Future<void> _handleManualMark() async {
    if (_capturedImagePath == null || selectedUser == null) {
      _showErrorSnackbar(context, "Please capture an image first.");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.200:8082/attendance/manual-checkin'),
      );

      request.fields['empId'] = selectedUser!;

      String? mimeType = lookupMimeType(_capturedImagePath!) ?? 'image/jpeg';
      var mediaType = MediaType.parse(mimeType);

      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _capturedImagePath!,
        contentType: mediaType,
      ));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Manual Check-in Response: $responseBody');

      if (response.statusCode == 200) {
        if (context.mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Attendance marked successfully'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Navigate to HomeDashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeDashboard()),
            (route) => false,
          );
        }
      } else {
        if (context.mounted) {
          _showErrorSnackbar(context, "Failed to mark attendance manually: $responseBody");
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackbar(context, "Error: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitData(BuildContext context) async {
    if (_capturedImagePath != null && selectedUser != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.0.200:8082/attendance/checkin'),
        );

        request.fields['employeeId'] = selectedUser!;

        String? mimeType = lookupMimeType(_capturedImagePath!) ?? 'image/jpeg';
        var mediaType = MediaType.parse(mimeType);

        request.files.add(await http.MultipartFile.fromPath(
          'file',
          _capturedImagePath!,
          contentType: mediaType,
        ));

        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        print('Response: $responseBody');

        if (response.statusCode == 200) {
          try {
            final decoded = json.decode(responseBody);
            
            // Handle not recognized case
            if (decoded is Map && decoded['status'] == 'not found') {
              setState(() {
                _isNotRecognized = true;
              });
              return;
            }

            if (decoded is Map && decoded['message'] == 'Attendance marked successfully') {
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeDashboard()),
                  (route) => false,
                );
              }
              return;
            }
            if (decoded is Map && decoded['message'] == 'Please check out before checking in again') {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please check out before checking in again'),
                    backgroundColor: Colors.red,
                  ),
                );
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => HomeDashboard()),
                  (route) => false,
                );
              }
              return;
            }
          } catch (_) {}

          if (responseBody.contains('Present')) {
            showAttendancePopup(context, true, () async {}, () {}, selectedUser!);
            widget.onCheckInSuccess?.call();
            Future.delayed(Duration(seconds: 1), () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            });
          } else if (responseBody.contains('Absent')) {
            showAttendancePopup(
              context,
              false,
              () async {
                Navigator.pop(context);
                Navigator.pop(context, false);
              },
              () {
                showAttendancePopup(context, false, () async {}, () {}, selectedUser!);
              },
              selectedUser!,
            );
          }
        } else {
          _showErrorSnackbar(context, "Server Error: $responseBody");
        }
      } catch (e) {
        _showErrorSnackbar(context, "Exception: $e");
      }
    } else {
      _showErrorSnackbar(context, "Please select a user and capture an image.");
    }
  }


  // Helper function to show error messages
  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.teal.shade800),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Face Check-In",
          style: TextStyle(
            color: Colors.teal.shade800,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "Position Your Face in the Frame",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 6),
                        Stack(
                          children: [
                            Container(
                              height: 440,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.teal.shade800,
                              ),
                              child: FutureBuilder<void>(
                                future: _initializeCameraController,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: CameraPreview(_cameraController),
                                    );
                                  } else {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                },
                              ),
                            ),
                            if (_capturedImagePath != null)
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 1,
                                  child: Image.file(
                                    File(_capturedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        SizedBox(height: 16),
                        if (!_isConfirming) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: Icon(Icons.switch_camera, color: Colors.teal),
                                onPressed: _switchCamera,
                              ),
                              IconButton(
                                icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.teal),
                                onPressed: _toggleFlash,
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 120, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: selectedUser == null ? null : _capturePhoto,
                              child: Text("Capture", style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ] else ...[
                          if (_isNotRecognized) ...[
                            Container(
                              padding: EdgeInsets.all(12),
                              margin: EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: Colors.red),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Face not recognized. Please try again or mark manually.",
                                      style: TextStyle(color: Colors.red.shade900),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[300],
                                      foregroundColor: Colors.black87,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _isLoading ? null : _retryCapture,
                                    child: Text("Retry", style: TextStyle(fontSize: 16)),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _isNotRecognized ? Colors.orange : Colors.teal,
                                      foregroundColor: Colors.white,
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: _isLoading ? null : (_isNotRecognized ? _handleManualMark : () => _submitData(context)),
                                    child: _isLoading
                                        ? SizedBox(
                                            height: 20,
                                            width: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : Text(
                                            _isNotRecognized ? "Mark Manually" : "Send",
                                            style: TextStyle(fontSize: 16),
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
}

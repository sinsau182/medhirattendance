import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'attendance_popup.dart';
import 'dropdown.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchUsers();
    if (widget.prefilledUser != null) {
      selectedUser = widget.prefilledUser;
    }
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

  Future<void> _fetchUsers() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.0.200:8082/api/users'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        List<String> sortedUsers = data.map((user) => user['name'].toString()).toList();
        sortedUsers.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        if (mounted) {
          setState(() {
            users = sortedUsers;
          });
        }
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

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
        });
      }
    }
  }

  Future<void> _submitData(BuildContext context) async {
    if (_capturedImagePath != null && selectedUser != null) {
      try {
        var request = http.MultipartRequest(
          'POST',
          Uri.parse('http://192.168.0.200:8082/api/users/verify'),
        );

        request.fields['name'] = selectedUser!;

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



        if (response.statusCode == 200) {
          if (responseBody.contains('Present')) {
            showAttendancePopup(context, true, () async {}, () {}, selectedUser!); // Show success popup

            widget.onCheckInSuccess?.call(); // Call fetchCheckInsToday

            Future.delayed(Duration(seconds: 1), () {
              Navigator.pop(context);
              Navigator.pop(context, true); // Close popup after 1 second
            });
          } else if (responseBody.contains('Absent')) {
            showAttendancePopup(
              context,
              false,
                  () async {
                    Navigator.pop(context);
                    Navigator.pop(context, false);// Close popup first
              },
                  () {
                showAttendancePopup(context, false, () async {}, () {}, selectedUser!); // Manual mark
              },
              selectedUser!, // Pass prefilled user
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

  void _onCaptureButtonPressed() async {
    await _capturePhoto();
    if (context.mounted) {
      _submitData(context);
    }
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
      body: SingleChildScrollView(
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserDropdown(
                      users: users,
                      selectedUser: selectedUser,
                      onUserSelected: (user) {
                        setState(() {
                          selectedUser = user;
                        });
                      },
                    ),
                    if (selectedUser != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          "Selected User: $selectedUser",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.teal.shade800,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 10),
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
                        onPressed: selectedUser == null ? null : _onCaptureButtonPressed,
                        child: Text("Capture", style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

    );
  }
}

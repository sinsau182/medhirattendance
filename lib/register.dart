import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'home_dashboard.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  _RegisterUserScreenState createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  late List<CameraDescription> _cameras;
  late CameraController _cameraController;
  late Future<void> _initializeCameraController;
  String? _capturedImagePath;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;
  bool _isPhotoConfirming = false;
  bool _isLoading = false;
  bool _showCamera = false;
  String? _empId;
  String? _empName;

  @override
  void initState() {
    super.initState();
    _loadEmpData();
    // Set status bar to dark icons for visibility
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ));
  }

  Future<void> _loadEmpData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _empId = prefs.getString('employeeId') ?? 'MED102';
      _empName = prefs.getString('employeeName') ?? 'ankit';
    });
  }

  Future<void> _initializeCamera({int? cameraIndex}) async {
    _cameras = await availableCameras();
    _selectedCameraIndex = cameraIndex ??
        _cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.front);
    if (_selectedCameraIndex == -1) {
      _selectedCameraIndex = 0;
    }
    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );
    _initializeCameraController = _cameraController.initialize();
    if (mounted) setState(() {});
  }

  void _switchCamera() {
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _initializeCamera(cameraIndex: _selectedCameraIndex);
  }

  void _toggleFlash() async {
    if (_cameraController.value.flashMode == FlashMode.off) {
      await _cameraController.setFlashMode(FlashMode.torch);
      setState(() => _isFlashOn = true);
    } else {
      await _cameraController.setFlashMode(FlashMode.off);
      setState(() => _isFlashOn = false);
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
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);
      if (image != null) {
        img.Image processedImage = _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front
            ? img.flipHorizontal(image)
            : image;
        await imageFile.writeAsBytes(img.encodeJpg(processedImage));
        setState(() {
          _capturedImagePath = imageFile.path;
          _isPhotoConfirming = true;
        });
      }
    }
  }

  void _retryPhoto() {
    setState(() {
      _capturedImagePath = null;
      _isPhotoConfirming = false;
      _showCamera = false;
    });
  }

  Future<void> _submitRegistration() async {
    if (_capturedImagePath == null || _empId == null || _empName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Missing photo or employee data!')),
      );
      return;
    }
    setState(() { _isLoading = true; });
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.200:8082/attendance/register'),
      );
      request.fields['empId'] = _empId!;
      request.fields['empName'] = _empName!;
      request.files.add(await http.MultipartFile.fromPath(
        'empImage',
        _capturedImagePath!,
        contentType: MediaType('image', 'jpeg'),
      ));
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Register Response: $responseBody');
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration Completed!'), backgroundColor: Colors.blueAccent),
        );
        await Future.delayed(Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => HomeDashboard()),
            (route) => false,
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $responseBody'), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double cameraFrameWidth = MediaQuery.of(context).size.width * 0.85;
    final double cameraFrameHeight = cameraFrameWidth * 4 / 3; // 4:3 aspect ratio
    final double buttonWidth = MediaQuery.of(context).size.width * 0.7;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F0FF), Color(0xFFB6D8FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 36),
                      // Title
                      Center(
                        child: Text(
                          "Complete Your Profile",
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      // Subtitle
                      Center(
                        child: Text(
                          "Take your selfie to get started",
                          style: TextStyle(fontSize: 15, color: Colors.blue[700]),
                        ),
                      ),
                      SizedBox(height: 30),
                      // Show Add Photo button or Camera
                      if (!_showCamera && !_isPhotoConfirming) ...[
                        Center(
                          child: SizedBox(
                            width: buttonWidth,
                            height: 56,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              onPressed: () async {
                                setState(() { _showCamera = true; });
                                await _initializeCamera();
                              },
                              icon: Icon(Icons.add_a_photo, size: 32),
                              label: Text("Add Your Photo"),
                            ),
                          ),
                        ),
                        SizedBox(height: 16),
                      ] else if (_showCamera && !_isPhotoConfirming) ...[
                        Stack(
                          children: [
                            Container(
                              width: cameraFrameWidth,
                              height: cameraFrameHeight,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                color: Colors.blue[50],
                              ),
                              child: FutureBuilder<void>(
                                future: _initializeCameraController,
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: CameraPreview(_cameraController),
                                    );
                                  } else {
                                    return Center(child: CircularProgressIndicator());
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_cameras.isNotEmpty && _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.back)
                              IconButton(
                                icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off, color: Colors.blue[200], size: 28),
                                onPressed: _toggleFlash,
                              ),
                            IconButton(
                              icon: Icon(Icons.switch_camera, color: Colors.blue[200], size: 28),
                              onPressed: _switchCamera,
                            ),
                          ],
                        ),
                        SizedBox(height: 22),
                        Center(
                          child: SizedBox(
                            width: buttonWidth,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                              ),
                              onPressed: _capturePhoto,
                              icon: Icon(Icons.camera_alt_rounded, size: 24),
                              label: Text("Take Selfie"),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          width: cameraFrameWidth,
                          height: cameraFrameHeight,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            color: Colors.blue[50],
                          ),
                          child: _capturedImagePath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.file(
                                    File(_capturedImagePath!),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Center(child: CircularProgressIndicator()),
                        ),
                        SizedBox(height: 22),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: SizedBox(
                                width: 110,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue[100],
                                    foregroundColor: Colors.blue[900],
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _isLoading ? null : _retryPhoto,
                                  child: Text("Retry", style: TextStyle(fontSize: 15)),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: SizedBox(
                                width: 110,
                                height: 40,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: _isLoading ? null : _submitRegistration,
                                  child: _isLoading
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : Text("Register", style: TextStyle(fontSize: 15)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
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
      ),
    );
  }
}

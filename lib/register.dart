import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';

class RegisterUserScreen extends StatefulWidget {
  const RegisterUserScreen({super.key});

  @override
  _RegisterUserScreenState createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  late List<CameraDescription> _cameras;
  late CameraController _cameraController;
  late Future<void> _initializeCameraController;
  final TextEditingController _nameController = TextEditingController();
  bool _isPhotoCaptured = false;
  bool _isNameEntered = false;
  String? _capturedImagePath;
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera({int? cameraIndex}) async {
    _cameras = await availableCameras();

    // Default to front camera
    _selectedCameraIndex = cameraIndex ??
        _cameras.indexWhere((camera) => camera.lensDirection == CameraLensDirection.front);

    if (_selectedCameraIndex == -1) {
      _selectedCameraIndex = 0; // Fallback to first camera if front is unavailable
    }

    _cameraController = CameraController(
      _cameras[_selectedCameraIndex],
      ResolutionPreset.medium,
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
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_cameraController.value.isInitialized) {
      final XFile file = await _cameraController.takePicture();
      File imageFile = File(file.path);

      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image != null) {
        // Flip image horizontally if using front camera
        img.Image processedImage = _cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.front
            ? img.flipHorizontal(image)
            : image;

        await imageFile.writeAsBytes(img.encodeJpg(processedImage));

        setState(() {
          _capturedImagePath = imageFile.path;
          _isPhotoCaptured = true;
        });
      }
    }
  }

  Future<void> _submitData() async {
    if (_capturedImagePath != null && _nameController.text.isNotEmpty) {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.0.200:8082/api/users/register'),
      );

      request.fields['name'] = _nameController.text;
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _capturedImagePath!,
        contentType: MediaType('image', 'jpeg'),
      ));

      var response = await request.send();
      var responseBody = await response.stream.bytesToString();
      print('Response: $responseBody');

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Data submitted successfully!')));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit data: $responseBody')));
      }
    }
  }

  void _onNameSubmitted() {
    setState(() {
      _isNameEntered = true;
    });
    _submitData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.teal.shade50,
      appBar: AppBar(
        backgroundColor: Colors.teal.shade50,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Register New User",
          style: TextStyle(
            color: Colors.teal.shade900,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      _isPhotoCaptured ? "Enter User Details" : "Capture User Image",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    if (_isPhotoCaptured) ...[
                      Container(
                        height: 430,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade300,
                        ),
                        child: _capturedImagePath != null
                            ? Image.file(
                          File(_capturedImagePath!),
                          fit: BoxFit.cover,
                        )
                            : Center(child: CircularProgressIndicator()),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: "Enter full name",
                        ),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _onNameSubmitted,
                        child: Text("Submit", style: TextStyle(fontSize: 16)),
                      ),
                    ] else ...[
                      Stack(
                        children: [
                          FutureBuilder<void>(
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
                          Positioned(
                            top: 10,
                            right: 10,
                            child: IconButton(
                              icon: Icon(Icons.switch_camera, color: Colors.white, size: 30),
                              onPressed: _switchCamera,
                            ),
                          ),
                          if (_cameras[_selectedCameraIndex].lensDirection == CameraLensDirection.back)
                            Positioned(
                              top: 10,
                              left: 10,
                              child: IconButton(
                                icon: Icon(
                                  _isFlashOn ? Icons.flash_on : Icons.flash_off,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                onPressed: _toggleFlash,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _capturePhoto,
                        icon: Icon(Icons.camera_alt),
                        label: Text("Capture Photo", style: TextStyle(fontSize: 16)),
                      ),
                    ],
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

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart'; // Add this import

class RegisterUserScreen extends StatefulWidget {
  @override
  _RegisterUserScreenState createState() => _RegisterUserScreenState();
}

class _RegisterUserScreenState extends State<RegisterUserScreen> {
  late CameraController _cameraController;
  late Future<void> _initializeCameraController;
  final TextEditingController _nameController = TextEditingController();
  bool _isPhotoCaptured = false;
  bool _isNameEntered = false;
  String? _capturedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  void _initializeCamera() async {
    final cameras = await availableCameras();
    _cameraController = CameraController(cameras[1], ResolutionPreset.medium);
    _initializeCameraController = _cameraController.initialize();
    if (mounted) setState(() {});
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

      // Read image bytes
      Uint8List imageBytes = await imageFile.readAsBytes();
      img.Image? image = img.decodeImage(imageBytes);

      if (image != null) {
        // Flip image horizontally
        img.Image flippedImage = img.flipHorizontal(image);

        // Save the flipped image
        await imageFile.writeAsBytes(img.encodeJpg(flippedImage));

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

      // Add the actual image file, not just the path
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        _capturedImagePath!,
        contentType: MediaType('image', 'jpeg'), // Ensure it's properly recognized
      ));

      // Debugging: Print request details
      print('Request Fields: ${request.fields}');
      print('Sending Image File: $_capturedImagePath');

      var response = await request.send();

      // Convert response to String
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
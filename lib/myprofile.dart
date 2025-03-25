import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String? _editingField;
  final TextEditingController _textController = TextEditingController();
  File? _profileImage;

  Map<String, dynamic> profileData = {};

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    final url = Uri.parse('http://192.168.0.200:8083/employee/id/emp123');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          profileData = json.decode(response.body);
        });

        print('Profile data fetched: $profileData');
      } else {
        throw Exception('Failed to load profile data');
      }
    } catch (e) {
      print('Error fetching profile data: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  void _startEditing(String field, String value) {
    setState(() {
      _editingField = field;
      _textController.text = value;
    });
  }

  void _stopEditing() {
    setState(() {
      _editingField = null;
    });
  }

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _textController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  Widget _buildTextField(
      String label,
      String value, {
        bool isDropdown = false,
        List<String>? dropdownItems,
      }) {
    bool isEditing = _editingField == label;
    String? selectedValue = (dropdownItems != null && dropdownItems.contains(value.trim()))
        ? value.trim()
        : null;

    return GestureDetector(
      onTap: _stopEditing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[600],
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    isEditing ? Icons.check : Icons.edit,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    if (isEditing) {
                      _stopEditing();
                    } else {
                      _startEditing(label, value);
                    }
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 5),
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: isEditing
                ? (label == "Date of Birth"
                ? GestureDetector(
              onTap: () => _selectDate(context),
              child: AbsorbPointer(
                child: TextField(
                  controller: _textController,
                  decoration: InputDecoration(border: InputBorder.none),
                ),
              ),
            )
                : TextField(
              controller: _textController,
              decoration: InputDecoration(border: InputBorder.none),
            ))
                : isDropdown
                ? DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedValue,
                items: dropdownItems!
                    .map((e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ))
                    .toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      selectedValue = newValue;
                    });
                  }
                },
                dropdownColor: Colors.white,
                isExpanded: true,
              ),
            )
                : Text(
              value,
              style: TextStyle(fontSize: 16, color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildUploadButton(String label) {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.blueGrey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!), // Light border
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.upload_file, color: Colors.grey[600]),
            SizedBox(width: 8),
            Text(
              "Upload $label Image",
              style: TextStyle(fontSize: 16, color: Colors.black54), // Lighter font color
            ),
          ],
        ),
      ),
    );
  }

  Widget _playCard(String heading, Widget content) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 6,
            spreadRadius: 1,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            heading,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4FBFB),
      body: Padding(
        padding: const EdgeInsets.only(top: 50.0, bottom: 4.0),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: Colors.teal.shade800),
                  onPressed: () => (
                      Navigator.pop(context)
                  ),
                ),
                Text(
                  'My Profile',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            Expanded(

              child: GestureDetector(
                onTap: _stopEditing,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: 20),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 16),
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: List.generate(4, (index) {
                            return GestureDetector(
                              onTap: () => _onTabTapped(index),
                              child: Container(
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
                                decoration: BoxDecoration(
                                  color: _currentIndex == index ? Colors.white : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: _currentIndex == index
                                      ? [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      spreadRadius: 2,
                                      offset: Offset(0, 2),
                                    )
                                  ]
                                      : [],
                                ),
                                child: Icon(
                                  [
                                    LucideIcons.user,
                                    LucideIcons.briefcase,
                                    LucideIcons.banknote,
                                    LucideIcons.fileText,
                                  ][index],
                                  color: _currentIndex == index ? Colors.black : Colors.grey,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      SizedBox(height: 20),
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 1.4,
                        child: PageView(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentIndex = index),
                          children: [
                            _playCard(
                              "Personal Information",
                              Column(
                                children: [
                                  Center(
                                    child: Column(
                                      children: [
                                        GestureDetector(
                                          onTap: _pickImage,
                                          child: CircleAvatar(
                                            radius: 40,
                                            backgroundColor: Colors.teal[50],
                                            backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                                            child: _profileImage == null
                                                ? Text("JD", style: TextStyle(fontSize: 20, color: Colors.teal))
                                                : null,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text("${profileData!['name']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                        Text("${profileData!['title']}\n${profileData!['department']}", textAlign: TextAlign.center),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  _buildTextField("Full Name", "${profileData!['name']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Email", "${profileData!['email']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Phone Number", "+91 ${profileData!['phone']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Date of Birth", "May 15th, 1990"),
                                  SizedBox(height: 10),
                                  _buildTextField("Gender", "${profileData!['gender']}", isDropdown: true, dropdownItems: ["Male", "Female", "Prefer not to say"]),
                                  SizedBox(height: 10),
                                  _buildTextField("Current Address", "${profileData!['currentAddress']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Permanent Address", "${profileData!['permanentAddress']}"),
                                ],
                              ),
                            ),
                            _playCard(
                              "Job Information",
                              Column(
                                children: [
                                  _buildTextField("Job Title", "${profileData!['title']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Department", "${profileData!['department']}", isDropdown: true, dropdownItems: ["Engineering", "Marketing", "Finance", "IT"]),
                                  SizedBox(height: 10),
                                  _buildTextField("Employee ID", "${profileData!['employeeId']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Joining Date", "March 10th, 2020"),
                                  SizedBox(height: 10),
                                  _buildTextField("Work Location", "New York Office"),
                                  SizedBox(height: 10),
                                  _buildTextField("Reporting Manager", "${profileData!['reportingManager']}"),
                                ],
                              ),
                            ),
                            _playCard(
                              "Bank Information",
                              Column(
                                children: [
                                  _buildTextField("Account Number", "${profileData['bankDetails']?['accountNumber']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Account Holder Name", "${profileData['bankDetails']?['accountHolderName']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Bank Name", "${profileData['bankDetails']?['bankName']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("Branch Name", "${profileData['bankDetails']?['branchName']}"),
                                  SizedBox(height: 10),
                                  _buildTextField("IFSC Code", "${profileData['bankDetails']?['ifscCode']}"),
                                  SizedBox(height: 10),
                                  _buildUploadButton("Passbook"),
                                ],
                              ),
                            ),
                            _playCard(
                              "Identification Information",
                              Column(
                                children: [
                                  _buildTextField("Aadhar Number", "${profileData['idProofs']?['aadharNo']}"),
                                  SizedBox(height: 10),
                                  _buildUploadButton("Aadhar"),
                                  SizedBox(height: 10),
                                  _buildTextField("PAN Number", "${profileData['idProofs']?['panNo']}"),
                                  SizedBox(height: 10),
                                  _buildUploadButton("PAN"),
                                  SizedBox(height: 10),
                                  _buildTextField("Driving License", "${profileData['idProofs']?['drivingLicense']}"),
                                  SizedBox(height: 10),
                                  _buildUploadButton("Driving License"),
                                  SizedBox(height: 10),
                                  _buildTextField("Voter ID", "${profileData['idProofs']?['voterId']}"),
                                  SizedBox(height: 10),
                                  _buildUploadButton("Voter ID"),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
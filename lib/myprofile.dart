import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class MyProfileScreen extends StatefulWidget {
  @override
  _MyProfileScreenState createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  String? _editingField;
  TextEditingController _textController = TextEditingController();
  File? _profileImage;

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

  Widget _buildTextField(String label, String value,
      {bool isDropdown = false, List<String>? dropdownItems}) {
    bool isEditing = _editingField == label;
    return GestureDetector(
      onTap: _stopEditing,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[600])),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(isEditing ? Icons.check : Icons.edit, color: Colors.grey[600]),
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
                value: value,
                items: dropdownItems!
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) {},
                dropdownColor: Colors.white,
                isExpanded: true,
              ),
            )
                : Text(value, style: TextStyle(fontSize: 16, color: Colors.black)),
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
                    children: List.generate(5, (index) {
                      return GestureDetector(
                        onTap: () => _onTabTapped(index),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
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
                              LucideIcons.calendarDays
                            ][index],
                            color: _currentIndex == index ? Colors.black : Colors.grey,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                SizedBox(height: 20),
                Container(
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
                                  Text("John Doe", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  Text("Senior Software Engineer\nEngineering", textAlign: TextAlign.center),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            _buildTextField("Full Name", "John Doe"),
                            SizedBox(height: 10),
                            _buildTextField("Email", "john.doe@company.com"),
                            SizedBox(height: 10),
                            _buildTextField("Phone Number", "+1 (555) 123-4567"),
                            SizedBox(height: 10),
                            _buildTextField("Date of Birth", "May 15th, 1990"),
                            SizedBox(height: 10),
                            _buildTextField("Gender", "Male", isDropdown: true, dropdownItems: ["Male", "Female", "Prefer not to say"]),
                            SizedBox(height: 10),
                            _buildTextField("Current Address", "123 Main Street, Apt 4B, New York, NY 10001"),
                            SizedBox(height: 10),
                            _buildTextField("Permanent Address", "456 Oak Avenue, Springfield, IL 62701"),
                          ],
                        ),
                      ),
                      _playCard(
                        "Job Information",
                        Column(
                          children: [
                            _buildTextField("Job Title", "Senior Software Engineer"),
                            SizedBox(height: 10),
                            _buildTextField("Department", "Engineering", isDropdown: true, dropdownItems: ["Engineering", "Marketing", "Finance"]),
                            SizedBox(height: 10),
                            _buildTextField("Employee ID", "EMP-1234"),
                            SizedBox(height: 10),
                            _buildTextField("Joining Date", "March 10th, 2020"),
                            SizedBox(height: 10),
                            _buildTextField("Work Location", "New York Office"),
                            SizedBox(height: 10),
                            _buildTextField("Reporting Manager", "Jane Smith"),
                          ],
                        ),
                      ),
                      _playCard(
                        "Bank Information",
                        Column(
                          children: [
                            _buildTextField("Account Number", "XXXX-XXXX-XXXX-5678"),
                            SizedBox(height: 10),
                            _buildTextField("Account Holder Name", "John Doe"),
                            SizedBox(height: 10),
                            _buildTextField("Bank Name", "First National Bank"),
                            SizedBox(height: 10),
                            _buildTextField("Branch Name", "Downtown Branch"),
                            SizedBox(height: 10),
                            _buildTextField("IFSC Code", "FNBK0001234"),
                            SizedBox(height: 10),
                            _buildUploadButton("Passbook"),
                          ],
                        ),
                      ),
                      _playCard(
                        "Identification Information",
                        Column(
                          children: [
                            _buildTextField("Aadhar Number", "Not provided"),
                            SizedBox(height: 10),
                            _buildUploadButton("Aadhar"),
                            SizedBox(height: 10),
                            _buildTextField("PAN Number", "ABCDE1234F"),
                            SizedBox(height: 10),
                            _buildUploadButton("PAN"),
                            SizedBox(height: 10),
                            _buildTextField("Driving License", "Not provided"),
                            SizedBox(height: 10),
                            _buildUploadButton("Driving License"),
                            SizedBox(height: 10),
                            _buildTextField("Voter ID", "Not provided"),
                            SizedBox(height: 10),
                            _buildUploadButton("Voter ID"),
                          ],
                        ),
                      ),
                      _playCard(
                        "Leave Information",
                        Column(
                          children: [
                            _buildTextField("Paid Leave Balance", "15"),
                            SizedBox(height: 10),
                            _buildTextField("Sick Leave Balance", "7"),
                            SizedBox(height: 10),
                            _buildTextField("Casual Leave Balance", "5"),
                            SizedBox(height: 10),
                            _buildTextField("Leave Policy", "Standard Employee Leave Policy"),
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
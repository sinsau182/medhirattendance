import 'package:flutter/material.dart';
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
  File? _profileImage;
  bool _isSameAddress = false;
  bool _isBankDetailsEditable = false;
  File? _passbookImage;
  File? _aadharImage;
  File? _panImage;
  File? _drivingLicenseImage;
  File? _voterIdImage;
  File? _passportImage;
  final TextEditingController _currentAddressController = TextEditingController();
  final TextEditingController _permanentAddressController = TextEditingController();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _accountHolderNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _branchNameController = TextEditingController();
  final TextEditingController _ifscCodeController = TextEditingController();
  String? _gender;

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      _pageController.animateToPage(index,
          duration: Duration(milliseconds: 300), curve: Curves.easeInOut);
    });
  }

  Future<void> _pickImage(Function(File) setImage) async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        setImage(File(pickedFile.path));
      });
    }
  }

  void _onCheckboxChanged(bool? value) {
    setState(() {
      _isSameAddress = value ?? false;
      if (_isSameAddress) {
        _permanentAddressController.text = _currentAddressController.text;
      } else {
        _permanentAddressController.clear();
      }
    });
  }

  bool _areAllFieldsFilled() {
    return _fullNameController.text.isNotEmpty &&
        _emailController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _gender != null &&
        _currentAddressController.text.isNotEmpty &&
        (_isSameAddress || _permanentAddressController.text.isNotEmpty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("My Profile"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF4FBFB),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, LucideIcons.user),
                  _buildNavItem(1, LucideIcons.briefcase),
                  _buildNavItem(2, LucideIcons.banknote),
                  _buildNavItem(3, LucideIcons.fileText),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height - kToolbarHeight - 100,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                children: [
                  _buildPersonalDetails(),
                  _buildJobDetails(),
                  _buildBankDetails(),
                  _buildDocuments(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon) {
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: _currentIndex == index ? Colors.blue[100] : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: _currentIndex == index ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPersonalDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? Icon(Icons.person, size: 50, color: Colors.blue)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () => _pickImage((image) => _profileImage = image),
                    child: CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.camera_alt, size: 18, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_areAllFieldsFilled())
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Icon(Icons.check_circle, color: Colors.green[800], size: 30), // Dark green color
              ),
            ),
          SizedBox(height: 20),
          _buildFloatingLabelTextField("Full Name", controller: _fullNameController),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Email Address", controller: _emailController),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Phone Number", controller: _phoneController),
          SizedBox(height: 10),
          _buildFloatingLabelTextField(
            "Gender",
            isDropdown: true,
            dropdownItems: ["Male", "Female"],
            dropdownValue: _gender,
            onChanged: (newValue) {
              setState(() {
                _gender = newValue;
              });
            },
          ),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Current Address", controller: _currentAddressController),
          SizedBox(height: 10),
          Row(
            children: [
              Checkbox(
                value: _isSameAddress,
                onChanged: _onCheckboxChanged,
              ),
              Text("Same as Current Address"),
            ],
          ),
          _buildFloatingLabelTextField("Permanent Address", controller: _permanentAddressController, enabled: !_isSameAddress),
          SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: double.infinity, // Match the width of the input boxes
              child: ElevatedButton(
                onPressed: () {
                  // Handle save action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Background color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Job Information",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildFloatingLabelTextField("Company Name", readOnly: true),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Employee ID", readOnly: true),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Job Title", readOnly: true),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Department", readOnly: true),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Manager's Name", readOnly: true),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Employment Type", readOnly: true, isDropdown: true),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Work Location", readOnly: true),
        ],
      ),
    );
  }

  Widget _buildBankDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Bank Details",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  setState(() {
                    _isBankDetailsEditable = !_isBankDetailsEditable;
                  });
                },
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildFloatingLabelTextField("Account Holder Name", controller: _accountHolderNameController, enabled: _isBankDetailsEditable),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Account Number", controller: _accountNumberController, enabled: _isBankDetailsEditable),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Bank Name", controller: _bankNameController, enabled: _isBankDetailsEditable),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("Branch Name", controller: _branchNameController, enabled: _isBankDetailsEditable),
          SizedBox(height: 10),
          _buildFloatingLabelTextField("IFSC Code", controller: _ifscCodeController, enabled: _isBankDetailsEditable),
          SizedBox(height: 10),
          if (_passbookImage == null)
            ElevatedButton.icon(
              onPressed: _isBankDetailsEditable ? () => _pickImage((image) => _passbookImage = image) : null,
              icon: Icon(Icons.upload_file),
              label: Text("Browse"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _isBankDetailsEditable ? () => _pickImage((image) => _passbookImage = image) : null,
              child: CircleAvatar(
                radius: 30,
                backgroundImage: FileImage(_passbookImage!),
              ),
            ),
          SizedBox(height: 10),
          Text(
            "Upload a scanned copy of your bank passbook (PDF or image)",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: double.infinity, // Match the width of the input boxes
              child: ElevatedButton(
                onPressed: () {
                  // Handle save action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Background color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingLabelTextField(String label, {TextEditingController? controller, bool enabled = true, bool readOnly = false, bool isDropdown = false, List<String>? dropdownItems, String? dropdownValue, Function(String?)? onChanged}) {
    if (isDropdown) {
      return Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey, width: 2),
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: label,
            border: InputBorder.none,
          ),
          items: dropdownItems?.map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: readOnly ? null : onChanged,
          dropdownColor: Colors.white,
          style: TextStyle(color: Colors.black),
          iconEnabledColor: Colors.grey,
          value: dropdownValue,
        ),
      );
    } else {
      return TextFormField(
        controller: controller,
        enabled: enabled,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      );
    }
  }


  Widget _buildDocuments() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Documents",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          _buildDocumentField("Aadhar Number", (image) => _aadharImage = image, _aadharImage),
          SizedBox(height: 10),
          _buildDocumentField("PAN Number", (image) => _panImage = image, _panImage),
          SizedBox(height: 10),
          _buildDocumentField("Driving License Number", (image) => _drivingLicenseImage = image, _drivingLicenseImage),
          SizedBox(height: 10),
          _buildDocumentField("Voter ID Number", (image) => _voterIdImage = image, _voterIdImage),
          SizedBox(height: 10),
          _buildDocumentField("Passport Number", (image) => _passportImage = image, _passportImage),
          SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: double.infinity, // Match the width of the input boxes
              child: ElevatedButton(
                onPressed: () {
                  // Handle save action
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Background color
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentField(String label, Function(File) setImage, File? image) {
    return Row(
      children: [
        Expanded(
          child: TextFormField(
            decoration: InputDecoration(
              labelText: label,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
            ),
          ),
        ),
        SizedBox(width: 10),
        _buildUploadButton(setImage, image),
      ],
    );
  }

  Widget _buildUploadButton(Function(File) setImage, File? image) {
    return GestureDetector(
      onTap: () => _pickImage(setImage),
      child: CircleAvatar(
        radius: 30,
        backgroundColor: Colors.grey[100],
        child: image == null
            ? Icon(Icons.file_upload_outlined, size: 30, color: Colors.black38)
            : CircleAvatar(
          radius: 28,
          backgroundImage: FileImage(image),
        ),
      ),
    );
  }
}
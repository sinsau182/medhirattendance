import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:math';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  bool isEditing = false;
  final TextEditingController _nameController = TextEditingController(text: 'Kishan');
  final TextEditingController _emailController = TextEditingController(text: 'kishan@gmail.com');
  final TextEditingController _phoneController = TextEditingController(text: '0987654321');
  final TextEditingController _fatherNameController = TextEditingController(text: '---');
  final TextEditingController _alternatePhoneController = TextEditingController(text: '---');
  final TextEditingController _accountNumberController = TextEditingController(text: '---');
  final TextEditingController _ifscController = TextEditingController(text: '---');
  final TextEditingController _bankNameController = TextEditingController(text: '---');
  final TextEditingController _branchNameController = TextEditingController(text: '---');
  final TextEditingController _upiPhoneController = TextEditingController(text: '---');
  final TextEditingController _upiIdController = TextEditingController(text: '---');

  @override
  Widget build(BuildContext context) {
    final Color cardBg = Colors.white;
    final Color sectionTitle = Colors.blueGrey.shade900;
    final Color labelColor = Colors.blueGrey.shade700;
    final Color valueColor = Colors.blueGrey.shade800;
    final double cardRadius = 18;
    final double sectionSpacing = 18;
    final double fieldSpacing = 8;
    final Color borderColor = Colors.blueGrey.shade100;
    final Color bgColor = const Color(0xFFF0F6FF); // Soft blue background

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Profile', style: TextStyle(color: Colors.blueGrey.shade900, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: Colors.blueGrey.shade900),
        actions: [
          IconButton(
            icon: Icon(isEditing ? Icons.check : Icons.edit, color: Color(0xFF5C7CFA)),
            onPressed: () {
              setState(() {
                isEditing = !isEditing;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Animated Gradient Header Card
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(cardRadius),
                border: Border.all(color: borderColor, width: 1.2),
                gradient: LinearGradient(
                  colors: [Color(0xFFB6E0FE), Color(0xFF74C0FC), Color(0xFF5C7CFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.18),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            CircleAvatar(
                              radius: 38,
                              backgroundColor: Colors.white,
                              child: Icon(Icons.person, size: 50, color: Color(0xFF5C7CFA)),
                            ),
                            if (isEditing)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(Icons.camera_alt, size: 20, color: Color(0xFF5C7CFA)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.verified, color: Colors.green, size: 16),
                                        const SizedBox(width: 4),
                                        Text('Active Employee', style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.w600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade100,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.blue, size: 16),
                                        const SizedBox(width: 4),
                                        Text('Joined on 12/21/2024', style: TextStyle(color: Colors.blue.shade800, fontWeight: FontWeight.w600, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (isEditing)
                                TextField(
                                  controller: _nameController,
                                  style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                  ),
                                )
                              else
                                Text('Kishan', style: TextStyle(fontSize: 23, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900, letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text('CLAD1   |   Marketing  •  Sales', style: TextStyle(fontSize: 15, color: Colors.blueGrey.shade700)),
                              const SizedBox(height: 2),
                              if (isEditing)
                                TextField(
                                  controller: _emailController,
                                  style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                    border: InputBorder.none,
                                    hintText: 'Enter email',
                                  ),
                                )
                              else
                                Text('No official email', style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade400)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.edit, size: 18),
                          label: Text('Edit Profile'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF5C7CFA),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            textStyle: TextStyle(fontWeight: FontWeight.bold),
                            elevation: 0,
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: Text('Report to'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF5C7CFA),
                            side: BorderSide(color: Color(0xFF5C7CFA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                        OutlinedButton(
                          onPressed: () {},
                          child: Text('PF Status Enrolled'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF5C7CFA),
                            side: BorderSide(color: Color(0xFF5C7CFA)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Section Cards
            _sectionCard(
              icon: Icons.person_outline,
              title: 'Personal Information',
              children: [
                _editableInfoRow('Father\'s Name', _fatherNameController),
                _infoRow('Gender', 'Male'),
                _editableInfoRow('Phone', _phoneController),
                _editableInfoRow('Alternate Phone', _alternatePhoneController),
                _editableInfoRow('Personal Email', _emailController),
              ],
            ),
            SizedBox(height: sectionSpacing),
            _sectionCard(
              icon: Icons.verified_user_outlined,
              title: 'Statutory Information',
              children: [
                _infoRow('PF Status', 'Enrolled', valueColor: Colors.green),
                _infoRow('UAN Number', '---'),
                _infoRow('ESIC Status', 'Not Enrolled', valueColor: Colors.red),
              ],
            ),
            SizedBox(height: sectionSpacing),
            _sectionCard(
              icon: Icons.account_balance_outlined,
              title: 'Bank Information',
              children: [
                _editableInfoRow('Account Number', _accountNumberController),
                _editableInfoRow('IFSC Code', _ifscController),
                _editableInfoRow('Bank Name', _bankNameController),
                _editableInfoRow('Branch Name', _branchNameController),
                _editableInfoRow('UPI Phone', _upiPhoneController),
                _editableInfoRow('UPI ID', _upiIdController),
                _infoRow('Bank Passbook', 'Not uploaded'),
              ],
            ),
            SizedBox(height: sectionSpacing),
            _sectionCard(
              icon: Icons.badge_outlined,
              title: 'Identity Documents',
              children: [
                _infoRow('Aadhar No.', 'No document'),
                _infoRow('PAN No.', 'No document'),
                _infoRow('Passport', 'No document'),
                _infoRow('Driving Licence', 'No document'),
                _infoRow('Voter ID', 'No document'),
              ],
            ),
            SizedBox(height: sectionSpacing),
            _sectionCard(
              icon: Icons.payments_outlined,
              title: 'Salary Information',
              children: [
                _infoRow('Annual CTC', '₹0'),
                _infoRow('Monthly CTC', '₹0'),
                _infoRow('Basic Salary', '₹0'),
                _infoRow('HRA', '₹0'),
                _infoRow('Allowances', '₹0'),
                _infoRow('Employer PF', '₹0'),
                _infoRow('Employee PF', '₹0'),
              ],
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required IconData icon, required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blueGrey.shade100, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.blueGrey.shade50,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Color(0xFF5C7CFA), size: 22),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade900)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: Text(value, style: TextStyle(color: valueColor ?? Colors.blueGrey.shade800, fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _editableInfoRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(label, style: TextStyle(color: Colors.blueGrey.shade700, fontSize: 14)),
          ),
          Expanded(
            flex: 3,
            child: isEditing
                ? TextField(
                    controller: controller,
                    style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.w500, fontSize: 14),
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.blueGrey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Color(0xFF5C7CFA)),
                      ),
                    ),
                  )
                : Text(controller.text, style: TextStyle(color: Colors.blueGrey.shade800, fontWeight: FontWeight.w500, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
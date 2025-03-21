import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({Key? key}) : super(key: key);

  @override
  _ApplyLeaveScreenState createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _leaveType;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _reason;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final requestBody = {
        'employeeId': 'emp123',
        'leaveType': _leaveType,
        'startDate': _startDate?.toIso8601String().split('T')[0], // Format the start date
        'endDate': _endDate?.toIso8601String().split('T')[0],
        'reason': _reason,
      };

      print(requestBody);

      final response = await http.post(
        Uri.parse('http://192.168.0.200:8084/leaves'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Leave application submitted successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit leave application')),

        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New Leave Application',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 16),
                Text(
                  'Leave Type',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                DropdownButtonFormField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF4FBFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  items: ['Casual Leave', 'Sick Leave', 'Privilege Leave']
                      .map((leave) => DropdownMenuItem(
                            value: leave,
                            child: Text(leave),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _leaveType = value as String?;
                    });
                  },
                  validator: (value) => value == null ? 'Please select a leave type' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Date',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF4FBFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              suffixIcon: Icon(Icons.calendar_today),
                              hintText: _startDate != null ? _startDate!.toLocal().toString().split(' ')[0] : 'Select date',
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _startDate = pickedDate;
                                });
                              }
                            },
                            validator: (value) => _startDate == null ? 'Please select a start date' : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'End Date',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            readOnly: true,
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Color(0xFFF4FBFB),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              suffixIcon: Icon(Icons.calendar_today),
                              hintText: _endDate != null ? _endDate!.toLocal().toString().split(' ')[0] : 'Select date',
                            ),
                            onTap: () async {
                              DateTime? pickedDate = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2101),
                              );
                              if (pickedDate != null) {
                                setState(() {
                                  _endDate = pickedDate;
                                });
                              }
                            },
                            validator: (value) => _endDate == null ? 'Please select an end date' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Reason',
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                TextFormField(
                  maxLines: 3,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color(0xFFF4FBFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: Colors.black, width: 2),
                    ),
                    hintText: 'Please provide a reason for your leave',
                  ),
                  onSaved: (value) {
                    _reason = value;
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please provide a reason' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFF4FBFB),
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF00AD9C),
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                      ),
                      child: Text(
                        'Submit',
                        style: GoogleFonts.inter(
                          color: Color(0xFFF5FCFB),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
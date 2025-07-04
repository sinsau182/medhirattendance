import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'toast.dart';
import 'home_dashboard.dart';
import 'register.dart';
import 'manager_screen.dart';
import 'package:jwt_decode/jwt_decode.dart';


class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isFilled = false;

  @override
  void initState() {
    super.initState();
    emailController.addListener(_updateFilledState);
    passwordController.addListener(_updateFilledState);
  }

  @override
  void dispose() {
    emailController.removeListener(_updateFilledState);
    passwordController.removeListener(_updateFilledState);
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void _updateFilledState() {
    setState(() {
      _isFilled = emailController.text.isNotEmpty && passwordController.text.isNotEmpty;
    });
  }

  Future<void> _login() async {
    final String email = emailController.text.trim();
    final String password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Email and password are required');
      return;
    }

    _showLoading();

    try {
      final response = await http.post(
        Uri.parse('http://192.168.0.200:8080/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password
        }),
      );

      Navigator.pop(context); // Close loading dialog

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Login response: $data');

        if (data['token'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('authToken', data['token']);
          await prefs.setString('employeeId', data['employeeId']);

          // Parse JWT token to get employee name
          final token = data['token'];
          Map<String, dynamic> payload = Jwt.parseJwt(token);
          await prefs.setString('employeeName', payload['name'] ?? '');

          // Save roles from response (case-insensitive)
          List roles = [];
          if (data['roles'] != null && data['roles'] is List) {
            roles = (data['roles'] as List).map((r) => r.toString().toUpperCase().trim()).toList();
            await prefs.setString('roles', json.encode(roles));
          }

          // Show Custom Toast
          ToastHelper.showCustomToast(context);

          // Check if employee is registered
          final empId = prefs.getString('employeeId') ?? '';
          final checkUrl = 'http://192.168.0.200:8082/manager/registered-users/$empId';
          final checkResponse = await http.get(Uri.parse(checkUrl));
          final checkData = json.decode(checkResponse.body);

          print('Check registration response: $checkData');

          if (checkData['status'] == true) {
            // Registration complete, now check roles
            if (roles.contains('MANAGER')) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ManagerScreen()),
              );
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeDashboard()),
              );
            }
          } else {
            // Not registered, pass roles to RegisterUserScreen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => RegisterUserScreen(roles: roles)),
            );
          }
        } else {
          _showError('Invalid login response: No token received');
        }
      } else {
        print('Login failed with status: ${response.statusCode}');
        print('Response body: ${response.body}');

        try {
          final data = json.decode(response.body);
          _showError(data['message'] ?? 'Failed to authenticate');
        } catch (e) {
          _showError('Failed to authenticate. Please try again.');
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Login error: $e');
      _showError('Connection error. Please check your internet connection.');
    }
  }

  void _showLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
          ),
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FE),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // // Top Icon
              // Container(
              //   decoration: BoxDecoration(
              //     color: Colors.white,
              //     shape: BoxShape.circle,
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.blue.withOpacity(0.08),
              //         blurRadius: 16,
              //         offset: Offset(0, 4),
              //       ),
              //     ],
              //   ),
              //   padding: EdgeInsets.all(24),
              //   child: Icon(Icons.assignment, color: Color(0xFF2563EB), size: 48),
              // ),
              SizedBox(height: 24),
              // Welcome Text
              Text(
                "Welcome to Medhir",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                  color: Color(0xFF232B55),
                ),
              ),
              SizedBox(height: 8),
              Text(
                "Sign in to mark your attendance",
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 16,
                ),
              ),
              SizedBox(height: 32),
              Container(
                width: 320,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        "Employee Login",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Color(0xFF232B55),
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    Text(
                      "Email",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF232B55),
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.person_outline, color: Colors.grey),
                        hintText: "Enter your Email ID",
                        filled: true,
                        fillColor: Color(0xFFF4F7FE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      "Password",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF232B55),
                        fontSize: 15,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      onChanged: (value) {
                        setState(() {}); // Trigger rebuild to update isFilled state
                      },
                      decoration: InputDecoration(
                        prefixIcon: Icon(Icons.lock_outline, color: Colors.grey),
                        hintText: "Enter your password",
                        filled: true,
                        fillColor: Color(0xFFF4F7FE),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: _isFilled
                              ? LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1CB5E0)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          )
                              : LinearGradient(
                            colors: [Colors.blue.shade200, Colors.blue.shade100],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ElevatedButton(
                          onPressed: _isFilled ? _login : null,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            textStyle: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          child: Text(
                            "Sign In",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
// import 'employee-dashborad.dart';
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

  bool get isFilled =>
      emailController.text.isNotEmpty && passwordController.text.isNotEmpty;

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
      backgroundColor: Color(0xFFF5F6FA),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87)),
              SizedBox(height: 32),
              TextField(
                controller: emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              SizedBox(height: 18),
              TextField(
                controller: passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
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
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4F8CFF),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: isFilled ? _login : null,
                  child: Text('Login', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
import 'package:flutter/material.dart';
import 'employee-dashborad.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      builder: (context, child) {
        return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(1.0), // Prevent font scaling
            ),
            child: child!);
      },
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
      ),
      // home: const HomePage(),
      //  home: const LeaveManagementScreen(),
      // home: ExpenseForm(),
      // home: SalaryPayrollPage(),
      //home: PayslipScreen(),
      // home: MyProfileScreen(),
      home: const EmployeeDashboard(),
    );
  }
}


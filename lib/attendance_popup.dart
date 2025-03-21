import 'package:flutter/material.dart';
import 'employee-dashborad.dart';
import 'home_page.dart';
import 'check-in.dart';

void showAttendancePopup(
  BuildContext context,
  bool isSuccess,
  Future<void> Function() onRetry, // Retry function now async
  VoidCallback onManualMark,
  String selectedUser, // Add selectedUser parameter
) {
  showModalBottomSheet(
    context: context,
    isDismissible: false, // Prevent accidental dismissal
    enableDrag: false,
    backgroundColor: Colors.transparent, // Sleek UI
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.4, // 40% screen height
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle_outline : Icons.error_outline,
              color: isSuccess ? Colors.green : Colors.red,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              isSuccess ? "Attendance Marked Successfully!" : "Failed to Mark Attendance",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isSuccess
                  ? "You have successfully checked in."
                  : "There was an issue marking your attendance. Please try again or mark it manually.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            if (!isSuccess)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(context); // Close popup first
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeDashboard()),
                      );// Navigate to CheckInScreen
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: const Text("Retry", style: TextStyle(color: Colors.white)),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close popup first
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeDashboard()),
                      ); // Navigate to HomePage
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    child: const Text("Mark Manually", style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}
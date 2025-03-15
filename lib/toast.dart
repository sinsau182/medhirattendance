import 'package:flutter/material.dart';

class ToastHelper {
  static void showCustomToast(BuildContext context) {
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 40,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 8,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Toast Content
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Login successful',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                      ),
                      SizedBox(height: 4),
                      Text('Welcome back!', style: TextStyle(fontSize: 14, color: Colors.black54)),
                    ],
                  ),

                  // Close Button
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.black54),
                    onPressed: () {
                      try {
                        overlayEntry?.remove();
                        overlayEntry = null;
                      } catch (e) {
                        debugPrint('Error removing toast: $e');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    // Get overlay state safely
    OverlayState? overlayState = Overlay.of(context, rootOverlay: true);
    if (overlayState != null) {
      overlayState.insert(overlayEntry!);
    } else {
      debugPrint('Error: Overlay not found');
      return;
    }

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      try {
        overlayEntry?.remove();
        overlayEntry = null;
      } catch (e) {
        debugPrint('Error auto-removing toast: $e');
      }
    });
  }
}

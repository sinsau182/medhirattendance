import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _mController;
  late Animation<double> _mScaleAnimation;
  int _visibleLetters = 0;

  @override
  void initState() {
    super.initState();
    _mController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _mScaleAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _mController, curve: Curves.easeOutBack),
    );
    _mController.forward();

    // After M grows, start showing letters one by one
    Future.delayed(const Duration(milliseconds: 500), () async {
      for (int i = 1; i <= 5; i++) {
        await Future.delayed(const Duration(milliseconds: 120));
        setState(() {
          _visibleLetters = i;
        });
      }
    });

    // Navigate to login screen after animation
    Future.delayed(const Duration(milliseconds: 1300), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _mController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const String rest = 'edhir';
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE0F7FA), Color(0xFFFFFFFF)],
          ),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // M with accent color, shadow, and scale
              ScaleTransition(
                scale: _mScaleAnimation,
                child: Text(
                  'M',
                  style: GoogleFonts.inter(
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                    shadows: [
                      Shadow(
                        blurRadius: 16,
                        color: Colors.teal.withOpacity(0.3),
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                ),
              ),
              // Animated 'edhir' letters
              ...List.generate(5, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  margin: EdgeInsets.only(left: _visibleLetters > i ? 0 : 30),
                  child: AnimatedOpacity(
                    opacity: _visibleLetters > i ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: AnimatedSlide(
                      offset: _visibleLetters > i ? Offset.zero : const Offset(0.4, 0.2),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: Text(
                        rest[i],
                        style: GoogleFonts.inter(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          shadows: [
                            Shadow(
                              blurRadius: 10,
                              color: Colors.teal.withOpacity(0.15),
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
} 
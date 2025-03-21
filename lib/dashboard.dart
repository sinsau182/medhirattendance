import 'package:flutter/material.dart';

class DashboardCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double delay;
  final String? className; // This can be used for custom styling if needed

  const DashboardCard({
    Key? key,
    required this.child,
    this.onTap,
    this.delay = 0.0,
    this.className,
  }) : super(key: key);

  @override
  _DashboardCardState createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 400),
    );

    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.1), end: Offset(0, 0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: (widget.delay * 150).toInt()), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.translate(
                offset: _slideAnimation.value,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: -2,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: widget.child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
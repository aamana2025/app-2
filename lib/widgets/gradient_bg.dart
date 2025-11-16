import 'package:flutter/material.dart';

class GradientDecoratedBackground extends StatelessWidget {
  final Widget child;

  const GradientDecoratedBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFEFF6FF),
                Color(0xFFFFFFFF),
              ],
            ),
          ),
        ),
        // Soft radial blue glow top-right
        Positioned(
          top: -80,
          right: -60,
          child: _blurredCircle(const Color(0xFF0A84FF).withOpacity(0.25), 220),
        ),
        // Soft radial blue glow bottom-left
        Positioned(
          bottom: -100,
          left: -80,
          child: _blurredCircle(const Color(0xFF007AFF).withOpacity(0.22), 260),
        ),
        // Decorative gradient rings
        Positioned(
          top: 140,
          left: -30,
          child: _ring(),
        ),
        Positioned(
          bottom: 140,
          right: -20,
          child: Transform.rotate(angle: 0.5, child: _ring(size: 160)),
        ),
        // App brand mark (subtle) center faint
        Center(
          child: Opacity(
            opacity: 0.06,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: const Color(0xFF0A84FF).withOpacity(0.35),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(Icons.school, size: 64, color: Color(0xFF0A84FF)),
              ),
            ),
          ),
        ),
        // Foreground content
        child,
      ],
    );
  }

  Widget _blurredCircle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }

  Widget _ring({double size = 120}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          width: 2,
          color: const Color(0xFF0A84FF).withOpacity(0.4),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 2,
            color: const Color(0xFF007AFF).withOpacity(0.35),
          ),
        ),
      ),
    );
  }
}

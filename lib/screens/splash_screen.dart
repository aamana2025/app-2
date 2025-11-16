import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late Animation<double> _logoAnimation;
  late Animation<double> _logoMoveAnimation;
  late Animation<double> _textAnimation;

  @override
  void initState() {
    super.initState();

    // Logo animation controller
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Text animation controller
    _textController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Logo scale: pop-in and slightly grow while moving up
    // Start from 0.9 to avoid flash, then animate to 1.1
    _logoAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutBack,
    ));

    // Logo vertical movement upwards (in pixels)
    _logoMoveAnimation = Tween<double>(
      begin: 0.0,
      end: -36.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOutQuad,
    ));

    _textAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Logo is already visible at 0.9 scale from the start, so animation begins immediately
    // Start logo animation
    await _logoController.forward();

    // Wait a bit then start text animation
    await Future.delayed(const Duration(milliseconds: 500));
    await _textController.forward();

    // Wait a bit more then check authentication
    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Check if user is authenticated and has a valid token
    if (authProvider.isAuthenticated && authProvider.token != null) {
      // Try to validate session by fetching fresh user data
      print('SplashScreen: Auto-login detected, validating session...');

      try {
        final success = await authProvider.refreshUserData();

        if (success) {
          print(
              'SplashScreen: Session validated successfully, routing to home');
          if (mounted) {
            context.go('/home');
          }
          return;
        } else {
          // Do not clear stored auth on transient or backend errors.
          // Proceed to app using cached user data; screens can refresh later.
          print(
              'SplashScreen: Session validation failed, proceeding to home with cached auth');
          if (mounted) {
            context.go('/home');
          }
          return;
        }
      } catch (e) {
        // Network or parsing error: keep user logged in and continue.
        print('SplashScreen: Error during auto-login, continuing: $e');
        if (mounted) {
          context.go('/home');
        }
        return;
      }
    } else {
      // No stored authentication, go to login
      print('SplashScreen: No stored authentication, routing to login');
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double shortestSide = screenSize.shortestSide;
    // Scale between 0.8 (very small phones) and 1.1 (large phones)
    final double uiScale = shortestSide / 360.0;
    final double scale = uiScale.clamp(0.8, 1.1);

    final double logoSize = 120 * scale;
    final double logoMoveUp = -24.0 * scale;
    final double bigBlob = 160 * scale;
    final double smallBlob = 120 * scale;
    final double iconLarge = 40 * scale;
    final double iconSmall = 28 * scale;
    final double textFontSize = (40 * scale).clamp(22.0, 42.0);
    final double textMaxWidth = screenSize.width * 0.82;
    final double pad24 = 24 * scale;
    final double pad30 = 30 * scale;
    final double pad60 = 60 * scale;
    final double pad90 = 90 * scale;
    final double pad120 = 120 * scale;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7FAFF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Soft blobs and caps
          Positioned(
            left: -30 * scale,
            top: pad60,
            child: _blob(smallBlob, const Color(0xFF0A84FF).withOpacity(0.20)),
          ),
          Positioned(
            right: -40 * scale,
            bottom: -20 * scale,
            child: _blob(bigBlob, const Color(0xFF007AFF).withOpacity(0.18)),
          ),
          Positioned(
            right: pad24,
            top: pad90,
            child: Icon(Icons.school,
                color: const Color(0xFF0A84FF).withOpacity(0.14),
                size: iconLarge),
          ),
          Positioned(
            left: pad30,
            bottom: pad120,
            child: Icon(Icons.school,
                color: const Color(0xFF0A84FF).withOpacity(0.14),
                size: iconSmall),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animation: move up while scaling
                // Show logo immediately at initial scale to avoid flash
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        _logoMoveAnimation.value * scale +
                            logoMoveUp -
                            (-36.0 * scale),
                      ),
                      child: Transform.scale(
                        scale: _logoAnimation.value,
                        child: Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF0A84FF),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xFF0A84FF).withOpacity(0.25),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              )
                            ],
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 60,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: (40 * scale).clamp(20.0, 48.0)),

                // Animated text
                AnimatedBuilder(
                  animation: _textAnimation,
                  builder: (context, child) {
                    return _buildHandwritingText(textFontSize, textMaxWidth);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withOpacity(0.0)],
          radius: 0.9,
        ),
      ),
    );
  }

  Widget _buildHandwritingText(double fontSize, double maxWidth) {
    const text = "Aamana classroom";

    // Use a connected script font and reveal the text smoothly from left to right
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: ClipRect(
        child: Align(
          alignment: Alignment.centerLeft,
          widthFactor: _textAnimation.value.clamp(0.0, 1.0),
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: fontSize,
                color: const Color(0xFF0A84FF),
                fontFamily: 'WindSong',
                fontWeight: FontWeight.w500,
                letterSpacing: 0.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

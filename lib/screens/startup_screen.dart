import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:new_version_plus/new_version_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'no_internet_screen.dart';

class StartupScreen extends StatefulWidget {
  final Widget child;

  const StartupScreen({super.key, required this.child});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _isInitializing = true;
  bool _hasInternet = true;
  bool _hasShownUpdateDialog = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _performStartupChecks();
    _startConnectivityListener();
  }

  Future<void> _performStartupChecks() async {
    try {
      // Check internet connection first
      await _checkInternetConnection();

      // Don't block on app updates - check in background
      if (_hasInternet) {
        // Check for app updates in background (don't wait for it)
        _checkForAppUpdates().catchError((e) {
          print('StartupScreen: Error checking for app updates: $e');
        });
      }
      
      // Mark initialization complete immediately after connectivity check
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      print('StartupScreen: Error during startup checks: $e');
      // Even on error, allow app to proceed
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _startConnectivityListener() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      ConnectivityResult result,
    ) {
      // Check if result indicates connectivity
      final hasConnection = result != ConnectivityResult.none;

      if (mounted) {
        setState(() {
          _hasInternet = hasConnection;
        });
      }
    });
  }

  Future<void> _checkInternetConnection() async {
    try {
      final connectivityResult = await Connectivity().checkConnectivity();

      final hasConnection = connectivityResult != ConnectivityResult.none;

      setState(() {
        _hasInternet = hasConnection;
      });
    } catch (e) {
      print('StartupScreen: Error checking internet connection: $e');
      setState(() {
        _hasInternet = false;
      });
    }
  }

  Future<void> _checkForAppUpdates() async {
    try {
      final newVersion = NewVersionPlus(
        androidId:
            'com.aamanaclassroom.app', // Your actual Android package name
        iOSId:
            'com.aamanaclassroom.app.ios', // TODO: Replace with your actual iOS bundle ID when available
      );

      final status = await newVersion.getVersionStatus();

      if (status != null &&
          status.canUpdate &&
          mounted &&
          !_hasShownUpdateDialog) {
        setState(() {
          _hasShownUpdateDialog = true;
        });

        _showUpdateDialog(status.appStoreLink);
      }
    } catch (e) {
      print('StartupScreen: Error checking for app updates: $e');
      // Don't show error to user, just continue with app
    }
  }

  void _showUpdateDialog(String storeUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.system_update, color: Color(0xFF0A84FF), size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'تحديث متاح',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'يتوفر إصدار جديد من التطبيق مع تحسينات وميزات جديدة.',
                style: TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                  height: 1.5,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'نوصي بتحديث التطبيق للحصول على أفضل تجربة.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            // Later Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'لاحقاً',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // Update Now Button
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _launchStoreUrl(storeUrl);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: const Text(
                'تحديث الآن',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchStoreUrl(String storeUrl) async {
    try {
      final uri = Uri.parse(storeUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('لا يمكن فتح رابط المتجر'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('StartupScreen: Error launching store URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('خطأ في فتح رابط المتجر'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onRetryConnection() {
    setState(() {
      _isInitializing = true;
    });
    _performStartupChecks();
  }

  @override
  Widget build(BuildContext context) {
    // If no internet connection, show NoInternetScreen
    if (!_hasInternet) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: NoInternetScreen(onRetry: _onRetryConnection),
      );
    }

    // Show loading screen while performing startup checks
    if (_isInitializing) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: _buildLoadingScreen(),
      );
    }

    // All checks passed, show the main app
    return widget.child;
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background gradient - matching SplashScreen exactly
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFF7FAFF), Colors.white],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // App Logo/Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF0A84FF),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A84FF).withOpacity(0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.school,
                    size: 50,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 32),

                // App Name
                const Text(
                  'Aamana Classroom',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),

                const SizedBox(height: 16),

                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0A84FF)),
                  strokeWidth: 3,
                ),

                const SizedBox(height: 24),

                // Loading text
                const Text(
                  'جاري التحميل...',
                  style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

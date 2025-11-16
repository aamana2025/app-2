import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/profile_info_row.dart';
import '../widgets/gradient_bg.dart';
import '../widgets/countdown_timer.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _planDetails;
  bool _isLoadingPlan = false;

  @override
  void initState() {
    super.initState();
    _loadPlanDetails();
  }

  // Glass-styled snackbar helper to unify success/error toasts
  void _showGlassSnackBar(
    BuildContext context, {
    required String message,
    required Color color,
    IconData icon = Icons.info_outline,
  }) {
    final snack = SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 2),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.65),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                    ),
                  ),
                  child: Icon(icon, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snack);
  }

  // Clean container with blue outer border and decorative elements
  Widget _glassContainer({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(20),
    BorderRadiusGeometry borderRadius =
        const BorderRadius.all(Radius.circular(16)),
    bool showDecorations = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
        border: Border.all(
          color: const Color(0xFF0A84FF).withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0A84FF).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Random graduation cap shadows
          if (showDecorations) ...[
            // Top area graduation caps
            Positioned(
                top: 8, left: 12, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 12, left: 45, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 6, left: 78, child: _buildGraduationCap(10, 0.012, 0.06)),
            Positioned(
                top: 15, left: 120, child: _buildGraduationCap(7, 0.01, 0.05)),
            Positioned(
                top: 9, left: 160, child: _buildGraduationCap(9, 0.011, 0.055)),
            Positioned(
                top: 11,
                left: 200,
                child: _buildGraduationCap(5, 0.007, 0.035)),
            Positioned(
                top: 7, left: 240, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 13, left: 280, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 5, left: 320, child: _buildGraduationCap(9, 0.011, 0.055)),

            // Middle area graduation caps
            Positioned(
                top: 35, left: 8, child: _buildGraduationCap(7, 0.009, 0.045)),
            Positioned(
                top: 38, left: 35, child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 32, left: 65, child: _buildGraduationCap(9, 0.011, 0.055)),
            Positioned(
                top: 40, left: 95, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 36, left: 125, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 34,
                left: 155,
                child: _buildGraduationCap(7, 0.009, 0.045)),
            Positioned(
                top: 39, left: 185, child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 33,
                left: 215,
                child: _buildGraduationCap(9, 0.011, 0.055)),
            Positioned(
                top: 37, left: 245, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 35, left: 275, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 38,
                left: 305,
                child: _buildGraduationCap(7, 0.009, 0.045)),

            // Lower area graduation caps
            Positioned(
                top: 65, left: 15, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 68, left: 42, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 62, left: 72, child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 70,
                left: 102,
                child: _buildGraduationCap(9, 0.011, 0.055)),
            Positioned(
                top: 66,
                left: 132,
                child: _buildGraduationCap(7, 0.009, 0.045)),
            Positioned(
                top: 64, left: 162, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 69, left: 192, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 63, left: 222, child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 67,
                left: 252,
                child: _buildGraduationCap(9, 0.011, 0.055)),
            Positioned(
                top: 65,
                left: 282,
                child: _buildGraduationCap(7, 0.009, 0.045)),

            // Bottom area graduation caps
            Positioned(
                top: 95, left: 25, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 98, left: 55, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 92, left: 85, child: _buildGraduationCap(9, 0.011, 0.055)),
            Positioned(
                top: 100,
                left: 115,
                child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 96,
                left: 145,
                child: _buildGraduationCap(7, 0.009, 0.045)),
            Positioned(
                top: 94, left: 175, child: _buildGraduationCap(8, 0.01, 0.05)),
            Positioned(
                top: 99, left: 205, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 93,
                left: 235,
                child: _buildGraduationCap(9, 0.011, 0.055)),
            Positioned(
                top: 97, left: 265, child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 95,
                left: 295,
                child: _buildGraduationCap(7, 0.009, 0.045)),

            // Additional scattered graduation caps
            Positioned(
                top: 25,
                left: 300,
                child: _buildGraduationCap(4, 0.005, 0.025)),
            Positioned(
                top: 45, left: 5, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 75, left: 310, child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 105, left: 2, child: _buildGraduationCap(7, 0.009, 0.045)),
            Positioned(
                top: 135,
                left: 315,
                child: _buildGraduationCap(4, 0.005, 0.025)),
            Positioned(
                top: 165, left: 8, child: _buildGraduationCap(6, 0.008, 0.04)),
            Positioned(
                top: 195,
                left: 312,
                child: _buildGraduationCap(5, 0.006, 0.03)),
            Positioned(
                top: 215,
                left: 15,
                child: _buildGraduationCap(7, 0.009, 0.045)),
            Positioned(
                top: 235,
                left: 308,
                child: _buildGraduationCap(4, 0.005, 0.025)),
            Positioned(
                top: 255, left: 22, child: _buildGraduationCap(6, 0.008, 0.04)),
          ],
          // Main content
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }

  // Clean section heading without decorative elements
  Widget _sectionHeading(String title,
      {IconData? icon, Color color = const Color(0xFF1A1A1A)}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(
            icon,
            size: 20,
            color: const Color(0xFF0A84FF),
          ),
        if (icon != null) const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // Clean minimal divider
  Widget _softDivider() {
    return Container(
      height: 1,
      width: double.infinity,
      color: const Color(0xFFF3F4F6),
    );
  }

  // Helper method to build graduation cap decorations
  Widget _buildGraduationCap(
      double size, double bgOpacity, double iconOpacity) {
    final colors = [const Color(0xFF0A84FF), const Color(0xFF007AFF)];
    final randomColor = colors[DateTime.now().millisecond % 2];

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: randomColor.withOpacity(bgOpacity),
        borderRadius: BorderRadius.circular(size / 2),
      ),
      child: Icon(
        DateTime.now().millisecond % 2 == 0
            ? Icons.school
            : Icons.school_outlined,
        color: randomColor.withOpacity(iconOpacity),
        size: size * 0.6,
      ),
    );
  }

  // Removed automatic refresh on visibility to avoid repeated requests

  // (Removed unused _refreshPlanDetails to satisfy linter)

  Future<void> _loadPlanDetails() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    setState(() {
      _isLoadingPlan = true;
    });
    try {
      final cached = await authProvider.getCachedCurrentPlanDetails();
      if (!mounted) return;
      setState(() {
        _planDetails = cached;
        _isLoadingPlan = false;
      });
    } catch (e) {
      print('ProfileScreen: Error loading plan details via provider: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingPlan = false;
      });
    }
  }

  Future<void> _refreshData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    try {
      // Get fresh student data from unified API
      final studentData = await authProvider.getFreshStudentData();

      if (studentData != null) {
        // Update plan details from the fresh data
        if (studentData['plan'] != null) {
          setState(() {
            _planDetails = studentData['plan'];
            _isLoadingPlan = false;
          });
        }

        if (mounted) {
          _showGlassSnackBar(
            context,
            message: 'تم تحديث البيانات بنجاح',
            color: const Color(0xFF22C55E),
            icon: Icons.check_circle_outline,
          );
        }
      } else {
        if (mounted) {
          _showGlassSnackBar(
            context,
            message: 'فشل في تحديث البيانات',
            color: const Color(0xFFEF4444),
            icon: Icons.error_outline,
          );
        }
      }
    } catch (e) {
      print('ProfileScreen: Error refreshing data: $e');
      if (mounted) {
        _showGlassSnackBar(
          context,
          message: 'فشل في تحديث البيانات: $e',
          color: const Color(0xFFEF4444),
          icon: Icons.error_outline,
        );
      }
    }
  }

  // Helper method to safely get boolean value
  bool _getBoolValue(dynamic value) {
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true' || value == '1';
    }
    if (value is int) return value == 1;
    return true; // default to true
  }

  DateTime? _parseExpiryDate(dynamic expiresAt) {
    if (expiresAt == null) return null;

    try {
      if (expiresAt is String) {
        return DateTime.parse(expiresAt);
      } else if (expiresAt is int) {
        // Unix timestamp in seconds
        return DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      } else {
        // Unix timestamp in milliseconds
        return DateTime.fromMillisecondsSinceEpoch(expiresAt);
      }
    } catch (e) {
      print('Error parsing expiry date: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user ?? {};

    // Debug: Print user data to see what we're getting
    print('ProfileScreen: User data: $user');
    print('ProfileScreen: Phone field: ${user['phone']}');
    print('ProfileScreen: Mobile field: ${user['mobile']}');

    final Map<String, dynamic> student = {
      'name': (user['name'] ?? user['fullName'] ?? 'غير محدد').toString(),
      'phone': (user['phone'] ?? user['mobile'] ?? 'غير محدد').toString(),
      'email': (user['email'] ?? 'غير محدد').toString(),
      'active': _getBoolValue(
          user['active'] ?? user['isActive'] ?? user['status'] == 'active'),
      'expiresAt': user['expiresAt'],
    };

    print('ProfileScreen: Processed student data: $student');

    final expiryDate = _parseExpiryDate(student['expiresAt']);

    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                ).createShader(bounds);
              },
              blendMode: BlendMode.srcIn,
              child: const Icon(Icons.arrow_back_ios, color: Colors.black),
            ),
            onPressed: () => context.pop(),
          ),
          title: const Text(
            'الملف الشخصي',
            style: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: RefreshIndicator(
              onRefresh: _refreshData,
              color: const Color(0xFF0A84FF),
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Profile Header Card with Account Info
                    _glassContainer(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Profile Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF86B6FF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.08),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ShaderMask(
                                  shaderCallback: (Rect bounds) {
                                    return const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0A84FF),
                                        Color(0xFF007AFF)
                                      ],
                                    ).createShader(bounds);
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: const Icon(Icons.person,
                                      size: 38, color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Student Name
                          Text(
                            student['name'],
                            style: const TextStyle(
                              color: Color(0xFF1A1A1A),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            height: 4,
                            width: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: student['active']
                                  ? Colors.green.withOpacity(0.2)
                                  : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: student['active']
                                    ? Colors.green
                                    : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: student['active']
                                        ? Colors.green
                                        : Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  student['active'] ? 'نشط' : 'غير نشط',
                                  style: TextStyle(
                                    color: student['active']
                                        ? Colors.green
                                        : Colors.red,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Account Information Section
                          _glassContainer(
                            padding: const EdgeInsets.all(16),
                            borderRadius: BorderRadius.circular(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _sectionHeading('معلومات الحساب',
                                    icon: Icons.info_outline),
                                const SizedBox(height: 12),
                                ProfileInfoRow(
                                  label: '',
                                  value: student['name'],
                                  icon: Icons.person_outline,
                                ),
                                const SizedBox(height: 10),
                                _softDivider(),
                                const SizedBox(height: 10),
                                ProfileInfoRow(
                                  label: '',
                                  value: student['phone'],
                                  icon: Icons.phone_outlined,
                                ),
                                const SizedBox(height: 10),
                                _softDivider(),
                                const SizedBox(height: 10),
                                ProfileInfoRow(
                                  label: '',
                                  value: student['email'],
                                  icon: Icons.email_outlined,
                                ),
                                const SizedBox(height: 10),
                                _softDivider(),
                                const SizedBox(height: 10),
                                ProfileInfoRow(
                                  label: '',
                                  value: expiryDate != null
                                      ? '${expiryDate.year}-${expiryDate.month.toString().padLeft(2, '0')}-${expiryDate.day.toString().padLeft(2, '0')}'
                                      : 'غير محدد',
                                  icon: Icons.calendar_today_outlined,
                                  valueColor: const Color(0xFFB0B0B0),
                                ),
                                const SizedBox(height: 6),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Countdown Timer with enhanced styling
                    if (expiryDate != null)
                      _glassContainer(
                        borderRadius: BorderRadius.circular(16),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Text on the right (first child in RTL)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'الوقت المتبقي على الاشتراك',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                      color: Color(0xFF1A1A1A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  CountdownTimer(
                                    expiryDate: expiryDate,
                                    onExpired: () {},
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0A84FF),
                                    Color(0xFF007AFF)
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.timer_outlined,
                                  color: Colors.white, size: 22),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    // Subscription plan card
                    _glassContainer(
                      padding: const EdgeInsets.all(20),
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icon at top-left
                          const Align(
                            alignment: Alignment.topLeft,
                            child: Icon(
                              Icons.workspace_premium,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                          const SizedBox(height: 6),
                          _sectionHeading('الخطة الحالية',
                              icon: Icons.workspace_premium),
                          const SizedBox(height: 12),
                          if (_isLoadingPlan)
                            const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF0A84FF),
                              ),
                            )
                          else if (_planDetails != null) ...[
                            Text(
                              _planDetails!['title'] ?? 'خطة غير محددة',
                              style: const TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_planDetails!['price'] ?? 0} دينار كويتي / ${_planDetails!['durationValue'] ?? 1} ${_planDetails!['durationType'] == 'day' ? 'يوم' : _planDetails!['durationType'] == 'month' ? 'شهر' : 'سنة'}',
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                            if (_planDetails!['description'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                _planDetails!['description'],
                                style: const TextStyle(
                                  color: Color(0xFF6B7280),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ] else ...[
                            const Text(
                              'خطة غير محددة',
                              style: TextStyle(
                                color: Color(0xFF1A1A1A),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'لا توجد خطة نشطة',
                              style: TextStyle(
                                color: Color(0xFF6B7280),
                                fontSize: 14,
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          // Hidden: "ترقيه الخطه" button (kept for future use)
                          // The original widget tree is preserved below as a block comment.
                          // To re-enable, replace the SizedBox with the commented Align.
                          const SizedBox.shrink(),
                          /*
                          Align(
                            alignment: Alignment.bottomLeft,
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  _showUpgradeConfirmation(context);
                                },
                                child: Container(
                                  height: 42,
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFF0A84FF), width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0A84FF).withOpacity(0.1),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      Positioned(
                                        top: 2,
                                        right: 4,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A84FF).withOpacity(0.005),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.star, color: Color(0xFF0A84FF), size: 8),
                                        ),
                                      ),
                                      Center(
                                        child: ShaderMask(
                                          shaderCallback: (bounds) => const LinearGradient(
                                            colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ).createShader(bounds),
                                          blendMode: BlendMode.srcIn,
                                          child: const Text(
                                            'ترقيه الخطه',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          */
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Edit Profile Button with enhanced styling
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF0A84FF), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A84FF).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showEditProfileDialog(context, student),
                          child: Stack(
                            children: [
                              // Decorative blue star in top-right corner
                              Positioned(
                                top: 4,
                                right: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0A84FF)
                                        .withOpacity(0.005),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.star,
                                    color: Color(0xFF0A84FF),
                                    size: 10,
                                  ),
                                ),
                              ),
                              // Main content
                              Center(
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [
                                      Color(0xFF0A84FF),
                                      Color(0xFF007AFF)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: const Text(
                                    'تعديل الملف الشخصي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Logout Button with enhanced styling
                    Container(
                      width: double.infinity,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE53E3E), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE53E3E).withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () =>
                              _showLogoutConfirmation(context, authProvider),
                          child: Stack(
                            children: [
                              // Decorative graduation cap in top-left corner
                              Positioned(
                                top: 4,
                                left: 8,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE53E3E)
                                        .withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.school_outlined,
                                    color: Color(0xFFE53E3E),
                                    size: 10,
                                  ),
                                ),
                              ),
                              // Main content
                              Center(
                                child: ShaderMask(
                                  shaderCallback: (bounds) =>
                                      const LinearGradient(
                                    colors: [
                                      Color(0xFFE53E3E),
                                      Color(0xFFC53030)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ).createShader(bounds),
                                  blendMode: BlendMode.srcIn,
                                  child: const Text(
                                    'تسجيل خروج',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditProfileDialog(
      BuildContext context, Map<String, dynamic> student) {
    final nameController = TextEditingController(
        text: student['name'] == 'غير محدد' ? '' : student['name']);
    final phoneController = TextEditingController(
        text: student['phone'] == 'غير محدد' ? '' : student['phone']);
    final emailController = TextEditingController(
        text: student['email'] == 'غير محدد' ? '' : student['email']);
    final passwordController = TextEditingController();

    final scrollController = ScrollController();

    showDialog(
      context: context,
      builder: (ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            backgroundColor: Colors.transparent,
            body: Center(
              child: Dialog(
                insetPadding: const EdgeInsets.symmetric(horizontal: 16),
                elevation: 0,
                backgroundColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).viewInsets.bottom > 0
                            ? MediaQuery.of(context).size.height *
                                0.6 // Smaller when keyboard is open
                            : MediaQuery.of(context).size.height *
                                0.8, // Normal size when keyboard is closed
                        maxWidth: MediaQuery.of(context).size.width * 0.9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0A84FF).withOpacity(0.15),
                            blurRadius: 25,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Professional Header with Blue Gradient
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(24),
                                topRight: Radius.circular(24),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      const Color(0xFF0A84FF).withOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'تعديل الملف الشخصي',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Form Content
                          Flexible(
                            child: SingleChildScrollView(
                              controller: scrollController,
                              padding: EdgeInsets.all(24).copyWith(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom > 0
                                        ? 16
                                        : 24,
                              ),
                              child: Column(
                                children: [
                                  // Name Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'الاسم',
                                      style: const TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF0A84FF)
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0A84FF)
                                              .withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: nameController,
                                      decoration: InputDecoration(
                                        hintText: 'أدخل اسمك الكامل',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.person_outline,
                                            color: Color(0xFF0A84FF),
                                            size: 20,
                                          ),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 2.5,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Phone Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'رقم الهاتف',
                                      style: const TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF0A84FF)
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0A84FF)
                                              .withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: phoneController,
                                      keyboardType: TextInputType.phone,
                                      decoration: InputDecoration(
                                        hintText: 'أدخل رقم هاتفك',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.phone_outlined,
                                            color: Color(0xFF0A84FF),
                                            size: 20,
                                          ),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 2.5,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Email Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'البريد الإلكتروني',
                                      style: const TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF0A84FF)
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0A84FF)
                                              .withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: emailController,
                                      keyboardType: TextInputType.emailAddress,
                                      decoration: InputDecoration(
                                        hintText: 'أدخل بريدك الإلكتروني',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.email_outlined,
                                            color: Color(0xFF0A84FF),
                                            size: 20,
                                          ),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 2.5,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  // Password Field
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      'كلمة المرور الجديدة (اختياري)',
                                      style: const TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: const Color(0xFF0A84FF)
                                            .withOpacity(0.3),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0A84FF)
                                              .withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: TextField(
                                      controller: passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        hintText:
                                            'أدخل كلمة مرور جديدة (اختياري)',
                                        hintStyle: const TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w400,
                                        ),
                                        prefixIcon: Container(
                                          margin: const EdgeInsets.all(8),
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.lock_outline,
                                            color: Color(0xFF0A84FF),
                                            size: 20,
                                          ),
                                        ),
                                        isDense: true,
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF0A84FF),
                                            width: 2.5,
                                          ),
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          borderSide: BorderSide(
                                            color: const Color(0xFF0A84FF)
                                                .withOpacity(0.3),
                                            width: 1.5,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 20,
                                          vertical: 18,
                                        ),
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFF1F2937),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      // Cancel Button
                                      Expanded(
                                        child: Container(
                                          height: 56,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            border: Border.all(
                                              color: const Color(0xFFE5E7EB),
                                              width: 2,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.05),
                                                blurRadius: 8,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              onTap: () =>
                                                  Navigator.of(ctx).pop(),
                                              child: const Center(
                                                child: Text(
                                                  'إلغاء',
                                                  style: TextStyle(
                                                    color: Color(0xFF6B7280),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      // Save Button
                                      Expanded(
                                        child: Consumer<AuthProvider>(
                                          builder:
                                              (context, authProvider, child) {
                                            return Container(
                                              height: 56,
                                              decoration: BoxDecoration(
                                                gradient: const LinearGradient(
                                                  colors: [
                                                    Color(0xFF0A84FF),
                                                    Color(0xFF007AFF)
                                                  ],
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        const Color(0xFF0A84FF)
                                                            .withOpacity(0.3),
                                                    blurRadius: 12,
                                                    offset: const Offset(0, 4),
                                                  ),
                                                ],
                                              ),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  onTap: authProvider.isLoading
                                                      ? null
                                                      : () async {
                                                          final newName =
                                                              nameController
                                                                  .text
                                                                  .trim();
                                                          final newPhone =
                                                              phoneController
                                                                  .text
                                                                  .trim();
                                                          final newEmail =
                                                              emailController
                                                                  .text
                                                                  .trim();
                                                          final newPassword =
                                                              passwordController
                                                                  .text
                                                                  .trim();

                                                          if (newName.isEmpty ||
                                                              newPhone
                                                                  .isEmpty ||
                                                              newEmail
                                                                  .isEmpty) {
                                                            _showGlassSnackBar(
                                                              context,
                                                              message:
                                                                  'جميع الحقول مطلوبة',
                                                              color: const Color(
                                                                  0xFFEF4444),
                                                              icon: Icons
                                                                  .error_outline,
                                                            );
                                                            return;
                                                          }

                                                          final success =
                                                              await authProvider
                                                                  .updateProfile(
                                                            name: newName,
                                                            phone: newPhone,
                                                            email: newEmail,
                                                            password: newPassword
                                                                    .isNotEmpty
                                                                ? newPassword
                                                                : null,
                                                          );

                                                          if (success) {
                                                            Navigator.of(ctx)
                                                                .pop();
                                                            _showGlassSnackBar(
                                                              context,
                                                              message:
                                                                  'تم حفظ التعديلات بنجاح',
                                                              color: const Color(
                                                                  0xFF22C55E),
                                                              icon: Icons
                                                                  .check_circle_outline,
                                                            );
                                                          } else {
                                                            _showGlassSnackBar(
                                                              context,
                                                              message: authProvider
                                                                      .error ??
                                                                  'فشل في تحديث الملف الشخصي',
                                                              color: const Color(
                                                                  0xFFEF4444),
                                                              icon: Icons
                                                                  .error_outline,
                                                            );
                                                          }
                                                        },
                                                  child: Center(
                                                    child: authProvider
                                                            .isLoading
                                                        ? const SizedBox(
                                                            width: 24,
                                                            height: 24,
                                                            child:
                                                                CircularProgressIndicator(
                                                              color:
                                                                  Colors.white,
                                                              strokeWidth: 2.5,
                                                            ),
                                                          )
                                                        : const Text(
                                                            'حفظ',
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                          ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showUpgradeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تأكيد ترقية الخطة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: const Text(
              'في حالة الدخول لهذه الصفحة سيكون الحساب معلق لحين اتمام الدفع',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push('/plan-selection');
                  },
                  child: const Text(
                    'متابعة',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(
      BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text(
              'تأكيد تسجيل الخروج',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: const Text(
              'هل أنت متأكد من أنك تريد تسجيل الخروج؟',
              style: TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'إلغاء',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53E3E), Color(0xFFC53030)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    // Close confirmation dialog first
                    Navigator.of(context).pop();

                    // Perform immediate logout without any loading dialogs
                    print(
                        'ProfileScreen: Starting immediate logout after confirmation...');

                    // Store user data before clearing for server logout
                    final userData = authProvider.user;
                    final deviceToken = authProvider.deviceToken;

                    // Clear local state immediately
                    await authProvider.quickLogout();

                    // Navigate to login immediately
                    if (context.mounted) {
                      print('ProfileScreen: Navigating to login immediately');
                      context.go('/login');
                    }

                    // Try server logout in background (don't wait for it)
                    if (userData != null && deviceToken != null) {
                      Future.microtask(() async {
                        try {
                          print(
                              'ProfileScreen: Attempting background server logout...');
                          final apiService = ApiService();
                          await apiService.logout(
                            userId: userData['id'] ?? userData['_id'],
                            deviceToken: deviceToken,
                          );
                          print(
                              'ProfileScreen: Background server logout completed');
                        } catch (e) {
                          print(
                              'ProfileScreen: Background server logout failed: $e');
                        }
                      });
                    }
                  },
                  child: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

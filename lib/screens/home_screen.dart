import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../widgets/class_card.dart';
import '../widgets/gradient_bg.dart';
import '../widgets/subscription_expired_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final TextEditingController _classIdController = TextEditingController();
  List<Map<String, dynamic>> _joinedClasses = [];
  bool _isJoiningClass = false;
  bool _joinExpanded = false;
  bool _isLoadingClasses = false;
  Map<String, dynamic>? _subscriptionData;
  bool _isLoadingSubscription = false;
  bool _hasShownExpiredDialog = false;

  @override
  void initState() {
    super.initState();
    // Observe app lifecycle to re-check subscription on resume
    WidgetsBinding.instance.addObserver(this);
    // Reset dialog flag when screen initializes
    _hasShownExpiredDialog = false;
    // Rebuild to show/ hide clear icon and enable button
    _classIdController.addListener(() {
      if (mounted) setState(() {});
    });
    // Load data with a small delay to ensure UI is rendered first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    // Load data with a small delay to prevent blocking the UI
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      _loadJoinedClasses();
      _loadSubscriptionData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Check subscription status after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSubscriptionStatus();
    });
  }

  void _checkSubscriptionStatus() {
    if (_hasShownExpiredDialog) return; // Prevent showing dialog multiple times

    final authProvider = context.read<AuthProvider>();
    final bool isActiveFromApi = _subscriptionData != null
        ? (_subscriptionData!['isActive'] == true)
        : true; // default true if unknown
    final bool isActiveFromProvider = authProvider.isSubscribed;
    final bool shouldShowExpired = !(isActiveFromApi && isActiveFromProvider);

    if (shouldShowExpired) {
      _hasShownExpiredDialog = true;
      // Show subscription expired dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Cannot be dismissed by tapping outside
        builder: (BuildContext context) {
          return const SubscriptionExpiredDialog();
        },
      );
    }
  }

  Future<void> _loadJoinedClasses() async {
    if (!mounted) return;

    print('Loading joined classes...');
    setState(() {
      _isLoadingClasses = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      print('HomeScreen: About to call getStudentClasses()');

      // Add timeout to prevent hanging
      final classes = await authProvider.getStudentClasses().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('HomeScreen: getStudentClasses timeout');
          return <Map<String, dynamic>>[];
        },
      );

      print('HomeScreen: Fetched classes from API: $classes');
      print('HomeScreen: Classes count: ${classes.length}');
      if (mounted) {
        setState(() {
          _joinedClasses = classes;
          _isLoadingClasses = false;
        });
        print('HomeScreen: Updated _joinedClasses: $_joinedClasses');
        print('HomeScreen: _joinedClasses length: ${_joinedClasses.length}');
      }
    } catch (e) {
      print('HomeScreen: Error loading classes: $e');
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
      }
    }
  }

  Future<void> _loadSubscriptionData() async {
    if (!mounted) return;

    print('Loading subscription data...');
    setState(() {
      _isLoadingSubscription = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      print('HomeScreen: About to call getFreshStudentData()');

      // Add timeout to prevent hanging
      final studentData = await authProvider.getFreshStudentData().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          print('HomeScreen: getFreshStudentData timeout');
          return null;
        },
      );

      print('HomeScreen: Fetched student data from API: $studentData');

      if (mounted && studentData != null) {
        // Extract subscription data from the unified response
        // Derive isActive robustly even if backend omits fields
        final statusStr = studentData['status']?.toString().toLowerCase();
        final expiresAt = studentData['expiresAt'];
        bool isActive = false;
        if (statusStr != null) {
          isActive = statusStr == 'active';
          if (statusStr == 'pending' ||
              statusStr == 'expired' ||
              statusStr == 'inactive' ||
              statusStr == 'disabled' ||
              statusStr == 'invalid') {
            isActive = false;
          }
        }
        if (!isActive && expiresAt != null) {
          // Use expiration date as fallback
          try {
            DateTime date;
            if (expiresAt is String) {
              date = DateTime.parse(expiresAt);
            } else if (expiresAt is int) {
              date = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
            } else {
              date = DateTime.fromMillisecondsSinceEpoch(expiresAt);
            }
            isActive = date.isAfter(DateTime.now());
          } catch (_) {}
        }

        final subscriptionData = {
          'isActive': isActive,
          'formattedDate': _formatDate(expiresAt),
          'plan': studentData['plan']?['title'] ?? '',
          'status': studentData['status'],
          'expiresAt': expiresAt,
        };

        setState(() {
          _subscriptionData = subscriptionData;
          _isLoadingSubscription = false;
        });
        print('HomeScreen: Updated _subscriptionData: $_subscriptionData');

        // Check subscription status after loading data
        _checkSubscriptionStatus();
      } else {
        // Fallback: try the subscription-status endpoint
        try {
          final sub = await context
              .read<AuthProvider>()
              .getUserSubscriptionStatus()
              .timeout(const Duration(seconds: 10), onTimeout: () {
            print('HomeScreen: getUserSubscriptionStatus timeout');
            return {
              'isActive': true,
              'formattedDate': 'غير محدد',
              'plan': '',
              'status': 'unknown',
            };
          });

          if (!mounted) return;
          setState(() {
            _subscriptionData = sub;
            _isLoadingSubscription = false;
          });
          _checkSubscriptionStatus();
        } catch (e) {
          if (mounted) {
            setState(() {
              _isLoadingSubscription = false;
            });
          }
        }
      }
    } catch (e) {
      print('HomeScreen: Error loading subscription data: $e');
      if (mounted) {
        setState(() {
          _isLoadingSubscription = false;
        });
      }
    }
  }

  String _formatDate(dynamic expiresAt) {
    if (expiresAt == null) return 'غير محدد';

    try {
      DateTime date;
      if (expiresAt is String) {
        date = DateTime.parse(expiresAt);
      } else if (expiresAt is int) {
        date = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      } else {
        date = DateTime.fromMillisecondsSinceEpoch(expiresAt);
      }
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'غير محدد';
    }
  }

  Future<void> _refreshData() async {
    try {
      // Refresh both classes and subscription data
      await Future.wait([
        _loadJoinedClasses(),
        _loadSubscriptionData(),
      ]);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث البيانات بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('HomeScreen: Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في تحديث البيانات: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _classIdController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset dialog flag so we can show it again if status changed while app was closed
      _hasShownExpiredDialog = false;
      // Refresh user data and show expiry dialog if needed
      _loadSubscriptionData();
    }
    super.didChangeAppLifecycleState(state);
  }

  // Helper method to get subscription status
  bool _getSubscriptionStatus(AuthProvider authProvider) {
    // Prefer latest API-derived subscription data when available
    if (_subscriptionData != null) {
      return _subscriptionData!['isActive'] == true;
    }
    return authProvider.isSubscribed;
  }

  // Helper method to get renewal date
  String _getRenewalDate(AuthProvider authProvider) {
    if (_subscriptionData != null &&
        (_subscriptionData!['formattedDate']?.toString().isNotEmpty ?? false)) {
      return _subscriptionData!['formattedDate'].toString();
    }
    return authProvider.renewalDate;
  }

  Future<void> _handleJoinClass() async {
    final id = _classIdController.text.trim();
    if (id.isEmpty) return;

    setState(() {
      _isJoiningClass = true;
    });

    try {
      final authProvider = context.read<AuthProvider>();
      final result = await authProvider.joinClassById(id);
      if (!mounted) return;

      if (result != null && result['success'] == true) {
        print('Join class successful, refreshing classes list...');

        setState(() {
          _isJoiningClass = false;
        });

        // Small delay to ensure backend has processed the join
        await Future.delayed(const Duration(milliseconds: 500));

        // Refresh the classes list from backend
        await _loadJoinedClasses();

        print(
            'Classes list refreshed, current count: ${_joinedClasses.length}');

        // If no classes were loaded from backend, add the joined class locally as fallback
        if (_joinedClasses.isEmpty) {
          print(
              'No classes from backend, adding joined class locally as fallback');
          final joined = result['class'];
          final classId = (joined is Map<String, dynamic>)
              ? (joined['id']?.toString() ?? joined['_id']?.toString() ?? id)
              : id;
          final className = (joined is Map<String, dynamic>)
              ? (joined['name']?.toString() ??
                  joined['title']?.toString() ??
                  'كلاس')
              : 'كلاس';

          setState(() {
            _joinedClasses.add({
              'id': classId,
              'name': className,
            });
          });
          print('Added fallback class: $className with ID: $classId');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
            ),
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF0A84FF)),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'تم الانضمام إلى الكلاس بنجاح',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
        _classIdController.clear();
      } else {
        setState(() {
          _isJoiningClass = false;
        });
        final error = authProvider.error ?? 'فشل في الانضمام إلى الكلاس';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
            ),
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isJoiningClass = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
          ),
          content: Row(
            children: const [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'حدث خطأ غير متوقع',
                  style: TextStyle(
                      color: Colors.black, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;

        // Show loading screen if user data is not available yet
        if (user == null) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: Color(0xFF0A84FF),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'جاري تحميل البيانات...',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.light,
            systemNavigationBarColor: Colors.white,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Colors.transparent,
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              toolbarHeight: 0,
              systemOverlayStyle: const SystemUiOverlayStyle(
                statusBarColor: Colors.transparent,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              ),
            ),
            body: Stack(
              children: [
                const GradientDecoratedBackground(child: SizedBox.expand()),
                SafeArea(
                  child: RefreshIndicator(
                    onRefresh: _refreshData,
                    color: const Color(0xFF0A84FF),
                    backgroundColor: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                      child: Directionality(
                        textDirection: TextDirection.rtl,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Student card with logout
                              _isLoadingSubscription
                                  ? Container(
                                      height: 130,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.10),
                                            blurRadius: 18,
                                            spreadRadius: 1,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF0A84FF),
                                        ),
                                      ),
                                    )
                                  : _buildStudentCardWithLogout(
                                      studentName: user['name'] ?? 'الطالب',
                                      isSubscribed:
                                          _getSubscriptionStatus(authProvider),
                                      renewalDate:
                                          _getRenewalDate(authProvider),
                                      onProfileTap: () {
                                        // Immediate navigation with no delay
                                        context.push('/profile');
                                      },
                                      onLogoutTap: () =>
                                          _showLogoutConfirmation(
                                              context, authProvider),
                                    ),
                              const SizedBox(height: 24),
                              // Collapsible Join control
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 280),
                                switchInCurve: Curves.easeOutCubic,
                                switchOutCurve: Curves.easeInCubic,
                                transitionBuilder: (child, anim) {
                                  final slide = Tween<Offset>(
                                    begin: const Offset(0, 0.15),
                                    end: Offset.zero,
                                  ).animate(anim);
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                        position: slide, child: child),
                                  );
                                },
                                child: !_joinExpanded
                                    ? Container(
                                        key: const ValueKey('join_collapsed'),
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
                                              color: const Color(0xFF0A84FF)
                                                  .withOpacity(0.25),
                                              blurRadius: 12,
                                              offset: const Offset(0, 6),
                                            ),
                                          ],
                                        ),
                                        child: Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: () => setState(
                                                () => _joinExpanded = true),
                                            borderRadius:
                                                BorderRadius.circular(16),
                                            child: Container(
                                              height: 64,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 20),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width: 36,
                                                    height: 36,
                                                    decoration: BoxDecoration(
                                                      color: Colors.white
                                                          .withOpacity(0.2),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                    ),
                                                    child: const Icon(
                                                      Icons.group_add_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  const Text(
                                                    'انضمام إلى كلاس',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  const Icon(
                                                    Icons
                                                        .arrow_forward_ios_rounded,
                                                    color: Colors.white,
                                                    size: 16,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : Container(
                                        key: const ValueKey('join_expanded'),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFF0F7FF),
                                              Colors.white
                                            ],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                            color:
                                                Colors.black.withOpacity(0.05),
                                            width: 1,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withOpacity(0.08),
                                              blurRadius: 20,
                                              offset: const Offset(0, 8),
                                            ),
                                          ],
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(14),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    width: 34,
                                                    height: 34,
                                                    decoration: BoxDecoration(
                                                      gradient:
                                                          const LinearGradient(
                                                        colors: [
                                                          Color(0xFF0A84FF),
                                                          Color(0xFF007AFF)
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end: Alignment
                                                            .bottomRight,
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: const Color(
                                                                  0xFF0A84FF)
                                                              .withOpacity(
                                                                  0.25),
                                                          blurRadius: 10,
                                                          offset: const Offset(
                                                              0, 4),
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Icon(
                                                        Icons.group_add_rounded,
                                                        color: Colors.white,
                                                        size: 20),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  const Text(
                                                    'انضمام إلى كلاس',
                                                    style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  const Spacer(),
                                                  IconButton(
                                                    onPressed: () => setState(
                                                        () => _joinExpanded =
                                                            false),
                                                    icon: const Icon(
                                                        Icons.close_rounded,
                                                        color:
                                                            Color(0xFF6B7280)),
                                                    tooltip: 'إغلاق',
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: SizedBox(
                                                      height: 54,
                                                      child: TextField(
                                                        controller:
                                                            _classIdController,
                                                        textAlignVertical:
                                                            TextAlignVertical
                                                                .center,
                                                        style: const TextStyle(
                                                          fontSize:
                                                              13, // Smaller font
                                                        ),
                                                        decoration:
                                                            InputDecoration(
                                                          filled: true,
                                                          fillColor:
                                                              const Color(
                                                                  0xFFF8FAFF),
                                                          hintText:
                                                              'أدخل رقم الكلاس',
                                                          hintStyle:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF9CA3AF),
                                                            fontSize:
                                                                13, // Smaller hint font
                                                          ),
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      14,
                                                                  vertical: 16),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        14),
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.06),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          enabledBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        14),
                                                            borderSide:
                                                                BorderSide(
                                                              color: Colors
                                                                  .black
                                                                  .withOpacity(
                                                                      0.06),
                                                              width: 1,
                                                            ),
                                                          ),
                                                          focusedBorder:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        14),
                                                            borderSide:
                                                                const BorderSide(
                                                              color: Color(
                                                                  0xFF0A84FF),
                                                              width: 1.5,
                                                            ),
                                                          ),
                                                          prefixIcon: const Icon(
                                                              Icons.class_,
                                                              color: Color(
                                                                  0xFF0A84FF)),
                                                          suffixIcon: Container(
                                                            width:
                                                                40, // Further reduced width
                                                            constraints:
                                                                const BoxConstraints(
                                                              maxWidth: 40,
                                                            ),
                                                            child: Row(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .end,
                                                              mainAxisSize:
                                                                  MainAxisSize
                                                                      .min,
                                                              children: [
                                                                if (_classIdController
                                                                    .text
                                                                    .isNotEmpty)
                                                                  IconButton(
                                                                    tooltip:
                                                                        'مسح',
                                                                    icon: const Icon(
                                                                        Icons
                                                                            .clear_rounded,
                                                                        color: Color(
                                                                            0xFF9CA3AF),
                                                                        size:
                                                                            16),
                                                                    onPressed:
                                                                        () {
                                                                      _classIdController
                                                                          .clear();
                                                                      setState(
                                                                          () {});
                                                                    },
                                                                  ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  // Icon button instead of text button
                                                  Container(
                                                    height: 54,
                                                    width: 54,
                                                    decoration: BoxDecoration(
                                                      gradient: _classIdController
                                                              .text
                                                              .trim()
                                                              .isEmpty
                                                          ? LinearGradient(
                                                              colors: [
                                                                Colors
                                                                    .grey[300]!,
                                                                Colors
                                                                    .grey[400]!
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            )
                                                          : const LinearGradient(
                                                              colors: [
                                                                Color(
                                                                    0xFF0A84FF),
                                                                Color(
                                                                    0xFF007AFF)
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              14),
                                                      boxShadow:
                                                          _classIdController
                                                                  .text
                                                                  .trim()
                                                                  .isEmpty
                                                              ? null
                                                              : [
                                                                  BoxShadow(
                                                                    color: const Color(
                                                                            0xFF0A84FF)
                                                                        .withOpacity(
                                                                            0.25),
                                                                    blurRadius:
                                                                        8,
                                                                    offset:
                                                                        const Offset(
                                                                            0,
                                                                            4),
                                                                  ),
                                                                ],
                                                    ),
                                                    child: Material(
                                                      color: Colors.transparent,
                                                      child: InkWell(
                                                        onTap: _classIdController
                                                                .text
                                                                .trim()
                                                                .isEmpty
                                                            ? null
                                                            : _isJoiningClass
                                                                ? null
                                                                : _handleJoinClass,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(14),
                                                        child: Center(
                                                          child: _isJoiningClass
                                                              ? const SizedBox(
                                                                  width: 20,
                                                                  height: 20,
                                                                  child:
                                                                      CircularProgressIndicator(
                                                                    color: Colors
                                                                        .white,
                                                                    strokeWidth:
                                                                        2,
                                                                  ),
                                                                )
                                                              : const Icon(
                                                                  Icons
                                                                      .add_rounded,
                                                                  color: Colors
                                                                      .white,
                                                                  size: 24,
                                                                ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 10),
                                              Row(
                                                children: const [
                                                  Icon(
                                                      Icons
                                                          .info_outline_rounded,
                                                      size: 16,
                                                      color: Color(0xFF6B7280)),
                                                  SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'أدخل رقم الكلاس للانضمام إليه',
                                                      style: TextStyle(
                                                        color:
                                                            Color(0xFF6B7280),
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  const Text(
                                    'الكلاسات المنضَمّة',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    onPressed: () {
                                      _loadJoinedClasses();
                                      _loadSubscriptionData();
                                    },
                                    icon: const Icon(Icons.refresh,
                                        color: Color(0xFF0A84FF)),
                                    tooltip: 'تحديث القائمة',
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _isLoadingClasses
                                  ? const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF0A84FF),
                                      ),
                                    )
                                  : RefreshIndicator(
                                      onRefresh: () async {
                                        await _loadJoinedClasses();
                                        await _loadSubscriptionData();
                                      },
                                      color: const Color(0xFF0A84FF),
                                      child: ListView.separated(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        itemCount: _joinedClasses.length,
                                        separatorBuilder: (_, __) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, index) {
                                          final klass = _joinedClasses[index];
                                          print(
                                              'HomeScreen: Building ClassCard for ${klass['name']} with status: ${klass['status']}');
                                          return ClassCard(
                                            className:
                                                klass['name']?.toString() ??
                                                    'كلاس',
                                            status:
                                                klass['status']?.toString() ??
                                                    'active',
                                            onTap: () {
                                              // Immediate navigation with no delay
                                              context.push(
                                                '/classroom',
                                                extra: {
                                                  'id':
                                                      klass['id']?.toString() ??
                                                          '',
                                                  'name': klass['name']
                                                          ?.toString() ??
                                                      'كلاس',
                                                },
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    ),
                              // Empty state for joined classes
                              if (!_isLoadingClasses && _joinedClasses.isEmpty)
                                Container(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 40),
                                  padding: const EdgeInsets.all(24),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.6),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: Colors.black.withOpacity(0.08),
                                      width: 1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.school_outlined,
                                        color: Colors.grey[400],
                                        size: 48,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'لم تنضم إلى أي كلاس بعد',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'استخدم زر "انضمام إلى كلاس" لإضافة كلاس جديد',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStudentCardWithLogout({
    required String studentName,
    required bool isSubscribed,
    required String renewalDate,
    required VoidCallback onProfileTap,
    required VoidCallback onLogoutTap,
  }) {
    return Container(
      height: 130, // Fixed height to prevent overlapping
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.10),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Decorative ring
            Positioned(
              top: -30,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0A84FF).withOpacity(0.15),
                    width: 2,
                  ),
                ),
              ),
            ),
            // Status badge
            Positioned(
              bottom: 20,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: (isSubscribed ? Colors.green : Colors.red)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isSubscribed ? Colors.green : Colors.red)
                        .withOpacity(0.6),
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
                        color: isSubscribed ? Colors.green : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isSubscribed ? 'نشط' : 'غير مفعل',
                      style: TextStyle(
                        color:
                            isSubscribed ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Logout button
            Positioned(
              top: 16,
              left: 16,
              child: InkWell(
                onTap: onLogoutTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0A84FF).withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            // Clickable left half for profile
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              right: 0,
              child: Row(
                children: [
                  Expanded(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onProfileTap,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        splashColor: const Color(0xFF0A84FF).withOpacity(0.1),
                        highlightColor:
                            const Color(0xFF0A84FF).withOpacity(0.05),
                        child: Container(
                          height: double.infinity,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Right half (non-clickable)
                  Expanded(
                    child: Container(
                      height: double.infinity,
                    ),
                  ),
                ],
              ),
            ),
            // User name at top right
            Positioned(
              top: 20,
              right: 16,
              child: Text(
                studentName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF0A84FF),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            // Renewal date at bottom
            Positioned(
              bottom: 20,
              right: 16,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today,
                      size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    'تجديد: $renewalDate',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
                    colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextButton(
                  onPressed: () async {
                    // Close confirmation dialog first
                    Navigator.of(context).pop();

                    // Show loading dialog
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      builder: (BuildContext context) {
                        return Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: const Color(0xFF1C1C1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const CircularProgressIndicator(
                                  color: Color(0xFF0A84FF),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'جاري تسجيل الخروج...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'يرجى الانتظار',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );

                    // Perform logout process with immediate execution
                    print('HomeScreen: Starting immediate logout...');

                    // Store user data before clearing for server logout
                    final userData = authProvider.user;
                    final deviceToken = authProvider.deviceToken;

                    // Clear local state immediately
                    await authProvider.quickLogout();

                    // Close loading dialog immediately
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }

                    // Navigate to login immediately
                    if (context.mounted) {
                      print('HomeScreen: Navigating to login immediately');
                      context.go('/login');
                    }

                    // Try server logout in background (don't wait for it)
                    if (userData != null && deviceToken != null) {
                      Future.microtask(() async {
                        try {
                          print(
                              'HomeScreen: Attempting background server logout...');
                          final apiService = ApiService();
                          await apiService.logout(
                            userId: userData['id'] ?? userData['_id'],
                            deviceToken: deviceToken,
                          );
                          print(
                              'HomeScreen: Background server logout completed');
                        } catch (e) {
                          print(
                              'HomeScreen: Background server logout failed: $e');
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

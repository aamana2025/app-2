import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isAuthenticated = false;
  Map<String, dynamic>? _user;
  String? _token;
  String? _error;
  String? _pendingId;
  String? _deviceToken;
  // In-memory cache for current plan details (lives for app session only)
  Map<String, dynamic>? _cachedPlanDetails;
  bool _hasFetchedPlanDetailsThisSession = false;

  // Getters
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;
  Map<String, dynamic>? get user => _user;
  String? get token => _token;
  String? get error => _error;
  String? get pendingId => _pendingId;
  String? get deviceToken => _deviceToken;

  // Generate unique device token
  Future<String> _generateDeviceToken() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String deviceId = '';

      try {
        final androidInfo = await deviceInfo.androidInfo;
        deviceId = '${androidInfo.model}_${androidInfo.id}';
      } catch (e) {
        try {
          final iosInfo = await deviceInfo.iosInfo;
          deviceId = '${iosInfo.model}_${iosInfo.identifierForVendor}';
        } catch (e) {
          deviceId = 'unknown_device_${DateTime.now().millisecondsSinceEpoch}';
        }
      }

      // Create a unique token combining device info and timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final deviceToken = '${deviceId}_$timestamp';

      print('AuthProvider: Generated device token: $deviceToken');
      return deviceToken;
    } catch (e) {
      print('AuthProvider: Error generating device token: $e');
      // Fallback to timestamp-based token
      return 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  // Login
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Generate device token
      _deviceToken = await _generateDeviceToken();

      final response = await _apiService.login(
        email: email,
        password: password,
        deviceToken: _deviceToken,
      );

      // Accept login when backend returns user even if status is pending/expired
      if (response['user'] != null) {
        _token = response['accessToken'];
        _user = response['user'];
        _isAuthenticated = true;

        // Make token available for all API calls by default
        _apiService.setAccessToken(_token);
        print(
            'AuthProvider: Access token set for API service: ${_token?.substring(0, 20)}...');

        // Save login data to secure storage
        await _saveLoginData();

        _setLoading(false);
        print(
            'AuthProvider: Login successful (any status), token: ${_token?.substring(0, 10)}...');
        return true;
      } else {
        // Check for device conflict
        if (response['code'] == 'DEVICE_CONFLICT') {
          _setError('DEVICE_CONFLICT');
          _setLoading(false);
          return false;
        }

        // Login failed - extract error message
        String errorMessage =
            response['message'] ?? response['error'] ?? 'فشل في تسجيل الدخول';
        print('AuthProvider: Login failed - $errorMessage');

        final lower = errorMessage.toLowerCase();
        final isDeviceConflict = lower.contains('device') ||
            lower.contains('conflict') ||
            lower.contains('مسجل في جهاز') ||
            lower.contains('مسجل على جهاز') ||
            lower.contains('على جهاز آخر') ||
            lower.contains('على جهاز اخر') ||
            lower.contains('logged in on another device') ||
            lower.contains('already logged in') ||
            lower.contains('session exists');

        if (isDeviceConflict) {
          _setError('DEVICE_CONFLICT');
        } else if (lower.contains('invalid') ||
            lower.contains('wrong') ||
            lower.contains('incorrect') ||
            lower.contains('not found') ||
            lower.contains('غير صحيحه') ||
            lower.contains('غير صحيحة') ||
            lower.contains('المستخدم غير موجود')) {
          _setError('البيانات غير صحيحه');
        } else {
          _setError(errorMessage);
        }

        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Debug: Print the exception to see what's happening
      print('AuthProvider: Login exception: $e');

      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }

      print('AuthProvider: Processed error message: "$errorMessage"');

      // Check if this might be a device conflict error
      final lower = errorMessage.toLowerCase();
      if (lower.contains('device') ||
          lower.contains('conflict') ||
          lower.contains('مسجل في جهاز') ||
          lower.contains('مسجل على جهاز') ||
          lower.contains('على جهاز آخر') ||
          lower.contains('على جهاز اخر') ||
          lower.contains('logged in on another device') ||
          lower.contains('already active on another device') ||
          lower.contains('already logged in') ||
          lower.contains('session exists')) {
        print('AuthProvider: Detected device conflict in exception');
        _setError('DEVICE_CONFLICT');
      } else if (lower.contains('invalid') ||
          lower.contains('wrong') ||
          lower.contains('incorrect') ||
          lower.contains('not found') ||
          lower.contains('غير صحيحه') ||
          lower.contains('غير صحيحة') ||
          lower.contains('المستخدم غير موجود')) {
        _setError('البيانات غير صحيحه');
      } else {
        print('AuthProvider: Setting regular error: $errorMessage');
        _setError(errorMessage);
      }
      _setLoading(false);
      return false;
    }
  }

  // Get student's joined classes
  Future<List<Map<String, dynamic>>> getStudentClasses() async {
    if (_user == null) {
      print('AuthProvider: User is null, cannot fetch classes');
      _setError('يرجى تسجيل الدخول أولاً');
      return [];
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      print('AuthProvider: User data: $_user');
      print('AuthProvider: Extracted user ID: $rawUserId');
      print('AuthProvider: Token: ${_token?.substring(0, 10)}...');

      if (rawUserId == null) {
        print('AuthProvider: No user ID found in user data');
        _setError('معرف الطالب غير متوفر');
        return [];
      }

      print(
          'AuthProvider: Calling API to fetch classes for student: $rawUserId');
      final classes = await _apiService.getStudentClasses(
        studentId: rawUserId.toString(),
        accessToken: _token,
      );
      print('AuthProvider: Received classes: $classes');
      return classes;
    } catch (e) {
      print('AuthProvider: Error fetching classes: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      return [];
    }
  }

  // Get user subscription status and renewal date
  Future<Map<String, dynamic>> getUserSubscriptionStatus() async {
    if (_user == null) {
      print('AuthProvider: User is null, cannot fetch subscription status');
      _setError('يرجى تسجيل الدخول أولاً');
      return {
        'isActive': false,
        'formattedDate': 'غير محدد',
        'plan': '',
        'status': 'inactive',
      };
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      print('AuthProvider: Fetching subscription status for user: $rawUserId');

      if (rawUserId == null) {
        print('AuthProvider: No user ID found in user data');
        _setError('معرف الطالب غير متوفر');
        return {
          'isActive': false,
          'formattedDate': 'غير محدد',
          'plan': '',
          'status': 'inactive',
        };
      }

      final subscriptionData = await _apiService.getUserSubscriptionStatus(
        userId: rawUserId.toString(),
        accessToken: _token,
      );

      print('AuthProvider: Received subscription data: $subscriptionData');
      return subscriptionData;
    } catch (e) {
      print('AuthProvider: Error fetching subscription status: $e');
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      return {
        'isActive': false,
        'formattedDate': 'غير محدد',
        'plan': '',
        'status': 'inactive',
      };
    }
  }

  // Verify that access token is properly set in API service
  bool verifyAccessToken() {
    final hasToken = _apiService.hasAccessToken();
    final currentToken = _apiService.getCurrentAccessToken();
    print(
        'AuthProvider: Token verification - hasToken: $hasToken, currentToken: ${currentToken?.substring(0, 20) ?? 'null'}...');
    return hasToken;
  }

  // Test API call with current token (for debugging)
  Future<Map<String, dynamic>> testApiWithToken() async {
    print('AuthProvider: Testing API call with current token...');
    return await _apiService.testApiWithToken();
  }

  // Force refresh the token in API service
  void forceRefreshToken() {
    if (_token != null) {
      _apiService.setAccessToken(_token);
      print(
          'AuthProvider: Token force refreshed in API service: ${_token?.substring(0, 20)}...');
    } else {
      print('AuthProvider: No token to refresh');
    }
  }

  // Test a real API call to verify token is working
  Future<Map<String, dynamic>> testRealApiCall() async {
    if (_user == null) {
      return {'error': 'User not logged in'};
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      if (rawUserId == null) {
        return {'error': 'User ID not found'};
      }

      print('AuthProvider: Testing real API call with token...');
      print('AuthProvider: User ID: $rawUserId');
      print('AuthProvider: Token: ${_token?.substring(0, 20) ?? 'none'}...');
      print(
          'AuthProvider: API Service has token: ${_apiService.hasAccessToken()}');

      final classes = await getStudentClasses();

      return {
        'success': true,
        'message': 'API call successful',
        'classesCount': classes.length,
        'hasToken': verifyAccessToken(),
        'tokenPreview': _token?.substring(0, 20) ?? 'none',
        'apiServiceToken':
            _apiService.getCurrentAccessToken()?.substring(0, 20) ?? 'none',
      };
    } catch (e) {
      print('AuthProvider: Test API call failed: $e');
      return {
        'error': e.toString(),
        'hasToken': verifyAccessToken(),
        'tokenPreview': _token?.substring(0, 20) ?? 'none',
        'apiServiceToken':
            _apiService.getCurrentAccessToken()?.substring(0, 20) ?? 'none',
      };
    }
  }

  // Get current plan details once per app session
  Future<Map<String, dynamic>?> getCachedCurrentPlanDetails() async {
    if (_user == null) {
      print('AuthProvider: User is null, cannot fetch plan details');
      return null;
    }

    final dynamic planField = _user!['plan'];
    if (planField == null || planField.toString().isEmpty) {
      print('AuthProvider: No plan assigned to user, skipping plan details');
      return null;
    }

    if (_hasFetchedPlanDetailsThisSession && _cachedPlanDetails != null) {
      print('AuthProvider: Returning cached plan details for this session');
      return _cachedPlanDetails;
    }

    try {
      final String planId = planField.toString();
      print('AuthProvider: Fetching plan details for planId: $planId');
      final Map<String, dynamic> planDetails = await _apiService.getPlanDetails(
        planId: planId,
        accessToken: _token,
      );
      _cachedPlanDetails = planDetails;
      _hasFetchedPlanDetailsThisSession = true;
      return _cachedPlanDetails;
    } catch (e) {
      print('AuthProvider: Error fetching plan details: $e');
      return null;
    }
  }

  // Refresh user data from server using unified API
  Future<bool> refreshUserData() async {
    if (_user == null || _token == null) {
      print('AuthProvider: No user or token available for refresh');
      return false;
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      if (rawUserId == null) {
        print('AuthProvider: No user ID found for refresh');
        return false;
      }

      print('AuthProvider: Refreshing user data for user: $rawUserId');

      // Fetch updated user data from unified API
      final studentData = await _apiService.getStudentData(
        studentId: rawUserId.toString(),
        accessToken: _token,
      );

      if (studentData != null) {
        // Check if user status is pending
        final status = studentData['status']?.toString().toLowerCase();

        if (status == 'pending') {
          print('AuthProvider: User status is pending');
          // User is pending approval - keep existing data but update status
          _user = {
            ...?_user,
            'status': 'pending',
          };

          // Save updated data to storage
          await _saveLoginData();

          // Clear plan details cache
          _cachedPlanDetails = null;
          _hasFetchedPlanDetailsThisSession = false;

          notifyListeners();
          return true; // Return true to allow app to continue, but user will see pending popup
        }

        // Update local user data with the new structure
        _user = {
          'id': studentData['id'] ?? _user!['id'] ?? _user!['_id'],
          'name': studentData['name'] ?? _user!['name'],
          'email': studentData['email'] ?? _user!['email'],
          'phone': studentData['phone'] ?? _user!['phone'],
          'status': studentData['status'] ?? _user!['status'],
          'expiresAt': studentData['expiresAt'] ?? _user!['expiresAt'],
          'plan': studentData['plan']?['id'] ??
              _user!['plan'], // Store plan ID for compatibility
          'createdAt': studentData['createdAt'] ?? _user!['createdAt'],
        };

        // Save updated data to storage
        await _saveLoginData();

        // Clear plan details cache to force refresh
        _cachedPlanDetails = null;
        _hasFetchedPlanDetailsThisSession = false;

        notifyListeners();
        print('AuthProvider: User data refreshed successfully');
        return true;
      } else {
        print('AuthProvider: Failed to get updated user data');
        return false;
      }
    } catch (e) {
      print('AuthProvider: Error refreshing user data: $e');
      return false;
    }
  }

  // Force refresh user data after plan upgrade
  Future<void> refreshUserDataAfterUpgrade() async {
    print('AuthProvider: Refreshing user data after plan upgrade...');
    await getFreshStudentData();
  }

  // Get fresh student data (for home screen and profile screen)
  Future<Map<String, dynamic>?> getFreshStudentData() async {
    if (_user == null || _token == null) {
      print('AuthProvider: No user or token available');
      return null;
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      if (rawUserId == null) {
        print('AuthProvider: No user ID found');
        return null;
      }

      print('AuthProvider: Fetching fresh student data for user: $rawUserId');
      print('AuthProvider: Token: ${_token?.substring(0, 20) ?? 'none'}...');
      print(
          'AuthProvider: API Service has token: ${_apiService.hasAccessToken()}');
      print(
          'AuthProvider: API Service token: ${_apiService.getCurrentAccessToken()?.substring(0, 20) ?? 'none'}...');

      // Force refresh token in API service to ensure it's set
      forceRefreshToken();

      // Fetch fresh data from unified API
      final studentData = await _apiService.getStudentData(
        studentId: rawUserId.toString(),
        accessToken: _token,
      );

      if (studentData != null) {
        // Check if user status is pending
        final status = studentData['status']?.toString().toLowerCase();

        if (status == 'pending') {
          print('AuthProvider: User status is pending (fresh data)');
          // For pending status, keep existing user ID and update only status
          _user = {
            ...?_user,
            'status': 'pending',
          };
        } else {
          // Update local user data
          _user = {
            'id': studentData['id'] ?? _user!['id'] ?? _user!['_id'],
            'name': studentData['name'] ?? _user!['name'],
            'email': studentData['email'] ?? _user!['email'],
            'phone': studentData['phone'] ?? _user!['phone'],
            'status': studentData['status'] ?? _user!['status'],
            'expiresAt': studentData['expiresAt'] ?? _user!['expiresAt'],
            'plan': studentData['plan']?['id'] ?? _user!['plan'],
            'createdAt': studentData['createdAt'] ?? _user!['createdAt'],
          };
        }

        // Save updated data to storage
        await _saveLoginData();

        // Clear cached plan details to force refresh
        _cachedPlanDetails = null;
        _hasFetchedPlanDetailsThisSession = false;

        notifyListeners();
        print('AuthProvider: Fresh student data fetched successfully');
        return studentData;
      } else {
        print('AuthProvider: Failed to get fresh student data');
        return null;
      }
    } catch (e) {
      print('AuthProvider: Error fetching fresh student data: $e');
      return null;
    }
  }

  // Get subscription status from user data (fallback)
  bool get isSubscribed {
    if (_user == null) {
      print(
          'AuthProvider: User is null, returning false for subscription status');
      return false;
    }

    // Check if user has subscription data
    final status = _user!['status'];
    final expiresAt = _user!['expiresAt'];
    final plan = _user!['plan'];

    // Check for active status
    final statusLower = status?.toString().toLowerCase();

    if (statusLower == 'active') {
      return true;
    }

    // Check for pending/inactive status (including "pending" which shows subscription expired popup)
    if (statusLower == 'pending' ||
        statusLower == 'inactive' ||
        statusLower == 'expired' ||
        statusLower == 'disabled' ||
        statusLower == 'invalid') {
      return false;
    }

    // If we have an expiration date, check if it's in the future
    if (expiresAt != null) {
      try {
        DateTime expirationDate;
        if (expiresAt is String) {
          expirationDate = DateTime.parse(expiresAt);
        } else if (expiresAt is int) {
          // Unix timestamp in seconds
          expirationDate =
              DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
        } else {
          // Unix timestamp in milliseconds
          expirationDate = DateTime.fromMillisecondsSinceEpoch(expiresAt);
        }

        final now = DateTime.now();
        final isActive = expirationDate.isAfter(now);

        print('AuthProvider: Expiration date: $expirationDate');
        print('AuthProvider: Current date: $now');
        print('AuthProvider: Is expiration in future: $isActive');

        return isActive;
      } catch (e) {
        print('AuthProvider: Error parsing expiration date: $e');
        return false;
      }
    }

    // If no status or expiration date, check if user has a plan
    if (plan != null && plan.toString().isNotEmpty) {
      print('AuthProvider: User has plan: $plan, assuming active');
      return true;
    }

    print('AuthProvider: No clear subscription indication, returning false');
    // Default to false if no clear indication
    return false;
  }

  // Get renewal date from user data (fallback)
  String get renewalDate {
    if (_user == null) return 'غير محدد';

    final expiresAt = _user!['expiresAt'];
    if (expiresAt == null) return 'غير محدد';

    try {
      DateTime expirationDate;
      if (expiresAt is String) {
        expirationDate = DateTime.parse(expiresAt);
      } else if (expiresAt is int) {
        // Unix timestamp in seconds
        expirationDate = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
      } else {
        // Unix timestamp in milliseconds
        expirationDate = DateTime.fromMillisecondsSinceEpoch(expiresAt);
      }
      return '${expirationDate.year}-${expirationDate.month.toString().padLeft(2, '0')}-${expirationDate.day.toString().padLeft(2, '0')}';
    } catch (e) {
      print('AuthProvider: Error formatting expiration date: $e');
      return 'غير محدد';
    }
  }

  // Join class by id/code
  Future<Map<String, dynamic>?> joinClassById(String classId) async {
    if (_user == null) {
      _setError('يرجى تسجيل الدخول أولاً');
      return null;
    }

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      if (rawUserId == null) {
        _setError('معرف الطالب غير متوفر');
        return null;
      }
      final response = await _apiService.joinClass(
        classId: classId,
        studentId: rawUserId.toString(),
        accessToken: _token,
      );
      return response;
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      return null;
    }
  }

  // Legacy signup method (for backward compatibility)
  Future<bool> signup({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // Use the new pending user flow (with default plan)
      final response = await _apiService.createPendingUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
        planId: '68c480b976422a6a54f3fa72', // Default plan ID
      );

      if (response['pendingId'] != null) {
        _pendingId = response['pendingId'];
        await _secureStorage.write(key: 'pendingId', value: _pendingId!);
        _setLoading(false);
        return true;
      } else {
        String errorMsg = response['message'] ??
            response['error'] ??
            response['msg'] ??
            'فشل في إنشاء الحساب المؤقت';
        _setError(errorMsg);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Create pending user (new signup flow)
  Future<bool> createPendingUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String planId,
    bool manageLoading =
        true, // New parameter to control loading state management
  }) async {
    if (manageLoading) {
      _setLoading(true);
    }
    _clearError();

    try {
      print('AuthProvider: Creating pending user...');
      final response = await _apiService.createPendingUser(
        name: name,
        email: email,
        phone: phone,
        password: password,
        planId: planId,
      );

      print('AuthProvider: Response received: $response');
      print('AuthProvider: Response type: ${response.runtimeType}');
      print(
          'AuthProvider: Has pendingId: ${response.containsKey('pendingId')}');
      print('AuthProvider: PendingId value: ${response['pendingId']}');

      if (response['pendingId'] != null) {
        _pendingId = response['pendingId'];
        await _secureStorage.write(key: 'pendingId', value: _pendingId!);
        print('AuthProvider: Pending ID stored: $_pendingId');
        if (manageLoading) {
          _setLoading(false);
        }
        return true;
      } else {
        // If no pendingId in response, check for error message
        String errorMsg = response['message'] ??
            response['error'] ??
            response['msg'] ??
            'فشل في إنشاء الحساب المؤقت';
        print('AuthProvider: No pendingId found, error message: $errorMsg');
        print(
            'AuthProvider: Available keys in response: ${response.keys.toList()}');
        _setError(errorMsg);
        if (manageLoading) {
          _setLoading(false);
        }
        return false;
      }
    } catch (e) {
      print('AuthProvider: Exception caught - $e');
      print('AuthProvider: Exception type - ${e.runtimeType}');
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      print('AuthProvider: Final error message - $errorMessage');
      _setError(errorMessage);
      if (manageLoading) {
        _setLoading(false);
      }
      return false;
    }
  }

  // Get plans
  Future<List<Map<String, dynamic>>> getPlans() async {
    try {
      final plans = await _apiService.getPlans();
      return plans.cast<Map<String, dynamic>>();
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      return [];
    }
  }

  // Create checkout session
  Future<String?> createCheckoutSession(String planId) async {
    if (_pendingId == null) {
      _setError('معرف المستخدم المؤقت غير موجود');
      return null;
    }

    try {
      return await _apiService.createCheckoutSession(
        pendingId: _pendingId!,
        planId: planId,
      );
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      return null;
    }
  }

  // Check signup status
  Future<bool> checkSignupStatus() async {
    if (_pendingId == null) {
      _setError('معرف المستخدم المؤقت غير موجود');
      return false;
    }

    try {
      final response = await _apiService.checkSignupStatus(_pendingId!);
      if (response != null && response['activated'] == true) {
        // User is activated, clear pending ID and redirect to login
        await _secureStorage.delete(key: 'pendingId');
        _pendingId = null;
        return true;
      }
      return false;
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      return false;
    }
  }

  // Load pending ID from storage
  Future<void> loadPendingId() async {
    _pendingId = await _secureStorage.read(key: 'pendingId');
    notifyListeners();
  }

  // Request Password Reset
  Future<bool> requestPasswordReset({
    required String email,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.requestPasswordReset(email: email);

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'فشل في إرسال رمز التحقق');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Verify OTP
  Future<bool> verifyOtp({
    required String email,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.verifyOtp(
        email: email,
        otp: otp,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'رمز التحقق غير صحيح');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.resetPassword(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );

      if (response['success'] == true) {
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'فشل في تغيير كلمة المرور');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      // Extract error message from exception
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage =
            errorMessage.substring(11); // Remove 'Exception: ' prefix
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Update Profile
  Future<bool> updateProfile({
    required String name,
    required String phone,
    required String email,
    String? password,
  }) async {
    if (_user == null) {
      _setError('يرجى تسجيل الدخول أولاً');
      return false;
    }

    _setLoading(true);
    _clearError();

    try {
      final rawUserId = _user!['id'] ?? _user!['_id'] ?? _user!['userId'];
      if (rawUserId == null) {
        _setError('معرف الطالب غير متوفر');
        _setLoading(false);
        return false;
      }

      final response = await _apiService.updateUserProfile(
        studentId: rawUserId.toString(),
        name: name,
        phone: phone,
        email: email,
        password: password,
        accessToken: _token,
      );

      if (response['student'] != null) {
        // Update local user data with the response
        _user = {
          ...?_user,
          'name': response['student']['name'],
          'phone': response['student']['phone'],
          'email': response['student']['email'],
        };
        await _saveLoginData();
        _setLoading(false);
        return true;
      } else {
        _setError(response['message'] ?? 'فشل في تحديث الملف الشخصي');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Save login data to secure storage
  Future<void> _saveLoginData() async {
    if (_token != null && _user != null) {
      await _secureStorage.write(key: 'auth_token', value: _token!);
      await _secureStorage.write(key: 'user_data', value: jsonEncode(_user!));
      await _secureStorage.write(key: 'is_authenticated', value: 'true');
      if (_deviceToken != null) {
        await _secureStorage.write(key: 'device_token', value: _deviceToken!);
      }
      print('AuthProvider: Login data saved to secure storage');
    }
  }

  // Load login data from secure storage
  Future<void> loadStoredLoginData() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final userDataString = await _secureStorage.read(key: 'user_data');
      final isAuthenticatedString =
          await _secureStorage.read(key: 'is_authenticated');
      final deviceToken = await _secureStorage.read(key: 'device_token');

      if (token != null &&
          userDataString != null &&
          isAuthenticatedString == 'true') {
        _token = token;
        _user = jsonDecode(userDataString);
        _isAuthenticated = true;
        // Set default token into API service for all calls
        _apiService.setAccessToken(_token);
        print(
            'AuthProvider: Access token restored for API service: ${token.substring(0, 20)}...');
        if (deviceToken != null) {
          _deviceToken = deviceToken;
        }
        print('AuthProvider: Login data loaded from secure storage');
        print('AuthProvider: Token: ${token.substring(0, 10)}...');
        print('AuthProvider: User: ${_user?['name'] ?? 'Unknown'}');
        print(
            'AuthProvider: Device Token: ${deviceToken?.substring(0, 10) ?? 'None'}...');

        // Skip session validation to prevent blocking the UI
        // The session will be validated when needed
        print('AuthProvider: Stored session loaded successfully');

        notifyListeners();
      } else {
        print('AuthProvider: No valid stored login data found');
        _isAuthenticated = false;
        _token = null;
        _user = null;
        _deviceToken = null;
        notifyListeners();
      }
    } catch (e) {
      print('AuthProvider: Error loading stored login data: $e');
      // Clear invalid data
      await _clearStoredLoginData();
      _isAuthenticated = false;
      _token = null;
      _user = null;
      _deviceToken = null;
      notifyListeners();
    }
  }

  // Validate current session and clear if invalid
  Future<bool> validateSession() async {
    if (!_isAuthenticated || _token == null || _user == null) {
      print('AuthProvider: No active session to validate');
      return false;
    }

    try {
      // Try to fetch user classes to validate the session
      final classes = await getStudentClasses();
      print(
          'AuthProvider: Session validation successful, found ${classes.length} classes');
      return true;
    } catch (e) {
      print('AuthProvider: Session validation failed: $e');
      // Clear invalid session
      await forceClearAuthState();
      return false;
    }
  }

  // Clear stored login data
  Future<void> _clearStoredLoginData() async {
    await _secureStorage.delete(key: 'auth_token');
    await _secureStorage.delete(key: 'user_data');
    await _secureStorage.delete(key: 'is_authenticated');
    await _secureStorage.delete(key: 'device_token');
    print('AuthProvider: Stored login data cleared');
  }

  // Force clear all authentication state (for debugging or force logout)
  Future<void> forceClearAuthState() async {
    print('AuthProvider: Force clearing all authentication state...');

    // Clear stored data
    await _clearStoredLoginData();

    // Clear memory state
    _token = null;
    _user = null;
    _deviceToken = null;
    _isAuthenticated = false;
    _error = null;
    _pendingId = null;
    // Clear session cache
    _cachedPlanDetails = null;
    _hasFetchedPlanDetailsThisSession = false;

    // Notify listeners
    notifyListeners();

    print('AuthProvider: All authentication state cleared');
  }

  // Quick logout - just clear local state without server call
  Future<Map<String, dynamic>> quickLogout() async {
    print('AuthProvider: Performing quick logout (local only)...');

    try {
      // Clear loading state first
      _setLoading(false);

      // Clear all authentication state
      _token = null;
      _user = null;
      _deviceToken = null;
      _isAuthenticated = false;
      _error = null;
      _pendingId = null;
      // Clear session cache
      _cachedPlanDetails = null;
      _hasFetchedPlanDetailsThisSession = false;

      // Clear stored data
      await _clearStoredLoginData();

      // Notify listeners immediately
      notifyListeners();

      print('AuthProvider: Quick logout completed successfully');

      return {
        'success': true,
        'message': 'تم تسجيل الخروج محلياً',
        'serverLogoutSuccess': false,
      };
    } catch (e) {
      print('AuthProvider: Quick logout error: $e');

      // Even if there's an error, clear the state
      _token = null;
      _user = null;
      _deviceToken = null;
      _isAuthenticated = false;
      _error = null;
      _pendingId = null;
      _setLoading(false);
      // Clear session cache
      _cachedPlanDetails = null;
      _hasFetchedPlanDetailsThisSession = false;
      notifyListeners();

      return {
        'success': true,
        'message': 'تم تسجيل الخروج محلياً',
        'serverLogoutSuccess': false,
      };
    }
  }

  // Force login (for device conflict resolution)
  Future<bool> forceLogin({
    required String email,
    required String password,
    required String userId,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      // First, force logout from other device
      await _apiService.forceLogout(userId: userId);

      // Generate new device token
      _deviceToken = await _generateDeviceToken();

      // Try login again
      final response = await _apiService.login(
        email: email,
        password: password,
        deviceToken: _deviceToken,
      );

      if (response['accessToken'] != null && response['user'] != null) {
        _token = response['accessToken'];
        _user = response['user'];
        _isAuthenticated = true;

        // Make token available for all API calls by default
        _apiService.setAccessToken(_token);
        print(
            'AuthProvider: Access token set for API service (force login): ${_token?.substring(0, 20)}...');

        // Save login data to secure storage
        await _saveLoginData();

        _setLoading(false);
        print('AuthProvider: Force login successful');
        return true;
      } else {
        String errorMessage =
            response['message'] ?? response['error'] ?? 'فشل في تسجيل الدخول';
        _setError(errorMessage);
        _setLoading(false);
        return false;
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }
      _setError(errorMessage);
      _setLoading(false);
      return false;
    }
  }

  // Logout
  Future<Map<String, dynamic>> logout() async {
    _setLoading(true);
    _clearError();

    try {
      bool serverLogoutSuccess = false;
      String logoutMessage = 'تم تسجيل الخروج بنجاح';

      // Attempt server logout if we have user data
      if (_user != null && _deviceToken != null) {
        try {
          print('AuthProvider: Attempting server logout...');
          print('AuthProvider: User ID: ${_user!['id'] ?? _user!['_id']}');
          print(
              'AuthProvider: Device Token: ${_deviceToken!.substring(0, 10)}...');

          final logoutResult = await _apiService
              .logout(
            userId: _user!['id'] ?? _user!['_id'],
            deviceToken: _deviceToken!,
          )
              .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              print('AuthProvider: Server logout timeout after 3 seconds');
              return {
                'success': false,
                'message': 'انتهت مهلة تسجيل الخروج من الخادم',
              };
            },
          );

          print('AuthProvider: Server logout result: $logoutResult');

          if (logoutResult['success'] == true) {
            serverLogoutSuccess = true;
            logoutMessage =
                logoutResult['message'] ?? 'تم تسجيل الخروج من الخادم بنجاح';
            print('AuthProvider: Server logout successful');
          } else {
            logoutMessage =
                logoutResult['message'] ?? 'تم تسجيل الخروج محلياً فقط';
            print(
                'AuthProvider: Server logout failed: ${logoutResult['message']}');
          }
        } catch (e) {
          print('AuthProvider: Server logout error: $e');
          logoutMessage = 'تم تسجيل الخروج محلياً (خطأ في الخادم)';
        }
      } else {
        print('AuthProvider: No user data or device token, local logout only');
        print('AuthProvider: User: $_user');
        print('AuthProvider: Device Token: $_deviceToken');
        logoutMessage = 'تم تسجيل الخروج محلياً';
      }

      // Always clear local data regardless of server response
      print('AuthProvider: Clearing local data...');
      await forceClearAuthState();
      _setLoading(false);

      print(
          'AuthProvider: Authentication state cleared, notifying listeners...');

      return {
        'success': true,
        'message': logoutMessage,
        'serverLogoutSuccess': serverLogoutSuccess,
      };
    } catch (e) {
      print('AuthProvider: Logout error: $e');

      // Even if there's an error, clear local data
      await forceClearAuthState();
      _setLoading(false);

      return {
        'success': false,
        'message': 'حدث خطأ أثناء تسجيل الخروج',
        'error': e.toString(),
      };
    }
  }

  // Public method to set loading state
  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// API Service for handling all backend communication
///
/// This service automatically includes the access token in the Authorization header
/// for all API calls when a token is set via setAccessToken().
///
/// Usage:
/// 1. After successful login, call setAccessToken(token) to set the token
/// 2. All subsequent API calls will automatically include the token in headers
/// 3. Individual API methods can override the token by passing accessToken parameter
class ApiService {
  static final ApiService _instance = ApiService._internal(); 
  factory ApiService() => _instance;
  ApiService._internal(); 

  // Centralized backend base URL
  // Note: Keep this in sync across the app; other modules should reference
  // ApiService.baseUrl instead of hardcoding URLs.
  static const String baseUrl = 'https://aamana-classroom-backend.vercel.app';

  String? _accessToken; // default token to attach to all requests

  void setAccessToken(String? token) {
    _accessToken = token;
    print(
      'ApiService: Default access token updated: '
      '${token != null ? token.substring(0, token.length > 10 ? 10 : token.length) + '...' : 'null'}',
    );
  }

  // Get current access token (for debugging)
  String? getCurrentAccessToken() {
    return _accessToken;
  }

  // Verify token is set
  bool hasAccessToken() {
    return _accessToken != null && _accessToken!.isNotEmpty;
  }

  // Test API call with current token (for debugging)
  Future<Map<String, dynamic>> testApiWithToken() async {
    try {
      final uri = Uri.parse(
        '$baseUrl/api/test',
      ); // This endpoint might not exist, but we can test the headers
      final headers = _buildHeaders();

      print('ApiService: Testing API call with current token');
      print('ApiService: Headers: $headers');

      final response = await http.get(uri, headers: headers);

      return {
        'statusCode': response.statusCode,
        'hasToken': hasAccessToken(),
        'tokenPreview': _accessToken?.substring(0, 20) ?? 'none',
        'responseBody': response.body,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'hasToken': hasAccessToken(),
        'tokenPreview': _accessToken?.substring(0, 20) ?? 'none',
      };
    }
  }

  Map<String, String> _buildHeaders({String? accessToken, bool json = true}) {
    final effectiveToken = (accessToken != null && accessToken.isNotEmpty)
        ? accessToken
        : (_accessToken ?? '');

    final headers = <String, String>{
      if (json) 'Content-Type': 'application/json',
      if (effectiveToken.isNotEmpty) 'Authorization': 'Bearer $effectiveToken',
    };

    // Log the headers for debugging (without exposing the full token)
    if (effectiveToken.isNotEmpty) {
      print(
        'ApiService: Building headers with token: ${effectiveToken.substring(0, 20)}...',
      );
    } else {
      print('ApiService: Building headers without token');
    }

    return headers;
  }

  // Mock delay to simulate network requests
  Future<void> _mockDelay() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  // Get class files
  Future<List<Map<String, dynamic>>> getClassFiles({
    required String classId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/class/$classId/Allfiles');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');
      print(
        'ApiService: Using token: ${accessToken?.substring(0, 20) ?? _accessToken?.substring(0, 20) ?? 'none'}...',
      );

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for class files: $data');

        // Handle the response format: {"files": [...]}
        if (data is Map<String, dynamic>) {
          if (data.containsKey('files')) {
            final files = data['files'] as List<dynamic>;
            print('Extracted files from response: $files');

            // Validate and enhance file data
            final processedFiles = files.map((file) {
              final fileMap = file as Map<String, dynamic>;

              // Check if URL is expired
              final expiresAt = fileMap['expiresAt'];
              final isExpired = expiresAt != null &&
                  DateTime.now().millisecondsSinceEpoch > (expiresAt * 1000);

              return {
                ...fileMap,
                'isExpired': isExpired,
                'expiresAtFormatted': expiresAt != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        expiresAt * 1000,
                      ).toIso8601String()
                    : null,
              };
            }).toList();

            return processedFiles.cast<Map<String, dynamic>>();
          } else if (data.containsKey('data') && data['data'] is List) {
            final files = data['data'] as List<dynamic>;
            print('Extracted files from data field: $files');
            return files.cast<Map<String, dynamic>>();
          } else {
            print('No files array found in response object');
            print('Available keys: ${data.keys.toList()}');
            return [];
          }
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('Unexpected response format');
        return [];
      } else if (response.statusCode == 404) {
        print('Class not found: ${response.body}');
        return [];
      } else {
        print(
          'Error fetching class files: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Exception fetching class files: $e');
      return [];
    }
  }

  // Get class notes
  Future<List<Map<String, dynamic>>> getClassNotes({
    required String classId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/classes/$classId/notes');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for class notes: $data');

        // Try different possible response formats
        if (data is Map<String, dynamic>) {
          if (data.containsKey('notes')) {
            final notes = data['notes'] as List<dynamic>;
            print('Extracted notes from response: $notes');
            return notes.cast<Map<String, dynamic>>();
          } else if (data.containsKey('data') && data['data'] is List) {
            final notes = data['data'] as List<dynamic>;
            print('Extracted notes from data field: $notes');
            return notes.cast<Map<String, dynamic>>();
          } else {
            print('No notes array found in response object');
            print('Available keys: ${data.keys.toList()}');
            return [];
          }
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('Unexpected response format');
        return [];
      } else {
        print(
          'Error fetching class notes: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Exception fetching class notes: $e');
      return [];
    }
  }

  // Get student's joined classes
  Future<List<Map<String, dynamic>>> getStudentClasses({
    required String studentId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/$studentId/classes');
      final headers = _buildHeaders(accessToken: accessToken);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for student classes: $data');
        if (data is Map<String, dynamic> && data.containsKey('classes')) {
          final classes = data['classes'] as List<dynamic>;
          print('Extracted classes from response: $classes');
          return classes.cast<Map<String, dynamic>>();
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('No classes found in response');
        return [];
      } else {
        print(
          'Error fetching student classes: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Exception fetching student classes: $e');
      return [];
    }
  }

  // Join class by code/id
  Future<Map<String, dynamic>> joinClass({
    required String classId,
    required String studentId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/join-class');
      final headers = _buildHeaders(accessToken: accessToken);

      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode({'classId': classId, 'studentId': studentId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        // Normalize response to a common shape
        final joinedClass = (data is Map<String, dynamic>)
            ? (data['class'] ?? data['data'] ?? data['classObj'] ?? data)
            : data;
        return {
          'success': true,
          'message': (data is Map<String, dynamic>)
              ? (data['message'] ?? 'تم الانضمام إلى الكلاس بنجاح')
              : 'تم الانضمام إلى الكلاس بنجاح',
          'class': joinedClass,
        };
      } else {
        // Try to extract error from JSON body
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  errorData['msg'] ??
                  'فشل في الانضمام إلى الكلاس')
              : 'فشل في الانضمام إلى الكلاس';
          throw Exception(errorMessage);
        } catch (_) {
          throw Exception('فشل في الانضمام إلى الكلاس');
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  // Authentication Methods
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? deviceToken,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'deviceToken': deviceToken,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Handle the new response structure with user object
      if (responseData['user'] != null) {
        final user = responseData['user'] as Map<String, dynamic>;

        print('API Service: User status: ${user['status']}');

        // Ensure all required fields are present with defaults
        final processedUser = {
          'id': user['id'] ?? user['_id'],
          'name': user['name'] ?? 'الطالب',
          'email': user['email'] ?? '',
          'phone': user['phone'] ?? '',
          'status': user['status'] ?? 'inactive',
          'plan': user['plan'] ?? '',
          'expiresAt': user['expiresAt'],
          'deviceToken': user['deviceToken'] ?? deviceToken,
        };

        print('API Service: Processed user data: $processedUser');

        return {
          'accessToken': responseData['accessToken'],
          'user': processedUser,
          'message': responseData['message'] ?? 'Login successful',
        };
      } else {
        print(
          'API Service: No user object in response, using fallback structure',
        );
        // Fallback to old structure if user object is not present
        return responseData;
      }
    } else {
      // Try to extract error message from response
      try {
        final errorData = jsonDecode(response.body);
        print('API Service: Login error data: $errorData');

        if (errorData is Map<String, dynamic>) {
          // If backend signals pending/expired account, surface it as a structured response
          final statusStr = errorData['status']?.toString().toLowerCase();
          final messageStr = (errorData['message'] ?? errorData['error'] ?? '')
              .toString()
              .toLowerCase();

          final isPendingOrExpired = statusStr == 'pending' ||
              statusStr == 'expired' ||
              messageStr.contains('pending') ||
              messageStr.contains('expired') ||
              messageStr.contains('inactive');

          if (isPendingOrExpired) {
            final user = (errorData['user'] ?? {}) as Map<String, dynamic>;
            final processedUser = {
              'id': user['id'] ?? user['_id'],
              'name': user['name'] ?? 'الطالب',
              'email': user['email'] ?? '',
              'phone': user['phone'] ?? '',
              'status': user['status'] ?? (statusStr ?? 'pending'),
              'plan': user['plan'] ?? '',
              'expiresAt': user['expiresAt'],
              'deviceToken': user['deviceToken'] ?? deviceToken,
            };

            print(
                'API Service: Pending/Expired login, returning structured data');
            return {
              'accessToken': errorData['accessToken'], // may be null
              'user': processedUser,
              'status': processedUser['status'],
              'message': errorData['message'] ?? 'الحساب غير مفعل',
            };
          }
          // Check for device conflict code first
          if (errorData['code'] == 'DEVICE_CONFLICT') {
            throw Exception('الحساب مسجل في جهاز اخر');
          }

          String errorMessage = errorData['message'] ??
              errorData['error'] ??
              errorData['msg'] ??
              'فشل في تسجيل الدخول';

          print('API Service: Extracted login error message: $errorMessage');

          // Clean up the error message if it contains JSON
          if (errorMessage.contains('{') && errorMessage.contains('}')) {
            try {
              final nestedError = jsonDecode(errorMessage);
              if (nestedError is Map<String, dynamic> &&
                  nestedError.containsKey('message')) {
                errorMessage = nestedError['message'];
              }
            } catch (e) {
              errorMessage = 'بيانات تسجيل الدخول غير صحيحة';
            }
          }

          // Translate common login error messages
          if (errorMessage.toLowerCase().contains('invalid credentials') ||
              errorMessage.toLowerCase().contains('wrong password') ||
              errorMessage.toLowerCase().contains('incorrect password')) {
            errorMessage = 'البيانات غير صحيحه';
          } else if (errorMessage.toLowerCase().contains('user not found') ||
              errorMessage.toLowerCase().contains('email not found')) {
            // Treat as invalid credentials for clearer UX
            errorMessage = 'البيانات غير صحيحه';
          } else if (errorMessage.toLowerCase().contains('login error')) {
            errorMessage = 'خطأ في تسجيل الدخول';
          } else if (errorMessage.toLowerCase().contains('device') ||
              errorMessage.toLowerCase().contains('conflict') ||
              errorMessage.toLowerCase().contains('مسجل في جهاز') ||
              errorMessage.toLowerCase().contains('مسجل على جهاز') ||
              errorMessage.toLowerCase().contains('مسجل بجهاز') ||
              errorMessage.toLowerCase().contains('على جهاز آخر') ||
              errorMessage.toLowerCase().contains('على جهاز اخر') ||
              errorMessage.toLowerCase().contains(
                    'logged in on another device',
                  ) ||
              errorMessage.toLowerCase().contains('already logged in') ||
              errorMessage.toLowerCase().contains('session exists')) {
            errorMessage = 'الحساب مسجل في جهاز اخر';
          }

          print('API Service: Final login error message: $errorMessage');
          throw Exception(errorMessage);
        } else {
          throw Exception('فشل في تسجيل الدخول');
        }
      } catch (jsonError) {
        print('API Service: Login JSON parsing error: $jsonError');
        // Inspect body text regardless of status code for known cases
        final bodyLower = response.body.toLowerCase();
        // Treat pending/expired as soft-success: allow app login with limited data
        if (bodyLower.contains('pending') ||
            bodyLower.contains('expired') ||
            bodyLower.contains('inactive')) {
          print('API Service: Detected pending/expired in body text');
          return {
            'accessToken': null,
            'user': {
              'id': null,
              'name': 'الطالب',
              'email': email,
              'phone': '',
              'status': bodyLower.contains('expired') ? 'expired' : 'pending',
              'plan': '',
              'expiresAt': null,
              'deviceToken': deviceToken,
            },
            'status': bodyLower.contains('expired') ? 'expired' : 'pending',
            'message': 'الحساب غير مفعل',
          };
        }
        if (bodyLower.contains('device') ||
            bodyLower.contains('conflict') ||
            bodyLower.contains('مسجل في جهاز') ||
            bodyLower.contains('مسجل على جهاز') ||
            bodyLower.contains('على جهاز آخر') ||
            bodyLower.contains('على جهاز اخر') ||
            bodyLower.contains('logged in on another device') ||
            bodyLower.contains('already active on another device') ||
            bodyLower.contains('already logged in') ||
            bodyLower.contains('session exists')) {
          throw Exception('الحساب مسجل في جهاز اخر');
        } else if (bodyLower.contains('invalid') ||
            bodyLower.contains('wrong password') ||
            bodyLower.contains('incorrect password') ||
            bodyLower.contains('user not found') ||
            bodyLower.contains('email not found')) {
          throw Exception('البيانات غير صحيحه');
        }
        // If JSON parsing fails, provide user-friendly messages based on status code
        if (response.statusCode == 401) {
          // Some backends use 401 for device conflict too; check body text
          final body = response.body.toLowerCase();
          if (body.contains('device') ||
              body.contains('conflict') ||
              body.contains('مسجل في جهاز') ||
              body.contains('مسجل على جهاز') ||
              body.contains('على جهاز آخر') ||
              body.contains('على جهاز اخر') ||
              body.contains('logged in on another device')) {
            throw Exception('الحساب مسجل في جهاز اخر');
          }
          throw Exception('البيانات غير صحيحه');
        } else if (response.statusCode == 403) {
          // Forbidden often used for pending/expired accounts
          return {
            'accessToken': null,
            'user': {
              'id': null,
              'name': 'الطالب',
              'email': email,
              'phone': '',
              'status': 'pending',
              'plan': '',
              'expiresAt': null,
              'deviceToken': deviceToken,
            },
            'status': 'pending',
            'message': 'الحساب غير مفعل',
          };
        } else if (response.statusCode == 404) {
          // Treat as invalid credentials for UX
          throw Exception('البيانات غير صحيحه');
        } else if (response.statusCode == 500) {
          throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
        } else if (response.statusCode == 409) {
          // 409 Conflict might indicate device conflict
          throw Exception('الحساب مسجل في جهاز اخر');
        } else {
          throw Exception('فشل في تسجيل الدخول');
        }
      }
    }
  }

  // Create pending user (new signup flow)
  Future<Map<String, dynamic>> createPendingUser({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String planId,
  }) async {
    try {
      print('Creating pending user with email: $email');
      print('API URL: $baseUrl/api/auth/pending');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/pending'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'planId': planId,
        }),
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      print('Response headers: ${response.headers}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Success response data: $responseData');

        // Check if the response actually contains a pendingId
        if (responseData['pendingId'] != null) {
          print(
            'API Service: Success - pendingId found: ${responseData['pendingId']}',
          );
          return responseData; // contains pendingId
        } else {
          // API returned success but no pendingId - this is an error
          print('API Service: Success response but no pendingId found');
          print('API Service: Response keys: ${responseData.keys.toList()}');
          print('API Service: Full response: $responseData');

          String errorMessage = responseData['message'] ??
              responseData['error'] ??
              responseData['msg'] ??
              responseData['errorMessage'] ??
              responseData['details'] ??
              'فشل في إنشاء الحساب المؤقت';

          // Check for specific error patterns that indicate email already exists
          String responseBody = response.body.toLowerCase();
          if (responseBody.contains('email') &&
              (responseBody.contains('already') ||
                  responseBody.contains('exists') ||
                  responseBody.contains('registered') ||
                  responseBody.contains('duplicate'))) {
            errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
            print(
              'API Service: Detected email already exists error from response body',
            );
          } else if (errorMessage.toLowerCase().contains('email') &&
              (errorMessage.toLowerCase().contains('already') ||
                  errorMessage.toLowerCase().contains('exists') ||
                  errorMessage.toLowerCase().contains('registered') ||
                  errorMessage.toLowerCase().contains('duplicate'))) {
            errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
            print(
              'API Service: Detected email already exists in error message',
            );
          }

          print(
            'API Service: 201 response but no pendingId, final error: $errorMessage',
          );
          throw Exception(errorMessage);
        }
      } else {
        print(
          'Error creating pending user: ${response.statusCode} - ${response.body}',
        );

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          print('API Service: Parsed error data: $errorData');

          if (errorData is Map<String, dynamic>) {
            // Check for different possible error message fields
            String errorMessage = errorData['message'] ??
                errorData['error'] ??
                errorData['msg'] ??
                'فشل في إنشاء الحساب المؤقت';

            print('API Service: Extracted error message: $errorMessage');

            // Clean up the error message if it contains JSON
            if (errorMessage.contains('{') && errorMessage.contains('}')) {
              try {
                final nestedError = jsonDecode(errorMessage);
                if (nestedError is Map<String, dynamic> &&
                    nestedError.containsKey('message')) {
                  errorMessage = nestedError['message'];
                }
              } catch (e) {
                // If nested JSON parsing fails, use a generic message
                errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
              }
            }

            // Translate common English error messages to Arabic
            if (errorMessage.toLowerCase().contains(
                  'error fetching pending payment',
                )) {
              errorMessage = 'خطأ في جلب بيانات الدفع المؤقت';
            } else if (errorMessage.toLowerCase().contains('email already') ||
                errorMessage.toLowerCase().contains('email exists') ||
                errorMessage.toLowerCase().contains('email registered') ||
                errorMessage.toLowerCase().contains('duplicate email')) {
              errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
            } else if (errorMessage.toLowerCase().contains('server error')) {
              errorMessage = 'خطأ في الخادم، يرجى المحاولة لاحقاً';
            }

            // Also check the raw response body for email-related errors
            String responseBody = response.body.toLowerCase();
            if (responseBody.contains('email') &&
                (responseBody.contains('already') ||
                    responseBody.contains('exists') ||
                    responseBody.contains('registered') ||
                    responseBody.contains('duplicate'))) {
              errorMessage = 'البريد الإلكتروني مسجل مسبقاً';
              print(
                'API Service: Detected email already exists error from raw response body',
              );
            }

            print('API Service: Final error message: $errorMessage');
            throw Exception(errorMessage);
          } else {
            throw Exception('فشل في إنشاء الحساب المؤقت');
          }
        } catch (jsonError) {
          print('API Service: JSON parsing error: $jsonError');
          // If JSON parsing fails, check response body for email errors
          String responseBody = response.body.toLowerCase();
          if (responseBody.contains('email') &&
              (responseBody.contains('already') ||
                  responseBody.contains('exists') ||
                  responseBody.contains('registered') ||
                  responseBody.contains('duplicate'))) {
            throw Exception('البريد الإلكتروني مسجل مسبقاً');
          } else if (response.statusCode == 400) {
            throw Exception('البريد الإلكتروني مسجل مسبقاً');
          } else if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else {
            throw Exception('فشل في إنشاء الحساب المؤقت');
          }
        }
      }
    } catch (e) {
      print('Exception creating pending user: $e');
      rethrow; // Re-throw to let AuthProvider handle the error message
    }
  }

  // Get available plans
  Future<List<dynamic>> getPlans() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/plans'));
      print('Plans API Response Status: ${response.statusCode}');
      print('Plans API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // The API returns { "plans": [...] }, so we need to extract the plans array
        if (data is Map<String, dynamic> && data.containsKey('plans')) {
          return data['plans'] as List<dynamic>;
        } else if (data is List) {
          return data;
        }
      }
      print('Error: Invalid response format or status code');
      return [];
    } catch (e) {
      print('Error fetching plans: $e');
      return [];
    }
  }

  // Create Stripe checkout session
  Future<String?> createCheckoutSession({
    required String pendingId,
    required String planId,
  }) async {
    try {
      print(
        'Creating checkout session with pendingId: $pendingId, planId: $planId',
      );
      // NOTE: Backend route per documentation is /api/payment/checkout
      // If your backend uses a different path, adjust here accordingly.
      print('API URL: $baseUrl/api/payment/checkout');

      http.Response response = await http.post(
        Uri.parse('$baseUrl/api/payment/checkout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'pendingId': pendingId, 'planId': planId}),
      );

      print('Checkout session response status: ${response.statusCode}');
      print('Checkout session response body: ${response.body}');

      // Fallback to the older endpoint if needed
      if (response.statusCode == 404 || response.statusCode == 405) {
        print('Primary checkout endpoint not found; trying legacy endpoint');
        response = await http.post(
          Uri.parse('$baseUrl/api/payment/create-checkout-session'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'pendingId': pendingId, 'planId': planId}),
        );
        print('Legacy endpoint status: ${response.statusCode}');
        print('Legacy endpoint body: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final possibleUrl =
              data['url'] ?? data['checkoutUrl'] ?? data['paymentUrl'];
          if (possibleUrl is String && possibleUrl.isNotEmpty) {
            return possibleUrl;
          }
          if (data.containsKey('data') &&
              data['data'] is Map<String, dynamic>) {
            final inner = data['data'] as Map<String, dynamic>;
            final innerUrl =
                inner['url'] ?? inner['checkoutUrl'] ?? inner['paymentUrl'];
            if (innerUrl is String && innerUrl.isNotEmpty) return innerUrl;
          }
        }
        throw Exception('رابط الدفع غير موجود في استجابة الخادم');
      } else {
        print(
          'Error creating checkout session: ${response.statusCode} - ${response.body}',
        );

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic> &&
              errorData.containsKey('message')) {
            throw Exception(errorData['message']);
          } else {
            throw Exception('فشل في إنشاء جلسة الدفع');
          }
        } catch (jsonError) {
          // If JSON parsing fails, throw with response body
          throw Exception('فشل في إنشاء جلسة الدفع: ${response.body}');
        }
      }
    } catch (e) {
      print('Exception creating checkout session: $e');
      rethrow; // Re-throw to let AuthProvider handle the error message
    }
  }

  // Check signup status
  Future<Map<String, dynamic>?> checkSignupStatus(String pendingId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/auth/status/$pendingId'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      print('Error: ${response.body}');
      return null;
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset({
    required String email,
  }) async {
    try {
      print('Requesting password reset for email: $email');
      print('API URL: $baseUrl/api/auth/forgot-password');

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      print('Password reset response status: ${response.statusCode}');
      print('Password reset response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'message': responseData['message'] ??
              'تم إرسال رمز التحقق إلى بريدك الإلكتروني',
        };
      } else {
        print(
          'Error requesting password reset: ${response.statusCode} - ${response.body}',
        );

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map<String, dynamic>) {
            String errorMessage = errorData['message'] ??
                errorData['error'] ??
                'فشل في إرسال رمز التحقق';

            // Handle specific error cases
            if (response.statusCode == 500) {
              errorMessage = 'خطأ في الخادم، يرجى المحاولة لاحقاً';
            } else if (response.statusCode == 404) {
              errorMessage = 'البريد الإلكتروني غير مسجل';
            } else if (response.statusCode == 400) {
              errorMessage = 'البريد الإلكتروني غير صحيح';
            }

            print('API Service: Password reset error message: $errorMessage');
            throw Exception(errorMessage);
          } else {
            throw Exception('فشل في إرسال رمز التحقق');
          }
        } catch (jsonError) {
          print('API Service: Password reset JSON parsing error: $jsonError');
          // If JSON parsing fails, provide user-friendly messages based on status code
          if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else if (response.statusCode == 404) {
            throw Exception('البريد الإلكتروني غير مسجل');
          } else if (response.statusCode == 400) {
            throw Exception('البريد الإلكتروني غير صحيح');
          } else {
            throw Exception('فشل في إرسال رمز التحقق');
          }
        }
      }
    } catch (e) {
      print('Exception requesting password reset: $e');
      rethrow; // Re-throw to let AuthProvider handle the error message
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    await _mockDelay();

    if (otp.isEmpty || otp.length != 6) {
      throw Exception('رمز التحقق غير صحيح');
    }

    // Mock OTP verification (accepts 123456)
    if (otp != '123456') {
      throw Exception('رمز التحقق غير صحيح');
    }

    return {'success': true, 'message': 'تم التحقق من الرمز بنجاح'};
  }

  Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    await _mockDelay();

    if (newPassword.length < 6) {
      throw Exception('كلمة المرور يجب أن تكون 6 أحرف على الأقل');
    }

    // Mock password reset
    return {'success': true, 'message': 'تم تغيير كلمة المرور بنجاح'};
  }

  // Legacy getPlans method (keeping for backward compatibility)
  Future<List<Map<String, dynamic>>> getPlansLegacy() async {
    await _mockDelay();

    return [
      {
        'id': '1',
        'name': 'الخطة الشهرية',
        'price': 29.99,
        'currency': 'SAR',
        'duration': 'شهر',
        'features': [
          'وصول كامل للمحتوى',
          'دعم فني 24/7',
          'تحديثات مستمرة',
          'إشعارات فورية',
        ],
        'popular': false,
      },
      {
        'id': '2',
        'name': 'الخطة النصف سنوية',
        'price': 149.99,
        'currency': 'SAR',
        'duration': '6 أشهر',
        'features': [
          'وصول كامل للمحتوى',
          'دعم فني 24/7',
          'تحديثات مستمرة',
          'إشعارات فورية',
          'خصم 20%',
        ],
        'popular': true,
      },
      {
        'id': '3',
        'name': 'الخطة السنوية',
        'price': 249.99,
        'currency': 'SAR',
        'duration': 'سنة',
        'features': [
          'وصول كامل للمحتوى',
          'دعم فني 24/7',
          'تحديثات مستمرة',
          'إشعارات فورية',
          'خصم 30%',
          'ميزات حصرية',
        ],
        'popular': false,
      },
    ];
  }

  Future<Map<String, dynamic>> payWithStripe({
    required String planId,
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  }) async {
    await _mockDelay();

    // Mock validation
    if (cardNumber.isEmpty ||
        expiryDate.isEmpty ||
        cvv.isEmpty ||
        cardholderName.isEmpty) {
      throw Exception('جميع بيانات البطاقة مطلوبة');
    }

    if (cardNumber.length < 16) {
      throw Exception('رقم البطاقة غير صحيح');
    }

    if (cvv.length < 3) {
      throw Exception('رمز الأمان غير صحيح');
    }

    // Mock successful payment
    return {
      'success': true,
      'message': 'تم الدفع بنجاح',
      'transactionId': 'txn_${DateTime.now().millisecondsSinceEpoch}',
      'subscriptionId': 'sub_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Logout method
  Future<Map<String, dynamic>> logout({
    required String userId,
    required String deviceToken,
  }) async {
    try {
      print('Making logout API call for userId: $userId');

      final response = await http
          .post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId, 'deviceToken': deviceToken}),
      )
          .timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('API Service: Logout request timeout');
          throw Exception('انتهت مهلة الطلب');
        },
      );

      print('Logout response status: ${response.statusCode}');
      print('Logout response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'message': data['message'] ?? 'تم تسجيل الخروج من الخادم بنجاح',
          'data': data,
        };
      } else {
        print('Logout error: ${response.statusCode} - ${response.body}');

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  'فشل في تسجيل الخروج من الخادم')
              : 'فشل في تسجيل الخروج من الخادم';

          return {
            'success': false,
            'message': errorMessage,
            'statusCode': response.statusCode,
          };
        } catch (jsonError) {
          return {
            'success': false,
            'message': 'فشل في تسجيل الخروج من الخادم',
            'statusCode': response.statusCode,
          };
        }
      }
    } catch (e) {
      print('Logout exception: $e');

      // Handle specific exception types
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('TimeoutException')) {
        return {
          'success': false,
          'message': 'خطأ في الاتصال بالإنترنت أثناء تسجيل الخروج',
          'error': 'network_error',
        };
      } else {
        return {
          'success': false,
          'message': 'حدث خطأ أثناء تسجيل الخروج من الخادم',
          'error': e.toString(),
        };
      }
    }
  }

  // Force logout method (for device conflict resolution)
  Future<Map<String, dynamic>> forceLogout({required String userId}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/force-logout'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Force logout error: ${response.statusCode} - ${response.body}');
        return {'success': false, 'message': 'Force logout failed'};
      }
    } catch (e) {
      print('Force logout exception: $e');
      return {'success': false, 'message': 'Force logout failed'};
    }
  }

  // Get user subscription status and renewal date
  Future<Map<String, dynamic>> getUserSubscriptionStatus({
    required String userId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/user/$userId/subscription');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for subscription status: $data');

        // Handle the response format
        if (data is Map<String, dynamic>) {
          final subscriptionData = data['subscription'] ?? data['data'] ?? data;

          // Process subscription data - check multiple possible field names and values
          final status = subscriptionData['status']?.toString().toLowerCase();
          final isActiveField = subscriptionData['isActive'];
          final activeField = subscriptionData['active'];
          final isSubscribedField = subscriptionData['isSubscribed'];

          // Check if status is 'active' (not 'pending')
          final isActive = status == 'active' ||
              isActiveField == true ||
              activeField == true ||
              isSubscribedField == true;

          final expiresAt = subscriptionData['expiresAt'] ??
              subscriptionData['expiryDate'] ??
              subscriptionData['renewalDate'];

          String formattedDate = 'غير محدد';
          if (expiresAt != null) {
            try {
              // Handle different date formats
              DateTime date;
              if (expiresAt is String) {
                date = DateTime.parse(expiresAt);
              } else if (expiresAt is int) {
                // Unix timestamp in seconds
                date = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
              } else {
                // Unix timestamp in milliseconds
                date = DateTime.fromMillisecondsSinceEpoch(expiresAt);
              }
              formattedDate =
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
            } catch (e) {
              print('Error parsing expiration date: $e');
              formattedDate = 'غير محدد';
            }
          }

          final result = {
            'isActive': isActive,
            'expiresAt': expiresAt,
            'formattedDate': formattedDate,
            'plan':
                subscriptionData['plan'] ?? subscriptionData['planName'] ?? '',
            'status': subscriptionData['status'] ??
                (isActive ? 'active' : 'inactive'),
          };

          return result;
        } else {
          print('Unexpected response format');
          return {
            'isActive': false,
            'expiresAt': null,
            'formattedDate': 'غير محدد',
            'plan': '',
            'status': 'inactive',
          };
        }
      } else if (response.statusCode == 404) {
        print('User subscription not found: ${response.body}');
        return {
          'isActive': false,
          'expiresAt': null,
          'formattedDate': 'غير محدد',
          'plan': '',
          'status': 'inactive',
        };
      } else {
        print(
          'Error fetching subscription status: ${response.statusCode} - ${response.body}',
        );
        return {
          'isActive': false,
          'expiresAt': null,
          'formattedDate': 'غير محدد',
          'plan': '',
          'status': 'inactive',
        };
      }
    } catch (e) {
      print('Exception fetching subscription status: $e');
      return {
        'isActive': false,
        'expiresAt': null,
        'formattedDate': 'غير محدد',
        'plan': '',
        'status': 'inactive',
      };
    }
  }

  // ---------------- Dashboard Integration Stubs ----------------
  // These methods model how the app will talk to the teacher dashboard
  // in the future. They currently return mocked responses.

  // Content models
  Future<List<Map<String, dynamic>>> listNotes({
    required String classId,
  }) async {
    await _mockDelay();
    return [
      {
        'id': 'n1',
        'title': 'ملاحظة عامة',
        'content': 'يرجى مراجعة ملخص الدرس الأول',
        'createdAt': DateTime.now().toIso8601String(),
      },
    ];
  }

  Future<List<Map<String, dynamic>>> listVideos({
    required String classId,
    String? accessToken,
  }) async {
    try {
      print('API Service: Fetching videos for classId: $classId');

      final headers = _buildHeaders(accessToken: accessToken);

      var response = await http.get(
        Uri.parse('$baseUrl/api/student/classes/$classId/videos'),
        headers: headers,
      );

      print('API Service: Videos response status: ${response.statusCode}');
      print('API Service: Videos response body: ${response.body}');

      // If the plural endpoint doesn't work, try the singular endpoint
      if (response.statusCode == 404) {
        print('API Service: Trying singular endpoint...');
        response = await http.get(
          Uri.parse('$baseUrl/api/student/class/$classId/videos'),
          headers: headers,
        );
        print(
          'API Service: Singular endpoint response status: ${response.statusCode}',
        );
        print('API Service: Singular endpoint response body: ${response.body}');
      }

      // If still 404, try other possible endpoints
      if (response.statusCode == 404) {
        print('API Service: Trying content endpoint...');
        response = await http.get(
          Uri.parse('$baseUrl/api/student/classes/$classId/content'),
          headers: headers,
        );
        print(
          'API Service: Content endpoint response status: ${response.statusCode}',
        );
        print('API Service: Content endpoint response body: ${response.body}');
      }

      if (response.statusCode == 404) {
        print('API Service: Trying media endpoint...');
        response = await http.get(
          Uri.parse('$baseUrl/api/student/classes/$classId/media'),
          headers: headers,
        );
        print(
          'API Service: Media endpoint response status: ${response.statusCode}',
        );
        print('API Service: Media endpoint response body: ${response.body}');
      }

      if (response.statusCode == 404) {
        print('API Service: Trying materials endpoint...');
        response = await http.get(
          Uri.parse('$baseUrl/api/student/classes/$classId/materials'),
          headers: headers,
        );
        print(
          'API Service: Materials endpoint response status: ${response.statusCode}',
        );
        print(
          'API Service: Materials endpoint response body: ${response.body}',
        );
      }

      // Try teacher-specific endpoints
      if (response.statusCode == 404) {
        print('API Service: Trying teacher videos endpoint...');
        response = await http.get(
          Uri.parse('$baseUrl/api/teacher/class/$classId/videos'),
          headers: headers,
        );
        print(
          'API Service: Teacher videos endpoint response status: ${response.statusCode}',
        );
        print(
          'API Service: Teacher videos endpoint response body: ${response.body}',
        );
      }

      if (response.statusCode == 404) {
        print('API Service: Trying all files endpoint...');
        response = await http.get(
          Uri.parse('$baseUrl/api/student/class/$classId/Allfiles'),
          headers: headers,
        );
        print(
          'API Service: All files endpoint response status: ${response.statusCode}',
        );
        print(
          'API Service: All files endpoint response body: ${response.body}',
        );
      }

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('API Service: Videos response data: $responseData');

        // Handle different possible response formats
        List<dynamic> videosList = [];

        if (responseData is Map<String, dynamic>) {
          // Try different possible keys for videos array
          if (responseData.containsKey('videos') &&
              responseData['videos'] is List) {
            videosList = responseData['videos'] as List;
            print('API Service: Found videos in "videos" key');
          } else if (responseData.containsKey('data') &&
              responseData['data'] is List) {
            videosList = responseData['data'] as List;
            print('API Service: Found videos in "data" key');
          } else if (responseData.containsKey('results') &&
              responseData['results'] is List) {
            videosList = responseData['results'] as List;
            print('API Service: Found videos in "results" key');
          } else if (responseData.containsKey('files') &&
              responseData['files'] is List) {
            // Check if files contain videos
            final files = responseData['files'] as List;
            videosList = files.where((file) {
              final fileType = file['type']?.toString().toLowerCase() ?? '';
              final fileName = file['name']?.toString().toLowerCase() ?? '';
              final fileUrl = file['url']?.toString().toLowerCase() ?? '';
              return fileType.contains('video') ||
                  fileName.contains('video') ||
                  fileUrl.contains('youtube') ||
                  fileUrl.contains('video') ||
                  fileType.contains('mp4') ||
                  fileType.contains('avi') ||
                  fileType.contains('mov');
            }).toList();
            print(
              'API Service: Found ${videosList.length} video files in "files" key',
            );
          } else {
            print('API Service: No videos array found in response');
            print('API Service: Available keys: ${responseData.keys.toList()}');
            return [];
          }
        } else if (responseData is List) {
          videosList = responseData;
          print('API Service: Response is direct list');
        } else {
          print(
            'API Service: Unexpected response format: ${responseData.runtimeType}',
          );
          return [];
        }

        if (videosList.isNotEmpty) {
          final videos = videosList.map((video) {
            print('API Service: Processing video: $video');

            // Extract video ID from YouTube URL if present
            String? videoId = video['videoId'] ?? video['youtubeId'];
            String? videoUrl =
                video['url'] ?? video['fileUrl'] ?? video['pdfUrl'];

            // If no videoId but we have a URL, try to extract YouTube ID
            if (videoId == null && videoUrl != null) {
              final url = videoUrl.toString();
              if (url.contains('youtube.com/watch?v=')) {
                videoId = url.split('v=')[1].split('&')[0];
              } else if (url.contains('youtu.be/')) {
                videoId = url.split('youtu.be/')[1].split('?')[0];
              }
            }

            return {
              'id': video['_id'] ?? video['id'] ?? '',
              'videoId': videoId ?? '',
              'title': video['name'] ??
                  video['title'] ??
                  video['fileName'] ??
                  'فيديو بدون عنوان',
              'description': video['description'] ?? '',
              'uploadedAt': video['uploadedAt'] ??
                  video['createdAt'] ??
                  video['addedAt'] ??
                  '',
              'url': videoId != null
                  ? 'https://www.youtube.com/embed/$videoId?autoplay=0&rel=0&modestbranding=1&controls=1'
                  : videoUrl ?? '',
            };
          }).toList();

          print('API Service: Processed ${videos.length} videos');
          return videos;
        } else {
          print('API Service: Videos list is empty');
          return [];
        }
      } else if (response.statusCode == 404) {
        print('API Service: Videos endpoint not found (404)');
        return [];
      } else {
        print('API Service: Failed to fetch videos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('API Service: Error fetching videos: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> listExams({
    required String classId,
  }) async {
    await _mockDelay();
    return [
      {
        'id': 'e1',
        'title': 'امتحان الوحدة 1',
        'pdfUrl': 'https://example.com/exams/e1.pdf',
        'deadline': '2025-12-20',
      },
    ];
  }

  // Upload endpoints (teacher)
  Future<Map<String, dynamic>> uploadPdf({
    required String classId,
    required String filePath,
    required String title,
  }) async {
    await _mockDelay();
    return {
      'success': true,
      'id': 'pdf_${DateTime.now().millisecondsSinceEpoch}',
      'url':
          'https://example.com/pdfs/${DateTime.now().millisecondsSinceEpoch}.pdf',
    };
  }

  Future<Map<String, dynamic>> createExam({
    required String classId,
    required String title,
    required String pdfUrl,
    required String deadline,
  }) async {
    await _mockDelay();
    return {
      'success': true,
      'id': 'e_${DateTime.now().millisecondsSinceEpoch}',
    };
  }

  // Student submission
  Future<Map<String, dynamic>> submitExam({
    required String classId,
    required String examId,
    required String filePath,
  }) async {
    await _mockDelay();
    return {
      'success': true,
      'submissionId': 's_${DateTime.now().millisecondsSinceEpoch}',
      'status': 'received',
    };
  }

  // Get class tasks/exams from backend
  Future<List<Map<String, dynamic>>> getClassTasks({
    required String classId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/class/$classId/tasks');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for class tasks: $data');

        // Handle the response format: {"tasks": [...]}
        if (data is Map<String, dynamic>) {
          if (data.containsKey('tasks')) {
            final tasks = data['tasks'] as List<dynamic>;
            print('Extracted tasks from response: $tasks');

            // Process task data to match expected format
            final processedTasks = tasks.map((task) {
              final taskMap = task as Map<String, dynamic>;

              // Format addedAt date
              String formattedDate = 'غير محدد';
              if (taskMap['addedAt'] != null) {
                try {
                  final date = DateTime.parse(taskMap['addedAt']);
                  formattedDate =
                      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                } catch (e) {
                  print('Error parsing addedAt date: $e');
                }
              }

              // Check if task is expired
              final expiresAt = taskMap['expiresAt'];
              final isExpired = expiresAt != null &&
                  DateTime.now().millisecondsSinceEpoch > (expiresAt * 1000);

              return {
                'id': taskMap['_id'],
                'title': taskMap['name'] ?? 'امتحان غير محدد',
                'content': taskMap['description'] ?? 'لا يوجد وصف',
                'pdfUrl': taskMap['url'],
                'expiresAt': expiresAt,
                'isExpired': isExpired,
                'expiresAtFormatted': expiresAt != null
                    ? DateTime.fromMillisecondsSinceEpoch(
                        expiresAt * 1000,
                      ).toIso8601String()
                    : null,
                'addedAt': formattedDate,
                'deadline': formattedDate, // For compatibility with existing UI
              };
            }).toList();

            return processedTasks.cast<Map<String, dynamic>>();
          } else if (data.containsKey('data') && data['data'] is List) {
            final tasks = data['data'] as List<dynamic>;
            print('Extracted tasks from data field: $tasks');
            return tasks.cast<Map<String, dynamic>>();
          } else {
            print('No tasks array found in response object');
            print('Available keys: ${data.keys.toList()}');
            return [];
          }
        } else if (data is List) {
          print('Response is direct list: $data');
          return data.cast<Map<String, dynamic>>();
        }
        print('Unexpected response format');
        return [];
      } else if (response.statusCode == 404) {
        print('Class not found: ${response.body}');
        return [];
      } else {
        print(
          'Error fetching class tasks: ${response.statusCode} - ${response.body}',
        );
        return [];
      }
    } catch (e) {
      print('Exception fetching class tasks: $e');
      return [];
    }
  }

  // Get single task details (to check submission status)
  Future<Map<String, dynamic>?> getTaskDetails({
    required String classId,
    required String taskId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/class/$classId/task/$taskId');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for task details: $data');
        if (data is Map<String, dynamic>) {
          return data;
        }
        return null;
      } else {
        print(
          'Error fetching task details: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Exception fetching task details: $e');
      return null;
    }
  }

  // Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String studentId,
    required String name,
    required String phone,
    required String email,
    String? password,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/$studentId/updateUser');
      final headers = _buildHeaders(accessToken: accessToken);

      final body = {
        'name': name,
        'phone': phone,
        'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
      };

      print('Making API call to: $uri');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for user update: $data');
        return data;
      } else {
        print('Error updating user: ${response.statusCode} - ${response.body}');

        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  errorData['msg'] ??
                  'فشل في تحديث الملف الشخصي')
              : 'فشل في تحديث الملف الشخصي';

          throw Exception(errorMessage);
        } catch (jsonError) {
          if (response.statusCode == 400) {
            throw Exception('بيانات الطلب غير صحيحة');
          } else if (response.statusCode == 401) {
            throw Exception('غير مخول لتحديث الملف الشخصي');
          } else if (response.statusCode == 404) {
            throw Exception('المستخدم غير موجود');
          } else if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else {
            throw Exception('فشل في تحديث الملف الشخصي');
          }
        }
      }
    } catch (e) {
      print('Exception updating user: $e');
      rethrow;
    }
  }

  // Get plan details
  Future<Map<String, dynamic>> getPlanDetails({
    required String planId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/plan/$planId');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');
      print(
        'ApiService: Using token for getPlanDetails: ${accessToken?.substring(0, 20) ?? _accessToken?.substring(0, 20) ?? 'none'}...',
      );

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for plan details: $data');
        return data;
      } else {
        print(
          'Error fetching plan details: ${response.statusCode} - ${response.body}',
        );

        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  errorData['msg'] ??
                  'فشل في جلب تفاصيل الخطة')
              : 'فشل في جلب تفاصيل الخطة';

          throw Exception(errorMessage);
        } catch (jsonError) {
          if (response.statusCode == 404) {
            throw Exception('الخطة غير موجودة');
          } else if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else {
            throw Exception('فشل في جلب تفاصيل الخطة');
          }
        }
      }
    } catch (e) {
      print('Exception fetching plan details: $e');
      rethrow;
    }
  }

  // Get user profile
  Future<Map<String, dynamic>?> getUserProfile({
    required String userId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/$userId/profile');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');
      print(
        'ApiService: Using token for getUserProfile: ${accessToken?.substring(0, 20) ?? _accessToken?.substring(0, 20) ?? 'none'}...',
      );

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for user profile: $data');

        // Handle different response formats
        if (data is Map<String, dynamic>) {
          // Check if user data is nested
          if (data.containsKey('user')) {
            return data['user'] as Map<String, dynamic>;
          } else if (data.containsKey('student')) {
            return data['student'] as Map<String, dynamic>;
          } else if (data.containsKey('data')) {
            return data['data'] as Map<String, dynamic>;
          } else {
            return data;
          }
        }
        return null;
      } else {
        print(
          'Error fetching user profile: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Exception fetching user profile: $e');
      return null;
    }
  }

  // Get unified student data (replaces multiple API calls)
  Future<Map<String, dynamic>?> getStudentData({
    required String studentId,
    String? accessToken,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/api/student/$studentId/data');
      final headers = _buildHeaders(accessToken: accessToken);

      print('Making API call to: $uri');
      print('Headers: $headers');
      print(
        'ApiService: Using token for getStudentData: ${accessToken?.substring(0, 20) ?? _accessToken?.substring(0, 20) ?? 'none'}...',
      );

      final response = await http.get(uri, headers: headers);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('API Response for student data: $data');
        return data;
      } else if (response.statusCode == 401) {
        print(
          'API Error: Unauthorized (401) - Token may be invalid or expired',
        );
        print('Response body: ${response.body}');
        return null;
      } else if (response.statusCode == 403) {
        print('API Error: Forbidden (403) - Access denied');
        print('Response body: ${response.body}');

        // Check if this is a pending/expired status response
        try {
          final errorData = jsonDecode(response.body);
          String message = '';
          if (errorData is Map<String, dynamic>) {
            final status = errorData['status']?.toString().toLowerCase();
            message = errorData['message']?.toString() ?? '';

            final msgLower = message.toLowerCase();
            final isPending =
                status == 'pending' || msgLower.contains('pending');
            final isExpired =
                status == 'expired' || msgLower.contains('expired');

            if (isPending || isExpired) {
              print('API: Detected ${isExpired ? 'expired' : 'pending'} user');
              return {
                'id': null,
                'status': isExpired ? 'expired' : 'pending',
                'message': message.isNotEmpty
                    ? message
                    : (isExpired
                        ? 'Account expired'
                        : 'Account pending approval'),
              };
            }
          }
        } catch (e) {
          print('API: Could not parse 403 response: $e');
        }

        // Default: treat as pending to be safe
        return {
          'id': null,
          'status': 'pending',
          'message': 'Account pending approval',
        };
      } else {
        print(
          'Error fetching student data: ${response.statusCode} - ${response.body}',
        );
        return null;
      }
    } catch (e) {
      print('Exception fetching student data: $e');
      return null;
    }
  }

  // Submit task solution
  Future<Map<String, dynamic>> submitTaskSolution({
    required String studentId,
    required String classId,
    required String taskId,
    required String filePath,
    String? accessToken,
  }) async {
    try {
      // Validate student ID
      if (studentId.isEmpty) {
        throw Exception('معرف الطالب غير متوفر');
      }

      // Validate file path
      if (filePath.isEmpty) {
        throw Exception('مسار الملف غير صحيح');
      }

      // Check if file exists
      final file = File(filePath);
      if (!await file.exists()) {
        throw Exception('الملف غير موجود');
      }

      // Check file size (limit to 10MB)
      final fileSize = await file.length();
      if (fileSize > 10 * 1024 * 1024) {
        throw Exception('حجم الملف كبير جداً (الحد الأقصى 10 ميجابايت)');
      }

      // Build the API endpoint with studentId, classId, and taskId
      final uri = Uri.parse(
        '$baseUrl/api/student/$studentId/class/$classId/task/$taskId/solution',
      );

      // Create multipart request for file upload
      var request = http.MultipartRequest('POST', uri);

      // Add headers
      final effectiveToken = (accessToken != null && accessToken.isNotEmpty)
          ? accessToken
          : _accessToken;
      if (effectiveToken != null && effectiveToken.isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $effectiveToken';
      }

      // Add file with proper content type
      final fileExtension = filePath.split('.').last.toLowerCase();
      String contentType = 'application/octet-stream';

      switch (fileExtension) {
        case 'pdf':
          contentType = 'application/pdf';
          break;
        case 'doc':
          contentType = 'application/msword';
          break;
        case 'docx':
          contentType =
              'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
          break;
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
      }

      request.files.add(
        await http.MultipartFile.fromPath(
          'solution',
          filePath,
          contentType: MediaType(
            contentType.split('/')[0],
            contentType.split('/')[1],
          ),
        ),
      );

      print('Making API call to: $uri');
      print('Student ID: $studentId');
      print('Class ID: $classId');
      print('Task ID: $taskId');
      print('File path: $filePath');
      print('File size: ${fileSize} bytes');
      print('Content type: $contentType');
      print('Headers: ${request.headers}');

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('API Response for task submission: $data');

        return {
          'success': true,
          'message': data['message'] ?? 'تم تسليم الحل بنجاح',
          'solution': data['solution'],
        };
      } else {
        print(
          'Error submitting task solution: ${response.statusCode} - ${response.body}',
        );

        // Try to extract error message from response
        try {
          final errorData = jsonDecode(response.body);
          String errorMessage = (errorData is Map<String, dynamic>)
              ? (errorData['message'] ??
                  errorData['error'] ??
                  errorData['msg'] ??
                  'فشل في تسليم الحل')
              : 'فشل في تسليم الحل';

          throw Exception(errorMessage);
        } catch (jsonError) {
          // Provide specific error messages based on status code
          if (response.statusCode == 400) {
            throw Exception('بيانات الطلب غير صحيحة');
          } else if (response.statusCode == 401) {
            throw Exception('غير مخول لتسليم هذا الامتحان');
          } else if (response.statusCode == 403) {
            throw Exception('انتهت صلاحية الامتحان');
          } else if (response.statusCode == 404) {
            throw Exception('الامتحان غير موجود');
          } else if (response.statusCode == 413) {
            throw Exception('حجم الملف كبير جداً');
          } else if (response.statusCode == 500) {
            throw Exception('خطأ في الخادم، يرجى المحاولة لاحقاً');
          } else {
            throw Exception('فشل في تسليم الحل');
          }
        }
      }
    } catch (e) {
      print('Exception submitting task solution: $e');

      // Handle specific exception types
      if (e.toString().contains('SocketException') ||
          e.toString().contains('HandshakeException') ||
          e.toString().contains('TimeoutException')) {
        throw Exception('خطأ في الاتصال بالإنترنت');
      } else if (e.toString().contains('FileSystemException')) {
        throw Exception('خطأ في قراءة الملف');
      } else {
        rethrow; // Re-throw the original exception if it's already in Arabic
      }
    }
  }
}

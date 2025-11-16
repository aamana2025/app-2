import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// Debug widget to test authentication and API calls
/// This widget can be temporarily added to any screen for debugging
class AuthDebugWidget extends StatefulWidget {
  const AuthDebugWidget({super.key});

  @override
  State<AuthDebugWidget> createState() => _AuthDebugWidgetState();
}

class _AuthDebugWidgetState extends State<AuthDebugWidget> {
  Map<String, dynamic>? _testResult;
  bool _isLoading = false;

  Future<void> _runAuthTest() async {
    setState(() {
      _isLoading = true;
      _testResult = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Test 1: Check if user is authenticated
      final isAuthenticated = authProvider.isAuthenticated;
      final hasToken = authProvider.verifyAccessToken();
      final user = authProvider.user;
      final token = authProvider.token;

      // Test 2: Try a real API call
      final apiTestResult = await authProvider.testRealApiCall();

      setState(() {
        _testResult = {
          'isAuthenticated': isAuthenticated,
          'hasToken': hasToken,
          'userExists': user != null,
          'tokenExists': token != null,
          'tokenPreview': token?.substring(0, 20) ?? 'none',
          'apiTestResult': apiTestResult,
          'timestamp': DateTime.now().toIso8601String(),
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Auth Debug Info',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _runAuthTest,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Run Auth Test'),
            ),
            const SizedBox(height: 16),
            if (_testResult != null) ...[
              const Text(
                'Test Results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _testResult.toString(),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

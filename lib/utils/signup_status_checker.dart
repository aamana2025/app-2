import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class SignupStatusChecker {
  static Future<void> checkAndHandleStatus(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.pendingId != null) {
      final isActivated = await authProvider.checkSignupStatus();

      if (isActivated && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تفعيل حسابك بنجاح! يمكنك الآن تسجيل الدخول'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 5),
          ),
        );
        context.go('/login');
      }
    }
  }
}

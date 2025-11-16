import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/auth/signup_with_payment_screen.dart';
import '../screens/auth/forget_password_screen.dart';
import '../screens/auth/otp_verification_screen.dart';
import '../screens/auth/reset_password_screen.dart';
import '../screens/subscription/plans_screen.dart';
import '../screens/subscription/payment_screen.dart';
import '../screens/subscription/plan_selection_screen.dart';
import '../screens/subscription/payment_confirmation_screen.dart';
import '../screens/home_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/classroom_screen.dart';
import '../screens/debug/api_test_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Only load stored data if not already loaded
      if (!authProvider.isAuthenticated && authProvider.user == null) {
        try {
          await authProvider.loadStoredLoginData();
        } catch (e) {
          print('AppRouter: Error loading stored data: $e');
        }
      }

      final isAuthenticated = authProvider.isAuthenticated;
      final isSubscribed = authProvider.isSubscribed;
      final currentPath = state.uri.path;

      print('AppRouter: Current path: $currentPath');
      print('AppRouter: Is authenticated: $isAuthenticated');
      print('AppRouter: Is subscribed: $isSubscribed');

      // Allow splash screen to show without redirects
      if (currentPath == '/splash') {
        return null;
      }

      // If user is not authenticated and trying to access protected routes
      if (!isAuthenticated) {
        if (currentPath == '/login' ||
            currentPath == '/signup' ||
            currentPath == '/plan-selection' ||
            currentPath == '/forget-password' ||
            currentPath == '/otp' ||
            currentPath == '/reset-password' ||
            currentPath == '/plans' ||
            currentPath == '/payment' ||
            currentPath == '/payment-confirmation') {
          return null; // Allow access to auth and payment routes
        } else {
          return '/login'; // Redirect to login for protected routes
        }
      }

      // If user is authenticated but not subscribed (pending/expired),
      // allow navigation to Home so the in-app expired popup can guide them.
      // They can still navigate to plan-selection/payment manually from the popup.
      if (isAuthenticated && !isSubscribed) {
        return null; // No redirect – app will show the expiry dialog
      }

      // If user is authenticated and subscribed
      if (isAuthenticated && isSubscribed) {
        if (currentPath == '/login' ||
            currentPath == '/signup' ||
            currentPath == '/forget-password' ||
            currentPath == '/otp' ||
            currentPath == '/reset-password') {
          return '/home'; // Redirect to home for auth routes
        }
        // Allow access to plan-selection, plans, payment, and payment-confirmation for upgrades
      }

      return null; // No redirect needed
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/plan-selection',
        name: 'plan-selection',
        builder: (context, state) => const PlanSelectionScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupWithPaymentScreen(),
      ),
      GoRoute(
        path: '/signup-old',
        name: 'signup-old',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forget-password',
        name: 'forget-password',
        builder: (context, state) => const ForgetPasswordScreen(),
      ),
      GoRoute(
        path: '/otp',
        name: 'otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return OtpVerificationScreen(email: email);
        },
      ),
      GoRoute(
        path: '/reset-password',
        name: 'reset-password',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          final otp = state.uri.queryParameters['otp'] ?? '';
          return ResetPasswordScreen(email: email, otp: otp);
        },
      ),
      GoRoute(
        path: '/plans',
        name: 'plans',
        builder: (context, state) => const PlansScreen(),
      ),
      GoRoute(
        path: '/payment',
        name: 'payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/payment-confirmation',
        name: 'payment-confirmation',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaymentConfirmationScreen(selectedPlan: extra);
        },
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/classroom',
        name: 'classroom',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final classId = extra?['id']?.toString() ?? '';
          final className = extra?['name']?.toString() ?? 'الكلاس';
          return ClassroomScreen(classId: classId, className: className);
        },
      ),
      GoRoute(
        path: '/api-test',
        name: 'api-test',
        builder: (context, state) => const ApiTestScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            const Text(
              'الصفحة غير موجودة',
              style: TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'الرابط المطلوب غير صحيح',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0A84FF),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('العودة للصفحة الرئيسية'),
            ),
          ],
        ),
      ),
    ),
  );
}

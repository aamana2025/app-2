import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/signup_status_checker.dart';
import '../../widgets/gradient_bg.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    // Check signup status when login screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SignupStatusChecker.checkAndHandleStatus(context);
    });
  }

  void _togglePasswordVisibility() {
    setState(() {
      _isPasswordVisible = !_isPasswordVisible;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // Clear any previous error
    setState(() {
      _errorMessage = null;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      // Debug: Print the actual error to see what we're getting
      print('LoginScreen: AuthProvider error: "${authProvider.error}"');

      // Check for device conflict
      if (authProvider.error == 'DEVICE_CONFLICT') {
        print('LoginScreen: Device conflict detected, showing new message');
        setState(() {
          _errorMessage = 'الحساب مسجل في جهاز اخر';
        });
        // Auto-dismiss error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      } else {
        print(
            'LoginScreen: Regular error, showing: ${authProvider.error ?? 'فشل في تسجيل الدخول'}');
        // Map generic/invalid cases to the correct Arabic message
        final raw = (authProvider.error ?? '').toLowerCase();
        String displayError;
        if (raw.contains('invalid') ||
            raw.contains('wrong') ||
            raw.contains('incorrect') ||
            raw.contains('not found') ||
            raw.contains('غير صحيحه') ||
            raw.contains('غير صحيحة') ||
            raw.contains('المستخدم غير موجود')) {
          displayError = 'البيانات غير صحيحه';
        } else {
          displayError = authProvider.error ?? 'فشل في تسجيل الدخول';
        }
        setState(() {
          _errorMessage = displayError;
        });
        // Auto-dismiss error after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _errorMessage = null;
            });
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

        final formContent = Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),
              // Logo/Title
              const Icon(
                Icons.school,
                size: 80,
                color: Color.fromARGB(255, 10, 132, 255),
              ),
              const SizedBox(height: 24),
              const Text(
                'مرحباً بك',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'سجل دخولك للوصول إلى حسابك',
                style: TextStyle(
                  color: Color(0xFF666666),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Email Field
              CustomTextField(
                controller: _emailController,
                hintText: 'البريد الإلكتروني',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFFB0B0B0),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'البريد الإلكتروني مطلوب';
                  }
                  if (!value.contains('@')) {
                    return 'البريد الإلكتروني غير صحيح';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Password Field
              CustomTextField(
                controller: _passwordController,
                hintText: 'كلمة المرور',
                obscureText: !_isPasswordVisible,
                prefixIcon: const Icon(
                  Icons.lock_outline,
                  color: Color(0xFFB0B0B0),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: const Color(0xFFB0B0B0),
                  ),
                  onPressed: _togglePasswordVisibility,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'كلمة المرور مطلوبة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Error Message Display (above button)
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red[400],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Login Button
              CustomButton(
                text: 'تسجيل الدخول',
                onPressed: _handleLogin,
                isLoading: authProvider.isLoading,
                textColor: Colors.white,
                backgroundGradient: const LinearGradient(
                  colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              const SizedBox(height: 24),
              // Forgot Password Link
              TextButton(
                onPressed: () => context.go('/forget-password'),
                child: const Text(
                  'نسيت كلمة المرور؟',
                  style: TextStyle(
                    color: Color(0xFF0A84FF),
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Hidden: Sign-up prompt "ليس لديك حساب؟ إنشاء حساب"
              const SizedBox.shrink(),
              /*
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'ليس لديك حساب؟ ',
                    style: TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 16,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/plans'),
                    child: const Text(
                      'إنشاء حساب جديد',
                      style: TextStyle(
                        color: Color(0xFF0A84FF),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              */
            ],
          ),
        );

        return Scaffold(
          backgroundColor: Colors.white,
          extendBodyBehindAppBar: true,
          body: SafeArea(
            child: GradientDecoratedBackground(
              child: isKeyboardOpen
                  ? NotificationListener<OverscrollIndicatorNotification>(
                      onNotification: (notification) {
                        notification.disallowIndicator();
                        return true;
                      },
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: formContent,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: formContent,
                    ),
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/gradient_bg.dart'; // <-- تأكد إن الملف يحتوي الكلاس GradientDecoratedBackground

class SignupWithPaymentScreen extends StatefulWidget {
  const SignupWithPaymentScreen({super.key});

  @override
  State<SignupWithPaymentScreen> createState() =>
      _SignupWithPaymentScreenState();
}

class _SignupWithPaymentScreenState extends State<SignupWithPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  bool _isEmailFocused = false;
  String? _errorMessage;

  Map<String, dynamic>? _selectedPlan;

  bool _showPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(() {
      setState(() {
        _isEmailFocused = _emailFocusNode.hasFocus;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // احنا بنستلم الخطة عبر extra من الراوتر
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _selectedPlan = extra?['plan'] as Map<String, dynamic>?;

    if (_selectedPlan == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go('/plans');
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPlan == null) {
      setState(() => _errorMessage = 'يرجى اختيار خطة اشتراك أولاً');
      return;
    }

    setState(() => _errorMessage = null);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    authProvider.setLoading(true);

    try {
      // Support both `_id` and `id` keys from the plans API
      final selectedPlanId =
          (_selectedPlan!['_id'] ?? _selectedPlan!['id'] ?? '').toString();

      final success = await authProvider.createPendingUser(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        planId: selectedPlanId,
        manageLoading: false,
      );

      if (success && mounted) {
        final checkoutUrl =
            await authProvider.createCheckoutSession(selectedPlanId);
        // Stop loading before navigation
        authProvider.setLoading(false);
        if (!mounted) return;

        // Always navigate to payment; it will show error UI if url is null
        if (checkoutUrl != null) {
          context.go('/payment', extra: {'url': checkoutUrl});
        } else {
          context.go('/payment');
        }
        return;
      } else if (mounted) {
        authProvider.setLoading(false);
        setState(() {
          _errorMessage = authProvider.error ?? 'حدث خطأ غير متوقع';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _errorMessage = null);
        });
      }
    } catch (e) {
      if (mounted) {
        authProvider.setLoading(false);
        setState(() {
          _errorMessage = 'حدث خطأ غير متوقع: ${e.toString()}';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _errorMessage = null);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // لو الخطة مش موجودة لسه، نعرض مؤشر تحميل قصير
    if (_selectedPlan == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0A84FF)),
        ),
      );
    }

    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return GradientDecoratedBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: LoadingOverlay(
                isLoading: authProvider.isLoading,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 40),

                        // Selected Plan Info (كما في كودك الأصلي)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF0A84FF),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'الخطة المختارة',
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _selectedPlan!['title'] ?? 'خطة غير محددة',
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${_selectedPlan!['price'] ?? '0.00'} دينار كويتي',
                                    style: const TextStyle(
                                      color: Color(0xFF0A84FF),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () => context.go('/plans'),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Color(0xFF0A84FF),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Logo + Title زي صفحة الـ Login
                        const Icon(
                          Icons.school,
                          size: 80,
                          color: Color(0xFF0A84FF),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'إنشاء حساب جديد',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'أدخل بياناتك لإنشاء حساب جديد',
                          style: TextStyle(
                            color: Color(0xFFB0B0B0),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 32),

                        // Name
                        CustomTextField(
                          controller: _nameController,
                          hintText: 'الاسم الكامل',
                          prefixIcon: const Icon(Icons.person_outline,
                              color: Color(0xFFB0B0B0)),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'الاسم مطلوب';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email with helper when focused
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_isEmailFocused)
                              Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color:
                                      const Color(0xFF0A84FF).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: const Color(0xFF0A84FF)
                                          .withOpacity(0.3)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Color(0xFF0A84FF), size: 16),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'الرجاء استخدام حساب جيميل مفعل',
                                        style: TextStyle(
                                          color: Color(0xFF0A84FF),
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            CustomTextField(
                              controller: _emailController,
                              focusNode: _emailFocusNode,
                              hintText: 'البريد الإلكتروني',
                              prefixIcon: const Icon(Icons.email_outlined,
                                  color: Color(0xFFB0B0B0)),
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty)
                                  return 'البريد الإلكتروني مطلوب';
                                if (!value.contains('@'))
                                  return 'البريد الإلكتروني غير صحيح';
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Phone
                        CustomTextField(
                          controller: _phoneController,
                          hintText: 'رقم الهاتف',
                          prefixIcon: const Icon(Icons.phone_outlined,
                              color: Color(0xFFB0B0B0)),
                          keyboardType: TextInputType.phone,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty)
                              return 'رقم الهاتف مطلوب';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'كلمة المرور',
                          obscureText: !_showPassword,
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFFB0B0B0)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFFB0B0B0),
                            ),
                            onPressed: () {
                              setState(() {
                                _showPassword = !_showPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'كلمة المرور مطلوبة';
                            if (value.length < 6)
                              return 'يجب أن تكون 6 أحرف على الأقل';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        CustomTextField(
                          controller: _confirmPasswordController,
                          hintText: 'تأكيد كلمة المرور',
                          obscureText: !_showConfirmPassword,
                          prefixIcon: const Icon(Icons.lock_outline,
                              color: Color(0xFFB0B0B0)),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showConfirmPassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: const Color(0xFFB0B0B0),
                            ),
                            onPressed: () {
                              setState(() {
                                _showConfirmPassword = !_showConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'تأكيد كلمة المرور مطلوب';
                            if (value != _passwordController.text)
                              return 'كلمة المرور غير متطابقة';
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        // Error message
                        if (_errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red[400], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                        color: Colors.red[400],
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Signup button
                        CustomButton(
                          text: 'إنشاء الحساب',
                          onPressed: _handleSignup,
                          isLoading: authProvider.isLoading,
                          backgroundGradient: const LinearGradient(
                            colors: [Color(0xFF0A84FF), Color(0xFF007AFF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('لديك حساب بالفعل؟ ',
                                style: TextStyle(
                                    color: Color(0xFFB0B0B0), fontSize: 16)),
                            TextButton(
                                onPressed: () => context.go('/login'),
                                child: const Text('تسجيل الدخول',
                                    style: TextStyle(
                                        color: Color(0xFF0A84FF),
                                        fontWeight: FontWeight.w600))),
                          ],
                        ),

                        const SizedBox(
                            height: 60), // Extra space for better scrolling
                      ],
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
}

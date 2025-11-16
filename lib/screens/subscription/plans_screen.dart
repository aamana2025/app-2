import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/plan_card.dart';
import '../../widgets/loading_overlay.dart';
import '../../widgets/gradient_bg.dart';

class PlansScreen extends StatefulWidget {
  const PlansScreen({super.key});

  @override
  State<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends State<PlansScreen> {
  List<Map<String, dynamic>> _plans = [];
  bool _isLoading = true;
  String? _selectedPlanId;
  Map<String, dynamic>? _selectedPlan;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final plans = await authProvider.getPlans();

    if (mounted) {
      setState(() {
        _plans = plans.cast<Map<String, dynamic>>();
        _isLoading = false;
      });
    }
  }

  void _selectPlan(Map<String, dynamic> plan) {
    final planId = plan['id']?.toString() ??
        plan['_id']?.toString() ??
        plan['planId']?.toString();
    setState(() {
      _selectedPlanId = planId;
      _selectedPlan = plan;
    });
  }

  void _proceed() {
    if (_selectedPlan == null) return;
    context.go('/signup', extra: {'plan': _selectedPlan});
  }

  @override
  Widget build(BuildContext context) {
    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            child: FloatingActionButton.extended(
              onPressed: _selectedPlanId != null ? _proceed : null,
              backgroundColor: _selectedPlanId != null
                  ? const Color(0xFF0A84FF)
                  : Colors.grey,
              foregroundColor: Colors.white,
              elevation: 2,
              label: const Text(
                'متابعة إنشاء الحساب',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => context.go('/login'),
          ),
          title: const Text(
            'اختر خطة الاشتراك',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: LoadingOverlay(
          isLoading: _isLoading,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  const Text(
                    'اختر الخطة المناسبة لك',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'جميع الخطط تشمل وصول كامل للمحتوى والدعم الفني',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 40),

                  // Plans List
                  if (_plans.isNotEmpty)
                    ..._plans.asMap().entries.map((entry) {
                      final index = entry.key;
                      final plan = entry.value;
                      final planId = plan['id']?.toString() ??
                          plan['_id']?.toString() ??
                          plan['planId']?.toString() ??
                          index.toString();
                      final isSelected = _selectedPlanId == planId;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: PlanCard(
                          plan: plan,
                          isSelected: isSelected,
                          onTap: () => _selectPlan(plan),
                        ),
                      );
                    })
                  else if (!_isLoading)
                    Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.grey[400],
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد خطط متاحة حالياً',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadPlans,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0A84FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('إعادة المحاولة'),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Back Button
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'العودة لتسجيل الدخول',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

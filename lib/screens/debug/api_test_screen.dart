import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../widgets/gradient_bg.dart';

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _testResult = 'لم يتم الاختبار بعد';
  bool _isLoading = false;

  Future<void> _testApiConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'جاري اختبار الاتصال...';
    });

    try {
      // Use the same base URL as ApiService
      const baseUrl = 'https://class-room-backend-nodejs.vercel.app';

      // Test plans API with correct URL
      final response = await http.get(
        Uri.parse('$baseUrl/api/plans/'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      String result = 'الاستجابة: ${response.statusCode}\n';
      result += 'المحتوى: ${response.body}\n\n';

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          if (data is Map<String, dynamic> && data.containsKey('plans')) {
            final plans = data['plans'] as List<dynamic>;
            result += 'عدد الخطط: ${plans.length}\n';
            for (int i = 0; i < plans.length; i++) {
              final plan = plans[i] as Map<String, dynamic>;
              result +=
                  'الخطة ${i + 1}: ${plan['title']} - \$${plan['price']}\n';
            }
          } else {
            result += 'تنسيق الاستجابة غير صحيح';
          }
        } catch (e) {
          result += 'خطأ في تحليل JSON: $e';
        }
      }

      setState(() {
        _testResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _testResult = 'خطأ في الاتصال: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientDecoratedBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('اختبار API'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _testApiConnection,
                child: Text(_isLoading ? 'جاري الاختبار...' : 'اختبار الاتصال'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _testResult,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

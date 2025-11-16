import 'package:flutter/material.dart';
import '../services/api_service.dart';

class SubscriptionProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _selectedPlan;
  bool _isPaymentProcessing = false;
  String? _error;
  String? _paymentSuccess;

  // Getters
  bool get isLoading => _isLoading;
  List<Map<String, dynamic>> get plans => _plans;
  Map<String, dynamic>? get selectedPlan => _selectedPlan;
  bool get isPaymentProcessing => _isPaymentProcessing;
  String? get error => _error;
  String? get paymentSuccess => _paymentSuccess;

  // Load Plans
  Future<void> loadPlans() async {
    _setLoading(true);
    _clearError();

    try {
      final plans = await _apiService.getPlans();
      _plans = plans.cast<Map<String, dynamic>>();
      _setLoading(false);
    } catch (e) {
      _setError(e.toString());
      _setLoading(false);
    }
  }

  // Select Plan
  void selectPlan(Map<String, dynamic> plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  // Process Payment
  Future<bool> processPayment({
    required String cardNumber,
    required String expiryDate,
    required String cvv,
    required String cardholderName,
  }) async {
    if (_selectedPlan == null) {
      _setError('يرجى اختيار خطة أولاً');
      return false;
    }

    _setPaymentProcessing(true);
    _clearError();
    _clearPaymentSuccess();

    try {
      final response = await _apiService.payWithStripe(
        planId: _selectedPlan!['id'],
        cardNumber: cardNumber,
        expiryDate: expiryDate,
        cvv: cvv,
        cardholderName: cardholderName,
      );

      if (response['success'] == true) {
        _setPaymentSuccess(response['message']);
        _setPaymentProcessing(false);
        return true;
      } else {
        _setError(response['message'] ?? 'فشل في معالجة الدفع');
        _setPaymentProcessing(false);
        return false;
      }
    } catch (e) {
      _setError(e.toString());
      _setPaymentProcessing(false);
      return false;
    }
  }

  // Clear selected plan
  void clearSelectedPlan() {
    _selectedPlan = null;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setPaymentProcessing(bool processing) {
    _isPaymentProcessing = processing;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _setPaymentSuccess(String message) {
    _paymentSuccess = message;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void _clearPaymentSuccess() {
    _paymentSuccess = null;
    notifyListeners();
  }
}

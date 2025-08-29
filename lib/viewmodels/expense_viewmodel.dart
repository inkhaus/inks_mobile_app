import 'package:flutter/material.dart';
import 'package:inkhaus/models/expense_model.dart';
import 'package:inkhaus/services/api_service.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<ExpenseModel> _expenses = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Getters
  List<ExpenseModel> get expenses => _expenses;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  double get totalExpenses {
    return _expenses.fold(0, (sum, expense) => sum + expense.amount);
  }
  
  // Load all expenses
  Future<void> loadExpenses({int skip = 0, int limit = 100}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _expenses = await _apiService.getAllExpenses(skip: skip, limit: limit);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Load more expenses (pagination)
  Future<void> loadMoreExpenses({int skip = 0, int limit = 100}) async {
    try {
      final moreExpenses = await _apiService.getAllExpenses(skip: skip, limit: limit);
      _expenses.addAll(moreExpenses);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Create expense
  Future<ExpenseModel?> createExpense({
    required double amount,
    required String category,
    required String evidence,
    required String notes,
    required PayeeModel payee,
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      
      final expense = ExpenseModel(
        amount: amount,
        category: category,
        evidence: evidence,
        notes: notes,
        payee: payee,
        createdAt: now,
      );
      
      final createdExpense = await _apiService.createExpense(expense);
      _isLoading = false;
      notifyListeners();
      
      // Add the new expense to the local list
      _expenses.insert(0, createdExpense);
      notifyListeners();
      
      return createdExpense;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
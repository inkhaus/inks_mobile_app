import 'package:flutter/material.dart';
import 'package:inkhaus/models/user_model.dart';
import 'package:inkhaus/services/user_service.dart';

class AuthViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Sign up user
  Future<UserModel?> signUp(String email, String password, String accountType) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _userService.registerUser(email, password, accountType);
      _isLoading = false;
      notifyListeners();
      return user;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return null;
    }
  }

  // Login user
  Future<UserModel?> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = await _userService.loginUser(email, password);
      _isLoading = false;
      notifyListeners();
      return user;
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
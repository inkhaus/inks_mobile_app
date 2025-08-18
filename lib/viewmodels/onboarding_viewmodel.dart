import 'package:flutter/material.dart';
import 'package:inkhaus/services/user_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  final UserService _userService = UserService();
  int _currentPage = 0;
  bool _isLoading = false;

  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;

  void setCurrentPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  Future<bool> checkUserLoggedIn() async {
    _isLoading = true;
    notifyListeners();
    
    final isLoggedIn = await _userService.isUserLoggedIn();
    
    _isLoading = false;
    notifyListeners();
    
    return isLoggedIn;
  }
}
import 'package:inkhaus/core/constants.dart';
import 'package:inkhaus/models/user_model.dart';
import 'package:inkhaus/services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final ApiService _apiService = ApiService();
  
  // Save user session data
  Future<void> saveUserSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.userIdKey, user.id ?? '');
    await prefs.setString(AppConstants.userEmailKey, user.email);
    await prefs.setString(AppConstants.userAccountTypeKey, user.accountType);
  }
  
  // Check if user is logged in
  Future<bool> isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(AppConstants.userIdKey) && 
           prefs.getString(AppConstants.userIdKey)?.isNotEmpty == true;
  }
  
  // Get current user data
  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(AppConstants.userIdKey);
    final userEmail = prefs.getString(AppConstants.userEmailKey);
    final userAccountType = prefs.getString(AppConstants.userAccountTypeKey);
    
    if (userId == null || userEmail == null || userAccountType == null) {
      return null;
    }
    
    return UserModel(
      id: userId,
      email: userEmail,
      accountType: userAccountType,
      createdAt: '',
    );
  }
  
  // Login user
  Future<UserModel> loginUser(String email, String password) async {
    final user = await _apiService.loginUser(email, password);
    await saveUserSession(user);
    return user;
  }
  
  // Register user
  Future<UserModel> registerUser(String email, String password, String accountType) async {
    final now = DateTime.now().toUtc().toIso8601String();
    final userModel = UserModel(
      email: email,
      accountType: accountType.toLowerCase(),
      createdAt: now,
      password: password,
    );
    
    final registeredUser = await _apiService.registerUser(userModel);
    await saveUserSession(registeredUser);
    return registeredUser;
  }
  
  // Logout user
  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.userEmailKey);
    await prefs.remove(AppConstants.userAccountTypeKey);
  }
}
class AppConstants {
  static const String baseUrl = 'http://18.196.248.228:8000';
  static const String apiVersion = '/v1';
  
  // API Endpoints
  static const String loginEndpoint = '$apiVersion/users/login';
  static const String signupEndpoint = '$apiVersion/users/';
  static const String usersEndpoint = '$apiVersion/users/';
  static const String productsEndpoint = '$apiVersion/products/';
  static const String salesEndpoint = '$apiVersion/sales/';
  static const String enquiriesEndpoint = '$apiVersion/enquiries/';
  static const String appointmentsEndpoint = '$apiVersion/appointments/';
  static const String expensesEndpoint = '$apiVersion/expenses/';
  
  // SharedPreferences Keys
  static const String userIdKey = 'user_id';
  static const String userEmailKey = 'user_email';
  static const String userAccountTypeKey = 'user_account_type';
}
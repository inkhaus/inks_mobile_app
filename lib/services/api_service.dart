import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:inkhaus/core/constants.dart';
import 'package:inkhaus/models/user_model.dart';
import 'package:inkhaus/models/product_model.dart';
import 'package:inkhaus/models/sales_model.dart';
import 'package:inkhaus/models/enquiry_model.dart';
import 'package:inkhaus/models/appointment_model.dart';

class ApiService {
  final Dio _dio = Dio(BaseOptions(
    baseUrl: AppConstants.baseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
    contentType: 'application/json',
  ));

  // Login user
  Future<UserModel> loginUser(String email, String password) async {
    try {
      final response = await _dio.post(
        AppConstants.loginEndpoint,
        data: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Login failed');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  // Register user
  Future<UserModel> registerUser(UserModel user) async {
    try {
      final response = await _dio.post(
        AppConstants.signupEndpoint,
        data: jsonEncode(user.toJson()),
      );
      
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Registration failed');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final response = await _dio.post(AppConstants.usersEndpoint);
      
      return (response.data as List)
          .map((user) => UserModel.fromJson(user))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to get users');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Create product
  Future<ProductModel> createProduct(ProductModel product) async {
    try {
      final response = await _dio.post(
        AppConstants.productsEndpoint,
        data: jsonEncode(product.toJson()),
      );
      
      return ProductModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to create product');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Get all products
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final response = await _dio.get(AppConstants.productsEndpoint);
      
      return (response.data as List)
          .map((product) => ProductModel.fromJson(product))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to get products');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Create sale
  Future<SalesModel> createSale(SalesModel sale) async {
    try {
      final response = await _dio.post(
        AppConstants.salesEndpoint,
        data: jsonEncode(sale.toJson()),
      );
      
      return SalesModel.fromJson(response.data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to create sale');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Get all sales with pagination
  Future<List<SalesModel>> getAllSales({int skip = 0, int limit = 100}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.salesEndpoint}?skip=$skip&limit=$limit',
      );
      
      return (response.data as List)
          .map((sale) => SalesModel.fromJson(sale))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to get sales');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Search sales by date range
  Future<List<SalesModel>> searchSales({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final startDateStr = Uri.encodeComponent(startDate.toIso8601String());
      final endDateStr = Uri.encodeComponent(endDate.toIso8601String());
      
      final response = await _dio.get(
        '${AppConstants.salesEndpoint}search?start_date=$startDateStr&end_date=$endDateStr',
      );
      
      return (response.data as List)
          .map((sale) => SalesModel.fromJson(sale))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to search sales');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Get all enquiries with pagination
  Future<List<EnquiryModel>> getAllEnquiries({int skip = 0, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.enquiriesEndpoint}?skip=$skip&limit=$limit',
      );
      
      return (response.data as List)
          .map((enquiry) => EnquiryModel.fromJson(enquiry))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to get enquiries');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
  
  // Get all appointments with pagination
  Future<List<AppointmentModel>> getAllAppointments({int skip = 0, int limit = 10}) async {
    try {
      final response = await _dio.get(
        '${AppConstants.appointmentsEndpoint}?skip=$skip&limit=$limit',
      );
      
      return (response.data as List)
          .map((appointment) => AppointmentModel.fromJson(appointment))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to get appointments');
      } else {
        throw Exception('Network error occurred. Please check your connection.');
      }
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
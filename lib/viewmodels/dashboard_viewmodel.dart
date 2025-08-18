import 'package:flutter/material.dart';
import 'package:inkhaus/models/product_model.dart';
import 'package:inkhaus/models/sales_model.dart';
import 'package:inkhaus/models/enquiry_model.dart';
import 'package:inkhaus/services/api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<ProductModel> _products = [];
  List<SalesModel> _todaySales = [];
  List<SalesModel> _recentSales = [];
  Map<String, List<SalesModel>> _weeklySales = {};
  List<EnquiryModel> _pendingEnquiries = [];
  
  bool _isLoadingProducts = false;
  bool _isLoadingSales = false;
  bool _isLoadingEnquiries = false;
  String _errorMessage = '';
  
  // Getters
  List<ProductModel> get products => _products;
  List<SalesModel> get todaySales => _todaySales;
  List<SalesModel> get recentSales => _recentSales;
  Map<String, List<SalesModel>> get weeklySales => _weeklySales;
  List<EnquiryModel> get pendingEnquiries => _pendingEnquiries;
  
  bool get isLoadingProducts => _isLoadingProducts;
  bool get isLoadingSales => _isLoadingSales;
  bool get isLoadingEnquiries => _isLoadingEnquiries;
  bool get isLoading => _isLoadingProducts || _isLoadingSales || _isLoadingEnquiries;
  String get errorMessage => _errorMessage;
  
  int get productCount => _products.length;
  
  int get todaySalesCount => _todaySales.length;
  
  int get pendingEnquiriesCount => _pendingEnquiries.length;
  
  double get todayTotalSales {
    return _todaySales.fold(0, (sum, sale) => sum + sale.totalPrice);
  }
  
  // Load products
  Future<void> loadProducts() async {
    _isLoadingProducts = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _products = await _apiService.getAllProducts();
      _isLoadingProducts = false;
      notifyListeners();
    } catch (e) {
      _isLoadingProducts = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Load today's sales
  Future<void> loadTodaySales() async {
    _isLoadingSales = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);
      
      _todaySales = await _apiService.searchSales(
        startDate: startOfDay,
        endDate: endOfDay,
      );
      
      // Get the 5 most recent sales
      _recentSales = List.from(_todaySales)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      if (_recentSales.length > 5) {
        _recentSales = _recentSales.sublist(0, 5);
      }
      
      _isLoadingSales = false;
      notifyListeners();
    } catch (e) {
      _isLoadingSales = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Load weekly sales data for the chart
  Future<void> loadWeeklySales() async {
    _isLoadingSales = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final now = DateTime.now();
      final endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final startDate = endDate.subtract(const Duration(days: 6));
      
      final sales = await _apiService.searchSales(
        startDate: startDate,
        endDate: endDate,
      );
      
      // Group sales by day
      _weeklySales = {};
      for (int i = 0; i <= 6; i++) {
        final date = endDate.subtract(Duration(days: i));
        final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        _weeklySales[dateStr] = [];
      }
      
      for (final sale in sales) {
        final saleDate = DateTime.parse(sale.createdAt);
        final dateStr = '${saleDate.year}-${saleDate.month.toString().padLeft(2, '0')}-${saleDate.day.toString().padLeft(2, '0')}';
        
        if (_weeklySales.containsKey(dateStr)) {
          _weeklySales[dateStr]!.add(sale);
        }
      }
      
      _isLoadingSales = false;
      notifyListeners();
    } catch (e) {
      _isLoadingSales = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Load pending enquiries
  Future<void> loadPendingEnquiries() async {
    _isLoadingEnquiries = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final allEnquiries = await _apiService.getAllEnquiries(skip: 0, limit: 100);
      // Filter for enquiries from last 7 days with pending_response status
      final now = DateTime.now();
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      
      _pendingEnquiries = allEnquiries.where((enquiry) {
        final enquiryDate = DateTime.parse(enquiry.createdAt);
        return enquiryDate.isAfter(sevenDaysAgo) && enquiry.status == 'pending_response';
      }).toList();
      
      _isLoadingEnquiries = false;
      notifyListeners();
    } catch (e) {
      _isLoadingEnquiries = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Load all dashboard data
  Future<void> loadDashboardData() async {
    await loadProducts();
    await loadTodaySales();
    await loadWeeklySales();
    await loadPendingEnquiries();
  }
  
  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }
}
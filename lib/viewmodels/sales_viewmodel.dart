import 'package:flutter/material.dart';
import 'package:inkhaus/models/product_model.dart';
import 'package:inkhaus/models/sales_model.dart';
import 'package:inkhaus/services/api_service.dart';

class SalesViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<ProductModel> _products = [];
  List<SalesModel> _sales = [];
  List<ProductModel> _cartItems = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Getters
  List<ProductModel> get products => _products;
  List<SalesModel> get sales => _sales;
  List<ProductModel> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  
  double get cartTotal {
    return _cartItems.fold(0, (sum, item) => sum + item.unitPrice);
  }
  
  // Load products
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _products = await _apiService.getAllProducts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Load sales
  Future<void> loadSales({int skip = 0, int limit = 100}) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _sales = await _apiService.getAllSales(skip: skip, limit: limit);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Load more sales (pagination)
  Future<void> loadMoreSales({int skip = 0, int limit = 100}) async {
    try {
      final moreSales = await _apiService.getAllSales(skip: skip, limit: limit);
      _sales.addAll(moreSales);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Search sales by date range
  Future<void> searchSales(DateTime startDate, DateTime endDate) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      _sales = await _apiService.searchSales(
        startDate: startDate,
        endDate: endDate,
      );
      print('sales: ${_sales.length}');
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
    }
  }
  
  // Add item to cart
  void addToCart(ProductModel product) {
    _cartItems.add(product);
    notifyListeners();
  }
  
  // Remove item from cart
  void removeFromCart(ProductModel product) {
    _cartItems.remove(product);
    notifyListeners();
  }
  
  // Clear cart
  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }
  
  // Create sale
  Future<SalesModel?> createSale({
    required List<SalesEntryModel> entries,
    required CustomerModel customer,
    required String paymentChannel,
    required String recordedBy,
    String note = '',
  }) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();
    
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final totalPrice = entries.fold(
        0.0, 
        (sum, entry) => sum + (entry.unitPrice * entry.quantity)
      );
      
      final sale = SalesModel(
        entries: entries,
        customer: customer,
        totalPrice: totalPrice,
        paymentChannel: paymentChannel,
        createdAt: now,
        recordedBy: recordedBy,
        note: note,
      );
      
      final createdSale = await _apiService.createSale(sale);
      _isLoading = false;
      notifyListeners();
      
      // Clear cart after successful sale
      clearCart();
      
      return createdSale;
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
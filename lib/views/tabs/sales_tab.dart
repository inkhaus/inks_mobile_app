import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkhaus/models/product_model.dart';
import 'package:inkhaus/models/sales_model.dart';
import 'package:inkhaus/services/user_service.dart';
import 'package:inkhaus/services/api_service.dart';
import 'package:inkhaus/viewmodels/sales_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SalesTab extends StatefulWidget {
  const SalesTab({super.key});

  @override
  State<SalesTab> createState() => _SalesTabState();
}

class _SalesTabState extends State<SalesTab>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService();
  final ApiService _apiService = ApiService();
  String _userEmail = '';
  String _searchQuery = '';
  String _accountType = '';
  List<SalesModel> _filteredSales = [];
  DateTime? _startDate;
  DateTime? _endDate;
  late TabController _tabController;
  final ScrollController _salesScrollController = ScrollController();
  bool _isLoadingMore = false;
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
      _loadSales();
    });

    // Setup scroll listener for pagination
    _salesScrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _salesScrollController.removeListener(_scrollListener);
    _salesScrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_salesScrollController.position.pixels >=
            _salesScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMore) {
      _loadMoreSales();
    }
  }

  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    if (user != null && mounted) {
      setState(() {
        _userEmail = user.email;
        _accountType = user.accountType;
      });
    }
  }

  Future<void> _loadProducts() async {
    final salesViewModel = Provider.of<SalesViewModel>(context, listen: false);
    await salesViewModel.loadProducts();
  }

  Future<void> _loadSales() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    final salesViewModel = Provider.of<SalesViewModel>(context, listen: false);
    await salesViewModel.loadSales(skip: 0, limit: _pageSize);
    _currentPage = 1;
    _filterSales();

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
    });
  }

  void _filterSales() {
    final salesViewModel = Provider.of<SalesViewModel>(context, listen: false);
    if (_searchQuery.isEmpty && _startDate == null && _endDate == null) {
      _filteredSales = List.from(salesViewModel.sales);
    } else {
      _filteredSales = salesViewModel.sales.where((sale) {
        bool matchesSearch = true;
        bool matchesDate = true;

        // Text search
        if (_searchQuery.isNotEmpty) {
          final searchLower = _searchQuery.toLowerCase();
          matchesSearch =
              sale.id?.toLowerCase().contains(searchLower) == true ||
              sale.customer.fullname.toLowerCase().contains(searchLower) ||
              sale.paymentChannel.toLowerCase().contains(searchLower) ||
              sale.entries.any(
                (entry) => entry.service.toLowerCase().contains(searchLower),
              );
        }

        // Date filter
        if (_startDate != null || _endDate != null) {
          final saleDate = DateTime.parse(sale.createdAt);
          if (_startDate != null && saleDate.isBefore(_startDate!)) {
            matchesDate = false;
          }
          if (_endDate != null && saleDate.isAfter(_endDate!)) {
            matchesDate = false;
          }
        }

        return matchesSearch && matchesDate;
      }).toList();
    }
  }

  Future<void> _loadMoreSales() async {
    if (!mounted) return;
    setState(() {
      _isLoadingMore = true;
    });

    final salesViewModel = Provider.of<SalesViewModel>(context, listen: false);
    await salesViewModel.loadMoreSales(
      skip: _currentPage * _pageSize,
      limit: _pageSize,
    );
    _currentPage++;
    _filterSales();

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshProducts() async {
  await _loadProducts();
}

Future<void> _refreshSales() async {
  setState(() {
    _currentPage = 0;
    _filteredSales.clear();
  });
  await _loadSales();
}

  List<String> paymentChannels = ['Cash', 'Mobile Money', 'Bank Transfer'];
  Map<String, String> paymentChannelsMap = {
    'Cash': 'cash',
    'Mobile Money': 'mobile_money',
    'Bank Transfer': 'bank_transfer',
  };
  String? selectedPaymentChannel;
  TextEditingController customerNameController = TextEditingController();
  TextEditingController customerPhoneNumberController = TextEditingController();
  TextEditingController customerEmailController = TextEditingController();

  int currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sales',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          // if (currentTab == 1) // Only show search on Sales History tab
          //   IconButton(
          //     icon: const Icon(Icons.search),
          //     onPressed: () => _showSearchBottomSheet(),
          //   ),
          // if (currentTab == 1) // Only show date filter on Sales History tab
          //   IconButton(
          //     icon: const Icon(Icons.filter_list),
          //     onPressed: () => _showDateFilterBottomSheet(),
          //   ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            if (index == 1) {
              _filterSales(); // Refresh filtered sales when switching to Sales History

              setState(() {
                currentTab = 1;
              });
            } else {
              setState(() {
                currentTab = 0;
              });
            }
          },
          tabs: const [
            Tab(text: 'Products'),
            Tab(text: 'Sales History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Products Tab
          Column(
            children: [
              Expanded(
                child: RefreshIndicator(onRefresh: _refreshProducts, child: Consumer<SalesViewModel>(
                  builder: (context, salesViewModel, child) {
                    if (salesViewModel.isLoading &&
                        salesViewModel.products.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (salesViewModel.errorMessage.isNotEmpty &&
                        salesViewModel.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Error: ${salesViewModel.errorMessage}',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => salesViewModel.loadProducts(),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    if (salesViewModel.products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No products available',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildProductGrid(salesViewModel.products);
                  },
                )),
              ),
            ],
          ),

          _buildSalesHistoryTab(),

          // Sales History Tab
        ],
      ),
      floatingActionButton: _accountType != 'admin' && _tabController.index == 0 ?null : FloatingActionButton(
        onPressed: () {
          if (_tabController.index == 0) {
            _showAddProductBottomSheet();
          } else {
            _showAddSaleBottomSheet(context);
          }
        },
        backgroundColor: Colors.blue[700],
        child: Icon(
          _tabController.index == 0
              ? Icons.add_business
              : Icons.add_shopping_cart,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(15),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: Container(
              height: 80,
              width: double.infinity,
              color: Colors.grey[200],
              child: product.artworkUrl.isNotEmpty
                  ? Image.network(
                      product.artworkUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.image_not_supported,
                        size: 50,
                        color: Colors.grey[400],
                      ),
                    )
                  : Icon(Icons.image, size: 50, color: Colors.grey[400]),
            ),
          ),

          // Product details
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                  '\$${product.unitPrice.toStringAsFixed(2)}',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  product.businessUnit,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesHistoryTab() {
    return RefreshIndicator(onRefresh: _refreshSales, child: Consumer<SalesViewModel>(
      builder: (context, salesViewModel, child) {
        // Use filtered sales if search is active, otherwise use all sales
        final displaySales =
            (_searchQuery.isNotEmpty || _startDate != null || _endDate != null)
            ? _filteredSales
            : salesViewModel.sales;

        if (salesViewModel.isLoading && salesViewModel.sales.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (salesViewModel.errorMessage.isNotEmpty &&
            salesViewModel.sales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Only show date filter on Sales History tab
                Text(
                  'Error: ${salesViewModel.errorMessage}',
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSales,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (displaySales.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () => _showDateFilterBottomSheet(),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          margin: const EdgeInsets.all(10),
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Text(
                                'Filter by date',
                                style: GoogleFonts.poppins(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                              IconButton(
                                iconSize: 20,
                                color: Colors.white,
                                icon: const Icon(Icons.filter_list),
                                onPressed: () => _showDateFilterBottomSheet(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(child: Container()),
                Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  _searchQuery.isNotEmpty ||
                          _startDate != null ||
                          _endDate != null
                      ? 'No sales found matching your criteria'
                      : 'No sales recorded yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                Expanded(child: Container()),
              ],
            ),
          );
        }

        return Column(
          children: [
            InkWell(
              onTap: () => _showDateFilterBottomSheet(),
              child: SizedBox(
                width: MediaQuery.of(context).size.width,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      margin: const EdgeInsets.all(10),
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.blue[700],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Filter by date',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            iconSize: 20,
                            color: Colors.white,
                            icon: const Icon(Icons.filter_list),
                            onPressed: () => _showDateFilterBottomSheet(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Expanded(
              child: ListView.builder(
                controller: _salesScrollController,
                padding: const EdgeInsets.all(15),
                itemCount: displaySales.length + (_isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == displaySales.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final sale = displaySales[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    child: ListTile(
                      title: Text(
                        sale.id != null
                            ? 'Order #${sale.id!.substring(0, 8)}'
                            : 'Order',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(DateTime.parse(sale.createdAt).toLocal()),
                            style: GoogleFonts.poppins(fontSize: 12),
                          ),
                          Text(
                            '${sale.entries.length} item(s) - \$${sale.totalPrice.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => _showSaleDetailsBottomSheet(context, sale),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    ));
  }

  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // Handle the case where the phone app cannot be launched
      Fluttertoast.showToast(
        msg: 'Could not launch $phoneNumber',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
    }
  }

  void _showSaleDetailsBottomSheet(BuildContext context, SalesModel sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Sale Details',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    Text(
                      sale.id != null
                          ? 'Order #${sale.id!.substring(0, 8)}'
                          : 'Order',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(sale.createdAt).toLocal())}',
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Customer: ${sale.customer.fullname}',
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Email: ${sale.customer.email}',
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Payment Channel: ${sale.paymentChannel}',
                      style: GoogleFonts.poppins(),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Recorded By: ${sale.recordedBy}",
                      style: GoogleFonts.poppins(),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Items:',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    const Divider(),
                    ...sale.entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                entry.service,
                                style: GoogleFonts.poppins(),
                              ),
                            ),
                            Text(
                              '${entry.quantity} x GHS ${entry.unitPrice.toStringAsFixed(2)}',
                              style: GoogleFonts.poppins(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'GHS ${sale.totalPrice.toStringAsFixed(2)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Close button
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () => makePhoneCall(sale.customer.phoneNumber),
                child: Container(
                  height: 56,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
                        spreadRadius: 0,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        spreadRadius: 0,
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => makePhoneCall(sale.customer.phoneNumber),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone, color: Colors.white, size: 24),
                            Text(
                              " Call Customer",
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
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

  void _showAddProductBottomSheet() {
    final formKey = GlobalKey<FormState>();
    String title = '';
    String description = '';
    double unitPrice = 0.0;
    String artworkUrl = '';
    String businessUnit = '';

    final businessUnits = ['inkhaus', 'snaphaus'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => StatefulBuilder(
            builder: (context, setState) => Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  Text(
                    'Add New Product',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Form content
                  Expanded(
                    child: Form(
                      key: formKey,
                      child: ListView(
                        controller: scrollController,
                        children: [
                          // Product title
                          Text(
                            'Product Title',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              hintText: 'Enter product title',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a product title';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              title = value!;
                            },
                          ),

                          const SizedBox(height: 16),

                          // Description
                          Text(
                            'Description',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            maxLines: 3,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              hintText: 'Enter product description',
                            ),
                            onSaved: (value) {
                              description = value ?? '';
                            },
                          ),

                          const SizedBox(height: 16),

                          // Unit price
                          Text(
                            'Unit Price (\$)',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              hintText: '0.00',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a unit price';
                              }
                              final price = double.tryParse(value);
                              if (price == null || price <= 0) {
                                return 'Please enter a valid price';
                              }
                              return null;
                            },
                            onSaved: (value) {
                              unitPrice = double.parse(value!);
                            },
                          ),

                          const SizedBox(height: 16),

                          // Business unit dropdown
                          Text(
                            'Business Unit',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: businessUnit.isEmpty ? null : businessUnit,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            hint: Text(
                              'Select business unit',
                              style: GoogleFonts.poppins(),
                            ),
                            items: businessUnits.map((unit) {
                              return DropdownMenuItem<String>(
                                value: unit,
                                child: Text(unit, style: GoogleFonts.poppins()),
                              );
                            }).toList(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please select a business unit';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              setState(() {
                                businessUnit = value!;
                              });
                            },
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text('Cancel', style: GoogleFonts.poppins()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            if (formKey.currentState!.validate()) {
                              formKey.currentState!.save();

                              try {
                                final product = ProductModel(
                                  title: title,
                                  description: description,
                                  unitPrice: unitPrice,
                                  artworkUrl: artworkUrl,
                                  businessUnit: businessUnit,
                                  createdAt: DateTime.now()
                                      .toUtc()
                                      .toIso8601String(),
                                );

                                await _apiService.createProduct(product);

                                Navigator.pop(context);
                                Fluttertoast.showToast(
                                  msg: 'Product created successfully!',
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.greenAccent,
                                  textColor: Colors.white,
                                );

                                // Refresh products list
                                _loadProducts();
                              } catch (e) {
                                Fluttertoast.showToast(
                                  msg: 'Failed to create product: $e',
                                  toastLength: Toast.LENGTH_LONG,
                                  gravity: ToastGravity.TOP,
                                  backgroundColor: Colors.red,
                                  textColor: Colors.white,
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Add Product',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddSaleBottomSheet(BuildContext context) {
    final salesViewModel = Provider.of<SalesViewModel>(context, listen: false);
    ProductModel? selectedProduct;
    int quantity = 1;
    double unitPrice = 0.0;
    double totalPrice = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) => StatefulBuilder(
            builder: (context, setState) {
              // Calculate total price whenever product or quantity changes
              totalPrice = (selectedProduct?.unitPrice ?? 0) * quantity;

              return Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Handle bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Add Sale',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Form content
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        children: [
                          // Product dropdown
                          Text(
                            'Service/Product',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<ProductModel>(
                            value: selectedProduct,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            hint: Text(
                              'Select a product',
                              style: GoogleFonts.poppins(),
                            ),
                            items: salesViewModel.products.map((product) {
                              return DropdownMenuItem<ProductModel>(
                                value: product,
                                child: Text(
                                  product.title,
                                  style: GoogleFonts.poppins(),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                selectedProduct = value;
                                unitPrice = value?.unitPrice ?? 0;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Customer Name
                          Text(
                            'Customer Name',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: customerNameController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Customer Phone Number
                          Text(
                            'Customer Phone Number',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: customerPhoneNumberController,
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(10),
                            ],
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Customer Email
                          Text(
                            'Customer Email',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: customerEmailController,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Quantity field
                          Text(
                            'Quantity',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            initialValue: quantity.toString(),
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                quantity = int.tryParse(value) ?? 1;
                                if (quantity < 1) quantity = 1;
                              });
                            },
                          ),

                          const SizedBox(height: 16),

                          // Payment Channel
                          Text(
                            'Payment Channel',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            onChanged: (value) {
                              setState(() {
                                selectedPaymentChannel = value;
                              });
                            },
                            items: paymentChannels.map((channel) {
                              return DropdownMenuItem<String>(
                                value: paymentChannelsMap[channel],
                                child: Text(channel),
                              );
                            }).toList(),
                            value: selectedPaymentChannel,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Unit price (read-only)
                          Text(
                            'Unit Price',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: '${unitPrice.toStringAsFixed(2)}',
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Total price (calculated)
                          Text(
                            'Total Price',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: '${totalPrice.toStringAsFixed(2)}',
                            ),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                          ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text('Cancel', style: GoogleFonts.poppins()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedProduct == null
                                ? null
                                : () async {
                                    // Create sale entry
                                    final nowIso = DateTime.now()
                                        .toUtc()
                                        .toIso8601String();
                                    final entry = SalesEntryModel(
                                      service: selectedProduct!.title,
                                      unitPrice: selectedProduct!.unitPrice,
                                      quantity: quantity,
                                      createdAt: nowIso,
                                    );

                                    // Create sale
                                    final result = await salesViewModel
                                        .createSale(
                                          entries: [entry],
                                          customer: CustomerModel(
                                            fullname: customerNameController
                                                .text
                                                .trim(),
                                            phoneNumber:
                                                customerPhoneNumberController
                                                    .text
                                                    .trim(),
                                            email: customerEmailController.text
                                                .trim(),
                                            createdAt: nowIso,
                                          ),
                                          paymentChannel:
                                              selectedPaymentChannel ?? 'cash',
                                          recordedBy: _userEmail,
                                        );

                                    if (result != null) {
                                      Navigator.pop(context);
                                      Fluttertoast.showToast(
                                        msg: 'Sale added successfully!',
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.TOP,
                                        backgroundColor: Colors.greenAccent,
                                        textColor: Colors.white,
                                      );

                                      // Refresh sales list
                                      _loadSales();
                                    } else {
                                      Fluttertoast.showToast(
                                        msg: salesViewModel.errorMessage,
                                        toastLength: Toast.LENGTH_LONG,
                                        gravity: ToastGravity.TOP,
                                        backgroundColor: Colors.red,
                                        textColor: Colors.white,
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedProduct == null
                                  ? Colors.grey
                                  : Colors.blue[700],
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: Text(
                              'Add Sale',
                              style: GoogleFonts.poppins(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _showSearchBottomSheet() {
    String tempSearchQuery = _searchQuery;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Search Sales',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 20),

              // Search field
              TextField(
                autofocus: true,
                decoration: InputDecoration(
                  hintText:
                      'Search by order ID, customer name, payment method, or service...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (value) {
                  tempSearchQuery = value;
                },
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _filterSales();
                        });
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text('Clear', style: GoogleFonts.poppins()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = tempSearchQuery;
                          _filterSales();
                        });
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Search',
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateFilterBottomSheet() {
    DateTime? tempStartDateTime = _startDate;
    DateTime? tempEndDateTime = _endDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // Added to handle keyboard overflow
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom:
                  MediaQuery.of(context).viewInsets.bottom +
                  20, // Handle keyboard
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  'Filter by Date & Time Range',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),

                // Start datetime picker
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      'Start Date & Time',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      tempStartDateTime != null
                          ? DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(tempStartDateTime!)
                          : 'Select start date & time',
                      style: GoogleFonts.poppins(
                        color: tempStartDateTime != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      // First pick the date
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempStartDateTime ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );

                      if (date != null) {
                        // Then pick the time
                        final time = await showTimePicker(
                          context: context,
                          initialTime: tempStartDateTime != null
                              ? TimeOfDay.fromDateTime(tempStartDateTime!)
                              : TimeOfDay.now(),
                        );

                        if (time != null) {
                          setState(() {
                            tempStartDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(height: 12),

                // End datetime picker
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      'End Date & Time',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      tempEndDateTime != null
                          ? DateFormat(
                              'MMM dd, yyyy - hh:mm a',
                            ).format(tempEndDateTime!)
                          : 'Select end date & time',
                      style: GoogleFonts.poppins(
                        color: tempEndDateTime != null
                            ? Colors.black
                            : Colors.grey[600],
                      ),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      // First pick the date
                      final date = await showDatePicker(
                        context: context,
                        initialDate: tempEndDateTime ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );

                      if (date != null) {
                        // Then pick the time
                        final time = await showTimePicker(
                          context: context,
                          initialTime: tempEndDateTime != null
                              ? TimeOfDay.fromDateTime(tempEndDateTime!)
                              : TimeOfDay.now(),
                        );

                        if (time != null) {
                          setState(() {
                            tempEndDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // Quick preset buttons
                Text(
                  'Quick Select',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),

                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickSelectButton('Today', () {
                        final now = DateTime.now();
                        setState(() {
                          tempStartDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            0,
                            0,
                          );
                          tempEndDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            23,
                            59,
                          );
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildQuickSelectButton('Yesterday', () {
                        final yesterday = DateTime.now().subtract(
                          const Duration(days: 1),
                        );
                        setState(() {
                          tempStartDateTime = DateTime(
                            yesterday.year,
                            yesterday.month,
                            yesterday.day,
                            0,
                            0,
                          );
                          tempEndDateTime = DateTime(
                            yesterday.year,
                            yesterday.month,
                            yesterday.day,
                            23,
                            59,
                          );
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildQuickSelectButton('Last 7 Days', () {
                        final now = DateTime.now();
                        final sevenDaysAgo = now.subtract(
                          const Duration(days: 7),
                        );
                        setState(() {
                          tempStartDateTime = DateTime(
                            sevenDaysAgo.year,
                            sevenDaysAgo.month,
                            sevenDaysAgo.day,
                            0,
                            0,
                          );
                          tempEndDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            23,
                            59,
                          );
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildQuickSelectButton('Last 30 Days', () {
                        final now = DateTime.now();
                        final thirtyDaysAgo = now.subtract(
                          const Duration(days: 30),
                        );
                        setState(() {
                          tempStartDateTime = DateTime(
                            thirtyDaysAgo.year,
                            thirtyDaysAgo.month,
                            thirtyDaysAgo.day,
                            0,
                            0,
                          );
                          tempEndDateTime = DateTime(
                            now.year,
                            now.month,
                            now.day,
                            23,
                            59,
                          );
                        });
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            tempStartDateTime = null;
                            tempEndDateTime = null;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Clear', style: GoogleFonts.poppins()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Cancel', style: GoogleFonts.poppins()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Validate that start time is before end time
                          if (tempStartDateTime != null &&
                              tempEndDateTime != null &&
                              tempStartDateTime!.isAfter(tempEndDateTime!)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Start date & time must be before end date & time',
                                  style: GoogleFonts.poppins(),
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          this.setState(() {
                            _startDate = tempStartDateTime;
                            _endDate = tempEndDateTime;
                          });
                          _filterSales();
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Apply',
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method for quick select buttons
  Widget _buildQuickSelectButton(String label, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: Colors.blue[300]!),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 12, color: Colors.blue[700]),
      ),
    );
  }
}



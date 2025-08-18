import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkhaus/services/user_service.dart';
import 'package:inkhaus/viewmodels/dashboard_viewmodel.dart';
import 'package:provider/provider.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({super.key});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final UserService _userService = UserService();
  String _userEmail = '';
  String _accountType = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDashboardData();
    });
  }

  Future<void> _loadUserData() async {
    final user = await _userService.getCurrentUser();
    if (user != null) {
      setState(() {
        _userEmail = user.email;
        _accountType = user.accountType;
      });
    }
  }
  
  Future<void> _loadDashboardData() async {
    final dashboardViewModel = Provider.of<DashboardViewModel>(context, listen: false);
    await dashboardViewModel.loadDashboardData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info
              Container(
                height: 150,
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 10,),
                    Text(
                      'Welcome back,',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _userEmail,
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _accountType.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quick stats
              Consumer<DashboardViewModel>(
                builder: (context, dashboardViewModel, child) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quick Stats',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (dashboardViewModel.isLoading)
                              const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildStatCard(
                              'Today\'s Sales',
                              'GHS ${dashboardViewModel.todayTotalSales.toStringAsFixed(2)}',
                              Colors.green[100]!,
                              Colors.green[700]!,
                              Icons.trending_up,
                            ),
                            const SizedBox(width: 15),
                            _buildStatCard(
                              'Sales Count',
                              dashboardViewModel.todaySalesCount.toString(),
                              Colors.orange[100]!,
                              Colors.orange[700]!,
                              Icons.receipt_long,
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            _buildStatCard(
                              'Products',
                              dashboardViewModel.productCount.toString(),
                              Colors.purple[100]!,
                              Colors.purple[700]!,
                              Icons.inventory_2,
                            ),
                            const SizedBox(width: 15),
                            _buildStatCard(
                              'Enquiries',
                              dashboardViewModel.pendingEnquiriesCount.toString(),
                              Colors.blue[100]!,
                              Colors.blue[700]!,
                              Icons.question_answer,
                              onTap: () {
                                // Navigate to enquiry page
                                final tabController = DefaultTabController.of(context);
                                if (tabController != null) {
                                  tabController.animateTo(2); // Navigate to Enquiry tab
                                }
                              },
                            ),
                          ],
                        ),
                        if (dashboardViewModel.errorMessage.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Text(
                              dashboardViewModel.errorMessage,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.red,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              
              // Recent sales
              Consumer<DashboardViewModel>(
                builder: (context, dashboardViewModel, child) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Sales',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // TextButton(
                            //   onPressed: () {
                            //     // Navigate to sales page
                            //     final tabController = DefaultTabController.of(context);
                            //     if (tabController != null) {
                            //       tabController.animateTo(1); // Navigate to Sales tab
                            //     }
                            //   },
                            //   child: Text(
                            //     'View All',
                            //     style: GoogleFonts.poppins(
                            //       color: Colors.blue[700],
                            //       fontWeight: FontWeight.w500,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        if (dashboardViewModel.isLoadingSales)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else if (dashboardViewModel.recentSales.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Text(
                                'No sales recorded today',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                            ),
                          )
                        else
                          ...dashboardViewModel.recentSales.map((sale) {
                            final date = DateTime.parse(sale.createdAt);
                            final formattedTime = '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
                            
                            return _buildActivityItem(
                              'Sale #${sale.id?.substring(0, 8) ?? 'New'}',
                              'GHS ${sale.totalPrice.toStringAsFixed(2)}',
                              formattedTime,
                              Colors.green,
                            );
                          }).toList(),
                      ],
                    ),
                  );
                },
              ),
              
              // Weekly sales chart
              Consumer<DashboardViewModel>(
                builder: (context, dashboardViewModel, child) {
                  return Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '7-Day Sales Overview',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 15),
                        if (dashboardViewModel.isLoadingSales)
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        else
                          Container(
                            height: 200,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _buildSalesChart(dashboardViewModel),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color bgColor, Color textColor, IconData icon, {VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Icon(
                    icon,
                    color: textColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActivityItem(String title, String status, String time, Color statusColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                time,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(DashboardViewModel viewModel) {
    // Extract data for the chart
    final Map<String, double> dailyTotals = {};
    final List<String> labels = [];
    
    // Sort the dates
    final sortedDates = viewModel.weeklySales.keys.toList()..sort();
    
    // Calculate daily totals
    for (final dateStr in sortedDates) {
      final sales = viewModel.weeklySales[dateStr] ?? [];
      final total = sales.fold(0.0, (sum, sale) => sum + sale.totalPrice);
      
      // Format date for display (e.g., "Mon", "Tue", etc.)
      final date = DateTime.parse(dateStr);
      final dayName = _getDayName(date.weekday);
      
      dailyTotals[dayName] = total;
      labels.add(dayName);
    }
    
    // If we have no data, show a message
    if (dailyTotals.isEmpty) {
      return Center(
        child: Text(
          'No sales data available for the past week',
          style: GoogleFonts.poppins(
            color: Colors.grey[600],
          ),
        ),
      );
    }
    
    // Find the maximum value for scaling
    final maxValue = dailyTotals.values.reduce((a, b) => a > b ? a : b);
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: labels.map((day) {
        final value = dailyTotals[day] ?? 0.0;
        final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
        
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'GHS ${value.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 5),
              Container(
                height: 120 * percentage,
                width: 20,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                day,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  String _getDayName(int weekday) {
    switch (weekday) {
      case 1: return 'Mon';
      case 2: return 'Tue';
      case 3: return 'Wed';
      case 4: return 'Thu';
      case 5: return 'Fri';
      case 6: return 'Sat';
      case 7: return 'Sun';
      default: return '';
    }
  }
}
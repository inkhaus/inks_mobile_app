import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkhaus/models/appointment_model.dart';
import 'package:inkhaus/models/enquiry_model.dart';
import 'package:inkhaus/services/api_service.dart';
import 'package:inkhaus/views/widgets/enquiry_detail_bottom_sheet.dart';
import 'package:inkhaus/views/widgets/appointment_detail_bottom_sheet.dart';
import 'package:intl/intl.dart';

class EnquiryTab extends StatefulWidget {
  const EnquiryTab({super.key});

  @override
  State<EnquiryTab> createState() => _EnquiryTabState();
}

class _EnquiryTabState extends State<EnquiryTab> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();

  late TabController _tabController;
  final ScrollController _enquiryScrollController = ScrollController();
  final ScrollController _appointmentScrollController = ScrollController();

  final int _pageSize = 10;

  // Enquiries state
  List<EnquiryModel> _enquiries = [];
  bool _isLoadingEnquiries = false;
  bool _isLoadingMoreEnquiries = false;
  bool _hasMoreEnquiries = true;
  int _enquiryPage = 0;
  String _enquiryError = '';

  // Appointments state
  List<AppointmentModel> _appointments = [];
  bool _isLoadingAppointments = false;
  bool _isLoadingMoreAppointments = false;
  bool _hasMoreAppointments = true;
  int _appointmentPage = 0;
  String _appointmentError = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _enquiryScrollController.addListener(_onEnquiryScroll);
    _appointmentScrollController.addListener(_onAppointmentScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadEnquiries();
      _loadAppointments();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _enquiryScrollController.removeListener(_onEnquiryScroll);
    _appointmentScrollController.removeListener(_onAppointmentScroll);
    _enquiryScrollController.dispose();
    _appointmentScrollController.dispose();
    super.dispose();
  }

  void _onEnquiryScroll() {
    if (_enquiryScrollController.position.pixels >=
            _enquiryScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMoreEnquiries &&
        _hasMoreEnquiries) {
      _loadMoreEnquiries();
    }
  }

  void _onAppointmentScroll() {
    if (_appointmentScrollController.position.pixels >=
            _appointmentScrollController.position.maxScrollExtent * 0.8 &&
        !_isLoadingMoreAppointments &&
        _hasMoreAppointments) {
      _loadMoreAppointments();
    }
  }

  Future<void> _loadEnquiries() async {
    setState(() {
      _isLoadingEnquiries = true;
      _enquiryError = '';
    });
    try {
      final results = await _apiService.getAllEnquiries(skip: 0, limit: _pageSize);
      setState(() {
        _enquiries = results;
        _enquiryPage = 1;
        _hasMoreEnquiries = results.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _enquiryError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEnquiries = false;
        });
      }
    }
  }

  Future<void> _loadMoreEnquiries() async {
    setState(() {
      _isLoadingMoreEnquiries = true;
    });
    try {
      final results = await _apiService.getAllEnquiries(
        skip: _enquiryPage * _pageSize,
        limit: _pageSize,
      );
      setState(() {
        _enquiries.addAll(results);
        _enquiryPage += 1;
        _hasMoreEnquiries = results.length == _pageSize;
      });
    } catch (e) {
      // Keep prior data; optionally show a snackbar
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreEnquiries = false;
        });
      }
    }
  }

  Future<void> _loadAppointments() async {
    setState(() {
      _isLoadingAppointments = true;
      _appointmentError = '';
    });
    try {
      final results = await _apiService.getAllAppointments(skip: 0, limit: _pageSize);
      setState(() {
        _appointments = results;
        _appointmentPage = 1;
        _hasMoreAppointments = results.length == _pageSize;
      });
    } catch (e) {
      setState(() {
        _appointmentError = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingAppointments = false;
        });
      }
    }
  }

  Future<void> _loadMoreAppointments() async {
    setState(() {
      _isLoadingMoreAppointments = true;
    });
    try {
      final results = await _apiService.getAllAppointments(
        skip: _appointmentPage * _pageSize,
        limit: _pageSize,
      );
      setState(() {
        _appointments.addAll(results);
        _appointmentPage += 1;
        _hasMoreAppointments = results.length == _pageSize;
      });
    } catch (e) {
      // Keep prior data; optionally show a snackbar
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMoreAppointments = false;
        });
      }
    }
  }

  // Pull-to-refresh handlers
  Future<void> _refreshEnquiries() async {
    try {
      final results = await _apiService.getAllEnquiries(skip: 0, limit: _pageSize);
      setState(() {
        _enquiries = results;
        _enquiryPage = 1;
        _hasMoreEnquiries = results.length == _pageSize;
        _enquiryError = '';
      });
    } catch (e) {
      setState(() {
        _enquiryError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _refreshAppointments() async {
    try {
      final results = await _apiService.getAllAppointments(skip: 0, limit: _pageSize);
      setState(() {
        _appointments = results;
        _appointmentPage = 1;
        _hasMoreAppointments = results.length == _pageSize;
        _appointmentError = '';
      });
    } catch (e) {
      setState(() {
        _appointmentError = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Enquiry & Appointments',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Enquiries'),
            Tab(text: 'Appointments'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildEnquiriesTab(),
          _buildAppointmentsTab(),
        ],
      ),
    );
  }

  Widget _buildEnquiriesTab() {
    if (_isLoadingEnquiries && _enquiries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_enquiryError.isNotEmpty && _enquiries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshEnquiries,
        child: _buildErrorState(_enquiryError, _loadEnquiries),
      );
    }
    if (_enquiries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshEnquiries,
        child: _buildEmptyState('No enquiries yet'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshEnquiries,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _enquiryScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _enquiries.length + (_isLoadingMoreEnquiries ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _enquiries.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final enquiry = _enquiries[index];
          return _buildEnquiryCard(enquiry);
        },
      ),
    );
  }

  Widget _buildAppointmentsTab() {
    if (_isLoadingAppointments && _appointments.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_appointmentError.isNotEmpty && _appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: _buildErrorState(_appointmentError, _loadAppointments),
      );
    }
    if (_appointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refreshAppointments,
        child: _buildEmptyState('No appointments yet'),
      );
    }

    return RefreshIndicator(
      onRefresh: _refreshAppointments,
      child: ListView.builder(
        physics: AlwaysScrollableScrollPhysics(),
        controller: _appointmentScrollController,
        padding: const EdgeInsets.all(12),
        itemCount: _appointments.length + (_isLoadingMoreAppointments ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _appointments.length) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          final appointment = _appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildErrorState(String message, VoidCallback onRetry) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even when content doesn't scroll
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Error: $message',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(
                  'Retry',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Enables pull-to-refresh even when content doesn't scroll
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnquiryCard(EnquiryModel enquiry) {
    final statusColor = _statusColor(enquiry.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: () => _showEnquiryDetails(enquiry),
        title: Text(
          enquiry.fullname,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_formatServiceCategory(enquiry.serviceCategory)} • ${DateFormat('MMM dd, yyyy').format(DateTime.parse(enquiry.createdAt).toLocal())}',
              style: GoogleFonts.poppins(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              enquiry.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: statusColor),
          ),
          child: Text(
            _formatStatus(enquiry.status),
            style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentCard(AppointmentModel appointment) {
    final statusColor = _appointmentStatusColor(appointment.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showAppointmentDetails(appointment),
        child: ListTile(
          title: Text(
            appointment.fullname,
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${appointment.purpose} • ${appointment.day} • ${appointment.time}',
                style: GoogleFonts.poppins(fontSize: 12),
              ),
              if (appointment.specialRequest.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    appointment.specialRequest,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                  ),
                ),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: statusColor),
            ),
            child: Text(
              _formatAppointmentStatus(appointment.status),
              style: GoogleFonts.poppins(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending_response':
        return Colors.orange;
      case 'responded_to_enquirer':
        return Colors.green;
      case 'should_be_ignored':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _appointmentStatusColor(String status) {
    switch (status) {
      case 'pending_fulfilment':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      case 'fulfilled':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending_response':
        return 'Pending';
      case 'responded_to_enquirer':
        return 'Responded';
      case 'should_be_ignored':
        return 'Ignore';
      default:
        return status;
    }
  }

  String _formatAppointmentStatus(String status) {
    switch (status) {
      case 'pending_fulfilment':
        return 'Pending';
      case 'cancelled':
        return 'Cancelled';
      case 'fulfilled':
        return 'Fulfilled';
      default:
        return status;
    }
  }

  String _formatServiceCategory(String serviceCategory) {
    switch (serviceCategory) {
      case 't_shirt_printing_and_customization':
        return 'T-Shirt Printing and Customization';
      case 'branded_items_and_customization':
        return 'Branded Items and Customization';
      case 'photography_and_videography':
        return 'Photography and Videography';
      default:
        return serviceCategory;
    }
  }
  
  void _showEnquiryDetails(EnquiryModel enquiry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
         expand: false,
        builder: (_, controller) => EnquiryDetailBottomSheet(
          enquiry: enquiry,
          onStatusUpdated: (updatedEnquiry) {
            setState(() {
              final index = _enquiries.indexWhere((e) => e.id == updatedEnquiry.id);
              if (index != -1) {
                _enquiries[index] = updatedEnquiry;
              }
            });
          },
        ),
      ),
    );
  }
  
  void _showAppointmentDetails(AppointmentModel appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, controller) => AppointmentDetailBottomSheet(
          appointment: appointment,
          onStatusUpdated: (updatedAppointment) {
            setState(() {
              final index = _appointments.indexWhere((a) => a.id == updatedAppointment.id);
              if (index != -1) {
                _appointments[index] = updatedAppointment;
              }
            });
          },
        ),
      ),
    );
  }
}
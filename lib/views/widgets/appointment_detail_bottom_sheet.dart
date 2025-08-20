import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:inkhaus/models/appointment_model.dart';
import 'package:inkhaus/services/api_service.dart';
import 'package:url_launcher/url_launcher.dart';

class AppointmentDetailBottomSheet extends StatefulWidget {
  final AppointmentModel appointment;
  final Function(AppointmentModel) onStatusUpdated;

  const AppointmentDetailBottomSheet({
    Key? key,
    required this.appointment,
    required this.onStatusUpdated,
  }) : super(key: key);

  @override
  State<AppointmentDetailBottomSheet> createState() => _AppointmentDetailBottomSheetState();
}

class _AppointmentDetailBottomSheetState extends State<AppointmentDetailBottomSheet> {
  final ApiService _apiService = ApiService();
  String _selectedStatus = '';
  bool _isUpdating = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.appointment.status;
  }

  Future<void> _updateStatus() async {
    if (_selectedStatus == widget.appointment.status) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isUpdating = true;
      _errorMessage = '';
    });

    try {
      final updatedAppointment = await _apiService.updateAppointmentStatus(
        appointmentId: widget.appointment.id!,
        status: _selectedStatus,
        updatedBy: 'app_user@example.com', // This should be the logged-in user's email
      );

      widget.onStatusUpdated(updatedAppointment);
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isUpdating = false;
      });
    }
  }

  Future<void> _makePhoneCall() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.appointment.phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch phone dialer')),
        );
      }
    }
  }

  String _formatTime(int time) {
    final hour = time ~/ 100;
    final minute = time % 100;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  String _formatStatus(String status) {
    switch (status) {
      case 'pending_fulfilment':
        return 'Pending Fulfilment';
      case 'cancelled':
        return 'Cancelled';
      case 'fulfilled':
        return 'Fulfilled';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Appointment Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailItem('Full Name', widget.appointment.fullname),
            _buildDetailItem('Purpose', widget.appointment.purpose),
            _buildDetailItem('Phone Number', widget.appointment.phoneNumber),
            _buildDetailItem('Day', widget.appointment.day),
            _buildDetailItem('Time', _formatTime(widget.appointment.time)),
            if (widget.appointment.specialRequest.isNotEmpty)
              _buildDetailItem('Special Request', widget.appointment.specialRequest),
            _buildDetailItem('Created At', DateFormat('MMM dd, yyyy').format(DateTime.parse(widget.appointment.createdAt).toLocal())),
            _buildStatusItem('Status', widget.appointment.status),
            const SizedBox(height: 20),
            Text(
              'Update Status',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _buildStatusDropdown(),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  _errorMessage,
                  style: GoogleFonts.poppins(
                    color: Colors.red,
                    fontSize: 14,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _makePhoneCall,
                    icon: const Icon(Icons.phone),
                    label: Text(
                      'Call',
                      style: GoogleFonts.poppins(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUpdating ? null : _updateStatus,
                    child: _isUpdating
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Update Status',
                            style: GoogleFonts.poppins(),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String status) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _statusColor(status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _statusColor(status)),
            ),
            child: Text(
              _formatStatus(status),
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: _statusColor(status),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          hint: Text(
            'Select Status',
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          items: [
            DropdownMenuItem(
              value: 'pending_fulfilment',
              child: Text(
                'Pending Fulfilment',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            DropdownMenuItem(
              value: 'cancelled',
              child: Text(
                'Cancelled',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            DropdownMenuItem(
              value: 'fulfilled',
              child: Text(
                'Fulfilled',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedStatus = value;
              });
            }
          },
        ),
      ),
    );
  }
}
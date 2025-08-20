import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inkhaus/models/enquiry_model.dart';
import 'package:inkhaus/services/api_service.dart';
import 'package:inkhaus/services/user_service.dart';
import 'package:inkhaus/viewmodels/enquiry_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fluttertoast/fluttertoast.dart';


class EnquiryDetailBottomSheet extends StatefulWidget {
  final EnquiryModel enquiry;
  final Function(EnquiryModel) onStatusUpdated;

  const EnquiryDetailBottomSheet({
    super.key,
    required this.enquiry,
    required this.onStatusUpdated,
  });

  @override
  State<EnquiryDetailBottomSheet> createState() => _EnquiryDetailBottomSheetState();
}

class _EnquiryDetailBottomSheetState extends State<EnquiryDetailBottomSheet> {
  final ApiService _apiService = ApiService();
  String _selectedStatus = '';
  bool _isUpdating = false;
  String _errorMessage = '';
  final TextEditingController _noteController = TextEditingController();
  final UserService _userService = UserService();
  

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.enquiry.status;
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _updateStatus() async {
    final user = await _userService.getCurrentUser();
    
    setState(() {
      _isUpdating = true;
      _errorMessage = '';
    });

    try {
      final updatedEnquiry = await _apiService.updateEnquiryStatus(
        enquiryId: widget.enquiry.id!,
        status: _selectedStatus,
        updatedBy: user?.email ?? '', // This should be the logged-in user's email
        responderNote: _noteController.text,
      );

      widget.onStatusUpdated(updatedEnquiry);
      Fluttertoast.showToast(msg: 'Status updated successfully',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.green,
      textColor: Colors.white,
      fontSize: 16.0
      );
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
    final Uri phoneUri = Uri(scheme: 'tel', path: widget.enquiry.phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      if (mounted) {
        
        Fluttertoast.showToast(msg: 'Could not launch phone dialer',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.TOP,
        timeInSecForIosWeb: 1,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0
        );
      }
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

  String _formatStatus(String status) {
    switch (status) {
      case 'pending_response':
        return 'Pending Response';
      case 'responded_to_enquirer':
        return 'Responded to Enquirer';
      case 'should_be_ignored':
        return 'Should Be Ignored';
      default:
        return status;
    }
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
              'Enquiry Details',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildDetailItem('Full Name', widget.enquiry.fullname),
            _buildDetailItem('Service Category', _formatServiceCategory(widget.enquiry.serviceCategory)),
            _buildDetailItem('Phone Number', widget.enquiry.phoneNumber),
            _buildDetailItem('Message', widget.enquiry.message),
            _buildStatusItem('Status', widget.enquiry.status),
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
            const SizedBox(height: 15),
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                labelText: 'Responder Note',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                hintText: 'Add a note about this status update',
              ),
              maxLines: 3,
            ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 300),
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
              value: 'pending_response',
              child: Text(
                'Pending Response',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            DropdownMenuItem(
              value: 'responded_to_enquirer',
              child: Text(
                'Responded to Enquirer',
                style: GoogleFonts.poppins(fontSize: 14),
              ),
            ),
            DropdownMenuItem(
              value: 'should_be_ignored',
              child: Text(
                'Should Be Ignored',
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
import 'package:flutter/material.dart';
import 'package:inkhaus/models/enquiry_model.dart';
import 'package:inkhaus/services/api_service.dart';


class EnquiryViewModel extends ChangeNotifier {
  final ApiService _enquiryService = ApiService();  
  final List<EnquiryModel> _enquiries = [];

  List<EnquiryModel> get enquiries => _enquiries;

  Future<void> fetchEnquiries() async {
    _enquiries.addAll(await _enquiryService.getAllEnquiries());
    notifyListeners();
  }

  Future<void> updateEnquiryStatus({required String enquiryId, required String status, required String updatedBy, required String responderNote}) async {
    await _enquiryService.updateEnquiryStatus(enquiryId: enquiryId, status: status, updatedBy: updatedBy, responderNote: responderNote);
    notifyListeners();
  }
}
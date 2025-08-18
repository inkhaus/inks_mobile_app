class EnquiryModel {
  final String? id;
  final String fullname;
  final String phoneNumber;
  final String serviceCategory;
  final String message;
  final String status;
  final String createdAt;

  EnquiryModel({
    this.id,
    required this.fullname,
    required this.phoneNumber,
    required this.serviceCategory,
    required this.message,
    required this.status,
    required this.createdAt,
  });

  factory EnquiryModel.fromJson(Map<String, dynamic> json) {
    return EnquiryModel(
      id: json['id'],
      fullname: json['fullname'],
      phoneNumber: json['phoneNumber'],
      serviceCategory: json['serviceCategory'],
      message: json['message'],
      status: json['status'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'fullname': fullname,
      'phoneNumber': phoneNumber,
      'serviceCategory': serviceCategory,
      'message': message,
      'status': status,
      'createdAt': createdAt,
    };
    
    return data;
  }
}
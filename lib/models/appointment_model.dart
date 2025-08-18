class AppointmentModel {
  final String? id;
  final String fullname;
  final String phoneNumber;
  final String purpose;
  final String day;
  final int time;
  final String status;
  final String specialRequest;
  final String createdAt;

  AppointmentModel({
    this.id,
    required this.fullname,
    required this.phoneNumber,
    required this.purpose,
    required this.day,
    required this.time,
    required this.status,
    required this.specialRequest,
    required this.createdAt,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    return AppointmentModel(
      id: json['id'],
      fullname: json['fullname'],
      phoneNumber: json['phoneNumber'],
      purpose: json['purpose'],
      day: json['day'],
      time: json['time'],
      status: json['status'],
      specialRequest: json['specialRequest'] ?? '',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullname': fullname,
      'phoneNumber': phoneNumber,
      'purpose': purpose,
      'day': day,
      'time': time,
      'status': status,
      'specialRequest': specialRequest,
      'createdAt': createdAt,
    };
  }
}
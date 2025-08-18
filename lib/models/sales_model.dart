class SalesModel {
  final String? id;
  final List<SalesEntryModel> entries;
  final CustomerModel customer;
  final double totalPrice;
  final String paymentChannel;
  final String createdAt;
  final String recordedBy;
  final String note;

  SalesModel({
    this.id,
    required this.entries,
    required this.customer,
    required this.totalPrice,
    required this.paymentChannel,
    required this.createdAt,
    required this.recordedBy,
    required this.note,
  });

  factory SalesModel.fromJson(Map<String, dynamic> json) {
    return SalesModel(
      id: json['id'],
      entries: (json['entries'] as List)
          .map((entry) => SalesEntryModel.fromJson(entry))
          .toList(),
      customer: CustomerModel.fromJson(json['customer']),
      totalPrice: (json['total_price'] is int)
          ? (json['total_price'] as int).toDouble()
          : json['total_price'],
      paymentChannel: json['paymentChannel'],
      createdAt: json['createdAt'],
      recordedBy: json['recordedBy'],
      note: json['note'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((entry) => entry.toJson()).toList(),
      'customer': customer.toJson(),
      'total_price': totalPrice,
      'paymentChannel': paymentChannel,
      'createdAt': createdAt,
      'recordedBy': recordedBy,
      'note': note,
    };
  }
}

class SalesEntryModel {
  final String service;
  final double unitPrice;
  final int quantity;
  final String createdAt;

  SalesEntryModel({
    required this.service,
    required this.unitPrice,
    required this.quantity,
    required this.createdAt,
  });

  factory SalesEntryModel.fromJson(Map<String, dynamic> json) {
    return SalesEntryModel(
      service: json['service'],
      unitPrice: (json['unitPrice'] is int)
          ? (json['unitPrice'] as int).toDouble()
          : json['unitPrice'],
      quantity: json['quantity'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'unitPrice': unitPrice,
      'quantity': quantity,
      'createdAt': createdAt,
    };
  }
}

class CustomerModel {
  final String fullname;
  final String phoneNumber;
  final String email;
  final String createdAt;

  CustomerModel({
    required this.fullname,
    required this.phoneNumber,
    required this.email,
    required this.createdAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) {
    return CustomerModel(
      fullname: json['fullname'],
      phoneNumber: json['phoneNumber'],
      email: json['email'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullname': fullname,
      'phoneNumber': phoneNumber,
      'email': email,
      'createdAt': createdAt,
    };
  }
}
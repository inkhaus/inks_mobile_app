class PayeeModel {
  final String fullname;
  final String phoneNumber;
  final String emailAddress;

  PayeeModel({
    required this.fullname,
    required this.phoneNumber,
    required this.emailAddress,
  });

  factory PayeeModel.fromJson(Map<String, dynamic> json) {
    return PayeeModel(
      fullname: json['fullname'],
      phoneNumber: json['phoneNumber'],
      emailAddress: json['emailAddress'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullname': fullname,
      'phoneNumber': phoneNumber,
      'emailAddress': emailAddress,
    };
  }
}

class ExpenseModel {
  final String? id;
  final double amount;
  final String category;
  final String evidence;
  final String notes;
  final PayeeModel payee;
  final String createdAt;

  ExpenseModel({
    this.id,
    required this.amount,
    required this.category,
    required this.evidence,
    required this.notes,
    required this.payee,
    required this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'],
      amount: (json['amount'] as num).toDouble(),
      category: json['category'],
      evidence: json['evidence'],
      notes: json['notes'],
      payee: PayeeModel.fromJson(json['payee']),
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'amount': amount,
      'category': category,
      'evidence': evidence,
      'notes': notes,
      'payee': payee.toJson(),
      'createdAt': createdAt,
    };
    
    if (id != null) {
      data['id'] = id;
    }
    
    return data;
  }
}
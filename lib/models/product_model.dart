class ProductModel {
  final String? id;
  final String title;
  final String description;
  final double unitPrice;
  final String artworkUrl;
  final String businessUnit;
  final String createdAt;

  ProductModel({
    this.id,
    required this.title,
    required this.description,
    required this.unitPrice,
    required this.artworkUrl,
    required this.businessUnit,
    required this.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      unitPrice: (json['unitPrice'] is int) 
          ? (json['unitPrice'] as int).toDouble() 
          : json['unitPrice'],
      artworkUrl: json['artworkUrl'] ?? '',
      businessUnit: json['businessUnit'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'title': title,
      'description': description,
      'unitPrice': unitPrice,
      'artworkUrl': artworkUrl,
      'businessUnit': businessUnit,
      'createdAt': createdAt,
    };
    
    return data;
  }
}
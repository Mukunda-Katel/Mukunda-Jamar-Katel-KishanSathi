
class Category {
  final int id;
  final String name;
  final String description;
  final String icon;
  final int productCount;
  final DateTime createdAt;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.productCount,
    required this.createdAt,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      icon: json['icon'] ?? '',
      productCount: json['product_count'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'product_count': productCount,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class Product {
  final int id;
  final String name;
  final String description;
  final double price;
  final double quantity;
  final String unit;
  final String unitDisplay;
  final String status;
  final String statusDisplay;
  final bool isOrganic;
  final String location;
  final String district;
  final String? image;
  final String categoryName;
  final String farmerName;
  final int? farmerId;
  final DateTime createdAt;
  final bool isAvailable;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.unitDisplay,
    required this.status,
    required this.statusDisplay,
    required this.isOrganic,
    required this.location,
    required this.district,
    this.image,
    required this.categoryName,
    required this.farmerName,
    this.farmerId,
    required this.createdAt,
    required this.isAvailable,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      price: double.parse(json['price'].toString()),
      quantity: double.parse(json['quantity'].toString()),
      unit: json['unit'],
      unitDisplay: json['unit_display'],
      status: json['status'],
      statusDisplay: json['status_display'],
      isOrganic: json['is_organic'],
      location: json['location'],
      district: json['district'] ?? '',
      image: json['image'],
      categoryName: json['category_name'],
      farmerName: json['farmer_name'],
      farmerId: json['farmer_id'] ?? json['farmer'],
      createdAt: DateTime.parse(json['created_at']),
      isAvailable: json['is_available'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'unit_display': unitDisplay,
      'status': status,
      'status_display': statusDisplay,
      'is_organic': isOrganic,
      'location': location,
      'district': district,
      'image': image,
      'category_name': categoryName,
      'farmer_name': farmerName,
      'farmer_id': farmerId,
      'created_at': createdAt.toIso8601String(),
      'is_available': isAvailable,
    };
  }
}

class ProductCreateRequest {
  final int categoryId;
  final String name;
  final String description;
  final double price;
  final double quantity;
  final String unit;
  final String status;
  final bool isOrganic;
  final String? harvestDate;
  final String location;
  final String district;
  final String? imagePath;

  ProductCreateRequest({
    required this.categoryId,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.unit,
    this.status = 'available',
    this.isOrganic = false,
    this.harvestDate,
    required this.location,
    required this.district,
    this.imagePath,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': categoryId,
      'name': name,
      'description': description,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'status': status,
      'is_organic': isOrganic,
      if (harvestDate != null) 'harvest_date': harvestDate,
      'location': location,
      'district': district,
    };
  }
}

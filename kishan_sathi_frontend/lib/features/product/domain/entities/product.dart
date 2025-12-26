import 'package:equatable/equatable.dart';

/// Product entity - Pure business object
class Product extends Equatable {
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
  final DateTime? harvestDate;
  final String location;
  final String district;
  final String? image;
  final int categoryId;
  final String categoryName;
  final int farmerId;
  final String farmerName;
  final DateTime createdAt;
  final bool isAvailable;

  const Product({
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
    this.harvestDate,
    required this.location,
    required this.district,
    this.image,
    required this.categoryId,
    required this.categoryName,
    required this.farmerId,
    required this.farmerName,
    required this.createdAt,
    required this.isAvailable,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        quantity,
        unit,
        unitDisplay,
        status,
        statusDisplay,
        isOrganic,
        harvestDate,
        location,
        district,
        image,
        categoryId,
        categoryName,
        farmerId,
        farmerName,
        createdAt,
        isAvailable,
      ];
}

/// Category entity
class Category extends Equatable {
  final int id;
  final String name;
  final String description;
  final String icon;
  final int productCount;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.productCount,
    required this.createdAt,
  });

  @override
  List<Object> get props => [
        id,
        name,
        description,
        icon,
        productCount,
        createdAt,
      ];
}

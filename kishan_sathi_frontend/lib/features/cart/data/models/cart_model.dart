import 'package:kishan_sathi_frontend/features/product/data/models/product_model.dart';

class Cart {
  final int id;
  final int buyer;
  final List<CartItem> items;
  final int totalItems;
  final double totalPrice;
  final DateTime createdAt;
  final DateTime updatedAt;

  Cart({
    required this.id,
    required this.buyer,
    required this.items,
    required this.totalItems,
    required this.totalPrice,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Cart.fromJson(Map<String, dynamic> json) {
    return Cart(
      id: json['id'],
      buyer: json['buyer'],
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item))
          .toList(),
      totalItems: json['total_items'] ?? 0,
      totalPrice: double.parse(json['total_price'].toString()),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'buyer': buyer,
      'items': items.map((item) => item.toJson()).toList(),
      'total_items': totalItems,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Cart copyWith({
    int? id,
    int? buyer,
    List<CartItem>? items,
    int? totalItems,
    double? totalPrice,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Cart(
      id: id ?? this.id,
      buyer: buyer ?? this.buyer,
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      totalPrice: totalPrice ?? this.totalPrice,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CartItem {
  final int id;
  final Product product;
  final double quantity;
  final double subtotal;
  final DateTime addedAt;
  final DateTime updatedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    required this.subtotal,
    required this.addedAt,
    required this.updatedAt,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'],
      product: Product.fromJson(json['product']),
      quantity: double.parse(json['quantity'].toString()),
      subtotal: double.parse(json['subtotal'].toString()),
      addedAt: DateTime.parse(json['added_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'subtotal': subtotal,
      'added_at': addedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    int? id,
    Product? product,
    double? quantity,
    double? subtotal,
    DateTime? addedAt,
    DateTime? updatedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      subtotal: subtotal ?? this.subtotal,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class CartCount {
  final int count;
  final double totalPrice;

  CartCount({
    required this.count,
    required this.totalPrice,
  });

  factory CartCount.fromJson(Map<String, dynamic> json) {
    return CartCount(
      count: json['count'] ?? 0,
      totalPrice: double.parse(json['total_price']?.toString() ?? '0'),
    );
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/cart_model.dart';

class CartService {
  final String baseUrl = '${ApiConstants.apiBaseUrl}/buyer/cart';

  Future<Cart> getCart(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return Cart.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load cart: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required String token,
    required int productId,
    required double quantity,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add_item/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'product_id': productId,
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to add item to cart');
    }
  }

  Future<Map<String, dynamic>> updateCartItem({
    required String token,
    required int itemId,
    required double quantity,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/update_item/$itemId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'quantity': quantity,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to update cart item');
    }
  }

  Future<void> removeFromCart({
    required String token,
    required int itemId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/remove_item/$itemId/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to remove item from cart');
    }
  }

  Future<void> clearCart(String token) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/clear/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to clear cart');
    }
  }

  Future<Map<String, dynamic>> completePurchase(String token) async {
    final response = await http.post(
      Uri.parse('$baseUrl/complete_purchase/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      final error = json.decode(response.body);
      throw Exception(error['error'] ?? 'Failed to complete purchase');
    }
  }

  Future<CartCount> getCartCount(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/count/'),
      headers: {
        'Authorization': 'Token $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return CartCount.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get cart count');
    }
  }
}

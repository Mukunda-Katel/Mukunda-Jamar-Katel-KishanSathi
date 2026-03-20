import '../models/cart_model.dart';
import '../services/cart_service.dart';

class CartRepository {
  final CartService _cartService = CartService();

  Future<Cart> getCart(String token) async {
    try {
      return await _cartService.getCart(token);
    } catch (e) {
      throw Exception('Failed to fetch cart: $e');
    }
  }

  Future<Map<String, dynamic>> addToCart({
    required String token,
    required int productId,
    required double quantity,
  }) async {
    try {
      return await _cartService.addToCart(
        token: token,
        productId: productId,
        quantity: quantity,
      );
    } catch (e) {
      throw Exception('Failed to add item to cart: $e');
    }
  }

  Future<Map<String, dynamic>> updateCartItem({
    required String token,
    required int itemId,
    required double quantity,
  }) async {
    try {
      return await _cartService.updateCartItem(
        token: token,
        itemId: itemId,
        quantity: quantity,
      );
    } catch (e) {
      throw Exception('Failed to update cart item: $e');
    }
  }

  Future<void> removeFromCart({
    required String token,
    required int itemId,
  }) async {
    try {
      await _cartService.removeFromCart(token: token, itemId: itemId);
    } catch (e) {
      throw Exception('Failed to remove item from cart: $e');
    }
  }

  Future<void> clearCart(String token) async {
    try {
      await _cartService.clearCart(token);
    } catch (e) {
      throw Exception('Failed to clear cart: $e');
    }
  }

  Future<Map<String, dynamic>> completePurchase(String token) async {
    try {
      return await _cartService.completePurchase(token);
    } catch (e) {
      throw Exception('Failed to complete purchase: $e');
    }
  }

  Future<CartCount> getCartCount(String token) async {
    try {
      return await _cartService.getCartCount(token);
    } catch (e) {
      throw Exception('Failed to get cart count: $e');
    }
  }
}

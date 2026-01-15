import 'package:equatable/equatable.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  final String token;

  const LoadCart(this.token);

  @override
  List<Object> get props => [token];
}

class AddToCart extends CartEvent {
  final String token;
  final int productId;
  final double quantity;

  const AddToCart({
    required this.token,
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object> get props => [token, productId, quantity];
}

class UpdateCartItem extends CartEvent {
  final String token;
  final int itemId;
  final double quantity;

  const UpdateCartItem({
    required this.token,
    required this.itemId,
    required this.quantity,
  });

  @override
  List<Object> get props => [token, itemId, quantity];
}

class RemoveFromCart extends CartEvent {
  final String token;
  final int itemId;

  const RemoveFromCart({
    required this.token,
    required this.itemId,
  });

  @override
  List<Object> get props => [token, itemId];
}

class ClearCart extends CartEvent {
  final String token;

  const ClearCart(this.token);

  @override
  List<Object> get props => [token];
}

class GetCartCount extends CartEvent {
  final String token;

  const GetCartCount(this.token);

  @override
  List<Object> get props => [token];
}

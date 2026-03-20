import 'package:equatable/equatable.dart';
import '../../data/models/cart_model.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final Cart cart;

  const CartLoaded(this.cart);

  @override
  List<Object> get props => [cart];
}

class CartItemAdded extends CartState {
  final String message;

  const CartItemAdded(this.message);

  @override
  List<Object> get props => [message];
}

class CartItemUpdated extends CartState {
  final String message;

  const CartItemUpdated(this.message);

  @override
  List<Object> get props => [message];
}

class CartItemRemoved extends CartState {
  final String message;

  const CartItemRemoved(this.message);

  @override
  List<Object> get props => [message];
}

class CartCleared extends CartState {}

class CartCountLoaded extends CartState {
  final CartCount cartCount;

  const CartCountLoaded(this.cartCount);

  @override
  List<Object> get props => [cartCount];
}

class PurchaseCompleted extends CartState {
  final String message;

  const PurchaseCompleted(this.message);

  @override
  List<Object> get props => [message];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object> get props => [message];
}

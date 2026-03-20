import 'package:flutter_bloc/flutter_bloc.dart';
import 'cart_event.dart';
import 'cart_state.dart';
import '../../data/repositories/cart_repository.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository cartRepository;

  CartBloc({required this.cartRepository}) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<UpdateCartItem>(_onUpdateCartItem);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
    on<GetCartCount>(_onGetCartCount);
    on<CompletePurchase>(_onCompletePurchase);
  }

  Future<void> _onLoadCart(
    LoadCart event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    try {
      final cart = await cartRepository.getCart(event.token);
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onAddToCart(
    AddToCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final result = await cartRepository.addToCart(
        token: event.token,
        productId: event.productId,
        quantity: event.quantity,
      );
      emit(CartItemAdded(result['message'] ?? 'Item added to cart'));
      // Reload cart after adding
      final cart = await cartRepository.getCart(event.token);
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onUpdateCartItem(
    UpdateCartItem event,
    Emitter<CartState> emit,
  ) async {
    try {
      final result = await cartRepository.updateCartItem(
        token: event.token,
        itemId: event.itemId,
        quantity: event.quantity,
      );
      emit(CartItemUpdated(result['message'] ?? 'Cart updated'));
      // Reload cart after updating
      final cart = await cartRepository.getCart(event.token);
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      await cartRepository.removeFromCart(
        token: event.token,
        itemId: event.itemId,
      );
      emit(const CartItemRemoved('Item removed from cart'));
      // Reload cart after removing
      final cart = await cartRepository.getCart(event.token);
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onClearCart(
    ClearCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      await cartRepository.clearCart(event.token);
      emit(CartCleared());
      // Reload cart after clearing
      final cart = await cartRepository.getCart(event.token);
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onGetCartCount(
    GetCartCount event,
    Emitter<CartState> emit,
  ) async {
    try {
      final cartCount = await cartRepository.getCartCount(event.token);
      emit(CartCountLoaded(cartCount));
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onCompletePurchase(
    CompletePurchase event,
    Emitter<CartState> emit,
  ) async {
    try {
      final result = await cartRepository.completePurchase(event.token);
      emit(PurchaseCompleted(result['message'] ?? 'Purchase completed successfully'));

      final cartCount = await cartRepository.getCartCount(event.token);
      emit(CartCountLoaded(cartCount));

      final cart = await cartRepository.getCart(event.token);
      emit(CartLoaded(cart));
    } catch (e) {
      emit(CartError(e.toString().replaceAll('Exception: ', '')));
    }
  }
}

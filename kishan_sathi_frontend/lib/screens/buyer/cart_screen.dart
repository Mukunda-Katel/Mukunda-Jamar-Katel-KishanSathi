import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kishan_sathi_frontend/screens/buyer/esewa.dart';
import '../../features/cart/data/models/cart_model.dart';
import '../../features/payment/data/datasources/khalti_remote_data_source.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_event.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import '../../services/khalti_payment_service.dart';

enum _PaymentMethod { esewa, khalti }

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  bool _isProcessingCheckout = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  void _loadCart() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<CartBloc>().add(LoadCart(authState.token));
    }
  }

  Future<void> _checkoutWithEsewa({
    required String token,
    required Cart cart,
  }) async {
    final String productId = 'KS${DateTime.now().millisecondsSinceEpoch}';

    final esewa = Esewa(
      context: context,
      productId: productId,
      productName: 'Kishan Sathi Order',
      totalAmount: cart.totalPrice.toStringAsFixed(0),
      onSuccess: () {
        context.read<CartBloc>().add(CompletePurchase(token));
      },
      onFailure: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('eSewa payment failed or cancelled.'),
            backgroundColor: Colors.red,
          ),
        );
      },
    );

    esewa.pay();
  }

  Map<String, dynamic>? _toJsonMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return value.map((key, val) => MapEntry('$key', val));
    return null;
  }

  String _extractTransactionId(dynamic paymentResult) {
    final map = _toJsonMap(paymentResult);
    if (map == null) return '';
    return (map['transaction_id'] ?? map['transactionId'] ?? map['idx'] ?? map['tid'] ?? '')
        .toString();
  }

  Future<void> _checkoutWithKhalti({
    required String token,
    required Cart cart,
  }) async {
    if (_isProcessingCheckout) return;

    setState(() {
      _isProcessingCheckout = true;
    });

    try {
      final remoteDataSource = KhaltiRemoteDataSource();

      final status = await remoteDataSource.checkBusinessKhaltiStatus(
        token: token,
        relationshipId: cart.id,
      );

      final hasKhalti = status['has_khalti'] == true;
      final isActive = status['is_active'] == true;

      if (!hasKhalti || !isActive) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Seller has not linked an active Khalti account.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final initiate = await remoteDataSource.initiateKhaltiPayment(
        token: token,
        relationshipId: cart.id,
        amount: cart.totalPrice,
        description: 'Kishan Sathi Order',
      );

      final pidx = (initiate['pidx'] ?? '').toString();
      final paymentRecordId = initiate['payment_record_id'] as int?;
      final publicKey = (initiate['public_key'] ?? '').toString();
      final isTestEnvironment = initiate['is_test_environment'] == true;

      if (pidx.isEmpty || paymentRecordId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not start Khalti payment. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (!mounted) return;
      final khaltiService = KhaltiPaymentService();

      await khaltiService.initiatePayment(
        context: context,
        pidx: pidx,
        isTestEnvironment: isTestEnvironment,
        publicKey: publicKey.isEmpty ? null : publicKey,
        onPaymentResult: (paymentResult) async {
          try {
            final verifyResponse = await remoteDataSource.verifyKhaltiPayment(
              token: token,
              paymentRecordId: paymentRecordId,
              pidx: pidx,
              transactionId: _extractTransactionId(paymentResult),
              totalAmount: cart.totalPrice.toStringAsFixed(2),
              status: 'completed',
              khaltiResponse: _toJsonMap(paymentResult),
            );

            if (!mounted) return;
            if (verifyResponse['status'] == 200) {
              context.read<CartBloc>().add(CompletePurchase(token));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    (verifyResponse['message'] ?? 'Khalti verification failed').toString(),
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Khalti verify error: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        onMessage: (message, {needsPaymentConfirmation = false, khalti}) {
          if (!mounted) return;
          final lowered = message.toLowerCase();
          if (lowered.contains('fail') || lowered.contains('cancel')) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Khalti checkout failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingCheckout = false;
        });
      }
    }
  }

  Future<void> _showPaymentMethodSheet({
    required String token,
    required Cart cart,
  }) async {
    if (_isProcessingCheckout) return;

    final method = await showModalBottomSheet<_PaymentMethod>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose Payment Method',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Select your preferred checkout provider.',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('eSewa'),
                  subtitle: const Text('Pay using eSewa wallet'),
                  onTap: () => Navigator.pop(sheetContext, _PaymentMethod.esewa),
                ),
                ListTile(
                  leading: const Icon(Icons.payments_outlined),
                  title: const Text('Khalti'),
                  subtitle: const Text('Pay using Khalti checkout'),
                  onTap: () => Navigator.pop(sheetContext, _PaymentMethod.khalti),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );

    if (method == null) return;

    if (method == _PaymentMethod.esewa) {
      await _checkoutWithEsewa(token: token, cart: cart);
      return;
    }

    await _checkoutWithKhalti(token: token, cart: cart);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isSmallScreen ? 12.0 : 16.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: const Color(0xFF2196F3),
        title: const Text(
          'My Cart',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && state.cart.items.isNotEmpty) {
                return IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _showClearCartDialog(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<CartBloc, CartState>(
        listener: (context, state) {
          if (state is CartItemAdded) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CartItemUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is CartItemRemoved) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is PurchaseCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.green,
              ),
            );

            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          } else if (state is CartError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CartLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CartLoaded) {
            if (state.cart.items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 100,
                      color: Colors.grey[300],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 18 : 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add products to get started',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 14,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 24 : 32,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Browse Products',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: [
                // Cart Items List
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(horizontalPadding),
                    itemCount: state.cart.items.length,
                    itemBuilder: (context, index) {
                      final item = state.cart.items[index];
                      return _CartItemCard(
                        item: item,
                        onUpdateQuantity: (newQuantity) {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthSuccess) {
                            context.read<CartBloc>().add(
                                  UpdateCartItem(
                                    token: authState.token,
                                    itemId: item.id,
                                    quantity: newQuantity,
                                  ),
                                );
                          }
                        },
                        onRemove: () {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthSuccess) {
                            context.read<CartBloc>().add(
                                  RemoveFromCart(
                                    token: authState.token,
                                    itemId: item.id,
                                  ),
                                );
                          }
                        },
                      );
                    },
                  ),
                ),

                // Cart Summary
                Container(
                  padding: EdgeInsets.all(horizontalPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total Items:',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 16,
                                color: Colors.grey[700],
                              ),
                            ),
                            Text(
                              '${state.cart.totalItems}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 15 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Price:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rs. ${state.cart.totalPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 18 : 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2196F3),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessingCheckout
                                ? null
                                : () {
                                    final authState = context.read<AuthBloc>().state;
                                    if (authState is! AuthSuccess) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please login again to continue checkout.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                      return;
                                    }

                                    _showPaymentMethodSheet(
                                      token: authState.token,
                                      cart: state.cart,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isProcessingCheckout
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'Proceed to Checkout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Failed to load cart'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadCart,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthSuccess) {
                context.read<CartBloc>().add(ClearCart(authState.token));
              }
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

class _CartItemCard extends StatelessWidget {
  final dynamic item;
  final Function(double) onUpdateQuantity;
  final VoidCallback onRemove;

  const _CartItemCard({
    required this.item,
    required this.onUpdateQuantity,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
        child: Row(
          children: [
            // Product Image
            Container(
              width: isSmallScreen ? 68 : 80,
              height: isSmallScreen ? 68 : 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.product.image != null && item.product.image!.isNotEmpty
                    ? Image.network(
                        item.product.image!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[100],
                            child: Icon(
                              Icons.shopping_basket,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                          );
                        },
                      )
                    : Container(
                        color: Colors.grey[100],
                        child: Icon(
                          Icons.shopping_basket,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${item.product.price} per ${item.product.unit}',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 16),
                              onPressed: () {
                                if (item.quantity > 1) {
                                  onUpdateQuantity(item.quantity - 1);
                                }
                              },
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                item.quantity.toString(),
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 16),
                              onPressed: () {
                                if (item.quantity < item.product.quantity) {
                                  onUpdateQuantity(item.quantity + 1);
                                }
                              },
                              constraints: const BoxConstraints(
                                minWidth: 28,
                                minHeight: 28,
                              ),
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Subtotal
                      Flexible(
                        child: Text(
                          'Rs. ${item.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2196F3),
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Remove Button
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}

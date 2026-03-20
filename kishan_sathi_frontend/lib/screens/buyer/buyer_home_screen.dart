import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_event.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/notification/presentation/bloc/notification_event.dart';
import '../../features/notification/presentation/bloc/notification_state.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/product/presentation/bloc/product_event.dart';
import '../../features/product/presentation/bloc/product_state.dart';
import '../notification/notification_screen.dart';
import 'cart_screen.dart';
import 'widgets/buyer_home_widgets.dart';

class BuyerHomeScreen extends StatefulWidget {
  final Set<int> favoriteProductIds;
  final ValueChanged<int> onToggleFavorite;
  final ValueChanged<List<Product>> onProductsLoaded;

  const BuyerHomeScreen({
    super.key,
    required this.favoriteProductIds,
    required this.onToggleFavorite,
    required this.onProductsLoaded,
  });

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int? _selectedCategoryId;

  final List<Map<String, dynamic>> _categories = [
    {'id': null, 'name': 'All', 'icon': Icons.grid_view},
    {'id': 1, 'name': 'Vegetables', 'icon': Icons.local_florist},
    {'id': 2, 'name': 'Fruits', 'icon': Icons.apple},
    {'id': 3, 'name': 'Grains', 'icon': Icons.grass},
    {'id': 4, 'name': 'Dairy', 'icon': Icons.water_drop},
    {'id': 5, 'name': 'Spices', 'icon': Icons.spa},
    {'id': 6, 'name': 'Pulses', 'icon': Icons.grain},
    {'id': 7, 'name': 'Seeds', 'icon': Icons.eco},
    {'id': 8, 'name': 'Organic', 'icon': Icons.nature},
  ];

  @override
  void initState() {
    super.initState();
    context.read<ProductBloc>().add(const LoadProducts(availableOnly: true));

    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<CartBloc>().add(GetCartCount(authState.token));
      context.read<NotificationBloc>().add(GetNotificationCount(authState.token));
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });

    context.read<ProductBloc>().add(
          LoadProducts(
            categoryId: categoryId,
            availableOnly: true,
          ),
        );
  }

  IconData _getProductIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('grain') || name.contains('pulses')) return Icons.grain;
    if (name.contains('vegetable')) return Icons.local_florist;
    if (name.contains('fruit')) return Icons.apple;
    if (name.contains('dairy')) return Icons.emoji_food_beverage;
    if (name.contains('spice')) return Icons.spa;
    if (name.contains('organic')) return Icons.eco;
    if (name.contains('seed')) return Icons.scatter_plot;
    return Icons.shopping_basket;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 20.0;
    final gridCrossAxisCount = screenWidth >= 1200
        ? 4
        : screenWidth >= 900
            ? 3
            : 2;

    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartItemAdded || state is CartItemUpdated || state is CartItemRemoved) {
          final message = state is CartItemAdded
              ? state.message
              : state is CartItemUpdated
                  ? state.message
                  : (state as CartItemRemoved).message;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          final authState = context.read<AuthBloc>().state;
          if (authState is AuthSuccess) {
            context.read<CartBloc>().add(GetCartCount(authState.token));
          }
        } else if (state is CartError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (state is PurchaseCompleted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          context.read<ProductBloc>().add(
                LoadProducts(
                  categoryId: _selectedCategoryId,
                  availableOnly: true,
                ),
              );

          final authState = context.read<AuthBloc>().state;
          if (authState is AuthSuccess) {
            context.read<CartBloc>().add(GetCartCount(authState.token));
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  padding: EdgeInsets.all(horizontalPadding),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF2196F3), Color(0xFF64B5F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)?.home ?? 'Home',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Find fresh produce',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              BlocBuilder<CartBloc, CartState>(
                                builder: (context, cartState) {
                                  int cartCount = 0;
                                  if (cartState is CartLoaded) {
                                    cartCount = cartState.cart.totalItems;
                                  } else if (cartState is CartCountLoaded) {
                                    cartCount = cartState.cartCount.count;
                                  }

                                  return Stack(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (newContext) => MultiBlocProvider(
                                                providers: [
                                                  BlocProvider.value(value: context.read<CartBloc>()),
                                                  BlocProvider.value(value: context.read<AuthBloc>()),
                                                ],
                                                child: const CartScreen(),
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.shopping_cart_outlined,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      if (cartCount > 0)
                                        Positioned(
                                          right: 6,
                                          top: 6,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                            child: Text(
                                              cartCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                              BlocBuilder<NotificationBloc, NotificationState>(
                                builder: (context, notificationState) {
                                  int unreadCount = 0;
                                  if (notificationState is NotificationCountLoaded) {
                                    unreadCount = notificationState.count.unreadCount;
                                  }

                                  return Stack(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (newContext) => MultiBlocProvider(
                                                providers: [
                                                  BlocProvider.value(value: context.read<AuthBloc>()),
                                                  BlocProvider.value(value: context.read<NotificationBloc>()),
                                                ],
                                                child: const NotificationScreen(),
                                              ),
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.notifications_outlined,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      if (unreadCount > 0)
                                        Positioned(
                                          right: 8,
                                          top: 8,
                                          child: Container(
                                            padding: const EdgeInsets.all(4),
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                            child: Text(
                                              unreadCount > 99 ? '99+' : unreadCount.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.search, color: Colors.grey),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Search for products...',
                                  hintStyle: TextStyle(color: Colors.grey[400]),
                                  border: InputBorder.none,
                                ),
                                onSubmitted: (value) {
                                  context.read<ProductBloc>().add(
                                        LoadProducts(
                                          categoryId: _selectedCategoryId,
                                          availableOnly: true,
                                          search: value.trim().isEmpty ? null : value.trim(),
                                        ),
                                      );
                                },
                              ),
                            ),
                            const Icon(Icons.tune, color: Color(0xFF2196F3)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Categories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.darkGreen,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: isSmallScreen ? 92 : 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          itemBuilder: (context, index) {
                            final category = _categories[index];
                            final id = category['id'] as int?;
                            final isSelected = _selectedCategoryId == id;

                            return BuyerCategoryCard(
                              icon: category['icon'] as IconData,
                              label: category['name'] as String,
                              color: const Color(0xFF2196F3),
                              isSelected: isSelected,
                              onTap: () => _onCategorySelected(id),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              BlocBuilder<ProductBloc, ProductState>(
                builder: (context, state) {
                  if (state is ProductLoading) {
                    return const SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is ProductError) {
                    return SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            state.message,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    );
                  }

                  if (state is ProductsLoaded) {
                    widget.onProductsLoaded(state.products);

                    if (state.products.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: Text(
                            'No products available right now.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 0, horizontalPadding, 20),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: gridCrossAxisCount,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = state.products[index];
                            return BuyerProductCard(
                              productId: product.id,
                              name: product.name,
                              price: product.price.toString(),
                              unit: product.unit,
                              farmer: product.farmerName,
                              farmerId: product.farmerId,
                              location: product.location,
                              rating: 4.5,
                              imageIcon: _getProductIcon(product.categoryName),
                              imageUrl: product.image,
                              isOrganic: product.isOrganic,
                              availableQuantity: product.quantity,
                              status: product.status,
                              isFavorite: widget.favoriteProductIds.contains(product.id),
                              onFavoriteTap: () => widget.onToggleFavorite(product.id),
                            );
                          },
                          childCount: state.products.length,
                        ),
                      ),
                    );
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

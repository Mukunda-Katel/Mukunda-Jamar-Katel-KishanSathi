import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/product/presentation/bloc/product_event.dart';
import '../../features/product/presentation/bloc/product_state.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../features/chat/presentation/bloc/chat_event.dart';
import '../../features/chat/presentation/bloc/chat_state.dart';
import '../../features/chat/data/repositories/chat_repository.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/cart/presentation/bloc/cart_event.dart';
import '../../features/cart/presentation/bloc/cart_state.dart';
import '../../features/cart/data/repositories/cart_repository.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/notification/presentation/bloc/notification_event.dart';
import '../../features/notification/presentation/bloc/notification_state.dart';
import '../../features/notification/data/repositories/notification_repository.dart';
import 'chat_list_screen.dart';
import 'chat_screen.dart';
import 'cart_screen.dart';
import '../community/community_feed_screen.dart';
import '../notification/notification_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BuyerHomeScreen(),
    const CommunityFeedScreen(),
    const BuyerChatListScreen(),
    const Center(child: Text('Orders - Coming Soon')),
    const Center(child: Text('Favorites - Coming Soon')),
    const BuyerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ProductBloc(productRepository: ProductRepository()),
        ),
        BlocProvider(
          create: (context) => CartBloc(cartRepository: CartRepository()),
        ),
        BlocProvider(
          create: (context) => NotificationBloc(
              notificationRepository: NotificationRepository()),
        ),
      ],
      child: Scaffold(
        body: _screens[_selectedIndex],
        bottomNavigationBar: Container(
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
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(Icons.home, 'Home', 0),
                  _buildNavItem(Icons.groups, 'Community', 1),
                  _buildNavItem(Icons.chat, 'Chat', 2),
                  _buildNavItem(Icons.favorite, 'Favorites', 4),
                  _buildNavItem(Icons.person, 'Profile', 5),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2196F3).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class BuyerHomeScreen extends StatefulWidget {
  const BuyerHomeScreen({super.key});

  @override
  State<BuyerHomeScreen> createState() => _BuyerHomeScreenState();
}

class _BuyerHomeScreenState extends State<BuyerHomeScreen> {
  int? _selectedCategoryId;
  
  // Static categories data
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Vegetables', 'icon': Icons.local_florist},
    {'id': 2, 'name': 'Fruits', 'icon': Icons.apple},
    {'id': 3, 'name': 'Grains', 'icon': Icons.grass},
    {'id': 4, 'name': 'Dairy', 'icon': Icons.water_drop},
    {'id': 5, 'name': 'Spices', 'icon': Icons.cake},
    {'id': 6, 'name': 'Pulses', 'icon': Icons.grain},
    {'id': 7, 'name': 'Seeds', 'icon': Icons.eco},
    {'id': 8, 'name': 'Organic', 'icon': Icons.nature},
  ];

  @override
  void initState() {
    super.initState();
    // Load all products when screen initializes
    context.read<ProductBloc>().add(const LoadProducts(availableOnly: true));
    
    // Load cart and notifications
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<CartBloc>().add(LoadCart(authState.token));
      context.read<NotificationBloc>().add(GetNotificationCount(authState.token));
    }
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    // Reload products with category filter
    context.read<ProductBloc>().add(LoadProducts(
      categoryId: categoryId,
      availableOnly: true,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CartBloc, CartState>(
      listener: (context, state) {
        if (state is CartItemAdded) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
          // Reload cart count
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
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: SafeArea(
          child: CustomScrollView(
            slivers: [
              // App Bar
              SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.all(20),
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello Buyer! 👋',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Find Fresh Produce',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Cart Icon with Badge
                            BlocBuilder<CartBloc, CartState>(
                              builder: (context, cartState) {
                                int cartCount = 0;
                                if (cartState is CartLoaded) {
                                  cartCount = cartState.cart.totalItems;
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
                                                BlocProvider.value(
                                                  value: context.read<CartBloc>(),
                                                ),
                                                BlocProvider.value(
                                                  value: context.read<AuthBloc>(),
                                                ),
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
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
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
                            // Notification Icon
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
                                                BlocProvider.value(
                                                  value: context.read<AuthBloc>(),
                                                ),
                                                BlocProvider.value(
                                                  value: context.read<NotificationBloc>(),
                                                ),
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
                                          constraints: const BoxConstraints(
                                            minWidth: 18,
                                            minHeight: 18,
                                          ),
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
                    const SizedBox(height: 20),
                    // Search Bar
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
                                hintText: 'Search for crops, vegetables...',
                                hintStyle: TextStyle(color: Colors.grey[400]),
                                border: InputBorder.none,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.tune, color: Color(0xFF2196F3)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Categories - Static Data
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length + 1, // +1 for "All" category
                        itemBuilder: (context, index) {
                          // First item is "All"
                          if (index == 0) {
                            return _CategoryCard(
                              icon: Icons.grid_view,
                              label: 'All',
                              color: const Color(0xFF2196F3),
                              isSelected: _selectedCategoryId == null,
                              onTap: () {
                                _onCategorySelected(null);
                              },
                            );
                          }
                          
                          final category = _categories[index - 1];
                          final colors = [
                            const Color(0xFFFF9800),
                            const Color(0xFF4CAF50),
                            const Color(0xFFE91E63),
                            const Color(0xFF009688),
                            const Color(0xFF9C27B0),
                            const Color(0xFF2196F3),
                            const Color(0xFFFF5722),
                            const Color(0xFF795548),
                          ];
                          return _CategoryCard(
                            icon: category['icon'] as IconData,
                            label: category['name'] as String,
                            color: colors[(index - 1) % colors.length],
                            isSelected: _selectedCategoryId == category['id'],
                            onTap: () {
                              _onCategorySelected(category['id'] as int);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Featured Products Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategoryId == null 
                          ? 'All Products' 
                          : '${_categories.firstWhere((c) => c['id'] == _selectedCategoryId, orElse: () => {'name': 'Featured'})['name']} Products',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        // Clear category filter and show all products
                        _onCategorySelected(null);
                      },
                      child: Text(
                        _selectedCategoryId == null ? 'Refresh' : 'View All',
                        style: const TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid - Dynamic Data from Backend
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ),
                  );
                }

                if (state is ProductError) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 60,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error: ${state.message}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                context.read<ProductBloc>().add(
                                  LoadProducts(
                                    categoryId: _selectedCategoryId,
                                    availableOnly: true,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2196F3),
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                if (state is ProductsLoaded) {
                  if (state.products.isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.shopping_basket_outlined,
                                size: 60,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No products available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Check back later for fresh produce!',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.68,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final product = state.products[index];
                          return _ProductCard(
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

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    ));
  }

  IconData _getProductIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('grain') || name.contains('pulses')) return Icons.grain;
    if (name.contains('vegetable')) return Icons.local_pizza;
    if (name.contains('fruit')) return Icons.apple;
    if (name.contains('dairy')) return Icons.emoji_food_beverage;
    if (name.contains('poultry')) return Icons.egg_alt;
    if (name.contains('spice')) return Icons.spa;
    if (name.contains('honey')) return Icons.water_drop;
    if (name.contains('organic')) return Icons.eco;
    if (name.contains('seed')) return Icons.scatter_plot;
    return Icons.shopping_basket;
  }
}

// Category Card Widget
class _CategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
    this.isSelected = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isSelected ? Border.all(color: color, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.1 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.3) : color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon, 
                color: isSelected ? Colors.white : color, 
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Product Card Widget
class _ProductCard extends StatelessWidget {
  final int productId;
  final String name;
  final String price;
  final String unit;
  final String farmer;
  final int? farmerId;
  final String location;
  final double rating;
  final IconData imageIcon;
  final String? imageUrl;
  final bool isOrganic;

  const _ProductCard({
    required this.productId,
    required this.name,
    required this.price,
    required this.unit,
    required this.farmer,
    this.farmerId,
    required this.location,
    required this.rating,
    required this.imageIcon,
    this.imageUrl,
    this.isOrganic = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder or real image
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: imageUrl == null
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.3),
                          AppTheme.lightGreen.withOpacity(0.2)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Icon(
                              imageIcon,
                              size: 40,
                              color: AppTheme.primaryGreen.withOpacity(0.5),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Center(
                      child: Icon(
                        imageIcon,
                        size: 40,
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ),
                  // Organic badge
                  if (isOrganic)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco,
                              size: 12,
                              color: Colors.white,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Organic',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Product Info
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 12, color: Colors.amber),
                      const SizedBox(width: 3),
                      Text(
                        rating.toString(),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.person, size: 11, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          farmer,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 11, color: Colors.grey[600]),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Price and Action Buttons
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Rs. $price',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2196F3),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'per $unit',
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          // Add to Cart Button
                          GestureDetector(
                            onTap: () {
                              final authState = context.read<AuthBloc>().state;
                              if (authState is! AuthSuccess) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Please log in to add to cart'),
                                  ),
                                );
                                return;
                              }
                              
                              context.read<CartBloc>().add(
                                AddToCart(
                                  token: authState.token,
                                  productId: productId,
                                  quantity: 1,
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryGreen,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(
                                Icons.add_shopping_cart,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (farmerId != null) ...[
                            const SizedBox(width: 6),
                            // Chat Button
                            GestureDetector(
                              onTap: () async {
                                // Get the auth token
                                final authBloc = context.read<AuthBloc>();
                                final authState = authBloc.state;
                                
                                if (authState is! AuthSuccess) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please log in to chat'),
                                    ),
                                  );
                                  return;
                                }

                              // Show loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                                try {
                                  // Create or get chat room with the farmer
                                  final chatBloc = ChatBloc(
                                    chatRepository: ChatRepository(),
                                    token: authState.token,
                                  );
                                  
                                  // Listen for the ChatRoomCreated state
                                  final subscription = chatBloc.stream.listen((state) {
                                    if (state is ChatRoomCreated) {
                                      // Close loading dialog
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        
                                        // Navigate to chat screen with actual room ID
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => BuyerChatScreen(
                                              userName: farmer,
                                              userRole: 'Farmer',
                                              chatRoomId: state.chatRoom.id,
                                            ),
                                          ),
                                        );
                                      }
                                    } else if (state is ChatError) {
                                      // Close loading dialog and show error
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Failed to create chat: ${state.message}'),
                                          ),
                                        );
                                      }
                                    }
                                  });
                                  
                                  // Trigger the creation
                                  chatBloc.add(CreateChatRoom(
                                    participantIds: [farmerId!],
                                  ));
                                  
                                  // Cancel subscription after 10 seconds to prevent memory leaks
                                  Future.delayed(const Duration(seconds: 10), () {
                                    subscription.cancel();
                                  });
                                } catch (e) {
                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to create chat: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.chat_bubble,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      );
    
  }
}

// Buyer Profile Screen
class BuyerProfileScreen extends StatelessWidget {
  const BuyerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthSuccess ? authState.user : null;
          
          return Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            body: SafeArea(
              child: Column(
                children: [
                  // Blue Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Profile Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              size: 40,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Name
                          Text(
                            user?.fullName ?? 'John Doe',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Role
                          Text(
                            user?.role.toUpperCase() ?? 'BUYER',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Email
                          Text(
                            user?.email ?? 'john.doe@example.com',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Menu Items
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        children: [
                          _BuyerProfileMenuItem(
                            icon: Icons.person_outline,
                            iconColor: const Color(0xFF2196F3),
                            title: 'Edit Profile',
                            onTap: () {
                              // TODO: Navigate to edit profile
                            },
                          ),
                          _BuyerProfileMenuItem(
                            icon: Icons.notifications_outlined,
                            iconColor: const Color(0xFF2196F3),
                            title: 'Notifications',
                            onTap: () {
                              // TODO: Navigate to notifications
                            },
                          ),
                          _BuyerProfileMenuItem(
                            icon: Icons.help_outline,
                            iconColor: const Color(0xFF2196F3),
                            title: 'Help & Support',
                            onTap: () {
                              // TODO: Navigate to help & support
                            },
                          ),
                          _BuyerProfileMenuItem(
                            icon: Icons.shield_outlined,
                            iconColor: const Color(0xFF2196F3),
                            title: 'Privacy Policy',
                            onTap: () {
                              // TODO: Navigate to privacy policy
                            },
                          ),
                          _BuyerProfileMenuItem(
                            icon: Icons.info_outline,
                            iconColor: const Color(0xFF2196F3),
                            title: 'About',
                            onTap: () {
                              // TODO: Navigate to about
                            },
                          ),
                          const Spacer(),
                          // Logout Button
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Logout'),
                                      content: const Text('Are you sure you want to logout?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text('Cancel'),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pop(context);
                                            context.read<AuthBloc>().add(LogoutRequested());
                                          },
                                          child: const Text(
                                            'Logout',
                                            style: TextStyle(color: Colors.red),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.logout),
                                label: const Text(
                                  'Logout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE53935),
                                  foregroundColor: Colors.white,
                                  elevation: 2,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Buyer Profile Menu Item Widget
class _BuyerProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final VoidCallback onTap;

  const _BuyerProfileMenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

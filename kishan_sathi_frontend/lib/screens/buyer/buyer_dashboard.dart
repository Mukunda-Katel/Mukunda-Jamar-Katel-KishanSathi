import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../bloc/product/product_bloc.dart';
import '../../repositories/product_repository.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const BuyerHomeScreen(),
    const Center(child: Text('Community - Coming Soon')),
    const Center(child: Text('Orders - Coming Soon')),
    const Center(child: Text('Favorites - Coming Soon')),
    const Center(child: Text('Profile - Coming Soon')),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(productRepository: ProductRepository()),
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
                  _buildNavItem(Icons.receipt_long, 'Orders', 2),
                  _buildNavItem(Icons.favorite, 'Favorites', 3),
                  _buildNavItem(Icons.person, 'Profile', 4),
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

  // Static products data
  final List<Map<String, dynamic>> _products = [
    {
      'name': 'Fresh Tomatoes',
      'price': '80',
      'unit': 'per kg',
      'farmer': 'Ram Sharma',
      'location': 'Kathmandu',
      'rating': 4.5,
      'category': 'Vegetables',
    },
    {
      'name': 'Organic Potatoes',
      'price': '60',
      'unit': 'per kg',
      'farmer': 'Sita Devi',
      'location': 'Pokhara',
      'rating': 4.8,
      'category': 'Vegetables',
    },
    {
      'name': 'Fresh Apples',
      'price': '250',
      'unit': 'per kg',
      'farmer': 'Krishna Kumar',
      'location': 'Mustang',
      'rating': 4.7,
      'category': 'Fruits',
    },
    {
      'name': 'Basmati Rice',
      'price': '120',
      'unit': 'per kg',
      'farmer': 'Hari Prasad',
      'location': 'Jhapa',
      'rating': 4.6,
      'category': 'Grains',
    },
    {
      'name': 'Fresh Milk',
      'price': '80',
      'unit': 'per liter',
      'farmer': 'Gita Sharma',
      'location': 'Chitwan',
      'rating': 4.9,
      'category': 'Dairy',
    },
    
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        Stack(
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            Positioned(
                              right: 8,
                              top: 8,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Text(
                                  '2',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
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
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
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
                            color: colors[index % colors.length],
                            onTap: () {
                              // Filter products by category (optional)
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
                    const Text(
                      'Featured Products',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: Color(0xFF2196F3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Product Grid - Static Data
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _products[index];
                    return _ProductCard(
                      name: product['name'] as String,
                      price: product['price'] as String,
                      unit: product['unit'] as String,
                      farmer: product['farmer'] as String,
                      location: product['location'] as String,
                      rating: product['rating'] as double,
                      imageIcon: _getProductIcon(product['category'] as String),
                      imageUrl: null,
                    );
                  },
                  childCount: _products.length,
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    final name = categoryName.toLowerCase();
    if (name.contains('grain') || name.contains('pulses')) return Icons.grain;
    if (name.contains('vegetable')) return Icons.eco;
    if (name.contains('fruit')) return Icons.apple;
    if (name.contains('dairy')) return Icons.emoji_food_beverage;
    if (name.contains('poultry')) return Icons.egg_alt;
    if (name.contains('spice')) return Icons.spa;
    if (name.contains('honey')) return Icons.water_drop;
    if (name.contains('organic')) return Icons.local_florist;
    if (name.contains('seed')) return Icons.scatter_plot;
    return Icons.category;
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
  final VoidCallback onTap;

  const _CategoryCard({
    required this.icon,
    required this.label,
    required this.color,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
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
  final String name;
  final String price;
  final String unit;
  final String farmer;
  final String location;
  final double rating;
  final IconData imageIcon;
  final String? imageUrl;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.unit,
    required this.farmer,
    required this.location,
    required this.rating,
    required this.imageIcon,
    this.imageUrl,
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
            flex: 5,
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.favorite_border,
                        size: 16,
                        color: Colors.grey,
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
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
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
                  const SizedBox(height: 3),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
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
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2196F3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.add_shopping_cart,
                          size: 14,
                          color: Colors.white,
                        ),
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

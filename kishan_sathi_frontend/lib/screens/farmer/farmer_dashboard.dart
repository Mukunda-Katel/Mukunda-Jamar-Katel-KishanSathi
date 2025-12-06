// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../theme/app_theme.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../bloc/product/product_bloc.dart';
import '../../bloc/product/product_event.dart';
import '../../bloc/product/product_state.dart';
import '../../repositories/product_repository.dart';
import 'add_product_screen.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FarmerHomeScreen(),
    const MyCropsScreen(),
    const MarketplaceScreen(),
    const ConsultationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ProductBloc(productRepository: ProductRepository()),
      child: Scaffold(
        body: _screens[_selectedIndex],
        floatingActionButton: _selectedIndex == 0 || _selectedIndex == 1
            ? FloatingActionButton.extended(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddProductScreen(),
                    ),
                  );
                  
                  // Reload products if a product was added
                  if (result == true) {
                    final authState = context.read<AuthBloc>().state;
                    if (authState is AuthSuccess) {
                      context.read<ProductBloc>().add(LoadMyProducts(authState.token));
                    }
                  }
                },
                backgroundColor: AppTheme.primaryGreen,
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Add Product',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                elevation: 4,
              )
            : null,
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
                  _buildNavItem(Icons.eco, 'My Crops', 1),
                  _buildNavItem(Icons.store, 'Market', 2),
                  _buildNavItem(Icons.medical_services, 'Consult', 3),
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
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryGreen : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey,
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
class FarmerHomeScreen extends StatefulWidget {
  const FarmerHomeScreen({super.key});

  @override
  State<FarmerHomeScreen> createState() => _FarmerHomeScreenState();
}

class _FarmerHomeScreenState extends State<FarmerHomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load farmer's products when screen initializes
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<ProductBloc>().add(LoadMyProducts(authState.token));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        // Get farmer name from auth state, fallback to "Farmer"
        final farmerName = authState is AuthSuccess 
            ? authState.user.fullName 
            : 'Farmer';

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
                        colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
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
                                  'Welcome Back! 👋',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farmerName,
                                  style: const TextStyle(
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
                                      '3',
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
                        // Weather Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.wb_sunny,
                                    color: Colors.yellow[100],
                                    size: 40,
                                  ),
                                  const SizedBox(width: 12),
                                  const Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '28°C',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'Partly Cloudy',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'Kathmandu',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Humidity: 65%',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.add_circle_outline,
                                label: 'Add Crop',
                                color: AppTheme.primaryGreen,
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.local_offer,
                                label: 'Sell Product',
                                color: const Color(0xFF2196F3),
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.chat_bubble_outline,
                                label: 'Ask Expert',
                                color: const Color(0xFFFF9800),
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.trending_up,
                                label: 'Market Trends',
                                color: const Color(0xFF9C27B0),
                                onTap: () {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // My Active Crops
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'My Active Crops',
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
                              color: AppTheme.primaryGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Crop Cards - BLoC Integration
                BlocBuilder<ProductBloc, ProductState>(
                  builder: (context, state) {
                    if (state is ProductLoading) {
                      return const SliverFillRemaining(
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (state is ProductError) {
                      return SliverFillRemaining(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline, size: 48, color: Colors.red),
                              const SizedBox(height: 16),
                              Text(
                                'Failed to load products',
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: () {
                                  final authState = context.read<AuthBloc>().state;
                                  if (authState is AuthSuccess) {
                                    context.read<ProductBloc>().add(LoadMyProducts(authState.token));
                                  }
                                },
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    if (state is MyProductsLoaded) {
                      if (state.myProducts.isEmpty) {
                        return SliverFillRemaining(
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.eco_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No products yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start by adding your first product',
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = state.myProducts[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == state.myProducts.length - 1 ? 20 : 12,
                                ),
                                child: _CropCard(
                                  cropName: product.name,
                                  area: '${product.quantity} ${product.unitDisplay}',
                                  plantedDate: _formatDate(product.createdAt),
                                  status: product.statusDisplay,
                                  health: product.isAvailable ? 85 : 65,
                                  imageUrl: product.image,
                                  price: '₹${product.price}',
                                  location: product.location,
                                ),
                              );
                            },
                            childCount: state.myProducts.length,
                          ),
                        ),
                      );
                    }

                    // Initial state - show loading
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

// Quick Action Card Widget
class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
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
        padding: const EdgeInsets.all(16),
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
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
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

// Crop Card Widget
class _CropCard extends StatelessWidget {
  final String cropName;
  final String area;
  final String plantedDate;
  final String status;
  final int health;
  final String? imageUrl;
  final String? price;
  final String? location;

  const _CropCard({
    required this.cropName,
    required this.area,
    required this.plantedDate,
    required this.status,
    required this.health,
    this.imageUrl,
    this.price,
    this.location,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor = health >= 80
        ? AppTheme.primaryGreen
        : health >= 60
            ? const Color(0xFFFF9800)
            : AppTheme.errorRed;

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
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: imageUrl != null && imageUrl!.isNotEmpty
                ? Image.network(
                    imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [AppTheme.primaryGreen.withOpacity(0.3), AppTheme.lightGreen.withOpacity(0.2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.eco,
                            size: 60,
                            color: AppTheme.primaryGreen.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  )
                : Container(
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryGreen.withOpacity(0.3), AppTheme.lightGreen.withOpacity(0.2)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.eco,
                        size: 60,
                        color: AppTheme.primaryGreen.withOpacity(0.5),
                      ),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cropName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      area,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      plantedDate,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.currency_rupee, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        price!,
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (location != null) ...[
                        Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryGreen,
                          side: const BorderSide(color: AppTheme.primaryGreen),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('View Details'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Update'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder screens
class MyCropsScreen extends StatelessWidget {
  const MyCropsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('My Crops Screen'),
      ),
    );
  }
}

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Marketplace Screen'),
      ),
    );
  }
}

class ConsultationScreen extends StatelessWidget {
  const ConsultationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Consultation Screen'),
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Profile Screen'),
      ),
    );
  }
}

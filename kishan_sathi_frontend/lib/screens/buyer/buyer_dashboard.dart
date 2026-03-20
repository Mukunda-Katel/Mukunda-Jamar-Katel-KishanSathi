import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../features/cart/data/repositories/cart_repository.dart';
import '../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../features/notification/data/repositories/notification_repository.dart';
import '../../features/notification/presentation/bloc/notification_bloc.dart';
import '../../features/product/data/models/product_model.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../community/community_feed_screen.dart';
import 'buyer_favorites_screen.dart';
import 'buyer_home_screen.dart';
import 'buyer_profile_screen.dart';
import 'chat_list_screen.dart';

class BuyerDashboard extends StatefulWidget {
  const BuyerDashboard({super.key});

  @override
  State<BuyerDashboard> createState() => _BuyerDashboardState();
}

class _BuyerDashboardState extends State<BuyerDashboard> {
  int _selectedIndex = 0;
  final Set<int> _favoriteProductIds = <int>{};
  final Map<int, Product> _productCache = <int, Product>{};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final storedIds = prefs.getStringList(AppConstants.favoriteProductIdsKey) ?? [];
    final parsedIds = storedIds.map(int.tryParse).whereType<int>().toSet();

    if (!mounted) {
      return;
    }

    setState(() {
      _favoriteProductIds
        ..clear()
        ..addAll(parsedIds);
    });
  }

  Future<void> _persistFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoriteIdsAsString = _favoriteProductIds.map((id) => id.toString()).toList();
    await prefs.setStringList(AppConstants.favoriteProductIdsKey, favoriteIdsAsString);
  }

  void _toggleFavorite(int productId) {
    setState(() {
      if (_favoriteProductIds.contains(productId)) {
        _favoriteProductIds.remove(productId);
      } else {
        _favoriteProductIds.add(productId);
      }
    });
    _persistFavorites();
  }

  void _cacheProducts(List<Product> products) {
    for (final product in products) {
      _productCache[product.id] = product;
    }
  }

  List<Widget> _buildScreens() {
    return [
      BuyerHomeScreen(
        favoriteProductIds: _favoriteProductIds,
        onToggleFavorite: _toggleFavorite,
        onProductsLoaded: _cacheProducts,
      ),
      const CommunityFeedScreen(),
      const BuyerChatListScreen(),
      const Center(child: Text('Orders - Coming Soon')),
      BuyerFavoritesScreen(
        allProducts: _productCache.values.toList(),
        favoriteProductIds: _favoriteProductIds,
        onToggleFavorite: _toggleFavorite,
      ),
      const BuyerProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompactNav = screenWidth < 420;

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
            notificationRepository: NotificationRepository(),
          ),
        ),
      ],
      child: Scaffold(
        body: _buildScreens()[_selectedIndex],
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
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(child: _buildNavItem(Icons.home, l10n.home, 0, isCompactNav)),
                      Expanded(child: _buildNavItem(Icons.groups, l10n.community, 1, isCompactNav)),
                      Expanded(child: _buildNavItem(Icons.chat, l10n.chat, 2, isCompactNav)),
                      Expanded(child: _buildNavItem(Icons.favorite, l10n.favorites, 4, isCompactNav)),
                      Expanded(child: _buildNavItem(Icons.person, l10n.profile, 5, isCompactNav)),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isCompactNav) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isCompactNav ? 6 : 10, vertical: 8),
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
              size: isCompactNav ? 20 : 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? const Color(0xFF2196F3) : Colors.grey,
                fontSize: isCompactNav ? 9 : 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

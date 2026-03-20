import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../core/theme/app_theme.dart';
import '../../features/product/data/models/product_model.dart';
import 'widgets/buyer_home_widgets.dart';

class BuyerFavoritesScreen extends StatelessWidget {
  final List<Product> allProducts;
  final Set<int> favoriteProductIds;
  final ValueChanged<int> onToggleFavorite;

  const BuyerFavoritesScreen({
    super.key,
    required this.allProducts,
    required this.favoriteProductIds,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 600 ? 16.0 : 20.0;
    final gridCrossAxisCount = screenWidth >= 1200
        ? 4
        : screenWidth >= 900
            ? 3
            : 2;

    final favoriteProducts = allProducts.where((p) => favoriteProductIds.contains(p.id)).toList();
    final favoriteCategories = favoriteProducts.map((p) => p.categoryName.toLowerCase()).toSet();
    final relatedProducts = allProducts
        .where(
          (p) => !favoriteProductIds.contains(p.id) && favoriteCategories.contains(p.categoryName.toLowerCase()),
        )
        .toList();

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.all(horizontalPadding),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFE91E63), Color(0xFFF06292)],
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
                    Text(
                      AppLocalizations.of(context)!.favorites,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${favoriteProducts.length} saved products',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (favoriteProducts.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(30),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.favorite_border, size: 72, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No favorites yet',
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the heart icon on any product to save it here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 10),
                  child: const Text(
                    'Your Favorites',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCrossAxisCount,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = favoriteProducts[index];
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
                        isFavorite: true,
                        onFavoriteTap: () => onToggleFavorite(product.id),
                      );
                    },
                    childCount: favoriteProducts.length,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 10),
                  child: const Text(
                    'Similar Category Products',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                  ),
                ),
              ),
              if (relatedProducts.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'No related products available right now.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
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
                        final product = relatedProducts[index];
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
                          isFavorite: favoriteProductIds.contains(product.id),
                          onFavoriteTap: () => onToggleFavorite(product.id),
                        );
                      },
                      childCount: relatedProducts.length,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
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

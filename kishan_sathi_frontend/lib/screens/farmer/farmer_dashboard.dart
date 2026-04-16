// ignore_for_file: deprecated_member_use

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:kishan_sathi_frontend/features/auth/presentation/bloc/auth_event.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/product/presentation/bloc/product_bloc.dart';
import '../../features/product/presentation/bloc/product_event.dart';
import '../../features/product/presentation/bloc/product_state.dart';
import '../../features/product/data/repositories/product_repository_impl.dart';
import 'add_product_screen.dart';
import 'chat_list_screen.dart';
import 'consultation_screen.dart';
import 'weather_widget.dart';
import '../community/community_feed_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../settings/language_settings_screen.dart';
import 'ai_chatbot_screen.dart';
import '../../features/chatbot/presentation/bloc/chatbot_bloc.dart';
import '../../features/chatbot/data/services/chatbot_service.dart';
import '../../features/payment/data/datasources/khalti_remote_data_source.dart';

class FarmerDashboard extends StatefulWidget {
  const FarmerDashboard({super.key});

  @override
  State<FarmerDashboard> createState() => _FarmerDashboardState();
}

class _FarmerDashboardState extends State<FarmerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const FarmerHomeScreen(),
    const CommunityFeedScreen(),
    const ChatListScreen(),
    const FarmerConsultationScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenWidth = mediaQuery.size.width;
    final textScaleFactor = mediaQuery.textScaleFactor.clamp(0.9, 1.2);

    final isTinyScreen = screenWidth < 360;
    final isCompactNav = screenWidth < 420;
    final isTablet = screenWidth >= 768;

    final navHorizontalPadding = isTablet ? 20.0 : (isTinyScreen ? 4.0 : 8.0);
    final navVerticalPadding = isTablet ? 8.0 : (isTinyScreen ? 4.0 : 6.0);
    final navMinHeight = isTablet ? 72.0 : (isTinyScreen ? 56.0 : 62.0);
    final iconSize = isTablet ? 26.0 : (isTinyScreen ? 18.0 : (isCompactNav ? 20.0 : 24.0));
    final labelFontSize = (isTablet ? 12.0 : (isTinyScreen ? 8.0 : (isCompactNav ? 9.0 : 11.0))) /
        textScaleFactor;

    return BlocProvider(
      create: (context) => ProductBloc(productRepository: ProductRepository()),
      child: Scaffold(
        body: _screens[_selectedIndex],
        floatingActionButton: _selectedIndex == 0
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
                label: Builder(
                  builder: (context) => Text(
                    AppLocalizations.of(context)!.addProduct,
                    style: const TextStyle(
                    color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                elevation: 4,
              )
            : null,
        bottomNavigationBar: Container(
          constraints: BoxConstraints(minHeight: navMinHeight),
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
              padding: EdgeInsets.symmetric(
                horizontal: navHorizontalPadding,
                vertical: navVerticalPadding,
              ),
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context)!;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.home,
                          label: l10n.home,
                          index: 0,
                          isCompactNav: isCompactNav,
                          iconSize: iconSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.groups,
                          label: l10n.community,
                          index: 1,
                          isCompactNav: isCompactNav,
                          iconSize: iconSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.chat,
                          label: l10n.chat,
                          index: 2,
                          isCompactNav: isCompactNav,
                          iconSize: iconSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.medical_services,
                          label: l10n.consult,
                          index: 3,
                          isCompactNav: isCompactNav,
                          iconSize: iconSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
                      Expanded(
                        child: _buildNavItem(
                          icon: Icons.person,
                          label: l10n.profile,
                          index: 4,
                          isCompactNav: isCompactNav,
                          iconSize: iconSize,
                          labelFontSize: labelFontSize,
                        ),
                      ),
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

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required int index,
    required bool isCompactNav,
    required double iconSize,
    required double labelFontSize,
  }) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(horizontal: isCompactNav ? 6 : 8, vertical: 4),
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
              size: iconSize,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppTheme.primaryGreen : Colors.grey,
                fontSize: labelFontSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isTinyScreen ? 12.0 : (isSmallScreen ? 16.0 : 20.0);
    final headerTitleSize = isTinyScreen ? 20.0 : (isSmallScreen ? 22.0 : 24.0);
    final headerSubtitleSize = isTinyScreen ? 13.0 : 16.0;
    final notificationIconSize = isTinyScreen ? 24.0 : 28.0;
    final sectionTitleSize = isTinyScreen ? 18.0 : 20.0;
    final quickActionGap = isTinyScreen ? 8.0 : 12.0;
    final quickActionTopGap = isTinyScreen ? 12.0 : 16.0;
    final listBottomGap = isTinyScreen ? 16.0 : 20.0;

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
                    padding: EdgeInsets.all(horizontalPadding),
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
                                  AppLocalizations.of(context)!.welcomeBack,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: headerSubtitleSize,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farmerName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: headerTitleSize,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Stack(
                              children: [
                                IconButton(
                                  onPressed: () {},
                                  icon: Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: notificationIconSize,
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
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Weather Widget
                const SliverToBoxAdapter(
                  child: WeatherWidget(location: 'Kathmandu'),
                ),

                // Quick Actions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.quickActions,
                          style: TextStyle(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                        SizedBox(height: quickActionTopGap),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.eco,
                                label: AppLocalizations.of(context)!.myCrops,
                                color: AppTheme.primaryGreen,
                                onTap: () {
                                  final authState = context.read<AuthBloc>().state;
                                  if (authState is AuthSuccess) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => BlocProvider(
                                          create: (context) => ProductBloc(
                                            productRepository: ProductRepository(),
                                          )..add(LoadMyProducts(authState.token)),
                                          child: const MyCropsScreen(),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            SizedBox(width: quickActionGap),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.smart_toy,
                                label: AppLocalizations.of(context)!.aiAssistant,
                                color: const Color(0xFFFF9800),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => BlocProvider(
                                        create: (context) => ChatbotBloc(
                                          chatbotService: ChatbotService(),
                                        ),
                                        child: const AIChatbotScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: quickActionGap),
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.add_circle_outline,
                                label: AppLocalizations.of(context)!.addCrop,
                                color: const Color(0xFF2196F3),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const AddProductScreen(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            SizedBox(width: quickActionGap),
                            Expanded(
                              child: _QuickActionCard(
                                icon: Icons.trending_up,
                                label: AppLocalizations.of(context)!.marketTrends,
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
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.myActiveCrops,
                          style: TextStyle(
                            fontSize: sectionTitleSize,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGreen,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            AppLocalizations.of(context)!.viewAll,
                            style: const TextStyle(
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
                                AppLocalizations.of(context)!.failedToLoad,
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
                                child: Text(AppLocalizations.of(context)!.retry),
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
                                  AppLocalizations.of(context)!.noProductsYet,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)!.startByAdding,
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      return SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final product = state.myProducts[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == state.myProducts.length - 1 ? listBottomGap : quickActionGap,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final cardPadding = isTinyScreen ? 12.0 : 16.0;
    final iconPadding = isTinyScreen ? 9.0 : 12.0;
    final iconSize = isTinyScreen ? 24.0 : 28.0;
    final labelSize = isTinyScreen ? 12.0 : 13.0;
    final spacing = isTinyScreen ? 6.0 : 8.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(cardPadding),
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
              padding: EdgeInsets.all(iconPadding),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
            ),
            SizedBox(height: spacing),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: labelSize,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;
    final imageHeight = isTinyScreen ? 120.0 : (isSmallScreen ? 132.0 : 140.0);
    final cardPadding = isTinyScreen ? 12.0 : 16.0;
    final titleSize = isTinyScreen ? 16.0 : 18.0;
    final statusFontSize = isTinyScreen ? 10.0 : 11.0;
    final metaIconSize = isTinyScreen ? 14.0 : 16.0;
    final metaFontSize = isTinyScreen ? 12.0 : 13.0;
    final priceSize = isTinyScreen ? 14.0 : 15.0;

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
                    height: imageHeight,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: imageHeight,
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
                  height: imageHeight,
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
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cropName,
                      style: TextStyle(
                        fontSize: titleSize,
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
                          fontSize: statusFontSize,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: metaIconSize, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      area,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: metaFontSize,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today, size: metaIconSize, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      plantedDate,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: metaFontSize,
                      ),
                    ),
                  ],
                ),
                if (price != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.currency_rupee, size: metaIconSize, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        price!,
                        style: TextStyle(
                          color: AppTheme.primaryGreen,
                          fontSize: priceSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (location != null) ...[
                        Icon(Icons.location_on_outlined, size: metaIconSize, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            location!,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: metaFontSize,
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
class MyCropsScreen extends StatefulWidget {
  const MyCropsScreen({super.key});

  @override
  State<MyCropsScreen> createState() => _MyCropsScreenState();
}

class _MyCropsScreenState extends State<MyCropsScreen> {
  @override
  void initState() {
    super.initState();
    // Load farmer's products
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      context.read<ProductBloc>().add(LoadMyProducts(authState.token));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.marketplace,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        // TODO: Implement search
                      },
                      icon: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Statistics Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primaryGreen, AppTheme.lightGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatCard(
                        icon: Icons.attach_money,
                        value: 'Rs. 45,000',
                        label: AppLocalizations.of(context)!.totalSales,
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _StatCard(
                        icon: Icons.inventory_2,
                        value: '12',
                        label: AppLocalizations.of(context)!.products,
                      ),
                      Container(
                        height: 50,
                        width: 1,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _StatCard(
                        icon: Icons.shopping_bag,
                        value: '28',
                        label: AppLocalizations.of(context)!.orders,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // My Products Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.myProducts,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.darkGreen,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AddProductScreen(),
                          ),
                        );
                        
                        if (result == true) {
                          final authState = context.read<AuthBloc>().state;
                          if (authState is AuthSuccess) {
                            context.read<ProductBloc>().add(LoadMyProducts(authState.token));
                          }
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(AppLocalizations.of(context)!.addProduct),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Products Grid
            BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  );
                }

                if (state is ProductError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
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
                              final authState = context.read<AuthBloc>().state;
                              if (authState is AuthSuccess) {
                                context.read<ProductBloc>().add(LoadMyProducts(authState.token));
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(AppLocalizations.of(context)!.retry),
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
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 60,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noProductsYet,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              AppLocalizations.of(context)!.addYourFirstProduct,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
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
                          final product = state.myProducts[index];
                          return _MyProductCard(
                            product: product,
                            onMenuTap: () {
                              _showProductMenu(context, product);
                            },
                          );
                        },
                        childCount: state.myProducts.length,
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
    );
  }

  void _showProductMenu(BuildContext context, dynamic product) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryGreen),
              title: Text(AppLocalizations.of(context)!.editProduct),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to edit screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.blue),
              title: Text(AppLocalizations.of(context)!.viewDetails),
              onTap: () {
                Navigator.pop(context);
                // TODO: Navigate to details screen
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(AppLocalizations.of(context)!.deleteProduct),
              onTap: () {
                Navigator.pop(context);
                // TODO: Show delete confirmation
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Statistics Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// My Product Card Widget
class _MyProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onMenuTap;

  const _MyProductCard({
    required this.product,
    required this.onMenuTap,
  });

  @override
  Widget build(BuildContext context) {
    final soldQuantity = 120.0; // TODO: Get from backend
    
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
          // Product Image with menu
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: product.image != null && product.image!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          child: Image.network(
                            product.image!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.primaryGreen.withOpacity(0.3),
                                      AppTheme.lightGreen.withOpacity(0.2)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.eco,
                                    size: 40,
                                    color: AppTheme.primaryGreen.withOpacity(0.5),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppTheme.primaryGreen.withOpacity(0.3),
                                AppTheme.lightGreen.withOpacity(0.2)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.eco,
                              size: 40,
                              color: AppTheme.primaryGreen.withOpacity(0.5),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: onMenuTap,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.more_vert,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Product Info
          Expanded(
            flex: 4,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs. ${product.price}/${product.unit}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryGreen,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Icon(Icons.inventory_2, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '${product.quantity.toStringAsFixed(0)} ${product.unit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.check_circle, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        'Sold: ${soldQuantity.toStringAsFixed(0)} ${product.unit}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
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

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;
  bool _isLinkingKhalti = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileImageFromServer();
  }

  String _normalizedToken(String token) {
    final trimmed = token.trim();
    if (trimmed.startsWith('Token ')) {
      return trimmed.substring(6).trim();
    }
    if (trimmed.startsWith('Bearer ')) {
      return trimmed.substring(7).trim();
    }
    return trimmed;
  }

  String? _resolveImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')) {
      return rawUrl;
    }
    return AppConfig.getUrl(rawUrl.startsWith('/') ? rawUrl : '/$rawUrl');
  }

  Map<String, dynamic> _safeJsonObject(String rawBody) {
    if (rawBody.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(rawBody);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // Non-JSON responses are handled by caller.
    }
    return <String, dynamic>{};
  }

  String _buildUploadErrorMessage(http.Response response, Map<String, dynamic> body) {
    final apiMessage = (body['error'] ?? body['message'])?.toString();
    if (apiMessage != null && apiMessage.isNotEmpty) {
      return apiMessage;
    }

    final compact = response.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.toLowerCase().startsWith('<!doctype html') || compact.toLowerCase().startsWith('<html')) {
      return 'Server returned an HTML error page (status ${response.statusCode}). Please check backend logs.';
    }
    if (compact.isEmpty) {
      return 'Server error (status ${response.statusCode}).';
    }
    final preview = compact.length > 180 ? '${compact.substring(0, 180)}...' : compact;
    return 'Server error (status ${response.statusCode}): $preview';
  }

  Future<void> _loadProfileImageFromServer() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) return;

    try {
      final response = await http.get(
        Uri.parse(AppConfig.getUrl('/api/auth/profile/')),
        headers: {
          'Authorization': 'Token ${_normalizedToken(authState.token)}',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final imageUrl = _resolveImageUrl(body['profile_picture_url'] as String?);
        if (!mounted) return;
        setState(() {
          _profileImageUrl = imageUrl;
        });
        context.read<AuthBloc>().add(
              AuthUserUpdated(
                user: authState.user.copyWith(profilePictureUrl: imageUrl),
              ),
            );
      }
    } catch (_) {
      // Keep fallback avatar if profile fetch fails.
    }
  }

  Future<void> _pickAndUploadProfileImage({required String token}) async {
    if (_isUploadingImage) return;

    final pickedFile = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 1200,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse(AppConfig.getUrl('/api/auth/profile/')),
      );
      request.headers['Authorization'] = 'Token ${_normalizedToken(token)}';
      request.headers['Accept'] = 'application/json';
      request.files.add(
        await http.MultipartFile.fromPath('profile_picture', File(pickedFile.path).path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = _safeJsonObject(response.body);

      if (response.statusCode == 200) {
        final authState = context.read<AuthBloc>().state;
        final userData = body['user'] as Map<String, dynamic>?;
        final imageUrl = _resolveImageUrl(userData?['profile_picture_url'] as String?);
        if (!mounted) return;
        setState(() {
          _profileImageUrl = imageUrl;
        });
        if (authState is AuthSuccess) {
          context.read<AuthBloc>().add(
                AuthUserUpdated(
                  user: authState.user.copyWith(
                        profilePictureUrl: imageUrl,
                      ),
                ),
              );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final errorMessage = _buildUploadErrorMessage(response, body);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  String _buildTestKhaltiId(dynamic user) {
    final userId = user?.id is int ? user.id as int : 1;
    final suffix = (userId % 10000).toString().padLeft(4, '0');
    return '980000$suffix';
  }

  String _buildTestAccountName(dynamic user) {
    final fullName = (user?.fullName ?? '').toString().trim();
    if (fullName.isNotEmpty) return fullName;

    final email = (user?.email ?? '').toString().trim();
    if (email.isNotEmpty) return email;

    final userId = user?.id is int ? user.id as int : 0;
    return 'Farmer $userId';
  }

  Future<void> _linkSellerKhaltiTestAccount(AuthSuccess authState) async {
    if (_isLinkingKhalti) return;

    setState(() {
      _isLinkingKhalti = true;
    });

    final remoteDataSource = KhaltiRemoteDataSource();
    final testKhaltiId = _buildTestKhaltiId(authState.user);
    final accountName = _buildTestAccountName(authState.user);

    try {
      await remoteDataSource.linkKhaltiAccount(
        token: authState.token,
        khaltiId: testKhaltiId,
        accountName: accountName,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seller Khalti test account linked: $testKhaltiId'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      final errorText = e.toString().toLowerCase();
      final shouldUpdate = errorText.contains('already linked') || errorText.contains('already exists');

      if (shouldUpdate) {
        try {
          await remoteDataSource.updateKhaltiAccount(
            token: authState.token,
            khaltiId: testKhaltiId,
            accountName: accountName,
          );

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seller Khalti test account updated: $testKhaltiId'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (updateError) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update test Khalti account: $updateError'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link test Khalti account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLinkingKhalti = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isTinyScreen ? 12.0 : (isSmallScreen ? 16.0 : 20.0);
    final headerTitleSize = isTinyScreen ? 20.0 : 24.0;
    final profileTopGap = isTinyScreen ? 22.0 : 30.0;
    final avatarSize = isTinyScreen ? 80.0 : (isSmallScreen ? 90.0 : 100.0);
    final profileNameSize = isTinyScreen ? 20.0 : 24.0;
    final roleSize = isTinyScreen ? 13.0 : 14.0;
    final emailSize = isTinyScreen ? 12.0 : 13.0;
    final initialsSize = isTinyScreen ? 30.0 : 34.0;
    final statsDividerHeight = isTinyScreen ? 34.0 : 40.0;
    final statValueSize = isTinyScreen ? 18.0 : 22.0;
    final statLabelSize = isTinyScreen ? 10.0 : 12.0;
    final menuHorizontalPadding = isTinyScreen ? 16.0 : 20.0;
    final menuVerticalPadding = isTinyScreen ? 14.0 : 16.0;
    final menuIconSize = isTinyScreen ? 22.0 : 24.0;
    final menuTitleSize = isTinyScreen ? 15.0 : 16.0;
    final actionButtonHeight = isTinyScreen ? 52.0 : 56.0;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          // Navigate to auth screen and clear all previous routes
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/auth',
            (route) => false,
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthSuccess ? authState.user : null;
          final imageUrl = _profileImageUrl ?? _resolveImageUrl(user?.profilePictureUrl);
          
          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  // Green Header Section
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(horizontalPadding),
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
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            AppLocalizations.of(context)!.profile,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: headerTitleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      SizedBox(height: profileTopGap),
                      // Profile Picture with Edit Icon
                      Stack(
                        children: [
                          Container(
                            width: avatarSize,
                            height: avatarSize,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              image: imageUrl != null && imageUrl.isNotEmpty
                                  ? DecorationImage(
                                      image: NetworkImage(imageUrl),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: imageUrl == null || imageUrl.isEmpty
                                ? Center(
                                    child: Text(
                                      user?.initials ?? 'F',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: AppTheme.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                        fontSize: initialsSize,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: authState is AuthSuccess
                                  ? () => _pickAndUploadProfileImage(token: authState.token)
                                  : null,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: EdgeInsets.all(isTinyScreen ? 5 : 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: _isUploadingImage
                                    ? const SizedBox(
                                        height: 16,
                                        width: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.camera_alt,
                                        size: 16,
                                        color: AppTheme.primaryGreen,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: isTinyScreen ? 12 : 16),
                      // Name
                      Text(
                        user?.fullName ?? 'Ram Sharma',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: profileNameSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Role
                      Text(
                        user?.role.toUpperCase() ?? 'FARMER',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: roleSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Email
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isTinyScreen ? 12 : 16,
                          vertical: isTinyScreen ? 6 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user?.email ?? 'farmer@kishansathi.com',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: emailSize,
                          ),
                        ),
                      ),
                      SizedBox(height: isTinyScreen ? 18 : 24),
                      // Statistics Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _ProfileStat(
                            value: '6',
                            label: 'Active Crops',
                            valueFontSize: statValueSize,
                            labelFontSize: statLabelSize,
                          ),
                          Container(
                            height: statsDividerHeight,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _ProfileStat(
                            value: '28',
                            label: 'Products Sold',
                            valueFontSize: statValueSize,
                            labelFontSize: statLabelSize,
                          ),
                          Container(
                            height: statsDividerHeight,
                            width: 1,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          _ProfileStat(
                            value: '6.5 acres',
                            label: 'Total Land',
                            valueFontSize: statValueSize,
                            labelFontSize: statLabelSize,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // White Section with Menu Items
                Expanded(
                  child: Container(
                    color: Colors.white,
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        SizedBox(height: isTinyScreen ? 16 : 20),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: menuHorizontalPadding),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: authState is AuthSuccess && !_isLinkingKhalti
                                  ? () => _linkSellerKhaltiTestAccount(authState)
                                  : null,
                              icon: _isLinkingKhalti
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.account_balance_wallet_outlined),
                              label: Text(
                                _isLinkingKhalti
                                    ? 'Linking Test Khalti Account...'
                                    : 'Link Seller Khalti Account (Test)',
                                style: TextStyle(
                                  fontSize: isTinyScreen ? 13 : 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: isTinyScreen ? 12 : 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ProfileMenuItem(
                          icon: Icons.person_outline,
                          title: AppLocalizations.of(context)!.editProfile,
                          iconSize: menuIconSize,
                          titleFontSize: menuTitleSize,
                          horizontalPadding: menuHorizontalPadding,
                          verticalPadding: menuVerticalPadding,
                          onTap: () {
                            // TODO: Navigate to edit profile
                          },
                        ),
                        // _ProfileMenuItem(
                        //   icon: Icons.notifications_outlined,
                        //   title: AppLocalizations.of(context)!.notifications,
                        //   onTap: () {
                        //     // TODO: Navigate to notifications
                        //   },
                        // ),
                        _ProfileMenuItem(
                          icon: Icons.language,
                          title: AppLocalizations.of(context)!.language,
                          iconSize: menuIconSize,
                          titleFontSize: menuTitleSize,
                          horizontalPadding: menuHorizontalPadding,
                          verticalPadding: menuVerticalPadding,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LanguageSettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _ProfileMenuItem(
                          icon: Icons.settings_outlined,
                          title: AppLocalizations.of(context)!.settings,
                          iconSize: menuIconSize,
                          titleFontSize: menuTitleSize,
                          horizontalPadding: menuHorizontalPadding,
                          verticalPadding: menuVerticalPadding,
                          onTap: () {
                            // TODO: Navigate to settings
                          },
                        ),
                        _ProfileMenuItem(
                          icon: Icons.help_outline,
                          title: AppLocalizations.of(context)!.helpSupport,
                          iconSize: menuIconSize,
                          titleFontSize: menuTitleSize,
                          horizontalPadding: menuHorizontalPadding,
                          verticalPadding: menuVerticalPadding,
                          onTap: () {
                            // TODO: Navigate to help & support
                          },
                        ),
                        // Logout Button
                        Padding(
                          padding: EdgeInsets.all(menuHorizontalPadding),
                          child: SizedBox(
                            width: double.infinity,
                            height: actionButtonHeight,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: Text(AppLocalizations.of(context)!.logout),
                                    content: Text(AppLocalizations.of(context)!.logoutConfirmation),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(dialogContext),
                                        child: Text(AppLocalizations.of(context)!.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(dialogContext);
                                          context.read<AuthBloc>().add(LogoutRequested());
                                        },
                                        child: Text(
                                          AppLocalizations.of(context)!.logout,
                                          style: const TextStyle(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(Icons.logout),
                              label: Text(
                                AppLocalizations.of(context)!.logout,
                                style: TextStyle(
                                  fontSize: isTinyScreen ? 15 : 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFD32F2F),
                                foregroundColor: Colors.white,
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: isTinyScreen ? 8 : 10),
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

// Profile Stat Widget
class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final double valueFontSize;
  final double labelFontSize;

  const _ProfileStat({
    required this.value,
    required this.label,
    this.valueFontSize = 22,
    this.labelFontSize = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: valueFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: labelFontSize,
          ),
        ),
      ],
    );
  }
}

// Profile Menu Item Widget
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final double iconSize;
  final double titleFontSize;
  final double horizontalPadding;
  final double verticalPadding;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.iconSize = 24,
    this.titleFontSize = 16,
    this.horizontalPadding = 20,
    this.verticalPadding = 16,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
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
              color: AppTheme.primaryGreen,
              size: iconSize,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: iconSize,
            ),
          ],
        ),
      ),
    );
  }
}

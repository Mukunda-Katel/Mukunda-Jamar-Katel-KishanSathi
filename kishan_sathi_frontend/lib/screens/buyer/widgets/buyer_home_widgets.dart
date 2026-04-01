import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_theme.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/bloc/auth_state.dart';
import '../../../features/cart/presentation/bloc/cart_bloc.dart';
import '../../../features/cart/presentation/bloc/cart_event.dart';
import '../../../features/chat/data/repositories/chat_repository.dart';
import '../../../features/chat/presentation/bloc/chat_bloc.dart';
import '../../../features/chat/presentation/bloc/chat_event.dart';
import '../../../features/chat/presentation/bloc/chat_state.dart';
import '../chat_screen.dart';

class BuyerCategoryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const BuyerCategoryCard({
    super.key,
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

class BuyerProductCard extends StatelessWidget {
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
  final double availableQuantity;
  final String status;
  final bool isFavorite;
  final VoidCallback? onFavoriteTap;

  const BuyerProductCard({
    super.key,
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
    required this.availableQuantity,
    required this.status,
    this.isFavorite = false,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isAvailable = status == 'available' && availableQuantity > 0;

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
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                gradient: imageUrl == null
                    ? LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.3),
                          AppTheme.lightGreen.withOpacity(0.2),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  if (imageUrl != null && imageUrl!.isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(
                        imageUrl!,
                        width: double.infinity,
                        height: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _iconFallback();
                        },
                      ),
                    )
                  else
                    _iconFallback(),
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
                            Icon(Icons.eco, size: 12, color: Colors.white),
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: onFavoriteTap,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFavorite ? Colors.red : Colors.grey[700],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.all(7),
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
                  const SizedBox(height: 1),
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
                  const SizedBox(height: 1),
                  Row(
                    children: [
                      Icon(
                        isAvailable ? Icons.inventory_2 : Icons.block,
                        size: 11,
                        color: isAvailable ? Colors.green[600] : Colors.red[600],
                      ),
                      const SizedBox(width: 2),
                      Text(
                        isAvailable
                            ? '${availableQuantity.toStringAsFixed(0)} $unit available'
                            : 'Out of stock',
                        style: TextStyle(
                          fontSize: 10,
                          color: isAvailable ? Colors.green[700] : Colors.red[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 1),
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
                  const SizedBox(height: 1),
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
                        style: TextStyle(fontSize: 9, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: isAvailable ? () => _addToCart(context) : null,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isAvailable ? AppTheme.primaryGreen : Colors.grey[400],
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                isAvailable ? Icons.add_shopping_cart : Icons.remove_shopping_cart,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          if (farmerId != null) ...[
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => _openChat(context),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2196F3),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.chat_outlined,
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

  Widget _iconFallback() {
    return Center(
      child: Icon(
        imageIcon,
        size: 40,
        color: AppTheme.primaryGreen.withOpacity(0.5),
      ),
    );
  }

  void _addToCart(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to cart')),
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
  }

  Future<void> _openChat(BuildContext context) async {
    if (farmerId == null) {
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to chat')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final chatBloc = ChatBloc(
        chatRepository: ChatRepository(),
        token: authState.token,
      );

      final chatRoomFuture =
          chatBloc.stream.firstWhere((state) => state is ChatRoomCreated || state is ChatError);
      chatBloc.add(CreateChatRoom(participantIds: [farmerId!]));
      final chatState = await chatRoomFuture;

      if (!context.mounted) {
        return;
      }

      Navigator.pop(context);

      if (chatState is ChatRoomCreated) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (screenContext) => BuyerChatScreen(
              userName: farmer,
              userRole: 'Farmer',
              chatRoomId: chatState.chatRoom.id,
            ),
          ),
        );
      } else if (chatState is ChatError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(chatState.message.replaceFirst('Exception: ', ''))),
        );
      }
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to open chat. Please try again.')),
      );
    }
  }
}

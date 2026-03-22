import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'appointments_screen.dart';
import 'chat_requests_screen.dart';
import 'consultant_home_screen.dart';
import 'consultant_profile_screen.dart';
import 'create_article_bottom_sheet.dart';
import 'knowledge_base_screen.dart';

class ConsultantDashboard extends StatefulWidget {
  const ConsultantDashboard({super.key});

  @override
  State<ConsultantDashboard> createState() => _ConsultantDashboardState();
}

class _ConsultantDashboardState extends State<ConsultantDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    ConsultantHomeScreen(),
    AppointmentsScreen(),
    ChatRequestsScreen(),
    KnowledgeBaseScreen(),
    ConsultantProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      },
      child: Scaffold(
        body: _screens[_selectedIndex],
        floatingActionButton: _selectedIndex == 3
            ? FloatingActionButton.extended(
                onPressed: () {
                  _showCreateArticleDialog(context);
                },
                backgroundColor: const Color(0xFFFF9800),
                icon: const Icon(Icons.article, color: Colors.white),
                label: const Text(
                  'New Article',
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
                  _buildNavItem(Icons.dashboard, 'Home', 0),
                  _buildNavItem(Icons.post_add, 'Community', 1),
                  _buildNavItem(Icons.chat_bubble, 'Chats', 2),
                  _buildNavItem(Icons.library_books, 'Knowledge', 3),
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
          color: isSelected ? const Color(0xFFFF9800).withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFFFF9800) : Colors.grey,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateArticleDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CreateArticleBottomSheet(),
    );
  }
}

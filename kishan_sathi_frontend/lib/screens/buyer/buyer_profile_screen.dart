import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../settings/language_settings_screen.dart';

class BuyerProfileScreen extends StatefulWidget {
  const BuyerProfileScreen({super.key});

  @override
  State<BuyerProfileScreen> createState() => _BuyerProfileScreenState();
}

class _BuyerProfileScreenState extends State<BuyerProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;
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
        final fetchedUser = UserModel.fromJson(body);
        final url = _resolveImageUrl(body['profile_picture_url'] as String?);
        if (!mounted) return;
        setState(() {
          _profileImageUrl = url;
        });
        context.read<AuthBloc>().add(AuthUserUpdated(user: fetchedUser));
      }
    } catch (_) {
      // Keep existing UI fallback if profile fetch fails.
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
        final user = body['user'] as Map<String, dynamic>?;
        final updatedUser = user != null ? UserModel.fromJson(user) : null;
        final imageUrl = _resolveImageUrl(user?['profile_picture_url'] as String?);
        setState(() {
          _profileImageUrl = imageUrl;
        });
        if (updatedUser != null) {
          context.read<AuthBloc>().add(AuthUserUpdated(user: updatedUser));
        }
        if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;
    final horizontalPadding = isTinyScreen ? 12.0 : (isSmallScreen ? 16.0 : 24.0);
    final avatarSize = isTinyScreen ? 80.0 : (isSmallScreen ? 90.0 : 100.0);
    final nameSize = isTinyScreen ? 20.0 : 24.0;
    final titleSize = isTinyScreen ? 20.0 : 24.0;
    final statValueSize = isTinyScreen ? 18.0 : 22.0;
    final statLabelSize = isTinyScreen ? 10.0 : 12.0;

    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final user = state is AuthSuccess ? state.user : null;
          final imageUrl = _profileImageUrl ?? _resolveImageUrl(user?.profilePictureUrl);

          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: SafeArea(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(horizontalPadding, 20, horizontalPadding, 24),
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
                              l10n.profile,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: titleSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          SizedBox(height: isTinyScreen ? 16 : 24),
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
                                          user?.initials ?? 'B',
                                          style: const TextStyle(
                                            color: AppTheme.primaryGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 34,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: InkWell(
                                  onTap: state is AuthSuccess
                                      ? () => _pickAndUploadProfileImage(token: state.token)
                                      : null,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryGreen,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: _isUploadingImage
                                        ? const SizedBox(
                                            height: 14,
                                            width: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.camera_alt,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            user?.fullName ?? l10n.buyer,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: nameSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _localizedRole(user?.role, l10n),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              user?.email ?? '-',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.95),
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ProfileStat(value: '0', label: l10n.orders),
                              _ProfileStat(value: '0', label: l10n.favorites),
                              _ProfileStat(value: '0', label: l10n.chat),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(horizontalPadding),
                      child: Column(
                        children: [
                          _infoTile(
                            icon: Icons.badge,
                            title: l10n.profileRole,
                            value: _localizedRole(user?.role, l10n),
                          ),
                          _infoTile(
                            icon: Icons.email,
                            title: l10n.email,
                            value: user?.email ?? l10n.notProvided,
                          ),
                          _infoTile(
                            icon: Icons.phone,
                            title: l10n.phoneNumber,
                            value: user?.phoneNumber ?? l10n.notProvided,
                          ),
                          _infoTile(
                            icon: Icons.calendar_month,
                            title: l10n.memberSince,
                            value: user?.formattedJoinDate ?? l10n.notProvided,
                          ),
                          const SizedBox(height: 16),
                          _menuTile(Icons.edit, l10n.editProfile),
                          _menuTile(
                            Icons.language,
                            l10n.changeLanguage,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const LanguageSettingsScreen(),
                                ),
                              );
                            },
                          ),
                          _menuTile(Icons.help_outline, l10n.helpSupport),
                          _menuTile(Icons.privacy_tip_outlined, l10n.privacyPolicy),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => _confirmLogout(context, l10n),
                              icon: const Icon(Icons.logout),
                              label: Text(l10n.logout),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE53935),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _localizedRole(String? role, AppLocalizations l10n) {
    switch (role) {
      case 'farmer':
        return l10n.farmer;
      case 'doctor':
        return l10n.doctor;
      case 'buyer':
        return l10n.buyer;
      default:
        return l10n.buyer;
    }
  }

  Future<void> _confirmLogout(BuildContext context, AppLocalizations l10n) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      context.read<AuthBloc>().add(const LogoutRequested());
    }
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2196F3)),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(value),
      ),
    );
  }

  Widget _menuTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryGreen),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;

  const _ProfileStat({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;

    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: isTinyScreen ? 18.0 : 22.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: isTinyScreen ? 10.0 : 12.0,
          ),
        ),
      ],
    );
  }
}


import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../settings/language_settings_screen.dart';

class ConsultantProfileScreen extends StatefulWidget {
  const ConsultantProfileScreen({super.key});

  @override
  State<ConsultantProfileScreen> createState() => _ConsultantProfileScreenState();
}

class _ConsultantProfileScreenState extends State<ConsultantProfileScreen> {
  static const Color _headerStartColor = Color(0xFFFF9800);
  static const Color _headerEndColor = Color(0xFFFFB74D);

  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImage = false;
  String? _profileImageUrl;

  @override
  void initState() {
    super.initState();
    _loadProfileFromServer();
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

  Future<void> _loadProfileFromServer() async {
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
        final refreshedUser = UserModel.fromJson(body);
        final imageUrl = _resolveImageUrl(refreshedUser.profilePictureUrl);

        if (!mounted) return;
        setState(() {
          _profileImageUrl = imageUrl;
        });

        context.read<AuthBloc>().add(
              AuthUserUpdated(
                user: refreshedUser.copyWith(
                  profilePictureUrl: imageUrl ?? refreshedUser.profilePictureUrl,
                ),
              ),
            );
      }
    } catch (_) {
      // Keep fallback avatar if profile fetch fails.
    }
  }

  Future<void> _pickAndUploadProfileImage({required String token}) async {
    final l10n = AppLocalizations.of(context)!;

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
        final userData = body['user'] as Map<String, dynamic>?;
        if (userData == null) {
          throw Exception('Profile update response did not include user data.');
        }

        final refreshedUser = UserModel.fromJson(userData);
        final imageUrl = _resolveImageUrl(refreshedUser.profilePictureUrl);

        if (!mounted) return;
        setState(() {
          _profileImageUrl = imageUrl;
        });

        context.read<AuthBloc>().add(
              AuthUserUpdated(
                user: refreshedUser.copyWith(
                  profilePictureUrl: imageUrl ?? refreshedUser.profilePictureUrl,
                ),
              ),
            );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profilePictureUpdated),
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
          content: Text('${l10n.failedToUploadImage}: $e'),
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

  String _buildStatusValue(UserModel? user, AppLocalizations l10n) {
    final status = (user?.doctorStatusDisplay ?? user?.doctorStatus ?? '').trim();
    if (status.isNotEmpty) return status;

    final fallbackStatus = (user?.statusMessage ?? '').trim();
    if (fallbackStatus.isNotEmpty) return fallbackStatus;

    return l10n.info;
  }

  List<Widget> _buildConsultantDetailRows(UserModel? user, AppLocalizations l10n) {
    final rows = <Widget>[
      _InfoRow(
        label: l10n.profileRole,
        value: user?.roleDisplay ?? user?.role ?? '-',
      ),
      const SizedBox(height: 10),
      _InfoRow(
        label: l10n.phoneNumber,
        value: user?.phoneNumber ?? l10n.notProvided,
      ),
      const SizedBox(height: 10),
      _InfoRow(
        label: l10n.status,
        value: _buildStatusValue(user, l10n),
      ),
    ];

    if ((user?.specialization ?? '').trim().isNotEmpty) {
      rows.add(const SizedBox(height: 10));
      rows.add(
        _InfoRow(
          label: l10n.specialization,
          value: user!.specialization!.trim(),
        ),
      );
    }

    if (user?.experienceYears != null) {
      rows.add(const SizedBox(height: 10));
      rows.add(
        _InfoRow(
          label: l10n.experience,
          value: '${user!.experienceYears} ${l10n.years}',
        ),
      );
    }

    if ((user?.licenseNumber ?? '').trim().isNotEmpty) {
      rows.add(const SizedBox(height: 10));
      rows.add(
        _InfoRow(
          label: l10n.licenseNumberLabel,
          value: user!.licenseNumber!.trim(),
        ),
      );
    }

    if (user?.dateJoined != null && user!.dateJoined!.isNotEmpty) {
      rows.add(const SizedBox(height: 10));
      rows.add(
        _InfoRow(
          label: l10n.memberSince,
          value: user.formattedJoinDate,
        ),
      );
    }

    return rows;
  }

  void _showLogoutDialog(AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.logout),
        content: Text(l10n.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthBloc>().add(LogoutRequested());
            },
            child: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
    final statValueSize = isTinyScreen ? 13.0 : 15.0;
    final statLabelSize = isTinyScreen ? 10.0 : 11.0;
    final menuHorizontalPadding = isTinyScreen ? 16.0 : 20.0;
    final menuVerticalPadding = isTinyScreen ? 14.0 : 16.0;
    final menuIconSize = isTinyScreen ? 22.0 : 24.0;
    final menuTitleSize = isTinyScreen ? 15.0 : 16.0;
    final actionButtonHeight = isTinyScreen ? 52.0 : 56.0;

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
          final l10n = AppLocalizations.of(context)!;
          final user = authState is AuthSuccess ? authState.user : null;
          final imageUrl = _profileImageUrl ?? _resolveImageUrl(user?.profilePictureUrl);
          final roleText = (user?.roleDisplay ?? user?.role ?? l10n.doctor).toUpperCase();

          return Scaffold(
            backgroundColor: AppTheme.backgroundColor,
            body: SafeArea(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(horizontalPadding),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_headerStartColor, _headerEndColor],
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
                              fontSize: headerTitleSize,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(height: profileTopGap),
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
                                        user?.initials ?? 'C',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: _headerStartColor,
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
                                            valueColor: AlwaysStoppedAnimation<Color>(_headerStartColor),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.camera_alt,
                                          size: 16,
                                          color: _headerStartColor,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: isTinyScreen ? 12 : 16),
                        Text(
                          user?.fullName ?? l10n.doctor,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: profileNameSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          roleText,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: roleSize,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
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
                            user?.email ?? l10n.notProvided,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: emailSize,
                            ),
                          ),
                        ),
                        SizedBox(height: isTinyScreen ? 18 : 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _ProfileStat(
                              value: user?.experienceYears?.toString() ?? '-',
                              label: l10n.experience,
                              valueFontSize: statValueSize,
                              labelFontSize: statLabelSize,
                            ),
                            Container(
                              height: statsDividerHeight,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _ProfileStat(
                              value: _buildStatusValue(user, l10n),
                              label: l10n.status,
                              valueFontSize: statValueSize,
                              labelFontSize: statLabelSize,
                            ),
                            Container(
                              height: statsDividerHeight,
                              width: 1,
                              color: Colors.white.withOpacity(0.3),
                            ),
                            _ProfileStat(
                              value: user?.formattedJoinDate ?? '-',
                              label: l10n.memberSince,
                              valueFontSize: statValueSize,
                              labelFontSize: statLabelSize,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          SizedBox(height: isTinyScreen ? 16 : 20),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: menuHorizontalPadding),
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: _buildConsultantDetailRows(user, l10n),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ProfileMenuItem(
                            icon: Icons.person_outline,
                            title: l10n.editProfile,
                            iconColor: _headerStartColor,
                            iconSize: menuIconSize,
                            titleFontSize: menuTitleSize,
                            horizontalPadding: menuHorizontalPadding,
                            verticalPadding: menuVerticalPadding,
                            onTap: () {},
                          ),
                          _ProfileMenuItem(
                            icon: Icons.language,
                            title: l10n.language,
                            iconColor: _headerStartColor,
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
                            title: l10n.settings,
                            iconColor: _headerStartColor,
                            iconSize: menuIconSize,
                            titleFontSize: menuTitleSize,
                            horizontalPadding: menuHorizontalPadding,
                            verticalPadding: menuVerticalPadding,
                            onTap: () {},
                          ),
                          _ProfileMenuItem(
                            icon: Icons.help_outline,
                            title: l10n.helpSupport,
                            iconColor: _headerStartColor,
                            iconSize: menuIconSize,
                            titleFontSize: menuTitleSize,
                            horizontalPadding: menuHorizontalPadding,
                            verticalPadding: menuVerticalPadding,
                            onTap: () {},
                          ),
                          _ProfileMenuItem(
                            icon: Icons.info_outline,
                            title: l10n.about,
                            iconColor: _headerStartColor,
                            iconSize: menuIconSize,
                            titleFontSize: menuTitleSize,
                            horizontalPadding: menuHorizontalPadding,
                            verticalPadding: menuVerticalPadding,
                            onTap: () {},
                          ),
                          Padding(
                            padding: EdgeInsets.all(menuHorizontalPadding),
                            child: SizedBox(
                              width: double.infinity,
                              height: actionButtonHeight,
                              child: ElevatedButton.icon(
                                onPressed: () => _showLogoutDialog(l10n),
                                icon: const Icon(Icons.logout),
                                label: Text(
                                  l10n.logout,
                                  style: TextStyle(
                                    fontSize: isTinyScreen ? 15 : 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.errorRed,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w600),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final double valueFontSize;
  final double labelFontSize;

  const _ProfileStat({
    required this.value,
    required this.label,
    this.valueFontSize = 15,
    this.labelFontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.85),
              fontSize: labelFontSize,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Color iconColor;
  final double iconSize;
  final double titleFontSize;
  final double horizontalPadding;
  final double verticalPadding;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    required this.iconColor,
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
        padding: EdgeInsets.symmetric(
          horizontal: horizontalPadding,
          vertical: verticalPadding,
        ),
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

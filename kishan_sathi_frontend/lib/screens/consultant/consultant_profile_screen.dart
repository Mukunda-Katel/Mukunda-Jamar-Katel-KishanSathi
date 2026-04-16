import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class ConsultantProfileScreen extends StatefulWidget {
  const ConsultantProfileScreen({super.key});

  @override
  State<ConsultantProfileScreen> createState() => _ConsultantProfileScreenState();
}

class _ConsultantProfileScreenState extends State<ConsultantProfileScreen> {
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
                  user: authState.user.copyWith(profilePictureUrl: imageUrl),
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

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final user = authState is AuthSuccess ? authState.user : null;
        final imageUrl = _profileImageUrl ?? _resolveImageUrl(user?.profilePictureUrl);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Consultant Profile'),
            backgroundColor: const Color(0xFFFF9800),
            foregroundColor: Colors.white,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
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
                                style: const TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 36,
                                ),
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: InkWell(
                        onTap: authState is AuthSuccess
                            ? () => _pickAndUploadProfileImage(token: authState.token)
                            : null,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF9800),
                            shape: BoxShape.circle,
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
                              : const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Consultant',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.email ?? '-',
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 20),
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Role', value: user?.roleDisplay ?? user?.role ?? '-'),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Phone', value: user?.phoneNumber ?? 'Not provided'),
                        const SizedBox(height: 10),
                        _InfoRow(label: 'Status', value: user?.statusMessage ?? 'Active'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
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

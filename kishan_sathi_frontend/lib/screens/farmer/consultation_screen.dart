import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../core/theme/app_theme.dart';
import '../../services/consultation_service.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../farmer/chat_screen.dart';

class FarmerConsultationScreen extends StatefulWidget {
  const FarmerConsultationScreen({super.key});

  @override
  State<FarmerConsultationScreen> createState() =>
      _FarmerConsultationScreenState();
}

class _FarmerConsultationScreenState extends State<FarmerConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late ConsultationService _consultationService;
  String _token = '';
  bool _isLoading = false;
  List<Doctor> _doctors = [];
  List<ConsultationRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _consultationService = ConsultationService(client: http.Client());
    
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthSuccess) {
      _token = authState.token;
      _loadData();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final doctors = await _consultationService.getApprovedDoctors(_token);
      final requests = await _consultationService.getMyRequests(_token);
      setState(() {
        _doctors = doctors;
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _requestConsultation(Doctor doctor) async {
    final messageController = TextEditingController();
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Consultation with ${doctor.fullName}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${doctor.specialization ?? "Doctor"}'),
              const SizedBox(height: 8),
              Text('${doctor.experienceYears ?? 0} years of experience'),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                decoration: const InputDecoration(
                  labelText: 'Message (Optional)',
                  hintText: 'Describe your concern...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
            ),
            child: const Text('Request'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _consultationService.requestConsultation(
          _token,
          doctor.id,
          messageController.text.trim(),
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Consultation request sent successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          _loadData();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTinyScreen = screenWidth < 360;
    final isSmallScreen = screenWidth < 600;

    final titleFontSize = isTinyScreen ? 16.0 : 18.0;
    final tabFontSize = isTinyScreen ? 12.0 : 14.0;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Veterinary Consultation',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: titleFontSize,
          ),
        ),
        backgroundColor: AppTheme.primaryGreen,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: isSmallScreen,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(fontSize: tabFontSize, fontWeight: FontWeight.w600),
          unselectedLabelStyle: TextStyle(fontSize: tabFontSize),
          tabs: const [
            Tab(text: 'Available Doctors'),
            Tab(text: 'My Requests'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildDoctorsList(isTinyScreen: isTinyScreen),
                _buildRequestsList(isTinyScreen: isTinyScreen),
              ],
            ),
    );
  }

  Widget _buildDoctorsList({required bool isTinyScreen}) {
    final listPadding = isTinyScreen ? 12.0 : 16.0;
    final cardPadding = isTinyScreen ? 12.0 : 16.0;
    final avatarRadius = isTinyScreen ? 24.0 : 30.0;
    final doctorNameSize = isTinyScreen ? 16.0 : 18.0;
    final subtitleSize = isTinyScreen ? 13.0 : 14.0;
    final detailTextSize = isTinyScreen ? 12.0 : 14.0;
    final buttonFontSize = isTinyScreen ? 13.0 : 14.0;
    final infoIconSize = isTinyScreen ? 14.0 : 16.0;

    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.medical_services, size: isTinyScreen ? 54 : 64, color: Colors.grey[400]),
            SizedBox(height: isTinyScreen ? 12 : 16),
            Text(
              'No doctors available',
              style: TextStyle(fontSize: isTinyScreen ? 14 : 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(listPadding),
        itemCount: _doctors.length,
        itemBuilder: (context, index) {
          final doctor = _doctors[index];
          final hasRequest = _requests.any(
            (r) => r.doctor?.id == doctor.id && r.status == 'pending',
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTinyScreen ? 10 : 12),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: avatarRadius,
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Text(
                          doctor.fullName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: isTinyScreen ? 20 : 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      SizedBox(width: isTinyScreen ? 10 : 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.fullName,
                              style: TextStyle(
                                fontSize: doctorNameSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isTinyScreen ? 2 : 4),
                            Text(
                              doctor.specialization ?? 'General Veterinarian',
                              style: TextStyle(
                                fontSize: subtitleSize,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: isTinyScreen ? 10 : 16,
                    runSpacing: 6,
                    children: [
                      Icon(Icons.work_outline,
                          size: infoIconSize, color: Colors.grey[600]),
                      Text(
                        '${doctor.experienceYears ?? 0} years experience',
                        style: TextStyle(color: Colors.grey[600], fontSize: detailTextSize),
                      ),
                      if (doctor.phoneNumber != null) ...[
                        Icon(Icons.phone, size: infoIconSize, color: Colors.grey[600]),
                        Text(
                          doctor.phoneNumber!,
                          style: TextStyle(color: Colors.grey[600], fontSize: detailTextSize),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: hasRequest ? null : () => _requestConsultation(doctor),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        padding: EdgeInsets.symmetric(vertical: isTinyScreen ? 10 : 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(
                        hasRequest ? Icons.schedule : Icons.chat_bubble_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        hasRequest ? 'Request Pending' : 'Request Consultation',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: buttonFontSize,
                        ),
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

  Widget _buildRequestsList({required bool isTinyScreen}) {
    final listPadding = isTinyScreen ? 12.0 : 16.0;
    final cardPadding = isTinyScreen ? 12.0 : 16.0;

    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: isTinyScreen ? 54 : 64, color: Colors.grey[400]),
            SizedBox(height: isTinyScreen ? 12 : 16),
            Text(
              'No consultation requests',
              style: TextStyle(fontSize: isTinyScreen ? 14 : 16, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(listPadding),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          final doctor = request.doctor;

          if (doctor == null) return const SizedBox.shrink();

          Color statusColor;
          IconData statusIcon;
          
          switch (request.status) {
            case 'approved':
              statusColor = Colors.green;
              statusIcon = Icons.check_circle;
              break;
            case 'rejected':
              statusColor = Colors.red;
              statusIcon = Icons.cancel;
              break;
            case 'completed':
              statusColor = Colors.blue;
              statusIcon = Icons.done_all;
              break;
            default:
              statusColor = Colors.orange;
              statusIcon = Icons.schedule;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isTinyScreen ? 10 : 12),
            ),
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: isTinyScreen ? 20 : 24,
                        backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Text(
                          doctor.fullName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: isTinyScreen ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGreen,
                          ),
                        ),
                      ),
                      SizedBox(width: isTinyScreen ? 10 : 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              doctor.fullName,
                              style: TextStyle(
                                fontSize: isTinyScreen ? 15 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: isTinyScreen ? 2 : 4),
                            Row(
                              children: [
                                Icon(statusIcon, size: isTinyScreen ? 14 : 16, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  request.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: isTinyScreen ? 11 : 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (request.message != null && request.message!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        request.message!,
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: isTinyScreen ? 13 : 14,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Requested: ${_formatDate(request.createdAt)}',
                    style: TextStyle(
                      fontSize: isTinyScreen ? 11 : 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (request.status == 'approved' && request.chatRoomId != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ChatScreen(
                                userName: doctor.fullName,
                                userRole: 'doctor',
                                chatRoomId: request.chatRoomId!,
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          padding: EdgeInsets.symmetric(vertical: isTinyScreen ? 10 : 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.chat, color: Colors.white),
                        label: const Text(
                          'Start Chat',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

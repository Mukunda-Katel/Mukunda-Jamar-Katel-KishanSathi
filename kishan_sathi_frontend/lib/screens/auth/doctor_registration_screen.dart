import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_event.dart';
import '../../bloc/auth/auth_state.dart';
import '../../theme/app_theme.dart';

class DoctorRegistrationScreen extends StatefulWidget {
  const DoctorRegistrationScreen({super.key});

  @override
  State<DoctorRegistrationScreen> createState() => _DoctorRegistrationScreenState();
}

class _DoctorRegistrationScreenState extends State<DoctorRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _licenseController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  
  // NEW: File picker variables
  File? _certificateFile;
  String? _certificateFileName;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _specializationController.dispose();
    _experienceController.dispose();
    _licenseController.dispose();
    super.dispose();
  }

  // NEW: Pick certificate file
  Future<void> _pickCertificate() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();
        
        // Check file size (max 10MB)
        if (fileSize > 10485760) {
          if (mounted) {
            _showSnackBar(
              context,
              'File size must not exceed 10MB',
              AppTheme.errorRed,
              Icons.error,
            );
          }
          return;
        }

        setState(() {
          _certificateFile = file;
          _certificateFileName = result.files.single.name;
        });

        if (mounted) {
          _showSnackBar(
            context,
            'Certificate uploaded successfully',
            AppTheme.primaryGreen,
            Icons.check_circle,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          context,
          'Error picking file: $e',
          AppTheme.errorRed,
          Icons.error,
        );
      }
    }
  }

  void _handleRegister(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      if (!_agreeToTerms) {
        _showSnackBar(
          context,
          'Please agree to terms and conditions',
          AppTheme.errorRed,
          Icons.warning,
        );
        return;
      }

      // NEW: Check if certificate is uploaded
      if (_certificateFile == null) {
        _showSnackBar(
          context,
          'Please upload your certificate',
          AppTheme.errorRed,
          Icons.warning,
        );
        return;
      }

      // Dispatch doctor register event to BLoC
      context.read<AuthBloc>().add(
            DoctorRegisterRequested(
              fullName: _nameController.text.trim(),
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              password: _passwordController.text,
              specialization: _specializationController.text.trim(),
              experienceYears: int.parse(_experienceController.text.trim()),
              licenseNumber: _licenseController.text.trim(),
              certificateFile: _certificateFile!, 
            ),
          );
    }
  }

  void _showSnackBar(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Registration'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is DoctorRegistrationPending) {
            // Show success dialog for pending approval
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                icon: const Icon(
                  Icons.pending_actions,
                  color: Colors.orange,
                  size: 64,
                ),
                title: const Text('Registration Submitted'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'You will receive an email notification once your account is verified.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop(); 
                      Navigator.of(context).pop(); 
                    },
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          } else if (state is AuthFailure) {
            _showSnackBar(context, state.error, AppTheme.errorRed, Icons.error);
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const Icon(
                    Icons.medical_services,
                    size: 80,
                    color: AppTheme.primaryGreen,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Consultant/Doctor Registration',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.darkGreen,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join as a consultant',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Personal Information
                  _buildSectionHeader('Personal Information'),
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    hint: 'Dr. John Doe',
                    icon: Icons.person_outline,
                    enabled: !isLoading,
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : v.length < 3
                            ? 'Min 3 characters'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _emailController,
                    label: 'Email Address',
                    hint: 'doctor@example.com',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)
                            ? 'Invalid email'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number',
                    hint: '98XXXXXXXX',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : v.length < 10
                            ? 'Invalid phone number'
                            : null,
                  ),
                  const SizedBox(height: 24),

                  // Professional Information
                  _buildSectionHeader('Professional Information'),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _specializationController,
                    label: 'Specialization',
                    hint: 'e.g., Livestock, Poultry, General Practice',
                    icon: Icons.medical_information_outlined,
                    enabled: !isLoading,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _experienceController,
                    label: 'Years of Experience',
                    hint: 'e.g., 5',
                    icon: Icons.work_outline,
                    keyboardType: TextInputType.number,
                    enabled: !isLoading,
                    validator: (v) {
                      if (v!.isEmpty) return 'Required';
                      final years = int.tryParse(v);
                      if (years == null || years < 0) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _licenseController,
                    label: 'License Number',
                    hint: 'VET-XXXXXX',
                    icon: Icons.badge_outlined,
                    enabled: !isLoading,
                    validator: (v) => v!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 24),

                  // NEW: Certificate Upload Section
                  _buildSectionHeader('License Certificate'),
                  const SizedBox(height: 16),
                  
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _certificateFile != null
                            ? AppTheme.primaryGreen
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: isLoading ? null : _pickCertificate,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Icon(
                                _certificateFile != null
                                    ? Icons.check_circle
                                    : Icons.upload_file,
                                size: 48,
                                color: _certificateFile != null
                                    ? AppTheme.primaryGreen
                                    : Colors.grey,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _certificateFile != null
                                    ? _certificateFileName!
                                    : 'Upload Certificate',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _certificateFile != null
                                      ? AppTheme.primaryGreen
                                      : Colors.grey.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'PDF, JPG, PNG (Max 10MB)',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              if (_certificateFile != null) ...[
                                const SizedBox(height: 12),
                                TextButton.icon(
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          setState(() {
                                            _certificateFile = null;
                                            _certificateFileName = null;
                                          });
                                        },
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Remove'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppTheme.errorRed,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security
                  _buildSectionHeader('Security'),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Min 6 characters',
                    icon: Icons.lock_outline,
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : v.length < 6
                            ? 'Min 6 characters'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hint: 'Re-enter password',
                    icon: Icons.lock_outline,
                    obscureText: _obscureConfirmPassword,
                    enabled: !isLoading,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () => setState(
                          () => _obscureConfirmPassword = !_obscureConfirmPassword),
                    ),
                    validator: (v) => v!.isEmpty
                        ? 'Required'
                        : v != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
                  ),
                  const SizedBox(height: 24),

                  // Terms and Conditions
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 20,
                        width: 20,
                        child: Checkbox(
                          value: _agreeToTerms,
                          onChanged: isLoading
                              ? null
                              : (v) => setState(() => _agreeToTerms = v ?? false),
                          activeColor: AppTheme.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          children: [
                            Text(
                              'I agree to ',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                            const Text(
                              'Terms & Conditions',
                              style: TextStyle(
                                color: AppTheme.primaryGreen,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              ' and confirm that all information provided is accurate and verifiable.',
                              style: TextStyle(color: Colors.grey[700], fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : () => _handleRegister(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Submit Application',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward, size: 20),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your application will be reviewed by our admin team. You will be notified via email once approved.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.darkGreen,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    bool enabled = true,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppTheme.primaryGreen, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppTheme.backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository_impl.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepositoryImpl authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    on<LoginRequested>(_onLoginRequested);
    on<RegisterRequested>(_onRegisterRequested);
    on<DoctorRegisterRequested>(_onDoctorRegisterRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<CheckAuthStatus>(_onCheckAuthStatus);
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.login(
        email: event.email,
        password: event.password,
        role: event.role,
      );

      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      final token = response['token'] as String;
      final message = response['message'] as String? ?? 'Login successful';

      emit(AuthSuccess(
        token: token,
        user: user,
        message: message,
      ));
    } catch (e) {
      emit(AuthFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRegisterRequested(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.register(
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        role: event.role,
      );

      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      final token = response['token'] as String? ?? '';
      final message = response['message'] as String? ?? 'Registration successful';

      if (token.isNotEmpty) {
        emit(AuthSuccess(
          token: token,
          user: user,
          message: message,
        ));
      } else {
        emit(AuthFailure(error: message));
      }
    } catch (e) {
      emit(AuthFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  /// UPDATED: Handle doctor registration with file
  Future<void> _onDoctorRegisterRequested(
    DoctorRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final response = await authRepository.registerDoctor(
        fullName: event.fullName,
        email: event.email,
        phoneNumber: event.phoneNumber,
        password: event.password,
        specialization: event.specialization,
        experienceYears: event.experienceYears,
        licenseNumber: event.licenseNumber,
        certificateFile: event.certificateFile,
      );

      final user = UserModel.fromJson(response['user'] as Map<String, dynamic>);
      final message = response['message'] as String? ??
          'Registration submitted successfully! Pending admin approval.';

      emit(DoctorRegistrationPending(
        user: user,
        message: message,
      ));
    } catch (e) {
      emit(AuthFailure(error: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      await authRepository.logout();
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure(error: e.toString()));
    }
  }

  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    final isLoggedIn = await authRepository.isLoggedIn();
    if (isLoggedIn) {
      emit(const AuthUnauthenticated());
    } else {
      emit(const AuthUnauthenticated());
    }
  }
}


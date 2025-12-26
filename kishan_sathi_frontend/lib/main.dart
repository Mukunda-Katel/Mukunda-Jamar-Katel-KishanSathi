import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'screens/farmer/farmer_dashboard.dart';
import 'screens/buyer/buyer_dashboard.dart';
import 'screens/consultant/consultant_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize services
  final apiService = ApiService();
  final authRepository = AuthRepositoryImpl(
    apiService: apiService,
    prefs: prefs,
  );
  
  // Create AuthBloc
  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(const CheckAuthStatus());
  
  runApp(MyApp(authBloc: authBloc));
}

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;
  
  const MyApp({super.key, required this.authBloc});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: MaterialApp(
        title: 'Kishan Sathi',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: AppTheme.primaryGreen,
          scaffoldBackgroundColor: AppTheme.backgroundColor,
          fontFamily: 'Poppins',
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppTheme.primaryGreen,
            brightness: Brightness.light,
          ),
        ),
        home: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthSuccess && state.token.isNotEmpty) {
              // Redirect to appropriate dashboard based on role
              switch (state.user.role) {
                case 'farmer':
                  return const FarmerDashboard();
                case 'buyer':
                  return const BuyerDashboard();
                case 'doctor':
                  return const ConsultantDashboard();
                default:
                  return const FarmerDashboard();
              }
            }
            // Show auth screen for unauthenticated users
            return const AuthScreen();
          },
        ),
        routes: {
          '/auth': (context) => const AuthScreen(),
          '/farmer-dashboard': (context) => const FarmerDashboard(),
          '/buyer-dashboard': (context) => const BuyerDashboard(),
          '/consultant-dashboard': (context) => const ConsultantDashboard(),
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/auth/auth_screen.dart';
import 'theme/app_theme.dart';
import 'bloc/auth/auth_bloc.dart';
import 'bloc/auth/auth_event.dart';
import 'repositories/auth_repository.dart';
import 'services/api_service.dart';
import 'screens/farmer/farmer_dashboard.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  
  // Initialize services
  final apiService = ApiService();
  final authRepository = AuthRepository(
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
        initialRoute: '/',
        routes: {
          '/': (context) => const FarmerDashboard(),
        },
      ),
    );
  }
}

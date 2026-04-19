import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'firebase_options.dart';
import 'features/auth/presentation/screens/auth_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/providers/locale_provider.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'screens/farmer/farmer_dashboard.dart';
import 'screens/buyer/buyer_dashboard.dart';
import 'screens/consultant/consultant_dashboard.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  
  // Initialize services
  final apiService = ApiService();
  final authRepository = AuthRepositoryImpl(
    apiService: apiService,
    prefs: prefs,
    secureStorage: secureStorage,
  );
  
  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  
  // Create AuthBloc
  final authBloc = AuthBloc(authRepository: authRepository)
    ..add(const CheckAuthStatus());
  
  // Create LocaleProvider and wait for it to load
  final localeProvider = LocaleProvider();
  await localeProvider.initialize();
  
  runApp(MyApp(
    authBloc: authBloc,
    localeProvider: localeProvider,
    notificationService: notificationService,
  ));
}

class MyApp extends StatelessWidget {
  final AuthBloc authBloc;
  final LocaleProvider localeProvider;
  final NotificationService notificationService;

  const MyApp({
    super.key,
    required this.authBloc,
    required this.localeProvider,
    required this.notificationService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: authBloc),
        ChangeNotifierProvider<LocaleProvider>.value(value: localeProvider),
      ],
      child: Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          return MaterialApp(
            title: 'Kishan Sathi',
            debugShowCheckedModeBanner: false,
            locale: localeProvider.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en', ''),
              Locale('ne', ''),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              // Check if the current device locale is supported
              if (locale != null) {
                for (var supportedLocale in supportedLocales) {
                  if (supportedLocale.languageCode == locale.languageCode) {
                    return supportedLocale;
                  }
                }
              }
              // If the device locale is not supported, use the provider's locale
              return localeProvider.locale;
            },
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
            home: BlocListener<AuthBloc, AuthState>(
              listener: (context, state) {
                // Update FCM token when user logs in successfully
                if (state is AuthSuccess && state.token.isNotEmpty) {
                  notificationService.updateFCMToken(state.token);
                }
              },
              child: BlocBuilder<AuthBloc, AuthState>(
                builder: (context, state) {
                  if (state is AuthSuccess && state.token.isNotEmpty) {
                    // Redirect to appropriate dashboard based on role
                    switch (state.user.role) {
                      case 'farmer':
                        return const FarmerDashboard();
                      case 'buyer':
                        return const BuyerDashboard();
                      case 'doctor':
                      case 'consultant':
                        return const ConsultantDashboard();
                      default:
                        return const FarmerDashboard();
                    }
                  }
                  // Show auth screen for unauthenticated users
                  return const AuthScreen();
                },
              ),
            ),
            routes: {
              '/auth': (context) => const AuthScreen(),
              '/farmer-dashboard': (context) => const FarmerDashboard(),
              '/buyer-dashboard': (context) => const BuyerDashboard(),
              '/consultant-dashboard': (context) => const ConsultantDashboard(),
            },
          );
        },
      ),
    );
  }
}

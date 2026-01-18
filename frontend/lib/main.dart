import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'src/app.dart';
import 'src/config/app_config.dart';
import 'src/features/auth/data/auth_repository.dart';
import 'src/features/auth/data/token_storage.dart';
import 'src/features/dashboard/data/dashboard_repository.dart';
import 'src/features/auth/application/locale_bloc.dart';
import 'src/features/auth/application/auth_bloc.dart';
import 'src/features/auth/application/login_bloc.dart';
import 'src/features/cart/application/cart_bloc.dart';
import 'src/features/cart/application/cart_event.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Initialize Core Services
  final appConfig = AppConfig.dev();

  // Initialize Firebase using platform-specific configuration
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
    // Continue app execution even if Firebase fails
  }
  
  // 2. Setup Dio
  final dio = Dio(BaseOptions(
    baseUrl: appConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    contentType: Headers.jsonContentType,
  ));
  
  dio.interceptors.add(LogInterceptor(
    requestBody: true,
    responseBody: true,
  ));

  // 3. Setup Repositories
  final tokenStorage = TokenStorage(const FlutterSecureStorage());
  
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await tokenStorage.getToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ));

  final authRepository = AuthRepository(dio, googleClientId: appConfig.googleClientId);
  final dashboardRepository = DashboardRepository(dio);
  
  // 4. Create Blocs
  final localeBloc = LocaleBloc()..add(LoadLocale());
  final authBloc = AuthBloc(tokenStorage)..add(AuthCheckRequested());
  final loginBloc = LoginBloc(authRepository);
  final cartBloc = CartBloc(dashboardRepository)..add(CartStarted());

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AppConfig>.value(value: appConfig),
        RepositoryProvider<Dio>.value(value: dio),
        RepositoryProvider<TokenStorage>.value(value: tokenStorage),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<DashboardRepository>.value(value: dashboardRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<LocaleBloc>.value(value: localeBloc),
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<LoginBloc>.value(value: loginBloc),
          BlocProvider<CartBloc>.value(value: cartBloc),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

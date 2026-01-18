import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'dart:io' show Platform;

enum Environment { dev, staging, prod }

class AppConfig {
  final String appName;
  final String apiBaseUrl;
  final Environment environment;
  final String? sentryDsn;
  
  // Dynamic Configuration for White-labeling
  final String googleClientId;
  final Map<String, String> firebaseOptions;

  // Feature Flags
  final bool enableFoodVariants;
  final bool enableCoupons;

  const AppConfig({
    required this.appName,
    required this.apiBaseUrl,
    required this.googleClientId,
    required this.firebaseOptions,
    this.environment = Environment.dev,
    this.sentryDsn,
    this.enableFoodVariants = true,
    this.enableCoupons = true,
  });

  // Default Dev Config
  factory AppConfig.dev() {
    String baseUrl = const String.fromEnvironment('API_BASE_URL');
    
    if (baseUrl.trim().isEmpty) {
      if (!kIsWeb && Platform.isAndroid) {
        baseUrl = 'http://10.0.2.2:8000'; // Standard Android Emulator Bridge
      } else {
        baseUrl = 'http://127.0.0.1:8000'; // Default for iOS/Web/Desktop
      }
    }

    debugPrint('🚀 APP CONFIG: Base URL set to $baseUrl');

    return AppConfig(
      appName: 'AB Delivery (Dev)',
      apiBaseUrl: baseUrl,
      environment: Environment.dev,
      googleClientId: const String.fromEnvironment('GOOGLE_CLIENT_ID'),
      firebaseOptions: {
        'apiKey': const String.fromEnvironment('FIREBASE_API_KEY'),
        'authDomain': const String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        'projectId': const String.fromEnvironment('FIREBASE_PROJECT_ID'),
        'storageBucket': const String.fromEnvironment('FIREBASE_STORAGE_BUCKET'),
        'messagingSenderId': const String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID'),
        'appId': const String.fromEnvironment('FIREBASE_APP_ID'),
        'measurementId': const String.fromEnvironment('FIREBASE_MEASUREMENT_ID'),
      },
    );
  }
}

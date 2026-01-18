import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/src/l10n/app_localizations.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/otp_screen.dart';
import '../features/auth/presentation/email_login_screen.dart';
import '../features/auth/presentation/name_input_screen.dart';
import '../features/auth/presentation/name_input_screen.dart';
import '../features/auth/application/auth_bloc.dart';
import '../features/dashboard/presentation/home_screen.dart';
import '../features/dashboard/presentation/offer_screen.dart';
import '../features/dashboard/presentation/product_details_screen.dart';
import '../features/dashboard/presentation/favorites_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dashboard/presentation/orders_screen.dart';
import '../features/dashboard/presentation/addresses_screen.dart';
import '../features/dashboard/presentation/help_screen.dart';
import '../features/auth/presentation/profile_screen.dart';
import '../features/cart/presentation/cart_screen.dart';
import '../features/cart/presentation/checkout_screen.dart';

// Helper class to convert Bloc Stream to Listenable for GoRouter
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}


// Global variable for router, we will manage the refreshListenable externally or via a workaround
// Since we are using Bloc, we can create the router factory
GoRouter createRouter(AuthBloc authBloc) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = authBloc.state;
      final isLoggingIn = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/otp' ||
                          state.matchedLocation == '/email-login' ||
                          state.matchedLocation == '/name-input';
      
      if (authState is AuthInitial || authState is AuthLoading) {
        return null;
      }

      if (authState is AuthUnauthenticated) {
        return isLoggingIn ? null : '/login';
      }

      if (authState is AuthAuthenticated) {
        return isLoggingIn ? '/' : null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final phone = state.extra as String;
          return OtpScreen(phoneNumber: phone);
        },
      ),
      GoRoute(
        path: '/email-login',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/name-input',
        builder: (context, state) {
          final token = state.extra as String;
          return NameInputScreen(token: token);
        },
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/offer',
        builder: (context, state) {
          final banner = state.extra as Map<String, dynamic>;
          return OfferScreen(banner: banner);
        },
      ),
      GoRoute(
        path: '/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/product-details',
        builder: (context, state) {
           final food = state.extra as Map<String, dynamic>;
           return ProductDetailsScreen(food: food);
        },
      ),
      GoRoute(
        path: '/favorites',
        builder: (context, state) => const FavoritesScreen(),
      ),
      GoRoute(
        path: '/orders',
        builder: (context, state) => const OrdersScreen(),
      ),
      GoRoute(
        path: '/addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/help',
        builder: (context, state) => const HelpSupportScreen(),
      ),
      GoRoute(
        path: '/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
    ],
  );
}

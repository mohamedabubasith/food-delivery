import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/src/l10n/app_localizations.dart';
import '../../../utils/error_utils.dart';
import '../../../utils/toast_service.dart';
import '../application/login_bloc.dart';
import '../application/locale_bloc.dart';
import '../application/auth_bloc.dart';
import '../data/auth_repository.dart';
import '../data/token_storage.dart';
import 'email_login_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LoginBloc(
        context.read<AuthRepository>(),
      ),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      String phoneNumber = _phoneController.text.trim();
      
      // Add country code if not present (Firebase requires E.164 format: +919585909514)
      if (!phoneNumber.startsWith('+')) {
        phoneNumber = '+91$phoneNumber';
      }
      
      context.read<LoginBloc>().add(LoginSubmitted(phoneNumber));
    }
  }

  Future<void> _handleEmailLoginSuccess(BuildContext context, String token, AppLocalizations l10n) async {
    try {
      final repository = context.read<AuthRepository>();
      final profile = await repository.getUserProfile(token);
      final userData = profile['data'] as Map<String, dynamic>?;
      final userName = userData?['name'] ?? 'User';
      
      if (userName == 'User') {
        // User needs to set their name
        if (context.mounted) {
          context.push('/name-input', extra: token);
        }
      } else {
        // User already has a name, save token and go to home
        if (context.mounted) {
          final tokenStorage = context.read<TokenStorage>();
          await tokenStorage.saveToken(token);
          context.read<AuthBloc>().add(AuthLoggedIn(token));
          ToastService.showSuccess(context, l10n.emailSignInSuccess);
          context.go('/');
        }
      }
    } catch (e) {
      // If profile check fails, go to name input to be safe
      if (context.mounted) {
        context.push('/name-input', extra: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.language),
            onPressed: () {
              final currentLocale = context.read<LocaleBloc>().state.locale;
              final newLocale = currentLocale.languageCode == 'en' 
                  ? const Locale('ta') 
                  : const Locale('en');
              context.read<LocaleBloc>().add(ChangeLocale(newLocale));
            },
          ),
        ],
      ),
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
             final errorMessage = ErrorUtils.parseError(state.error);
             ToastService.showError(context, errorMessage);
          } else if (state is LoginSuccess) {
             ToastService.showSuccess(context, l10n.codeSent);
             context.push('/otp', extra: _phoneController.text.trim());
          } else if (state is GoogleLoginSuccess) {
            // Save the token to storage
            final tokenStorage = context.read<TokenStorage>();
            tokenStorage.saveToken(state.token);
            // Trigger auth state update with the token
            context.read<AuthBloc>().add(AuthLoggedIn(state.token));
            // Show success message
            ToastService.showSuccess(context, l10n.googleSignInSuccess);
            // Navigation will be handled by router redirect
          } else if (state is EmailLoginSuccess) {
            // Check if user already has a name (same flow as OTP)
            _handleEmailLoginSuccess(context, state.token, l10n);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.restaurant_menu, size: 80, color: theme.colorScheme.primary)
                        .animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    
                    Text(
                      l10n.welcomeTitle,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(begin: 0.3),
                    
                    const SizedBox(height: 8),
                    Text(
                      l10n.welcomeSubtitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(begin: 0.3, delay: 100.ms),

                    const SizedBox(height: 48),

                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: l10n.phoneNumber,
                        prefixText: '+91 ',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      validator: (value) {
                        if (value == null || value.length < 10) {
                          return l10n.phoneHint;
                        }
                        return null;
                      },
                    ).animate().fadeIn().slideX(begin: -0.1, delay: 200.ms),

                    const SizedBox(height: 24),

                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(l10n.continueButton),
                    ).animate().fadeIn().slideY(begin: 0.2, delay: 300.ms),

                    const SizedBox(height: 24),
                    
                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider()),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'or continue with',
                            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                          ),
                        ),
                        const Expanded(child: Divider()),
                      ],
                    ),

                    const SizedBox(height: 24),
                    
                    // Social Auth Icons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Icon
                        InkWell(
                          onTap: isLoading ? null : () {
                            context.read<LoginBloc>().add(const GoogleLoginSubmitted());
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Image.network(
                                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                errorBuilder: (context, error, stackTrace) => 
                                  const Icon(Icons.g_mobiledata, size: 28),
                              ),
                            ),
                          ),
                        ).animate().fadeIn().scale(delay: 400.ms),
                        
                        const SizedBox(width: 24),
                        
                        // Email Icon
                        InkWell(
                          onTap: isLoading ? null : () {
                            context.push('/email-login');
                          },
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.outline),
                            ),
                            child: const Icon(
                              Icons.email,
                              size: 28,
                            ),
                          ),
                        ).animate().fadeIn().scale(delay: 450.ms),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

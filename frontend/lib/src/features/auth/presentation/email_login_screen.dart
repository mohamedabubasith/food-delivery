import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/src/l10n/app_localizations.dart';
import '../application/login_bloc.dart';
import '../application/auth_bloc.dart';
import '../data/auth_repository.dart';
import '../data/token_storage.dart';
import '../../../utils/toast_service.dart';

class EmailLoginScreen extends StatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  State<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends State<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            EmailLoginSubmitted(
              _emailController.text.trim(),
              _passwordController.text,
              isSignUp: _isSignUp,
            ),
          );
    }
  }

  Future<void> _handleEmailLoginSuccess(BuildContext context, String token, AppLocalizations l10n) async {
    try {
      final repository = context.read<AuthRepository>();
      final profile = await repository.getUserProfile(token);
      final userData = profile['data'] as Map<String, dynamic>?;
      final userName = userData?['name'];

      if (userName == null || userName == 'User' || (userName is String && userName.isEmpty)) {
        // User needs to set their name
        if (context.mounted) {
          // Replace current screen with name input to avoid back stack issues
          context.pushReplacement('/name-input', extra: token);
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
        context.pushReplacement('/name-input', extra: token);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Helper to map error codes to user-friendly messages
    String _getErrorMessage(String error) {
      switch (error) {
        case 'EMAIL_IN_USE':
          return l10n.errorEmailInUse;
        case 'WRONG_PASSWORD':
          return l10n.errorWrongPassword;
        case 'USER_NOT_FOUND':
          return l10n.invalidEmail;
        case 'WEAK_PASSWORD':
          return l10n.weakPassword;
        default:
          return error;
      }
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state is LoginFailure) {
            ToastService.showError(
              context, 
              _getErrorMessage(state.error),
            );
          } else if (state is EmailLoginSuccess) {
             _handleEmailLoginSuccess(context, state.token, l10n);
          }
        },
        builder: (context, state) {
          final isLoading = state is LoginLoading;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    
                    Text(
                      _isSignUp ? l10n.signUp : l10n.signIn,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isSignUp 
                          ? 'Create a new account' 
                          : 'Sign in to your account',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: l10n.emailAddress,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.email),
                        enabled: !isLoading,
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.invalidEmail;
                        }
                        if (!value.contains('@')) {
                          return l10n.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: l10n.password,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        enabled: !isLoading,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      obscureText: _obscurePassword,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return l10n.weakPassword;
                        }
                        if (_isSignUp && value.length < 6) {
                          return l10n.weakPassword;
                        }
                        return null;
                      },
                    ),
                    
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      // Confirm Password Field
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          prefixIcon: const Icon(Icons.lock_outline),
                          enabled: !isLoading,
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (_isSignUp) {
                            if (value == null || value.isEmpty) {
                              return 'Please confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              _isSignUp ? l10n.signUp : l10n.signIn,
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Toggle Sign In / Sign Up
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _isSignUp ? l10n.alreadyHaveAccount : l10n.newUser,
                          style: theme.textTheme.bodyMedium,
                        ),
                        TextButton(
                          onPressed: isLoading ? null : () {
                            setState(() {
                              _isSignUp = !_isSignUp;
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            _isSignUp ? l10n.signIn : l10n.signUp,
                          ),
                        ),
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

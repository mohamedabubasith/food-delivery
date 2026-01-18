import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:frontend/src/l10n/app_localizations.dart';
import 'package:pausable_timer/pausable_timer.dart';
import '../../../utils/error_utils.dart';
import '../../../utils/toast_service.dart';
import '../application/otp_bloc.dart';
import '../application/auth_bloc.dart';
import '../data/auth_repository.dart';
import '../data/token_storage.dart';

class OtpScreen extends StatelessWidget {
  final String phoneNumber;

  const OtpScreen({super.key, required this.phoneNumber});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => OtpBloc(
        context.read<AuthRepository>(),
        context.read<TokenStorage>(),
        context.read<AuthBloc>(),
      ),
      child: _OtpView(phoneNumber: phoneNumber),
    );
  }
}

class _OtpView extends StatefulWidget {
  final String phoneNumber;
  const _OtpView({required this.phoneNumber});

  @override
  State<_OtpView> createState() => _OtpViewState();
}

class _OtpViewState extends State<_OtpView> {
  final _otpController = TextEditingController();
  late PausableTimer _timer;
  int _timeLeft = 30;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = PausableTimer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
          _timer.reset();
          _timer.start();
        }
      });
    });
    _timer.start();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _submit() {
    final otp = _otpController.text.trim();
    if (otp.length == 6) {
      context.read<OtpBloc>().add(OtpSubmitted(widget.phoneNumber, otp));
    } else {
      ToastService.showInfo(context, "Please enter a valid 6-digit OTP");
    }
  }

  void _resendCode() {
    context.read<OtpBloc>().add(OtpResendRequested(widget.phoneNumber));
    setState(() {
      _timeLeft = 30;
      _otpController.clear();
      _startTimer();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.pop()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocConsumer<OtpBloc, OtpState>(
        listener: (context, state) async {
           if (state is OtpSuccess) {
             // Check if user already has a name
             try {
               final repository = context.read<AuthRepository>();
               final profile = await repository.getUserProfile(state.token);
               print('DEBUG: Profile data: $profile');
               // Access name from data object (backend returns {success, data: {name, ...}})
               final userName = profile['name']?.toString() ?? '';
               print('DEBUG: Profile check result - Name: \'$userName\'');
               
               if (userName.trim().toLowerCase() == 'user' || userName.trim().isEmpty) {
                 // User needs to set their name
                 print('DEBUG: Name is User, showing name input screen');
                 if (context.mounted) {
                   context.push('/name-input', extra: state.token);
                 }
               } else {
                 // User already has a name, save token and go to home
                 print('DEBUG: User has name, going to home');
                 if (context.mounted) {
                   final tokenStorage = context.read<TokenStorage>();
                   await tokenStorage.saveToken(state.token);
                   context.read<AuthBloc>().add(AuthLoggedIn(state.token));
                   context.go('/');
                 }
               }
             } catch (e) {
               // If profile check fails, go to name input to be safe
               print('DEBUG: Profile check failed with error: $e');
               if (context.mounted) {
                 context.push('/name-input', extra: state.token);
               }
             }
           } else if (state is OtpFailure) {
             // Translate error codes to localized messages
             String errorMessage;
             switch (state.error) {
               case 'INVALID_OTP':
                 errorMessage = l10n.invalidOtpCode;
                 break;
               case 'OTP_EXPIRED':
                 errorMessage = l10n.otpExpired;
                 break;
               case 'TOO_MANY_REQUESTS':
                 errorMessage = l10n.tooManyRequests;
                 break;
               case 'PHONE_INVALID':
                 errorMessage = l10n.phoneNumberInvalid;
                 break;
               case 'VERIFICATION_FAILED':
                 errorMessage = l10n.verificationFailed;
                 break;
               default:
                 errorMessage = ErrorUtils.parseError(state.error);
             }
             ToastService.showError(context, errorMessage);
           } else if (state is OtpResendSuccess) {
             ToastService.showSuccess(context, state.message);
           }
        },
        builder: (context, state) {
          final isLoading = state is OtpLoading;

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  l10n.verification,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: 0.3),
                
                const SizedBox(height: 8),
                Text(
                  l10n.enterOtp(widget.phoneNumber),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn().slideY(begin: 0.3, delay: 100.ms),

                const SizedBox(height: 48),

                TextField(
                  controller: _otpController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, letterSpacing: 8),
                  maxLength: 6,
                  decoration: const InputDecoration(
                    hintText: "• • • • • •",
                    counterText: "",
                  ),
                  onSubmitted: (_) => _submit(),
                ).animate().fadeIn().slideX(begin: -0.1, delay: 200.ms),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                   child: isLoading 
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(l10n.verifyButton),
                ).animate().fadeIn().slideY(begin: 0.2, delay: 300.ms),

                const SizedBox(height: 24),

                Center(
                  child: _timeLeft > 0
                    ? Text(l10n.resendCodeIn(_timeLeft.toString().padLeft(2, '0')), style: const TextStyle(color: Colors.grey))
                    : TextButton(
                        onPressed: _resendCode,
                        child: Text(l10n.resendCode),
                      ),
                ).animate().fadeIn(delay: 500.ms),
              ],
            ),
          );
        },
      ),
    );
  }
}

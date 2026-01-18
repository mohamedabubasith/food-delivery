// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Local Eats';

  @override
  String get welcomeTitle => 'Welcome to Local Eats';

  @override
  String get welcomeSubtitle => 'Order delicious food from local restaurants.';

  @override
  String get phoneNumber => 'Phone Number';

  @override
  String get phoneHint => 'Enter a valid 10-digit number';

  @override
  String get continueButton => 'Continue';

  @override
  String get termsText =>
      'By continuing, you agree to our Terms & Privacy Policy.';

  @override
  String get verification => 'Verification';

  @override
  String enterOtp(String phone) {
    return 'Enter the OTP sent to $phone';
  }

  @override
  String get verifyButton => 'Verify & Login';

  @override
  String resendCodeIn(String time) {
    return 'Resend code in 00:$time';
  }

  @override
  String get resendCode => 'Resend Code';

  @override
  String get loginSuccessful => 'Login Successful';

  @override
  String get codeSent => 'Verification code sent';

  @override
  String get invalidCode => 'Invalid verification code';

  @override
  String get homeTitle => 'Home Screen (BLoC Edition)';

  @override
  String get completeProfile => 'Complete Your Profile';

  @override
  String get whatsYourName => 'What\'s your name?';

  @override
  String get personalizeName => 'This helps us personalize your experience';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterYourName => 'Enter your name';

  @override
  String get pleaseEnterName => 'Please enter your name';

  @override
  String get nameMinLength => 'Name must be at least 2 characters';

  @override
  String get welcome => 'Welcome!';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get googleSignInSuccess => 'Google Sign-In successful';

  @override
  String get invalidOtpCode => 'Invalid verification code. Please try again.';

  @override
  String get otpExpired =>
      'Verification code expired. Please request a new code.';

  @override
  String get tooManyRequests => 'Too many attempts. Please try again later.';

  @override
  String get phoneNumberInvalid => 'Invalid phone number format.';

  @override
  String get verificationFailed => 'Verification failed. Please try again.';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get password => 'Password';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get continueWithEmail => 'Continue with Email';

  @override
  String get newUser => 'New user?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get weakPassword => 'Password is too weak (min 6 characters)';

  @override
  String get emailAlreadyInUse => 'Email already in use';

  @override
  String get wrongPassword => 'Incorrect password';

  @override
  String get userNotFound => 'No account found with this email';

  @override
  String get emailSignInSuccess => 'Login successful!';

  @override
  String get errorEmailInUse =>
      'Account exists. Please sign in or use Google if you used it before.';

  @override
  String get errorWrongPassword =>
      'Incorrect password. If you used Google, please sign in with Google.';
}

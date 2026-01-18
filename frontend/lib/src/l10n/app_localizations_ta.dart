// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Tamil (`ta`).
class AppLocalizationsTa extends AppLocalizations {
  AppLocalizationsTa([String locale = 'ta']) : super(locale);

  @override
  String get appName => 'லோக்கல் ஈட்ஸ் (Local Eats)';

  @override
  String get welcomeTitle => 'லோக்கல் ஈட்ஸ்-க்கு உங்களை வரவேற்கிறோம்';

  @override
  String get welcomeSubtitle =>
      'உள்ளூர் உணவகங்களில் இருந்து சுவையான உணவை ஆர்டர் செய்யுங்கள்.';

  @override
  String get phoneNumber => 'கைபேசி எண்';

  @override
  String get phoneHint => 'சரியான 10 இலக்க எண்ணை உள்ளிடவும்';

  @override
  String get continueButton => 'தொடரவும்';

  @override
  String get termsText =>
      'தொடர்வதன் மூலம், எங்கள் விதிமுறைகள் மற்றும் தனியுரிமைக் கொள்கையை ஏற்கிறீர்கள்.';

  @override
  String get verification => 'சரிபார்ப்பு';

  @override
  String enterOtp(String phone) {
    return '$phone-க்கு அனுப்பப்பட்ட OTP-ஐ உள்ளிடவும்';
  }

  @override
  String get verifyButton => 'சரிபார்த்து உள்நுழையவும்';

  @override
  String resendCodeIn(String time) {
    return '00:$time வினாடிகளில் மீண்டும் அனுப்பு';
  }

  @override
  String get resendCode => 'மீண்டும் குறியீட்டை அனுப்பு';

  @override
  String get loginSuccessful => 'வெற்றிகரமாக உள்நுழைந்தீர்கள்';

  @override
  String get codeSent => 'சரிபார்ப்புக் குறியீடு அனுப்பப்பட்டது';

  @override
  String get invalidCode => 'தவறான சரிபார்ப்புக் குறியீடு';

  @override
  String get homeTitle => 'முகப்புத் திரை (BLoC பதிப்பு)';

  @override
  String get completeProfile => 'உங்கள் சுயவிவரத்தை நிறைவு செய்யுங்கள்';

  @override
  String get whatsYourName => 'உங்கள் பெயர் என்ன?';

  @override
  String get personalizeName => 'இது உங்கள் அனுபவத்தைத் தனிப்பயனாக்க உதவுகிறது';

  @override
  String get fullName => 'முழுப் பெயர்';

  @override
  String get enterYourName => 'உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get pleaseEnterName => 'தயவுசெய்து உங்கள் பெயரை உள்ளிடவும்';

  @override
  String get nameMinLength => 'பெயர் குறைந்தது 2 எழுத்துக்களாக இருக்க வேண்டும்';

  @override
  String get welcome => 'வரவேற்பு!';

  @override
  String get continueWithGoogle => 'Google மூலம் தொடரவும்';

  @override
  String get googleSignInSuccess => 'Google உள்நுழைவு வெற்றிகரமாக முடிந்தது';

  @override
  String get invalidOtpCode =>
      'தவறான சரிபார்ப்புக் குறியீடு. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get otpExpired =>
      'சரிபார்ப்புக் குறியீடு காலாவதியானது. புதிய குறியீட்டைக் கோரவும்.';

  @override
  String get tooManyRequests =>
      'பல முயற்சிகள். சிறிது நேரம் கழித்து முயற்சிக்கவும்.';

  @override
  String get phoneNumberInvalid => 'தவறான தொலைபேசி எண் வடிவம்.';

  @override
  String get verificationFailed =>
      'சரிபார்ப்பு தோல்வியடைந்தது. மீண்டும் முயற்சிக்கவும்.';

  @override
  String get emailAddress => 'மின்னஞ்சல் முகவரி';

  @override
  String get password => 'கடவுச்சொல்';

  @override
  String get signIn => 'உள்நுழைக';

  @override
  String get signUp => 'பதிவு செய்க';

  @override
  String get continueWithEmail => 'மின்னஞ்சல் மூலம் தொடரவும்';

  @override
  String get newUser => 'புதிய பயனரா?';

  @override
  String get alreadyHaveAccount => 'ஏற்கனவே கணக்கு உள்ளதா?';

  @override
  String get invalidEmail => 'தவறான மின்னஞ்சல் முகவரி';

  @override
  String get weakPassword =>
      'கடவுச்சொல் மிகவும் எளிதானது (குறைந்தது 6 எழுத்துக்கள்)';

  @override
  String get emailAlreadyInUse => 'மின்னஞ்சல் ஏற்கனவே பயன்பாட்டில் உள்ளது';

  @override
  String get wrongPassword => 'தவறான கடவுச்சொல்';

  @override
  String get userNotFound => 'இந்த மின்னஞ்சலுடன் கணக்கு இல்லை';

  @override
  String get emailSignInSuccess => 'நுழைவு வெற்றிகரமாக முடிந்தது!';

  @override
  String get errorEmailInUse =>
      'கணக்கு உள்ளது. தயவுசெய்து உள்நுழையவும் அல்லது Google மூலம் முயற்சிக்கவும்.';

  @override
  String get errorWrongPassword =>
      'தவறான கடவுச்சொல். நீங்கள் Google ஐப் பயன்படுத்தியிருந்தால், தயவுசெய்து Google மூலம் உள்நுழையவும்.';
}

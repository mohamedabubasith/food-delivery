import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../../utils/dio_provider.dart';

class AuthRepository {
  final Dio _dio;
  final String? googleClientId;

  AuthRepository(this._dio, {this.googleClientId});

  Future<void> loginWithPhone(String phoneNumber) async {
    try {
      await _dio.post(
        '/auth/login',
        data: {
          'phone_number': phoneNumber,
          'provider': 'local', // Explicitly use local provider for OTP flow
        },
      );
    } catch (e) {
      if (e is DioException) {
         // If error is 400 "Phone number not found", we might need to register first?
         // For now, assuming user exists or handled by backend error message
         throw Exception(e.response?.data['detail'] ?? 'Login failed');
      }
      rethrow;
    }
  }

  Future<String> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        clientId: googleClientId,
      );
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        throw Exception('Google Sign-In cancelled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final String? idToken = await userCredential.user?.getIdToken();

      if (idToken == null) {
        throw Exception('Failed to get ID token from Firebase');
      }

      // Extract display name from Google account
      final String displayName = googleUser.displayName ?? 'User';

      // Send the ID token and name to our backend
      final response = await _dio.post(
        '/auth/login',
        data: {
          'token': idToken,
          'provider': 'firebase',
          'name': displayName,
        },
      );

      final data = response.data;
      if (data.containsKey('data')) {
        return data['data']['access_token'];
      }
      return data['access_token'];
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Google login failed');
      }
      rethrow;
    }
  }

  // Firebase Phone Authentication
  String? _verificationId;
  int? _resendToken;

  Future<void> signInWithPhoneNumber(
    String phoneNumber, {
    required Function(String verificationId) onCodeSent,
    required Function(String error) onError,
    Function(PhoneAuthCredential credential)? onAutoVerify,
  }) async {
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          if (onAutoVerify != null) {
            onAutoVerify(credential);
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          onError(e.message ?? 'Phone verification failed');
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          onCodeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
        forceResendingToken: _resendToken,
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<String> verifyPhoneCode(String smsCode) async {
    try {
      if (_verificationId == null) {
        throw Exception('OTP_EXPIRED');
      }

      // Create credential
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      // Sign in with credential
      final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      
      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('VERIFICATION_FAILED');
      }

      // Get phone number from user
      final phoneNumber = userCredential.user?.phoneNumber;

      // Send token to backend
      final response = await _dio.post(
        '/auth/login',
        data: {
          'token': idToken,
          'provider': 'firebase',
          'phone_number': phoneNumber,
        },
      );

      final data = response.data;
      if (data.containsKey('data')) {
        return data['data']['access_token'];
      }
      return data['access_token'];
    } on FirebaseAuthException catch (e) {
      // Handle specific Firebase auth errors
      switch (e.code) {
        case 'invalid-verification-code':
          throw Exception('INVALID_OTP');
        case 'session-expired':
          throw Exception('OTP_EXPIRED');
        case 'too-many-requests':
          throw Exception('TOO_MANY_REQUESTS');
        case 'invalid-phone-number':
          throw Exception('PHONE_INVALID');
        default:
          throw Exception('VERIFICATION_FAILED');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('VERIFICATION_FAILED');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String token) async {
    try {
      final response = await _dio.get(
        '/auth/whoiam',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      final responseData = response.data;
      if (responseData is Map && responseData.containsKey('data')) {
        return responseData['data'] as Map<String, dynamic>;
      }
      return responseData as Map<String, dynamic>;
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to get profile');
      }
      rethrow;
    }
  }

  Future<void> updateUserName(String name, String token) async {
    try {
      await _dio.put(
        '/auth/profile',
        data: {'name': name},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
    } catch (e) {
      if (e is DioException) {
        throw Exception(e.response?.data['detail'] ?? 'Failed to update name');
      }
      rethrow;
    }
  }

  // Firebase Email/Password Authentication
  Future<String> signInWithEmail(String email, String password) async {
    try {
      // Sign in with Firebase
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get ID token from Firebase');
      }

      // Send token to backend
      final response = await _dio.post(
        '/auth/login',
        data: {
          'token': idToken,
          'provider': 'firebase',
          'email': email,
        },
      );

      final data = response.data;
      if (data.containsKey('data')) {
        return data['data']['access_token'];
      }
      return data['access_token'];
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          throw Exception('USER_NOT_FOUND');
        case 'wrong-password':
          throw Exception('WRONG_PASSWORD');
        case 'invalid-email':
          throw Exception('INVALID_EMAIL');
        case 'user-disabled':
          throw Exception('USER_DISABLED');
        default:
          throw Exception('EMAIL_SIGNIN_FAILED');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('EMAIL_SIGNIN_FAILED');
      }
      rethrow;
    }
  }

  Future<String> signUpWithEmail(String email, String password) async {
    try {
      // Create account with Firebase
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Get Firebase ID token
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get ID token from Firebase');
      }

      // Send token to backend
      final response = await _dio.post(
        '/auth/login',
        data: {
          'token': idToken,
          'provider': 'firebase',
          'email': email,
        },
      );

      final data = response.data;
      if (data.containsKey('data')) {
        return data['data']['access_token'];
      }
      return data['access_token'];
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          throw Exception('WEAK_PASSWORD');
        case 'email-already-in-use':
          throw Exception('EMAIL_IN_USE');
        case 'invalid-email':
          throw Exception('INVALID_EMAIL');
        default:
          throw Exception('EMAIL_SIGNUP_FAILED');
      }
    } catch (e) {
      if (e is DioException) {
        throw Exception('EMAIL_SIGNUP_FAILED');
      }
      rethrow;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  // Note: This provider is for Riverpod, but the app uses RepositoryProvider.
  // We should ensure consistency if both are used.
  return AuthRepository(dio);
});

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../data/auth_repository.dart';

// Events
abstract class LoginEvent extends Equatable {
  const LoginEvent();
  @override
  List<Object> get props => [];
}

class LoginSubmitted extends LoginEvent {
  final String phoneNumber;
  const LoginSubmitted(this.phoneNumber);
  @override
  List<Object> get props => [phoneNumber];
}

class GoogleLoginSubmitted extends LoginEvent {
  const GoogleLoginSubmitted();
}

class EmailLoginSubmitted extends LoginEvent {
  final String email;
  final String password;
  final bool isSignUp;
  const EmailLoginSubmitted(this.email, this.password, {this.isSignUp = false});
  @override
  List<Object> get props => [email, password, isSignUp];
}

// States
abstract class LoginState extends Equatable {
  const LoginState();
  @override
  List<Object> get props => [];
}

class LoginInitial extends LoginState {}
class LoginLoading extends LoginState {}
class LoginSuccess extends LoginState {
  final String message;
  const LoginSuccess(this.message);
  @override
  List<Object> get props => [message];
}

class GoogleLoginSuccess extends LoginState {
  final String token;
  const GoogleLoginSuccess(this.token);
  @override
  List<Object> get props => [token];
}

class EmailLoginSuccess extends LoginState {
  final String token;
  const EmailLoginSuccess(this.token);
  @override
  List<Object> get props => [token];
}

class LoginFailure extends LoginState {
  final String error;
  const LoginFailure(this.error);
  @override
  List<Object> get props => [error];
}

// BLoC
class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRepository _repository;

  LoginBloc(this._repository) : super(LoginInitial()) {
    on<LoginSubmitted>(_onSubmitted);
    on<GoogleLoginSubmitted>(_onGoogleSubmitted);
    on<EmailLoginSubmitted>(_onEmailSubmitted);
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    
    // Use Firebase Phone Authentication
    await _repository.signInWithPhoneNumber(
      event.phoneNumber,
      onCodeSent: (verificationId) {
        emit(const LoginSuccess('Verification code sent'));
      },
      onError: (error) {
        emit(LoginFailure(error));
      },
      onAutoVerify: (credential) async {
        // Auto-verification succeeded (Android only)
        emit(const LoginSuccess('Auto-verified'));
      },
    );
  }

  Future<void> _onGoogleSubmitted(
    GoogleLoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final token = await _repository.signInWithGoogle();
      // For Google login, we directly get the token, so it's a "Final Success"
      emit(GoogleLoginSuccess(token));
    } catch (e) {
      emit(LoginFailure(e.toString()));
    }
  }

  Future<void> _onEmailSubmitted(
    EmailLoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(LoginLoading());
    try {
      final token = event.isSignUp
          ? await _repository.signUpWithEmail(event.email, event.password)
          : await _repository.signInWithEmail(event.email, event.password);
      emit(EmailLoginSuccess(token));
    } catch (e) {
      final message = e.toString().replaceAll('Exception: ', '');
      emit(LoginFailure(message));
    }
  }
}

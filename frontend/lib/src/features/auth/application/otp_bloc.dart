import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:frontend/src/features/auth/data/auth_repository.dart';
import 'package:frontend/src/features/auth/data/token_storage.dart';
import '../application/auth_bloc.dart';

// Events
abstract class OtpEvent extends Equatable {
  const OtpEvent();
  @override
  List<Object> get props => [];
}

class OtpSubmitted extends OtpEvent {
  final String phoneNumber;
  final String otp;
  const OtpSubmitted(this.phoneNumber, this.otp);
  @override
  List<Object> get props => [phoneNumber, otp];
}

class OtpResendRequested extends OtpEvent {
  final String phoneNumber;
  const OtpResendRequested(this.phoneNumber);
  @override
  List<Object> get props => [phoneNumber];
}

// States
abstract class OtpState extends Equatable {
  const OtpState();
  @override
  List<Object> get props => [];
}

class OtpInitial extends OtpState {}
class OtpLoading extends OtpState {}
class OtpSuccess extends OtpState {
  final String token;
  const OtpSuccess(this.token);
  @override
  List<Object> get props => [token];
}
class OtpFailure extends OtpState {
  final String error;
  const OtpFailure(this.error);
  @override
  List<Object> get props => [error];
}

class OtpResendSuccess extends OtpState {
  final String message;
  const OtpResendSuccess(this.message);
  @override
  List<Object> get props => [message];
}

// BLoC
class OtpBloc extends Bloc<OtpEvent, OtpState> {
  final AuthRepository _repository;
  final TokenStorage _tokenStorage;
  final AuthBloc _authBloc;

  OtpBloc(this._repository, this._tokenStorage, this._authBloc) : super(OtpInitial()) {
    on<OtpSubmitted>(_onSubmitted);
    on<OtpResendRequested>(_onResendRequested);
  }

  Future<void> _onSubmitted(
    OtpSubmitted event,
    Emitter<OtpState> emit,
  ) async {
    emit(OtpLoading());
    try {
      // Use Firebase Phone Code verification
      final token = await _repository.verifyPhoneCode(event.otp);
      // Don't save token or update auth here - let the name input screen handle it
      emit(OtpSuccess(token));
    } catch (e) {
      // Extract error code from exception
      String errorMessage = e.toString();
      if (errorMessage.contains('INVALID_OTP')) {
        errorMessage = 'INVALID_OTP';
      } else if (errorMessage.contains('OTP_EXPIRED')) {
        errorMessage = 'OTP_EXPIRED';
      } else if (errorMessage.contains('TOO_MANY_REQUESTS')) {
        errorMessage = 'TOO_MANY_REQUESTS';
      } else if (errorMessage.contains('PHONE_INVALID')) {
        errorMessage = 'PHONE_INVALID';
      } else if (errorMessage.contains('VERIFICATION_FAILED')) {
        errorMessage = 'VERIFICATION_FAILED';
      }
      emit(OtpFailure(errorMessage));
    }
  }

  Future<void> _onResendRequested(
    OtpResendRequested event,
    Emitter<OtpState> emit,
  ) async {
    emit(OtpLoading());
    await _repository.signInWithPhoneNumber(
      event.phoneNumber,
      onCodeSent: (verificationId) {
        emit(const OtpResendSuccess("Verification code resent"));
      },
      onError: (error) {
        emit(OtpFailure(error));
      },
      onAutoVerify: (credential) {
         // In resend flow, auto-verify might be tricky to handle here as we'd need to verify the code
         // For now, let's just let it be. If auto-verify happens, the user might just need to click 'Verify' or we could auto-submit.
      },
    );
  }
}

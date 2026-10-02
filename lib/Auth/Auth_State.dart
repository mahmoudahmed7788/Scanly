part of 'Auth_Cubit.dart';

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
  notRegistered,
  alreadyRegistered,
}

class AuthState {
  final AuthStatus status;
  final String? errorMessage;
  final String? errorCode;
  final User? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.errorCode,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    String? errorCode,
    User? user,
    bool clearError = false,
    bool clearErrorCode = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
      errorCode: clearError || clearErrorCode
          ? null
          : errorCode ?? this.errorCode,
      user: clearUser
          ? null
          : user ?? this.user,
    );
  }
}
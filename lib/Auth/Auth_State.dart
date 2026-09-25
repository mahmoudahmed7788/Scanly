// ============================================================
// AUTH STATE
// ============================================================

part of 'Auth_Cubit.dart';

// ============================================================
// AUTH STATUS
// ============================================================

enum AuthStatus {
  initial,
  loading,
  success,
  failure,
}

// ============================================================
// AUTH STATE
// ============================================================

class AuthState {
  final AuthStatus status;

  final String? errorMessage;

  final User? user;

  const AuthState({
    this.status = AuthStatus.initial,
    this.errorMessage,
    this.user,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? errorMessage,
    User? user,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: clearError
          ? null
          : errorMessage ?? this.errorMessage,
      user: clearUser
          ? null
          : user ?? this.user,
    );
  }
}
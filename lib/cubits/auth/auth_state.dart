abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSuccess extends AuthState {
  final String role;
  final String? centerId;

  AuthSuccess({required this.role, this.centerId});
}

class AuthError extends AuthState {
  final String message;

  AuthError(this.message);
}
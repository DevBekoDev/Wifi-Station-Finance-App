abstract class ManagerActivationState {}

class ManagerActivationInitial extends ManagerActivationState {}

class ManagerActivationLoading extends ManagerActivationState {}

class ManagerActivationSuccess extends ManagerActivationState {
  final String message;

  ManagerActivationSuccess(this.message);
}

class ManagerActivationError extends ManagerActivationState {
  final String message;

  ManagerActivationError(this.message);
}
abstract class CreateCenterState {}

class CreateCenterInitial extends CreateCenterState {}

class CreateCenterLoading extends CreateCenterState {}

class CreateCenterSuccess extends CreateCenterState {
  final String message;

  CreateCenterSuccess(this.message);
}

class CreateCenterError extends CreateCenterState {
  final String message;

  CreateCenterError(this.message);
}
import "package:ownfinances/core/error/failure.dart";

class Result<T> {
  final T? data;
  final Failure? failure;

  const Result._({this.data, this.failure});

  bool get isSuccess => failure == null;

  static Result<T> success<T>(T data) => Result._(data: data);

  static Result<T> error<T>(Failure failure) => Result._(failure: failure);
}

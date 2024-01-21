import 'package:http/http.dart' as http;

class HuggingFaceError extends Error {
  HuggingFaceError._({
    required this.statusCode,
    required this.message,
  });

  final int statusCode;
  final String message;

  factory HuggingFaceError.fromResponse(http.Response response) {
    final statusCode = response.statusCode;
    final message = response.body;

    assert(statusCode != 200,
        'HuggingFaceError should only be used for non-200 status codes');

    return switch (statusCode) {
      HuggingFaceTooManyRequestsError.fixedStatusCode =>
        HuggingFaceTooManyRequestsError(message: message),
      HuggingFaceModelNotFoundError.fixedStatusCode =>
        HuggingFaceModelNotFoundError(message: message),
      HuggingFaceLoadingError.fixedStatusCode =>
        HuggingFaceLoadingError(message: message),
      _ => HuggingFaceUnknownError(
          statusCode: statusCode,
          message: message,
        ),
    };
  }
}

class HuggingFaceTooManyRequestsError extends HuggingFaceError {
  static const fixedStatusCode = 429;

  HuggingFaceTooManyRequestsError({required super.message})
      : super._(statusCode: fixedStatusCode);

  @override
  String toString() => 'HuggingFace too many requests error: $message';
}

class HuggingFaceModelNotFoundError extends HuggingFaceError {
  static const fixedStatusCode = 404;

  HuggingFaceModelNotFoundError({required super.message})
      : super._(statusCode: fixedStatusCode);

  @override
  String toString() => 'HuggingFace model not found: $message';
}

/// If the requested model is not loaded in memory, the Hosted Inference API
/// will start by loading the model into memory and returning a 503 response,
/// before it can respond with the prediction.
class HuggingFaceLoadingError extends HuggingFaceError {
  static const fixedStatusCode = 503;

  HuggingFaceLoadingError({required super.message})
      : super._(statusCode: fixedStatusCode);

  @override
  String toString() => 'HuggingFace model is loading: $message';
}

/// e.g. {"error":"cannot identify image file <_io.BytesIO object at 0x7f416c25bdb0>"}
class HuggingFaceUnknownError extends HuggingFaceError {
  HuggingFaceUnknownError({
    required super.statusCode,
    required super.message,
  }) : super._();

  @override
  String toString() => 'HuggingFace unknown error ($statusCode): $message';
}

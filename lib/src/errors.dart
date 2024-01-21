import 'dart:convert';

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
        HuggingFaceLoadingError(json: message),
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

  final double estimatedTime;

  /// e.g. {"error":"Model instruction-tuning-sd/cartoonizer is currently loading","estimated_time":219.25982666015625}
  HuggingFaceLoadingError({required String json})
      : estimatedTime = _parseEstimatedTime(json),
        super._(
          statusCode: fixedStatusCode,
          message: _parseError(json),
        );

  /// Returns the error from the JSON response.
  static String _parseError(String json) {
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    return parsed['error'];
  }

  /// Returns the estimated time from the JSON response.
  static double _parseEstimatedTime(String json) {
    final parsed = jsonDecode(json) as Map<String, dynamic>;
    return (parsed['estimated_time'] as num).toDouble();
  }

  @override
  String toString() =>
      'HuggingFaceLoadingError: $message, estimated time: ${estimatedTime}s';
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

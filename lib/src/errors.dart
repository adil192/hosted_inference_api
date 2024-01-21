import 'dart:convert';

import 'package:http/http.dart' as http;

/// A base class for errors from the HuggingFace Hosted Inference API.
class HFApiError extends Error {
  HFApiError._({
    required this.statusCode,
    required this.message,
  });

  /// The HTTP status code of the error.
  final int statusCode;

  /// The error message.
  final String message;

  /// Returns a [HFApiError] based on the
  /// HTTP response's status code.
  ///
  /// Note that the error is only returned, not thrown.
  ///
  /// This method should only be used for non-200 status codes.
  factory HFApiError.fromResponse(http.Response response) {
    final statusCode = response.statusCode;
    final message = response.body;

    assert(statusCode != 200,
        'HuggingFaceError should only be used for non-200 status codes');

    return switch (statusCode) {
      HFApiTooManyRequestsError.fixedStatusCode =>
        HFApiTooManyRequestsError._(message: message),
      HFApiModelNotFoundError.fixedStatusCode =>
        HFApiModelNotFoundError._(message: message),
      HFApiLoadingError.fixedStatusCode => HFApiLoadingError._(json: message),
      _ => HFApiUnknownError._(
          statusCode: statusCode,
          message: message,
        ),
    };
  }
}

/// You have exceeded the rate limit.
/// If you haven't yet specified an API token,
/// provide one to increase your quota.
class HFApiTooManyRequestsError extends HFApiError {
  /// The status code corresponding to this error.
  static const fixedStatusCode = 429;

  HFApiTooManyRequestsError._({required super.message})
      : super._(statusCode: fixedStatusCode);

  @override
  String toString() => 'HuggingFace too many requests error: $message';
}

/// The requested model was not found.
class HFApiModelNotFoundError extends HFApiError {
  /// The status code corresponding to this error.
  static const fixedStatusCode = 404;

  HFApiModelNotFoundError._({required super.message})
      : super._(statusCode: fixedStatusCode);

  @override
  String toString() => 'HuggingFace model not found: $message';
}

/// If the requested model is not loaded in memory, the Hosted Inference API
/// will start by loading the model into memory and returning a 503 response,
/// before it can respond with the prediction.
class HFApiLoadingError extends HFApiError {
  /// The status code corresponding to this error.
  static const fixedStatusCode = 503;

  /// The estimated time in seconds until the model is loaded.
  final double estimatedTime;

  /// e.g. {"error":"Model instruction-tuning-sd/cartoonizer is currently loading","estimated_time":219.25982666015625}
  HFApiLoadingError._({required String json})
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

/// An error from the HuggingFace Hosted Inference API
/// that this package does not recognize.
///
/// e.g. {"error":"cannot identify image file <_io.BytesIO object at 0x7f416c25bdb0>"}
class HFApiUnknownError extends HFApiError {
  HFApiUnknownError._({
    required super.statusCode,
    required super.message,
  }) : super._();

  @override
  String toString() => 'HuggingFace unknown error ($statusCode): $message';
}

import 'package:http/http.dart' as http;
import 'package:hosted_inference_api/src/errors.dart';
import 'package:meta/meta.dart';

export 'package:hosted_inference_api/src/errors.dart';

/// Determines the type of the output of a model.
enum HFOutputType {
  /// The model outputs text.
  string,

  /// The model outputs bytes (e.g. an image).
  bytes,
}

/// A client for the HuggingFace Hosted Inference API.
class HFApi {
  /// Creates a new client for the HuggingFace Hosted Inference API.
  HFApi({
    required this.model,
    required this.outputType,
    required this.apiToken,
  }) : _client = http.Client();

  /// Creates a new client for the HuggingFace Hosted Inference API,
  /// with a custom (i.e. mock) HTTP client.
  @visibleForTesting
  HFApi.withClient({
    required this.model,
    required this.outputType,
    required this.apiToken,
    required http.Client client,
  }) : _client = client;

  /// The model to use.
  /// See https://huggingface.co/models for a list of available models.
  final String model;

  /// The type of the output of the model.
  final HFOutputType outputType;

  /// The API token to use.
  ///
  /// This can be null,
  /// but (I think) the rate limit is stricter without a token.
  final String? apiToken;

  late final http.Client _client;

  /// The HTTP client for this model.
  late final endpoint =
      Uri.https('api-inference.huggingface.co', '/models/$model');

  /// The HTTP headers for this model,
  /// containing the API token if it is not null.
  late final headers = apiToken == null
      ? null
      : Map<String, String>.unmodifiable({
          'Authorization': 'Bearer $apiToken',
        });

  /// Runs the model on the given input.
  Future<TOutput> run<TOutput>(Object input) async {
    final response = await _client.post(
      endpoint,
      headers: headers,
      body: input,
    );

    if (response.statusCode != 200) {
      throw HFApiError.fromResponse(response);
    }

    return switch (outputType) {
      HFOutputType.string => response.body,
      HFOutputType.bytes => response.bodyBytes,
    } as TOutput;
  }
}

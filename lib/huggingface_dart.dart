import 'package:http/http.dart' as http;
import 'package:huggingface_dart/src/errors.dart';
import 'package:meta/meta.dart';

export 'package:huggingface_dart/src/errors.dart';

enum HFOutputType {
  string,
  bytes,
}

class HuggingFace {
  HuggingFace({
    required this.model,
    required this.outputType,
    required this.apiToken,
  }) : _client = http.Client();

  @visibleForTesting
  HuggingFace.withClient({
    required this.model,
    required this.outputType,
    required this.apiToken,
    required http.Client client,
  }) : _client = client;

  final String model;
  final HFOutputType outputType;
  final String? apiToken;

  late final http.Client _client;
  late final endpoint =
      Uri.https('api-inference.huggingface.co', '/models/$model');

  late final headers = apiToken == null
      ? null
      : Map<String, String>.unmodifiable({
          'Authorization': 'Bearer $apiToken',
        });

  Future<TOutput> run<TOutput>(Object input) async {
    final response = await _client.post(
      endpoint,
      headers: headers,
      body: input,
    );

    if (response.statusCode != 200) {
      throw HuggingFaceError.fromResponse(response);
    }

    return switch (outputType) {
      HFOutputType.string => response.body,
      HFOutputType.bytes => response.bodyBytes,
    } as TOutput;
  }
}

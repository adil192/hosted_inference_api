import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:huggingface_dart/src/errors.dart';

export 'package:huggingface_dart/src/errors.dart';

class HuggingFace<TInput extends Object, TOutput extends Object> {
  HuggingFace({
    required this.model,
    required this.apiToken,
  })  : assert(TInput == String || TInput == Uint8List),
        assert(TOutput == String || TOutput == Uint8List),
        _client = http.Client();

  final String model;
  final String? apiToken;

  late final http.Client _client;
  late final endpoint =
      Uri.https('api-inference.huggingface.co', '/models/$model');

  late final headers = apiToken == null
      ? null
      : Map<String, String>.unmodifiable({
          'Authorization': 'Bearer $apiToken',
        });

  Future<TOutput> run(TInput input) async {
    final response = await _client.post(
      endpoint,
      headers: headers,
      body: input,
    );

    if (response.statusCode != 200) {
      throw HuggingFaceError.fromResponse(response);
    }

    return switch (TOutput) {
      const (String) => response.body as TOutput,
      const (Uint8List) => response.bodyBytes as TOutput,
      _ => throw UnsupportedError('Unsupported output type: $TOutput'),
    };
  }
}

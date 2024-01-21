import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;
import 'package:hosted_inference_api/hosted_inference_api.dart';
import 'package:test/test.dart';

void main() {
  group('gpt2:', () {
    const input = 'Hello, my name is';
    const output = 'Hello, my name is John';

    const error429 = '{"error":"TODO: Find an actual response"}';
    const error404 = '{"error":"TODO: Find an actual response"}';
    const error503 =
        '{"error":"Model instruction-tuning-sd/cartoonizer is currently loading","estimated_time":219.25982666015625}';
    const error400 =
        '{"error":"cannot identify image file <_io.BytesIO object at 0x7f416c25bdb0>"}';

    test('normal response', () async {
      final api = HFApi.withClient(
        model: 'gpt2',
        outputType: HFOutputType.string,
        apiToken: 'api_token',
        client: MockClient((request) async {
          expect(request.url.host, 'api-inference.huggingface.co');
          expect(request.url.path, '/models/gpt2');
          expect(request.headers['Authorization'], 'Bearer api_token');
          expect(request.body, input);
          return http.Response(output, 200);
        }),
      );

      final result = await api.run<String>(input);
      expect(result, output);
    });

    test('too many requests', () async {
      final api = HFApi.withClient(
        model: 'gpt2',
        outputType: HFOutputType.string,
        apiToken: 'api_token',
        client: MockClient((request) async => http.Response(error429, 429)),
      );

      try {
        await api.run<String>(input);
        fail('Expected HFApiTooManyRequestsError');
      } on HFApiTooManyRequestsError catch (e) {
        expect(e.message, error429);
      }
    });

    test('model not found', () async {
      final api = HFApi.withClient(
        model: 'gpt2',
        outputType: HFOutputType.string,
        apiToken: 'api_token',
        client: MockClient((request) async => http.Response(error404, 404)),
      );

      try {
        await api.run<String>(input);
        fail('Expected HFApiModelNotFoundError');
      } on HFApiModelNotFoundError catch (e) {
        expect(e.message, error404);
      }
    });

    test('model loading', () async {
      final api = HFApi.withClient(
        model: 'gpt2',
        outputType: HFOutputType.string,
        apiToken: 'api_token',
        client: MockClient((request) async => http.Response(error503, 503)),
      );

      try {
        await api.run<String>(input);
        fail('Expected HFApiLoadingError');
      } on HFApiLoadingError catch (e) {
        expect(e.message,
            'Model instruction-tuning-sd/cartoonizer is currently loading');
        expect(e.estimatedTime, 219.25982666015625);
      }
    });

    test('unknown error', () async {
      final api = HFApi.withClient(
        model: 'gpt2',
        outputType: HFOutputType.string,
        apiToken: 'api_token',
        client: MockClient((request) async => http.Response(error400, 400)),
      );

      try {
        await api.run<String>(input);
        fail('Expected HFApiUnknownError');
      } on HFApiUnknownError catch (e) {
        expect(e.statusCode, 400);
        expect(e.message, error400);
      }
    });
  });
}

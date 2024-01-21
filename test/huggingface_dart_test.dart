import 'package:http/http.dart' as http;
import 'package:http/testing.dart' show MockClient;
import 'package:huggingface_dart/huggingface_dart.dart';
import 'package:test/test.dart';

void main() {
  test('gpt2', () async {
    const input = 'Hello, my name is';
    const output = 'Hello, my name is John';

    final api = HuggingFace.withClient(
      model: 'gpt2',
      outputType: HFOutputType.string,
      apiToken: 'api_token',
      client: MockClient((request) {
        expect(request.url.host, 'api-inference.huggingface.co');
        expect(request.url.path, '/models/gpt2');
        expect(request.headers['Authorization'], 'Bearer api_token');
        expect(request.body, input);
        return Future.value(http.Response(output, 200));
      }),
    );

    final result = await api.run<String>(input);
    expect(result, output);
  });
}

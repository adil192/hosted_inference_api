import 'package:hosted_inference_api/hosted_inference_api.dart';

Future<void> main() async {
  final api = HFApi(
    model: 'gpt2',
    outputType: HFOutputType.string,
    apiToken: 'hf_xxxxx',
  );
  final result = await api
      .run<String>('Can you please let us know more details about your ');
  print(result);
}

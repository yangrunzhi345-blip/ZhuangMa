import 'llm_response.dart';

abstract interface class LlmProvider {
  Future<LlmResponse> generate({
    required String instruction,
    required String objective,
  });
}

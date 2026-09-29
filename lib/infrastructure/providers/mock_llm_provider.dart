import '../../domain/llm/llm_provider.dart';
import '../../domain/llm/llm_response.dart';

class MockLlmProvider implements LlmProvider {
  const MockLlmProvider();

  @override
  Future<LlmResponse> generate({
    required String instruction,
    required String objective,
  }) async => LlmResponse(
    '$instruction\nObjective: $objective',
    metadata: const {'provider': 'mock'},
  );
}

class LlmResponse {
  final String text;
  final Map<String, dynamic> metadata;
  const LlmResponse(this.text, {this.metadata = const {}});
}

abstract interface class LlmProvider {
  Future<LlmResponse> generate({
    required String instruction,
    required String objective,
  });
}

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

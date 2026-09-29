class LlmResponse {
  final String text;
  final Map<String, dynamic> metadata;

  const LlmResponse(this.text, {this.metadata = const {}});
}

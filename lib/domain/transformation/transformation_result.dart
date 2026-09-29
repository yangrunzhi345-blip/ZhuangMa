class TransformationResult {
  final String originalText, transformedText, transformerId;
  final Map<String, dynamic> parameters, metadata;
  final DateTime createdAt;
  final double estimatedRecoverability;

  TransformationResult({
    required this.originalText,
    required this.transformedText,
    required this.transformerId,
    this.parameters = const {},
    this.metadata = const {},
    DateTime? createdAt,
    this.estimatedRecoverability = 1,
  }) : createdAt = createdAt ?? DateTime.now();
}

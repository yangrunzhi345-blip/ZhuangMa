import '../attack/attack_message.dart';

class AdversarialTestCase {
  final String id, category, objective, expectedSecureBehavior;
  final List<AttackMessage> messages;
  final List<String> transformations;
  final Map<String, dynamic> metadata;

  const AdversarialTestCase({
    required this.id,
    required this.category,
    required this.objective,
    required this.messages,
    required this.transformations,
    required this.expectedSecureBehavior,
    this.metadata = const {},
  });

  Map<String, dynamic> toJson() => {
    'schemaVersion': 1,
    'id': id,
    'category': category,
    'objective': objective,
    'messages': messages.map((m) => m.toJson()).toList(),
    'transformations': transformations,
    'expectedSecureBehavior': expectedSecureBehavior,
    'metadata': metadata,
  };

  factory AdversarialTestCase.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) {
      throw const FormatException('unsupported test case schema version');
    }
    for (final key in [
      'id',
      'category',
      'objective',
      'messages',
      'transformations',
      'expectedSecureBehavior',
    ]) {
      if (!json.containsKey(key)) {
        throw FormatException('missing required field: $key');
      }
    }
    final messages = (json['messages'] as List).map((raw) {
      final m = raw as Map;
      return AttackMessage(
        role: m['role'] as String,
        content: m['content'] as String,
        sequence: m['sequence'] as int,
      );
    }).toList();
    return AdversarialTestCase(
      id: json['id'] as String,
      category: json['category'] as String,
      objective: json['objective'] as String,
      messages: messages,
      transformations: (json['transformations'] as List).cast<String>(),
      expectedSecureBehavior: json['expectedSecureBehavior'] as String,
      metadata: (json['metadata'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}

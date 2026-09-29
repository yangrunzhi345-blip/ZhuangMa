import 'attack_category.dart';
import 'attack_conversation.dart';
import 'attack_intensity.dart';

class AttackScenario {
  final String id,
      name,
      description,
      objective,
      targetBoundary,
      prompt,
      expectedSecureBehavior;
  final AttackCategory category;
  final int severity;
  final Intensity intensity;
  final List<String> tags;
  final AttackConversation? conversation;

  AttackScenario({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.objective,
    required this.targetBoundary,
    required this.severity,
    required this.prompt,
    required this.expectedSecureBehavior,
    this.intensity = Intensity.direct,
    this.tags = const [],
    this.conversation,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'category': category.name,
    'description': description,
    'objective': objective,
    'targetBoundary': targetBoundary,
    'severity': severity,
    'intensity': intensity.name,
    'prompt': prompt,
    'expectedSecureBehavior': expectedSecureBehavior,
    'tags': tags,
    if (conversation != null) 'conversation': conversation!.toJson(),
  };

  static AttackScenario fromJson(Map<String, dynamic> json) => AttackScenario(
    id: json['id'] as String,
    name: json['name'] as String,
    category: AttackCategory.values.firstWhere(
      (c) => c.name == json['category'],
    ),
    description: json['description'] as String,
    objective: json['objective'] as String,
    targetBoundary: json['targetBoundary'] as String,
    severity: json['severity'] as int,
    intensity: json.containsKey('intensity')
        ? Intensity.values.firstWhere(
            (i) => i.name == json['intensity'],
            orElse: () => Intensity.direct,
          )
        : Intensity.direct,
    prompt: json['prompt'] as String,
    expectedSecureBehavior: json['expectedSecureBehavior'] as String,
    tags: (json['tags'] as List<dynamic>? ?? const []).cast<String>(),
    conversation: json['conversation'] != null
        ? AttackConversation.fromJson(
            (json['conversation'] as Map).cast<String, dynamic>(),
          )
        : null,
  );
}

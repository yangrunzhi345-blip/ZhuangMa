import 'attack_message.dart';

class AttackConversation {
  final String id;
  final List<AttackMessage> messages;

  const AttackConversation({required this.id, required this.messages});

  Map<String, dynamic> toJson() => {
    'id': id,
    'messages': messages.map((m) => m.toJson()).toList(),
  };

  factory AttackConversation.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! String || json['messages'] is! List) {
      throw const FormatException('invalid conversation');
    }
    final messages = (json['messages'] as List).map((raw) {
      if (raw is! Map) {
        throw const FormatException('invalid conversation message');
      }
      return AttackMessage.fromJson(raw.cast<String, dynamic>());
    }).toList();
    return AttackConversation(
      id: json['id'] as String,
      messages: List.unmodifiable(messages),
    );
  }
}

class AttackMessage {
  final String role, content;
  final int sequence;

  const AttackMessage({
    required this.role,
    required this.content,
    required this.sequence,
  });

  Map<String, dynamic> toJson() => {
    'role': role,
    'content': content,
    'sequence': sequence,
  };

  factory AttackMessage.fromJson(Map<String, dynamic> json) {
    if (json['role'] is! String ||
        json['content'] is! String ||
        json['sequence'] is! int) {
      throw const FormatException('invalid conversation message');
    }
    return AttackMessage(
      role: json['role'] as String,
      content: json['content'] as String,
      sequence: json['sequence'] as int,
    );
  }
}

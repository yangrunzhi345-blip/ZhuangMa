abstract class TextTransformer {
  String get id;
  String get displayName;
  bool get isReversible => true;
  String transform(String input, {Map<String, dynamic> options = const {}});
  String restore(String input, {Map<String, dynamic> options = const {}});
}

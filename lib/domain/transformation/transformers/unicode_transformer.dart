import '../text_transformer.dart';

class UnicodeTransformer extends TextTransformer {
  @override
  String get id => 'unicode_escape';

  @override
  String get displayName => 'Unicode Escape';

  @override
  String transform(String s, {Map<String, dynamic> options = const {}}) =>
      s.runes.map((r) => '\\u${r.toRadixString(16).padLeft(4, '0')}').join();

  @override
  String restore(String s, {Map<String, dynamic> options = const {}}) {
    if (s.isEmpty) return '';
    final matches = RegExp(r'\\u([0-9a-fA-F]{4,6})').allMatches(s).toList();
    if (matches.isEmpty) {
      throw const FormatException('invalid unicode escape payload');
    }
    int lastEnd = 0;
    final values = <int>[];
    for (final m in matches) {
      if (m.start != lastEnd) {
        throw const FormatException(
          'invalid characters in unicode escape payload',
        );
      }
      final value = int.parse(m.group(1)!, radix: 16);
      if (value > 0x10ffff || (value >= 0xd800 && value <= 0xdfff)) {
        throw const FormatException('invalid Unicode scalar value');
      }
      values.add(value);
      lastEnd = m.end;
    }
    if (lastEnd != s.length) {
      throw const FormatException(
        'trailing invalid characters in unicode escape payload',
      );
    }
    return String.fromCharCodes(values);
  }
}

import '../text_transformer.dart';

class CodePointTransformer extends TextTransformer {
  @override
  String get id => 'code_points';

  @override
  String get displayName => 'Code Points';

  @override
  String transform(String s, {Map<String, dynamic> options = const {}}) => s
      .runes
      .map((r) => 'U+${r.toRadixString(16).toUpperCase().padLeft(4, '0')}')
      .join(' ');

  @override
  String restore(String s, {Map<String, dynamic> options = const {}}) {
    if (s.trim().isEmpty) return '';
    final values = s.trim().split(RegExp(r'\s+')).map((token) {
      if (!RegExp(r'^U\+[0-9a-fA-F]{4,6}$').hasMatch(token)) {
        throw const FormatException('invalid code point token');
      }
      final value = int.parse(token.substring(2), radix: 16);
      if (value > 0x10ffff || (value >= 0xd800 && value <= 0xdfff)) {
        throw const FormatException('invalid Unicode scalar value');
      }
      return value;
    }).toList();
    return String.fromCharCodes(values);
  }
}

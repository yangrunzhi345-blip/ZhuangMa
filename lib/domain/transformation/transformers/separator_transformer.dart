import '../text_transformer.dart';

class SeparatorTransformer extends TextTransformer {
  @override
  String get id => 'separator';

  @override
  String get displayName => 'Character Separator';

  String _separator(Map<String, dynamic> options) {
    final separator = options['separator'] as String? ?? ' ';
    if (separator.isEmpty) {
      throw const FormatException('separator must not be empty');
    }
    return separator;
  }

  @override
  String transform(String s, {Map<String, dynamic> options = const {}}) {
    final sep = _separator(options);
    if (s.isEmpty) return '';
    final tokens = <String>[];
    for (final rune in s.runes) {
      final ch = String.fromCharCode(rune);
      if (ch == '\\') {
        tokens.add(r'\\');
      } else if (ch == sep) {
        tokens.add('\\$sep');
      } else {
        tokens.add(ch);
      }
    }
    return tokens.join(sep);
  }

  @override
  String restore(String s, {Map<String, dynamic> options = const {}}) {
    final sep = _separator(options);
    if (s.isEmpty) return '';
    final buffer = StringBuffer();
    int i = 0;
    while (i < s.length) {
      if (s.startsWith(r'\\', i)) {
        buffer.write(r'\');
        i += 2;
      } else if (s.startsWith('\\$sep', i)) {
        buffer.write(sep);
        i += 1 + sep.length;
      } else {
        final unit = s.codeUnitAt(i);
        if (unit >= 0xd800 && unit <= 0xdbff) {
          if (i + 1 >= s.length) {
            throw const FormatException(
              'malformed surrogate pair in separator payload',
            );
          }
          final low = s.codeUnitAt(i + 1);
          if (low < 0xdc00 || low > 0xdfff) {
            throw const FormatException(
              'malformed surrogate pair in separator payload',
            );
          }
          buffer.write(s.substring(i, i + 2));
          i += 2;
        } else if (unit >= 0xdc00 && unit <= 0xdfff) {
          throw const FormatException(
            'unexpected trailing surrogate in separator payload',
          );
        } else {
          buffer.write(s.substring(i, i + 1));
          i += 1;
        }
      }

      if (i < s.length) {
        if (!s.startsWith(sep, i)) {
          throw const FormatException('malformed separator payload');
        }
        i += sep.length;
      }
    }
    return buffer.toString();
  }
}

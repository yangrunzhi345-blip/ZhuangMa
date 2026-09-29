import 'dart:convert';

import '../text_transformer.dart';

class HexTransformer extends TextTransformer {
  @override
  String get id => 'hex';

  @override
  String get displayName => 'Hex';

  @override
  String transform(String s, {Map<String, dynamic> options = const {}}) =>
      utf8.encode(s).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  @override
  String restore(String s, {Map<String, dynamic> options = const {}}) {
    if (s.length.isOdd || !RegExp(r'^[0-9a-fA-F]*$').hasMatch(s)) {
      throw const FormatException(
        'hex payload must contain an even number of hexadecimal digits',
      );
    }
    return utf8.decode(
      List.generate(
        s.length ~/ 2,
        (i) => int.parse(s.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }
}

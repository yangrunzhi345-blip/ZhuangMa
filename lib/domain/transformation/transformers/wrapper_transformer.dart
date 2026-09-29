import 'dart:convert';

import '../text_transformer.dart';

class WrapperTransformer extends TextTransformer {
  @override
  String get id => 'wrapper';

  @override
  String get displayName => 'Structured Wrapper';

  @override
  String transform(String s, {Map<String, dynamic> options = const {}}) =>
      jsonEncode({'type': 'test-payload', 'payload': s});

  @override
  String restore(String s, {Map<String, dynamic> options = const {}}) {
    try {
      final decoded = jsonDecode(s);
      if (decoded is! Map ||
          decoded['type'] != 'test-payload' ||
          decoded['payload'] is! String) {
        throw const FormatException('invalid wrapper payload');
      }
      return decoded['payload'] as String;
    } on FormatException {
      rethrow;
    } on Object catch (e) {
      throw FormatException('invalid wrapper payload: $e');
    }
  }
}

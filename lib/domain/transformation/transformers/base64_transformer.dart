import 'dart:convert';

import '../text_transformer.dart';

class Base64Transformer extends TextTransformer {
  @override
  String get id => 'base64';

  @override
  String get displayName => 'Base64';

  @override
  String transform(String s, {Map<String, dynamic> options = const {}}) =>
      base64Encode(utf8.encode(s));

  @override
  String restore(String s, {Map<String, dynamic> options = const {}}) =>
      utf8.decode(base64Decode(s));
}

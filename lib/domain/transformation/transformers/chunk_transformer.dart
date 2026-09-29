import 'dart:convert';
import 'dart:math';

import '../text_transformer.dart';

class ChunkTransformer extends TextTransformer {
  @override
  String get id => 'chunk';

  @override
  String get displayName => 'Chunk Reordering';

  @override
  String transform(String s, {Map<String, dynamic> options = const {}}) {
    final rawChunks = options['chunks'];
    final n = rawChunks is int
        ? rawChunks
        : (rawChunks == null
              ? 3
              : throw const FormatException(
                  'chunks option must be an integer',
                ));
    if (n < 1) throw const FormatException('chunks must be positive');
    final codePoints = s.runes.toList();
    if (codePoints.isEmpty) return '';
    final size = (codePoints.length / n).ceil();
    return [
      for (var i = 0; i < n; i++)
        if (i * size < codePoints.length)
          '[${i + 1}/$n] ${base64Encode(utf8.encode(String.fromCharCodes(codePoints.sublist(i * size, min(codePoints.length, (i + 1) * size)))))}',
    ].reversed.join('\n');
  }

  @override
  String restore(String s, {Map<String, dynamic> options = const {}}) {
    if (s.isEmpty) return '';
    final lines = s.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return '';
    final m =
        RegExp(
          r'^\[(\d+)\/(\d+)\] (.*)$',
          multiLine: true,
        ).allMatches(s).toList()..sort(
          (x, y) => int.parse(x.group(1)!).compareTo(int.parse(y.group(1)!)),
        );
    if (m.isEmpty || m.length != lines.length) {
      throw const FormatException('invalid chunk payload');
    }
    final total = int.parse(m.first.group(2)!);
    if (m.any((x) => int.parse(x.group(2)!) != total) ||
        m.map((x) => int.parse(x.group(1)!)).toSet().length != m.length) {
      throw const FormatException('inconsistent chunk payload');
    }
    for (var i = 0; i < m.length; i++) {
      if (int.parse(m[i].group(1)!) != i + 1) {
        throw const FormatException('missing or non-contiguous chunk indices');
      }
    }
    try {
      final combinedBytes = <int>[];
      for (final match in m) {
        combinedBytes.addAll(base64Decode(match.group(3)!));
      }
      return utf8.decode(combinedBytes);
    } on Object catch (e) {
      throw FormatException('invalid chunk data: $e');
    }
  }
}

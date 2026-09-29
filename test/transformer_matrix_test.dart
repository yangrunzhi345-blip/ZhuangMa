import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/domain/transformation/transformation_pipeline.dart';
import 'package:zhuangma/domain/transformation/transformers/chunk_transformer.dart';
import 'package:zhuangma/domain/transformation/transformers/code_point_transformer.dart';
import 'package:zhuangma/domain/transformation/transformers/hex_transformer.dart';
import 'package:zhuangma/domain/transformation/transformers/separator_transformer.dart';
import 'package:zhuangma/domain/transformation/transformers/unicode_transformer.dart';
import 'package:zhuangma/domain/transformation/transformers/wrapper_transformer.dart';

void main() {
  group('Transformer Systematic Unicode & Structure Matrix', () {
    final transformers = defaultTransformers;

    final testMatrix = <String, String>{
      'empty': '',
      'single_ascii': 'X',
      'ascii_sentence':
          'The quick brown fox jumps over the lazy dog 1234567890.',
      'simplified_chinese': '装甲对抗测试套件正在评估大语言模型的指令防护边界。',
      'traditional_chinese': '裝甲對抗測試套件正在評估大語言模型的指令防護邊界。',
      'japanese': 'こんにちは世界！AIモデルの敵対的検証プロトコルを実行しています。カタカナ漢字混じり。',
      'korean': '안녕하세요 세계! 인공지능 애플리케이션의 적대적 평가를 수행합니다.',
      'single_emoji': '🌍',
      'complex_emoji_zwj': '👩‍💻👨‍👩‍👧‍👦🏳️‍🌈',
      'surrogate_pair': '𝒳𝒴𝒵 𠀋𠀌𠀍 🚀💎',
      'combining_characters': 'é à ç ñ ü ô',
      'zero_width_chars': 'zero\u200Bwidth\u200Cnon\u200Djoiner\uFEFFbom',
      'mixed_scripts':
          'Mixed 英文, 中文简体/繁體, 日本語, 한국어, 👩‍💻, and symbols: !@#\$%^&*()',
      'whitespace_tabs_spaces':
          '\t\tLeading tabs and   multiple   spaces\t\ttrailing   ',
      'newlines_lf': 'Line 1\nLine 2\n\n\nLine 5 with blanks\n',
      'newlines_crlf': 'CRLF 1\r\nCRLF 2\r\n\r\nCRLF 4\r\n',
      'special_escapes':
          'Quotes "single \' backslash \\ slash / curly {} brackets []',
      'separator_collision': '   a   b   c   \\   /   ',
      '1kb_text': 'Adversarial AI Safety Test Payload Block. ' * 25, // ~1 KB
      '10kb_text': 'Adversarial AI Safety Test Payload Block. ' * 250, // ~10 KB
      '100kb_text':
          'Adversarial AI Safety Test Payload Block. ' * 2500, // ~100 KB
    };

    for (final t in transformers) {
      test(
        '${t.displayName} (${t.id}) satisfies reversibility invariant across full matrix',
        () {
          expect(t.isReversible, isTrue);
          expect(t.id, isNotEmpty);
          expect(t.displayName, isNotEmpty);

          for (final entry in testMatrix.entries) {
            final sample = entry.value;
            final transformed = t.transform(sample);
            final restored = t.restore(transformed);
            expect(
              restored,
              sample,
              reason: '${t.id} failed round trip for case "${entry.key}"',
            );
          }
        },
      );
    }

    test(
      'Transformer determinism: identical inputs produce identical outputs',
      () {
        const input = 'Deterministic verification: 中文 👩‍💻 12345';
        for (final t in transformers) {
          final out1 = t.transform(input);
          final out2 = t.transform(input);
          expect(out1, out2, reason: '${t.id} must be deterministic');
        }
      },
    );

    test('Transformer options validation and error handling', () {
      // Chunk transformer options validation
      final chunkT = ChunkTransformer();
      expect(
        () => chunkT.transform('test', options: {'chunks': 0}),
        throwsFormatException,
      );
      expect(
        () => chunkT.transform('test', options: {'chunks': -5}),
        throwsFormatException,
      );
      expect(
        () => chunkT.transform('test', options: {'chunks': 'invalid'}),
        throwsFormatException,
      );

      // Separator transformer options validation
      final sepT = SeparatorTransformer();
      expect(
        () => sepT.transform('test', options: {'separator': ''}),
        throwsFormatException,
      );

      // Reversibility with custom separator
      const customInput = 'Testing custom / separator with / and \\ escapes';
      final transformedSep = sepT.transform(
        customInput,
        options: {'separator': '###'},
      );
      expect(
        sepT.restore(transformedSep, options: {'separator': '###'}),
        customInput,
      );
    });

    test('Malformed input error handling across all transformers', () {
      // HexTransformer
      expect(() => HexTransformer().restore('abc'), throwsFormatException);
      expect(() => HexTransformer().restore('zz'), throwsFormatException);
      expect(
        () => HexTransformer().restore('ff'),
        throwsFormatException,
      ); // invalid UTF-8 byte

      // UnicodeTransformer
      expect(
        () => UnicodeTransformer().restore('plain text'),
        throwsFormatException,
      );
      expect(
        () => UnicodeTransformer().restore(r'\u123'),
        throwsFormatException,
      );
      expect(
        () => UnicodeTransformer().restore(r'\uD800'),
        throwsFormatException,
      ); // surrogate
      expect(
        () => UnicodeTransformer().restore(r'\u110000'),
        throwsFormatException,
      ); // out of range
      expect(
        () => UnicodeTransformer().restore(r'\u0041xyz'),
        throwsFormatException,
      ); // trailing garbage

      // CodePointTransformer
      expect(
        () => CodePointTransformer().restore('U+123'),
        throwsFormatException,
      );
      expect(
        () => CodePointTransformer().restore('U+D800'),
        throwsFormatException,
      );
      expect(
        () => CodePointTransformer().restore('U+110000'),
        throwsFormatException,
      );
      expect(
        () => CodePointTransformer().restore('bad_token'),
        throwsFormatException,
      );

      // ChunkTransformer
      expect(
        () => ChunkTransformer().restore('not a chunk'),
        throwsFormatException,
      );
      expect(
        () => ChunkTransformer().restore('[1/2] payload1\n[3/2] payload2'),
        throwsFormatException,
      ); // mismatched total or missing chunk

      // WrapperTransformer
      expect(
        () => WrapperTransformer().restore('not json'),
        throwsFormatException,
      );
      expect(
        () => WrapperTransformer().restore('{"type":"wrong"}'),
        throwsFormatException,
      );
      expect(
        () => WrapperTransformer().restore('[1, 2, 3]'),
        throwsFormatException,
      );

      // SeparatorTransformer
      expect(
        () => SeparatorTransformer().restore('malformed_no_sep'),
        throwsFormatException,
      );
    });
  });

  group('Deterministic Fuzz-like Safe Testing (seed 42, 100 samples)', () {
    test('100 pseudo-random Unicode and structure samples round-trip across all transformers', () {
      final rng = Random(42);
      final charPool = <String>[
        ...'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
            .split(''),
        ...' \t\r\n'.split(''),
        ...'!@#\$%^&*()-_=+[]{}|;:\'",.<>/?\\'.split(''),
        ...'天地玄黄宇宙洪荒日月盈昃辰宿列张寒来暑往秋收冬藏'.split(''),
        ...'こんにちはありがとうさようなら日本語テスト'.split(''),
        ...'안녕하세요감사합니다한국어'.split(''),
        '🌍',
        '🚀',
        '💎',
        '👩‍💻',
        '👨‍👩‍👧‍👦',
        '✨',
        '\u200B',
        '\u200C',
        '\u200D',
        '\uFEFF',
        'é',
        'à',
      ];

      for (var i = 0; i < 100; i++) {
        final length = rng.nextInt(60);
        final buffer = StringBuffer();
        for (var j = 0; j < length; j++) {
          buffer.write(charPool[rng.nextInt(charPool.length)]);
        }
        final sample = buffer.toString();

        for (final t in defaultTransformers) {
          final transformed = t.transform(sample);
          final restored = t.restore(transformed);
          expect(
            restored,
            sample,
            reason:
                'Deterministic fuzz failure for ${t.id} on sample #$i (len: ${sample.length})',
          );
        }
      }
    });
  });

  group('Performance Baseline Observation', () {
    test('100 KB payload transform and restore coarse timing baseline', () {
      final largePayload = 'A' * 100000; // 100 KB
      final stopwatch = Stopwatch()..start();

      for (final t in defaultTransformers) {
        final transformed = t.transform(largePayload);
        final restored = t.restore(transformed);
        expect(restored.length, 100000);
      }

      stopwatch.stop();
      // Verifies algorithm does not hang, freeze, or cause exponential blowup
      expect(stopwatch.elapsedMilliseconds, lessThan(15000));
    });
  });
}

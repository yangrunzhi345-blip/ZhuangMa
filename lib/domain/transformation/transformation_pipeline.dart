import '../../core/errors/transformer_exception.dart';
import '../protocol/recovery_protocol.dart';
import 'reversibility.dart';
import 'text_transformer.dart';
import 'transformers/base64_transformer.dart';
import 'transformers/chunk_transformer.dart';
import 'transformers/code_point_transformer.dart';
import 'transformers/hex_transformer.dart';
import 'transformers/separator_transformer.dart';
import 'transformers/unicode_transformer.dart';
import 'transformers/wrapper_transformer.dart';

final List<TextTransformer> defaultTransformers = [
  UnicodeTransformer(),
  CodePointTransformer(),
  Base64Transformer(),
  HexTransformer(),
  SeparatorTransformer(),
  ChunkTransformer(),
  WrapperTransformer(),
];

class TransformationPipeline {
  final List<TextTransformer> steps;
  TransformationPipeline(this.steps);

  Reversibility get reversibility {
    if (steps.isEmpty) return Reversibility.fullyReversible;
    final reversibleCount = steps.where((s) => s.isReversible).length;
    if (reversibleCount == steps.length) return Reversibility.fullyReversible;
    if (reversibleCount == 0) return Reversibility.notReversible;
    return Reversibility.partiallyReversible;
  }

  bool get isFullyReversible => reversibility == Reversibility.fullyReversible;

  String transform(String s) => steps.fold(s, (v, t) => t.transform(v));

  String reverse(String s) {
    if (!isFullyReversible) {
      throw const TransformerException(
        'Pipeline contains non-reversible steps',
      );
    }
    return steps.reversed.fold(s, (v, t) => t.restore(v));
  }

  RecoveryProtocol recoveryProtocol(String original) =>
      RecoveryProtocol.create(steps.map((step) => step.id).toList(), original);

  Map<String, dynamic> toJson() => {
    'version': 1,
    'steps': steps.map((s) => s.id).toList(),
  };

  static TransformationPipeline fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) {
      throw const FormatException('unsupported pipeline version');
    }
    final rawSteps = json['steps'];
    if (rawSteps is! List) {
      throw const FormatException('pipeline steps are required');
    }
    final known = <String, TextTransformer>{
      for (final t in defaultTransformers) t.id: t,
    };
    final seenStepIds = <String>{};
    final result = <TextTransformer>[];
    for (final raw in rawSteps) {
      if (raw is String) {
        final t = known[raw];
        if (t == null) throw FormatException('unknown transformer: $raw');
        result.add(t);
      } else if (raw is Map) {
        final stepId = raw['stepId'];
        if (stepId is String) {
          if (!seenStepIds.add(stepId)) {
            throw FormatException('duplicate step ID: $stepId');
          }
        }
        final transformerId = raw['transformerId'] ?? raw['id'];
        if (transformerId is! String || !known.containsKey(transformerId)) {
          throw FormatException('unknown transformer: $transformerId');
        }
        result.add(known[transformerId]!);
      } else {
        throw const FormatException('invalid step representation in pipeline');
      }
    }
    return TransformationPipeline(result);
  }
}

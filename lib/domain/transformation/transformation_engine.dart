import 'reversibility.dart';
import 'text_transformer.dart';
import 'transformation_pipeline.dart';
import 'transformation_result.dart';

class TransformationEngine {
  final List<TextTransformer> availableTransformers;

  TransformationEngine({List<TextTransformer>? transformers})
    : availableTransformers = List.unmodifiable(
        transformers ?? defaultTransformers,
      );

  TextTransformer? findTransformer(String id) {
    for (final t in availableTransformers) {
      if (t.id == id) return t;
    }
    return null;
  }

  TransformationPipeline createPipeline(List<String> transformerIds) {
    final steps = <TextTransformer>[];
    for (final id in transformerIds) {
      final t = findTransformer(id);
      if (t == null) {
        throw FormatException('Unknown transformer id: $id');
      }
      steps.add(t);
    }
    return TransformationPipeline(steps);
  }

  String transform(String input, TransformationPipeline pipeline) =>
      pipeline.transform(input);

  String restore(String input, TransformationPipeline pipeline) =>
      pipeline.reverse(input);

  TransformationResult execute(
    String input,
    TransformationPipeline pipeline, {
    Map<String, dynamic> metadata = const {},
  }) {
    final transformed = pipeline.transform(input);
    final recoverability = switch (pipeline.reversibility) {
      Reversibility.fullyReversible => 1.0,
      Reversibility.partiallyReversible => 0.5,
      Reversibility.notReversible => 0.0,
    };

    return TransformationResult(
      originalText: input,
      transformedText: transformed,
      transformerId: pipeline.steps.map((s) => s.id).join('->'),
      parameters: pipeline.toJson(),
      metadata: metadata,
      estimatedRecoverability: recoverability,
    );
  }
}

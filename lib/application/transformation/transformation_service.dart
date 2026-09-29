import '../../domain/transformation/reversibility.dart';
import '../../domain/transformation/text_transformer.dart';
import '../../domain/transformation/transformation_engine.dart';
import '../../domain/transformation/transformation_pipeline.dart';
import '../../domain/transformation/transformation_result.dart';

class TransformationService {
  final TransformationEngine _engine;

  TransformationService({TransformationEngine? engine})
    : _engine = engine ?? TransformationEngine();

  List<TextTransformer> get availableTransformers =>
      _engine.availableTransformers;

  TextTransformer? findTransformer(String id) => _engine.findTransformer(id);

  TransformationPipeline createPipeline(List<TextTransformer> steps) =>
      TransformationPipeline(steps);

  String transform(String input, TransformationPipeline pipeline) =>
      _engine.transform(input, pipeline);

  String restore(String input, TransformationPipeline pipeline) =>
      _engine.restore(input, pipeline);

  TransformationResult execute(
    String input,
    TransformationPipeline pipeline, {
    Map<String, dynamic> metadata = const {},
  }) => _engine.execute(input, pipeline, metadata: metadata);

  Reversibility checkReversibility(TransformationPipeline pipeline) =>
      pipeline.reversibility;
}

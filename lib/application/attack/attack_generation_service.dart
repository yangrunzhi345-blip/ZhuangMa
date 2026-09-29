import '../../domain/attack/attack_category.dart';
import '../../domain/attack/attack_generator.dart';
import '../../domain/attack/attack_intensity.dart';
import '../../domain/attack/attack_scenario.dart';

class AttackGenerationService {
  final AttackGenerator _generator;

  AttackGenerationService({AttackGenerator? generator})
    : _generator = generator ?? AttackGenerator();

  AttackScenario generate({
    required AttackCategory category,
    required String objective,
    String? targetBoundary,
    Intensity intensity = Intensity.direct,
  }) {
    return _generator.generate(
      category,
      objective,
      targetBoundary: targetBoundary,
      intensity: intensity,
    );
  }
}

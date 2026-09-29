import '../attack/attack_category.dart';
import '../attack/attack_scenario.dart';

abstract interface class ScenarioRepository {
  Future<void> save(AttackScenario scenario);
  Future<AttackScenario?> getById(String id);
  Future<List<AttackScenario>> all();
  Future<List<AttackScenario>> search(String query);
  Future<List<AttackScenario>> filter({
    AttackCategory? category,
    int? minSeverity,
    String? tag,
  });
  Future<int> count();
  Future<void> delete(String id);
  Future<void> close();
}

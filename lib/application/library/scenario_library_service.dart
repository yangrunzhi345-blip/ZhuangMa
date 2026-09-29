import '../../domain/attack/attack_category.dart';
import '../../domain/attack/attack_scenario.dart';
import '../../domain/repository/scenario_repository.dart';

class ScenarioLibraryService {
  final ScenarioRepository _repository;

  const ScenarioLibraryService(this._repository);

  Future<List<AttackScenario>> getScenarios() => _repository.all();

  Future<AttackScenario?> getScenarioById(String id) => _repository.getById(id);

  Future<void> saveScenario(AttackScenario scenario) =>
      _repository.save(scenario);

  Future<void> deleteScenario(String id) => _repository.delete(id);

  Future<List<AttackScenario>> searchScenarios(String query) =>
      _repository.search(query);

  Future<List<AttackScenario>> filterScenarios({
    AttackCategory? category,
    int? minSeverity,
    String? tag,
  }) => _repository.filter(
    category: category,
    minSeverity: minSeverity,
    tag: tag,
  );

  Future<int> count() => _repository.count();

  Future<void> dispose() => _repository.close();
}

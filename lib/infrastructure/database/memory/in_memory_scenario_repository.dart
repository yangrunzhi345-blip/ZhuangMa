import '../../../domain/attack/attack_category.dart';
import '../../../domain/attack/attack_scenario.dart';
import '../../../domain/repository/scenario_repository.dart';

class InMemoryScenarioRepository implements ScenarioRepository {
  final List<AttackScenario> _items = [];

  List<AttackScenario> getAll() => List.unmodifiable(_items);

  @override
  Future<void> save(AttackScenario scenario) async {
    _items.removeWhere((x) => x.id == scenario.id);
    _items.add(scenario);
  }

  @override
  Future<AttackScenario?> getById(String id) async {
    final matches = _items.where((x) => x.id == id);
    return matches.isEmpty ? null : matches.first;
  }

  @override
  Future<List<AttackScenario>> all() async => List.unmodifiable(_items);

  @override
  Future<List<AttackScenario>> search(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return all();
    return _items.where((s) {
      final combined =
          '${s.name} ${s.objective} ${s.prompt} ${s.targetBoundary} ${s.tags.join(' ')}'
              .toLowerCase();
      return combined.contains(clean);
    }).toList();
  }

  @override
  Future<List<AttackScenario>> filter({
    AttackCategory? category,
    int? minSeverity,
    String? tag,
  }) async {
    return _items.where((s) {
      if (category != null && s.category != category) return false;
      if (minSeverity != null && s.severity < minSeverity) return false;
      if (tag != null && !s.tags.contains(tag)) return false;
      return true;
    }).toList();
  }

  @override
  Future<int> count() async => _items.length;

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((x) => x.id == id);
  }

  @override
  Future<void> close() async {}
}

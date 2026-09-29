import '../../domain/attack/attack_scenario.dart';
import '../../domain/protocol/adversarial_test_case.dart';
import 'scenario_exporter.dart';

class ExportService {
  final ScenarioExporter exporter;
  const ExportService({this.exporter = const ScenarioExporter()});

  String text(AttackScenario scenario) => exporter.plain(scenario);
  String json(AttackScenario scenario) => exporter.json(scenario);
  String markdown(AttackScenario scenario) => exporter.markdown(scenario);
  String testCaseJson(AdversarialTestCase testCase) =>
      exporter.testCaseJson(testCase);
}

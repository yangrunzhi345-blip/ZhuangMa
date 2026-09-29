import '../main.dart';

class ExportService {
  const ExportService();
  String text(AttackScenario scenario) => ScenarioExporter().plain(scenario);
  String json(AttackScenario scenario) => ScenarioExporter().json(scenario);
  String markdown(AttackScenario scenario) =>
      ScenarioExporter().markdown(scenario);
  String testCaseJson(AdversarialTestCase testCase) =>
      ScenarioExporter().testCaseJson(testCase);
}

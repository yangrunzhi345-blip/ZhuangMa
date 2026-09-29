import 'dart:convert';

import '../../domain/attack/attack_scenario.dart';
import '../../domain/protocol/adversarial_test_case.dart';

class ScenarioExporter {
  const ScenarioExporter();

  String json(AttackScenario s, {List<String> transformations = const []}) =>
      const JsonEncoder.withIndent('  ').convert({
        'schemaVersion': 1,
        'scenario': s.toJson(),
        'transformations': transformations,
      });

  String markdown(AttackScenario s) =>
      '# ${s.name}\n\n**Category:** ${s.category.name}\n\n**Objective:** ${s.objective}\n\n## Prompt\n\n${s.prompt}\n\n## Expected secure behavior\n\n${s.expectedSecureBehavior}\n';

  String plain(AttackScenario s) =>
      '${s.name}\n${s.prompt}\nExpected: ${s.expectedSecureBehavior}';

  String testCaseJson(AdversarialTestCase testCase) =>
      const JsonEncoder.withIndent('  ').convert(testCase.toJson());
}

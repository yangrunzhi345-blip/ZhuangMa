import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/main.dart';
import 'package:zhuangma/infrastructure/sqlite_scenario_repository.dart';
import 'package:zhuangma/application/file_export_service.dart';
import 'package:zhuangma/presentation/app_strings.dart';
import 'package:flutter/widgets.dart';

void main() {
  test('localized copy provides English fallback and zh-Hans', () {
    expect(
      AppStrings(const Locale('en')).homeDescription,
      contains('adversarial'),
    );
    expect(
      AppStrings(const Locale('zh', 'Hans')).homeDescription,
      contains('对抗测试'),
    );
  });
  test('scenario JSON round trip and exports', () async {
    final scenario = AttackGenerator().generate(
      AttackCategory.encodedInjection,
      'Test encoded instructions',
    );
    final decoded = AttackScenario.fromJson(scenario.toJson());
    expect(decoded.prompt, scenario.prompt);
    final exporter = ScenarioExporter();
    expect(exporter.json(scenario), contains('schemaVersion'));
    expect(exporter.markdown(scenario), contains('# '));
    expect(exporter.plain(scenario), contains(scenario.prompt));
    final conversation = AttackConversation(
      id: scenario.id,
      messages: [
        AttackMessage(role: 'user', content: scenario.prompt, sequence: 1),
      ],
    );
    final testCase = AdversarialTestCase(
      id: scenario.id,
      category: scenario.category.name,
      objective: scenario.objective,
      messages: conversation.messages,
      transformations: const ['base64'],
      expectedSecureBehavior: scenario.expectedSecureBehavior,
    );
    expect(conversation.toJson()['messages'], hasLength(1));
    expect(testCase.toJson()['schemaVersion'], 1);
    final file = await FileExportService().writeJson(
      scenario,
      '${Directory.systemTemp.path}/zhuangma_export_test.json',
    );
    expect(await file.readAsString(), contains('schemaVersion'));
    await file.delete();
  });

  test('sqlite repository saves and reads scenarios', () async {
    final file = File('${Directory.systemTemp.path}/zhuangma_test.db');
    if (file.existsSync()) file.deleteSync();
    final repository = await SqliteScenarioRepository.open(file.path);
    final scenario = AttackGenerator().generate(
      AttackCategory.roleConfusion,
      'Test role boundary',
    );
    await repository.save(scenario);
    final rows = await repository.all();
    expect(rows.single.id, scenario.id);
    await repository.delete(scenario.id);
    expect(await repository.all(), isEmpty);
    await repository.close();
    if (file.existsSync()) file.deleteSync();
  });
}

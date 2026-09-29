import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/main.dart';
import 'package:zhuangma/infrastructure/sqlite_scenario_repository.dart';

void main() {
  test('scenario JSON round trip and exports', () {
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

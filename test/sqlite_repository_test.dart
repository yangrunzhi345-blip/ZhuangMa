import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/main.dart';
import 'package:zhuangma/infrastructure/sqlite_scenario_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('zhuangma_sqlite_test_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('SQLite integration: CRUD, count, search, and filter', () async {
    final dbPath = '${tempDir.path}/test_crud.db';
    final repo = await SqliteScenarioRepository.open(dbPath);

    expect(await repo.count(), 0);
    expect(await repo.all(), isEmpty);

    // Create 3 scenarios
    final s1 = AttackGenerator().generate(
      AttackCategory.directPromptInjection,
      'Bypass system instructions',
      targetBoundary: 'system_boundary',
      intensity: Intensity.direct,
    );
    final s2 = AttackGenerator().generate(
      AttackCategory.toolAuthority,
      'Execute unauthorized tool',
      targetBoundary: 'agent_tool_boundary',
      intensity: Intensity.multiTurn,
    );
    final s3 = AttackGenerator().generate(
      AttackCategory.contextPoisoning,
      'Poison context memory',
      targetBoundary: 'memory_boundary',
      intensity: Intensity.composite,
    );

    await repo.save(s1);
    await repo.save(s2);
    await repo.save(s3);

    expect(await repo.count(), 3);

    // Read by ID
    final fetchedS1 = await repo.getById(s1.id);
    expect(fetchedS1, isNotNull);
    expect(fetchedS1!.name, s1.name);
    expect(fetchedS1.objective, s1.objective);
    expect(fetchedS1.category, s1.category);
    expect(fetchedS1.severity, s1.severity);
    expect(fetchedS1.intensity, s1.intensity);

    // Multi-turn conversation preserved in SQLite
    final fetchedS2 = await repo.getById(s2.id);
    expect(fetchedS2, isNotNull);
    expect(fetchedS2!.conversation, isNotNull);
    expect(fetchedS2.conversation!.messages, hasLength(3));
    expect(fetchedS2.conversation!.messages[0].role, 'user');
    expect(fetchedS2.conversation!.messages[1].role, 'assistant');

    // Update scenario
    final updatedS1 = AttackScenario(
      id: s1.id,
      name: 'Updated Direct Injection',
      category: s1.category,
      description: s1.description,
      objective: 'Updated objective',
      targetBoundary: s1.targetBoundary,
      severity: 5,
      intensity: s1.intensity,
      prompt: s1.prompt,
      expectedSecureBehavior: s1.expectedSecureBehavior,
      tags: ['updated', 'security'],
    );
    await repo.save(updatedS1);

    expect(await repo.count(), 3);
    final reFetchedS1 = await repo.getById(s1.id);
    expect(reFetchedS1!.name, 'Updated Direct Injection');
    expect(reFetchedS1.objective, 'Updated objective');
    expect(reFetchedS1.tags, contains('updated'));

    // Search
    final searchResult = await repo.search('unauthorized');
    expect(searchResult.map((s) => s.id), contains(s2.id));
    expect(searchResult.map((s) => s.id), isNot(contains(s3.id)));

    // Filter by category
    final filterCat = await repo.filter(
      category: AttackCategory.contextPoisoning,
    );
    expect(filterCat, hasLength(1));
    expect(filterCat.first.id, s3.id);

    // Filter by minSeverity
    final filterSev = await repo.filter(minSeverity: 4);
    expect(filterSev.map((s) => s.id), contains(s1.id)); // updated to 5
    expect(filterSev.map((s) => s.id), contains(s3.id)); // composite is 5

    // Delete
    await repo.delete(s2.id);
    expect(await repo.count(), 2);
    expect(await repo.getById(s2.id), isNull);

    await repo.close();
  });

  test(
    'SQLite reopen test: persistence across distinct database instances',
    () async {
      final dbPath = '${tempDir.path}/test_reopen.db';

      // Instance 1: Create and write scenario
      final repo1 = await SqliteScenarioRepository.open(dbPath);
      final scenario = AttackGenerator().generate(
        AttackCategory.encodedInjection,
        'Test base64 boundary',
        intensity: Intensity.obfuscated,
      );
      await repo1.save(scenario);
      expect(await repo1.count(), 1);
      await repo1.close();

      // Instance 2: Reopen from disk in fresh instance
      final repo2 = await SqliteScenarioRepository.open(dbPath);
      expect(await repo2.count(), 1);
      final loaded = await repo2.getById(scenario.id);
      expect(loaded, isNotNull);
      expect(loaded!.id, scenario.id);
      expect(loaded.name, scenario.name);
      expect(loaded.category, scenario.category);
      expect(loaded.objective, scenario.objective);
      expect(loaded.prompt, scenario.prompt);
      expect(loaded.expectedSecureBehavior, scenario.expectedSecureBehavior);
      expect(loaded.tags, scenario.tags);
      expect(loaded.intensity, scenario.intensity);
      await repo2.close();
    },
  );

  test(
    'SQLite data consistency: Unicode, special characters, and long text',
    () async {
      final dbPath = '${tempDir.path}/test_consistency.db';
      final repo = await SqliteScenarioRepository.open(dbPath);

      final longText = 'Adversarial payload verification. ' * 500; // ~17 KB
      final unicodeScenario = AttackScenario(
        id: 'sc_unicode_test',
        name: '测试 Unicode 对抗场景 🌍 👩‍💻\u200b\r\n',
        category: AttackCategory.instructionPriorityConflict,
        description: '日本語と한국어 and 繁體中文 test description',
        objective:
            'Verify full Unicode round trip in SQLite: 👩‍💻✨ é\u0301\t\n',
        targetBoundary:
            'Boundary: <system/dev/user> "quotes" \'single\' & escapes',
        severity: 4,
        intensity: Intensity.composite,
        prompt: longText,
        expectedSecureBehavior:
            'Strict priority adherence under heavy payload: 🔒',
        tags: ['unicode', '中文', 'long-text', '👩‍💻'],
        conversation: AttackConversation(
          id: 'conv_long',
          messages: [
            AttackMessage(
              role: 'user',
              content: 'Turn 1 with Unicode 🌍',
              sequence: 1,
            ),
            AttackMessage(
              role: 'assistant',
              content: 'Turn 2 response: 🛡️',
              sequence: 2,
            ),
            AttackMessage(role: 'user', content: longText, sequence: 3),
          ],
        ),
      );

      await repo.save(unicodeScenario);
      final readBack = await repo.getById('sc_unicode_test');
      expect(readBack, isNotNull);
      expect(readBack!.name, unicodeScenario.name);
      expect(readBack.description, unicodeScenario.description);
      expect(readBack.objective, unicodeScenario.objective);
      expect(readBack.targetBoundary, unicodeScenario.targetBoundary);
      expect(readBack.prompt, unicodeScenario.prompt);
      expect(
        readBack.expectedSecureBehavior,
        unicodeScenario.expectedSecureBehavior,
      );
      expect(readBack.tags, unicodeScenario.tags);
      expect(readBack.conversation!.messages, hasLength(3));
      expect(readBack.conversation!.messages[2].content, longText);

      await repo.close();
    },
  );

  test('SQLite malformed record resilience: skips invalid records and logs diagnostics', () async {
    final dbPath = '${tempDir.path}/test_malformed.db';
    final repo = await SqliteScenarioRepository.open(dbPath);

    final validScenario = AttackGenerator().generate(
      AttackCategory.roleConfusion,
      'Valid scenario before corruption',
    );
    await repo.save(validScenario);

    // Insert corrupt rows directly into SQLite
    // 1. Malformed JSON
    await repo.database.rawInsert(
      'INSERT INTO attack_scenarios (id, payload, created_at, schema_version) VALUES (?, ?, ?, ?)',
      [
        'corrupt_json',
        '{not a valid json object',
        DateTime.now().millisecondsSinceEpoch,
        1,
      ],
    );

    // 2. JSON missing required fields
    await repo.database.rawInsert(
      'INSERT INTO attack_scenarios (id, payload, created_at, schema_version) VALUES (?, ?, ?, ?)',
      [
        'missing_fields',
        '{"id": "missing_fields"}',
        DateTime.now().millisecondsSinceEpoch,
        1,
      ],
    );

    // 3. Unknown enum in category
    await repo.database.rawInsert(
      'INSERT INTO attack_scenarios (id, payload, created_at, schema_version) VALUES (?, ?, ?, ?)',
      [
        'unknown_enum',
        '{"id": "unknown_enum", "name": "bad", "category": "nonExistentCategory", "description": "", "objective": "", "targetBoundary": "", "severity": 1, "prompt": "", "expectedSecureBehavior": ""}',
        DateTime.now().millisecondsSinceEpoch,
        1,
      ],
    );

    // Reading all scenarios should NOT throw, but skip corrupted entries and record diagnostics
    final loaded = await repo.all();
    expect(loaded, hasLength(1));
    expect(loaded.first.id, validScenario.id);
    expect(repo.diagnostics, hasLength(greaterThanOrEqualTo(3)));

    // Reading individual corrupt record returns null
    expect(await repo.getById('corrupt_json'), isNull);

    await repo.close();
  });

  test('SQLite concurrency and operation sequence safety', () async {
    final dbPath = '${tempDir.path}/test_concurrency.db';
    final repo = await SqliteScenarioRepository.open(dbPath);

    final s1 = AttackGenerator().generate(
      AttackCategory.directPromptInjection,
      'Target 1',
    );
    final s2 = AttackGenerator().generate(
      AttackCategory.roleConfusion,
      'Target 2',
    );

    // Consecutive parallel saves
    await Future.wait([repo.save(s1), repo.save(s2)]);
    expect(await repo.count(), 2);

    // Save + read in flight
    final s3 = AttackGenerator().generate(
      AttackCategory.toolAuthority,
      'Target 3',
    );
    await Future.wait([repo.save(s3), repo.all()]);
    expect(await repo.count(), 3);

    // Update + search
    await Future.wait([
      repo.save(
        AttackScenario(
          id: s1.id,
          name: 'Concurrent Update',
          category: s1.category,
          description: s1.description,
          objective: 'Concurrent objective',
          targetBoundary: s1.targetBoundary,
          severity: 2,
          prompt: s1.prompt,
          expectedSecureBehavior: s1.expectedSecureBehavior,
        ),
      ),
      repo.search('Concurrent'),
    ]);

    final updated = await repo.getById(s1.id);
    expect(updated!.name, 'Concurrent Update');

    // Operations after close should throw ScenarioRepositoryException
    await repo.close();
    expect(() => repo.all(), throwsA(isA<ScenarioRepositoryException>()));
    expect(() => repo.save(s1), throwsA(isA<ScenarioRepositoryException>()));
    expect(
      () => repo.getById(s1.id),
      throwsA(isA<ScenarioRepositoryException>()),
    );
    expect(() => repo.count(), throwsA(isA<ScenarioRepositoryException>()));
    expect(
      () => repo.delete(s1.id),
      throwsA(isA<ScenarioRepositoryException>()),
    );
  });
}

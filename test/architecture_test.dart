import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/application/attack/attack_generation_service.dart';
import 'package:zhuangma/application/export/export_service.dart';
import 'package:zhuangma/application/library/scenario_library_service.dart';
import 'package:zhuangma/application/transformation/transformation_service.dart';
import 'package:zhuangma/domain/attack/attack_category.dart';
import 'package:zhuangma/domain/attack/attack_generator.dart';
import 'package:zhuangma/domain/repository/scenario_repository.dart';
import 'package:zhuangma/domain/transformation/transformation_engine.dart';
import 'package:zhuangma/domain/transformation/transformation_pipeline.dart';
import 'package:zhuangma/infrastructure/database/memory/in_memory_scenario_repository.dart';
import 'package:zhuangma/infrastructure/database/sqlite/sqlite_scenario_repository.dart';

void main() {
  group('Architecture Boundary and Layer Independence Tests', () {
    test('Domain layer has zero dependencies on Flutter, SQLite, or UI', () {
      final domainDir = Directory('lib/domain');
      expect(domainDir.existsSync(), isTrue);

      final domainFiles = domainDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      expect(domainFiles, isNotEmpty);

      final forbiddenImports = [
        'package:flutter',
        'package:sqflite',
        'package:path_provider',
        'package:file_picker',
        'package:zhuangma/presentation',
        'package:zhuangma/application',
        'package:zhuangma/infrastructure',
        '../presentation',
        '../application',
        '../infrastructure',
        '../../presentation',
        '../../application',
        '../../infrastructure',
      ];

      for (final file in domainFiles) {
        final content = file.readAsStringSync();
        for (final forbidden in forbiddenImports) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason:
                'Domain file ${file.path} must not import "$forbidden" to preserve pure domain isolation.',
          );
        }
      }
    });

    test(
      'Application layer has zero dependencies on Flutter UI or Infrastructure',
      () {
        final appDir = Directory('lib/application');
        expect(appDir.existsSync(), isTrue);

        final appFiles = appDir
            .listSync(recursive: true)
            .whereType<File>()
            .where((f) => f.path.endsWith('.dart'))
            // Allow root forwarders for backward compatibility
            .where(
              (f) =>
                  !f.path.endsWith('lib/application/export_service.dart') &&
                  !f.path.endsWith(
                    'lib/application/file_export_service.dart',
                  ) &&
                  !f.path.endsWith('lib/application/llm_provider.dart'),
            )
            .toList();

        expect(appFiles, isNotEmpty);

        final forbiddenImports = [
          'package:flutter/material.dart',
          'package:flutter/widgets.dart',
          'package:sqflite',
          'package:zhuangma/presentation',
          '../presentation',
          '../../presentation',
        ];

        for (final file in appFiles) {
          final content = file.readAsStringSync();
          for (final forbidden in forbiddenImports) {
            expect(
              content.contains(forbidden),
              isFalse,
              reason:
                  'Application file ${file.path} must not import "$forbidden".',
            );
          }
        }
      },
    );

    test('Infrastructure layer has zero dependencies on Presentation', () {
      final infraDir = Directory('lib/infrastructure');
      expect(infraDir.existsSync(), isTrue);

      final infraFiles = infraDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();

      expect(infraFiles, isNotEmpty);

      final forbiddenImports = [
        'package:flutter/material.dart',
        'package:flutter/widgets.dart',
        'package:zhuangma/presentation',
        '../presentation',
        '../../presentation',
      ];

      for (final file in infraFiles) {
        final content = file.readAsStringSync();
        for (final forbidden in forbiddenImports) {
          expect(
            content.contains(forbidden),
            isFalse,
            reason:
                'Infrastructure file ${file.path} must not import "$forbidden".',
          );
        }
      }
    });

    test('main.dart is converged and contains no business domain logic', () {
      final mainFile = File('lib/main.dart');
      final lines = mainFile.readAsLinesSync();

      // main.dart should be compact and strictly bootstrap
      expect(lines.length, lessThan(40));

      final content = mainFile.readAsStringSync();
      expect(content.contains('class AttackScenario'), isFalse);
      expect(content.contains('class TransformationPipeline'), isFalse);
      expect(content.contains('class RecoveryProtocol'), isFalse);
    });

    test('Repository Authority: Sqlite and InMemory both implement ScenarioRepository', () {
      final inMemory = InMemoryScenarioRepository();
      expect(inMemory, isA<ScenarioRepository>());
      expect(SqliteScenarioRepository.currentSchemaVersion, 1);

      // Type verification: ScenarioLibraryService only depends on ScenarioRepository contract
      final service = ScenarioLibraryService(inMemory);
      expect(service, isNotNull);
    });

    test(
      'Transformer Authority: TransformationEngine governs all 7 transformers',
      () {
        final engine = TransformationEngine();
        expect(engine.availableTransformers.length, 7);

        final ids = engine.availableTransformers.map((t) => t.id).toSet();
        expect(
          ids,
          containsAll([
            'unicode_escape',
            'code_points',
            'base64',
            'hex',
            'separator',
            'chunk',
            'wrapper',
          ]),
        );

        final pipeline = engine.createPipeline(['base64', 'hex']);
        expect(pipeline.steps.length, 2);
        final transformed = engine.transform('Test', pipeline);
        final restored = engine.restore(transformed, pipeline);
        expect(restored, 'Test');
      },
    );

    test('Application Service Authority: attack, transformation, export, and library orchestration', () async {
      final attackService = AttackGenerationService(
        generator: AttackGenerator(),
      );
      final scenario = attackService.generate(
        category: AttackCategory.directPromptInjection,
        objective: 'Architectural test objective',
      );
      expect(scenario.category, AttackCategory.directPromptInjection);

      final transService = TransformationService();
      final pipeline = transService.createPipeline(
        defaultTransformers.take(2).toList(),
      );
      final result = transService.execute('Payload', pipeline);
      expect(result.originalText, 'Payload');

      final exportService = const ExportService();
      final jsonExport = exportService.json(scenario);
      expect(jsonExport, contains('Architectural test objective'));

      final repo = InMemoryScenarioRepository();
      final libService = ScenarioLibraryService(repo);
      await libService.saveScenario(scenario);
      final list = await libService.getScenarios();
      expect(list.length, 1);
      expect(list.first.id, scenario.id);
    });
  });
}

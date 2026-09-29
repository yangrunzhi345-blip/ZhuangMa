import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/application/export_service.dart';
import 'package:zhuangma/application/file_export_service.dart';
import 'package:zhuangma/application/llm_provider.dart';
import 'package:zhuangma/main.dart';
import 'package:zhuangma/presentation/app_strings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Localization copy and fallback', () {
    test('provides English fallback and zh-Hans strings', () {
      final en = AppStrings(const Locale('en'));
      final zh = AppStrings(const Locale('zh', 'Hans'));
      final fallback = AppStrings(const Locale('fr')); // unsupported locale

      expect(en.homeDescription, contains('adversarial'));
      expect(zh.homeDescription, contains('对抗测试'));
      expect(
        fallback.homeDescription,
        en.homeDescription,
      ); // falls back to English

      expect(en.navHome, 'Home');
      expect(zh.navHome, '首页');
      expect(en.createAttack, 'Create Attack Test');
      expect(zh.createAttack, '创建攻击测试');
      expect(en.transformPayload, 'Transform Payload');
      expect(zh.transformPayload, '转换载荷');
      expect(en.reversibilityFully, 'Fully Reversible');
      expect(zh.reversibilityFully, '完全可逆');
      expect(en.savedScenarios(3), '3 saved scenarios');
      expect(zh.savedScenarios(3), '已保存 3 个测试用例');
    });
  });

  group('Transformation Pipeline Combinations & Invariants', () {
    final t1 = UnicodeTransformer();
    final t2 = CodePointTransformer();
    final t3 = Base64Transformer();
    final t4 = HexTransformer();
    final t5 = SeparatorTransformer();
    final t6 = ChunkTransformer();
    final t7 = WrapperTransformer();

    const sample = 'Pipeline verification text: 英文 + 中文 + 👩‍💻 + \t\r\n';

    test('Single step pipeline round trip', () {
      for (final t in [t1, t2, t3, t4, t5, t6, t7]) {
        final pipeline = TransformationPipeline([t]);
        expect(pipeline.isFullyReversible, isTrue);
        final transformed = pipeline.transform(sample);
        final restored = pipeline.reverse(transformed);
        expect(restored, sample, reason: 'Single step ${t.id} failed');
      }
    });

    test('2 steps, 3 steps, 5 steps, and all 7 transformers combination', () {
      final pipelines = <TransformationPipeline>[
        TransformationPipeline([t3, t4]), // Base64 -> Hex
        TransformationPipeline([t5, t7, t3]), // Separator -> Wrapper -> Base64
        TransformationPipeline([t1, t3, t7, t4, t6]), // 5 steps
        TransformationPipeline([
          t1,
          t2,
          t3,
          t4,
          t5,
          t6,
          t7,
        ]), // All 7 transformers
      ];

      for (var i = 0; i < pipelines.length; i++) {
        final p = pipelines[i];
        expect(p.isFullyReversible, isTrue);
        final transformed = p.transform(sample);
        final reversed = p.reverse(transformed);
        expect(reversed, sample, reason: 'Pipeline #$i failed');
      }
    });

    test('Repeating the same transformer in a pipeline', () {
      final pipeline = TransformationPipeline([
        t3, // Base64
        t7, // Wrapper
        t3, // Base64 again
      ]);
      expect(pipeline.isFullyReversible, isTrue);
      final transformed = pipeline.transform(sample);
      final reversed = pipeline.reverse(transformed);
      expect(reversed, sample);
    });

    test('Reordered pipeline executes in strict LIFO reverse order', () {
      // Order A: Base64 -> Hex
      final pipelineA = TransformationPipeline([t3, t4]);
      // Order B: Hex -> Base64
      final pipelineB = TransformationPipeline([t4, t3]);

      final outA = pipelineA.transform(sample);
      final outB = pipelineB.transform(sample);
      expect(
        outA,
        isNot(equals(outB)),
      ); // Different order produces different outputs

      expect(pipelineA.reverse(outA), sample);
      expect(pipelineB.reverse(outB), sample);

      // Feeding outA to reverse of B should fail to restore or throw
      expect(() => pipelineB.reverse(outA), throwsFormatException);
    });

    test('Empty pipeline behaves as identity', () {
      final emptyPipeline = TransformationPipeline([]);
      expect(emptyPipeline.isFullyReversible, isTrue);
      expect(emptyPipeline.reversibility, Reversibility.fullyReversible);
      expect(emptyPipeline.transform(sample), sample);
      expect(emptyPipeline.reverse(sample), sample);

      final json = emptyPipeline.toJson();
      expect(json['version'], 1);
      expect(json['steps'], isEmpty);
      final restored = TransformationPipeline.fromJson(json);
      expect(restored.steps, isEmpty);
    });

    test('Pipeline serialization and deserialization round trip', () {
      final pipeline = TransformationPipeline([t3, t4, t7]);
      final json = pipeline.toJson();
      final decoded = TransformationPipeline.fromJson(json);

      expect(decoded.steps.map((s) => s.id).toList(), [
        'base64',
        'hex',
        'wrapper',
      ]);
      expect(decoded.reverse(decoded.transform(sample)), sample);
    });

    test('Pipeline deserialization handles step IDs and rejects duplicate step IDs', () {
      final validJsonWithStepIds = {
        'version': 1,
        'steps': [
          {'stepId': 'step-1', 'transformerId': 'base64'},
          {'stepId': 'step-2', 'transformerId': 'hex'},
        ],
      };
      final pipeline = TransformationPipeline.fromJson(validJsonWithStepIds);
      expect(pipeline.steps, hasLength(2));

      final duplicateStepIdJson = {
        'version': 1,
        'steps': [
          {'stepId': 'step-1', 'transformerId': 'base64'},
          {'stepId': 'step-1', 'transformerId': 'hex'},
        ],
      };
      expect(
        () => TransformationPipeline.fromJson(duplicateStepIdJson),
        throwsFormatException,
      );
    });

    test('Pipeline configuration error rejection: unsupported version, unknown transformer, invalid format', () {
      expect(
        () => TransformationPipeline.fromJson({
          'version': 2,
          'steps': ['base64'],
        }),
        throwsFormatException,
      );
      expect(
        () => TransformationPipeline.fromJson({
          'version': 1,
          'steps': ['unknown_id'],
        }),
        throwsFormatException,
      );
      expect(
        () => TransformationPipeline.fromJson({
          'version': 1,
          'steps': 'not_a_list',
        }),
        throwsFormatException,
      );
      expect(
        () => TransformationPipeline.fromJson({'version': 1}),
        throwsFormatException,
      );
    });
  });

  group('Recovery Protocol Specification & Round Trip', () {
    const payload = 'Target instruction to recover: 👩‍💻 12345';

    test(
      'Full round-trip: create -> toJson -> fromJson -> recover -> verify hash',
      () {
        final steps = ['base64', 'wrapper'];
        final protocol = RecoveryProtocol.create(steps, payload);

        expect(protocol.steps, steps);
        expect(protocol.expectedOutputHash, isNotEmpty);
        expect(protocol.originalPayload, isNotEmpty);

        final json = protocol.toJson();
        expect(json['version'], 1);
        expect(json['hashAlgorithm'], 'sha256');

        final deserialized = RecoveryProtocol.fromJson(json);
        expect(deserialized.steps, steps);
        expect(deserialized.expectedOutputHash, protocol.expectedOutputHash);
        expect(deserialized.originalPayload, protocol.originalPayload);

        final recovered = deserialized.recover();
        expect(recovered, payload);
      },
    );

    test(
      'Recovery protocol rejects corrupt and tampered inputs predictably',
      () {
        final valid = RecoveryProtocol.create(['base64'], payload);
        final json = valid.toJson();

        // Missing version
        final noVersion = Map<String, dynamic>.from(json)..remove('version');
        expect(
          () => RecoveryProtocol.fromJson(noVersion),
          throwsFormatException,
        );

        // Unsupported version
        final badVersion = Map<String, dynamic>.from(json)..['version'] = 99;
        expect(
          () => RecoveryProtocol.fromJson(badVersion),
          throwsFormatException,
        );

        // Unsupported hash algorithm
        final badHashAlgo = Map<String, dynamic>.from(json)
          ..['hashAlgorithm'] = 'md5';
        expect(
          () => RecoveryProtocol.fromJson(badHashAlgo),
          throwsFormatException,
        );

        // Missing transformation steps
        final noSteps = Map<String, dynamic>.from(json)
          ..remove('transformationSteps');
        expect(() => RecoveryProtocol.fromJson(noSteps), throwsFormatException);

        // Corrupt payload base64
        final corruptPayload = Map<String, dynamic>.from(json)
          ..['originalPayload'] = 'not-valid-base64!';
        expect(
          () => RecoveryProtocol.fromJson(corruptPayload),
          throwsFormatException,
        );

        // Modified payload (hash mismatch)
        final tamperedJson = Map<String, dynamic>.from(json)
          ..['originalPayload'] = RecoveryProtocol.create([
            'base64',
          ], 'tampered payload').originalPayload;
        final tamperedProtocol = RecoveryProtocol.fromJson(tamperedJson);
        expect(() => tamperedProtocol.recover(), throwsFormatException);
      },
    );
  });

  group('AttackScenario & AttackGenerator Semantics and Complexity', () {
    final generator = AttackGenerator();

    test(
      'All 10 categories produce semantically distinct prompts and behaviors',
      () {
        final prompts = <String>{};
        final behaviors = <String>{};

        for (final cat in AttackCategory.values) {
          final scenario = generator.generate(cat, 'Test objective');
          expect(
            prompts.add(scenario.prompt),
            isTrue,
            reason: 'Duplicate prompt for ${cat.name}',
          );
          expect(
            behaviors.add(scenario.expectedSecureBehavior),
            isTrue,
            reason: 'Duplicate behavior for ${cat.name}',
          );
          expect(scenario.category, cat);
          expect(scenario.targetBoundary, isNotEmpty);
        }
        expect(prompts.length, 10);
        expect(behaviors.length, 10);
      },
    );

    test(
      'Same category with different objectives produces distinct scenarios',
      () {
        final s1 = generator.generate(
          AttackCategory.directPromptInjection,
          'Objective A',
        );
        final s2 = generator.generate(
          AttackCategory.directPromptInjection,
          'Objective B',
        );

        expect(s1.prompt, isNot(equals(s2.prompt)));
        expect(s1.objective, 'Objective A');
        expect(s2.objective, 'Objective B');
      },
    );

    test('Target boundary parameter dynamically modifies prompt and expected behavior', () {
      final s1 = generator.generate(
        AttackCategory.toolAuthority,
        'Invoke tool',
        targetBoundary: 'database_exec_boundary',
      );
      final s2 = generator.generate(
        AttackCategory.toolAuthority,
        'Invoke tool',
        targetBoundary: 'network_egress_boundary',
      );

      expect(s1.targetBoundary, 'database_exec_boundary');
      expect(s2.targetBoundary, 'network_egress_boundary');
      expect(s1.prompt, contains('database_exec_boundary'));
      expect(s2.prompt, contains('network_egress_boundary'));
      expect(s1.expectedSecureBehavior, contains('database_exec_boundary'));
      expect(s2.expectedSecureBehavior, contains('network_egress_boundary'));
    });

    test('Complexity Levels 1 to 5 exhibit genuine structural differences', () {
      const obj = 'Evaluate authorization policy';
      const boundary = 'agent_memory_store';

      // Level 1: Direct
      final lvl1 = generator.generate(
        AttackCategory.contextPoisoning,
        obj,
        targetBoundary: boundary,
        intensity: Intensity.direct,
      );
      expect(lvl1.severity, 1);
      expect(lvl1.conversation, isNull);
      expect(lvl1.prompt, startsWith('Objective:'));

      // Level 2: Obfuscated
      final lvl2 = generator.generate(
        AttackCategory.contextPoisoning,
        obj,
        targetBoundary: boundary,
        intensity: Intensity.obfuscated,
      );
      expect(lvl2.severity, 2);
      expect(lvl2.conversation, isNull);
      expect(lvl2.prompt, contains('[Protocol Evaluation Mode: Active]'));

      // Level 3: Contextual
      final lvl3 = generator.generate(
        AttackCategory.contextPoisoning,
        obj,
        targetBoundary: boundary,
        intensity: Intensity.contextual,
      );
      expect(lvl3.severity, 3);
      expect(lvl3.conversation, isNull);
      expect(lvl3.prompt, contains('--- BEGIN UNTRUSTED CONTEXT DATA ---'));

      // Level 4: Multi-turn (Generates real structured conversation)
      final lvl4 = generator.generate(
        AttackCategory.contextPoisoning,
        obj,
        targetBoundary: boundary,
        intensity: Intensity.multiTurn,
      );
      expect(lvl4.severity, 4);
      expect(lvl4.conversation, isNotNull);
      expect(lvl4.conversation!.messages, hasLength(3));
      expect(lvl4.conversation!.messages[0].sequence, 1);
      expect(lvl4.conversation!.messages[0].role, 'user');
      expect(lvl4.conversation!.messages[1].sequence, 2);
      expect(lvl4.conversation!.messages[1].role, 'assistant');
      expect(lvl4.conversation!.messages[2].sequence, 3);
      expect(lvl4.conversation!.messages[2].role, 'user');

      // Level 5: Composite (Composite vector)
      final lvl5 = generator.generate(
        AttackCategory.contextPoisoning,
        obj,
        targetBoundary: boundary,
        intensity: Intensity.composite,
      );
      expect(lvl5.severity, 5);
      expect(lvl5.conversation, isNotNull);
      expect(lvl5.conversation!.messages, hasLength(3));
      expect(
        lvl5.conversation!.messages[2].content,
        contains('[Elevated Context Audit]'),
      );
    });
  });

  group('AttackConversation Structured Representation', () {
    test('Round-trip serialization, ordering, and message properties', () {
      final messages = [
        const AttackMessage(
          role: 'system',
          content: 'You are an AI assistant.',
          sequence: 1,
        ),
        const AttackMessage(
          role: 'user',
          content: 'First user prompt',
          sequence: 2,
        ),
        const AttackMessage(
          role: 'assistant',
          content: 'First response',
          sequence: 3,
        ),
        const AttackMessage(
          role: 'user',
          content: 'Follow-up adversarial instruction',
          sequence: 4,
        ),
      ];
      final conversation = AttackConversation(
        id: 'conv_123',
        messages: messages,
      );

      final json = conversation.toJson();
      expect(json['id'], 'conv_123');
      expect(json['messages'], hasLength(4));

      final decoded = AttackConversation.fromJson(json);
      expect(decoded.id, conversation.id);
      expect(decoded.messages, hasLength(4));
      for (var i = 0; i < messages.length; i++) {
        expect(decoded.messages[i].sequence, messages[i].sequence);
        expect(decoded.messages[i].role, messages[i].role);
        expect(decoded.messages[i].content, messages[i].content);
      }
    });

    test(
      'Conversation validation rejects invalid messages or missing fields',
      () {
        expect(
          () => AttackConversation.fromJson({'id': 123, 'messages': []}),
          throwsFormatException,
        );
        expect(
          () => AttackConversation.fromJson({
            'id': 'test',
            'messages': 'not_a_list',
          }),
          throwsFormatException,
        );
        expect(
          () => AttackConversation.fromJson({
            'id': 'test',
            'messages': [
              {'role': 'user'}, // missing content and sequence
            ],
          }),
          throwsFormatException,
        );
      },
    );
  });

  group('AdversarialTestCase v1 Protocol & Forward Compatibility', () {
    test('v1 JSON round-trip and validation', () {
      final messages = [
        const AttackMessage(
          role: 'user',
          content: 'Adversarial instruction',
          sequence: 1,
        ),
      ];
      const testCase = AdversarialTestCase(
        id: 'tc_001',
        category: 'directPromptInjection',
        objective: 'Test instruction boundary',
        messages: [
          AttackMessage(
            role: 'user',
            content: 'Adversarial instruction',
            sequence: 1,
          ),
        ],
        transformations: ['base64', 'hex'],
        expectedSecureBehavior: 'Refuse unauthorized prompt override.',
        metadata: {'author': 'auditor', 'risk_score': 8.5},
      );

      final json = testCase.toJson();
      expect(json['schemaVersion'], 1);

      final decoded = AdversarialTestCase.fromJson(json);
      expect(decoded.id, testCase.id);
      expect(decoded.category, testCase.category);
      expect(decoded.objective, testCase.objective);
      expect(decoded.messages.first.content, messages.first.content);
      expect(decoded.transformations, ['base64', 'hex']);
      expect(decoded.expectedSecureBehavior, testCase.expectedSecureBehavior);
      expect(decoded.metadata['author'], 'auditor');
      expect(decoded.metadata['risk_score'], 8.5);
    });

    test('Forward compatibility: tolerates unknown optional fields', () {
      final json = {
        'schemaVersion': 1,
        'id': 'tc_forward',
        'category': 'roleConfusion',
        'objective': 'Test forward compatibility',
        'messages': [
          {'role': 'user', 'content': 'Test', 'sequence': 1},
        ],
        'transformations': <String>[],
        'expectedSecureBehavior': 'Remain secure',
        'metadata': <String, dynamic>{},
        // Future unknown fields
        'future_field_string': 'future_value',
        'future_field_map': {'experimental': true},
      };

      final parsed = AdversarialTestCase.fromJson(json);
      expect(parsed.id, 'tc_forward');
      expect(parsed.category, 'roleConfusion');
    });

    test(
      'Rejection of missing required fields and unknown schema versions',
      () {
        final baseJson = {
          'schemaVersion': 1,
          'id': 'tc_bad',
          'category': 'directPromptInjection',
          'objective': 'Test missing',
          'messages': <dynamic>[],
          'transformations': <String>[],
          'expectedSecureBehavior': 'Safe',
        };

        // Missing objective
        final noObj = Map<String, dynamic>.from(baseJson)..remove('objective');
        expect(
          () => AdversarialTestCase.fromJson(noObj),
          throwsFormatException,
        );

        // Missing messages
        final noMsg = Map<String, dynamic>.from(baseJson)..remove('messages');
        expect(
          () => AdversarialTestCase.fromJson(noMsg),
          throwsFormatException,
        );

        // Missing transformations
        final noTrans = Map<String, dynamic>.from(baseJson)
          ..remove('transformations');
        expect(
          () => AdversarialTestCase.fromJson(noTrans),
          throwsFormatException,
        );

        // Unsupported schemaVersion
        final badVer = Map<String, dynamic>.from(baseJson)
          ..['schemaVersion'] = 2;
        expect(
          () => AdversarialTestCase.fromJson(badVer),
          throwsFormatException,
        );
      },
    );
  });

  group('Export Consistency & File Export Service', () {
    final scenario = AttackGenerator().generate(
      AttackCategory.roleConfusion,
      'Test authority boundary',
      intensity: Intensity.multiTurn,
    );

    test('All exports derive consistently from identical Domain Authority', () {
      const exporter = ExportService();
      final textExport = exporter.text(scenario);
      final jsonExport = exporter.json(scenario);
      final mdExport = exporter.markdown(scenario);

      expect(textExport, contains(scenario.name));
      expect(textExport, contains(scenario.prompt));
      expect(textExport, contains(scenario.expectedSecureBehavior));

      expect(jsonExport, contains(scenario.id));
      expect(jsonExport, contains(scenario.name));
      expect(jsonExport, contains('schemaVersion'));

      expect(mdExport, contains(scenario.name));
      expect(mdExport, contains(scenario.objective));
      expect(mdExport, contains(scenario.expectedSecureBehavior));
    });

    test('FileExportService filename sanitization handles special and Unicode characters', () {
      expect(FileExportService.sanitizeFilename(''), 'export');
      expect(FileExportService.sanitizeFilename('   '), 'export');
      expect(
        FileExportService.sanitizeFilename('case:with/illegal\\chars?*<>|'),
        'case_with_illegal_chars_____',
      );
      final sanitizedPath = FileExportService.sanitizeFilename(
        '../../etc/passwd',
      );
      expect(sanitizedPath, contains('etc_passwd'));
      expect(sanitizedPath, isNot(contains('/')));
      expect(sanitizedPath, isNot(contains('..')));
      // Unicode filenames must be preserved
      expect(
        FileExportService.sanitizeFilename('测试用例_日本語_2026'),
        '测试用例_日本語_2026',
      );
    });

    test(
      'FileExportService writes files and creates parent directories',
      () async {
        final tempDir = await Directory.systemTemp.createTemp(
          'zhuangma_export_',
        );
        final exportService = FileExportService();

        final targetPath =
            '${tempDir.path}/nested/subfolder/test_scenario.json';
        final file = await exportService.writeJson(scenario, targetPath);

        expect(await file.exists(), isTrue);
        final content = await file.readAsString();
        expect(content, contains(scenario.id));

        await tempDir.delete(recursive: true);
      },
    );
  });

  group('LlmProvider Extension Point Boundary', () {
    test(
      'MockLlmProvider fulfills contract cleanly without external side effects',
      () async {
        const provider = MockLlmProvider();
        final response = await provider.generate(
          instruction: 'Evaluate test boundary',
          objective: 'Observe mock execution',
        );

        expect(response.text, contains('Evaluate test boundary'));
        expect(response.text, contains('Observe mock execution'));
        expect(response.metadata['provider'], 'mock');
      },
    );
  });
}

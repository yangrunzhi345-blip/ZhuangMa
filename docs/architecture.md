# Architecture

ZhuangMa is structured in four decoupled, modular layers to maintain strict separation of concerns, deterministic testability, and resilience as test infrastructure for future security harness execution:

```
Presentation (Flutter Material 3 Shell, Pages, Widgets, AppStrings i18n, Error Boundary)
      ↓
Application (AttackGenerationService, TransformationService, ScenarioLibraryService, ExportService)
      ↓
Domain (TextTransformer, TransformationPipeline, TransformationEngine, RecoveryProtocol, AttackScenario, ScenarioRepository Interface)
      ↑
Infrastructure (SqliteScenarioRepository, InMemoryScenarioRepository, FileExportService, MockLlmProvider)
```

## Directory Hierarchy

```
lib/
├── core/
│   └── errors/
│       ├── app_exception.dart
│       ├── repository_exception.dart
│       └── transformer_exception.dart
├── domain/
│   ├── attack/
│   │   ├── attack_category.dart
│   │   ├── attack_conversation.dart
│   │   ├── attack_generator.dart
│   │   ├── attack_intensity.dart
│   │   ├── attack_message.dart
│   │   └── attack_scenario.dart
│   ├── llm/
│   │   ├── llm_provider.dart
│   │   └── llm_response.dart
│   ├── protocol/
│   │   ├── adversarial_test_case.dart
│   │   └── recovery_protocol.dart
│   ├── repository/
│   │   └── scenario_repository.dart
│   └── transformation/
│       ├── reversibility.dart
│       ├── text_transformer.dart
│       ├── transformation_engine.dart
│       ├── transformation_pipeline.dart
│       ├── transformation_result.dart
│       └── transformers/
│           ├── base64_transformer.dart
│           ├── chunk_transformer.dart
│           ├── code_point_transformer.dart
│           ├── hex_transformer.dart
│           ├── separator_transformer.dart
│           ├── unicode_transformer.dart
│           └── wrapper_transformer.dart
├── application/
│   ├── attack/
│   │   └── attack_generation_service.dart
│   ├── export/
│   │   ├── export_service.dart
│   │   └── scenario_exporter.dart
│   ├── library/
│   │   └── scenario_library_service.dart
│   └── transformation/
│       └── transformation_service.dart
├── infrastructure/
│   ├── database/
│   │   ├── memory/
│   │   │   └── in_memory_scenario_repository.dart
│   │   └── sqlite/
│   │       └── sqlite_scenario_repository.dart
│   ├── export/
│   │   └── file/
│   │       └── file_export_service.dart
│   └── providers/
│       └── mock_llm_provider.dart
├── presentation/
│   ├── app.dart
│   ├── app_strings.dart
│   ├── pages/
│   │   ├── composer_page.dart
│   │   ├── home_page.dart
│   │   ├── library_page.dart
│   │   └── transformer_page.dart
│   └── widgets/
│       └── shell.dart
├── main.dart (Pure App Initialization & Bootstrap)
└── zhuangma.dart (Package Root Barrel Export)
```

## Layer Specifications & Authority Rules

### 1. Domain Layer (Pure Dart)
- **Zero Framework Coupling**: The domain layer has zero imports of `package:flutter`, `package:sqflite`, `package:path_provider`, or platform-specific libraries. Mechanically enforced by automated architecture tests (`test/architecture_test.dart`).
- **Transformers**: Seven reversible text transformers (`UnicodeTransformer`, `CodePointTransformer`, `Base64Transformer`, `HexTransformer`, `SeparatorTransformer`, `ChunkTransformer`, `WrapperTransformer`) implementing `TextTransformer`. Every transformer preserves the strict reversibility invariant: `restore(transform(x)) == x`.
- **TransformationEngine**: Single domain authority for discovering, validating, and executing transformation pipelines.
- **TransformationPipeline**: Sequentially executes transformer steps and reverses them strictly in Last-In-First-Out (LIFO) order. Supports multi-step composition, repeated transformers, step-level tracking, and dynamic reversibility reporting (`fullyReversible`, `partiallyReversible`, `notReversible`).
- **RecoveryProtocol**: Captures transformer step sequence, base64-encoded original payload, and SHA-256 hash of the original UTF-8 payload. Rebuilding the payload validates hash equality and rejects tampered data with typed `FormatException`.
- **Attack Models**:
  - `AttackCategory`: 10 distinct AI security categories covering prompt injection, boundary escalation, context poisoning, role confusion, memory poisoning, and tool authority.
  - `Intensity`: 5 complexity levels (Level 1: Direct single-turn, Level 2: Obfuscated protocol framing, Level 3: Contextual untrusted document container, Level 4: Structured multi-turn conversation escalation, Level 5: Composite multi-vector simulation).
  - `AttackConversation` & `AttackMessage`: Structured multi-turn representations preserving turn sequence and roles, avoiding lossy flattening into strings in Domain Authority.
  - `AdversarialTestCase v1`: Interoperable test case protocol with schema versioning, structured messages, transformation metadata, and forward-compatible tolerance for optional fields.
- **ScenarioRepository Contract**: Abstract interface (`save`, `getById`, `all`, `search`, `filter`, `count`, `delete`, `close`) isolating domain and application layers from concrete storage engines.

### 2. Application Layer (Workflow Orchestration)
- **AttackGenerationService**: Orchestrates scenario creation, parameter validation, and boundary specification via `AttackGenerator`.
- **TransformationService**: Coordinates text transformations, pipeline construction, reversibility analysis, and execution reporting through `TransformationEngine`.
- **ScenarioLibraryService**: Governs scenario lifecycle operations against `ScenarioRepository`.
- **Export Services**: `ExportService` and `ScenarioExporter` serialize domain scenarios into Plain Text, JSON, Markdown, and `AdversarialTestCase` v1 formats from a single Domain Authority, guaranteeing zero presentation drift.

### 3. Infrastructure Layer (External Adapters)
- **Database**:
  - `SqliteScenarioRepository`: SQLite-backed persistence using `sqflite_common_ffi` with schema versioning (`version: 1`), migration hooks, and corrupt row resilience.
  - `InMemoryScenarioRepository`: High-performance in-memory repository implementing `ScenarioRepository` for testing and zero-IO fallback.
- **File Export**: `FileExportService` writes scenarios and test cases to disk, implementing rigorous filename sanitization (stripping traversal sequences `..`, control characters, and Windows reserved symbols `<>:"/\|?*`).
- **LLM Providers**: `MockLlmProvider` provides deterministic local execution without network calls, secrets, or external API keys.

### 4. Presentation Layer (UI & Interaction)
- Built with Flutter Material 3, adapting responsively across viewports from 320px narrow mobile to 1440px desktop.
- Wide screens (≥ 700px) render a left-aligned `NavigationRail`; compact screens (< 700px) render a `NavigationBar`.
- All user-facing strings are routed through `AppStrings` with English fallback and Simplified Chinese (`zh-Hans`) localization.
- **Widgets Decoupled from Infrastructure**: Pages (`ComposerPage`, `TransformerPage`, `LibraryPage`) do not instantiate concrete databases, perform filesystem operations, or execute raw JSON serialization; they delegate strictly to application services.
- **Error Boundary**: User-facing dialogs and banners present user-friendly localized messages without leaking raw exception strings or stack traces.

### 5. main.dart Convergence
- `main.dart` is reduced to an ultra-compact bootstrap entry point (under 30 lines), initializing Flutter bindings, wiring repository factories, and running `ZhuangMaApp`.

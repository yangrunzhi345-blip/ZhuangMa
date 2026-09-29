# Architecture

ZhuangMa is structured in four clear conceptual layers to maintain strict separation of concerns, deterministic testability, and resilience as test infrastructure for future security harness execution:

```
Presentation (Flutter Material 3 Shell, AppStrings i18n, Error Boundary, Constrained Dialogs)
      ↓
Application (ExportService, FileExportService, LlmProvider Abstract Extension Point)
      ↓
Domain (TextTransformer, TransformationPipeline, RecoveryProtocol, AttackScenario, AttackConversation, AdversarialTestCase v1)
      ↓
Infrastructure (SqliteScenarioRepository, FFI Database Factory, Migration Hooks)
```

## Presentation Layer
- Built with Flutter Material 3, adapting responsively across viewports from 320px narrow mobile to 1440px desktop.
- Wide screens (≥ 700px) render a left-aligned `NavigationRail`; compact screens (< 700px) render a `NavigationBar`.
- All user-facing strings are routed through `AppStrings` with English fallback and Simplified Chinese (`zh-Hans`) localization.
- Error presentation captures `FormatException` and database faults into user-friendly message containers rather than leaking raw exceptions or stack traces to the framework.
- Export preview dialogs enforce max-width constraints (`BoxConstraints(maxWidth: 600, maxHeight: 400)`) preventing horizontal `RenderFlex` overflows on ultra-narrow mobile viewports (320px).
- Large outputs and JSON payloads are encased in horizontal scroll views to preserve layout stability under multi-kilobyte adversarial test vectors.

## Application Layer
- **Export Services**: `ExportService` serializes domain scenarios into Plain Text, JSON, Markdown, and `AdversarialTestCase` v1 formats from a single Domain Authority, guaranteeing zero presentation drift.
- **File Export**: `FileExportService` safely writes scenarios and test cases to disk, implementing rigorous filename sanitization (stripping traversal sequences `..`, control characters, and Windows reserved symbols `<>:"/\|?*` while preserving valid Unicode filenames like Chinese/Japanese scripts).
- **LLM Provider Boundary**: `LlmProvider` defines an abstract interface for text generation. `MockLlmProvider` supplies deterministic local execution without network calls, secrets, or external API keys.

## Domain Layer
- **Transformers**: Seven reversible text transformers (`UnicodeTransformer`, `CodePointTransformer`, `Base64Transformer`, `HexTransformer`, `SeparatorTransformer`, `ChunkTransformer`, `WrapperTransformer`) sharing a pure Dart interface. Every transformer adheres to the strict reversibility invariant: `restore(transform(x)) == x`.
- **Transformation Pipeline**: Sequentially applies transformer steps and reverses them strictly in Last-In-First-Out (LIFO) order. Supports multi-step composition, repeated transformers, step-level tracking, and dynamic reversibility reporting (`fullyReversible`, `partiallyReversible`, `notReversible`).
- **Recovery Protocol**: Protocol v1 structure capturing transformer step sequence, base64-encoded original payload, and SHA-256 hash of the original UTF-8 payload. Rebuilding the payload validates hash equality and rejects tampered data with typed `FormatException`.
- **Attack Models**:
  - `AttackCategory`: 10 distinct AI security categories covering prompt injection, boundary escalation, context poisoning, role confusion, memory poisoning, and tool authority.
  - `Intensity`: 5 complexity levels (Level 1: Direct single-turn, Level 2: Obfuscated protocol framing, Level 3: Contextual untrusted document container, Level 4: Structured multi-turn conversation escalation, Level 5: Composite multi-vector simulation).
  - `AttackConversation` & `AttackMessage`: Structured multi-turn representations preserving turn sequence and roles, avoiding lossy flattening into strings in Domain Authority.
  - `AdversarialTestCase v1`: Interoperable test case protocol with schema versioning, structured messages, transformation metadata, and forward-compatible tolerance for optional fields.

## Infrastructure Layer
- `SqliteScenarioRepository` provides SQLite-backed persistence using `sqflite_common_ffi`.
- **Migration Contract**: SQLite database initializes via versioned `OpenDatabaseOptions` (`version: 1`, `onCreate: _createSchemaV1`, `onUpgrade: _migrate`), providing an explicit, deterministic pathway for future schema migrations (v1 → v2).
- **Resilience**: Corrupt or malformed database rows (invalid JSON, missing fields, unknown enums) are skipped without crashing the library; diagnostic messages are recorded in a diagnostics log for auditability.

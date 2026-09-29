# Roadmap

## Phase 1: Local Generation and Playground (Completed)
- Material 3 responsive shell (Mobile, Tablet, Desktop)
- 7 reversible transformers and sequential Transformation Pipeline
- Recovery Protocol generation and payload reconstruction
- 10 AI application adversarial categories with Template Attack Generator
- Attack Composer with structured multi-turn conversation support
- SQLite-backed Attack Library repository
- Multi-format export services (JSON, Markdown, Plain Text, AdversarialTestCase v1)
- LlmProvider abstraction and Mock Provider
- Centralized English fallback and zh-Hans localization copy

## Phase 1.5: Deep Audit & Adversarial Validation (Completed / Accepted)
- Rigorous reversibility matrix across all 7 transformers (empty text, ASCII, CJK, Japanese, Korean, Emoji, ZWJ sequences, combining marks, non-BMP characters, tabs/whitespace, CRLF, large payloads up to 100 KB)
- Fixed delimiter escaping in `SeparatorTransformer` to guarantee 100% round-trip fidelity
- Fixed stream BOM handling in `ChunkTransformer` for zero-width no-break spaces
- Fixed bounds check and non-BMP handling in `UnicodeTransformer`
- Enforced strict LIFO step execution in pipeline reverse restoration
- Hardened `RecoveryProtocol` with SHA-256 integrity verification
- Dynamic semantics for all 10 scenario categories, target boundaries, and 5 intensity levels (with real multi-turn conversations for Level 4)
- SQLite repository resiliency (versioning, migration hooks, corruption diagnostics, search/filter queries, typed exceptions)
- Robust responsive UI hardening across 320px–1440px viewport widths with zero RenderFlex overflow
- Expanded comprehensive test suite from 6 tests to 47 tests across domain, transformer matrix, SQLite repository, and responsive widgets

## Phase 2A: Architecture Hardening (Completed)
- Strict layer decoupling across Domain, Application, Infrastructure, and Presentation
- Pure Dart `domain/` layer with zero dependencies on Flutter, SQLite, or UI libraries
- `main.dart` converged from 1481 lines to an ultra-compact ~30 line bootstrap entry point
- Single Authority enforcement: `TransformationEngine`, `ScenarioRepository` contract interface, `ScenarioExporter`, and `AttackGenerationService`
- Error boundary enforcement preventing raw exception leakages to user interfaces
- Automated architecture boundary test suite enforcing layer isolation (`test/architecture_test.dart`)
- Test suite expanded to 54 tests with 100% pass rate and zero analyzer issues

## Phase 2B: Security Harness Protocol & Local Execution (Upcoming)
- Security Harness orchestration protocol
- Local execution harness for LLM/agent boundary testing
- Batch attack execution and automated evaluation against expected secure behavior
- Structured test reporting and benchmark metrics

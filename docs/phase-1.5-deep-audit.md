# Phase 1.5 Deep Audit

## Baseline
Audit started from `01473f4` with a clean worktree and matching `origin/main`.

## Scope
This audit covers reversible text transformations, Unicode boundaries, pipeline reversal, recovery metadata, attack model serialization, SQLite persistence, exports, provider boundaries, and responsive UI behavior. The security scope remains limited to AI application and prompt security testing.

## Findings and fixes
- **MAJOR fixed:** Chunk transformation used UTF-16 indexing and could split non-BMP characters. It now chunks Unicode scalar values and validates a positive chunk count.
- **MINOR fixed:** Hex restore silently ignored an odd trailing nibble. It now rejects odd or non-hex input with `FormatException`.

## Validation
The deterministic matrix covers empty text, ASCII, CJK, Japanese, Korean, emoji and ZWJ sequences, combining marks, zero-width characters, tabs, spaces, and CRLF. SQLite CRUD/reopen, export, protocol, and responsive shell tests remain part of the suite.

## Remaining limitations
The current repository still uses a compact domain implementation in `lib/main.dart`; a future refactor can split domain, application, and presentation files further. Full file-picker integration and exhaustive localized UI copy migration remain follow-up work.

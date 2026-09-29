# Transformation Engine

The transformation engine provides deterministic, reversible text encoding transformations designed to test how LLMs and prompt sanitization boundaries handle non-standard representations.

## Reversibility Invariant
For all reversible transformers, the following invariant is strictly enforced:
```dart
restore(transform(x, options: opt), options: opt) == x
```
This invariant holds across all supported Unicode scripts, emoji, zero-width joiners, surrogate pairs, combining marks, leading/trailing whitespace, newlines (LF/CRLF), empty strings, and payloads up to 100 KB.

## The Seven Reversible Transformers

| Transformer ID | Display Name | Mechanism | Reversibility & Error Handling |
| :--- | :--- | :--- | :--- |
| `unicode_escape` | Unicode Escape | Encodes runes into `\uXXXX` (4 to 6 hex digits). | Reversible for all Unicode scalar values. Rejects malformed or unescaped characters with `FormatException`. |
| `code_points` | Code Points | Formats code points as spaced `U+XXXX` tokens. | Reversible. Rejects invalid code point tokens or surrogate values with `FormatException`. |
| `base64` | Base64 | Encodes UTF-8 bytes to standard Base64. | Reversible. Validates Base64 and valid UTF-8 sequences. |
| `hex` | Hex | Encodes UTF-8 bytes to hexadecimal pairs. | Reversible. Rejects odd lengths, non-hex characters, and invalid UTF-8 bytes. |
| `separator` | Character Separator | Inserts a delimiter between characters, escaping occurrences of delimiter and backslash. | 100% reversible for all characters including whitespace. Delimiter and backslashes are escaped during transform and unescaped on restore. |
| `chunk` | Chunk Reordering | Splits code points into N chunks, base64 encodes each chunk, and reverses the chunk ordering with index headers `[i/N]`. | Reversible. Recombines byte arrays before decoding to protect against stream-level BOM stripping. Rejects missing or out-of-order chunks. |
| `wrapper` | Structured Wrapper | Envelopes payload in JSON envelope `{"type": "test-payload", "payload": s}`. | Reversible. Rejects invalid JSON, mismatched types, or missing payload fields. |

## Transformation Pipeline
- **Execution Order**: Forward transformation evaluates sequentially: `step[0] -> step[1] -> ... -> step[N-1]`.
- **Reversal Order**: Reversal is strictly Last-In-First-Out (LIFO): `step[N-1] -> ... -> step[1] -> step[0]`.
- **Reversibility Reporting**: Pipelines evaluate step capabilities:
  - `Reversibility.fullyReversible`: All steps are reversible.
  - `Reversibility.partiallyReversible`: Some steps are reversible, but others are not.
  - `Reversibility.notReversible`: No reversible steps.
- **Composition & Duplication**: Pipelines allow repeating transformers (e.g. `Base64 -> Wrapper -> Base64`), and reject duplicate step IDs when structured step IDs are provided.

## Recovery Protocol Specification
The `RecoveryProtocol` guarantees cryptographic integrity when restoring payloads:
- `version`: Protocol version (`1`).
- `transformationSteps`: List of transformer IDs in execution order.
- `expectedOutputHash`: The SHA-256 hex digest of the **original UTF-8 payload**.
- `hashAlgorithm`: Strictly `sha256`.
- `originalPayload`: Base64-encoded bytes of the **original UTF-8 payload**.
- `recover()`: Decodes `originalPayload`, computes its SHA-256 hash, verifies equality with `expectedOutputHash`, and returns the recovered string. Throws `FormatException('recovery hash mismatch')` if tampered.

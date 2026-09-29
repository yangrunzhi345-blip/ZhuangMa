# AdversarialTestCase Protocol Specification (v1)

`AdversarialTestCase` v1 is the canonical serialized format designed for exporting structured adversarial test vectors to downstream evaluation engines and future security harness integrations.

## Schema Specification

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "AdversarialTestCase_v1",
  "type": "object",
  "required": [
    "schemaVersion",
    "id",
    "category",
    "objective",
    "messages",
    "transformations",
    "expectedSecureBehavior"
  ],
  "properties": {
    "schemaVersion": {
      "type": "integer",
      "enum": [1],
      "description": "Protocol version. Only version 1 is supported."
    },
    "id": {
      "type": "string",
      "description": "Unique identifier for the adversarial test case."
    },
    "category": {
      "type": "string",
      "description": "AttackCategory name identifying the adversarial vector."
    },
    "objective": {
      "type": "string",
      "description": "High-level goal or instruction tested by this scenario."
    },
    "messages": {
      "type": "array",
      "description": "Ordered sequence of conversational turns in this test case.",
      "items": {
        "type": "object",
        "required": ["role", "content", "sequence"],
        "properties": {
          "role": { "type": "string", "enum": ["system", "user", "assistant"] },
          "content": { "type": "string" },
          "sequence": { "type": "integer", "minimum": 1 }
        }
      }
    },
    "transformations": {
      "type": "array",
      "items": { "type": "string" },
      "description": "List of transformer IDs applied to the test prompt."
    },
    "expectedSecureBehavior": {
      "type": "string",
      "description": "Assertion describing the expected secure AI application response."
    },
    "metadata": {
      "type": "object",
      "description": "Optional arbitrary metadata map (e.g. author, riskScore, tags)."
    }
  }
}
```

## Protocol Validation Rules
1. **Version Enforcement**: If `schemaVersion` is absent or not equal to `1`, parsers must throw a typed `FormatException('unsupported test case schema version')`. Silent degradation to v1 parsing is forbidden.
2. **Mandatory Fields**: Missing any of `id`, `category`, `objective`, `messages`, `transformations`, or `expectedSecureBehavior` will immediately fail validation with `FormatException('missing required field: <field>')`.
3. **Forward Compatibility**: Unknown top-level optional fields are safely ignored by the v1 parser, enabling non-breaking forward extensions in future harness runners.
4. **Structured Multi-Turn Authority**: Messages are preserved as structured objects with sequential numbering, preventing lossy string flattening in domain logic.

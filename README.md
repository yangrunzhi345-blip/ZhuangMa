# ZhuangMa

ZhuangMa is an adversarial testing toolkit for evaluating AI application security. It creates prompt-injection, context-boundary, encoding, and agent-authority test cases for local use.

## Features
- Material 3 responsive shell for desktop and mobile
- Seven reversible text transformations and composable pipelines
- Template attack generation across ten AI security categories
- Recovery protocol and AdversarialTestCase v1 domain models

## Scope
This project tests LLM and AI application boundaries. It does not implement malware, credential theft, phishing, destructive operations, remote exploitation, or unauthorized scanning.

## Development
`flutter pub get && dart format . && flutter analyze && flutter test`

ZhuangMa is independent from LT. Exported test cases are designed for a future LT harness integration.

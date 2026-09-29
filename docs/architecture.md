# Architecture
Presentation uses Flutter Material 3. Domain transformers and attack models are pure Dart and can be tested independently. Application orchestration will own persistence and exports; infrastructure adapters remain replaceable.

## Persistence boundary
`ScenarioRepository` is the application-facing repository contract used by the UI. A SQLite adapter can implement this contract without changing domain or presentation code; the current Phase 1 shell keeps the default repository in memory for deterministic local operation.

## Localization boundary
The app advertises English and Simplified Chinese locales through `MaterialApp.supportedLocales`; user-facing copy is being migrated behind a localization service before the next release.

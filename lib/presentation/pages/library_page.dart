import 'package:flutter/material.dart';

import '../../application/attack/attack_generation_service.dart';
import '../../application/library/scenario_library_service.dart';
import '../../domain/attack/attack_category.dart';
import '../../domain/attack/attack_scenario.dart';
import '../../infrastructure/database/memory/in_memory_scenario_repository.dart';
import '../app_strings.dart';

class LibraryPage extends StatefulWidget {
  static Future<ScenarioLibraryService> Function()? defaultServiceFactory;

  final ScenarioLibraryService? libraryService;
  final AttackGenerationService? attackService;

  const LibraryPage({super.key, this.libraryService, this.attackService});

  @override
  State<LibraryPage> createState() => _LibraryState();
}

class _LibraryState extends State<LibraryPage> {
  ScenarioLibraryService? _service;
  late final AttackGenerationService _attackService;
  List<AttackScenario> scenarios = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _attackService = widget.attackService ?? AttackGenerationService();
    _load();
  }

  Future<void> _load() async {
    try {
      final service =
          widget.libraryService ??
          (LibraryPage.defaultServiceFactory != null
              ? await LibraryPage.defaultServiceFactory!()
              : ScenarioLibraryService(InMemoryScenarioRepository()));

      final saved = await service.getScenarios();
      if (!mounted) {
        await service.dispose();
        return;
      }
      setState(() {
        _service = service;
        scenarios = saved;
        loading = false;
        errorMessage = null;
      });
    } on Object {
      if (mounted) {
        setState(() {
          loading = false;
          final strings = AppStrings(Localizations.localeOf(context));
          errorMessage = strings.dbError;
        });
      }
    }
  }

  Future<void> _create() async {
    try {
      final item = _attackService.generate(
        category: AttackCategory.directPromptInjection,
        objective: 'Test instruction priority boundary',
      );
      await _service?.saveScenario(item);
      if (mounted) setState(() => scenarios = [...scenarios, item]);
    } on Object {
      if (mounted) {
        setState(() {
          final strings = AppStrings(Localizations.localeOf(context));
          errorMessage = strings.dbError;
        });
      }
    }
  }

  Future<void> _delete(AttackScenario item) async {
    try {
      await _service?.deleteScenario(item.id);
      if (mounted) {
        setState(() => scenarios.removeWhere((x) => x.id == item.id));
      }
    } on Object {
      if (mounted) {
        setState(() {
          final strings = AppStrings(Localizations.localeOf(context));
          errorMessage = strings.dbError;
        });
      }
    }
  }

  @override
  void dispose() {
    // Only dispose if created locally and not passed from outside
    if (widget.libraryService == null) {
      _service?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final strings = AppStrings(Localizations.localeOf(c));
    return Material(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            strings.libraryTitle,
            style: Theme.of(c).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          if (loading)
            const SizedBox(
              height: 4,
              child: LinearProgressIndicator(value: 0.0),
            )
          else
            Text(strings.savedScenarios(scenarios.length)),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(color: Theme.of(c).colorScheme.error),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: loading ? null : _create,
            icon: const Icon(Icons.add),
            label: Text(strings.createLocalScenario),
          ),
          const SizedBox(height: 12),
          if (!loading && scenarios.isEmpty)
            Text(strings.noSavedScenarios)
          else
            ...scenarios.map(
              (s) => Card(
                child: ListTile(
                  title: Text(s.name),
                  subtitle: Text(s.objective),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _delete(s),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

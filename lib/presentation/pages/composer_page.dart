import 'dart:convert';

import 'package:flutter/material.dart';

import '../../application/attack/attack_generation_service.dart';
import '../../application/export/export_service.dart';
import '../../domain/attack/attack_category.dart';
import '../../domain/attack/attack_conversation.dart';
import '../../domain/attack/attack_intensity.dart';
import '../../domain/attack/attack_scenario.dart';
import '../app_strings.dart';

class ComposerPage extends StatefulWidget {
  final AttackGenerationService? attackService;
  final ExportService? exportService;

  const ComposerPage({super.key, this.attackService, this.exportService});

  @override
  State<ComposerPage> createState() => _ComposerState();
}

class _ComposerState extends State<ComposerPage> {
  late final AttackGenerationService _attackService;
  late final ExportService _exportService;

  AttackCategory cat = AttackCategory.directPromptInjection;
  Intensity intensity = Intensity.direct;
  final ctl = TextEditingController(
    text: 'Test whether the AI follows system instructions',
  );
  final boundaryCtl = TextEditingController(
    text: 'AI application instruction boundary',
  );
  AttackScenario? result;
  AttackConversation? conversation;

  @override
  void initState() {
    super.initState();
    _attackService = widget.attackService ?? AttackGenerationService();
    _exportService = widget.exportService ?? const ExportService();
  }

  @override
  void dispose() {
    ctl.dispose();
    boundaryCtl.dispose();
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
            strings.composerTitle,
            style: Theme.of(c).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<AttackCategory>(
            isExpanded: true,
            initialValue: cat,
            items: AttackCategory.values
                .map((x) => DropdownMenuItem(value: x, child: Text(x.name)))
                .toList(),
            onChanged: (x) => setState(() => cat = x!),
            decoration: InputDecoration(labelText: strings.category),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Intensity>(
            isExpanded: true,
            initialValue: intensity,
            items: Intensity.values
                .map((x) => DropdownMenuItem(value: x, child: Text(x.name)))
                .toList(),
            onChanged: (x) => setState(() => intensity = x!),
            decoration: InputDecoration(labelText: strings.intensity),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: boundaryCtl,
            decoration: InputDecoration(labelText: strings.targetBoundary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: ctl,
            decoration: InputDecoration(labelText: strings.objective),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => setState(() {
              result = _attackService.generate(
                category: cat,
                objective: ctl.text,
                targetBoundary: boundaryCtl.text,
                intensity: intensity,
              );
              conversation = result!.conversation;
            }),
            child: Text(strings.generate),
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SelectableText(
                    const JsonEncoder.withIndent('  ')
                        .convert(result!.toJson()),
                  ),
                ),
              ),
            ),
            if (conversation != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.conversationTurns,
                        style: Theme.of(c).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ...conversation!.messages.map(
                        (m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            '${strings.turnLabel} ${m.sequence} · ${m.role}: ${m.content}',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () =>
                      _showExport(c, strings, _exportService.text(result!)),
                  child: Text(strings.plainText),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _showExport(c, strings, _exportService.json(result!)),
                  child: Text(strings.jsonText),
                ),
                OutlinedButton(
                  onPressed: () =>
                      _showExport(c, strings, _exportService.markdown(result!)),
                  child: Text(strings.markdownText),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showExport(BuildContext context, AppStrings strings, String content) =>
      showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(strings.exportPreview),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600, maxHeight: 400),
            child: SingleChildScrollView(child: SelectableText(content)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(strings.close),
            ),
          ],
        ),
      );
}

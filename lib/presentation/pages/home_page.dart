import 'package:flutter/material.dart';

import '../app_strings.dart';
import 'composer_page.dart';
import 'transformer_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext c) {
    final strings = AppStrings(Localizations.localeOf(c));
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          strings.homeDescription,
          style: Theme.of(c).textTheme.headlineMedium,
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => Navigator.of(c).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(strings.composerTitle)),
                    body: const ComposerPage(),
                  ),
                ),
              ),
              icon: const Icon(Icons.bolt),
              label: Text(strings.createAttack),
            ),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(c).push(
                MaterialPageRoute(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: Text(strings.transformerTitle)),
                    body: const TransformerPage(),
                  ),
                ),
              ),
              icon: const Icon(Icons.transform),
              label: Text(strings.transformPayload),
            ),
          ],
        ),
      ],
    );
  }
}

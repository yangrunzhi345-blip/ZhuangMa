import 'package:flutter/material.dart';

import '../app_strings.dart';
import '../pages/composer_page.dart';
import '../pages/home_page.dart';
import '../pages/library_page.dart';
import '../pages/transformer_page.dart';

class Shell extends StatefulWidget {
  final int initialIndex;
  const Shell({super.key, this.initialIndex = 0});

  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  late int index;
  final pages = const [
    HomePage(),
    ComposerPage(),
    TransformerPage(),
    LibraryPage(),
  ];

  @override
  void initState() {
    super.initState();
    index = widget.initialIndex;
  }

  @override
  Widget build(BuildContext c) {
    final strings = AppStrings(Localizations.localeOf(c));
    return LayoutBuilder(
      builder: (c, b) {
        final wide = b.maxWidth >= 700;
        return Scaffold(
          appBar: AppBar(title: Text(strings.appName)),
          body: wide
              ? Row(
                  children: [
                    NavigationRail(
                      selectedIndex: index,
                      onDestinationSelected: (i) => setState(() => index = i),
                      labelType: NavigationRailLabelType.all,
                      destinations: [
                        NavigationRailDestination(
                          icon: const Icon(Icons.home_outlined),
                          label: Text(strings.navHome),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.bolt),
                          label: Text(strings.navAttackComposer),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.transform),
                          label: Text(strings.navTransformer),
                        ),
                        NavigationRailDestination(
                          icon: const Icon(Icons.library_books),
                          label: Text(strings.navLibrary),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: pages[index]),
                  ],
                )
              : pages[index],
          bottomNavigationBar: wide
              ? null
              : NavigationBar(
                  selectedIndex: index,
                  onDestinationSelected: (i) => setState(() => index = i),
                  destinations: [
                    NavigationDestination(
                      icon: const Icon(Icons.home_outlined),
                      label: strings.navHome,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.bolt),
                      label: strings.navAttackComposer,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.transform),
                      label: strings.navTransformer,
                    ),
                    NavigationDestination(
                      icon: const Icon(Icons.library_books),
                      label: strings.navLibrary,
                    ),
                  ],
                ),
        );
      },
    );
  }
}

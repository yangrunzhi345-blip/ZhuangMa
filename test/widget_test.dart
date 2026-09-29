import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/domain/transformation/text_transformer.dart';
import 'package:zhuangma/presentation/app.dart';
import 'package:zhuangma/presentation/pages/composer_page.dart';
import 'package:zhuangma/presentation/pages/home_page.dart';
import 'package:zhuangma/presentation/pages/library_page.dart';
import 'package:zhuangma/presentation/pages/transformer_page.dart';

void main() {
  testWidgets(
    'responsive shell renders in English and Simplified Chinese across all widths',
    (tester) async {
      final widths = [320.0, 360.0, 390.0, 600.0, 1024.0, 1440.0];
      final locales = [const Locale('en'), const Locale('zh', 'Hans')];

      for (final locale in locales) {
        for (final width in widths) {
          await tester.binding.setSurfaceSize(Size(width, 800));
          await tester.pumpWidget(ZhuangMaApp(initialLocale: locale));
          await tester.pumpAndSettle();

          expect(
            tester.takeException(),
            isNull,
            reason: 'Failed at width $width, locale $locale',
          );

          if (locale.languageCode == 'zh') {
            expect(find.text('用于评估 AI 应用安全性的对抗测试工具包。'), findsOneWidget);
            expect(find.text('创建攻击测试'), findsOneWidget);
          } else {
            expect(
              find.text(
                'An adversarial testing toolkit for evaluating AI application security.',
              ),
              findsOneWidget,
            );
            expect(find.text('Create Attack Test'), findsOneWidget);
          }
        }
      }
      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets('navigation across all four pages on 320px narrow mobile', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 800));
    await tester.pumpWidget(const ZhuangMaApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);

    // Navigate to Attack Composer
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.bolt),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ComposerPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Navigate to Transformer
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.transform),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TransformerPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Navigate to Library
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.byIcon(Icons.library_books),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('navigation across all four pages on 1024px desktop', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1024, 800));
    await tester.pumpWidget(const ZhuangMaApp());
    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);

    // Navigate to Attack Composer via NavigationRail
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Attack Composer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ComposerPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Navigate to Transformer
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Transformer'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TransformerPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Navigate to Library
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationRail),
        matching: find.text('Library'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LibraryPage), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets(
    'Attack Composer generates multi-turn and composite attacks cleanly',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 800));
      await tester.pumpWidget(const ZhuangMaApp());
      await tester.pumpAndSettle();

      // Navigate to composer via navigation bar
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.bolt),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Generate
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);

      // Scroll down to reveal export buttons
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      // Open export preview dialog
      await tester.tap(find.text('Plain Text'));
      await tester.pumpAndSettle();

      expect(find.text('Export preview'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Export preview'), findsNothing);

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Transformer Playground executes pipeline and handles errors gracefully',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 800)); // Narrow 320px
      await tester.pumpWidget(const ZhuangMaApp());
      await tester.pumpAndSettle();

      // Go to Transformer Playground via navigation bar
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.transform),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TransformerPage), findsOneWidget);

      // Select a transformer from dropdown
      await tester.tap(find.byType(DropdownButtonFormField<TextTransformer>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Base64').last);
      await tester.pumpAndSettle();

      // Transform
      await tester.tap(find.text('Transform'));
      await tester.pumpAndSettle();

      expect(find.byType(Card), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Restore
      await tester.tap(find.text('Restore'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Scroll down to Reset button if needed and tap
      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();
      expect(find.byType(Card), findsNothing);

      await tester.binding.setSurfaceSize(null);
    },
  );

  testWidgets(
    'Ultra-long content handles without RenderFlex overflow on 320px screen',
    (tester) async {
      await tester.binding.setSurfaceSize(
        const Size(320, 600),
      ); // Smallest screen constraint
      await tester.pumpWidget(const ZhuangMaApp());
      await tester.pumpAndSettle();

      // Go to Composer via navigation bar
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(Icons.bolt),
        ),
      );
      await tester.pumpAndSettle();

      // Enter very long objective
      final longObjective = 'Super long objective statement. ' * 50;
      await tester.enterText(find.byType(TextField).last, longObjective);
      await tester.pumpAndSettle();

      // Scroll to and tap Generate
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Generate'));
      await tester.pumpAndSettle();

      // Ensure no exception or overflow
      expect(tester.takeException(), isNull);

      // Scroll down to reveal export buttons
      await tester.scrollUntilVisible(
        find.text('JSON'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Open export preview dialog with long content
      await tester.tap(find.text('JSON'));
      await tester.pumpAndSettle();

      // Dialog must fit and not throw RenderFlex overflow
      expect(find.text('Export preview'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      await tester.binding.setSurfaceSize(null);
    },
  );
}

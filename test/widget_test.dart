import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/main.dart';

void main() {
  testWidgets('responsive shell renders', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(
      find.text(
        'An adversarial testing toolkit for evaluating AI application security.',
      ),
      findsOneWidget,
    );
  });
  test('transformers round trip', () {
    const input = 'Hello 世界 🌍';
    for (final t in [
      UnicodeTransformer(),
      CodePointTransformer(),
      Base64Transformer(),
      HexTransformer(),
    ]) {
      expect(t.restore(t.transform(input)), input);
    }
  });
  testWidgets('zh-Hans home copy is available', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh', 'Hans'),
        supportedLocales: [Locale('en'), Locale('zh', 'Hans')],
        home: HomePage(),
      ),
    );
    expect(find.text('用于评估 AI 应用安全性的对抗测试工具包。'), findsOneWidget);
  });
  testWidgets('shell fits narrow and desktop widths', (tester) async {
    for (final width in [320.0, 390.0, 1024.0]) {
      await tester.binding.setSurfaceSize(Size(width, 800));
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    await tester.binding.setSurfaceSize(null);
  });
}

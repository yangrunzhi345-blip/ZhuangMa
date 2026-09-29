import 'package:flutter_test/flutter_test.dart';
import 'package:zhuangma/main.dart';

void main() {
  testWidgets('responsive shell renders', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(
      find.text('Adversarial testing for AI applications'),
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
}

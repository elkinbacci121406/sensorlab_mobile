import 'package:flutter_test/flutter_test.dart';
import 'package:sensorlab_mobile/main.dart';

void main() {
  testWidgets('La pantalla principal muestra los cuatro módulos', (tester) async {
    await tester.pumpWidget(const SensorLabApp());

    expect(find.text('SensorLab Mobile'), findsOneWidget);
    for (final label in ['Batería', 'Luz', 'Proximidad', 'Info']) {
      expect(find.text(label), findsOneWidget);
    }
  });
}

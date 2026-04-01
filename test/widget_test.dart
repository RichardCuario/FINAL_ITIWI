import 'package:flutter_test/flutter_test.dart';
import 'package:hotline_app/main.dart';

void main() {
  testWidgets('Hotline app renders home page', (WidgetTester tester) async {
    await tester.pumpWidget(const HotlineApp());

    expect(find.text('Hotline App'), findsOneWidget);
    expect(find.text('Open Tourist Guide'), findsOneWidget);
  });
}

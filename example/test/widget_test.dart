import 'package:flutter_test/flutter_test.dart';
import 'package:pubdev_explorer/src/app.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const PubDevExplorerApp());
    await tester.pumpAndSettle();

    // Verify the app loads with the title
    expect(find.text('Pub.dev Explorer'), findsWidgets);
  });
}

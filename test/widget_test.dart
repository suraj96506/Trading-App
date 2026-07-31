// Basic smoke test for the trading app.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ticker_sim/main.dart';

void main() {
  testWidgets('App renders MarketScreen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MyApp()),
    );
    // The market screen should show 'Market' in the AppBar.
    expect(find.text('Market'), findsAtLeast(1));
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:el_dragon/pages/cart_page.dart';

void main() {
  testWidgets('Cart quantities update and the last item can be removed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CartPage(
          products: const [
            {
              'id': 1,
              'name': 'Gaming keyboard',
              'price': 1500,
              'category': 'Keyboard',
            },
          ],
          cart: const {1: 1},
        ),
      ),
    );
    expect(find.text('Gaming keyboard'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pump();
    expect(find.text('2'), findsOneWidget);
    expect(find.textContaining('3000.00'), findsNWidgets(2));
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.remove_circle_outline));
    await tester.pump();
    expect(find.text('Your cart is empty'), findsOneWidget);
    expect(find.text('Continue to checkout'), findsNothing);
  });
}

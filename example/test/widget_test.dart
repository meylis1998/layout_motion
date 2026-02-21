import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:layout_motion_example/main.dart';

void main() {
  testWidgets('App launches and shows demo selector', (tester) async {
    await tester.pumpWidget(const LayoutMotionExampleApp());
    await tester.pumpAndSettle();

    // Verify the demo selector screen renders with all demos.
    expect(find.text('layout_motion Demos'), findsOneWidget);
    expect(find.text('Basic List (Add / Remove)'), findsOneWidget);
    expect(find.text('Reorder'), findsOneWidget);
    expect(find.text('Wrap Reflow'), findsOneWidget);
    expect(find.text('Row Layout'), findsOneWidget);
  });

  testWidgets('Can navigate to Basic List demo', (tester) async {
    await tester.pumpWidget(const LayoutMotionExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Basic List (Add / Remove)'));
    await tester.pumpAndSettle();

    expect(find.text('Basic List'), findsOneWidget);
    expect(find.text('Item 1'), findsOneWidget);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 3'), findsOneWidget);
  });

  testWidgets('Basic List demo adds item on FAB tap', (tester) async {
    await tester.pumpWidget(const LayoutMotionExampleApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Basic List (Add / Remove)'));
    await tester.pumpAndSettle();

    // Tap the floating action button to add an item.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();

    expect(find.text('Item 4'), findsOneWidget);
  });
}

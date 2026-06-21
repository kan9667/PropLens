import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ghar_360/app.dart';
import 'package:ghar_360/providers/app_provider.dart';
import 'package:ghar_360/providers/comparison_provider.dart';
import 'package:ghar_360/widgets/hero_search_widget.dart';
import 'package:ghar_360/widgets/property_card.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Properties nav opens all listings with search', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => ComparisonProvider()),
        ],
        child: const Ghar360App(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 350));

    final heroSearchField = find.descendant(
      of: find.byType(HeroSearchWidget),
      matching: find.byType(TextField),
    );
    expect(heroSearchField, findsOneWidget);

    await tester.enterText(
      heroSearchField,
      '2 BHK in Gurgaon under 80 lakh with pool',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(seconds: 1));

    final propertiesNav = find.ancestor(
      of: find.text('Properties'),
      matching: find.byType(TextButton),
    );
    expect(propertiesNav, findsOneWidget);
    expect(find.byType(PropertyCard), findsWidgets);
    expect(
      find.byType(PropertyCard).evaluate().length,
      greaterThanOrEqualTo(1),
    );

    expect(find.text('Virtual Tours'), findsNothing);
    expect(find.text('All Properties'), findsNothing);

    await tester.tap(propertiesNav);
    await tester.pump();

    expect(find.text('All Properties'), findsOneWidget);
    expect(find.text('Search all properties'), findsOneWidget);
    expect(find.byType(PropertyCard), findsNWidgets(3));
    expect(find.textContaining('View all'), findsOneWidget);

    await tester.ensureVisible(find.textContaining('View all'));
    await tester.pump();
    await tester.tap(find.textContaining('View all'));
    await tester.pump();

    expect(find.byType(PropertyCard), findsWidgets);
    expect(find.byType(PropertyCard).evaluate().length, greaterThan(3));
    expect(find.textContaining('View all'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}

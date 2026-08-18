import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hubble/features/marketplace/presentation/screens/search_results_screen.dart';
import 'package:hubble/core/presentation/widgets/shimmer_loading.dart';

void main() {
  testWidgets('SearchResultsScreen shows empty state initially when no data is loaded', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SearchResultsScreen(initialQuery: 'Electrician'),
        ),
      ),
    );

    expect(find.byType(ShimmerListLoading), findsOneWidget);
    expect(find.text('Electrician'), findsOneWidget);
  });
}

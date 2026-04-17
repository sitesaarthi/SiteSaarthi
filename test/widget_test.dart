import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sitesaarthi/main.dart';

void main() {
  testWidgets('App loads successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const SiteSaarthiApp());

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
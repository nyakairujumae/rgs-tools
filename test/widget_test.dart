// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:hvac_tools_manager/main.dart';

void main() {
  // Initialize FFI for testing
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('App loads correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HvacToolsManagerApp());

    // Wait for the app to initialize and show login screen
    await tester.pumpAndSettle();

    // Verify that our app loads with the login screen elements
    // Check for email field
    expect(find.byType(TextFormField), findsWidgets);
    // Check for sign in button
    expect(find.text('Sign In'), findsOneWidget);
  });
}

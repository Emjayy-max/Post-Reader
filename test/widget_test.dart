import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:flutter_application_2/main.dart';

void main() {
  setUpAll(() async {
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);
    await Hive.openBox('favoritesBox');
  });

  testWidgets('Posts screen renders its header', (WidgetTester tester) async {
    await tester.pumpWidget(const PostReaderApp());
    await tester.pump();

    expect(find.text('Post Reader'), findsOneWidget);
    expect(find.textContaining('read today'), findsOneWidget);
    expect(find.text('New post'), findsOneWidget);
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:wealth_flow/main.dart';
import 'package:wealth_flow/models.dart';

void main() {
  setUpAll(() async {
    await Hive.initFlutter();
  });

  testWidgets('shows the wealth flow app', (tester) async {
    final storage = StorageService();
    await storage.init();
    storage.isOnboardingComplete = true;

    await tester.pumpWidget(WealthFlowApp(storage: storage));
    await tester.pumpAndSettle();

    expect(find.text('Wealth Flow'), findsWidgets);
  });
}

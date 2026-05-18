import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/main.dart';
import 'package:provider/provider.dart';
import 'package:mobile_app/providers/chat_provider.dart';

void main() {
  testWidgets('SahulatApp renders ChatScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => ChatProvider())],
        child: const SahulatApp(),
      ),
    );
    // App should render without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}

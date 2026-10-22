import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/main.dart';

void main() {
  testWidgets('Report a bug arrow expands and collapses, preserving draft',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MafiHelpCenter(language: 'es')));

    final bugTile = find.byKey(const Key('help-report-bug'));
    expect(bugTile, findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    expect(find.byIcon(Icons.expand_less), findsNothing);

    await tester.tap(bugTile);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.text('Describe lo ocurrido'), findsOneWidget);

    final reportField = find.widgetWithText(TextField, 'Describe lo ocurrido');
    await tester.ensureVisible(reportField);
    await tester.enterText(reportField, 'El botón no responde');
    await tester.pumpAndSettle();

    await tester.ensureVisible(bugTile);
    await tester.tap(bugTile);
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.expand_less), findsNothing);
    expect(find.text('El botón no responde'), findsNothing);

    await tester.tap(bugTile);
    await tester.pumpAndSettle();
    expect(find.text('El botón no responde'), findsOneWidget);
  });

  testWidgets('Switching to suggestion clears the unrelated bug draft',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MafiHelpCenter(language: 'en')));
    await tester.tap(find.byKey(const Key('help-report-bug')));
    await tester.pumpAndSettle();
    final field = find.widgetWithText(TextField, 'Describe what happened');
    await tester.ensureVisible(field);
    await tester.enterText(field, 'Bug draft');

    final ideaTile = find.byKey(const Key('help-suggest-feature'));
    await tester.ensureVisible(ideaTile);
    await tester.tap(ideaTile);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextField, 'Describe your suggestion'), findsOneWidget);
    expect(find.text('Bug draft'), findsNothing);
    expect(find.byIcon(Icons.expand_less), findsOneWidget);
  });
}

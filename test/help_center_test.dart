import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/main.dart';

void main() {
  Future<void> showHelp(WidgetTester tester, {
    String language = 'es',
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(useMaterial3: true),
      darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
      themeMode: themeMode,
      home: MafiHelpCenter(language: language),
    ));
  }

  final bug = find.byKey(const PageStorageKey<String>('help-report-bug'));
  final idea = find.byKey(const PageStorageKey<String>('help-suggest-feature'));
  final bugLocation = find.byKey(const Key('help-bug-location'));
  final bugMessage = find.byKey(const Key('help-bug-description'));
  final ideaMessage = find.byKey(const Key('help-idea-description'));

  testWidgets('Uses two independent native FAQ-style ExpansionTiles',
      (tester) async {
    await showHelp(tester);
    expect(tester.widget<ExpansionTile>(bug), isA<ExpansionTile>());
    expect(tester.widget<ExpansionTile>(idea), isA<ExpansionTile>());
    // Leave the arrow to the same native animation as FAQ (no custom trailing).
    expect(tester.widget<ExpansionTile>(bug).trailing, isNull);
    expect(tester.widget<ExpansionTile>(idea).trailing, isNull);
    expect(find.byType(ExpansionTile), findsNWidgets(6)); // 2 feedback + 4 FAQ
    expect(bugLocation, findsNothing);
    expect(bugMessage, findsNothing);
    expect(ideaMessage, findsNothing);

    await tester.tap(bug);
    await tester.pumpAndSettle();
    expect(bugMessage, findsOneWidget);
    expect(bugLocation, findsOneWidget);
    expect(ideaMessage, findsNothing);

    // The bug form must be *under its own header*, before the idea header.
    expect(tester.getTopLeft(bugMessage).dy,
        greaterThan(tester.getTopLeft(bug).dy));
    expect(tester.getTopLeft(bugMessage).dy,
        lessThan(tester.getTopLeft(idea).dy));

    await tester.ensureVisible(idea);
    await tester.tap(idea);
    await tester.pumpAndSettle();
    expect(bugMessage, findsOneWidget); // Opening idea does NOT close bug.
    expect(ideaMessage, findsOneWidget);
    expect(tester.getTopLeft(ideaMessage).dy,
        greaterThan(tester.getTopLeft(idea).dy));

    await tester.ensureVisible(bug);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    expect(bugMessage, findsNothing);
    expect(ideaMessage, findsOneWidget); // Closing bug leaves idea open.
  });

  testWidgets('Both drafts remain independent through collapse and reopen',
      (tester) async {
    await showHelp(tester);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    await tester.enterText(bugLocation, 'Pantalla de inicio');
    await tester.enterText(bugMessage, 'Error de prueba 123');
    expect(tester.widget<FilledButton>(
        find.byKey(const Key('help-send-bug'))).onPressed, isNotNull);

    await tester.ensureVisible(idea);
    await tester.tap(idea);
    await tester.pumpAndSettle();
    await tester.ensureVisible(ideaMessage);
    await tester.enterText(ideaMessage, 'Mejora de prueba 456');

    // Fold one at a time and check that the other is unaffected.
    await tester.ensureVisible(bug);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    expect(bugMessage, findsNothing);
    expect(ideaMessage, findsOneWidget);

    await tester.ensureVisible(idea);
    await tester.tap(idea);
    await tester.pumpAndSettle();
    expect(ideaMessage, findsNothing);

    await tester.ensureVisible(bug);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(bugLocation).controller!.text,
        'Pantalla de inicio');
    expect(tester.widget<TextField>(bugMessage).controller!.text,
        'Error de prueba 123');

    await tester.ensureVisible(idea);
    await tester.tap(idea);
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(ideaMessage).controller!.text,
        'Mejora de prueba 456');
  });

  testWidgets('FAQ also opens and closes without changing feedback sections',
      (tester) async {
    await showHelp(tester);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    final faq = find.widgetWithText(ExpansionTile, '¿Dónde se guardan mis datos?');
    await tester.ensureVisible(faq);
    await tester.tap(faq);
    await tester.pumpAndSettle();
    expect(find.textContaining('En este dispositivo.'), findsOneWidget);
    expect(bugMessage, findsOneWidget);

    await tester.ensureVisible(faq);
    await tester.tap(faq);
    await tester.pumpAndSettle();
    expect(find.textContaining('En este dispositivo.'), findsNothing);
    expect(bugMessage, findsOneWidget);
  });

  testWidgets('Five translations and both themes support narrow screens',
      (tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    const names = <String, List<String>>{
      'es': ['Reportar un error', 'Sugerir una función', 'Describe lo ocurrido'],
      'en': ['Report a bug', 'Suggest a feature', 'Describe what happened'],
      'fr': ['Signaler un problème', 'Suggérer une fonctionnalité', 'Décrivez le problème'],
      'de': ['Fehler melden', 'Funktion vorschlagen', 'Was ist passiert?'],
      'bn': ['সমস্যা জানান', 'নতুন ফিচারের পরামর্শ', 'কী ঘটেছে লিখুন'],
    };
    for (final mode in [ThemeMode.light, ThemeMode.dark]) {
      for (final entry in names.entries) {
        await showHelp(tester, language: entry.key, themeMode: mode);
        await tester.pumpAndSettle();
        expect(find.text(entry.value[0]), findsOneWidget);
        expect(find.text(entry.value[1]), findsOneWidget);
        await tester.tap(bug);
        await tester.pumpAndSettle();
        expect(find.text(entry.value[2]), findsOneWidget);
        expect(tester.takeException(), isNull,
            reason: 'Layout error for ${entry.key} in $mode');
        // Remounting is also expected to reset the expansion state.
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/main.dart';

void main() {
  Future<void> showHelp(
    WidgetTester tester, {
    String language = 'es',
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), useMaterial3: true),
      darkTheme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark), useMaterial3: true),
      themeMode: themeMode,
      home: MafiHelpCenter(language: language),
    ));
    await tester.pumpAndSettle();
  }

  final bug = find.byKey(const Key('help-report-bug'));
  final idea = find.byKey(const Key('help-suggest-feature'));
  final bugArrow = find.byKey(const Key('help-bug-arrow'));
  final ideaArrow = find.byKey(const Key('help-idea-arrow'));
  final bugForm = find.byKey(const Key('help-bug-form'));
  final ideaForm = find.byKey(const Key('help-idea-form'));
  final bugLocation = find.byKey(const Key('help-bug-location'));
  final bugMessage = find.byKey(const Key('help-bug-description'));
  final ideaMessage = find.byKey(const Key('help-idea-description'));

  void noUiErrors(WidgetTester tester) {
    expect(find.byType(ErrorWidget), findsNothing,
        reason: 'Flutter release would display a giant grey rectangle instead');
    expect(tester.takeException(), isNull);
  }

  testWidgets('Native FAQ preserved; feedback arrows rotate down/up independently',
      (tester) async {
    await showHelp(tester);
    expect(find.byType(ExpansionTile), findsNWidgets(4));
    expect(tester.widget<AnimatedRotation>(bugArrow).turns, 0.0);
    expect(tester.widget<AnimatedRotation>(ideaArrow).turns, 0.0);
    expect(bugForm, findsNothing);
    expect(ideaForm, findsNothing);

    await tester.tap(bug);
    await tester.pumpAndSettle();
    noUiErrors(tester);
    expect(tester.widget<AnimatedRotation>(bugArrow).turns, 0.5);
    expect(tester.widget<AnimatedRotation>(ideaArrow).turns, 0.0);
    expect(bugForm, findsOneWidget);
    expect(bugLocation, findsOneWidget);
    expect(bugMessage, findsOneWidget);
    expect(ideaForm, findsNothing);
    expect(tester.getTopLeft(bugMessage).dy,
        greaterThan(tester.getTopLeft(bug).dy));
    expect(tester.getTopLeft(bugMessage).dy,
        lessThan(tester.getTopLeft(idea).dy));

    await tester.ensureVisible(idea);
    await tester.tap(idea);
    await tester.pumpAndSettle();
    noUiErrors(tester);
    expect(tester.widget<AnimatedRotation>(bugArrow).turns, 0.5);
    expect(tester.widget<AnimatedRotation>(ideaArrow).turns, 0.5);
    expect(bugForm, findsOneWidget);
    expect(ideaForm, findsOneWidget);
    expect(tester.getTopLeft(ideaMessage).dy,
        greaterThan(tester.getTopLeft(idea).dy));

    await tester.ensureVisible(bug);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    noUiErrors(tester);
    expect(bugForm, findsNothing);
    expect(ideaForm, findsOneWidget);
    expect(tester.widget<AnimatedRotation>(bugArrow).turns, 0.0);
    expect(tester.widget<AnimatedRotation>(ideaArrow).turns, 0.5);
  });

  testWidgets('Both forms have finite layout and do not become grey placeholders',
      (tester) async {
    await showHelp(tester);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    noUiErrors(tester);
    expect(tester.getSize(find.byKey(const Key('help-bug-expand'))).height, lessThanOrEqualTo(410));
    expect(tester.getSize(bugMessage).height, lessThan(230));
    expect(find.byKey(const Key('help-send-bug')), findsOneWidget);
    await tester.ensureVisible(idea);
    await tester.tap(idea);
    await tester.pumpAndSettle();
    noUiErrors(tester);
    expect(tester.getSize(find.byKey(const Key('help-idea-expand'))).height, lessThanOrEqualTo(310));
    expect(tester.getSize(ideaMessage).height, lessThan(230));
    expect(find.byKey(const Key('help-send-idea')), findsOneWidget);
  });

  testWidgets('Closing one form preserves both independent drafts',
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
    expect(tester.widget<FilledButton>(
        find.byKey(const Key('help-send-idea'))).onPressed, isNotNull);

    await tester.ensureVisible(bug);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    expect(bugForm, findsNothing);
    expect(ideaForm, findsOneWidget);

    await tester.ensureVisible(idea);
    await tester.tap(idea);
    await tester.pumpAndSettle();
    expect(ideaForm, findsNothing);

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
    noUiErrors(tester);
  });

  testWidgets('Frequently asked questions remain native and independent',
      (tester) async {
    await showHelp(tester);
    await tester.tap(bug);
    await tester.pumpAndSettle();
    final faq = find.widgetWithText(ExpansionTile, '¿Dónde se guardan mis datos?');
    await tester.ensureVisible(faq);
    await tester.tap(faq);
    await tester.pumpAndSettle();
    expect(find.textContaining('En este dispositivo.'), findsOneWidget);
    expect(bugForm, findsOneWidget);
    await tester.ensureVisible(faq);
    await tester.tap(faq);
    await tester.pumpAndSettle();
    expect(find.textContaining('En este dispositivo.'), findsNothing);
    expect(bugForm, findsOneWidget);
    noUiErrors(tester);
  });

  testWidgets('Five translations, dark/light theme, narrow window',
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
        expect(find.text(entry.value[0]), findsOneWidget);
        expect(find.text(entry.value[1]), findsOneWidget);
        await tester.tap(bug);
        await tester.pumpAndSettle();
        expect(find.text(entry.value[2]), findsOneWidget);
        expect(tester.getSize(find.byKey(const Key('help-bug-expand'))).height, lessThanOrEqualTo(411));
        noUiErrors(tester);
        await tester.pumpWidget(const SizedBox.shrink());
      }
    }
  });
}

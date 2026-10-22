import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mafiflow/main.dart';

void main() {
  for (final language in ['es', 'en']) {
    testWidgets('Help arrows and independent drafts ($language)', (tester) async {
      await tester.pumpWidget(MaterialApp(home: MafiHelpCenter(language: language)));
      final bug = find.byKey(const Key('help-report-bug'));
      final idea = find.byKey(const Key('help-suggest-feature'));
      void expectArrow(Finder tile, IconData icon) {
        expect(find.descendant(of: tile, matching: find.byIcon(icon)), findsOneWidget);
      }
      Future<void> toggle(Finder tile) async {
        await tester.ensureVisible(tile);
        await tester.tap(tile);
        await tester.pumpAndSettle();
      }
      Future<void> enter(String label, String text) async {
        final field = find.widgetWithText(TextField, label);
        await tester.ensureVisible(field);
        await tester.enterText(field, text);
        await tester.pumpAndSettle();
      }
      final bugLabel = language == 'es' ? 'Describe lo ocurrido' : 'Describe what happened';
      final ideaLabel = language == 'es' ? 'Describe tu sugerencia' : 'Describe your suggestion';
      final locationLabel = language == 'es' ? '¿Dónde ocurrió?' : 'Where did it happen?';
      expectArrow(bug, Icons.expand_more);
      expectArrow(idea, Icons.expand_more);
      await toggle(bug);
      expectArrow(bug, Icons.expand_less);
      expectArrow(idea, Icons.expand_more);
      await enter(locationLabel, 'Dashboard');
      await enter(bugLabel, 'Bug draft');
      await toggle(bug);
      expectArrow(bug, Icons.expand_more);
      expect(find.byType(TextField), findsNothing);
      await toggle(bug);
      expect(find.text('Bug draft'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      await toggle(idea);
      expectArrow(bug, Icons.expand_more);
      expectArrow(idea, Icons.expand_less);
      expect(find.text('Bug draft'), findsNothing);
      expect(tester.widget<TextField>(find.widgetWithText(TextField, ideaLabel)).controller!.text, isEmpty);
      await enter(ideaLabel, 'Idea draft');
      await toggle(idea);
      expectArrow(idea, Icons.expand_more);
      expect(find.byType(TextField), findsNothing);
      await toggle(idea);
      expect(find.text('Idea draft'), findsOneWidget);
      await toggle(bug);
      expectArrow(bug, Icons.expand_less);
      expectArrow(idea, Icons.expand_more);
      expect(find.text('Bug draft'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Idea draft'), findsNothing);
      await toggle(idea);
      expect(find.text('Idea draft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}

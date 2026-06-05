import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/settings_flutter.dart';
import 'package:taminations/sequencer/danceability_resolve_dialog.dart';

// Harness: a button that opens the dialog and reports its result via [onResult].
Widget _harness(void Function(bool?) onResult) =>
    MaterialApp(home: Scaffold(body: Builder(builder: (context) =>
        ElevatedButton(
          onPressed: () async {
            onResult(await showDialog<bool>(
                context: context, builder: (_) => DanceabilityResolveDialog()));
          },
          child: const Text('open')))));

void main() {
  testWidgets('Go saves the shown (seeded) values and returns true', (tester) async {
    Settings.mockInit();
    Settings.danceabilityThreshold = 40; // non-default, on the 0..100 step-5 grid
    bool? result;
    await tester.pumpWidget(_harness((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(Settings.danceabilityThreshold, 40); // seeded 40 → saved 40
  });

  testWidgets('Reset restores SC defaults, then Go saves them', (tester) async {
    Settings.mockInit();
    Settings.danceabilityThreshold = 40;
    bool? result;
    await tester.pumpWidget(_harness((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Go'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
    expect(Settings.danceabilityThreshold, 60); // reset → default 60 → saved
  });

  testWidgets('Cancel returns false and writes nothing', (tester) async {
    Settings.mockInit();
    Settings.danceabilityThreshold = 40;
    bool? result;
    await tester.pumpWidget(_harness((r) => result = r));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(result, isFalse);
    expect(Settings.danceabilityThreshold, 40); // unchanged
  });
}

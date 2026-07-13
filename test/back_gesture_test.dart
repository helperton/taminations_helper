/*

  Taminations Square Dance Animations
  Copyright (C) 2026 Brad Christie

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/

//  The sequencer's timeline slider runs the full width of the window. Flutter's DEFAULT macOS
//  page transition (Cupertino) hangs a drag-to-pop gesture on the window's left edge, so with the
//  thumb at the far left, dragging the slider popped the page instead of moving the thumb — the
//  page slid off to the right and the one underneath showed through.
//
//  These tests pin both halves: that the gesture is real (it pops with the default theme), and
//  that TaminationsApp's theme removes it.

import 'package:flutter/material.dart' as fm;
import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/main.dart';

void main() {
  //  A left-edge drag to the right — a caller grabbing the slider thumb at beat 0.
  Future<void> dragFromLeftEdge(WidgetTester tester) async {
    await tester.dragFrom(const fm.Offset(5, 300), const fm.Offset(400, 0));
    await tester.pumpAndSettle();
  }

  fm.Widget twoPageApp({fm.ThemeData? theme}) {
    return fm.MaterialApp(
      theme: theme,
      home: fm.Builder(
        builder: (context) => fm.Scaffold(
          body: fm.Center(
            child: fm.ElevatedButton(
              onPressed: () => fm.Navigator.of(context).push(
                fm.MaterialPageRoute(
                  builder: (_) => const fm.Scaffold(body: fm.Center(child: fm.Text('SEQUENCER'))),
                ),
              ),
              child: const fm.Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openTheSequencer(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('SEQUENCER'), findsOneWidget);
  }

  testWidgets('the bug: with the default macOS theme, a left-edge drag pops the page',
      (tester) async {
    await tester.pumpWidget(twoPageApp());
    await openTheSequencer(tester);

    await dragFromLeftEdge(tester);

    //  The page was dragged away — this is what was happening to the slider.
    expect(find.text('SEQUENCER'), findsNothing);
  }, variant: TargetPlatformVariant.only(fm.TargetPlatform.macOS));

  testWidgets('with TaminationsApp\'s theme, the same drag leaves the page alone',
      (tester) async {
    await tester.pumpWidget(twoPageApp(
      theme: fm.ThemeData(pageTransitionsTheme: TaminationsAppTransitions.desktop),
    ));
    await openTheSequencer(tester);

    await dragFromLeftEdge(tester);

    //  The drag belongs to whatever is under the pointer — the slider — not to the Navigator.
    expect(find.text('SEQUENCER'), findsOneWidget);
  }, variant: TargetPlatformVariant.only(fm.TargetPlatform.macOS));
}

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

//  Mid-sequence editing: insert a call above/below another, or delete one.
//  Every call after the edit is re-interpreted against the formation the edit leaves
//  behind, so these tests pin BOTH outcomes: a good edit takes, and an edit that breaks
//  a later call is refused with the sequence left exactly as it was.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';

void main() async {

  //  This is necessary else the 1st test crashes
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };

  Future<SequencerModel> sequence(String calls) async {
    Settings.mockInit();
    final model = SequencerModel();
    model.setStartingFormation('Static Square');
    await model.paste(calls);
    return model;
  }

  testWidgets('delete removes a middle call and re-runs the ones after it', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Square Thru
Swing Thru
Swing Thru
Boys Run
Ferris Wheel''');
      expect(model.callNames.length, 5);

      final failed = model.deleteCallAt(2);   //  the second Swing Thru

      expect(failed, isNull);
      expect(model.callNames,
          ['Heads Square Thru', 'Swing Thru', 'Boys Run', 'Ferris Wheel']);
      expect(model.errorString, '');
    });
  });

  testWidgets('a delete that breaks a later call is refused, sequence unchanged', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Pass the Ocean
Extend
Swing Thru''');
      expect(model.callNames.length, 3);
      final before = model.callNames;

      //  Extend has nothing to extend from a squared set.
      final failed = model.deleteCallAt(0);

      expect(failed, isNotNull);
      expect(model.callNames, before, reason: 'a refused edit must change nothing');
    });
  });

  testWidgets('a delete whose call sets up the NEXT one is refused', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Star Thru
Double Pass Thru
Centers In
Cast Off Three Quarters''');
      final before = model.callNames;

      //  Cast Off Three Quarters has nothing to cast off without Centers In.
      final failed = model.deleteCallAt(2);

      expect(failed, 'Cast Off Three Quarters');
      expect(model.callNames, before, reason: 'a refused edit must change nothing');
    });
  });

  testWidgets('insert above puts the call before the one right-clicked', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Square Thru
Swing Thru
Boys Run''');

      //  Right-clicked Boys Run (index 2), inserting above it.
      final failed = model.insertCallAt(2, 'Swing Thru');

      expect(failed, isNull);
      expect(model.callNames,
          ['Heads Square Thru', 'Swing Thru', 'Swing Thru', 'Boys Run']);
    });
  });

  testWidgets('insert below puts the call after the one right-clicked', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Square Thru
Swing Thru''');

      //  Right-clicked Swing Thru (index 1), inserting below it.
      final failed = model.insertCallAt(2, 'Boys Run');

      expect(failed, isNull);
      expect(model.callNames, ['Heads Square Thru', 'Swing Thru', 'Boys Run']);
    });
  });

  testWidgets('an insert that breaks the call below it is refused', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Pass the Ocean
Extend''');
      final before = model.callNames;

      //  After a Square Thru the heads can no longer Pass the Ocean.
      final failed = model.insertCallAt(0, 'Heads Square Thru');

      expect(failed, 'Heads Pass the Ocean');
      expect(model.callNames, before, reason: 'a refused edit must change nothing');
    });
  });

  testWidgets('an insert that does not work there is refused, sequence unchanged', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Star Thru
Double Pass Thru''');
      final before = model.callNames;

      //  Nothing to extend from a squared set.
      final failed = model.insertCallAt(0, 'Extend');

      expect(failed, isNotNull);
      expect(model.callNames, before, reason: 'a refused edit must change nothing');
    });
  });

  testWidgets('rebuildSequence restores a previous sequence (the Undo path)', (tester) async {
    await tester.runAsync(() async {
      final model = await sequence('''Heads Star Thru
Double Pass Thru
Centers In''');
      final before = model.callNames;

      expect(model.deleteCallAt(2), isNull);
      expect(model.callNames.length, 2);

      expect(model.rebuildSequence(before), isNull);
      expect(model.callNames, before);
    });
  });

}

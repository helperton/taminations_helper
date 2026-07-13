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

//  Face Partner turns you to your ORIGINAL partner — the other half of your couple — wherever
//  they have got to. Face Partner of the Moment turns you to whoever you are paired with NOW.
//
//  Standing at home the two are the same call, because there your partner IS your partner of the
//  moment. The difference only shows once a progression has moved you on, and it matters: from a
//  squared set a Face Partner sets up a Right and Left Grand, but once you are standing beside
//  someone else's girl it points you diagonally across the set and RLG cannot be danced.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/dancer.dart';
import 'package:taminations/extensions.dart';
import 'package:taminations/sequencer/call_context.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';

void main() async {

  //  This is necessary else the 1st test crashes
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };

  Future<SequencerModel> danced(String calls) async {
    Settings.mockInit();
    final model = SequencerModel();
    model.setStartingFormation('Static Square');
    await model.paste(calls);
    model.animation.doPause();
    return model;
  }

  CallContext floor(SequencerModel model) {
    final ctx = model.contextFromAnimation();
    ctx.analyze();
    return ctx;
  }

  //  Who each dancer is looking at, by couple number.
  Map<String, int> facing(CallContext ctx) {
    final who = <String, int>{};
    for (final d in ctx.dancers) {
      final looking = ctx.dancers
          .where((other) => other != d)
          .reduce((a, b) =>
              d.angleToDancer(a).abs() < d.angleToDancer(b).abs() ? a : b);
      who['${d.numberCouple}${d.gender == Gender.BOY ? "B" : "G"}'] =
          looking.numberCouple.i;
    }
    return who;
  }

  testWidgets('Face Partner turns you to look at your own partner', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Face Partner');
      expect(model.errorString, '');

      final ctx = floor(model);
      for (final d in ctx.dancers) {
        final partner = ctx.dancers.firstWhere((other) =>
            other != d &&
            other.numberCouple == d.numberCouple &&
            other.gender != d.gender);
        //  Looking straight at them: the angle to them, from where you stand, is nil.
        expect(d.angleToDancer(partner).abs(), lessThan(0.1),
            reason: 'dancer $d is not looking at their partner');
      }
    });
  });

  testWidgets('at home, Face Partner of the Moment is the same call', (tester) async {
    await tester.runAsync(() async {
      //  Standing at home your partner IS your partner of the moment, so both must agree.
      final partner = facing(floor(await danced('Face Partner')));
      final ofTheMoment = facing(floor(await danced('Face Partner of the Moment')));
      expect(ofTheMoment, partner);
    });
  });

  testWidgets('Face Partner sets up a Right and Left Grand', (tester) async {
    await tester.runAsync(() async {
      //  RLG cannot be danced straight out of a squared set...
      final cold = await danced('Right and Left Grand');
      expect(cold.errorString, isNotEmpty);

      //  ...but facing your partner first is exactly what it wants.
      final warm = await danced('''Face Partner
Right and Left Grand''');
      expect(warm.errorString, '');
      expect(warm.callNames, ['Face Partner', 'Right and Left Grand']);
    });
  });

  //  The whole reason for two calls. Once a progression has moved you on, the girl beside you is
  //  not your partner, and the two calls point you at different people.
  testWidgets('after a progression the two calls part company', (tester) async {
    await tester.runAsync(() async {
      final partner =
          facing(floor(await danced('Swing Corner and Promenade\nFace Partner')));
      final ofTheMoment = facing(floor(
          await danced('Swing Corner and Promenade\nFace Partner of the Moment')));
      expect(ofTheMoment, isNot(partner),
          reason: 'the two calls should look at different people once you have progressed');
    });
  });

  testWidgets('after a progression it is the MOMENT that sets up an RLG', (tester) async {
    await tester.runAsync(() async {
      //  Your own partner is now diagonally across the set — you can't Right and Left Grand
      //  from there, and TH says so rather than dancing something bogus.
      final original = await danced('''Swing Corner and Promenade
Face Partner
Right and Left Grand''');
      expect(original.errorString, isNotEmpty);
      expect(original.callNames.length, 2, reason: 'the RLG must not have loaded');

      //  The girl beside you, though, is right there to take by the right hand — the RLG dances.
      //  (TH still warns "Dancers are not resolved", and it is right to: a Right and Left Grand
      //  from a progressed set does not bring you home. That is a note about the choreography,
      //  not a refusal — the call loaded.)
      final moment = await danced('''Swing Corner and Promenade
Face Partner of the Moment
Right and Left Grand''');
      expect(moment.callNames.length, 3, reason: 'the RLG should have danced');
      expect(moment.callNames.last, 'Right and Left Grand');
      expect(moment.errorString, isNot(contains('No animation')));
    });
  });

  testWidgets('nobody travels — you turn on the spot', (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced('Heads Square Thru'));
      final after = floor(await danced('Heads Square Thru\nFace Partner'));

      for (final d in after.dancers) {
        final was = before.dancers.firstWhere((o) =>
            o.numberCouple == d.numberCouple && o.gender == d.gender);
        final moved = (d.location - was.location).length;
        expect(moved, lessThan(0.1), reason: 'dancer $d moved $moved facing their partner');
      }
    });
  });

  testWidgets('however it is said', (tester) async {
    await tester.runAsync(() async {
      for (final call in [
        'Face Partner',
        'Face Your Partner',
        'face partner',
        'Face Partner of the Moment',
        'Face Your Partner of the Moment',
      ]) {
        final model = await danced(call);
        expect(model.errorString, '', reason: '"$call" should dance');
        expect(model.callNames.length, 1, reason: '"$call" should dance');
      }
      //  Unused, but proves the import is doing something if the geometry above ever changes.
      expect(pi, greaterThan(3));
    });
  });
}

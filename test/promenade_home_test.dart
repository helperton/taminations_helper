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

//  The two ways a singing call ends. They are the same call but for who the girls end up with:
//  Corner sends each girl on to the next couple, Partner leaves her with the one she has.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/dancer.dart';
import 'package:taminations/extensions.dart';
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

  testWidgets('Swing Partner and Promenade dances', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Swing Partner and Promenade');
      expect(model.errorString, '');
      expect(model.callNames.length, 1);
    });
  });

  testWidgets('however it is said', (tester) async {
    await tester.runAsync(() async {
      for (final call in [
        'Swing Partner and Promenade',
        'swing your partner and promenade',
        'Swing Your Partner And Promenade Home',
      ]) {
        final model = await danced(call);
        expect(model.errorString, '', reason: '"$call" should dance');
        expect(model.callNames.length, 1, reason: '"$call" should dance');
      }
    });
  });

  testWidgets('the Corner ending still dances', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Swing Corner and Promenade');
      expect(model.errorString, '');
      expect(model.callNames.length, 1);
    });
  });

  testWidgets('Promenade Home still dances', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Promenade Home');
      expect(model.errorString, '');
      expect(model.callNames.length, 1);
    });
  });

  //  Promenade on its own is still not a thing — the guard that lets Partner through must not have
  //  opened the door to everything else.
  testWidgets('a bare Promenade is still refused', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Promenade');
      expect(model.errorString, isNotEmpty);
    });
  });

  ///  Who each boy is standing beside when the music stops. THIS is the whole difference between
  ///  the two endings, so it is what the test looks at.
  ///
  ///  Called from a squared set, where each boy has BOTH his partner (beside him) and his corner
  ///  (the girl on his other side) to hand — so either ending resolves, and the only thing that
  ///  decides who he ends up with is the call.
  Future<Map<int, int>> girlBesideEachBoy(String ending) async {
    final model = await danced(ending);
    expect(model.errorString, '', reason: '"$ending" should dance');

    final ctx = model.contextFromAnimation();
    ctx.analyze();
    final girls = ctx.dancers.where((d) => d.gender == Gender.GIRL).toList();
    return {
      for (final boy in ctx.dancers.where((d) => d.gender == Gender.BOY))
        boy.numberCouple.i: girls
            .reduce((a, b) => (a.location - boy.location).length <
                    (b.location - boy.location).length
                ? a
                : b)
            .numberCouple.i
    };
  }

  testWidgets('Swing PARTNER ends each boy beside his own girl', (tester) async {
    await tester.runAsync(() async {
      final beside = await girlBesideEachBoy('Swing Partner and Promenade');
      expect(beside, {1: 1, 2: 2, 3: 3, 4: 4});
    });
  });

  testWidgets('Swing CORNER sends each girl on to the next couple', (tester) async {
    await tester.runAsync(() async {
      final beside = await girlBesideEachBoy('Swing Corner and Promenade');
      //  Not his own — that is the progression a singing call runs on.
      for (final entry in beside.entries) {
        expect(entry.value, isNot(entry.key),
            reason: 'boy ${entry.key} ended beside girl ${entry.value} — his own partner');
      }
    });
  });
}

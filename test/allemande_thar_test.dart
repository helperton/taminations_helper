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

//  Allemande Left to an Allemande Thar from a ring, as Go Forward leaves it: each man facing
//  a lady. They turn half by the left, which leaves the men inside, and the men step in to a
//  right-hand star with the ladies on the outside holding their left hands.
//
//  A thar drawn from a Static Square has the men one unit from the center and the ladies
//  three. Angles count counter-clockwise, so a man with the center on his right faces 90
//  degrees clockwise of the line out from the center through him, and a lady 90 degrees
//  counter-clockwise of it.

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
    final ctx = model.contextFromCurrentFormation();
    ctx.analyze();
    return ctx;
  }

  const ring = 'Allemande Left to an Allemande Thar\nShoot the Star\nGo Forward 2';
  const thar = '$ring\nAllemande Left to an Allemande Thar';

  void expectThar(CallContext ctx) {
    for (final d in ctx.dancers) {
      final out = d.location.angle;
      if (d.gender == Gender.BOY) {
        expect(d.location.length.isAround(1.0), isTrue,
            reason: 'man $d is ${d.location.length} from the center, not 1');
        expect(d.angleFacing.angleDiff(out - pi/2).isAround(0.0), isTrue,
            reason: 'man $d does not have the center on his right');
      } else {
        expect(d.location.length.isAround(3.0), isTrue,
            reason: 'lady $d is ${d.location.length} from the center, not 3');
        expect(d.angleFacing.angleDiff(out + pi/2).isAround(0.0), isTrue,
            reason: 'lady $d is not facing the other way to the men');
      }
    }
  }

  testWidgets('after Go Forward 2, the men step in to a star with the ladies outside',
      (tester) async {
    await tester.runAsync(() async {
      final model = await danced(thar);
      expect(model.errorString, '');
      expect(model.calls.length, 4);
      expectThar(floor(model));
    });
  });

  testWidgets('each lady holds the left hand of the man she was facing', (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced(ring));
      final after = floor(await danced(thar));
      for (final d in after.dancers.where((d) => d.gender == Gender.BOY)) {
        final faced = before.dancerFacing(before.dancers.firstWhere((o) => o == d))!;
        final lady = after.dancers.firstWhere((o) => o == faced);
        expect(lady.location.isAbout(d.location * 3.0), isTrue,
            reason: 'lady $lady is not just outside man $d');
      }
    });
  });

  //  Every hand of Go Forward lets go, so the left hand is free whatever the number
  testWidgets('it works after any Go Forward', (tester) async {
    await tester.runAsync(() async {
      for (final n in [1, 3]) {
        final model = await danced('Allemande Left to an Allemande Thar\nShoot the Star\n'
            'Go Forward $n\nAllemande Left to an Allemande Thar');
        expect(model.errorString, '', reason: 'after Go Forward $n');
        expectThar(floor(model));
      }
    });
  });

  //  Go Forward N to an Allemande Thar: the Nth hand is not a pull by but the left hand
  //  turning into the thar, so it dances the same as one hand fewer of Go Forward and then
  //  Allemande Left to an Allemande Thar.
  const star = 'Allemande Left to an Allemande Thar\nShoot the Star';

  Future<void> expectSameFloor(String calls, String sameAs) async {
    final got = floor(await danced(calls));
    final want = floor(await danced(sameAs));
    for (final d in got.dancers) {
      final w = want.dancers.firstWhere((o) => o == d);
      expect(d.location.isAbout(w.location), isTrue,
          reason: 'dancer $d is at ${d.location}, not ${w.location}');
    }
  }

  testWidgets('Go Forward 2 to an Allemande Thar turns into the thar on the second hand',
      (tester) async {
    await tester.runAsync(() async {
      final model = await danced('$star\nGo Forward 2 to an Allemande Thar');
      expect(model.errorString, '');
      expect(model.calls.length, 3);
      expectThar(floor(model));
      await expectSameFloor('$star\nGo Forward 2 to an Allemande Thar',
          '$star\nGo Forward 1\nAllemande Left to an Allemande Thar');
    });
  });

  testWidgets('Go Forward 4 to an Allemande Thar turns into the thar on the fourth hand',
      (tester) async {
    await tester.runAsync(() async {
      await expectSameFloor('$star\nGo Forward 4 to an Allemande Thar',
          '$star\nGo Forward 3\nAllemande Left to an Allemande Thar');
    });
  });

  //  Typed on one line; pasting splits a line at its commas
  testWidgets('it can be called as Go Forward 2, Allemande Thar', (tester) async {
    await tester.runAsync(() async {
      final model = await danced(star);
      model.loadOneCall('Go Forward 2, Allemande Thar');
      model.animation.doPause();
      expect(model.errorString, '');
      expect(model.calls.length, 3);
      expectThar(floor(model));
    });
  });

  testWidgets('the thar hand is the left, so the number must be even', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('$star\nGo Forward 3 to an Allemande Thar');
      expect(model.errorString, contains('the number must be even'));
    });
  });

  testWidgets('the men can back up the star, and shoot it again', (tester) async {
    await tester.runAsync(() async {
      expect((await danced('$thar\nAllemande Thar')).errorString, '');
      expect((await danced('$thar\nShoot the Star')).errorString, '');
    });
  });

  testWidgets('from a Static Square it is still the drawn animation', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Allemande Left to an Allemande Thar');
      expect(model.errorString, '');
      expectThar(floor(model));
    });
  });

  //  A Right Pull By on its own leaves everyone on the ring facing along it, nobody in front
  testWidgets('it needs each man facing a lady', (tester) async {
    await tester.runAsync(() async {
      final model = await danced(
          'Allemande Left\nRight Pull By\nAllemande Left to an Allemande Thar');
      expect(model.errorString,
          contains('Allemande Left to an Allemande Thar needs each man facing a lady'));
    });
  });

}

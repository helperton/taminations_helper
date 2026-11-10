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

//  Go Forward N: N hands of a Right and Left Grand around the ring, starting with the right.
//
//  After an Allemande Left the eight dancers stand on a ring at (±3,±1) and (±1,±3), each
//  facing the dancer they will pull by. Two spots along that ring is a quarter turn round
//  the center, and four is half way round.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/dancer.dart';
import 'package:taminations/math/hands.dart';
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

  Dancer same(CallContext ctx, Dancer d) => ctx.dancers.firstWhere(
      (o) => o.numberCouple == d.numberCouple && o.gender == d.gender);

  const ring = 'Allemande Left';

  //  Everyone squarely faces a dancer who squarely faces them back, ready for the next hand.
  void expectFacingPairs(CallContext ctx) {
    for (final d in ctx.dancers) {
      final d2 = ctx.dancerFacing(d);
      expect(d2, isNotNull, reason: 'dancer $d is not facing anyone');
      expect(ctx.dancerFacing(d2!), d, reason: 'dancer $d2 is not facing back at $d');
    }
  }

  //  Every dancer has gone [turn] radians round the center, boys one way and girls the other.
  void expectWentRound(CallContext before, CallContext after, double turn) {
    double? boysWay;
    for (final d in after.dancers) {
      final was = same(before, d).location;
      final way = d.location.isAbout(was.rotate(turn)) ? 1.0
          : d.location.isAbout(was.rotate(-turn)) ? -1.0
          : fail('dancer $d went from $was to ${d.location}, not $turn round the ring');
      if (d.gender == Gender.BOY)
        expect(boysWay ??= way, way, reason: 'boys went different ways round');
    }
    for (final d in after.dancers.where((d) => d.gender == Gender.GIRL)) {
      final was = same(before, d).location;
      expect(d.location.isAbout(was.rotate(-boysWay! * turn)), isTrue,
          reason: 'girl $d went the same way round as the boys');
    }
  }

  testWidgets('Go Forward 1 swaps places with the dancer you face', (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced(ring));
      final model = await danced('$ring\nGo Forward 1');
      expect(model.errorString, '');
      final after = floor(model);
      for (final d in after.dancers) {
        final faced = before.dancerFacing(same(before, d))!;
        expect(d.location.isAbout(faced.location), isTrue,
            reason: 'dancer $d is not where $faced was');
      }
      expectFacingPairs(after);
    });
  });

  testWidgets('Go Forward 2 goes a quarter of the way round, facing the next dancer',
      (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced(ring));
      final model = await danced('$ring\nGo Forward 2');
      expect(model.errorString, '');
      final after = floor(model);
      expectWentRound(before, after, pi/2);
      expectFacingPairs(after);
    });
  });

  testWidgets('Go Forward 4 meets your partner half way round', (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced(ring));
      final model = await danced('$ring\nGo Forward 4');
      expect(model.errorString, '');
      final after = floor(model);
      expectWentRound(before, after, pi);
      for (final d in after.dancers)
        expect(after.dancerFacing(d)!.numberCouple, d.numberCouple,
            reason: 'dancer $d is not facing their partner');
    });
  });

  //  After Shoot the Star everyone is on a ring facing along it, about 22 degrees off a
  //  straight line to the dancer they meet. They square up as they step in.
  testWidgets('from a ring facing along the curve, as Shoot the Star leaves it', (tester) async {
    await tester.runAsync(() async {
      const thar = 'Allemande Left to an Allemande Thar\nShoot the Star';
      final before = floor(await danced(thar));
      final model = await danced('$thar\nGo Forward 2');
      expect(model.errorString, '');
      final after = floor(model);
      expectWentRound(before, after, pi/2);
      expectFacingPairs(after);
    });
  });

  testWidgets('the first hand is the right, then the left', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('$ring\nGo Forward 2');
      expect(model.errorString, '');
      for (final d in model.animation.dancers) {
        final moves = d.path.movelist;
        final hands = moves.sublist(moves.length - 4).map((m) => m.hands).toList();
        expect(hands, [Hands.RIGHTHAND, Hands.RIGHTHAND, Hands.LEFTHAND, Hands.LEFTHAND],
            reason: 'dancer $d used the wrong hands');
      }
    });
  });

  testWidgets('the number can be spelled out', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('$ring\ngo forward two');
      expect(model.errorString, '');
      expect(model.calls.length, 2);
    });
  });

  testWidgets('it needs dancers facing each other round a ring', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Go Forward 2');
      expect(model.errorString, contains('Go Forward needs everyone on a ring'));
      expect(model.calls, isEmpty);
    });
  });

}

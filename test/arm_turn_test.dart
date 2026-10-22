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

//  Right / Left Arm Turn (1/2 when no amount is given), Allemande Right (the mirror of
//  Allemande Left), and Star Right / Star Left as another way of saying Right / Left Hand Star.
//
//  Angles count counter-clockwise, so a right arm turn swings everyone's facing clockwise:
//  -90 degrees for each quarter, and a left arm turn +90.

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

  Dancer same(CallContext ctx, Dancer d) => ctx.dancers.firstWhere(
      (o) => o.numberCouple == d.numberCouple && o.gender == d.gender);

  //  Every dancer's facing turned by [turn] radians between the two floors.
  void expectTurned(CallContext before, CallContext after, double turn) {
    for (final d in after.dancers) {
      final was = same(before, d);
      expect(d.angleFacing.angleDiff(was.angleFacing).isAround(turn), isTrue,
          reason: 'dancer $d turned ${d.angleFacing.angleDiff(was.angleFacing)}, expected $turn');
    }
  }

  //  Everyone finishes holding on in a mini-wave with the named hand.
  void expectMiniWaves(CallContext ctx, {required bool left}) {
    for (final d in ctx.dancers) {
      final d2 = left ? ctx.dancerToLeft(d) : ctx.dancerToRight(d);
      expect(d2 != null && ctx.isInWave(d, d2), isTrue,
          reason: 'dancer $d is not holding ${left ? 'left' : 'right'} hands in a mini-wave');
    }
  }

  Dancer partnerOf(CallContext ctx, Dancer d) => ctx.dancers.firstWhere((o) =>
      o.gender != d.gender && o.numberCouple == d.numberCouple);

  //  A boy's corner is the girl of the couple before his, a girl's the boy after hers.
  Dancer cornerOf(CallContext ctx, Dancer d) => ctx.dancers.firstWhere((o) =>
      o.gender != d.gender &&
      (d.gender == Gender.BOY
          ? o.numberCouple.i == (d.numberCouple.i + 2) % 4 + 1
          : o.numberCouple.i == d.numberCouple.i % 4 + 1));

  //  Allemande Left leaves you squarely facing your partner, your corner diagonally behind.
  //  Its mirror leaves you squarely facing your corner, your partner diagonally behind.
  void expectMirrorOfAllemandeLeft(CallContext ctx) {
    for (final d in ctx.dancers) {
      expect(d.angleToDancer(cornerOf(ctx, d)).abs(), lessThan(0.1),
          reason: 'dancer $d is not squarely facing their corner');
      expect(d.angleToDancer(partnerOf(ctx, d)).abs().isAbout(3*pi/4), isTrue,
          reason: 'dancer $d does not have their partner diagonally behind');
    }
  }

  //  Partners face each other after an Allemande Left — where a Right Arm Turn would be called.
  const facingPartners = 'Allemande Left';

  testWidgets('after an Allemande Left, Right Arm Turn is its mirror: squarely facing your corner',
      (tester) async {
    await tester.runAsync(() async {
      final model = await danced('$facingPartners\nRight Arm Turn');
      expect(model.errorString, '');
      expectMirrorOfAllemandeLeft(floor(model));
    });
  });

  testWidgets('outside a squared set the 1/2 dances just like Turn Thru', (tester) async {
    await tester.runAsync(() async {
      const box = 'Heads Square Thru 4';
      final armTurn = floor(await danced('$box\nRight Arm Turn'));
      final turnThru = floor(await danced('$box\nTurn Thru'));
      for (final d in armTurn.dancers) {
        final t = same(turnThru, d);
        expect(d.location.isAbout(t.location) && d.angleFacing.isAround(t.angleFacing), isTrue,
            reason: 'dancer $d differs between Right Arm Turn and Turn Thru');
      }
    });
  });

  testWidgets('with no amount it is the same as 1/2', (tester) async {
    await tester.runAsync(() async {
      final bare = floor(await danced('$facingPartners\nRight Arm Turn'));
      final half = floor(await danced('$facingPartners\nRight Arm Turn 1/2'));
      for (final d in bare.dancers) {
        final h = same(half, d);
        expect(d.location.isAbout(h.location) && d.angleFacing.isAround(h.angleFacing), isTrue,
            reason: 'dancer $d differs between Right Arm Turn and Right Arm Turn 1/2');
      }
    });
  });

  //  Mini-waves on the grid, where every quarter is a clean 90 degrees. (From the ring after an
  //  Allemande Left, TH draws a 1/4 or 3/4 in its squared-set convention — the ring bent round,
  //  dancers angled 22.5 degrees off square — so exact angles are checked here instead.)
  const rightWaves = 'Heads Square Thru 4\nStep to a Wave';
  const leftWaves = 'Heads Square Thru 4\nStep to a Left Hand Wave';

  testWidgets('3/4 turns three quarters', (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced(rightWaves));
      final model = await danced('$rightWaves\nRight Arm Turn 3/4');
      expect(model.errorString, '');
      expectTurned(before, floor(model), -3*pi/2);
      expectMiniWaves(floor(model), left: false);
    });
  });

  testWidgets('1/4 from a right-hand mini-wave', (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced(rightWaves));
      final model = await danced('$rightWaves\nRight Arm Turn 1/4');
      expect(model.errorString, '');
      expectTurned(before, floor(model), -pi/2);
    });
  });

  testWidgets('Left Arm Turn goes the other way, with left hands', (tester) async {
    await tester.runAsync(() async {
      final before = floor(await danced(leftWaves));
      final model = await danced('$leftWaves\nLeft Arm Turn 3/4');
      expect(model.errorString, '');
      final after = floor(model);
      expectTurned(before, after, 3*pi/2);
      expectMiniWaves(after, left: true);
    });
  });

  testWidgets('every amount dances from facing partners after an Allemande Left',
      (tester) async {
    await tester.runAsync(() async {
      for (final call in [
        'Right Arm Turn', 'Right Arm Turn 1/2', 'Right Arm Turn 3/4',
        'Left Arm Turn', 'Left Arm Turn 3/4',
      ]) {
        final model = await danced('$facingPartners\n$call');
        expect(model.errorString, '', reason: '"$call" should dance');
        expect(model.callNames.length, 2, reason: '"$call" should dance');
      }
    });
  });

  testWidgets('the wrong hand is refused, not danced', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Heads Square Thru 4\nStep to a Left Hand Wave\nRight Arm Turn 1/4');
      expect(model.errorString, isNotEmpty);
      expect(model.callNames.length, 2, reason: 'the arm turn must not have loaded');
    });
  });

  testWidgets('an arm turn is Mainstream', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('$facingPartners\nRight Arm Turn');
      expect(model.calls.last.level?.name, 'Mainstream');
    });
  });

  testWidgets('Allemande Right mirrors Allemande Left', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Allemande Right');
      expect(model.errorString, '');
      expect(model.calls.last.level?.name, 'Mainstream');
      expectMirrorOfAllemandeLeft(floor(model));
    });
  });

  testWidgets('Allemande Right sets up an Allemande Left', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Allemande Right\nAllemande Left');
      expect(model.errorString, '');
      expect(model.callNames, ['Allemande Right', 'Allemande Left']);
    });
  });

  //  The reference the mirror is measured against.
  testWidgets('Allemande Left: squarely facing your partner, corner diagonally behind',
      (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Allemande Left');
      expect(model.errorString, '');
      final ctx = floor(model);
      for (final d in ctx.dancers) {
        expect(d.angleToDancer(partnerOf(ctx, d)).abs(), lessThan(0.1),
            reason: 'dancer $d is not squarely facing their partner');
        expect(d.angleToDancer(cornerOf(ctx, d)).abs().isAbout(3*pi/4), isTrue,
            reason: 'dancer $d does not have their corner diagonally behind');
      }
    });
  });

  testWidgets('Star Right and Star Left are Right and Left Hand Star', (tester) async {
    await tester.runAsync(() async {
      for (final (said, meant) in [
        ('Heads Star Right', 'Heads Right Hand Star'),
        ('Heads Star Left', 'Heads Left Hand Star'),
        ('Heads Star Right 3/4', 'Heads Right Hand Star 3/4'),
      ]) {
        final a = await danced(said);
        final official = await danced(meant);
        expect(a.callNames.length, 1, reason: '"$said" should dance');
        //  Same notes as the official wording, too (Heads stars note "Assuming Do Your Part").
        expect(a.errorString, official.errorString);
        final b = floor(official);
        for (final d in floor(a).dancers) {
          final m = same(b, d);
          expect(d.location.isAbout(m.location) && d.angleFacing.isAround(m.angleFacing), isTrue,
              reason: '"$said" left dancer $d somewhere other than "$meant" does');
        }
      }
    });
  });
}

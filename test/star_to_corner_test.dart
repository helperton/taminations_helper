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

//  From a squared set:
//    Heads Star Right to Corner  — the heads star right once around, which leaves each of them
//                                  beside their corner (a man's corner is on his left, a lady's
//                                  on her right)
//    With Corner Star Left       — each head joins the side couple holding their corner in a
//                                  left-hand star, once around; the sides finish home and the
//                                  heads on the inside, back toward the middle
//    Heads Star Right Back Home  — the heads star right in the middle and drop out at home
//  And the same for the sides.

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

  //  A man's corner is the lady of the couple before his, a lady's the man after hers.
  Dancer cornerOf(CallContext ctx, Dancer d) => ctx.dancers.firstWhere((o) =>
      o.gender != d.gender &&
      (d.gender == Gender.BOY
          ? o.numberCouple.i == (d.numberCouple.i + 2) % 4 + 1
          : o.numberCouple.i == d.numberCouple.i % 4 + 1));

  //  Of all the dancers not starring, the one nearest is the corner.
  void expectBesideCorner(CallContext ctx, bool Function(Dancer) starring) {
    for (final d in ctx.dancers.where(starring)) {
      final nearest = ctx.dancers.where((o) => !starring(o)).reduce((a, b) =>
          d.distanceTo(a) < d.distanceTo(b) ? a : b);
      expect(nearest, cornerOf(ctx, d), reason: 'dancer $d is not beside their corner');
    }
  }

  void expectSquaredSet(CallContext after, CallContext home) {
    for (final d in after.dancers) {
      final h = same(home, d);
      expect((d.location - h.location).length < 0.001 &&
             d.angleFacing.isAround(h.angleFacing, delta: 0.001), isTrue,
          reason: 'dancer $d at ${d.location} facing ${d.angleFacing}, '
              'not home at ${h.location} facing ${h.angleFacing}');
    }
  }

  for (final (who, starring) in [
    ('Heads', (Dancer d) => d.isHead),
    ('Sides', (Dancer d) => d.isSide),
  ]) {
    final toCorner = '$who Star Right to Corner';
    final withCorner = '$toCorner\nWith Corner Star Left';
    final backHome = '$withCorner\n$who Star Right Back Home';

    testWidgets('$who Star Right to Corner leaves each of them beside their corner',
        (tester) async {
      await tester.runAsync(() async {
        final model = await danced(toCorner);
        expect(model.errorString, '');
        final ctx = floor(model);
        for (final d in ctx.dancers.where(starring))
          expect(d.location.length.isAbout(1.0), isTrue, reason: 'dancer $d is not in the star');
        expectBesideCorner(ctx, starring);
      });
    });

    testWidgets('With Corner Star Left: the others home, the $who inside beside their corner',
        (tester) async {
      await tester.runAsync(() async {
        final home = floor(await danced(''));
        final model = await danced(withCorner);
        expect(model.errorString, '');
        expect(model.callNames.length, 2);
        final ctx = floor(model);
        for (final d in ctx.dancers.where((d) => !starring(d))) {
          final h = same(home, d);
          expect((d.location - h.location).length < 0.001 &&
                 d.angleFacing.isAround(h.angleFacing, delta: 0.001), isTrue,
              reason: 'dancer $d is not back home');
        }
        for (final d in ctx.dancers.where(starring))
          expect(d.location.length, lessThan(2.0), reason: 'dancer $d is not on the inside');
        expectBesideCorner(ctx, starring);
      });
    });

    testWidgets('$who Star Right Back Home: everyone home, and an Allemande Left follows',
        (tester) async {
      await tester.runAsync(() async {
        final home = floor(await danced(''));
        final model = await danced(backHome);
        expect(model.errorString, '');
        expect(model.callNames.length, 3);
        expectSquaredSet(floor(model), home);
        final next = await danced('$backHome\nAllemande Left');
        expect(next.errorString, '');
        expect(next.callNames.length, 4);
      });
    });
  }
}

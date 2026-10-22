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

//  From a squared set, any four (Men, Ladies, Heads, Sides) Star Right or Left: in to the
//  middle and once around, finishing in the star in front of their partner (men left, ladies
//  right) or their corner (men right, ladies left).
//
//  And a figure for the heads or the sides:
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
import 'package:taminations/math/vector.dart';
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

  bool isMan(Dancer d) => d.gender == Gender.BOY;
  bool isLady(Dancer d) => d.gender == Gender.GIRL;

  void expectSameFloor(CallContext after, CallContext reference) {
    for (final d in after.dancers) {
      final r = same(reference, d);
      expect((d.location - r.location).length < 0.001 &&
             d.angleFacing.isAround(r.angleFacing, delta: 0.001), isTrue,
          reason: 'dancer $d at ${d.location} facing ${d.angleFacing}, '
              'not at ${r.location} facing ${r.angleFacing}');
    }
  }

  //  Men or Ladies, either hand, as far as asked. Once around brings you back in front of
  //  whoever you came in beside: your partner when the men star left or the ladies right,
  //  otherwise your corner. Then the hand out of the star turns that one and everyone is home:
  //  facing your corner after turning your partner, facing your partner after your corner.
  for (final (who, starring) in [('Men', isMan), ('Ladies', isLady)])
  for (final hand in ['Right', 'Left'])
  for (final far in ['', ' Once Around', ' Full Around', ' to Your Corner', ' to Corner',
                     ' to the Corner', ' to Your Partner', ' to Partner'])
  testWidgets('$who Star $hand$far, then out of the star', (tester) async {
    await tester.runAsync(() async {
      final star = '$who Star $hand$far';
      final toPartner = far.contains('Partner') ||
          (!far.contains('Corner') && (who == 'Men') == (hand == 'Left'));
      final free = hand == 'Right' ? 'Left' : 'Right';
      final out = toPartner ? 'Turn Partner $free'
          : free == 'Left' ? 'Allemande Left' : 'Allemande Right Your Corner';
      final home = floor(await danced(''));
      final model = await danced(star);
      expect(model.errorString, '');
      final ctx = floor(model);
      for (final d in ctx.dancers.where(starring)) {
        expect(d.location.length.isAbout(1.0), isTrue, reason: 'dancer $d is not in the star');
        final center = d.tx.inverse() * Vector();
        expect(hand == 'Left' ? center.y > 0 : center.y < 0, isTrue,
            reason: 'dancer $d does not have the center on their ${hand.lc} hand');
        final nearest = ctx.dancers.where((o) => !starring(o)).reduce((a, b) =>
            d.distanceTo(a) < d.distanceTo(b) ? a : b);
        final partner = ctx.dancers.firstWhere((o) => o.numberCouple == d.numberCouple && o != d);
        expect(nearest, toPartner ? partner : cornerOf(ctx, d),
            reason: 'dancer $d is not in front of their ${toPartner ? 'partner' : 'corner'}');
      }
      for (final d in ctx.dancers.where((d) => !starring(d)))
        expect((d.location - same(home, d).location).length < 0.001, isTrue,
            reason: 'dancer $d moved');
      final reference = floor(await danced(toPartner
          ? 'Allemande Left\nRight Allemande' : 'Allemande Left'));
      final after = await danced('$star\n$out');
      expect(after.errorString, '', reason: '$out should take them out of the star');
      expect(after.callNames.length, 2);
      expectSameFloor(floor(after), reference);
    });
  });

  //  Other ways of saying the same star
  for (final (said, meant) in [
    ('Ladies RH Star to Your Corner', 'Ladies Star Right to Your Corner'),
    ('Ladies Right Hand Star to Your Corner', 'Ladies Star Right to Your Corner'),
    ('Four Ladies Star Right to Your Corner', 'Ladies Star Right to Your Corner'),
    ('All 4 Ladies Star Right to Your Corner', 'Ladies Star Right to Your Corner'),
    ('Girls Star Right to Your Corner', 'Ladies Star Right to Your Corner'),
    ('Ladies Star Right 3/4', 'Ladies Star Right to Your Corner'),
    ('Men LH Star', 'Men Star Left'),
    ('Boys Left Hand Star', 'Men Star Left'),
    ('Men Star Left 3/4', 'Men Star Left to Your Corner'),
  ])
  testWidgets('"$said" is "$meant"', (tester) async {
    await tester.runAsync(() async {
      final reference = await danced(meant);
      expect(reference.errorString, '');
      final model = await danced(said);
      expect(model.errorString, '');
      expect(model.animation.beats, reference.animation.beats);
      expectSameFloor(floor(model), floor(reference));
    });
  });

  //  Other ways of saying the allemandes out of the star
  for (final (star, said, meant) in [
    ('Ladies Star Right to Your Corner', 'Allemande Left Your Corner', 'Allemande Left'),
    ('Ladies Star Right to Your Corner', 'Left Allemande Corner', 'Allemande Left'),
    ('Ladies Star Right to Your Corner', 'Turn Corner Left', 'Allemande Left'),
    ('Ladies Star Right to Your Corner', 'Turn Your Corner by the Left', 'Allemande Left'),
    ('Ladies Star Left to Your Corner', 'Right Allemande Corner', 'Allemande Right Your Corner'),
    ('Ladies Star Left to Your Corner', 'Turn Corner Right', 'Allemande Right Your Corner'),
    ('Men Star Left', 'Right Allemande Partner', 'Turn Partner Right'),
    ('Ladies Star Right', 'Allemande Left Your Partner', 'Turn Partner Left'),
  ])
  testWidgets('$star, "$said" is "$meant"', (tester) async {
    await tester.runAsync(() async {
      final reference = await danced('$star\n$meant');
      expect(reference.errorString, '');
      final model = await danced('$star\n$said');
      expect(model.errorString, '');
      expect(model.animation.beats, reference.animation.beats);
      expectSameFloor(floor(model), floor(reference));
    });
  });

  testWidgets('Allemande Right Your Corner needs a star to come out of', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Allemande Right Your Corner');
      expect(model.errorString, contains('out of a star'));
    });
  });

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

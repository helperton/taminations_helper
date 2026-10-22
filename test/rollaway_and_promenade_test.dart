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

//  Ladies Rollaway and Men Rollaway: the named dancers roll across in front of their partners,
//  who sidestep behind them. Either way partners end up having traded places. Rollaway with a
//  Half Sashay is its full name.
//
//  Men (or Ladies) Promenade, Inside the Ring: the named four walk once around inside the set
//  and back home.

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

  Dancer same(List<Dancer> dancers, Dancer d) => dancers.firstWhere(
      (o) => o.numberCouple == d.numberCouple && o.gender == d.gender);

  void expectSameFloor(CallContext after, CallContext reference) {
    for (final d in after.dancers) {
      final r = same(reference.dancers, d);
      expect((d.location - r.location).length < 0.001 &&
             d.angleFacing.isAround(r.angleFacing, delta: 0.001), isTrue,
          reason: 'dancer $d at ${d.location} facing ${d.angleFacing}, '
              'not at ${r.location} facing ${r.angleFacing}');
    }
  }

  for (final before in ['', 'Circle Left\n'])
  for (final (who, rolls) in [
    ('Ladies', Gender.GIRL), ('Men', Gender.BOY),
  ])
  testWidgets('${before.isEmpty ? 'from a squared set' : 'after Circle Left'}, $who Rollaway: '
      'partners trade, the $who rolling in front', (tester) async {
    await tester.runAsync(() async {
      final reference = floor(await danced('Rollaway'));
      final model = await danced('$before$who Rollaway');
      expect(model.errorString, '');
      expectSameFloor(floor(model), reference);
      //  Rolling in front takes each roller nearer the middle of the set than their partner
      final dancers = model.animation.dancers;
      final end = model.animation.beats;
      final start = end - model.calls.last.beats;
      double closest(Dancer d) => [
        for (var b = start; b <= end; b += 0.25) (d..animate(b)).location.length,
      ].reduce((a, b) => a < b ? a : b);
      for (final d in dancers.where((d) => d.gender == rolls)) {
        final partner = dancers.firstWhere((o) => o.numberCouple == d.numberCouple && o != d);
        expect(closest(d), lessThan(closest(partner)),
            reason: 'dancer $d is not rolling in front of their partner');
      }
    });
  });

  for (final said in ['Rollaway with a Half Sashay', 'Ladies Rollaway with a Half Sashay'])
  testWidgets('"$said" is Rollaway', (tester) async {
    await tester.runAsync(() async {
      final reference = floor(await danced('Rollaway'));
      final model = await danced(said);
      expect(model.errorString, '');
      expectSameFloor(floor(model), reference);
    });
  });

  for (final (said, meant) in [
    ('Ladies Promenade', 'Four Ladies Promenade'),
    ('Ladies Promenade Inside the Ring', 'Four Ladies Promenade'),
    ('Four Ladies Promenade Inside', 'Four Ladies Promenade'),
    ('Men Promenade', 'Four Men Promenade'),
    ('Men Promenade Inside the Ring', 'Four Men Promenade'),
  ])
  testWidgets('from a squared set, "$said" is "$meant", back home', (tester) async {
    await tester.runAsync(() async {
      final home = floor(await danced(''));
      final reference = await danced(meant);
      expect(reference.errorString, '');
      final model = await danced(said);
      expect(model.errorString, '');
      expect(model.animation.beats, reference.animation.beats);
      expectSameFloor(floor(model), home);
    });
  });
}

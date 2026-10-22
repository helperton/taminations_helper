import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/dancer.dart';
import 'package:taminations/extensions.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';
void main() async {
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };
  testWidgets('dump', (tester) async {
    await tester.runAsync(() async {
      for (final (calls, who) in [('Allemande Left\nRight and Left Grand', '1B')]) {
        Settings.mockInit();
        final m = SequencerModel();
        m.setStartingFormation('Static Square');
        await m.paste(calls);
        m.animation.doPause();
        final ds = m.animation.dancers;
        String n(Dancer d) => '${d.numberCouple}${d.gender == Gender.BOY ? "B" : "G"}';
        final d = ds.firstWhere((x) => n(x) == who);
        print('=== $calls  $who  beats=${d.beats}');
        for (var b = 8.0; b < d.beats; b += 0.5) {
          for (final o in ds) o.animate(b);
          final p0 = d.location, a0 = d.angleFacing;
          final near = ds.where((o) => o != d && d.distanceTo(o) < 2.4).map((o) {
            final v = d.vectorToDancer(o); return '${n(o)}(${v.x.toStringAsFixed(1)},${v.y.toStringAsFixed(1)})'; }).join(' ');
          d.animate(b + 0.25);
          final v = (d.location - p0).length / 0.25, w = d.angleFacing.angleDiff(a0) / 0.25;
          final r = w.abs() < 0.2 ? '-' : (v / w.abs()).toStringAsFixed(2);
          print('  b=${b.toStringAsFixed(1)} at (${p0.x.toStringAsFixed(2)},${p0.y.toStringAsFixed(2)}) face ${(a0 * 180 / pi).toStringAsFixed(0)}  w=${w.toStringAsFixed(2)} r=$r  near: $near');
        }
      }
    });
  });
}

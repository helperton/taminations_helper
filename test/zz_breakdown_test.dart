import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/dancer.dart';
import 'package:taminations/sequencer/call_suggestions.dart';
import 'package:taminations/sequencer/sequencer_calls_model.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';
void main() async {
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };
  testWidgets('breakdown', (tester) async {
    await tester.runAsync(() async {
      const h = ['-', 'L', 'R', 'B'];
      Settings.mockInit();
      final m = SequencerModel();
      m.setStartingFormation('Static Square');
      await m.paste('Allemande Left');
      m.animation.doPause();
      final hist = m.animation.dancers;
      String n(Dancer d) => '${d.numberCouple}${d.gender == Gender.BOY ? "B" : "G"}';
      print('was: ' + hist.map((d) => '${n(d)}:${h[lastHandUsed(hist, d)]}').join(' '));
      for (final call in ['Right Allemande', 'Right and Left Grand', 'Men Star Left', 'Dosado', 'Zoom', 'Star Thru', 'Left Hinge', 'Single Circle to a Wave']) {
        final ctx = probeCall(call, m.contextFromCurrentFormation().dancers.map((d) => d.clone()).toList());
        final score = flowScore(hist, ctx);
        print('${call.padRight(26)} ${score.toStringAsFixed(2)}  next: ' + ctx.dancers.map((d) => '${n(d)}:${h[firstHandUsed(ctx.dancers, d)]}').join(' '));
      }
    });
  });
}

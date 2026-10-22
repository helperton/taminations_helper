import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/dancer.dart';
import 'package:taminations/sequencer/call_suggestions.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';
void main() async {
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };
  testWidgets('hands', (tester) async {
    await tester.runAsync(() async {
      const h = ['none', 'L', 'R', 'both'];
      for (final calls in ['Allemande Left', 'Allemande Left\nRight Arm Turn', 'Allemande Left\nRight and Left Grand',
          'Heads Star Right', 'Heads Star Left', 'Heads Square Thru 4\nStep to a Wave', 'Heads Ladies Chain', 'Heads Pass Thru',
          'Allemande Left\nMen Star Left', 'Heads Square Thru 4\nSwing Thru', 'Heads Square Thru 4\nLeft Swing Thru']) {
        Settings.mockInit();
        final m = SequencerModel();
        m.setStartingFormation('Static Square');
        await m.paste(calls);
        m.animation.doPause();
        final ds = m.animation.dancers;
        final rows = <String>[];
        var agree = 0, n = 0;
        for (final d in ds) {
          final geo = lastHandUsed(ds, d), drawn = lastHandDrawn(d);
          if (drawn != 0) { n++; if (geo == drawn) agree++; }
          rows.add('${d.numberCouple}${d.gender == Gender.BOY ? "B" : "G"}:${h[geo]}/${h[drawn]}');
        }
        print('${calls.replaceAll('\n', ', ').padRight(42)} geo/drawn  agree $agree/$n   ${rows.join(' ')}');
      }
    });
  });
}

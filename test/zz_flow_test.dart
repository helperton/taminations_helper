import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/call_index.dart';
import 'package:taminations/level_data.dart';
import 'package:taminations/sequencer/call_suggestions.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';
void main() async {
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };
  testWidgets('flow', (tester) async {
    await tester.runAsync(() async {
      final titles = callIndex.where((e) => [LevelData.MS, LevelData.PLUS].contains(LevelData.find(e.link)))
          .map((e) => e.title).toList();
      final extra = ['Right and Left Grand', 'Right Allemande', 'Allemande Left', 'Left Hinge', 'Men Star Left',
          'Ladies Star Right', 'Right Arm Turn', 'Promenade Home', 'Promenade 1/2', 'Face Partner', 'Swing Thru', 'Dosado'];
      final phrases = {...extra, ...titles};
      for (final before in ['Allemande Left', 'Allemande Left\nRight Arm Turn']) {
        Settings.mockInit();
        final m = SequencerModel();
        m.setStartingFormation('Static Square');
        await m.paste(before);
        m.animation.doPause();
        final sw = Stopwatch()..start();
        final ranked = rankFromHere(phrases, m.animation.dancers, m.contextFromCurrentFormation().dancers);
        print('=== after ${before.replaceAll('\n', ', ')}: ${ranked.length} of ${phrases.length} dance, ${sw.elapsedMilliseconds} ms');
        for (final (p, s) in ranked.take(12)) print('  ${s.toStringAsFixed(2)}  $p');
        print('  ...');
        for (final (p, s) in ranked.reversed.take(6).toList().reversed) print('  ${s.toStringAsFixed(2)}  $p');
        for (final want in ['Right and Left Grand', 'Right Allemande', 'Left Hinge', 'Men Star Left', 'Allemande Left'])
          print('  rank of $want: ${ranked.indexWhere((r) => r.$1 == want) + 1}');
      }
    });
  });
}

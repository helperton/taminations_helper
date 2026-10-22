import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/sequencer/call_suggestions.dart';
import 'package:taminations/sequencer/calls/xml_call.dart';
import 'package:taminations/sequencer/sequencer_calls_model.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';
void main() async {
  testWidgets('fit', (tester) async {
    await tester.runAsync(() async {
      for (final before in ['Allemande Left', 'Allemande Left\nRight Arm Turn']) {
        Settings.mockInit();
        final m = SequencerModel();
        m.setStartingFormation('Static Square');
        await m.paste(before);
        m.animation.doPause();
        print('=== after ${before.replaceAll('\n', ', ')}');
        for (final call in ['Heads Load the Boat', 'All 8 Spin the Top', 'Heads Split Two', 'Heads Single Circle to a Wave', 'Sides Circulate', 'Weave the Ring', 'Dixie Grand', 'Ladies Star Right', 'Men Star Left', 'Heads Left Swing Thru', 'Men Diamond Circulate', 'Heads Reverse Flutterwheel', 'Men Split Two', 'Sides Spin the Top', 'Left Arm Turn', 'Allemande Left']) {
          try {
            final ctx = probeCall(call, m.contextFromCurrentFormation().dancers.map((d) => d.clone()).toList());
            final xml = ctx.callstack.whereType<XMLCall>().where((c) => c.found).toList();
            final off = xml.fold(0.0, (s, c) => s + c.matchOffset);
            print('  ${call.padRight(26)} flow ${flowScore(m.animation.dancers, ctx).toStringAsFixed(2)}  offset ${off.toStringAsFixed(2)}  ${xml.isEmpty ? 'coded' : xml.map((c) => c.xcall.from).join(',')}');
          } catch (e) { print('  ${call.padRight(26)} -- ${e.toString().split('\n').first}'); }
        }
      }
    });
  });
}

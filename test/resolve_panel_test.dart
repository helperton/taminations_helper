import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as pp;
import 'package:taminations/resolve_client.dart';
import 'package:taminations/settings_flutter.dart';
import 'package:taminations/sequencer/resolver_panel_controller.dart';
import 'package:taminations/sequencer/resolve_panel.dart';

Widget _host(ResolverPanelController c, {Map<String, VoidCallback>? taps}) =>
    pp.ChangeNotifierProvider<ResolverPanelController>.value(
      value: c,
      child: MaterialApp(
        home: Scaffold(
          body: ResolvePanel(
            onGo: taps?['go'] ?? () {},
            onForward: taps?['fwd'] ?? () {},
            onBack: taps?['back'] ?? () {},
            onAccept: taps?['accept'] ?? () {},
            onDismiss: taps?['dismiss'] ?? () {},
            onCancel: taps?['cancel'] ?? () {},
          ),
        ),
      ),
    );

void main() {
  testWidgets('phase 1 shows sliders + Go/Cancel', (tester) async {
    Settings.mockInit();
    final c = ResolverPanelController()..open();
    await tester.pumpWidget(_host(c));
    expect(find.text('Go'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.byType(Slider), findsNWidgets(5));
  });

  testWidgets('phase 2 shows the get-out + Back/Forward/Accept/Dismiss', (tester) async {
    Settings.mockInit();
    final c = ResolverPanelController()..open()..beginResolving();
    c.applyResult(const ResolveResult(resolved: true,
        resolution: ['RIGHT AND LEFT GRAND', 'PROMENADE HOME']), baselineCount: 0);
    await tester.pumpWidget(_host(c));
    expect(find.text('Forward'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Dismiss'), findsOneWidget);
    expect(find.textContaining('RIGHT AND LEFT GRAND'), findsOneWidget);
  });

  testWidgets('Go fires its callback', (tester) async {
    Settings.mockInit();
    var went = false;
    final c = ResolverPanelController()..open();
    await tester.pumpWidget(_host(c, taps: {'go': () => went = true}));
    await tester.tap(find.text('Go'));
    expect(went, isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/resolve_client.dart';
import 'package:taminations/sequencer/resolver_panel_controller.dart';

void main() {
  test('open → danceability phase', () {
    final c = ResolverPanelController();
    expect(c.phase, ResolverPhase.closed);
    expect(c.isOpen, isFalse);
    c.open();
    expect(c.phase, ResolverPhase.danceability);
    expect(c.isOpen, isTrue);
  });

  test('applyResult success → stepThrough with the resolution, zero loaded', () {
    final c = ResolverPanelController()..open()..beginResolving();
    c.applyResult(const ResolveResult(state: '[0L]1p', resolved: true,
        resolution: ['RIGHT AND LEFT GRAND', 'PROMENADE HOME']), baselineCount: 3);
    expect(c.phase, ResolverPhase.stepThrough);
    expect(c.resolution, ['RIGHT AND LEFT GRAND', 'PROMENADE HOME']);
    expect(c.baseline, 3);
    expect(c.loadedSteps, 0);
    expect(c.canForward(), isTrue);
    expect(c.canBack(), isFalse);
    expect(c.nextCall(), 'RIGHT AND LEFT GRAND');
  });

  test('applyResult failure → failed phase with note', () {
    final c = ResolverPanelController()..open()..beginResolving();
    c.applyResult(const ResolveResult(state: '[0T]1p', resolved: false,
        note: 'unresolved'), baselineCount: 3);
    expect(c.phase, ResolverPhase.failed);
    expect(c.note, contains('unresolved'));
  });

  test('step index advances/retreats and clamps', () {
    final c = ResolverPanelController()..open()..beginResolving();
    c.applyResult(const ResolveResult(resolved: true, resolution: ['A', 'B']),
        baselineCount: 0);
    expect(c.didLoadForward(), 'A'); // returns the call it advanced onto
    expect(c.loadedSteps, 1);
    expect(c.nextCall(), 'B');
    expect(c.didLoadForward(), 'B');
    expect(c.loadedSteps, 2);
    expect(c.canForward(), isFalse);
    expect(c.didLoadForward(), isNull); // clamped, no-op
    c.didUndoBack();
    expect(c.loadedSteps, 1);
    c.didUndoBack();
    c.didUndoBack(); // clamped at 0
    expect(c.loadedSteps, 0);
    expect(c.canBack(), isFalse);
  });

  test('close resets to closed', () {
    final c = ResolverPanelController()..open();
    c.close();
    expect(c.phase, ResolverPhase.closed);
    expect(c.resolution, isEmpty);
    expect(c.loadedSteps, 0);
  });
}

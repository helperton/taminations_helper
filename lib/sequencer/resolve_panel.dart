import 'package:flutter/material.dart' as fm;
import 'package:provider/provider.dart' as pp;

import '../common_flutter.dart';
import 'resolver_panel_controller.dart';

/// The resolve pushout panel: renders the resolve UI in the grown window region
/// (never overlays TH). Phase 1 = danceability sliders; phase 2 = get-out
/// step-through. The six callbacks are wired by the sequencer page so the panel
/// is testable in isolation.
class ResolvePanel extends fm.StatefulWidget {
  final fm.VoidCallback onGo, onForward, onBack, onAccept, onDismiss, onCancel;
  const ResolvePanel({
    super.key,
    required this.onGo,
    required this.onForward,
    required this.onBack,
    required this.onAccept,
    required this.onDismiss,
    required this.onCancel,
  });

  @override
  fm.State<ResolvePanel> createState() => _ResolvePanelState();
}

class _ResolvePanelState extends fm.State<ResolvePanel> {
  static const _dLane = 70.0, _dOverlap = 25.0, _dDist = 5.0, _dThreshold = 60.0, _dBlockWidth = 1.0;

  late double _lane = Settings.danceabilityLaneWeight;
  late double _overlap = Settings.danceabilityOverlapWeight;
  late double _dist = Settings.danceabilityDistWeight;
  late double _threshold = Settings.danceabilityThreshold;
  late double _blockWidth = Settings.danceabilityBlockWidth;

  void _reset() => setState(() {
        _lane = _dLane;
        _overlap = _dOverlap;
        _dist = _dDist;
        _threshold = _dThreshold;
        _blockWidth = _dBlockWidth;
      });

  void _saveAndGo() {
    Settings.danceabilityLaneWeight = _lane;
    Settings.danceabilityOverlapWeight = _overlap;
    Settings.danceabilityDistWeight = _dist;
    Settings.danceabilityThreshold = _threshold;
    Settings.danceabilityBlockWidth = _blockWidth;
    widget.onGo();
  }

  fm.Widget _slider(String label, double value, double min, double max, int div,
          void Function(double) on) =>
      fm.Column(
        crossAxisAlignment: fm.CrossAxisAlignment.start,
        mainAxisSize: fm.MainAxisSize.min,
        children: [
          fm.Text('$label  —  ${value.toStringAsFixed(1)}'),
          fm.Slider(
              value: value,
              min: min,
              max: max,
              divisions: div,
              label: value.toStringAsFixed(1),
              onChanged: (v) => setState(() => on(v))),
        ],
      );

  @override
  fm.Widget build(fm.BuildContext context) {
    final c = pp.Provider.of<ResolverPanelController>(context);
    final isDark = fm.Theme.of(context).brightness == fm.Brightness.dark;
    return fm.Material(
      color: isDark ? Color.BLACK : Color.FLOOR,
      child: fm.SingleChildScrollView(
        padding: const fm.EdgeInsets.all(8),
        child: switch (c.phase) {
          ResolverPhase.danceability => _danceabilityView(),
          ResolverPhase.resolving => const fm.Padding(
              padding: fm.EdgeInsets.all(16),
              child: fm.Center(child: fm.Text('Resolving…'))),
          ResolverPhase.stepThrough => _stepView(c),
          ResolverPhase.failed => _failedView(c),
          ResolverPhase.closed => const fm.SizedBox.shrink(),
        },
      ),
    );
  }

  fm.Widget _danceabilityView() => fm.Column(
        mainAxisSize: fm.MainAxisSize.min,
        crossAxisAlignment: fm.CrossAxisAlignment.stretch,
        children: [
          _slider('Lane-clearance', _lane, 0, 100, 20, (v) => _lane = v),
          _slider('Overlap (reserved)', _overlap, 0, 100, 20, (v) => _overlap = v),
          _slider('Corner-distance', _dist, 0, 100, 20, (v) => _dist = v),
          _slider('Offer threshold', _threshold, 0, 100, 20, (v) => _threshold = v),
          _slider('Block width', _blockWidth, 0.5, 2.0, 15, (v) => _blockWidth = v),
          fm.Row(mainAxisAlignment: fm.MainAxisAlignment.spaceEvenly, children: [
            fm.TextButton(onPressed: widget.onCancel, child: const fm.Text('Cancel')),
            fm.TextButton(onPressed: _reset, child: const fm.Text('Reset')),
            fm.FilledButton(onPressed: _saveAndGo, child: const fm.Text('Go')),
          ]),
        ],
      );

  fm.Widget _stepView(ResolverPanelController c) => fm.Column(
        mainAxisSize: fm.MainAxisSize.min,
        crossAxisAlignment: fm.CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < c.resolution.length; i++)
            fm.Text(
              '${i < c.loadedSteps ? "▸ " : "   "}${c.resolution[i]}',
              style: fm.TextStyle(
                  fontWeight: i == c.loadedSteps - 1
                      ? fm.FontWeight.bold
                      : fm.FontWeight.normal),
            ),
          const fm.SizedBox(height: 8),
          fm.Row(mainAxisAlignment: fm.MainAxisAlignment.spaceEvenly, children: [
            fm.TextButton(
                onPressed: c.canBack() ? widget.onBack : null,
                child: const fm.Text('Back')),
            fm.TextButton(
                onPressed: c.canForward() ? widget.onForward : null,
                child: const fm.Text('Forward')),
          ]),
          fm.Row(mainAxisAlignment: fm.MainAxisAlignment.spaceEvenly, children: [
            fm.TextButton(onPressed: widget.onDismiss, child: const fm.Text('Dismiss')),
            fm.FilledButton(onPressed: widget.onAccept, child: const fm.Text('Accept')),
          ]),
        ],
      );

  fm.Widget _failedView(ResolverPanelController c) => fm.Column(
        mainAxisSize: fm.MainAxisSize.min,
        children: [
          fm.Padding(padding: const fm.EdgeInsets.all(8), child: fm.Text(c.note)),
          fm.TextButton(onPressed: widget.onCancel, child: const fm.Text('Close')),
        ],
      );
}

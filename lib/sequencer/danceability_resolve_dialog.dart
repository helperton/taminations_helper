import 'package:flutter/material.dart' as fm;

import '../common_flutter.dart';

/// Pre-flight dialog shown when the user taps Resolve. Lets them tune the
/// danceability values, then Go (saves them to Settings and pops `true`) or
/// Cancel (pops `false`, writes nothing). Reset restores SquareCraft's
/// canonical defaults. There is no toggle — Go always sends what the sliders
/// show, so Reset+Go reproduces "use SquareCraft's defaults".
class DanceabilityResolveDialog extends fm.StatefulWidget {
  @override
  fm.State<DanceabilityResolveDialog> createState() =>
      _DanceabilityResolveDialogState();
}

class _DanceabilityResolveDialogState extends fm.State<DanceabilityResolveDialog> {
  // SquareCraft's canonical defaults — mirror the Settings getter fallbacks.
  static const _dLane = 70.0,
      _dOverlap = 25.0,
      _dDist = 5.0,
      _dThreshold = 60.0,
      _dBlockWidth = 1.0;

  late double _lane, _overlap, _dist, _threshold, _blockWidth;

  @override
  void initState() {
    super.initState();
    _lane = Settings.danceabilityLaneWeight;
    _overlap = Settings.danceabilityOverlapWeight;
    _dist = Settings.danceabilityDistWeight;
    _threshold = Settings.danceabilityThreshold;
    _blockWidth = Settings.danceabilityBlockWidth;
  }

  void _reset() => setState(() {
        _lane = _dLane;
        _overlap = _dOverlap;
        _dist = _dDist;
        _threshold = _dThreshold;
        _blockWidth = _dBlockWidth;
      });

  void _go() {
    Settings.danceabilityLaneWeight = _lane;
    Settings.danceabilityOverlapWeight = _overlap;
    Settings.danceabilityDistWeight = _dist;
    Settings.danceabilityThreshold = _threshold;
    Settings.danceabilityBlockWidth = _blockWidth;
    fm.Navigator.of(context).pop(true);
  }

  // Label + value on one line, full-width slider below. No side-by-side fixed
  // widths competing for the row, so it cannot horizontally overflow whatever
  // width the dialog gives it.
  fm.Widget _control(String label, double value, double min, double max,
      int divisions, void Function(double) onChanged) {
    return fm.Column(
      crossAxisAlignment: fm.CrossAxisAlignment.start,
      mainAxisSize: fm.MainAxisSize.min,
      children: [
        fm.Text('$label  —  ${value.toStringAsFixed(1)}'),
        fm.Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          label: value.toStringAsFixed(1),
          onChanged: (v) => setState(() => onChanged(v)),
        ),
      ],
    );
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    // Fit the slider rows to the window: AlertDialog eats inset + content
    // padding, so a fixed 400 overflowed the sequencer window. Subtract a
    // generous margin and clamp so it's readable but never wider than the
    // dialog's content area.
    final contentWidth =
        (fm.MediaQuery.of(context).size.width - 150).clamp(200.0, 300.0).toDouble();
    return fm.AlertDialog(
      scrollable: true, // tall (label-above-slider) content scrolls instead of overflowing a short window
      title: const fm.Text('Resolve danceability',
          style: fm.TextStyle(fontSize: 20, fontWeight: fm.FontWeight.bold)),
      titlePadding: const fm.EdgeInsets.fromLTRB(20, 16, 20, 8),
      contentPadding: const fm.EdgeInsets.fromLTRB(20, 0, 20, 0),
      content: fm.SizedBox(
        width: contentWidth,
        child: fm.Column(
          mainAxisSize: fm.MainAxisSize.min,
          crossAxisAlignment: fm.CrossAxisAlignment.stretch,
          children: [
            _control('Lane-clearance', _lane, 0, 100, 20, (v) => _lane = v),
            _control('Overlap (reserved)', _overlap, 0, 100, 20, (v) => _overlap = v),
            _control('Corner-distance', _dist, 0, 100, 20, (v) => _dist = v),
            _control('Offer threshold', _threshold, 0, 100, 20, (v) => _threshold = v),
            _control('Block width', _blockWidth, 0.5, 2.0, 15, (v) => _blockWidth = v),
          ],
        ),
      ),
      actions: [
        fm.TextButton(
            onPressed: () => fm.Navigator.of(context).pop(false),
            child: const fm.Text('Cancel')),
        fm.TextButton(onPressed: _reset, child: const fm.Text('Reset')),
        fm.FilledButton(onPressed: _go, child: const fm.Text('Go')),
      ],
    );
  }
}

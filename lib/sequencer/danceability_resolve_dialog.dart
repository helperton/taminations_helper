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

  fm.Widget _row(String label, double value, double min, double max,
      int divisions, void Function(double) onChanged) {
    return fm.Padding(
      padding: const fm.EdgeInsets.symmetric(vertical: 2),
      child: fm.Row(children: [
        fm.SizedBox(width: 150, child: fm.Text(label)),
        fm.Expanded(
            child: fm.Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                label: value.toStringAsFixed(1),
                onChanged: (v) => setState(() => onChanged(v)))),
        fm.SizedBox(
            width: 44,
            child: fm.Text(value.toStringAsFixed(1),
                textAlign: fm.TextAlign.right)),
      ]),
    );
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.AlertDialog(
      title: const fm.Text('Resolve'),
      content: fm.SizedBox(
        width: 400,
        child: fm.Column(mainAxisSize: fm.MainAxisSize.min, children: [
          _row('Lane-clearance', _lane, 0, 100, 20, (v) => _lane = v),
          _row('Overlap (reserved)', _overlap, 0, 100, 20, (v) => _overlap = v),
          _row('Corner-distance', _dist, 0, 100, 20, (v) => _dist = v),
          _row('Offer threshold', _threshold, 0, 100, 20, (v) => _threshold = v),
          _row('Block width', _blockWidth, 0.5, 2.0, 15, (v) => _blockWidth = v),
        ]),
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

/*

  Taminations Square Dance Animations
  Copyright (C) 2026 Brad Christie

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.

*/


import 'package:flutter/material.dart' as fm;
import 'package:flutter/painting.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as pp;

import 'common_flutter.dart';
import 'dance_model.dart';

class DanceThemeTuning extends fm.ChangeNotifier {
  static const int sliderDivisions = 4095;
  static const Color _minFloorColor = Color.BLACK;
  static const Color _midFloorColor = Color(0xFF505050);
  static const Color _maxFloorColor = Color.FLOOR;
  static const double _minDancerFillFactor = 0.65;
  static const double _maxDancerFillFactor = 0.90;
  static const double _strokeOffset = 0.10;
  static const double _minContrastBias = -0.06;
  static const double _maxContrastBias = 0.06;

  int _floorSliderValue = 2702;
  int _dancerSliderValue = 1711;
  int _contrastSliderValue = 2283;
  bool _isPanelExpanded = false;

  int get floorSliderValue => _floorSliderValue;
  int get dancerSliderValue => _dancerSliderValue;
  int get contrastSliderValue => _contrastSliderValue;
  bool get isPanelExpanded => _isPanelExpanded;

  double get _baseDancerFillFactor =>
      _interpolateDouble(_dancerSliderValue, _minDancerFillFactor, _maxDancerFillFactor);
  double get contrastBias =>
      _interpolateDouble(_contrastSliderValue, _minContrastBias, _maxContrastBias);

  Color get darkFloorColor {
    final midpoint = sliderDivisions / 2;
    final isLowerHalf = _floorSliderValue <= midpoint;
    final localValue = isLowerHalf
        ? _floorSliderValue
        : _floorSliderValue - midpoint.round();
    final localDivisions = midpoint.round();
    final startColor = isLowerHalf ? _minFloorColor : _midFloorColor;
    final endColor = isLowerHalf ? _midFloorColor : _maxFloorColor;
    final baseRed = _interpolateInt(localValue, startColor.red, endColor.red, divisions: localDivisions);
    final baseGreen = _interpolateInt(localValue, startColor.green, endColor.green, divisions: localDivisions);
    final baseBlue = _interpolateInt(localValue, startColor.blue, endColor.blue, divisions: localDivisions);
    final biasOffset = (contrastBias * 120).round();
    return Color.fromARGB(
      255,
      (baseRed - biasOffset).clamp(0, 255),
      (baseGreen - biasOffset).clamp(0, 255),
      (baseBlue - biasOffset).clamp(0, 255),
    );
  }
  String get darkFloorHex => '#'
      '${darkFloorColor.red.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${darkFloorColor.green.toRadixString(16).padLeft(2, '0').toUpperCase()}'
      '${darkFloorColor.blue.toRadixString(16).padLeft(2, '0').toUpperCase()}';

  double get darkDancerFillFactor =>
      (_baseDancerFillFactor + contrastBias).clamp(0.5, 0.98);
  double get darkDancerStrokeFactor =>
      max(0.0, darkDancerFillFactor - (_strokeOffset + (contrastBias * 0.25)));

  void setFloorSliderValue(double value) {
    final nextValue = value.round().clamp(0, sliderDivisions);
    if (nextValue == _floorSliderValue) return;
    _floorSliderValue = nextValue;
    notifyListeners();
  }

  void setDancerSliderValue(double value) {
    final nextValue = value.round().clamp(0, sliderDivisions);
    if (nextValue == _dancerSliderValue) return;
    _dancerSliderValue = nextValue;
    notifyListeners();
  }

  void setContrastSliderValue(double value) {
    final nextValue = value.round().clamp(0, sliderDivisions);
    if (nextValue == _contrastSliderValue) return;
    _contrastSliderValue = nextValue;
    notifyListeners();
  }

  void togglePanelExpanded() {
    _isPanelExpanded = !_isPanelExpanded;
    notifyListeners();
  }

  void reset() {
    _floorSliderValue = 2702;
    _dancerSliderValue = 1711;
    _contrastSliderValue = 2283;
    notifyListeners();
  }

  static int _interpolateInt(int sliderValue, int minValue, int maxValue, {int? divisions}) {
    final ratio = sliderValue / (divisions ?? sliderDivisions);
    return (minValue + ((maxValue - minValue) * ratio)).round();
  }

  static double _interpolateDouble(int sliderValue, double minValue, double maxValue) {
    final ratio = sliderValue / sliderDivisions;
    return minValue + ((maxValue - minValue) * ratio);
  }
}

class DanceThemeTuningPanel extends fm.StatelessWidget {
  final bool showsToggleButton;

  const DanceThemeTuningPanel({
    super.key,
    this.showsToggleButton = true,
  });

  @override
  fm.Widget build(fm.BuildContext context) {
    return pp.Consumer<DanceThemeTuning>(
      builder: (context, tuning, _) => fm.Container(
        color: const Color(0xFF161616),
        padding: const fm.EdgeInsets.fromLTRB(12, 8, 12, 10),
        child: fm.Column(
          crossAxisAlignment: fm.CrossAxisAlignment.start,
          children: [
            fm.Row(
              children: [
                if (showsToggleButton) const DanceThemeTuningToggleButton(),
                if (tuning.isPanelExpanded)
                  fm.Text(
                    'Theme Tuning',
                    style: fm.TextStyle(
                      color: Color.WHITE,
                      fontSize: 12,
                      fontWeight: fm.FontWeight.w600,
                    ),
                  ),
                const fm.Spacer(),
                if (tuning.isPanelExpanded)
                  fm.TextButton(
                    onPressed: tuning.reset,
                    child: const fm.Text('Reset'),
                  ),
              ],
            ),
            if (tuning.isPanelExpanded) ...[
              DanceThemeTuningSliderRow(
                label: 'Floor',
                detail: '${tuning.floorSliderValue}/4095  ${tuning.darkFloorHex}',
                value: tuning.floorSliderValue.toDouble(),
                onChanged: tuning.setFloorSliderValue,
              ),
              DanceThemeTuningSliderRow(
                label: 'Dancers',
                detail:
                    '${tuning.dancerSliderValue}/4095  fill ${tuning.darkDancerFillFactor.toStringAsFixed(3)}  outline ${tuning.darkDancerStrokeFactor.toStringAsFixed(3)}',
                value: tuning.dancerSliderValue.toDouble(),
                onChanged: tuning.setDancerSliderValue,
              ),
              DanceThemeTuningSliderRow(
                label: 'Contrast',
                detail:
                    '${tuning.contrastSliderValue}/4095  bias ${tuning.contrastBias >= 0 ? '+' : ''}${tuning.contrastBias.toStringAsFixed(3)}',
                value: tuning.contrastSliderValue.toDouble(),
                onChanged: tuning.setContrastSliderValue,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class DanceThemeTuningToggleButton extends fm.StatelessWidget {
  const DanceThemeTuningToggleButton({super.key});

  @override
  fm.Widget build(fm.BuildContext context) {
    return pp.Consumer<DanceThemeTuning>(
      builder: (context, tuning, _) => fm.IconButton(
        onPressed: tuning.togglePanelExpanded,
        tooltip: tuning.isPanelExpanded ? 'Hide theme tuning' : 'Show theme tuning',
        icon: fm.Icon(
          fm.Icons.dehaze,
          color: Color.WHITE,
          size: 18,
        ),
      ),
    );
  }
}

class DanceThemeTuningSliderRow extends fm.StatelessWidget {
  final String label;
  final String detail;
  final double value;
  final fm.ValueChanged<double> onChanged;

  const DanceThemeTuningSliderRow({
    super.key,
    required this.label,
    required this.detail,
    required this.value,
    required this.onChanged,
  });

  @override
  fm.Widget build(fm.BuildContext context) {
    return fm.Column(
      crossAxisAlignment: fm.CrossAxisAlignment.start,
      children: [
        fm.Text(
          '$label  $detail',
          style: fm.TextStyle(color: Color.WHITE, fontSize: 11),
        ),
        fm.SliderTheme(
          data: const fm.SliderThemeData(
            trackHeight: 3,
            thumbShape: fm.RoundSliderThumbShape(enabledThumbRadius: 7),
          ),
          child: fm.Slider(
            value: value,
            min: 0,
            max: DanceThemeTuning.sliderDivisions.toDouble(),
            divisions: DanceThemeTuning.sliderDivisions,
            activeColor: const Color(0xFFE6A800),
            inactiveColor: const Color(0xFF5A5A5A),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class DancePainter extends fm.CustomPainter  {
  static const _darkPathAlpha = 90;

  //  Shapes for drawing dancers
  //  rectangle for boys
  static const rect = fm.Rect.fromLTWH(-0.5, -0.5, 1.0, 1.0);
  //  rounded rectangle for phantoms (no gender)
  static var rrect = fm.RRect.fromRectAndRadius(rect,
      fm.Radius.circular(0.3));
  //  Circles for girls and everybody's head don't need
  //  predefined shapes
  static const NUMBER_HEIGHT = 8.0;

  DanceModel model;

  Vector _size = Vector();
  var leadin = 2.0;
  var leadout = 2.0;
  var _prevbeat = 0.0;
  //  currentPart is 0 if not in animation, 1 to n otherwise
  var currentPart = 0;
  var hasParts = false;
  var hasCalls = false;
  String partstr = '';
  Map<Dancer,fm.Path> paths = {};

  //  Create the painter by passing the animation beater
  //  This will make it repaint every animation frame whenever
  //  the beater is ticking
  bool darkMode;
  final DanceThemeTuning? themeTuning;
  DancePainter(this.model, {this.darkMode = false, this.themeTuning})
      : super(repaint: themeTuning == null
            ? model.beater
            : fm.Listenable.merge([model.beater, themeTuning])) {
    _prevbeat = 0; // model.beater.beat;
    computePaths();
  }

  Color get _darkFloorColor => themeTuning?.darkFloorColor ?? const Color(0xFF242424);
  double get _darkDancerFillFactor => themeTuning?.darkDancerFillFactor ?? 0.78;
  double get _darkDancerStrokeFactor => themeTuning?.darkDancerStrokeFactor ?? 0.68;

  @override
  bool shouldRepaint(covariant fm.CustomPainter oldDelegate) {
    return true;
  }

  @override
  bool? hitTest(fm.Offset position) => null;

  @override
  fm.SemanticsBuilderCallback? get semanticsBuilder => null;

  @override
  bool shouldRebuildSemantics(covariant fm.CustomPainter oldDelegate) => shouldRepaint(oldDelegate);

  //  Convert widget x and y to dance floor coordinates
  Vector mouse2dance(Vector wc) {
    var range = min(_size.x,_size.y);
    var s = range / 13.0;
    var dx = -(wc.y - _size.y / 2.0) / s;
    var dy = -(wc.x - _size.x / 2.0) / s;
    return Vector(dx,dy);
  }

  //  Find dancer at floor coordinates
  Dancer? dancerAt(Vector p) {
    try {
      return model.dancers.firstWhere((d) => (d.location - p).length < 0.5);
    } on Error {
      return null;
    }
  }

  //  Check that there isn't another dancer in the middle of
  //  a computed handhold.  Can happen when dancers are in
  //  tight formations like tidal waves.
  bool _dancerInHandhold(Handhold hh) {
    var hhloc = (hh.dancer1.location + hh.dancer2.location).scale(0.5,0.5);
    return model.dancers.any((d) =>
    d != hh.dancer1 && d != hh.dancer2 &&
        (d.location - hhloc).length < 0.5 );
  }

  // Compute points of paths for drawing path
  void computePaths() {
    for (var d in model.dancers) {
      d.animate(0);
      var loc = d.location;
      var path = fm.Path();
      path.moveTo(loc.x, loc.y);
      for (var beat = 0.1; beat <= d.beats; beat += 0.1) {
        d.animate(beat);
        loc = d.location;
        path.lineTo(loc.x, loc.y);
      }
      paths[d] = path;
    }
  }

  ///   Draw the entire Dancer's path as a translucent colored line
  /// @param c  Canvas to draw to
  void drawPath(fm.Canvas c, Dancer d) {
    //  The path color is a partly transparent version of the draw color
    final pathColor = darkMode
        ? d.drawColor.darker(_darkDancerStrokeFactor).withAlpha(_darkPathAlpha)
        : d.drawColor.withAlpha(128);
    var p = fm.Paint()
      ..color = pathColor
      ..style = fm.PaintingStyle.stroke
      ..strokeWidth = 0.1;
    c.drawPath(paths[d]!, p);
  }

  /// Updates dancers positions based on the passage of realtime.
  /// Called at the start of onDraw().
  void _updateDancers() {
    //  Move dancers
    var delta = model.beater.beat - _prevbeat;
    var incs = delta.abs().ceil();
    for (var j = 1; j <= incs; j++)
      model.dancers.forEach((d) {
        d.animate(_prevbeat + j * delta / incs);
      });
    model.dancers.forEach((d) {
      d.animate(model.beater.beat);
    });
    _prevbeat = model.beater.beat;


    //  Compute handholds
    var hhlist = <Handhold>[];
    model.dancers.forEach((d0) {
      d0.rightDancer = null;
      d0.leftDancer = null;
      d0.rightHandVisibility = false;
      d0.leftHandVisibility = false;
    });
    for (var i1 = 0; i1 < model.dancers.length - 1; i1++) {
      var d1 = model.dancers[i1];
      if (!d1.hidden) {
        for (var i2 = i1 + 1; i2 < model.dancers.length; i2++) {
          var d2 = model.dancers[i2];
          if (!d2.hidden) {
            var hh = Handhold.create(d1, d2, model.geometryType);
            if (hh != null)
              hhlist.add(hh);
          }
        }
      }
    }
    //  Sort the list to put the best scores first
    hhlist.sort((a, b) => a.score.compareTo(b.score));
    //  Apply the handholds in order from best to worst
    //  so that if a dancer has a choice it gets the best handhold
    hhlist.where((it) => !_dancerInHandhold(it)).forEach((hh) {
      //  Check that the hands aren't already used
      var incenter = model.geometryType == Geometry.HEXAGON && hh.inCenter;
      if (incenter ||
          (hh.hold1 == Hands.RIGHTHAND && hh.dancer1.rightDancer == null ||
              hh.hold1 == Hands.LEFTHAND && hh.dancer1.leftDancer == null) &&
              (hh.hold2 == Hands.RIGHTHAND && hh.dancer2.rightDancer == null ||
                  hh.hold2 == Hands.LEFTHAND &&
                      hh.dancer2.leftDancer == null)) {
        //      	Make the handhold visible
        //  Scale should be 1 if distance is 2
        //  float scale = hh.distance/2f;
        if (hh.hold1 == Hands.RIGHTHAND || hh.hold1 == Hands.GRIPRIGHT) {
          hh.dancer1.rightHandVisibility = true;
          hh.dancer1.rightHandNewVisibility = true;
        }
        if (hh.hold1 == Hands.LEFTHAND || hh.hold1 == Hands.GRIPLEFT) {
          hh.dancer1.leftHandVisibility = true;
          hh.dancer1.leftHandNewVisibility = true;
        }
        if (hh.hold2 == Hands.RIGHTHAND || hh.hold2 == Hands.GRIPRIGHT) {
          hh.dancer2.rightHandVisibility = true;
          hh.dancer2.rightHandNewVisibility = true;
        }
        if (hh.hold2 == Hands.LEFTHAND || hh.hold2 == Hands.GRIPLEFT) {
          hh.dancer2.leftHandVisibility = true;
          hh.dancer2.leftHandNewVisibility = true;
        }

        if (!incenter) {
          if (hh.hold1 == Hands.RIGHTHAND) {
            hh.dancer1.rightDancer = hh.dancer2;
            if ((hh.dancer1.hands & Hands.GRIPRIGHT) == Hands.GRIPRIGHT)
              hh.dancer1.rightGrip = hh.dancer2;
          } else {
            hh.dancer1.leftDancer = hh.dancer2;
            if ((hh.dancer1.hands & Hands.GRIPLEFT) == Hands.GRIPLEFT)
              hh.dancer1.leftGrip = hh.dancer2;
          }
          if (hh.hold2 == Hands.RIGHTHAND) {
            hh.dancer2.rightDancer = hh.dancer1;
            if ((hh.dancer2.hands & Hands.GRIPRIGHT) == Hands.GRIPRIGHT)
              hh.dancer2.rightGrip = hh.dancer1;
          } else {
            hh.dancer2.leftDancer = hh.dancer1;
            if ((hh.dancer2.hands & Hands.GRIPLEFT) == Hands.GRIPLEFT)
              hh.dancer2.leftGrip = hh.dancer1;
          }
        }
      }
    });

    //  Clear handholds no longer visible
    model.dancers.forEach ( (d) {
      if (d.leftHandVisibility && !d.leftHandNewVisibility)
        d.leftHandVisibility = false;
      if (d.rightHandVisibility && !d.rightHandNewVisibility)
        d.rightHandVisibility = false;
    });

  }


  @override
  void paint(fm.Canvas ctx, fm.Size size) {
    _updateDancers();
    ctx.save();
    ctx.drawRect(fm.Rect.fromLTWH(0,0,size.width,size.height),
        fm.Paint()..color = darkMode ? _darkFloorColor : Color.FLOOR);
    //  Save floor dimensions for calculating mouse coords to dancer
    _size = size.v;
    var range = min(size.width,size.height);
    //  Scale coordinate system to dancer's size
    ctx.translate(size.width/2, size.height/2);
    ctx.clipRect(fm.Rect.fromCenter(center:fm.Offset(0,0),width: size.width, height: size.height));
    var s = range / 13.0;
    //  Flip and rotate
    ctx.scale(s,-s);
    ctx.rotate(pi/2);
    //  Draw grid if on
    if (model.gridVisibility) {
      drawGrid(ctx,model.geometryType);
    }
    if (model.axesVisibility!='None') {
      drawAxes(ctx, model.geometryType, short:(model.axesVisibility=='Short'));
    }
    //  Always show bigon center mark
    if (model.geometryType == Geometry.BIGON) {
      var p = fm.Paint()
          ..strokeWidth = 0.03;
      ctx.drawLine(fm.Offset(0,-0.5), fm.Offset(0,0.5), p);
      ctx.drawLine(fm.Offset(-0.5,0), fm.Offset(0.5,0), p);
    }

    //  Draw paths if requested
    model.dancers.forEach((d) {
      if (!d.hidden && (model.showPaths || d.showPath))
        drawPath(ctx,d);
    });

    //  Draw handholds
    var hline = fm.Paint()
      ..color = Color.ORANGE
      ..strokeWidth = 0.05;
    model.dancers.forEach( (d) {
      var loc = d.location;
      if (d.rightHandVisibility) {
        if (d.rightDancer == null) {  // hexagon center
          ctx.drawLine(fm.Offset(loc.x,loc.y), fm.Offset(0,0), hline);
          ctx.drawCircle(fm.Offset(0,0), 0.125, hline);
        } else if (d.rightDancer! < d) {
          var loc2 = d.rightDancer!.location;
          ctx.drawLine(fm.Offset(loc.x,loc.y), fm.Offset(loc2.x,loc2.y), hline);
          ctx.drawCircle(
            fm.Offset((loc.x+loc2.x)/2, (loc.y+loc2.y)/2),
              0.125, hline);
        }
      }
      if (d.leftHandVisibility) {
        if (d.leftDancer == null) { // hexagon center
          ctx.drawLine(fm.Offset(loc.x, loc.y), fm.Offset(0, 0), hline);
          ctx.drawCircle(fm.Offset(0, 0), 0.125, hline);
        } else if (d.leftDancer! < d) {
          var loc2 = d.leftDancer!.location;
          ctx.drawLine(fm.Offset(loc.x,loc.y), fm.Offset(loc2.x,loc2.y), hline);
          ctx.drawCircle(
              fm.Offset((loc.x+loc2.x)/2, (loc.y+loc2.y)/2),
              0.125, hline);
        }
      }
    });

    //  Draw dancers
    model.dancers.where((d) => !d.hidden).forEach((d) {
      drawDancer(ctx,d);
    });
    ctx.restore();
  }

  //  Draw grids
  void drawGrid(fm.Canvas ctx, int geometryType) {
    var p = fm.Paint()
      ..color = Color.LIGHTGREY
      ..style = fm.PaintingStyle.stroke
      ..strokeWidth = 0;

    switch (geometryType) {
      case Geometry.BIGON :
        for (var xs = -1; xs <= 1; xs += 2) {
          ctx.save();
          ctx.scale(xs.d,1.0);
          for (var xi = -75; xi <= 75; xi += 10) {
            var x1 = xi / 10.0;
            var path = fm.Path();
            path.moveTo(x1.abs(), 0.0);
            for (var yi = 2; yi <= 75; yi += 2) {
              var y1 = yi / 10.0;
              var a = 2.0 * atan2(y1,x1);
              var r = sqrt(x1*x1 + y1*y1);
              var x = r * cos(a);
              var y = r * sin(a);
              path.lineTo(x, y);
            }
            ctx.drawPath(path, p);
          }
          ctx.restore();
        }
        break;

      case Geometry.SQUARE :
      case Geometry.HASHTAG :
      case Geometry.ASYMMETRIC :
        for (var x = -75; x <= 75; x += 10) {
          var path = fm.Path();
          path.moveTo(x/10.0, -7.5);
          path.lineTo(x/10.0, 7.5);
          ctx.drawPath(path,p);
        }
        for (var y = -75; y <= 75; y += 10) {
          var path = fm.Path();
          path.moveTo(-7.5, y/10.0);
          path.lineTo(7.5, y/10.0);
          ctx.drawPath(path,p);
        }
        break;

      case Geometry.HEXAGON :
        for (var yscale = -1; yscale <= 1; yscale += 2) {
          for (var a=0; a<=6; a++) {
            ctx.save();
            ctx.rotate(pi/6 + a*pi/3);
            ctx.scale(1.0, yscale.d);
            for (var xi=5; xi<=85; xi+=10) {
              var x0 = xi / 10.0;
              var path = fm.Path();
              path.moveTo(0.0, x0);
              for (var yi=5; yi<=85; yi++) {
                var y0 = yi / 10.0;
                var aa = atan2(y0,x0) * 2 / 3;
                var r = sqrt(x0*x0 + y0*y0);
                var x = r * sin(aa);
                var y = r * cos(aa);
                path.lineTo(x, y);
              }
              ctx.drawPath(path, p);
            }
            ctx.restore();
          }
        }
        break;
    }
  }

  //  Draw axes
  void drawAxes(fm.Canvas ctx, int geometryType, {bool short = false}) {
    var p = fm.Paint()
      ..color = Color.LIGHTGREY
      ..style = fm.PaintingStyle.stroke
      ..strokeWidth = 0;

    switch (geometryType) {
      case Geometry.BIGON :
        final length = short ? 2.0 : 7.5;
        p.color = Color.RED;
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(-length,0.0), p);
        p.color = Color.BLUE;
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(length,0.0), p);
        break;

      case Geometry.SQUARE :
      case Geometry.HASHTAG :
      case Geometry.ASYMMETRIC :
        final length = short ? 2.0 : 7.5;
        p.color = Color.RED;
        ctx.drawLine(fm.Offset(-length,0.0), fm.Offset(length,0.0), p);
        p.color = Color.BLUE;
        ctx.drawLine(fm.Offset(0.0,-length), fm.Offset(0.0,length), p);
        break;

      case Geometry.HEXAGON :
        final length = short ? 2.0 : 7.5;
        final tanlength = length * tan(pi/6);
        p.color = Color.RED;
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(-length,0.0), p);
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(tanlength,length), p);
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(tanlength,-length), p);
        p.color = Color.BLUE;
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(length,0.0), p);
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(-tanlength,length), p);
        ctx.drawLine(fm.Offset(0.0,0.0), fm.Offset(-tanlength,-length), p);
        break;
    }
  }

  //  Draw the Dancer at its current position
  //  The Canvas is already transformed to the Dancer's position and orientation
  //  and scaled to the Dancer's size
  void drawDancer(fm.Canvas c, Dancer d) {
    var dc = model.showColors ? d.drawColor : Color.GRAY;
    var fc = model.showColors ? d.fillColor : Color.LIGHTGREY;
    if (darkMode) {
      dc = dc.darker(_darkDancerStrokeFactor);
      fc = fc.darker(_darkDancerFillFactor);
    }
    c.save();
    //ctx.transform(d.tx);  not available on Flutter
    c.translate(d.location.x,d.location.y);
    c.rotate(d.tx.angle);
    //  Draw the head
    var p = fm.Paint()..color = dc;
    c.drawCircle(fm.Offset(0.5,0.0), 0.33, p);
    //  Draw the body
    final reallyShowNumbers =
        model.showNumbers != 'None' &&
            d.gender != Gender.PHANTOM &&
            d.fillColor != Color.GRAY;
    p.color = reallyShowNumbers ? fc.veryBright() : fc;
    var g = model.showShapes ? d.gender : Gender.PHANTOM;
    if (g == Gender.BOY)
      c.drawRect(rect, p);
    else if (g == Gender.GIRL)
      c.drawCircle(fm.Offset(0,0), 0.5, p);
    else
      c.drawRRect(rrect, p);
    //  Draw the body outline
    p.strokeWidth = 0.1;
    p.color = dc;
    p.style = fm.PaintingStyle.stroke;
    if (g == Gender.BOY)
      c.drawRect(rect, p);
    else if (g == Gender.GIRL)
      c.drawCircle(fm.Offset(0,0), 0.5, p);
    else
      c.drawRRect(rrect, p);
    //  Draw number if on
    if (reallyShowNumbers) {
      //  The Dancer is rotated relative to the display, but of course
      //  the Dancer number should not be rotated.
      //  So the number needs to be transformed back
      var angle = atan2(d.tx.m12,d.tx.m22);
      var txtext = Matrix.getRotation(-angle + pi/2);
      c.translate(txtext.location.x,txtext.location.y);
      c.rotate(txtext.angle);
      c.scale(-0.1,0.1);
      var t = '';
      if (model.showNumbers == '1-8' ||
          model.showNumbers == 'Dancer Numbers')
        t = d.number;
      else if (model.showNumbers == '1-4' ||
          model.showNumbers == 'Couple Numbers')
        t = d.numberCouple;
      else if (model.showNumbers == 'Names')
        t = d.name;
      var _span = TextSpan(text: t,
          style:GoogleFonts.roboto(fontSize: NUMBER_HEIGHT, color: fm.Colors.black));
      var _tp = TextPainter(text: _span,
          textAlign: TextAlign.center,
          textDirection: fm.TextDirection.ltr)..layout();

      _tp.paint(c, fm.Offset(-_tp.width/2,-_tp.height/2));
    }
    c.restore();
  }


}

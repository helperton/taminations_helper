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

import '../../../moves.dart';
import '../common.dart';

//  A figure from a squared set, called for the heads or the sides:
//
//    Heads Star Right to Corner  — the heads star right once around in the middle, which
//                                  leaves each of them beside their corner
//    With Corner Star Left       — each head joins the side couple holding their corner in a
//                                  left-hand star, once around; the sides step back home and
//                                  the heads are left on the inside
//    Heads Star Right Back Home  — the heads star right in the middle, and each drops out of
//                                  the star as they come by home
//
//  Stars here have four dancers on the diagonals of a circle of radius 1. Each call ends exactly
//  where the next one starts, so none of them is snapped to a standard formation.

//  The star spot round [center] nearest [location], and the way to face there with the
//  center on the star hand.
(Vector, double) _starSpot(Vector center, Vector location, {required bool isLeft}) {
  final spot = [for (final a in [pi/4, pi*3/4, pi*5/4, pi*7/4]) center + Vector(cos(a), sin(a))]
      .reduce((a, b) => (a - location).length < (b - location).length ? a : b);
  return (spot, (spot - center).angle + (isLeft ? pi/2 : -pi/2));
}

//  Round the star by [eighths] of a turn.
Path _aroundTheStar(int eighths, {required bool isLeft}) {
  var path = Path();
  var left = eighths;
  for (final (size, move) in [
    (4, isLeft ? SwingLeft : SwingRight),
    (2, isLeft ? HingeLeft : HingeRight),
    (1, isLeft ? HalfHingeLeft : HalfHingeRight),
  ]) {
    while (left >= size) {
      path = path + move;
      left -= size;
    }
  }
  return path;
}

//  Step in to the star round [center] and go once around.
void _starOnceAround(CallContext ctx, Dancer d, Vector center, {required bool isLeft}) {
  final (spot, facing) = _starSpot(center, d.location, isLeft: isLeft);
  d.path = ctx.moveToPosition(d, spot, facing) + _aroundTheStar(8, isLeft: isLeft);
  d.animateToEnd();
}

class StarRightToCorner extends Action {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/star';
  @override var help = '''From a squared set, Heads (or Sides) Star Right to Corner:
star right once around, which leaves each of you beside your corner.''';

  StarRightToCorner(super.name);

  @override
  void performCall(CallContext ctx) {
    if (!ctx.isSquare())
      throw CallError('$name is from a squared set');
    ctx.noSnap();
    for (final d in ctx.actives)
      _starOnceAround(ctx, d, Vector(), isLeft: false);
  }

}

class WithCornerStarLeft extends Action {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/star';
  @override var help = '''After Heads (or Sides) Star Right to Corner:
join the couple holding your corner in a left-hand star, once around.
They step back home, and you are left on the inside.''';

  WithCornerStarLeft(super.name);

  @override
  void performCall(CallContext ctx) {
    final inMiddle = ctx.dancers.where((d) => d.location.length < 2.0).toList();
    final atHome = ctx.dancers.where((d) => !inMiddle.contains(d)).toList();
    //  Each couple at home stars in front of their home spots
    Vector starFor(Dancer d) => d.location.x.abs() > d.location.y.abs()
        ? Vector(d.location.x.sign * 2, 0) : Vector(0, d.location.y.sign * 2);
    final centers = atHome.map(starFor).toSet().toList();
    if (inMiddle.length != 4 || atHome.length != 4 || centers.length != 2)
      throw CallError('$name needs four in the middle and two couples at home');
    ctx.noSnap();
    for (final d in atHome) {
      final (home, facing) = (d.location, d.tx.angle);
      _starOnceAround(ctx, d, starFor(d), isLeft: true);
      d.path = d.path + ctx.moveToPosition(d, home, facing);
      d.animateToEnd();
    }
    for (final d in inMiddle) {
      final center = centers.reduce((a, b) =>
          (a - d.location).length < (b - d.location).length ? a : b);
      _starOnceAround(ctx, d, center, isLeft: true);
    }
  }

}

class StarRightBackHome extends Action {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/star';
  @override var help = '''After With Corner Star Left:
Heads (or Sides) star right in the middle and drop out as you come by home.''';

  StarRightBackHome(super.name);

  @override
  void performCall(CallContext ctx) {
    ctx.noSnap();
    for (final d in ctx.actives) {
      final (spot, facing) = _starSpot(Vector(), d.location, isLeft: false);
      final (home, homeFacing) = ctx.home(d);
      //  Go round until home is straight ahead, then walk out to it and turn to face in
      int offBy(int eighths) {
        final out = spot.rotate(-eighths * pi/4);
        return ((home - out).angle.angleDiff(facing - eighths * pi/4).abs() * 1000).round();
      }
      final eighths = [for (var e = 1; e <= 8; e++) e].reduce((a, b) => offBy(a) <= offBy(b) ? a : b);
      d.path = ctx.moveToPosition(d, spot, facing) + _aroundTheStar(eighths, isLeft: false);
      d.animateToEnd();
      final toHome = home - d.location;
      d.path = d.path + ctx.moveToPosition(d, home - toHome / toHome.length, toHome.angle);
      d.animateToEnd();
      d.path = d.path + ctx.moveToPosition(d, home, homeFacing);
      d.animateToEnd();
    }
  }

}

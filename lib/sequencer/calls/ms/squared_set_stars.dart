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
import '../../normalize_call.dart';
import '../common.dart';

//  Stars from a squared set. Any four (Men, Ladies, Heads, Sides) Star Right or Left: in to the
//  middle and once around, which leaves each of them in the star in front of their partner or
//  their corner. "to Your Corner" (or "to Your Partner") goes round until they are in front of
//  them, and 1/4, 1/2 or 3/4 that far round. Out of the star, Allemande Left, Allemande Right
//  Your Corner and the partner allemandes take everyone home (see out_of_the_star.dart).
//  For the heads or the sides, Star Right to Corner is also the start of a figure:
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

//  A star spot round [center] for each of [dancers], and the way to face there with the center
//  on the star hand. The spots are shared out so the dancers walk and turn the least between
//  them: going to the nearest spot can mean a three-quarter turn on the way in.
Map<Dancer, (Vector, double)> _starSpots(List<Dancer> dancers, Vector center,
    {required bool isLeft}) {
  final spots = [
    for (final a in [pi/4, pi*3/4, pi*5/4, pi*7/4])
      (center + Vector(cos(a), sin(a)), a + (isLeft ? pi/2 : -pi/2)),
  ];
  double cost(Dancer d, (Vector, double) spot) =>
      (spot.$1 - d.location).length + 0.5 * spot.$2.angleDiff(d.angleFacing).abs();
  //  Every way of giving each dancer a different spot, cheapest first
  Iterable<List<int>> shares(int n, List<int> taken) sync* {
    if (n == 0) yield taken;
    for (var i = 0; i < spots.length; i++)
      if (!taken.contains(i)) yield* shares(n - 1, [...taken, i]);
  }
  double total(List<int> share) =>
      [for (var i = 0; i < dancers.length; i++) cost(dancers[i], spots[share[i]])].sum();
  final best = shares(dancers.length, []).reduce((a, b) => total(a) <= total(b) ? a : b);
  return {for (var i = 0; i < dancers.length; i++) dancers[i]: spots[best[i]]};
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

//  [dancers] step in to the star round [center] and go once around.
void _starOnceAround(CallContext ctx, List<Dancer> dancers, Vector center,
    {required bool isLeft}) {
  for (final MapEntry(key: d, value: (spot, facing))
      in _starSpots(dancers, center, isLeft: isLeft).entries) {
    d.path = ctx.moveToPosition(d, spot, facing) + _aroundTheStar(8, isLeft: isLeft);
    d.animateToEnd();
  }
}

class StarFromSquaredSet extends Action with IsLeft {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/star';
  @override var help = '''From a squared set, any four (Men, Ladies, Heads, Sides)
Star Right or Star Left: in to the middle and once around, which leaves you in the star in
front of your partner or your corner. Star ... to Your Corner (or to Your Partner) goes round
until you are in front of them; Star ... 1/4, 1/2 or 3/4 goes that far round.''';

  StarFromSquaredSet(super.name);

  @override
  void performCall(CallContext ctx) {
    final norm = name.norm;
    isLeft = norm.startsWith('Left');
    if (!ctx.isSquare())
      throw CallError('$name is from a squared set');
    if (ctx.actives.length != 4)
      throw CallError('$name is for four dancers');
    ctx.noSnap();
    final to = norm.endsWith('Corner') ? ctx.originalCorner
        : norm.endsWith('Partner') ? ctx.originalPartner : null;
    final quarters = {'14': 1, '12': 2, '34': 3}[norm.substring(norm.length - 2)];
    final athome = ctx.dancers.where((d) => !ctx.actives.contains(d)).toList();
    for (final MapEntry(key: d, value: (spot, facing))
        in _starSpots(ctx.actives, Vector(), isLeft: isLeft).entries) {
      //  Round to the first spot in front of the one named, by quarters
      bool inFrontOf(int eighths) {
        final end = spot.rotate((isLeft ? eighths : -eighths) * pi/4);
        return to!(d) == athome.reduce((a, b) =>
            (a.location - end).length < (b.location - end).length ? a : b);
      }
      final eighths = quarters != null ? quarters * 2
          : to == null ? 8
          : [2, 4, 6, 8].firstWhere(inFrontOf, orElse: () =>
              throw CallError('Dancer $d cannot star to ${norm.endsWith('Corner') ? 'corner' : 'partner'}'));
      d.path = ctx.moveToPosition(d, spot, facing) + _aroundTheStar(eighths, isLeft: isLeft);
      d.animateToEnd();
    }
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
    final homes = {for (final d in atHome) d: (d.location, d.tx.angle)};
    Vector nearest(Dancer d) => centers.reduce((a, b) =>
        (a - d.location).length < (b - d.location).length ? a : b);
    for (final center in centers)
      _starOnceAround(ctx, [
        ...atHome.where((d) => starFor(d) == center),
        ...inMiddle.where((d) => nearest(d) == center),
      ], center, isLeft: true);
    for (final MapEntry(key: d, value: (home, facing)) in homes.entries) {
      d.path = d.path + ctx.moveToPosition(d, home, facing);
      d.animateToEnd();
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
    final spots = _starSpots(ctx.actives, Vector(), isLeft: false);
    for (final d in ctx.actives) {
      final (spot, facing) = spots[d]!;
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

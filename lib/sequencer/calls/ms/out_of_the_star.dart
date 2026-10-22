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

//  Allemandes out of a star in a squared set: four dancers are in a star in the middle, each in
//  front of the one they turn with — their partner or their corner — who is still at home.

final _homeSpots = CallContext.fromFormation(Formation('Squared Set'))
    .dancers.map((d) => d.location).toList();

bool onAHomeSpot(Dancer d) => _homeSpots.any((s) => s.isAbout(d.location));

//  Four on home spots and the other four in the middle
bool isStarInTheMiddle(CallContext ctx) =>
    ctx.dancers.length == 8 &&
    ctx.dancers.where(onAHomeSpot).length == 4 &&
    ctx.dancers.where((d) => !onAHomeSpot(d)).every((d) => d.location.length < 2.0);

//  Each pair meet just inside the home line and turn 1/2 by the [isLeft] hand. Then everyone
//  steps on to their own home spot and faces whoever [finishFacing] names.
void allemandeOutOfTheStar(CallContext ctx, String name, {
    required bool isLeft,
    required Dancer? Function(Dancer) turnWith,
    required Dancer? Function(Dancer) finishFacing}) {
  for (final d in ctx.dancers) {
    final other = turnWith(d);
    if (other == null || onAHomeSpot(d) == onAHomeSpot(other))
      throw CallError('$name needs one of each pair in the star and the other at home');
    final inStar = onAHomeSpot(d) ? other : d;
    final atHome = ctx.dancers.where(onAHomeSpot).reduce((a, b) =>
        inStar.distanceTo(a) < inStar.distanceTo(b) ? a : b);
    if (turnWith(inStar) != atHome)
      throw CallError('Dancer $inStar is not in front of the dancer to turn with');
  }
  Vector sideOf(double facing) =>
      Vector(cos(facing), sin(facing)).rotate(isLeft ? pi/2 : -pi/2);
  for (final d in ctx.dancers) {
    final other = turnWith(d)!;
    final isHome = onAHomeSpot(d);
    final (homeSpot, homeFacing) = ctx.home(isHome ? d : other);
    final starHome = ctx.home(isHome ? other : d).$1;
    //  Meet a little way from the one at home toward the other's home, and in from the home line
    final toward = (starHome - homeSpot) / (starHome - homeSpot).length;
    final inward = -(homeSpot + starHome) / (homeSpot + starHome).length;
    final meet = homeSpot + toward * 0.5 + inward * 0.5;
    //  The one at home turns to have the other on the turning hand: still facing in if the
    //  other comes from that side, otherwise facing along toward the other's home
    final handSide = sideOf(homeFacing);
    final facing = handSide.x * toward.x + handSide.y * toward.y > 0 ? homeFacing : toward.angle;
    final side = sideOf(facing);
    d.path = ctx.moveToPosition(d,
            isHome ? meet - side * 0.5 : meet + side * 0.5,
            isHome ? facing : facing + pi) +
        (isLeft ? SwingLeft : SwingRight).scale(0.5, 0.5);
    d.animateToEnd();
    final (end, _) = ctx.home(d);
    final faceHome = ctx.home(finishFacing(d) ??
        thrower<Dancer>('Dancer $d has nobody to face')).$1;
    d.path = d.path + ctx.moveToPosition(d, end, (faceHome - end).angle);
    d.animateToEnd();
  }
}

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

//  Normally the belle of each couple rolls across in front of the beau, who sidesteps behind
//  (Reverse Rollaway: the beau rolls). Named dancers (Ladies Rollaway, Men Rollaway) roll from
//  whichever side they are on, and their partners sidestep.
class Rollaway extends Action with IsReverse {

  @override var helplink = 'ms/sashay';

  Rollaway(super.name);

  @override
  void performCall(CallContext ctx) {
    final everyone = ctx.actives.length == ctx.dancers.length;
    for (final d in ctx.actives)
      if (!d.data.beau && !d.data.belle)
        throw CallError('Dancer $d does not know how to Rollaway');
    final rollers = everyone
        ? ctx.actives.where((d) => isReverse ? d.data.beau : d.data.belle)
        : ctx.actives;
    for (final d in rollers) {
      final d2 = d.data.partner ?? thrower<Dancer>('Cannot find partner of $d');
      if (!everyone && ctx.actives.contains(d2))
        throw CallError('Only one of each couple can Rollaway');
      final dist = d.distanceTo(d2);
      if (d.data.belle) {
        d.path += FoldLeft.changeBeats(1.5)
            .scale(0.6, dist/4).changehands(Hands.GRIPLEFT) +
            UmTurnLeft.changeBeats(1.5)
            .skew(1.2, -dist/2.0).changehands(Hands.GRIPLEFT);
        d2.path += DodgeRight.scale(1.0, dist/2.0).changehands(Hands.GRIPRIGHT);
      } else {
        d.path += FoldRight.changeBeats(1.5)
            .scale(0.6, dist/4).changehands(Hands.GRIPRIGHT) +
            UmTurnRight.changeBeats(1.5)
            .skew(1.2, dist/2.0).changehands(Hands.GRIPRIGHT);
        d2.path += DodgeLeft.scale(1.0, dist/2.0).changehands(Hands.GRIPLEFT);
      }
    }
    for (final d in ctx.dancers)
      d.animateToEnd();
  }

}

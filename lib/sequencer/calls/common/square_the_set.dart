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

class SquareTheSet extends Action {

  @override var helplink = 'Square the Set moves all the dancers to '
      'their original squared set locations.  This is not a real call.';

  SquareTheSet(super.name);

  @override
  Path performOne(Dancer d, CallContext ctx) {

    final (home, ahome) = ctx.home(d);

    //  Calculate the difference to that position and angle
    //  from dancer's current location and facing direction
    var tohome = home - d.location;
    var angle = d.tx.angle;
    tohome = tohome.rotate(-angle);
    var adiff = ahome.angleDiff(angle);
    var turn = StandAhead.skew(tohome.x,tohome.y);
    var move = turn.pop().twist(adiff);
    return Path.fromMovement(move).changeBeats(2);
  }

}
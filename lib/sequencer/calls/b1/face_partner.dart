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

import '../common.dart';

//  Two calls, and the difference between them is WHO you turn to look at.
//
//  Face Partner        — your ORIGINAL partner: the other half of your couple number, the one you
//                        started the tip with. That holds wherever the pair of you have got to,
//                        even across the set.
//  Face Partner of the Moment
//                      — whoever you are paired with RIGHT NOW: the dancer beside you, which is
//                        what analyze() works out as `data.partner` (your beau or your belle).
//
//  Either way you turn in place. Nobody travels.
class FacePartner extends Action {

  @override final level = LevelData.B1;
  @override var helplink = 'b1/face';
  @override var help = '''Face Partner turns you in place to look at your ORIGINAL partner —
the other half of your couple — wherever they have got to.
Face Partner of the Moment turns you to look at whoever you are paired with right now.''';

  FacePartner(super.name);

  bool get _ofTheMoment => name.toLowerCase().contains('moment');

  @override
  Path performOne(Dancer d, CallContext ctx) {
    final target = _ofTheMoment ? d.data.partner : _originalPartner(d, ctx);
    if (target == null) {
      throw CallError(_ofTheMoment
          ? 'Dancer $d is not paired with anyone to face.'
          : 'Dancer $d cannot find their partner.');
    }
    //  Turn on the spot to look at them: same place, new facing.
    return ctx.moveToPosition(d, d.location, (target.location - d.location).angle);
  }

  //  The one you came in with — same couple number, other gender.
  Dancer? _originalPartner(Dancer d, CallContext ctx) {
    for (final other in ctx.dancers) {
      if (other != d &&
          other.numberCouple == d.numberCouple &&
          other.gender != d.gender) {
        return other;
      }
    }
    return null;
  }

}

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
import 'out_of_the_star.dart';

//  Allemande with your partner: Allemande Right (Your Partner), or Allemande Left (Your)
//  Partner. Partners turn 1/2 by that hand, let go and step on, and in a squared set finish
//  home squarely facing their corner — the mirror of an Allemande Left with the corner, which
//  leaves you squarely facing your partner.
//
//  Partners facing each other at home Face Partner and Arm Turn. Or one of each couple can be
//  coming out of a star in the middle (Men Star Left, Right Allemande Partner): the pair meet
//  just inside the home spots instead.
class PartnerAllemande extends Action with IsLeft {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/allemande';
  @override var help = '''Allemande Right is the mirror of Allemande Left:
face your partner, right arm turn 1/2, and step forward to face your corner.
Allemande Left Partner is the same with left arms.
Either works with one of each couple coming out of a star in the middle.''';

  PartnerAllemande(super.name);

  @override
  void performCall(CallContext ctx) {
    isLeft = name.contains('left'.ri);
    if (ctx.actives.every(onAHomeSpot)) {
      ctx.applyCalls('Face Partner', '$whichWay Arm Turn');
      _faceOnTheStep(ctx);
    } else
      allemandeOutOfTheStar(ctx, name, isLeft: isLeft,
          turnWith: ctx.originalPartner, finishFacing: ctx.originalCorner);
  }

  //  Face Partner is a turn on the spot. Fold it into the first step of the arm turn so
  //  dancers turn to their partner as they step in — and, already facing, just step in.
  void _faceOnTheStep(CallContext ctx) {
    for (final d in ctx.actives) {
      final moves = d.path.movelist;
      final faceTx = Path([moves[0]]).computeTransformList().last;
      final step = moves[1];
      final rest = moves.sublist(2);
      if (faceTx.angle.isAround(0.0))
        d.path = Path([step, ...rest]);
      else {
        final stepTx = Path([step]).computeTransformList().last;
        final faceAndStep = Movement.fromTransform(faceTx * stepTx,
            beats: step.beats, hands: step.hands);
        d.path = Path([faceAndStep, ...rest]);
      }
      d.animateToEnd();
    }
  }

}

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
    final spots = CallContext.fromFormation(Formation('Squared Set'))
        .dancers.map((d) => d.location).toList();
    bool onASpot(Dancer d) => spots.any((s) => s.isAbout(d.location));
    if (ctx.actives.every(onASpot)) {
      ctx.applyCalls('Face Partner', '$whichWay Arm Turn');
      _faceOnTheStep(ctx);
    } else
      _outOfTheStar(ctx, spots, onASpot);
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

  //  One of each couple is home, the other in the middle. They meet just inside the home line,
  //  turn 1/2, and step on — the one from the middle to the empty spot beside their partner —
  //  finishing home facing their corners.
  void _outOfTheStar(CallContext ctx, List<Vector> spots, bool Function(Dancer) onASpot) {
    final ends = <Dancer, Vector>{};
    for (final d in ctx.actives) {
      final partner = ctx.originalPartner(d);
      if (partner == null || onASpot(d) == onASpot(partner))
        throw CallError('$name needs partners facing, or one of them in the middle');
      final home = onASpot(d) ? d : partner;
      final beside = spots.firstWhereOrNull((s) =>
          (s - home.location).length.isAbout(2.0) &&
          !ctx.dancers.any((o) => o.location.isAbout(s)));
      if (beside == null)
        throw CallError('Dancer $d has no spot to come home to beside their partner');
      ends[d] = d == home ? home.location : beside;
    }
    for (final d in ctx.actives) {
      final partner = ctx.originalPartner(d)!;
      final isHome = onASpot(d);
      final homeSpot = isHome ? d.location : partner.location;
      final besideSpot = isHome ? ends[partner]! : ends[d]!;
      //  Along the side from the home partner's spot to the spot beside, and in toward the center
      final along = (besideSpot - homeSpot) / 2.0;
      final mid = (homeSpot + besideSpot) / 2.0;
      var inward = Vector(-along.y, along.x);
      if (inward.x * mid.x + inward.y * mid.y > 0)
        inward = -inward;
      final meet = mid - along * 0.5 + inward * 0.5;
      //  The one from the middle comes in from the inside, the one at home from the outside
      final side = isHome ? -0.5 : 0.5;
      final facing = (isHome ? along : -along).angle;
      final end = ends[d]!;
      final away = end - ends[partner]!;
      final corner = spots.firstWhere((s) => (s - end).length.isAbout(sqrt(8)) &&
          (s - end).x * away.x + (s - end).y * away.y > 0);
      d.path = ctx.moveToPosition(d, meet + inward * side, facing) +
          (isLeft ? SwingLeft : SwingRight).scale(0.5, 0.5);
      d.animateToEnd();
      d.path = d.path + ctx.moveToPosition(d, end, (corner - end).angle);
      d.animateToEnd();
    }
  }

}

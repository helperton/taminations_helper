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

//  Right Arm Turn / Left Arm Turn, 1/4, 1/2 or 3/4 — 1/2 when no amount is given.
//
//  1/2 lets go and steps on, like Allemande Left: a Turn Thru. In a squared set it is the
//  mirror of Allemande Left — where that leaves you squarely facing your partner, this
//  leaves you squarely facing the dancer diagonally ahead (your corner, after a right arm
//  turn with your partner), so each dancer turns on the spot to face them.
//
//  1/4 and 3/4 finish holding on in a mini-wave. 3/4 is a half to a wave and a Hinge.
//  1/4 has no half to start from, so it needs a mini-wave — facing dancers step to one
//  first where the formation allows.
class ArmTurn extends Action with IsLeft {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/arm_turns';
  @override var help = '''Right Arm Turn or Left Arm Turn, optionally 1/4, 1/2 or 3/4.
With no amount it turns 1/2 and steps on, like Allemande Left.
1/4 and 3/4 finish holding on in a mini-wave.''';

  ArmTurn(super.name);

  String get _halfToAWave => '$left Turn Thru to a Wave';

  @override
  void performCall(CallContext ctx) {
    isLeft = name.contains('left'.ri);
    if (norm.endsWith('14'))
      _quarter(ctx);
    else if (norm.endsWith('34'))
      ctx.applyCalls(_halfToAWave, 'Hinge');
    else {
      ctx.applyCalls('$left Turn Thru');
      if (ctx.isSquare())
        super.performCall(ctx);  // square up: performOne below
    }
    ctx.level = LevelData.MS;  // Turn Thru is Plus; an arm turn is not
  }

  //  Turn on the spot to face the dancer diagonally ahead.
  @override
  Path performOne(Dancer d, CallContext ctx) {
    final ahead = ctx.dancers
        .where((o) => o != d && d.angleToDancer(o).abs() < pi/4 + 0.1)
        .fold<Dancer?>(null, (best, o) =>
            best == null || d.distanceTo(o) < d.distanceTo(best) ? o : best);
    if (ahead == null)
      return Path();
    return ctx.moveToPosition(d, d.location, (ahead.location - d.location).angle);
  }

  void _quarter(CallContext ctx) {
    ctx.applyFacingCouplesRule(isLeft: isLeft);
    for (final d in ctx.actives) {
      final d2 = isLeft ? ctx.dancerToLeft(d) : ctx.dancerToRight(d);
      if (d2 == null || !ctx.isInWave(d, d2))
        throw CallError('$name needs dancers holding $whichWay hands in mini-waves');
    }
    ctx.applyCalls('Hinge');
  }

}

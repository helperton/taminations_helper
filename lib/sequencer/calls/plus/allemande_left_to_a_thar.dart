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

//  Allemande Left to an Allemande Thar from a ring where each man faces a lady, as Go Forward
//  leaves it. A Static Square has its own drawn animation, which the sequencer finds first.
//
//  Each pair takes left hands where they meet and turns half, which leaves the man inside.
//  The men step in to a right-hand star and the ladies step out, still holding left hands,
//  as far from the center as the drawn thar has them: the men one unit, the ladies three.
class AllemandeLeftToAThar extends Action {

  @override var level = LevelData.PLUS;
  @override var helplink = 'plus/allemande_thar';

  AllemandeLeftToAThar(super.name);

  @override
  void performCall(CallContext ctx) {
    final facing = <Dancer, Dancer>{};
    for (final d in ctx.dancers) {
      final faced = ctx.dancerFacing(d);
      if (faced == null || faced.gender == d.gender || ctx.dancerFacing(faced) != d)
        throw CallError('$name needs each man facing a lady');
      facing[d] = faced;
    }
    //  Where each pair meet and which way each dancer faces there, from where they start
    final starts = {
      for (final d in ctx.dancers)
        d: ((d.location + facing[d]!.location) / 2.0, (facing[d]!.location - d.location).angle)
    };
    for (final d in ctx.dancers) {
      final (meet, along) = starts[d]!;
      //  Take left hands: the lady on the man's left, half a unit either side of where they meet
      final leftSide = Vector(cos(along + pi/2), sin(along + pi/2));
      final out = meet.angle;
      final isMan = d.gender == Gender.BOY;
      d.path = ctx.moveToPosition(d, meet - leftSide * 0.5, along) +
          SwingLeft.scale(0.5, 0.5);
      d.animateToEnd();
      d.path = d.path + ctx.moveToPosition(d,
          Vector(cos(out), sin(out)) * (isMan ? 1.0 : 3.0),
          isMan ? out - pi/2 : out + pi/2)
          .changehands(isMan ? Hands.BOTH : Hands.LEFT);
      d.animateToEnd();
    }
  }

}

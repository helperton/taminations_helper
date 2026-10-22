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

//  Allemande (Left or Right) Your Corner. By the left it is Allemande Left. By the right it is
//  for coming out of a star in front of your corner (Ladies Star Left to Your Corner): turn 1/2
//  and step on home, facing your partner.
class CornerAllemande extends Action with IsLeft {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/allemande';
  @override var help = '''Allemande Left Your Corner is Allemande Left.
Allemande Right Your Corner is out of a star in front of your corner:
right arm turn 1/2 and step on home to face your partner.''';

  CornerAllemande(super.name);

  @override
  void performCall(CallContext ctx) {
    isLeft = name.contains('left'.ri);
    if (isLeft)
      ctx.applyCalls('Allemande Left');
    else if (isStarInTheMiddle(ctx))
      allemandeOutOfTheStar(ctx, name, isLeft: false,
          turnWith: ctx.originalCorner, finishFacing: ctx.originalPartner);
    else
      throw CallError('$name is for coming out of a star in front of your corner');
  }

}

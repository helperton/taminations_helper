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

class CrossFold extends Action {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/fold';

  CrossFold(super.name);

  @override
  void performCall(CallContext ctx) {
    //  Centers and ends cannot both cross fold
    if (ctx.actives.any((d) => d.data.center) &&
        ctx.actives.any((d) => d.data.end))
      throw CallError('Centers and ends cannot both Cross Fold');
    for (var d in ctx.actives) {
      //  Must be in a 4-dancer wave or line
      if (!d.data.center && !d.data.end)
        throw CallError('General line required for Cross Fold');

      //  Determine direction of Cross Fold
      var dleft = ctx.dancersToLeft(d);
      var dright = ctx.dancersToRight(d);
      Dancer d2;
      var isRight = true;
      if (dright.length < 2)
        isRight = false;
      if (dright.length >= 4 && dright.length-4 < 2)
        isRight = false;
      if (isRight && dright.length > 1) {
        d2 = dright.second;
      } else if (dleft.length > 1)
        d2 = dleft.second;
      else
        throw CallError('Unaable to calculate Cross Fold');
      if (d2.isActive)
        throw CallError('Invalid Cross Fold');

      var m = (isRight) ? FoldRight : FoldLeft;
      var dist = d.distanceTo(d2);
      var dxscale = 0.75;

      d.path = m.scale(dxscale,dist/2); // .skew(0.0,dyoffset);

    }
    //  Dancers often end up in unusual formations after
    //  Fold or Cross Fold.  Don't try to fix.
    ctx.noSnap();
  }

}
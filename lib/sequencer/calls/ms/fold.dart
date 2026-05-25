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

class Fold extends Action {

  @override
  var level = LevelData.MS;
  @override var helplink = 'ms/fold';

  Fold(super.name);

  //  We need to work with all the dancers, not just actives
  //  because partners of the folders need to adjust
  //  so we get a standard formation that can be used for more calls
  @override
  void performCall(CallContext ctx) {
    for (var d in ctx.actives) {
      //  Find dancer to fold in front of
      //  Usually it's the partner
      var d2 = d.data.partner;
      if (d2 == null) {
        var dleft = ctx.dancersToLeft(d);
        var dright = ctx.dancersToRight(d);
        if (dleft.length % 2 == 0 && dright.length % 2 == 1)
          d2 = ctx.dancerToRight(d)!;
        else if (dleft.length % 2 == 1 && dright.length % 2 == 0)
          d2 = ctx.dancerToLeft(d)!;
      }
      if (d2 == null || d2.data.active)
        throw CallError('Dancer $d has nobody to Fold in front');

      var m = d2.isRightOf(d) ? FoldRight : FoldLeft;
      var dist = d.distanceTo(d2);
      var dxscale = 0.75;
      var dyscale = dist/2.0;
      d.path = m.scale(dxscale, dyscale);

    }
    //  Dancers often end up in unusual formations after
    //  Fold or Cross Fold.  Don't try to fix.
    ctx.noSnap();
  }

}
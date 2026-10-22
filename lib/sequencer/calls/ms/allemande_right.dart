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

//  The mirror of Allemande Left: face your partner and Right Arm Turn — which lets go,
//  steps on, and in a squared set leaves you squarely facing your corner, as Allemande
//  Left leaves you squarely facing your partner.
class AllemandeRight extends Action {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/allemande';
  @override var help = '''Allemande Right is the mirror of Allemande Left:
face your partner, right arm turn 1/2, and step forward to face your corner.''';

  AllemandeRight(super.name);

  @override
  void performCall(CallContext ctx) {
    ctx.applyCalls('Face Partner', 'Right Arm Turn');
  }

}

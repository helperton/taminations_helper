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

//  Go Forward N: the first N hands of a Right and Left Grand round the ring, starting with
//  the right. Each hand is a Pull By with the dancer you meet. On a ring the next dancer is
//  round the curve, not straight ahead, so as you step on you turn to face them; otherwise
//  the next Pull By would find nobody in front. A ring can also start out facing along the
//  curve (as Shoot the Star leaves it), so the first step squares up to the first dancer.
class GoForward extends Action {

  @override var level = LevelData.MS;
  @override var helplink = 'ms/right_and_left_grand';
  @override var help = '''Go Forward and a number: that many hands of a Right and Left Grand
round the ring, starting with the right.''';

  GoForward(super.name);

  @override
  void performCall(CallContext ctx) {
    final hands = int.parse('\\d+'.r.firstMatch(norm)![0]!);
    //  The dancers in order round the center, and which way round each one is going
    final round = ctx.dancers.toList()
      ..sort((a, b) => a.location.angle.compareTo(b.location.angle));
    final n = round.length;
    //  Each dancer's neighbor on the ring that they face more nearly, and which way round
    //  that is. The two must be looking at each other.
    (Dancer, int) toward(int i) {
      final d = round[i];
      final ahead = round[(i + 1) % n], behind = round[(i - 1) % n];
      return d.angleToDancer(ahead).abs() <= d.angleToDancer(behind).abs()
          ? (ahead, 1) : (behind, -1);
    }
    final ways = <Dancer, int>{};
    for (final (i, d) in round.indexed) {
      final (meets, way) = toward(i);
      if (d.angleToDancer(meets).abs() > pi/4 || toward(round.indexOf(meets)).$1 != d)
        throw CallError('Go Forward needs everyone on a ring, facing the next dancer round it');
      ways[d] = way;
    }
    final spots = round.map((d) => d.location).toList();
    //  Turn to face the first dancer squarely, so Pull By finds them in front; the turn is
    //  folded into the first step below
    final squareUp = {
      for (final (i, d) in round.indexed)
        d: (spots[(i + ways[d]!) % n] - d.location).angle.angleDiff(d.tx.angle)
    };
    for (final d in round) {
      d.path = d.path + Path([Movement.fromTransform(Matrix.getRotation(squareUp[d]!), beats: 1)]);
      d.animateToEnd();
    }
    for (var hand = 1; hand <= hands; hand++) {
      ctx.applyCalls('${hand.isOdd ? 'Right' : 'Left'} Pull By');
      if (hand == 1)
        for (final d in round)
          d.path = Path(d.path.movelist.sublist(1)).turnDuringFirstMove(squareUp[d]!);
      for (final (i, d) in round.indexed) {
        final next = spots[(i + (hand + 1) * ways[d]!) % n];
        d.path = d.path.turnDuringLastMove((next - d.location).angle.angleDiff(d.tx.angle));
        d.animateToEnd();
      }
    }
  }

}

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

//  BeatNotifier.start() must guard on the ticker being ACTIVE, not TICKING. Flutter mutes a
//  ticker whenever the app's frames are disabled — which happens to SquareCraft's sidecar when it
//  is a backgrounded, floating window while SquareCraft presents. A muted-but-active ticker has
//  isTicking == false, so a start() guarded on isTicking would call Ticker.start() on an
//  already-active ticker and throw "A ticker was started twice", killing the /sequence request
//  that triggered it.

import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/beat_notifier.dart';

void main() {
  //  testWidgets provides the frame machinery a raw Ticker needs to start.
  testWidgets('start() twice in a row is a no-op, not a throw', (tester) async {
    final beat = BeatNotifier();
    beat.setTimes(0, 10);
    beat.start();
    await tester.pump();
    expect(beat.tickerActiveForTest, isTrue);
    expect(() => beat.start(), returnsNormally);
    beat.stop();
  });

  testWidgets('start() on an active-but-MUTED ticker does not throw (the backgrounded-sidecar bug)',
      (tester) async {
    final beat = BeatNotifier();
    beat.setTimes(0, 10);
    beat.start();
    await tester.pump();
    expect(beat.tickerActiveForTest, isTrue);

    //  Background the sidecar: Flutter mutes the ticker. It is still active, but no longer ticking.
    beat.tickerMutedForTest = true;
    expect(beat.isRunning, isFalse, reason: 'muted ⇒ isTicking is false');
    expect(beat.tickerActiveForTest, isTrue, reason: 'but the ticker is still active');

    //  This is the exact call that used to throw "A ticker was started twice".
    expect(() => beat.start(), returnsNormally);

    beat.tickerMutedForTest = false;
    beat.stop();
  });
}

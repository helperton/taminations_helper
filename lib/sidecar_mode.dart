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

import 'package:flutter/foundation.dart';

/// FLOOR ONLY.
///
/// When SquareCraft is presenting, the caller is reading the calls off his own cards — he does not
/// need the timeline, the call list, the input line or the buttons. He needs the dancers. So the
/// sidecar shows the floor and nothing else.
///
/// It is a notifier rather than a launch flag alone because SquareCraft flips it live, on the same
/// dock request that moves the window: on when he goes on stage, off when he comes back to editing.
final floorOnlyMode = ValueNotifier<bool>(false);

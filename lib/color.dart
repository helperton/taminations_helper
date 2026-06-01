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


//  Conditional export so the same `import 'color.dart';` works in both builds:
//   - the Flutter GUI gets color_flutter.dart (Color extends fm.Color, for rendering);
//   - headless `dart run` gets color_dart.dart (pure ARGB int, no dart:ui).
export 'color_dart.dart'
    if (dart.library.ui) 'color_flutter.dart';

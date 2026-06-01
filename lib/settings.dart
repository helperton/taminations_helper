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

//  Conditional export so the same `import 'settings.dart';` works in both builds:
//   - the Flutter GUI gets settings_flutter.dart (Settings extends ChangeNotifier,
//     backed by shared_preferences, system locale);
//   - headless `dart run` gets settings_dart.dart (mock-backed, no Flutter).
export 'settings_dart.dart'
    if (dart.library.ui) 'settings_flutter.dart';

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

//  The settings pages are white rows on light grey. In the sidecar's dark mode their text
//  took the dark theme's light colour, so every setting looked greyed out and disabled.

import 'package:flutter/material.dart' as fm;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart' as pp;
import 'package:taminations/pages/settings_page.dart';
import 'package:taminations/settings_flutter.dart';
import 'package:taminations/title_bar.dart';

void main() {

  Future<void> showInDarkMode(WidgetTester tester, fm.Widget frame) async {
    Settings.mockInit();
    await tester.pumpWidget(pp.MultiProvider(
      providers: [
        pp.ChangeNotifierProvider(create: (_) => Settings()),
        pp.ChangeNotifierProvider(create: (_) => TitleModel()),
      ],
      child: fm.MaterialApp(
        darkTheme: fm.ThemeData(brightness: fm.Brightness.dark),
        themeMode: fm.ThemeMode.dark,
        home: fm.Scaffold(body: frame),
      ),
    ));
  }

  //  Dark enough to read on the white rows
  void expectDarkText(WidgetTester tester, String text) {
    final color = tester.renderObject<RenderParagraph>(find.text(text)).text.style!.color!;
    expect(color.computeLuminance(), lessThan(0.2),
        reason: '"$text" is drawn in $color, which is too pale to read on white');
  }

  testWidgets('sequencer settings read as dark text in dark mode', (tester) async {
    await showInDarkMode(tester, SequencerSettingsFrame());
    expectDarkText(tester, 'Dancer Shapes');
    expectDarkText(tester, 'Dancer Identification');
  });

  testWidgets('animation settings read as dark text in dark mode', (tester) async {
    await showInDarkMode(tester, SettingsFrame());
    expectDarkText(tester, 'Loop');
    expectDarkText(tester, 'Grid');
  });

}

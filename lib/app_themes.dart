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

import 'package:flutter/cupertino.dart' as fc;
import 'package:flutter/material.dart' as fm;
import 'package:google_fonts/google_fonts.dart';

import 'common_flutter.dart';

///  Flutter's default transition on macOS is CupertinoPageTransitionsBuilder, which hangs a
///  ~20px drag-to-pop gesture on the window's left edge. The sequencer's timeline slider runs the
///  full width, so with the thumb at the far left, dragging it started the BACK gesture instead of
///  the slider — the page slid off to the right and the page underneath showed through. Nobody
///  back-swipes with a mouse, and the title bar has a Back button, so desktop gets a transition
///  with no edge gesture. The phones keep theirs.
class TaminationsAppTransitions {
  static const desktop = fm.PageTransitionsTheme(builders: {
    //  The phones keep the platform default (Cupertino on iOS carries the edge gesture, which is
    //  right there). Only the desktops, where the pointer is a mouse, lose it.
    fm.TargetPlatform.macOS: fm.FadeUpwardsPageTransitionsBuilder(),
    fm.TargetPlatform.windows: fm.ZoomPageTransitionsBuilder(),
    fm.TargetPlatform.linux: fm.ZoomPageTransitionsBuilder(),
    fm.TargetPlatform.iOS: fc.CupertinoPageTransitionsBuilder(),
    fm.TargetPlatform.android: fm.ZoomPageTransitionsBuilder(),
    fm.TargetPlatform.fuchsia: fm.ZoomPageTransitionsBuilder(),
  });
}

const _darkBackground = fm.Color(0xFF000000);

final _scrollbarTheme = fm.ScrollbarThemeData(
  thumbColor: fm.WidgetStateColor.resolveWith((states) => Color.TRANSPARENTGREY),
);

fm.ThemeData lightTheme() => fm.ThemeData(
  fontFamily: 'Roboto',
  brightness: fm.Brightness.light,
  pageTransitionsTheme: TaminationsAppTransitions.desktop,
  textTheme: GoogleFonts.robotoTextTheme(),
  scrollbarTheme: _scrollbarTheme,
);

//  The sidecar's presentation mode: a black floor with light text
fm.ThemeData darkTheme() => fm.ThemeData(
  fontFamily: 'Roboto',
  brightness: fm.Brightness.dark,
  pageTransitionsTheme: TaminationsAppTransitions.desktop,
  scaffoldBackgroundColor: _darkBackground,
  colorScheme: const fm.ColorScheme.dark(
    surface: _darkBackground,
    primary: fm.Color(0xFF90CAF9),
  ),
  textTheme: GoogleFonts.robotoTextTheme(fm.ThemeData.dark().textTheme),
  scrollbarTheme: _scrollbarTheme,
);

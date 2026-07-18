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
import 'package:flutter/cupertino.dart' as fc;
import 'package:flutter/material.dart' as fm;
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart' as pp;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taminations/beat_notifier.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:window_manager/window_manager.dart';

import 'api_server_stub.dart' if (dart.library.io) 'api_server.dart';
import 'branch.dart';
import 'tam_web_bridge_stub.dart' if (dart.library.html) 'tam_web_bridge.dart';
import 'common_flutter.dart';
import 'pages/anim_list_page.dart';
import 'pages/animation_page.dart';
import 'pages/calls_page.dart';
import 'pages/first_landscape_page.dart';
import 'pages/level_page.dart';
import 'pages/markdown_page.dart';
import 'pages/page.dart';
import 'pages/practice_page.dart';
import 'pages/second_landscape_page.dart';
import 'pages/settings_page.dart';
import 'pages/start_practice_page.dart';
import 'pages/tutorial_page.dart';
import 'resolve_client.dart';
import 'sidecar_mode.dart';
import 'sequencer/abbreviations_frame.dart';
import 'sequencer/resolver_panel_controller.dart';
import 'sequencer/abbreviations_model.dart';
import 'sequencer/sequencer_calls_page.dart';
import 'sequencer/sequencer_page.dart';

class SidecarDockRequest {
  final fm.Rect hostFrame;
  final fm.Rect screenFrame;
  final fm.Rect? dockFrame;
  final bool darkMode;

  ///  Float above everything. SquareCraft's presentation mode goes FULL SCREEN, so without this
  ///  the floor would sit behind the black and never be seen.
  final bool alwaysOnTop;

  ///  Show the dance floor and nothing else — no timeline, no call list, no buttons. The caller is
  ///  presenting, and the calls are on his cards. See sidecar_mode.dart.
  final bool floorOnly;

  ///  A DISPLAY, not an app. While SquareCraft is presenting, the caller drives everything from the
  ///  carousel — so the sidecar must never take the keyboard (or his arrow keys would stop reaching
  ///  SquareCraft) and never take the mouse (clicks fall through to the cards behind it).
  final bool passive;

  SidecarDockRequest({
    required this.hostFrame,
    required this.screenFrame,
    this.dockFrame,
    this.darkMode = false,
    this.alwaysOnTop = false,
    this.floorOnly = false,
    this.passive = false,
  });

  static SidecarDockRequest? fromLaunchArgs(List<String> args) {
    final hostValue = args
        .firstWhere((arg) => arg.startsWith('--sidecar-host-frame='), orElse: () => '');
    final screenValue = args
        .firstWhere((arg) => arg.startsWith('--sidecar-screen-frame='), orElse: () => '');
    if (hostValue.isEmpty || screenValue.isEmpty) {
      return null;
    }
    final hostFrame = _parseRectArg(hostValue.split('=').last);
    final screenFrame = _parseRectArg(screenValue.split('=').last);
    if (hostFrame == null || screenFrame == null) {
      return null;
    }
    final dockValue = args
        .firstWhere((arg) => arg.startsWith('--sidecar-dock-frame='), orElse: () => '');
    final dockFrame = dockValue.isEmpty ? null : _parseRectArg(dockValue.split('=').last);
    final darkMode = args.contains('--dark-mode');
    final alwaysOnTop = args.contains('--always-on-top');
    final floorOnly = args.contains('--floor-only');
    final passive = args.contains('--passive');
    return SidecarDockRequest(hostFrame: hostFrame, screenFrame: screenFrame,
        dockFrame: dockFrame, darkMode: darkMode, alwaysOnTop: alwaysOnTop,
        floorOnly: floorOnly, passive: passive);
  }

  static SidecarDockRequest? fromJson(Map<String, dynamic> json) {
    final hostFrame = _parseRectJson(json['hostFrame']);
    final screenFrame = _parseRectJson(json['screenFrame']);
    if (hostFrame == null || screenFrame == null) {
      return null;
    }
    final dockFrame = _parseRectJson(json['dockFrame']);
    final darkMode = json['darkMode'] as bool? ?? false;
    final alwaysOnTop = json['alwaysOnTop'] as bool? ?? false;
    final floorOnly = json['floorOnly'] as bool? ?? false;
    final passive = json['passive'] as bool? ?? false;
    return SidecarDockRequest(hostFrame: hostFrame, screenFrame: screenFrame,
        dockFrame: dockFrame, darkMode: darkMode, alwaysOnTop: alwaysOnTop,
        floorOnly: floorOnly, passive: passive);
  }

  static fm.Rect? _parseRectArg(String raw) {
    final values = raw.split(',').map((value) => double.tryParse(value)).toList();
    if (values.length != 4 || values.any((value) => value == null)) {
      return null;
    }
    return fm.Rect.fromLTWH(values[0]!, values[1]!, values[2]!, values[3]!);
  }

  static fm.Rect? _parseRectJson(dynamic raw) {
    if (raw is! Map<String, dynamic>) {
      return null;
    }
    final x = (raw['x'] as num?)?.toDouble();
    final y = (raw['y'] as num?)?.toDouble();
    final width = (raw['width'] as num?)?.toDouble();
    final height = (raw['height'] as num?)?.toDouble();
    if (x == null || y == null || width == null || height == null) {
      return null;
    }
    return fm.Rect.fromLTWH(x, y, width, height);
  }
}

///  Main routine
void main(List<String> args) async {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/LICENSE.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  // Start up window manager so we can set and detect window size
  //  on desktop platforms
  fm.WidgetsFlutterBinding.ensureInitialized();
  if (TamUtils.isWindowDevice) {
    await windowManager.ensureInitialized();
  }
  // Wipe any invalid formation name saved from a prior session so the
  // SequencerPage widget doesn't crash on startup trying to look it up.
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('Starting Formation', 'Squared Set');
  final prefsWithCache = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions());
  await prefsWithCache.setString('Starting Formation', 'Squared Set');

  //  A branched TamHelper (see branch.dart) serves on its own port and remembers the one it came
  //  from, so the first TamHelper keeps 7234 — the port SquareCraft talks to — and several
  //  branches can be open at once.
  final apiPort = BranchInfo.apiPortFromLaunchArgs(args);
  if (apiPort != null) {
    tamHelperApiServer.setPort(apiPort);
  }
  tamHelperApiServer.branchInfo = BranchInfo.fromLaunchArgs(args);

  await tamHelperApiServer.start();
  tamWebBridge.allowedOrigin = '*'; // set to the Happy Hoppers origin in prod
  tamWebBridge.start();

  final tokenArg = args.firstWhere(
      (arg) => arg.startsWith('--sc-token='), orElse: () => '');
  if (tokenArg.isNotEmpty) {
    final token = tokenArg.split('=').last;
    tamHelperApiServer.setExpectedToken(token);
    ResolveClient.scAuthToken = token;
  }

  fm.runApp(TaminationsApp(initialDockRequest: SidecarDockRequest.fromLaunchArgs(args)));
}

///  Desktop: no drag-to-go-back strip down the left edge of the window.
///
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

//  TaminationsApp is the top-level widget.
//  Here it is just a wrapper for the router and its delegate (below),
//  which does all the work
//  Also holds global state and initialization futures
class TaminationsApp extends fm.StatefulWidget {
  final SidecarDockRequest? initialDockRequest;

  TaminationsApp({this.initialDockRequest});

  @override
  fm.State<fm.StatefulWidget> createState() => _TaminationsAppState();
}

class _TaminationsAppState extends fm.State<TaminationsApp> with WindowListener {
  static const sidecarTopOffset = 40.0;
  static const sidecarWidthRatio = 0.16;
  static const sidecarHeightRatio = 0.94;
  static const sidecarDarkBackground = fm.Color(0xFF000000);
  static const resolverPaneHeight = 360.0; // extra height for the resolve pushout panel (Bottom/Top)
  static const resolverPaneWidth = 380.0; // extra width for the resolve pushout panel (Left/Right)

  SidecarDockRequest? _lastDockRequest;
  bool _resolverOpen = false;
  late final TaminationsRouterDelegate _routerDelegate;
  final TaminationsRouteInformationParser _routeInformationParser =
      TaminationsRouteInformationParser();
  final ValueNotifier<bool> _darkMode = ValueNotifier(true);

  @override
  void initState() {
    super.initState();
    _routerDelegate = TaminationsRouterDelegate(
      initialMainPage: widget.initialDockRequest != null ? MainPage.SEQUENCER : null,
      initialSidecarMode: widget.initialDockRequest != null,
    );
    if (widget.initialDockRequest != null) {
      _darkMode.value = widget.initialDockRequest!.darkMode;
    }
    tamHelperApiServer.setDockWindowHandler(_handleDockRequestJson);
    //  Float / stop floating, WITHOUT moving the window (see POST /float). SquareCraft floats the
    //  sidecar only while SquareCraft itself is frontmost, so it rides above SquareCraft without
    //  sitting on top of every other app.
    tamHelperApiServer.setAlwaysOnTopHandler((onTop) async {
      await windowManager.setAlwaysOnTop(onTop);
    });
    //  Stashed out of sight when the caller turns the sidecar off mid-tip — still running, still
    //  holding its floor, so turning it back on is instant and nothing he called is lost.
    //
    //  NOT windowManager.hide(). That is orderOut(), and Flutter's macOS AppDelegate returns true
    //  from applicationShouldTerminateAfterLastWindowClosed — so ordering out the only window
    //  TERMINATES the app. Hiding it would have killed it, floor and all.
    //
    //  Transparent instead: the window stays in AppKit's list (the app lives), it cannot be seen,
    //  and it cannot be clicked. The dock request that follows an unstash restores the mouse to
    //  whatever the mode calls for.
    tamHelperApiServer.setVisibilityHandler((visible) async {
      await windowManager.setOpacity(visible ? 1.0 : 0.0);
      await windowManager.setIgnoreMouseEvents(!visible);
    });
    tamHelperApiServer.setWindowDebugInfoProvider(_windowDebugInfo);
  }

  @override
  void dispose() {
    if (TamUtils.isWindowDevice)
      windowManager.removeListener(this);
    super.dispose();
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    //  Start with various setup chores
    return fm.FutureBuilder<bool>(
        //  Read saved user settings
        future: Settings.init().whenComplete(() {
          //  Restore main window to last size and position
          if (TamUtils.isWindowDevice) {  //  i.e., Windows, MacOS
            windowManager.ensureInitialized().whenComplete(() {
              var w = Settings.windowRect;
              if (w == 'Maximized')
                windowManager.maximize();
              else {
                var nums = w.split(' ');
                if (nums.length == 4)
                  windowManager.setBounds(fm.Rect.fromLTRB(
                      nums[0].d, nums[1].d, nums[2].d, nums[3].d));
              }
              if (widget.initialDockRequest != null) {
                later(() {
                  _dockWindow(widget.initialDockRequest!);
                });
              }
              //  and listen for when user changes the window size
              windowManager.addListener(this);
            });
          }
        }),
        builder: (context, snapshot) => snapshot.hasData
            ?
            //  Wrap the Settings around the top of the program
            //  so everybody has access to them
            pp.ChangeNotifierProvider(
                create: (_) => BeatNotifier(), // needed for some of the below
                child: pp.MultiProvider(
                    providers: [
                      pp.ChangeNotifierProvider(create: (_) => Settings()),
                      pp.ChangeNotifierProvider(create: (_) => AnimationState()),
                      pp.ChangeNotifierProvider(create: (_) => DanceThemeTuning()),
                      pp.ChangeNotifierProvider(create: (_) => AbbreviationsModel()),
                      pp.ChangeNotifierProvider(create: (context) {
                        final model = SequencerModel(context);
                        tamHelperApiServer.setSequencerModel(model);
                        tamWebBridge.setSequencerModel(model);
                        return model;
                      }),
                      pp.ChangeNotifierProvider(create: (_) => HighlightState()),
                      pp.ChangeNotifierProvider(create: (_) {
                        final c = ResolverPanelController();
                        c.onOpenChanged = (open) => setResolverOpen(open);
                        return c;
                      }),
                      pp.Provider(create: (_) => VirtualKeyboardVisible())
                    ],
                    child: fm.ValueListenableBuilder<bool>(
                      valueListenable: _darkMode,
                      builder: (context, isDark, _) => fm.MaterialApp.router(
                        debugShowCheckedModeBanner: false,
                        theme: fm.ThemeData(
                          fontFamily: 'Roboto',
                          brightness: fm.Brightness.light,
                          pageTransitionsTheme: TaminationsAppTransitions.desktop,
                          textTheme: GoogleFonts.robotoTextTheme(),
                          scrollbarTheme: fm.ScrollbarThemeData(
                            thumbColor:
                                fm.WidgetStateColor.resolveWith((states) => Color.TRANSPARENTGREY),
                          ),
                        ),
                        darkTheme: fm.ThemeData(
                          fontFamily: 'Roboto',
                          brightness: fm.Brightness.dark,
                          pageTransitionsTheme: TaminationsAppTransitions.desktop,
                          scaffoldBackgroundColor: sidecarDarkBackground,
                          colorScheme: const fm.ColorScheme.dark(
                            surface: sidecarDarkBackground,
                            primary: fm.Color(0xFF90CAF9),
                          ),
                          textTheme: GoogleFonts.robotoTextTheme(fm.ThemeData.dark().textTheme),
                          scrollbarTheme: fm.ScrollbarThemeData(
                            thumbColor:
                                fm.WidgetStateColor.resolveWith((states) => Color.TRANSPARENTGREY),
                          ),
                        ),
                        themeMode: isDark ? fm.ThemeMode.dark : fm.ThemeMode.light,
                        title: 'Taminations',
                        routerDelegate: _routerDelegate,
                        routeInformationParser: _routeInformationParser,
                      ),
                    )))
            //  Future not ready yet
            : fm.Container(
                color: Color.FLOOR,
                child: fm.Center(child: fm.Image.asset('assets/src/tam87.png'))));
  }


  //  Whenever user changes the window size, save it in the settings
  //  so it can be restored next time
  @override
  void onWindowMaximize() {
    Settings.windowRect = 'Maximized';
  }

  @override
  void onWindowUnmaximize() async {
    onWindowResize();
  }

  @override
  void onWindowResize() async {
    if (TamUtils.isWindowDevice) {
      var b = await windowManager.getBounds();
      Settings.windowRect = '${b.left} ${b.top} ${b.right} ${b.bottom}';
    }
  }

  Future<void> _handleDockRequestJson(Map<String, dynamic> request) async {
    final dockRequest = SidecarDockRequest.fromJson(request);
    if (dockRequest == null) {
      throw ArgumentError('Invalid dock request payload.');
    }
    await _dockWindow(dockRequest);
  }

  Future<Map<String, dynamic>> _windowDebugInfo() async {
    if (!TamUtils.isWindowDevice) {
      return {
        'isWindowDevice': false,
      };
    }
    final bounds = await windowManager.getBounds();
    return {
      'isWindowDevice': true,
      'windowBounds': {
        'x': bounds.left,
        'y': bounds.top,
        'width': bounds.width,
        'height': bounds.height,
      },
      'savedWindowRect': Settings.windowRect,
      'routerMainPage': _routerDelegate.appState.mainPage.toString(),
      'routerDetailPage': _routerDelegate.appState.detailPage.toString(),
      'routerSidecarMode': _routerDelegate.appState.sidecarMode,
    };
  }

  Future<void> _dockWindow(SidecarDockRequest request) async {
    if (!TamUtils.isWindowDevice) {
      return;
    }
    _lastDockRequest = request;
    _darkMode.value = request.darkMode;
    //  Presenting: float above SquareCraft's full-screen black, or the floor is simply not there.
    await windowManager.setAlwaysOnTop(request.alwaysOnTop);
    //  ...and show the floor alone; the caller reads the calls off his cards.
    floorOnlyMode.value = request.floorOnly;
    //  Movable = floor-only but NOT passive: the caller has unlocked the floor to reposition it, so
    //  the floor-only view turns on its drag surface. (Editing isn't floor-only; locked presenting
    //  is passive.)
    sidecarMovable.value = request.floorOnly && !request.passive;
    //  Presenting: a display, not an app. Clicks fall through to the cards behind, and the window
    //  never takes the keyboard — his arrow keys belong to SquareCraft.
    await windowManager.setIgnoreMouseEvents(request.passive);
    double convertTopOriginY(fm.Rect rect, {double height = 0}) {
      return request.screenFrame.bottom - rect.bottom + height;
    }
    if (request.dockFrame != null) {
      final dockFrame = request.dockFrame!;
      final targetWidth = min(dockFrame.width, request.screenFrame.width);
      final targetHeight = min(dockFrame.height, request.screenFrame.height);
      final targetLeft = max(
        request.screenFrame.left,
        min(dockFrame.left, request.screenFrame.right - targetWidth),
      );
      final targetTop = max<double>(
        0,
        min<double>(
          convertTopOriginY(dockFrame),
          max(0, request.screenFrame.height - targetHeight),
        ),
      );
      await windowManager.setBounds(_applyResolverGrow(
          targetLeft, targetTop, targetWidth, targetHeight, request.screenFrame));
      await windowManager.show(inactive: request.passive);
      if (!request.passive) {
        await windowManager.focus();
      }
      return;
    }
    final targetWidth = min(
      request.hostFrame.width * sidecarWidthRatio,
      request.screenFrame.width,
    );
    final targetHeight = min(
      request.hostFrame.height * sidecarHeightRatio,
      request.screenFrame.height,
    );
    final targetLeft = min(
      request.hostFrame.right,
      request.screenFrame.right - targetWidth,
    );
    final targetTop = min<double>(
      convertTopOriginY(request.hostFrame, height: sidecarTopOffset),
      max(0, request.screenFrame.height - targetHeight),
    );
    await windowManager.setBounds(_applyResolverGrow(
        targetLeft, targetTop, targetWidth, targetHeight, request.screenFrame));
    await windowManager.show(inactive: request.passive);
    if (!request.passive) {
      await windowManager.focus();
    }
  }

  /// Grow (true) or shrink (false) the sidecar to make room for the resolve
  /// pushout panel, by re-applying the last dock request with the extra height.
  Future<void> setResolverOpen(bool open) async {
    if (_resolverOpen == open) return;
    _resolverOpen = open;
    final req = _lastDockRequest;
    if (req != null) await _dockWindow(req);
  }

  // Grows the docked sidecar rect toward the configured side to make room for
  // the resolve pushout panel, then clamps back onto the screen. Bottom/Top add
  // height; Left/Right add width. Returns the base rect unchanged when closed.
  fm.Rect _applyResolverGrow(
      double left, double top, double width, double height, fm.Rect screen) {
    if (!_resolverOpen) return fm.Rect.fromLTWH(left, top, width, height);
    switch (Settings.resolverPanelSide) {
      case 'Top':
        top -= resolverPaneHeight;
        height += resolverPaneHeight;
        break;
      case 'Left':
        left -= resolverPaneWidth;
        width += resolverPaneWidth;
        break;
      case 'Right':
        width += resolverPaneWidth;
        break;
      case 'Bottom':
      default:
        height += resolverPaneHeight;
        break;
    }
    // Keep the grown window on-screen: clamp size, then position.
    height = min(height, screen.height);
    width = min(width, screen.width);
    top = max(0.0, min(top, screen.height - height));
    left = max(screen.left, min(left, screen.right - width));
    return fm.Rect.fromLTWH(left, top, width, height);
  }
}

//  Router Delegate
//  Handles all requests to change the layout
class TaminationsRouterDelegate extends fm.RouterDelegate<TamState>
    with fm.ChangeNotifier, fm.PopNavigatorRouterDelegateMixin<TamState> {
  @override
  final fm.GlobalKey<fm.NavigatorState> navigatorKey;
  final TamState appState;

  TaminationsRouterDelegate({MainPage? initialMainPage, bool initialSidecarMode = false})
      : navigatorKey = fm.GlobalKey<fm.NavigatorState>(),
        appState = TamState(
          mainPage: initialMainPage ?? MainPage.SEQUENCER,
          detailPage: DetailPage.NONE,
          sidecarMode: initialSidecarMode,
          formation: (initialMainPage ?? MainPage.SEQUENCER) == MainPage.SEQUENCER ? 'Squared Set' : null,
          calls: (initialMainPage ?? MainPage.SEQUENCER) == MainPage.SEQUENCER ? '' : null,
        ) {
    tamHelperApiServer.setAppState(appState);
    tamWebBridge.setAppState(appState);
  }
  var _orientation = fm.Orientation.landscape;
  //  this is necessary for the web URL and back button to work
  @override
  TamState get currentConfiguration => appState;

  @override
  fm.Widget build(fm.BuildContext context) {
    if (appState.embed && appState.definition)
      return pp.ChangeNotifierProvider.value(
          value: appState, child: MarkdownFrame(appState.link ?? ''));
    if (appState.embed) {
      return pp.ChangeNotifierProvider.value(value: appState, child: AnimationForEmbed());
    }
    return _PortraitForSmallDevices(
      child: pp.ChangeNotifierProvider.value(
          value: appState,
          child: fm.OrientationBuilder(builder: (context, orientation) {
            _orientation = orientation;
            return pp.Consumer<TamState>(builder: (context, appState, _) {
              //  For small devices, force Practice in landscape,
              //  other pages in portrait
              if (isSmallDevice(context)) {
                later(() {
                  if (appState.mainPage == MainPage.STARTPRACTICE ||
                      appState.mainPage == MainPage.PRACTICE)
                    SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
                  else
                    SystemChrome.setPreferredOrientations(
                        [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
                });
              }

              return fm.Navigator(
                  key: navigatorKey,

                  //  Pages for landscape - first and second, Sequencer, Practice
                  pages: (orientation == fm.Orientation.landscape)
                      ? ((appState.mainPage == MainPage.SEQUENCER && appState.sidecarMode)
                          ? [
                              fm.MaterialPage(
                                  key: fm.ValueKey('Sequencer'), child: SequencerPage()),
                            ]
                          : [
                          fm.MaterialPage(
                              key: fm.ValueKey('First Landscape Page'),
                              child: FirstLandscapePage()),
                          if (appState.mainPage == MainPage.ANIMLIST ||
                              appState.mainPage == MainPage.ANIMATIONS)
                            fm.MaterialPage(
                                key: fm.ValueKey('Second Landscape Page'),
                                child: SecondLandscapePage()),
                          if (appState.mainPage == MainPage.PRACTICE ||
                              appState.mainPage == MainPage.TUTORIAL ||
                              appState.mainPage == MainPage.STARTPRACTICE)
                            fm.MaterialPage(
                                key: fm.ValueKey('Start Practice'), child: StartPracticePage()),
                          if (appState.mainPage == MainPage.TUTORIAL)
                            fm.MaterialPage(key: fm.ValueKey('Tutorial'), child: TutorialPage()),
                          if (appState.mainPage == MainPage.PRACTICE)
                            fm.MaterialPage(key: fm.ValueKey('Practice'), child: PracticePage()),
                          if (appState.mainPage == MainPage.SEQUENCER)
                            fm.MaterialPage(key: fm.ValueKey('Sequencer'), child: SequencerPage()),
                        ])

                      //  Pages for portrait - Level, Animlist, Animation, Settings, etc
                      : [
                          //  Root of all portrait pages shows the levels
                          fm.MaterialPage(key: fm.ValueKey('LevelPage'), child: LevelPage()),
                          //  Settings, Help single pages just below the main page
                          if (appState.mainPage == MainPage.LEVELS &&
                              appState.detailPage == DetailPage.HELP)
                            fm.MaterialPage(
                                key: fm.ValueKey('About'), child: MarkdownPage('info/about.html')),
                          if (appState.mainPage == MainPage.LEVELS &&
                              appState.detailPage == DetailPage.SETTINGS)
                            fm.MaterialPage(key: fm.ValueKey('Settings'), child: SettingsPage()),

                          //  Pages leading to animations
                          if ((appState.mainPage == MainPage.LEVELS &&
                                  appState.detailPage == DetailPage.CALLS) ||
                              appState.mainPage == MainPage.ANIMLIST ||
                              appState.mainPage == MainPage.ANIMATIONS)
                            fm.MaterialPage(key: fm.ValueKey(appState.level), child: CallsPage()),
                          if (appState.mainPage == MainPage.ANIMLIST ||
                              appState.mainPage == MainPage.ANIMATIONS)
                            fm.MaterialPage(key: fm.ValueKey(appState.link), child: AnimListPage()),
                          if (appState.mainPage == MainPage.ANIMATIONS)
                            fm.MaterialPage(
                                key: fm.ValueKey(appState.link! + ' animation'),
                                child: AnimationPage()),
                          if (appState.detailPage == DetailPage.DEFINITION)
                            fm.MaterialPage(
                                key: fm.ValueKey(appState.link! + ' definition'),
                                child: MarkdownPage(appState.link!)),
                          if (appState.mainPage != MainPage.LEVELS &&
                              appState.detailPage == DetailPage.SETTINGS)
                            fm.MaterialPage(key: fm.ValueKey('Settings'), child: SettingsPage()),

                          if (appState.mainPage == MainPage.SEQUENCER)
                            fm.MaterialPage(key: fm.ValueKey('Sequencer'), child: SequencerPage()),
                          if (appState.mainPage == MainPage.SEQUENCER &&
                              appState.detailPage == DetailPage.HELP)
                            fm.MaterialPage(
                                key: fm.ValueKey('Sequencer Help'),
                                child: MarkdownPage('info/sequencer.html')),
                          if (appState.mainPage == MainPage.SEQUENCER &&
                              appState.detailPage == DetailPage.ABBREVIATIONS)
                            fm.MaterialPage(
                                key: fm.ValueKey('Sequencer Abbreviations'),
                                child: AbbreviationsPage()),
                          if (appState.mainPage == MainPage.SEQUENCER &&
                              appState.detailPage == DetailPage.SETTINGS)
                            fm.MaterialPage(
                                key: fm.ValueKey('Sequencer Settings'),
                                child: SequencerSettingsPage()),
                          if (appState.mainPage == MainPage.SEQUENCER &&
                              appState.detailPage == DetailPage.CALLS)
                            fm.MaterialPage(
                                key: fm.ValueKey('Sequencer Calls'), child: SequencerCallsPage()),

                          //  Displaying the StartPractice page will trigger
                          //  a rotation to landscape
                          if (appState.mainPage == MainPage.STARTPRACTICE)
                            fm.MaterialPage(
                                key: fm.ValueKey('Start Practice'), child: StartPracticePage()),
                        ],

                  //  onPopPage
                  //  Calculate popped config based on current config
                  onDidRemovePage: (page) {
                    pp.Provider.of<VirtualKeyboardVisible>(context, listen: false).isVisible =
                        false;

                    //  Going to Practice from the main page
                    //  on small devices triggers this callback,
                    //  but we don't want to change the state.
                    //  So check for this.
                    if (isSmallDevice(context) && page.key == ValueKey('LevelPage')) return;

                    if (_orientation == fm.Orientation.landscape) {
                      //  Pop landscape page
                      if (appState.mainPage == MainPage.SEQUENCER ||
                          appState.mainPage == MainPage.STARTPRACTICE)
                        appState.change(
                            mainPage: MainPage.LEVELS,
                            animnum: -1,
                            detailPage: DetailPage.NONE,
                            formation: '',
                            calls: '');
                      else if (appState.mainPage == MainPage.ANIMATIONS ||
                          appState.mainPage == MainPage.ANIMLIST) {
                        appState.change(
                            mainPage: MainPage.LEVELS,
                            animnum: -1,
                            link: '',
                            detailPage: DetailPage.CALLS);
                      } else if (appState.mainPage == MainPage.PRACTICE ||
                          appState.mainPage == MainPage.TUTORIAL)
                        appState.change(mainPage: MainPage.STARTPRACTICE);
                    } else {
                      // portrait
                      if (appState.mainPage == MainPage.LEVELS) {
                        if (appState.detailPage == DetailPage.SETTINGS ||
                            appState.detailPage == DetailPage.HELP ||
                            appState.detailPage == DetailPage.CALLS)
                          appState.change(detailPage: DetailPage.NONE);
                      } else if (appState.mainPage == MainPage.ANIMLIST) {
                        if (appState.detailPage == DetailPage.SETTINGS ||
                            appState.detailPage == DetailPage.DEFINITION)
                          appState.change(detailPage: DetailPage.NONE);
                        else
                          appState.change(mainPage: MainPage.LEVELS, detailPage: DetailPage.CALLS);
                      } else if (appState.mainPage == MainPage.ANIMATIONS) {
                        if (appState.detailPage == DetailPage.SETTINGS ||
                            appState.detailPage == DetailPage.DEFINITION)
                          appState.change(detailPage: DetailPage.NONE);
                        else
                          appState.change(mainPage: MainPage.ANIMLIST);
                      } else if (appState.mainPage == MainPage.SEQUENCER) {
                        if (appState.detailPage == DetailPage.HELP ||
                            appState.detailPage == DetailPage.ABBREVIATIONS ||
                            appState.detailPage == DetailPage.SETTINGS ||
                            appState.detailPage == DetailPage.CALLS)
                          appState.change(
                              mainPage: MainPage.SEQUENCER, detailPage: DetailPage.NONE);
                        else
                          appState.change(mainPage: MainPage.LEVELS, detailPage: DetailPage.NONE);
                      } else
                        appState.change(mainPage: MainPage.LEVELS, detailPage: DetailPage.NONE);
                    }
                  });
            });
          })),
    );
  }

  @override
  Future<void> setInitialRoutePath(TamState configuration) async {
    appState.change(
        level: configuration.level,
        link: configuration.link,
        animnum: configuration.animnum,
        animname: configuration.animname,
        mainPage: configuration.mainPage,
        detailPage: configuration.detailPage,
        embed: configuration.embed,
        definition: configuration.definition,
        formation: configuration.formation ?? '',
        calls: configuration.calls ?? '');
    appState.addListener(() {
      //setNewRoutePath(appState);
      notifyListeners();
    });
  }

  @override
  Future<void> setNewRoutePath(TamState configuration) async {
    appState.change(
        level: configuration.level,
        link: configuration.link,
        animnum: configuration.animnum,
        animname: configuration.animname,
        mainPage: configuration.mainPage,
        detailPage: configuration.detailPage,
        embed: configuration.embed,
        play: configuration.play,
        loop: configuration.loop,
        grid: configuration.grid,
        definition: configuration.definition,
        formation: configuration.formation ?? '',
        calls: configuration.calls ?? '');
    notifyListeners();
  }
}

//  This class converts an URL to/from the fields in
//  TaminationsRoutePath
//  Used by web browser implementation
class TaminationsRouteInformationParser extends fm.RouteInformationParser<TamState> {
  @override
  Future<TamState> parseRouteInformation(fm.RouteInformation routeInformation) async {
    final params = routeInformation.uri.queryParameters;
    var mainPage = params['main']?.toMainPage();
    var detailPage = params['detail']?.toDetailPage();
    var level = params['level'] ?? '';
    var link = params['link'] ?? '';
    var animnum = int.tryParse(params['animnum'] ?? '-1') ?? -1;
    var animname = params['animname'];
    //  Extra embed params
    var embed = params['embed'] != null;
    var play = params['play'] != null;
    var loop = params['loop'] != null;
    var grid = params['grid'] != null;
    var definition = params['definition'] != null;
    //  For sequencer
    if (params['action'] == 'SEQUENCER') {
      mainPage = MainPage.SEQUENCER;
    }
    var formation = params['formation'];
    var calls = params['calls'];
    if (mainPage == MainPage.SEQUENCER) {
      formation = null;
      calls = null;
    }
    //  For backwards compatibility
    if (params['action'] == 'ANIMLIST') {
      mainPage = MainPage.ANIMLIST;
      detailPage = DetailPage.DEFINITION;
      level = LevelData.find(link)!.dir;
    }
    return TamState(
        mainPage: mainPage,
        detailPage: detailPage,
        level: level,
        link: link,
        animnum: animnum,
        animname: animname,
        embed: embed,
        play: play,
        loop: loop,
        grid: grid,
        definition: definition,
        formation: formation,
        calls: calls);
  }

  @override
  fm.RouteInformation restoreRouteInformation(TamState path) {
    var location = path.toString();
    return fm.RouteInformation(uri: Uri.parse('?$location'));
  }
}

class _PortraitForSmallDevices extends fm.StatefulWidget {
  final fm.Widget child;
  _PortraitForSmallDevices({required this.child});
  @override
  __PortraitForSmallDevicesState createState() => __PortraitForSmallDevicesState();
}

class __PortraitForSmallDevicesState extends fm.State<_PortraitForSmallDevices> {
  @override
  void initState() {
    super.initState();
    later(() {
      if (isSmallDevice(context)) {
        SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
      }
    });
  }

  @override
  fm.Widget build(fm.BuildContext context) {
    return widget.child;
  }
}

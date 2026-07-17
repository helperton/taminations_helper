/*

  TamHelper API Server
  Provides a local HTTP API on localhost:7234 so SquareCraft can push
  sequences into the Taminations sequencer.

  Endpoints:
    GET  /status   — health check, returns {"status":"ok"}
    GET  /state    — current dancer state: positions, facing, formation, call history
    POST /reset    — clears the current sequence
    POST /undo     — removes the last N loaded calls
    POST /float    — float above other windows, or stop. Does NOT move the window.
                     Body: { "alwaysOnTop": true }
    POST /visible  — stash the window out of sight, or bring it back. Keeps running; keeps
                     its floor. Body: { "visible": false }
    POST /splice   — a branched TamHelper coming home (see branch.dart)
                     Body: { "seedCount": N, "calls": [...], "replaceTail": false }
    POST /sequence — loads and animates a sequence
                     Body: { "formation": "Squared Set", "calls": ["call1", ...],
                             "play": true }
                     "play" (default false): after loading, rewind to where this batch
                     began and play the calls through, one after another, so every call
                     is watchable. Without it only the LAST call is seen animating —
                     loading a call starts it playing, and the next load cuts it off.
                     Returns: { "ok": true } or
                              { "ok": false, "failingIndex": N, "failingCall": "...", "error": "..." }

*/

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'branch.dart';
import 'dancer.dart';
import 'sequencer/sequencer_model.dart';
import 'tam_state.dart';

class TamHelperApiServer {
  /// The port SquareCraft talks to. The FIRST TamHelper keeps it; a branch (see branch.dart) is
  /// given its own with --api-port, so several can run at once without fighting over this one.
  static const defaultPort = 7234;
  static const debugBuildMarker = 'validate-2';

  int port = defaultPort;

  /// Where this TamHelper was branched from, if it was. Set from the launch args in main().
  BranchInfo? branchInfo;

  void setPort(int value) {
    port = value;
  }

  SequencerModel? _sequencerModel;
  TamState? _appState;
  Future<void> Function(Map<String, dynamic> request)? _dockWindow;
  Future<Map<String, dynamic>> Function()? _windowDebugInfoProvider;
  HttpServer? _server;

  // Auth: expected SC token. Null until first request arrives (TOFU).
  // Set at startup via setExpectedToken() if launched with --sc-token.
  String? _expectedScToken;

  // Debug state — updated on every /sequence request.
  String? _lastFormation;
  List<String>? _lastCalls;
  String? _lastError;
  String? _lastRequestTime;
  String? _lastResponseSummary;
  Map<String, dynamic>? _lastDockRequest;
  String? _lastDockResult;

  void setSequencerModel(SequencerModel model) {
    _sequencerModel = model;
  }

  void setAppState(TamState state) {
    _appState = state;
  }

  void setExpectedToken(String? token) {
    if (token != null && token.isNotEmpty) {
      _expectedScToken = token;
    }
  }

  // Returns true and establishes the expected token (TOFU) on first use.
  // After the token is locked in, rejects requests with a missing or wrong token.
  bool _isAuthorized(Request request) {
    final incoming = request.headers['x-sc-token'] ?? '';
    if (_expectedScToken == null) {
      if (incoming.isNotEmpty) {
        _expectedScToken = incoming;
      }
      return true;
    }
    return incoming == _expectedScToken;
  }

  void setDockWindowHandler(Future<void> Function(Map<String, dynamic> request) handler) {
    _dockWindow = handler;
  }

  Future<void> Function(bool onTop)? _setAlwaysOnTop;

  void setAlwaysOnTopHandler(Future<void> Function(bool onTop) handler) {
    _setAlwaysOnTop = handler;
  }

  Future<void> Function(bool visible)? _setVisible;

  void setVisibilityHandler(Future<void> Function(bool visible) handler) {
    _setVisible = handler;
  }

  void setWindowDebugInfoProvider(Future<Map<String, dynamic>> Function() provider) {
    _windowDebugInfoProvider = provider;
  }

  Future<void> start() async {
    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(_router);
    try {
      _server = await shelf_io.serve(handler, 'localhost', port);
    } on SocketException catch (e) {
      //  DON'T RUN IF THE PORT IS ALREADY IN USE.
      //
      //  Another TamHelper already owns :$port. SquareCraft talks to exactly one TamHelper there,
      //  so a second is useless — and left to itself the unhandled bind error either crashes this
      //  process (the window appears while Flutter boots, then vanishes) or leaves it windowed but
      //  API-less. Both wedge the sidecar. Bow out cleanly instead: the instance that HAS the port
      //  stays the only one, and SquareCraft's recovery (kill a wedged one, relaunch) gets a clean
      //  port to bind.
      //
      //  This runs before runApp(), so a second instance never even shows a window.
      stderr.writeln('[TamHelper] localhost:$port is already in use — another TamHelper owns it; '
          'exiting. ($e)');
      exit(0);
    }
    // ignore: avoid_print
    print('[TamHelper] API server listening on localhost:$port');
  }

  // MARK: - Experimental splice: branching (see branch.dart)

  /// Opens a SECOND TamHelper, seeded with `calls` — the sequence up to and including the call
  /// that was right-clicked. It is a whole separate process with its own window and its own API
  /// port, so several branches can be open at once and sit side by side.
  ///
  /// Returns the branch's port, or throws with a reason the caller can show.
  Future<int> launchBranch({
    required List<String> calls,
    required String formation,
    required String parentName,
  }) async {
    //  Let the OS name a free port rather than guessing at one.
    final probe = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final childPort = probe.port;
    await probe.close();

    final args = <String>[
      '${BranchInfo.apiPortArg}$childPort',
      '${BranchInfo.parentPortArg}$port',
      '${BranchInfo.parentNameArg}$parentName',
      '${BranchInfo.seedCountArg}${calls.length}',
      //  The branch has to authenticate to us to splice back, and SquareCraft may want to talk to
      //  it too — so it inherits our token.
      if (_expectedScToken != null && _expectedScToken!.isNotEmpty)
        '--sc-token=$_expectedScToken',
    ];

    await Process.start(
      Platform.resolvedExecutable,
      args,
      mode: ProcessStartMode.detached,
    );

    //  Wait for the new window's API to answer, then push the calls into it. Seeding over the API
    //  we already serve beats trying to squeeze a whole sequence through the command line.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline)) {
      final status = await _get(childPort, '/status');
      if (status != null && status['ready'] == true) {
        final seeded = await _post(childPort, '/sequence', {
          'formation': formation,
          'calls': calls,
          'reset': true,
          'play': false,
        });
        if (seeded != null && seeded['ok'] == true) {
          return childPort;
        }
        throw 'The branch opened but would not take the calls: ${seeded?['error'] ?? 'no answer'}';
      }
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    throw 'The branch did not come up within 30 seconds.';
  }

  /// Splices this branch's sequence back into the TamHelper it came from.
  ///
  /// `replaceTail: false` first tries to keep the parent's calls that came AFTER the branch point
  /// and re-run them; if one of them no longer works, nothing changes and the failure comes back so
  /// the caller can offer to replace them instead.
  Future<SpliceOutcome> spliceIntoParent({
    required List<String> branchCalls,
    required bool replaceTail,
  }) async {
    final branch = branchInfo;
    if (branch == null) {
      return SpliceOutcome(ok: false, error: 'This TamHelper is not a branch of another.');
    }
    final answer = await _post(branch.parentPort, '/splice', {
      'seedCount': branch.seedCount,
      'calls': branchCalls,
      'replaceTail': replaceTail,
    });
    if (answer == null) {
      return SpliceOutcome(
          ok: false, error: 'The parent TamHelper did not answer — is it still open?');
    }
    return SpliceOutcome(
      ok: answer['ok'] == true,
      error: answer['error'] as String?,
      failingCall: answer['failingCall'] as String?,
      brokenTail: (answer['brokenTail'] as List?)?.cast<String>() ?? const [],
    );
  }

  /// Shuts this branch's window. Discarding an experiment should take the whole window with it.
  void closeBranchWindow() {
    exit(0);
  }

  Future<Map<String, dynamic>?> _get(int onPort, String path) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('http://localhost:$onPort$path'));
      _authorize(request);
      final response = await request.close();
      final body = await response.transform(const Utf8Decoder()).join();
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>?> _post(
      int onPort, String path, Map<String, dynamic> body) async {
    final client = HttpClient();
    try {
      final request = await client.postUrl(Uri.parse('http://localhost:$onPort$path'));
      request.headers.contentType = ContentType.json;
      _authorize(request);
      request.write(jsonEncode(body));
      final response = await request.close();
      final text = await response.transform(const Utf8Decoder()).join();
      return jsonDecode(text) as Map<String, dynamic>;
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }

  void _authorize(HttpClientRequest request) {
    final token = _expectedScToken;
    if (token != null && token.isNotEmpty) {
      request.headers.set('x-sc-token', token);
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
  }

  // Allow SquareCraft (or a local browser test page) to call the API.
  Middleware _corsMiddleware() {
    return (Handler innerHandler) {
      return (Request request) async {
        if (request.method == 'OPTIONS') {
          return Response.ok('', headers: _corsHeaders());
        }
        final response = await innerHandler(request);
        return response.change(headers: _corsHeaders());
      };
    };
  }

  Map<String, String> _corsHeaders() => {
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type',
      };

  Future<Response> _router(Request request) async {
    final path = request.url.path;

    if (!_isAuthorized(request)) {
      return Response(403,
          body: jsonEncode({'error': 'unauthorized'}),
          headers: {'Content-Type': 'application/json'});
    }

    if (request.method == 'GET' && path == 'status') {
      final ready = _appState != null;
      return _jsonOk({'status': 'ok', 'port': port, 'ready': ready});
    }

    if (request.method == 'GET' && path == 'debug') {
      final windowDebugInfo = await _windowDebugInfoProvider?.call();
      final runtimeBuildInfo = _runtimeBuildInfo();
      // Live playback position, so a caller can see whether the floor is actually animating
      // (and from where) rather than parked on the last call.
      final anim = _sequencerModel?.animation;
      return _jsonOk({
        'debugBuildMarker': debugBuildMarker,
        'runtimeBuildInfo': runtimeBuildInfo,
        'playing': anim?.beater.isRunning ?? false,
        'beat': anim == null ? null : (anim.beater.beat * 10).round() / 10.0,
        'totalBeats': anim == null ? null : (anim.beats * 10).round() / 10.0,
        'authTokenSet': _expectedScToken != null,
        'sequencerModelSet': _sequencerModel != null,
        'appStateSet': _appState != null,
        'ready': _appState != null,
        'currentMainPage': _appState?.mainPage.toString(),
        'lastRequestTime': _lastRequestTime,
        'lastFormation': _lastFormation,
        'lastCallCount': _lastCalls?.length,
        'lastCalls': _lastCalls,
        'lastError': _lastError,
        'lastResponseSummary': _lastResponseSummary,
        'lastDockRequest': _lastDockRequest,
        'lastDockResult': _lastDockResult,
        'windowDebugInfo': windowDebugInfo,
      });
    }

    if (request.method == 'POST' && path == 'reset') {
      _sequencerModel?.reset();
      return _jsonOk({'ok': true});
    }

    if (request.method == 'POST' && path == 'undo') {
      return await _handleUndo(request);
    }

    if (request.method == 'POST' && path == 'float') {
      return _handleFloat(request);
    }

    if (request.method == 'POST' && path == 'visible') {
      return _handleVisible(request);
    }

    if (request.method == 'POST' && path == 'splice') {
      return _handleSplice(request);
    }

    if (request.method == 'POST' && path == 'sequence') {
      return await _handleSequence(request);
    }

    if (request.method == 'POST' && path == 'validate') {
      return await _handleValidate(request);
    }

    if (request.method == 'GET' && path == 'state') {
      return _handleState();
    }

    if (request.method == 'POST' && path == 'exit') {
      stop();
      exit(0);
    }

    if (request.method == 'POST' && path == 'dock') {
      return await _handleDock(request);
    }

    return Response.notFound('{"error":"not found"}',
        headers: {'Content-Type': 'application/json'});
  }

  Map<String, dynamic> _runtimeBuildInfo() {
    final executableFile = File(Platform.resolvedExecutable);
    final executablePath = executableFile.path;
    final executableStat = executableFile.existsSync() ? executableFile.statSync() : null;

    final appContentsDirectory = executableFile.parent.parent;
    final kernelBlobFile = File(
      '${appContentsDirectory.path}/Frameworks/App.framework/Resources/flutter_assets/kernel_blob.bin',
    );
    final kernelBlobStat = kernelBlobFile.existsSync() ? kernelBlobFile.statSync() : null;

    return {
      'executablePath': executablePath,
      'executableModifiedAt': executableStat?.modified.toIso8601String(),
      'kernelBlobPath': kernelBlobFile.path,
      'kernelBlobModifiedAt': kernelBlobStat?.modified.toIso8601String(),
    };
  }

  Future<Response> _handleDock(Request request) async {
    final dockWindow = _dockWindow;
    if (dockWindow == null) {
      return _jsonOk({'ok': false, 'error': 'dock handler not ready'});
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }

    try {
      _lastDockRequest = body;
      _appState?.change(
        mainPage: MainPage.SEQUENCER,
        detailPage: DetailPage.NONE,
        sidecarMode: true,
        formation: 'Squared Set',
        calls: '',
      );
      await dockWindow(body);
      _lastDockResult = 'ok';
      return _jsonOk({'ok': true});
    } catch (error) {
      _lastDockResult = '$error';
      return _jsonOk({'ok': false, 'error': '$error'});
    }
  }

  Future<Response> _handleUndo(Request request) async {
    final model = _sequencerModel;
    if (model == null) {
      return _jsonOk({'ok': false, 'error': 'sequencer not ready'});
    }

    final Map<String, dynamic> body;
    try {
      final rawBody = await request.readAsString();
      body = rawBody.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(rawBody) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }

    final count = (body['count'] as num?)?.toInt() ?? 1;
    if (count < 0) {
      return Response(400,
          body: jsonEncode({'error': '"count" must be zero or greater'}),
          headers: {'Content-Type': 'application/json'});
    }

    for (var i = 0; i < count; i++) {
      model.undoLastCall();
    }
    return _jsonOk({'ok': true, 'undone': count});
  }

  /// Stash the window out of sight, or bring it back. NOTHING ELSE — the sidecar keeps running and
  /// keeps its floor, so unstashing is instant and the sequence is still there. (Hidden, not killed:
  /// the caller turns the sidecar off mid-tip and back on, and should not lose what he has called.)
  Future<Response> _handleVisible(Request request) async {
    final Map<String, dynamic> body;
    try {
      final raw = await request.readAsString();
      body = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }
    final visible = body['visible'] as bool? ?? true;
    await _setVisible?.call(visible);
    _lastResponseSummary = 'visible = $visible';
    return _jsonOk({'ok': true, 'visible': visible});
  }

  /// Float above the other windows, or stop. NOTHING ELSE — the window does not move.
  ///
  /// SquareCraft's presentation is full screen, so the sidecar has to float above it or it is not
  /// seen at all. But floating on macOS is GLOBAL: it would sit over the browser and everything
  /// else too. So SquareCraft floats it only while SquareCraft itself is the active app, and drops
  /// it the moment you switch away — the sidecar rides above SquareCraft, and nothing more.
  Future<Response> _handleFloat(Request request) async {
    final Map<String, dynamic> body;
    try {
      final raw = await request.readAsString();
      body = raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }
    final onTop = body['alwaysOnTop'] as bool? ?? false;
    await _setAlwaysOnTop?.call(onTop);
    _lastResponseSummary = 'alwaysOnTop = $onTop';
    return _jsonOk({'ok': true, 'alwaysOnTop': onTop});
  }

  /// A branch coming home. Body: { seedCount, calls (the branch's WHOLE sequence), replaceTail }.
  ///
  /// The branch already carries our first `seedCount` calls, so it replaces them. What's at stake
  /// is our TAIL — the calls after the branch point. We re-run them after the branch's; if one no
  /// longer works we change NOTHING and name it, so the branch can offer to drop them instead.
  Future<Response> _handleSplice(Request request) async {
    final model = _sequencerModel;
    if (model == null) {
      return _jsonOk({'ok': false, 'error': 'sequencer not ready'});
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }

    final seedCount = (body['seedCount'] as num?)?.toInt();
    final rawCalls = body['calls'];
    if (seedCount == null || seedCount < 0 || rawCalls is! List) {
      return Response(400,
          body: jsonEncode({'error': '"seedCount" (int) and "calls" (array) are required'}),
          headers: {'Content-Type': 'application/json'});
    }
    final branchCalls = rawCalls.cast<String>();
    final replaceTail = (body['replaceTail'] as bool?) ?? false;

    final parentCalls = model.callNames;
    final tail = parentTail(parentCalls: parentCalls, seedCount: seedCount);

    final failed = model.rebuildSequence(splicedSequence(
      parentCalls: parentCalls,
      branchCalls: branchCalls,
      seedCount: seedCount,
      replaceTail: replaceTail,
    ));

    if (failed == null) {
      _lastResponseSummary =
          'spliced ${branchCalls.length} call(s)${replaceTail ? ', tail replaced' : ''}';
      return _jsonOk({
        'ok': true,
        'callCount': model.calls.length,
        'replacedTail': replaceTail,
      });
    }

    //  It didn't take, and rebuildSequence left us exactly as we were. Now: WHOSE fault was it?
    //  Only a failure in our TAIL can be fixed by dropping the tail. If the branch itself doesn't
    //  dance, offering to "replace everything after" would be a lie — it would fail again.
    _lastError = failed;

    if (!replaceTail && _sequenceDances(model, branchCalls, restoringTo: parentCalls)) {
      _lastResponseSummary = 'splice refused — "$failed" no longer works after the branch';
      return _jsonOk({
        'ok': false,
        'failingCall': failed,
        //  What we would have to drop for this branch to land.
        'brokenTail': tail,
        'error': '"$failed" no longer works after the branch.',
      });
    }

    _lastResponseSummary = 'splice refused — the branch itself does not dance ("$failed")';
    return _jsonOk({
      'ok': false,
      'failingCall': failed,
      'brokenTail': <String>[],
      'error': 'The branch itself does not dance: "$failed".',
    });
  }

  /// Would `calls` dance on their own? Leaves the model holding `restoringTo` either way — this is
  /// a question, not an edit.
  bool _sequenceDances(SequencerModel model, List<String> calls, {required List<String> restoringTo}) {
    final failed = model.rebuildSequence(List<String>.from(calls));
    if (failed == null) {
      //  They danced, so the model is now holding THEM. Put the sequence back.
      model.rebuildSequence(restoringTo);
      return true;
    }
    //  They didn't, so rebuildSequence already restored what was there.
    return false;
  }

  //  /sequence mutates the ONE shared sequencer model (navigate → reset → load → play). Two
  //  overlapping requests — a manual Play-in-TH landing on top of the presentation follower, a
  //  double click — would tear the model down under each other, and the loser threw past the
  //  handler's guards into a shelf 500 (a non-JSON body SquareCraft reports as "Unexpected
  //  response"). Serialize them: one sequence at a time.
  Future<void> _sequenceGate = Future.value();

  Future<Response> _handleSequence(Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }

    //  Chain behind whatever sequence is already running, and let the next one chain behind us.
    final completer = Completer<void>();
    final previous = _sequenceGate;
    _sequenceGate = completer.future;
    try {
      await previous;
      //  The handler must ALWAYS speak JSON. Its inner sections guard the expected failures
      //  (bad formation, an undanceable call); this is the backstop for the unexpected — a torn
      //  model, an animation in a bad state — so nothing can escape as a 500.
      try {
        return await _runSequence(body);
      } catch (e, st) {
        _lastError = '$e';
        _lastResponseSummary = 'sequence threw';
        // ignore: avoid_print
        print('[TamHelper] /sequence threw: $e\n$st');
        return _jsonOk({
          'ok': false,
          'failingIndex': null,
          'failingCall': null,
          'error': 'TamHelper hit an internal error loading the sequence: $e',
        });
      }
    } finally {
      completer.complete();
    }
  }

  Future<Response> _runSequence(Map<String, dynamic> body) async {
    final formation = (body['formation'] as String?) ?? 'Squared Set';
    final shouldReset = (body['reset'] as bool?) ?? true;
    final shouldPlayThrough = (body['play'] as bool?) ?? false;
    final rawCalls = body['calls'];
    if (rawCalls == null || rawCalls is! List) {
      return Response(400,
          body: jsonEncode({'error': '"calls" must be a JSON array'}),
          headers: {'Content-Type': 'application/json'});
    }
    final calls = rawCalls.cast<String>();

    // Record debug state.
    _lastRequestTime = DateTime.now().toIso8601String();
    _lastFormation = formation;
    _lastCalls = List<String>.from(calls);
    _lastError = null;
    _lastResponseSummary = null;

    // Navigate to the sequencer page with fresh state from this request.
    _appState?.change(
      mainPage: MainPage.SEQUENCER,
      formation: formation,
      calls: '',
      sidecarMode: true,
    );
    final model = await _waitForSequencerModel();
    if (model == null) {
      _lastError = 'Sequencer model was not created after navigating to the Sequencer page.';
      _lastResponseSummary = 'sequencer not ready';
      return _jsonOk({
        'ok': false,
        'failingIndex': null,
        'failingCall': null,
        'error': _lastError,
      });
    }

    if (shouldReset) {
      // Reset to fresh state with the requested formation.
      try {
        model.setStartingFormation(formation);
        model.reset();
      } catch (e) {
        _lastError = 'Formation error: $e';
        _lastResponseSummary = 'failed at formation';
        return _jsonOk({
          'ok': false,
          'failingIndex': null,
          'failingCall': null,
          'error': _lastError,
        });
      }
    }

    // Where this batch starts on the timeline: 0 after a reset, otherwise the end of what
    // is already loaded. `play` rewinds here so the batch animates from its first call.
    final batchStartBeat = model.animation.beats;

    // Load calls one by one so we can report the exact failure index.
    for (var i = 0; i < calls.length; i++) {
      try {
        model.animation.doPause();
        final ok = model.loadOneCall(calls[i]);
        if (!ok) {
          _lastError = model.errorString;
          _lastResponseSummary = 'failed at call $i: ${calls[i]}';
          return _jsonOk({
            'ok': false,
            'failingIndex': i,
            'failingCall': calls[i],
            'error': _lastError,
          });
        }
      } catch (e) {
        _lastError = '$e';
        _lastResponseSummary = 'exception at call $i: ${calls[i]}';
        return _jsonOk({
          'ok': false,
          'failingIndex': i,
          'failingCall': calls[i],
          'error': _lastError,
        });
      }
    }

    if (shouldPlayThrough) {
      // Loading a call leaves it playing from its own start beat, so after the loop only the
      // LAST call is on screen. Rewind to the batch start and play the whole thing through:
      // each call animates in turn, and the next begins when the previous finishes.
      model.animation.goToBeat(batchStartBeat);
      model.animation.doPlay();
    }

    _lastResponseSummary =
        'ok — loaded ${calls.length} call(s)${shouldPlayThrough ? ', playing through' : ''}';
    return _jsonOk({'ok': true, 'callCount': calls.length, 'playing': shouldPlayThrough});
  }

  /// Batch validation: runs an entire call sequence in-process and returns each
  /// call's detected formation + measured beats in ONE response, so callers don't
  /// pay a /sequence + /state HTTP round-trip per call. Generic TH capability — no
  /// caller-specific interpretation here (resolves-home, timing adoption, etc. are
  /// the client's concern).
  Future<Response> _handleValidate(Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }

    final formation = (body['formation'] as String?) ?? 'Squared Set';
    final rawCalls = body['calls'];
    if (rawCalls == null || rawCalls is! List) {
      return Response(400,
          body: jsonEncode({'error': '"calls" must be a JSON array'}),
          headers: {'Content-Type': 'application/json'});
    }
    final calls = rawCalls.cast<String>();

    _lastRequestTime = DateTime.now().toIso8601String();
    _lastFormation = formation;
    _lastCalls = List<String>.from(calls);
    _lastError = null;
    _lastResponseSummary = null;

    _appState?.change(
      mainPage: MainPage.SEQUENCER,
      formation: formation,
      calls: '',
      sidecarMode: true,
    );
    final model = await _waitForSequencerModel();
    if (model == null) {
      _lastError = 'Sequencer model was not created after navigating to the Sequencer page.';
      return _jsonOk({
        'ok': false, 'failingIndex': null, 'failingCall': null,
        'error': _lastError, 'perCall': <Map<String, dynamic>>[],
      });
    }

    try {
      model.setStartingFormation(formation);
      model.reset();
    } catch (e) {
      _lastError = 'Formation error: $e';
      return _jsonOk({
        'ok': false, 'failingIndex': null, 'failingCall': null,
        'error': _lastError, 'perCall': <Map<String, dynamic>>[],
      });
    }

    final perCall = <Map<String, dynamic>>[];
    for (var i = 0; i < calls.length; i++) {
      try {
        model.animation.doPause();
        final ok = model.loadOneCall(calls[i]);
        if (!ok) {
          _lastError = model.errorString;
          _lastResponseSummary = 'failed at call $i: ${calls[i]}';
          return _jsonOk({
            'ok': false, 'failingIndex': i, 'failingCall': calls[i],
            'error': _lastError, 'perCall': perCall,
          });
        }
      } catch (e) {
        _lastError = '$e';
        _lastResponseSummary = 'exception at call $i: ${calls[i]}';
        return _jsonOk({
          'ok': false, 'failingIndex': i, 'failingCall': calls[i],
          'error': '$e', 'perCall': perCall,
        });
      }

      // Snapshot detected formation + measured beats for this call (same detection as /state).
      final ctx = model.contextFromAnimation();
      ctx.analyze();
      String? detectedFormation;
      if (ctx.isSquare()) detectedFormation = 'Squared Set';
      else if (ctx.isWaves()) detectedFormation = 'Waves';
      else if (ctx.isTwoFacedLines()) detectedFormation = 'Two-Faced Lines';
      else if (ctx.isLines()) detectedFormation = 'Lines';
      else if (ctx.isColumns()) detectedFormation = 'Columns';
      else if (ctx.isTidal()) detectedFormation = 'Tidal';
      else if (ctx.isThar()) detectedFormation = 'Thar';
      else if (ctx.isDiamond()) detectedFormation = 'Diamond';
      else if (ctx.isTBone()) detectedFormation = 'T-Bone';
      final beats = model.calls.isNotEmpty ? model.calls.last.beats : 0.0;
      perCall.add({
        'call': calls[i],
        'detectedFormation': detectedFormation,
        'beats': (beats * 10).round() / 10.0,
      });
    }

    _lastResponseSummary = 'validated ${calls.length} call(s)';
    return _jsonOk({'ok': true, 'callCount': calls.length, 'perCall': perCall});
  }

  Response _handleState() {
    final model = _sequencerModel;
    if (model == null) {
      return _jsonOk({'ok': false, 'error': 'sequencer not ready'});
    }

    try {
      final ctx = model.contextFromAnimation();
      ctx.analyze();

      final dancers = <Map<String, dynamic>>[];
      for (final d in ctx.dancers) {
        dancers.add({
          'number': d.number,
          'couple': d.numberCouple,
          'gender': d.gender == Gender.BOY ? 'boy' : d.gender == Gender.GIRL ? 'girl' : 'phantom',
          'x': (d.location.x * 1000).round() / 1000.0,
          'y': (d.location.y * 1000).round() / 1000.0,
          'angleDegrees': (d.angleFacing * 180 / pi * 10).round() / 10.0,
          'beau': d.data.beau,
          'belle': d.data.belle,
          'leader': d.data.leader,
          'trailer': d.data.trailer,
          'center': d.data.center,
          'end': d.data.end,
        });
      }

      String? detectedFormation;
      if (ctx.isSquare()) detectedFormation = 'Squared Set';
      else if (ctx.isWaves()) detectedFormation = 'Waves';
      else if (ctx.isTwoFacedLines()) detectedFormation = 'Two-Faced Lines';
      else if (ctx.isLines()) detectedFormation = 'Lines';
      else if (ctx.isColumns()) detectedFormation = 'Columns';
      else if (ctx.isTidal()) detectedFormation = 'Tidal';
      else if (ctx.isThar()) detectedFormation = 'Thar';
      else if (ctx.isDiamond()) detectedFormation = 'Diamond';
      else if (ctx.isTBone()) detectedFormation = 'T-Bone';

      final warning = model.errorString.isNotEmpty ? model.errorString : null;
      final totalBeats = model.totalBeats();
      final lastCallBeats = model.calls.isNotEmpty ? model.calls.last.beats : 0.0;

      return _jsonOk({
        'ok': true,
        'callCount': model.calls.length,
        'calls': model.calls.map((c) => c.name).toList(),
        'callLevels': model.calls.map((c) => c.level?.dir ?? '').toList(),
        'startingFormation': model.startingFormation,
        'detectedFormation': detectedFormation,
        'warning': warning,
        'lastFailedCall': model.lastFailedCall,
        'totalBeats': (totalBeats * 10).round() / 10.0,
        'lastCallBeats': (lastCallBeats * 10).round() / 10.0,
        'dancers': dancers,
      });
    } catch (e) {
      return _jsonOk({'ok': false, 'error': 'Failed to read state: $e'});
    }
  }

  /// Returns a human-readable debug snapshot for display in the UI.
  Map<String, dynamic> debugSnapshot() => {
        'sequencerModelSet': _sequencerModel != null,
        'appStateSet': _appState != null,
        'ready': _appState != null,
        'currentMainPage': _appState?.mainPage.toString() ?? '(null)',
        'lastRequestTime': _lastRequestTime ?? '(none)',
        'lastFormation': _lastFormation ?? '(none)',
        'lastCallCount': _lastCalls?.length ?? 0,
        'lastCalls': _lastCalls ?? [],
        'lastError': _lastError ?? '(none)',
        'lastResponseSummary': _lastResponseSummary ?? '(none)',
      };

  Future<SequencerModel?> _waitForSequencerModel() async {
    for (var attempt = 0; attempt < 25; attempt++) {
      final model = _sequencerModel;
      if (model != null) {
        return model;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    return null;
  }

  Response _jsonOk(Map<String, dynamic> data) => Response.ok(
        jsonEncode(data),
        headers: {'Content-Type': 'application/json'},
      );
}

/// Singleton accessible from main.dart and anywhere that needs to set context.
final tamHelperApiServer = TamHelperApiServer();

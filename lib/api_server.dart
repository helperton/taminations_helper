/*

  TamHelper API Server
  Provides a local HTTP API on localhost:7234 so SquareCraft can push
  sequences into the Taminations sequencer.

  Endpoints:
    GET  /status   — health check, returns {"status":"ok"}
    GET  /state    — current dancer state: positions, facing, formation, call history
    POST /reset    — clears the current sequence
    POST /undo     — removes the last N loaded calls
    POST /sequence — loads and animates a sequence
                     Body: { "formation": "Squared Set", "calls": ["call1", ...] }
                     Returns: { "ok": true } or
                              { "ok": false, "failingIndex": N, "failingCall": "...", "error": "..." }

*/

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'dancer.dart';
import 'sequencer/sequencer_model.dart';
import 'tam_state.dart';

class TamHelperApiServer {
  static const port = 7234;
  static const debugBuildMarker = 'dock-debug-8';

  SequencerModel? _sequencerModel;
  TamState? _appState;
  Future<void> Function(Map<String, dynamic> request)? _dockWindow;
  Future<Map<String, dynamic>> Function()? _windowDebugInfoProvider;
  HttpServer? _server;

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

  void setDockWindowHandler(Future<void> Function(Map<String, dynamic> request) handler) {
    _dockWindow = handler;
  }

  void setWindowDebugInfoProvider(Future<Map<String, dynamic>> Function() provider) {
    _windowDebugInfoProvider = provider;
  }

  Future<void> start() async {
    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(_router);
    _server = await shelf_io.serve(handler, 'localhost', port);
    // ignore: avoid_print
    print('[TamHelper] API server listening on localhost:$port');
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

    if (request.method == 'GET' && path == 'status') {
      final ready = _appState != null;
      return _jsonOk({'status': 'ok', 'port': port, 'ready': ready});
    }

    if (request.method == 'GET' && path == 'debug') {
      final windowDebugInfo = await _windowDebugInfoProvider?.call();
      final runtimeBuildInfo = _runtimeBuildInfo();
      return _jsonOk({
        'debugBuildMarker': debugBuildMarker,
        'runtimeBuildInfo': runtimeBuildInfo,
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

    if (request.method == 'POST' && path == 'sequence') {
      return await _handleSequence(request);
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

  Future<Response> _handleSequence(Request request) async {
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(await request.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return Response(400,
          body: jsonEncode({'error': 'invalid JSON body'}),
          headers: {'Content-Type': 'application/json'});
    }

    final formation = (body['formation'] as String?) ?? 'Squared Set';
    final shouldReset = (body['reset'] as bool?) ?? true;
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

    _lastResponseSummary = 'ok — loaded ${calls.length} call(s)';
    return _jsonOk({'ok': true, 'callCount': calls.length});
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

      return _jsonOk({
        'ok': true,
        'callCount': model.calls.length,
        'calls': model.calls.map((c) => c.name).toList(),
        'startingFormation': model.startingFormation,
        'detectedFormation': detectedFormation,
        'warning': warning,
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

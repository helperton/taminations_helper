/*

  TamHelper API Server
  Provides a local HTTP API on localhost:7234 so SquareCraft can push
  sequences into the Taminations sequencer.

  Endpoints:
    GET  /status   — health check, returns {"status":"ok"}
    POST /reset    — clears the current sequence
    POST /undo     — removes the last N loaded calls
    POST /sequence — loads and animates a sequence
                     Body: { "formation": "Squared Set", "calls": ["call1", ...] }
                     Returns: { "ok": true } or
                              { "ok": false, "failingIndex": N, "failingCall": "...", "error": "..." }

*/

import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;

import 'sequencer/sequencer_model.dart';
import 'tam_state.dart';

class TamHelperApiServer {
  static const port = 7234;

  SequencerModel? _sequencerModel;
  TamState? _appState;
  HttpServer? _server;

  // Debug state — updated on every /sequence request.
  String? _lastFormation;
  List<String>? _lastCalls;
  String? _lastError;
  String? _lastRequestTime;
  String? _lastResponseSummary;

  void setSequencerModel(SequencerModel model) {
    _sequencerModel = model;
  }

  void setAppState(TamState state) {
    _appState = state;
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
      return _jsonOk({
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

    return Response.notFound('{"error":"not found"}',
        headers: {'Content-Type': 'application/json'});
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
    _appState?.change(mainPage: MainPage.SEQUENCER, formation: formation, calls: '');
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

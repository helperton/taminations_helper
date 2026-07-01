// lib/tam_web_bridge.dart  (WEB ONLY — uses dart:html; conditionally imported)
//
// Browser transport for TamHelper: the web sibling of api_server.dart. A shelf
// HTTP server can't run in a browser, so on web we talk to the embedding page
// over window.postMessage. The controller logic (drive SequencerModel.loadOneCall,
// report the failing call, read the formation) mirrors the HTTP handlers.
//
// Uses dart:html (no new pubspec dependency). If you prefer the modern stack,
// swap to package:web + dart:js_interop and add `web:` to pubspec.
//
// Protocol — parent page -> iframe (each may carry a `requestId`, echoed back):
//   {type:'sequence', formation, calls:[...], reset:bool}
//   {type:'call',     call:'SQUARE THRU 2'}     // append + animate ONE call
//   {type:'reset',    formation}
//   {type:'undo',     count:1}
//   {type:'state'}
// Replies — iframe -> parent:
//   {type:'tam-ready'}                          // once, when the model is wired
//   {type:'sequence-result'|'call-result'|'reset-result'|'undo-result'|'state-result',
//    requestId, ok, failingIndex?, failingCall?, error?, ...state}

import 'dart:html' as html;

import 'sequencer/sequencer_model.dart';
import 'tam_state.dart';

class TamWebBridge {
  SequencerModel? _model;
  TamState? _appState;

  /// Origin allowed to drive the bridge; also the postMessage targetOrigin.
  /// Pin to the site origin in prod (e.g. 'https://happyhoppers.org'); '*' is
  /// for a local test page only.
  String allowedOrigin = '*';

  void setSequencerModel(SequencerModel m) {
    _model = m;
    _post({'type': 'tam-ready'}); // model is up — host may start sending
  }

  void setAppState(TamState s) => _appState = s;

  void start() {
    html.window.onMessage.listen(_onMessage);
    if (_model != null) _post({'type': 'tam-ready'});
  }

  void _onMessage(html.MessageEvent e) {
    if (allowedOrigin != '*' && e.origin != allowedOrigin) return;
    final data = e.data;
    if (data is! Map) return;
    final msg = Map<String, dynamic>.from(data);
    final type = msg['type'];
    final id = msg['requestId'];
    if (type is! String) return;

    switch (type) {
      case 'sequence':
        _reply('sequence-result', id, _handleSequence(msg));
        break;
      case 'call':
        _reply('call-result', id, _handleCall(msg));
        break;
      case 'reset':
        _reply('reset-result', id, _handleReset(msg));
        break;
      case 'undo':
        final n = (msg['count'] as num?)?.toInt() ?? 1;
        for (var i = 0; i < n; i++) _model?.undoLastCall();
        _reply('undo-result', id, {'ok': true, 'undone': n, ..._state()});
        break;
      case 'state':
        _reply('state-result', id, _state());
        break;
    }
  }

  // ── handlers (same logic as api_server.dart, minus HTTP) ──────────────────

  Map<String, dynamic> _handleReset(Map<String, dynamic> msg) {
    final model = _model;
    if (model == null) return {'ok': false, 'error': 'sequencer not ready'};
    final formation = (msg['formation'] as String?) ?? 'Squared Set';
    try {
      _appState?.change(
          mainPage: MainPage.SEQUENCER, formation: formation, calls: '', sidecarMode: true);
      model.setStartingFormation(formation);
      model.reset();
      return {'ok': true, ..._state()};
    } catch (e) {
      return {'ok': false, 'error': 'Formation error: $e'};
    }
  }

  /// Append + animate a single call — the incremental path for animate-on-hit.
  Map<String, dynamic> _handleCall(Map<String, dynamic> msg) {
    final model = _model;
    if (model == null) return {'ok': false, 'error': 'sequencer not ready'};
    final call = (msg['call'] as String?)?.trim() ?? '';
    if (call.isEmpty) return {'ok': false, 'error': 'empty call'};
    try {
      model.animation.doPause();
      if (!model.loadOneCall(call)) {
        return {'ok': false, 'failingCall': call, 'error': model.errorString};
      }
      return {'ok': true, 'call': call, ..._state()};
    } catch (e) {
      return {'ok': false, 'failingCall': call, 'error': '$e'};
    }
  }

  Map<String, dynamic> _handleSequence(Map<String, dynamic> msg) {
    final model = _model;
    if (model == null) {
      return {'ok': false, 'failingIndex': null, 'error': 'sequencer not ready'};
    }
    final formation = (msg['formation'] as String?) ?? 'Squared Set';
    final shouldReset = (msg['reset'] as bool?) ?? true;
    final calls = (msg['calls'] as List?)?.map((c) => '$c').toList() ?? const <String>[];

    _appState?.change(
        mainPage: MainPage.SEQUENCER, formation: formation, calls: '', sidecarMode: true);
    if (shouldReset) {
      try {
        model.setStartingFormation(formation);
        model.reset();
      } catch (e) {
        return {'ok': false, 'failingIndex': null, 'error': 'Formation error: $e'};
      }
    }
    for (var i = 0; i < calls.length; i++) {
      try {
        model.animation.doPause();
        if (!model.loadOneCall(calls[i])) {
          return {'ok': false, 'failingIndex': i, 'failingCall': calls[i], 'error': model.errorString};
        }
      } catch (e) {
        return {'ok': false, 'failingIndex': i, 'failingCall': calls[i], 'error': '$e'};
      }
    }
    return {'ok': true, 'callCount': calls.length, ..._state()};
  }

  /// Formation snapshot. NOTE: match these to your api_server.dart /state + /debug
  /// (model.calls / model.totalBeats() / ctx.isSquare()/isWaves()/… + dancers).
  Map<String, dynamic> _state() {
    final model = _model;
    if (model == null) return {'ok': false, 'error': 'sequencer not ready'};
    final ctx = model.contextFromAnimation()..analyze();
    return {
      'callCount': model.calls.length,
      'calls': model.calls.map((c) => c.name).toList(),
      'isSquare': ctx.isSquare(),
      'totalBeats': model.totalBeats(),
    };
  }

  // ── transport ──────────────────────────────────────────────────────────────
  void _reply(String type, dynamic requestId, Map<String, dynamic> body) {
    _post({'type': type, if (requestId != null) 'requestId': requestId, ...body});
  }

  void _post(Map<String, dynamic> data) {
    // Standalone (not iframed) => parent == window, which is harmless.
    html.window.parent?.postMessage(data, allowedOrigin);
  }
}

final tamWebBridge = TamWebBridge();

// lib/tam_web_bridge_stub.dart
//
// Native (non-web) no-op replacement for tam_web_bridge.dart, which imports
// dart:html and only compiles on web. main.dart conditionally imports this off
// web, so the wiring calls (tamWebBridge.start()/setSequencerModel()/…) compile
// on macOS/iOS/etc. as no-ops. Keep the surface in sync with TamWebBridge.

import 'sequencer/sequencer_model.dart';
import 'tam_state.dart';

class TamWebBridge {
  String allowedOrigin = '*';
  void start() {}
  void setSequencerModel(SequencerModel model) {}
  void setAppState(TamState state) {}
}

final tamWebBridge = TamWebBridge();

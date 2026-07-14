// lib/api_server_stub.dart
//
// Web/no-op replacement for api_server.dart. The real one imports dart:io +
// package:shelf, which DO NOT compile for Flutter web. main.dart conditionally
// imports this on web (see the conditional import), so the shelf server is simply
// absent from the web bundle. Every method is a no-op; keep the surface in sync
// with TamHelperApiServer so both libraries satisfy main.dart's call sites.
//
// Methods main.dart calls: start, setSequencerModel, setAppState, setExpectedToken,
// setDockWindowHandler, setWindowDebugInfoProvider, setPort.
//
// Branching (the experimental splice) is a desktop affair — it opens a second TamHelper process —
// so on web there is never a branch: branchInfo stays null and its UI never shows.

import 'branch.dart';
import 'sequencer/sequencer_model.dart';
import 'tam_state.dart';

class TamHelperApiServer {
  static const defaultPort = 7234;

  int port = defaultPort;
  BranchInfo? branchInfo;

  Future<void> start() async {}
  void setPort(int value) {}
  void setSequencerModel(SequencerModel model) {}
  void setAppState(TamState state) {}
  void setExpectedToken(dynamic token) {}
  void setDockWindowHandler(dynamic handler) {}
  void setAlwaysOnTopHandler(dynamic handler) {}
  void setVisibilityHandler(dynamic handler) {}
  void setWindowDebugInfoProvider(dynamic provider) {}

  Future<int> launchBranch({
    required List<String> calls,
    required String formation,
    required String parentName,
  }) async =>
      throw 'Branching a sequence needs the desktop app.';

  void closeBranchWindow() {}

  Future<SpliceOutcome> spliceIntoParent({
    required List<String> branchCalls,
    required bool replaceTail,
  }) async =>
      const SpliceOutcome(ok: false, error: 'Branching a sequence needs the desktop app.');
}

final tamHelperApiServer = TamHelperApiServer();

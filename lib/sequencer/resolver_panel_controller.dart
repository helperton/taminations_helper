import 'package:flutter/foundation.dart' as f;

import '../resolve_client.dart';

enum ResolverPhase { closed, danceability, resolving, stepThrough, failed }

/// Drives the resolve pushout panel: which phase it's in, the proposed get-out,
/// and how many of its calls are currently loaded into the sequencer. The
/// step-index logic is pure — the widget performs the actual model load/undo and
/// calls didLoadForward()/didUndoBack() to keep this in sync (so it stays
/// unit-testable). [onOpenChanged] lets the app grow/shrink the window when the
/// panel opens or closes.
class ResolverPanelController extends f.ChangeNotifier {
  ResolverPhase phase = ResolverPhase.closed;
  List<String> resolution = const [];
  int loadedSteps = 0; // get-out calls currently loaded into the model
  int baseline = 0;    // model.calls.length captured before resolving
  String note = '';
  String method = ''; // "sight" or "hybrid-fallback" — which resolver produced the get-out

  /// Set by the app; fired when the panel opens (true) or closes (false).
  void Function(bool open)? onOpenChanged;

  bool get isOpen => phase != ResolverPhase.closed;

  void open() {
    phase = ResolverPhase.danceability;
    note = '';
    notifyListeners();
    onOpenChanged?.call(true);
  }

  void beginResolving() {
    phase = ResolverPhase.resolving;
    notifyListeners();
  }

  void applyResult(ResolveResult r, {required int baselineCount}) {
    method = r.method;
    if (r.error != ResolveError.none) {
      phase = ResolverPhase.failed;
      note = 'SquareCraft: ${r.error.name}';
    } else if (!r.resolved) {
      phase = ResolverPhase.failed;
      note = r.note.isEmpty ? "Couldn't resolve from ${r.state}" : r.note;
    } else {
      resolution = List<String>.from(r.resolution);
      baseline = baselineCount;
      loadedSteps = 0;
      phase = ResolverPhase.stepThrough;
    }
    notifyListeners();
  }

  bool canForward() =>
      phase == ResolverPhase.stepThrough && loadedSteps < resolution.length;
  bool canBack() => phase == ResolverPhase.stepThrough && loadedSteps > 0;
  String? nextCall() => canForward() ? resolution[loadedSteps] : null;

  /// Advance one step; returns the call the widget should have just loaded, or
  /// null if already at the end.
  String? didLoadForward() {
    if (!canForward()) return null;
    final call = resolution[loadedSteps];
    loadedSteps++;
    notifyListeners();
    return call;
  }

  /// Retreat one step (the widget undoes one call). No-op at zero.
  void didUndoBack() {
    if (!canBack()) return;
    loadedSteps--;
    notifyListeners();
  }

  void close() {
    phase = ResolverPhase.closed;
    resolution = const [];
    loadedSteps = 0;
    baseline = 0;
    note = '';
    method = '';
    notifyListeners();
    onOpenChanged?.call(false);
  }
}

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

//  Experimental splice: branching a sequence.
//
//  Right-click a call and a SECOND TamHelper opens, seeded with the sequence up to that call.
//  You try something else there without disturbing what you came from. If you like it, splice it
//  back: the parent's calls from the branch point on are re-run after the branch's.
//
//  A branch is a whole separate process with its own window and its own API port, so you can have
//  several going at once and see them side by side. It knows its parent by that parent's port —
//  which is also how it splices back, over the API the parent already serves.
//
//  This file is the pure part: who a branch's parent is, and what the parent becomes when the
//  branch comes home. The process and socket work lives in api_server.dart (dart:io).

/// What a branched TamHelper knows about where it came from. Absent in a normal TamHelper.
class BranchInfo {
  /// The API port of the TamHelper this branch was cut from — how it splices back.
  final int parentPort;

  /// What to call the parent on screen.
  final String parentName;

  /// How many calls the branch was seeded with: the parent's calls[0 .. seedCount-1], i.e. every
  /// call up to and including the one that was right-clicked. Splicing replaces the parent's calls
  /// from here on with the branch's.
  final int seedCount;

  const BranchInfo({
    required this.parentPort,
    required this.parentName,
    required this.seedCount,
  });

  /// The launch arguments a parent passes to the child it spawns.
  static const parentPortArg = '--branch-parent-port=';
  static const parentNameArg = '--branch-parent-name=';
  static const seedCountArg = '--branch-seed-count=';
  static const apiPortArg = '--api-port=';

  /// Nil unless this process was launched as a branch of another.
  static BranchInfo? fromLaunchArgs(List<String> args) {
    String? valueOf(String prefix) {
      final arg = args.firstWhere((a) => a.startsWith(prefix), orElse: () => '');
      return arg.isEmpty ? null : arg.substring(prefix.length);
    }

    final port = int.tryParse(valueOf(parentPortArg) ?? '');
    final seed = int.tryParse(valueOf(seedCountArg) ?? '');
    if (port == null || seed == null || port <= 0 || seed < 0) {
      return null;
    }
    return BranchInfo(
      parentPort: port,
      parentName: valueOf(parentNameArg) ?? 'the parent',
      seedCount: seed,
    );
  }

  /// The API port this process should serve on, if it was told one. A branch gets its own so the
  /// parent keeps 7234 — the port SquareCraft talks to.
  static int? apiPortFromLaunchArgs(List<String> args) {
    final arg = args.firstWhere((a) => a.startsWith(apiPortArg), orElse: () => '');
    return arg.isEmpty ? null : int.tryParse(arg.substring(apiPortArg.length));
  }

  String get label => 'Branch of $parentName, from call $seedCount';
}

/// What to call a TamHelper on screen. The first one is Main; a branch carries its lineage, so with
/// several open you can always see which came from which.
String tamHelperDisplayName(BranchInfo? info) =>
    info == null ? 'Main' : 'Branch of ${info.parentName}';

/// What the parent's sequence becomes when a branch is spliced back into it.
///
/// The branch already carries the parent's first `seedCount` calls (it was seeded with them), so
/// it simply replaces them. The question is the parent's TAIL — the calls that came after the
/// branch point:
///
///  * `replaceTail: false` — keep it, and re-run it after the branch's calls. This is what you
///    want when the branch slots in cleanly. It can fail: the branch may leave the floor in a
///    formation the tail's first call can't be danced from.
///  * `replaceTail: true` — throw it away. The branch becomes the whole sequence. This is the
///    answer to "wipe out all the calls after and replace them with the new sequence".
List<String> splicedSequence({
  required List<String> parentCalls,
  required List<String> branchCalls,
  required int seedCount,
  required bool replaceTail,
}) {
  if (replaceTail) {
    return List<String>.from(branchCalls);
  }
  final tail = parentCalls.length > seedCount
      ? parentCalls.sublist(seedCount)
      : const <String>[];
  return [...branchCalls, ...tail];
}

/// The parent's calls after the branch point — the ones at stake when a splice conflicts.
List<String> parentTail({required List<String> parentCalls, required int seedCount}) =>
    parentCalls.length > seedCount ? parentCalls.sublist(seedCount) : const <String>[];

/// What came back from asking the parent to take a branch.
class SpliceOutcome {
  final bool ok;
  final String? error;

  /// The call that stopped the splice — either one of the parent's tail calls that no longer works
  /// after the branch, or (with `replaceTail`) a call in the branch itself.
  final String? failingCall;

  /// The parent's calls after the branch point, which splicing would have to drop. This is what a
  /// "replace everything after?" prompt lists.
  final List<String> brokenTail;

  const SpliceOutcome({
    required this.ok,
    this.error,
    this.failingCall,
    this.brokenTail = const [],
  });

  /// The parent kept its sequence, but dropping its tail would let the branch land.
  bool get canRetryByReplacingTail => !ok && failingCall != null && brokenTail.isNotEmpty;
}

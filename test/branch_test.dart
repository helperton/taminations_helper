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

//  Experimental splice: what a branch knows about its parent, and what the parent becomes when the
//  branch comes home. The process and socket work is exercised against a live pair of TamHelpers;
//  this pins the decisions.

import 'package:taminations/branch.dart';
import 'package:test/test.dart';

void main() {

  group('a branch knows where it came from', () {

    test('reads its parent and its branch point off the launch args', () {
      final info = BranchInfo.fromLaunchArgs([
        '--api-port=7245',
        '--branch-parent-port=7234',
        '--branch-parent-name=Main',
        '--branch-seed-count=2',
      ]);
      expect(info, isNotNull);
      expect(info!.parentPort, 7234);
      expect(info.parentName, 'Main');
      expect(info.seedCount, 2);
      expect(BranchInfo.apiPortFromLaunchArgs(['--api-port=7245']), 7245);
    });

    test('an ordinary TamHelper is nobody\'s branch', () {
      expect(BranchInfo.fromLaunchArgs([]), isNull);
      expect(BranchInfo.fromLaunchArgs(['--sc-token=abc']), isNull);
      //  Half a branch is no branch — never guess at a parent.
      expect(BranchInfo.fromLaunchArgs(['--branch-parent-port=7234']), isNull);
      expect(BranchInfo.apiPortFromLaunchArgs([]), isNull);
    });

    test('lineage is visible with several open at once', () {
      expect(tamHelperDisplayName(null), 'Main');
      const branch = BranchInfo(parentPort: 7234, parentName: 'Main', seedCount: 2);
      expect(tamHelperDisplayName(branch), 'Branch of Main');
      //  A branch of a branch says so, so you can tell which came from which.
      const nested = BranchInfo(parentPort: 7245, parentName: 'Branch of Main', seedCount: 4);
      expect(tamHelperDisplayName(nested), 'Branch of Branch of Main');
      expect(nested.label, 'Branch of Branch of Main, from call 4');
    });
  });

  group('splicing a branch home', () {

    //  The parent you branched from, at call 2 of 4.
    const parent = ['Heads Star Thru', 'Double Pass Thru', 'Centers In', 'Cast Off Three Quarters'];
    //  What you tried instead, in the branch.
    const branch = ['Heads Star Thru', 'Double Pass Thru', 'Peel Off'];
    const seedCount = 2;

    test('the parent\'s calls after the branch point are what is at stake', () {
      expect(parentTail(parentCalls: parent, seedCount: seedCount),
          ['Centers In', 'Cast Off Three Quarters']);
      //  Branch from the last call and there is no tail to lose.
      expect(parentTail(parentCalls: parent, seedCount: 4), isEmpty);
      expect(parentTail(parentCalls: parent, seedCount: 9), isEmpty);
    });

    test('keeping the tail re-runs it after the branch', () {
      expect(
          splicedSequence(
              parentCalls: parent,
              branchCalls: branch,
              seedCount: seedCount,
              replaceTail: false),
          ['Heads Star Thru', 'Double Pass Thru', 'Peel Off', 'Centers In', 'Cast Off Three Quarters']);
    });

    test('replacing the tail throws it away — the branch becomes the sequence', () {
      expect(
          splicedSequence(
              parentCalls: parent,
              branchCalls: branch,
              seedCount: seedCount,
              replaceTail: true),
          branch);
    });
  });

  group('what the parent says when a splice will not land', () {

    test('a broken TAIL can be fixed by dropping it, so offer that', () {
      const outcome = SpliceOutcome(
        ok: false,
        failingCall: 'Centers In',
        brokenTail: ['Centers In', 'Cast Off Three Quarters'],
      );
      expect(outcome.canRetryByReplacingTail, isTrue);
    });

    test('a branch that does not dance cannot be fixed by dropping the tail', () {
      //  Never offer "replace everything after" when it would fail all over again.
      const outcome = SpliceOutcome(ok: false, failingCall: 'Trade By', brokenTail: []);
      expect(outcome.canRetryByReplacingTail, isFalse);
    });

    test('a splice that landed offers nothing', () {
      const outcome = SpliceOutcome(ok: true);
      expect(outcome.canRetryByReplacingTail, isFalse);
    });
  });
}

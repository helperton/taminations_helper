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
import 'package:flutter/material.dart' as fm;
import 'package:taminations/sequencer/call_context.dart';
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/sequencer/words.dart';

import '../animated_call.dart';
import '../call_entry.dart';
import '../call_index.dart';
import '../common_flutter.dart';
import 'call_error.dart';
import 'call_suggestions.dart';

class SequencerCallsModel extends fm.ChangeNotifier {

  SequencerModel? sequencerModel;

  void setSequencerModel(SequencerModel model) {
    sequencerModel = model;
  }

  var callsSelected = <CallEntry>[];
  var validCalls = <String>[];
  //  SPIKE: the calls that follow best from here, best first, and the sequence they were
  //  ranked for (so they are only worked out again when it changes)
  var bestFromHere = <String>[];
  String? _rankedFor;

  final _levelsSelected = <LevelData, bool>{
    LevelData.MS: false,
    LevelData.PLUS: false,
    LevelData.A1: false,
    LevelData.A2: false,
    LevelData.C1: false,
    LevelData.C2: false,
    LevelData.C3A: false,
    LevelData.C3B: false
  };

  bool levelSelected(LevelData level) => _levelsSelected[level]!;

  void setSelected(LevelData level, bool value) {
    if (_levelsSelected[level] != value) {
      _levelsSelected[level] = value;
      callsSelected = callIndex.where((element) =>
      _levelsSelected[LevelData.find(element.link)] ?? false).toList();
    }
    computeValidCalls();
  }

  void computeValidCalls() async {
    if (sequencerModel != null) {
      var calls = callsSelected.map((c)=>c.title).toList();
      var ctx = sequencerModel!.contextFromCurrentFormation();
      var myDancers = ctx.dancers.map((d) => d.clone()).toList();
      var canApply = _ApplyCallContext(myDancers, calls);
      validCalls = await compute(_canApplyCall,canApply);
      notifyListeners();
    }
  }

  void computeBestFromHere() async {
    final model = sequencerModel;
    if (model == null)
      return;
    final sequence = model.calls.map((c) => c.name).join('\n');
    if (sequence == _rankedFor)
      return;
    _rankedFor = sequence;
    bestFromHere = [];
    notifyListeners();
    final job = _RankJob(model.animation.dancers,
        model.contextFromCurrentFormation().dancers.map((d) => d.clone()).toList());
    final ranked = await compute(_rankFromHere, job);
    if (_rankedFor == sequence) {
      bestFromHere = ranked;
      notifyListeners();
    }
  }

}

class _ApplyCallContext {

  List<Dancer> dancers;
  List<String> callNames;
  Map<String,List<AnimatedCall>> normalizedCallIndex = {};

  _ApplyCallContext(this.dancers, this.callNames) {
    normalizedCallIndex = Words.normalizedCallIndex;
  }

  bool showMyDancers() {
    print(dancers.show());
    return true;
  }

}

class _RankJob {
  final List<Dancer> history;
  final List<Dancer> current;
  final Map<String,List<AnimatedCall>> normalizedCallIndex = Words.normalizedCallIndex;
  _RankJob(this.history, this.current);
}

List<String> _rankFromHere(_RankJob job) {
  Words.normalizedCallIndex = job.normalizedCallIndex;
  return rankFromHere(commonPhrases(), job.history, job.current)
      .take(12).map((r) => r.$1).toList();
}

List<String> _canApplyCall(_ApplyCallContext ctx) {
  Words.normalizedCallIndex = ctx.normalizedCallIndex;
  var retval = <String>[];
  for (var call in ctx.callNames) {
    try {
      probeCall(call, ctx.dancers);
      retval.add(call);
    } on CallError {
      // fall through
    } catch (_) {
      // fall through
    }
  }
  return retval;
}

//  Throws a CallError unless [call] dances cleanly from where [dancers] stand; returns the result
CallContext probeCall(String call, List<Dancer> dancers) {
    var ctx = CallContext.fromDancers(dancers);
    ctx.interpretCall(call);
    ctx.performCall(tryDoYourPart: false);
    if (!RegExp(r'move in|step|gnat|back\s*(up|away)', caseSensitive: false)
        .hasMatch(call))
      ctx.adjustForSquaredSetConvention();
    ctx.checkCenters();
    ctx.animateToEnd();
    ctx.matchStandardFormation();
    if (ctx.isCollision())
      throw CallError('Collision');
    return ctx;
  }


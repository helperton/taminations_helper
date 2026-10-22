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

//  SPIKE — throwaway proof of concept, not for committing.
//  When a call fails, suggest what the caller might have meant ("did you mean") or what
//  dances from where the dancers are now ("from here, try").

import 'dart:math';

import '../call_index.dart';
import '../dancer.dart';
import '../extensions.dart';
import '../level_data.dart';
import '../math/hands.dart';
import 'call_context.dart';
import 'call_error.dart';
import 'calls/xml_call.dart';
import 'normalize_call.dart';
import 'sequencer_calls_model.dart';
import 'words.dart';

//  Phrasings of coded calls a caller might type. The real version would cover every call.
const _codedExamples = [
  'Allemande Right', 'Right Allemande', 'Right Allemande Partner', 'Left Allemande Partner',
  'Right Arm Turn', 'Left Arm Turn', 'Right Arm Turn 3/4', 'Face Partner', 'Face Corner',
  'Men Star Left', 'Ladies Star Right', 'Men Star Right', 'Ladies Star Left',
  'Heads Star Right to Corner', 'Sides Star Right to Corner', 'With Corner Star Left',
  'Heads Star Right Back Home', 'Sides Star Right Back Home',
  'Promenade Home', 'Promenade 1/2', 'Square the Set',
];

const _designators = ['Heads', 'Sides', 'Men', 'Ladies', 'Centers', 'Ends'];

//  The phrasings worth ranking from anywhere: the coded examples and the Mainstream and Plus
//  titles. Every level would make ranking too slow for a spike.
List<String> commonPhrases() => {
  ..._codedExamples,
  for (final e in callIndex)
    if ([LevelData.MS, LevelData.PLUS].contains(LevelData.find(e.link))) e.title,
}.toList();

List<String> _phrases() => {
  ..._codedExamples,
  for (final calls in Words.normalizedCallIndex.values)
    for (final call in calls) call.title,
}.toList();

//  Lower case words, as typed
List<String> _words(String s) =>
    s.lc.split('[^a-z0-9/]+'.r).where((w) => w.isNotEmpty).toList();

int _editDistance(String a, String b) {
  var prev = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final cur = [i, ...List<int>.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++)
      cur[j] = [prev[j] + 1, cur[j - 1] + 1, prev[j - 1] + (a[i - 1] == b[j - 1] ? 0 : 1)]
          .reduce(min);
    prev = cur;
  }
  return prev[b.length];
}

//  Up to three known phrasings spelled most like [call].
List<String> didYouMean(String call) {
  final typed = call.lc.trim();
  final scored = [
    for (final p in _phrases()) (p, _editDistance(typed, p.lc)),
  ]..sort((a, b) => a.$2.compareTo(b.$2));
  final limit = max(2, typed.length ~/ 4);
  return scored.where((s) => s.$2 <= limit).take(3).map((s) => s.$1).toList();
}

//  Up to three phrasings sharing words with [call] that dance from where [dancers] stand.
List<String> fromHere(String call, List<Dancer> dancers) {
  final typed = _words(call).toSet();
  final candidates = {
    for (final p in _phrases())
      ...[p, if (!_designators.any((d) => p.startsWith('$d '))) for (final d in _designators) '$d $p'],
  }.map((p) {
    final words = _words(p).toSet();
    final shared = words.intersection(typed).length;
    //  Closest first: most words in common, fewest extra
    return (p, shared == 0 ? 0.0 : shared - 0.5 * (words.length - shared));
  }).where((c) => c.$2 > 0).toList()
    ..sort((a, b) => b.$2.compareTo(a.$2));
  final works = <String>[];
  for (final (phrase, _) in candidates.take(60)) {
    //  Different wordings of the same call count once
    if (works.any((w) => normalizeCall(w) == normalizeCall(phrase)))
      continue;
    try {
      probeCall(phrase, dancers.map((d) => d.clone()).toList());
      works.add(phrase);
      if (works.length == 3) break;
    } on CallError {
      continue;
    } catch (_) {
      continue;
    }
  }
  return works;
}

//  The failure, with suggestions added when there are any.
String explainFailure(CallError e, String call, List<Dancer> dancers) {
  final suggestions = e is CallNotFoundError ? didYouMean(call) : fromHere(call, dancers);
  if (suggestions.isEmpty)
    return e.toString();
  return e is CallNotFoundError
      ? '$e. Did you mean ${suggestions.join(' or ')}?'
      : '$e From here, try ${suggestions.join(', ')}.';
}

//  How naturally a danced call follows what came before, from the paths alone: each dancer
//  carrying on in the direction they were moving (or facing), and not taking a hand they are
//  still holding from the call before. Lower levels come first, and calls with an animation
//  drawn for this position before code that dances from anywhere. Higher is better.
double flowScore(List<Dancer> history, CallContext next) {
  const levels = [LevelData.MS, LevelData.PLUS, LevelData.A1, LevelData.A2,
                  LevelData.C1, LevelData.C2, LevelData.C3A, LevelData.C3B];
  var total = 0.0;
  var counted = 0;
  for (final d in next.dancers) {
    if (d.beats < 0.01 || d.path.movelist.every((m) => m.translate().location.length < 0.01 &&
        m.rotate().angle.abs() < 0.01))
      continue;   // standing still: no say in the flow
    final was = history.firstWhere((h) => h.number == d.number);
    final end = was.beats;
    was.animate(max(0.0, end - 0.5));
    final before = was.location;
    was.animate(end);
    final travelled = was.location - before;
    final cameFrom = travelled.length > 0.05 ? travelled.angle : was.angleFacing;
    d.animate(0.0);
    final start = d.location;
    final startFacing = d.angleFacing;
    d.animate(min(0.5, d.beats));
    final moved = d.location - start;
    final goesTo = moved.length > 0.05 ? moved.angle : d.angleFacing;
    d.animateToEnd();
    //  Carrying on is 1, a right-angle turn 0, reversing -1; turning on the spot first counts
    //  against it too
    var body = cos(goesTo.angleDiff(cameFrom));
    if (moved.length <= 0.05 && d.angleFacing.angleDiff(startFacing).abs() > pi/3)
      body -= 0.5;
    final handWas = handHeldAtEnd(history, was);
    final handNext = firstHandUsed(next.dancers, d);
    final hand = handWas == 0 || handNext == 0 || handWas == 3 || handNext == 3
        ? 0.0 : handWas == handNext ? -1.0 : 1.0;
    total += body + 0.5 * hand;
    counted++;
  }
  final familiarity = -0.15 * max(0, levels.indexOf(next.level));
  //  An animation drawn for this very position beats code that moves dancers from anywhere,
  //  and both beat an animation the dancers have to be pushed about to fit
  final offset = _matchOffset(next);
  final fit = (isDrawnForHere(next) ? 0.5 : 0.0) - 0.1 * (offset ?? 0.0);
  return (counted == 0 ? -2.0 : total / counted) + familiarity + fit;
}

//  How far the dancers had to be pushed to fit the animations used, or null if code danced it
double? _matchOffset(CallContext danced) {
  final xml = danced.callstack.whereType<XMLCall>();
  if (xml.isEmpty || !xml.every((c) => c.found))
    return null;
  return xml.fold(0.0, (s, c) => s! + c.matchOffset);
}

bool isDrawnForHere(CallContext danced) => (_matchOffset(danced) ?? 99) < 1.0;

//  Every call that dances from where [current] stand, best flow first. A designated variant
//  (Men Star Left) is only offered when the plain call (Star Left) does not dance. Phrasings
//  that dance the same thing (Allemande Right, Right Allemande Partner) are one call, shown
//  by the first phrasing given.
List<(String, double)> rankFromHere(Iterable<String> phrases, List<Dancer> history,
    List<Dancer> current) {
  final ranked = <(String, double)>[];
  final outcomes = <String>{};
  final tried = <String>{};
  //  Whether [phrase] dances from here, adding it unless an earlier phrasing danced the same
  bool tryPhrase(String phrase) {
    try {
      final danced = probeCall(phrase, current.map((d) => d.clone()).toList());
      if (outcomes.add(_outcome(danced))) {
        //  Code will move a designated few from almost anywhere; without an animation drawn
        //  for it, that is rarely a call anyone would make
        final designated = _designators.any((d) => phrase.startsWith('$d '));
        final penalty = designated && !isDrawnForHere(danced) ? 0.5 : 0.0;
        ranked.add((phrase, flowScore(history, danced) - penalty));
      }
      return true;
    } catch (_) {
      return false;
    }
  }
  for (final phrase in phrases) {
    if (!tried.add(normalizeCall(phrase)))
      continue;
    if (!tryPhrase(phrase) && !_designators.any((d) => phrase.startsWith('$d ')))
      for (final d in _designators)
        tryPhrase('$d $phrase');
  }
  return ranked..sort((a, b) => b.$2.compareTo(a.$2));
}

//  The whole dance: where everyone is every half beat, to the nearest tenth, and the hands
//  they use. Weave the Ring ends where Right and Left Grand does but without hands.
String _outcome(CallContext danced) {
  final beats = danced.maxBeats();
  final out = StringBuffer(beats.toStringAsFixed(1));
  for (final d in danced.dancers) {
    out.write(' ${d.number}:${d.path.movelist.map((m) => m.hands & 3).join()}');
    for (var b = 0.0; b <= beats + 0.01; b += 0.5) {
      d.animate(b);
      out.write(' ${d.location.x.toStringAsFixed(1)},${d.location.y.toStringAsFixed(1)}');
    }
    d.animateToEnd();
  }
  return out.toString();
}

//  Which hands a dancer has in use, read from the geometry rather than from what the
//  animation draws. Sampled every quarter beat; all of [all] must be animated together.
//
//  A hand is in use when another dancer is abeam within arm's reach — an arm turn, a pull by,
//  a pass — or when the dancer is turning tightly round a point that another dancer is also
//  circling (a star, a swing, an allemande). Couples two units apart are only loosely holding
//  hands and do not count. Two dancers equally close on opposite sides cancel out.
//  Someone standing still beside you is only a hand within arm's reach; a dancer passing or
//  turning with you can be drawn a little further off.
const _reachStanding = 1.3, _reachMoving = 1.6, _tightTurn = 1.3, _step = 0.25;

int _abeamHand(List<Dancer> all, Dancer d, double beat) {
  double left = 99, right = 99;
  for (final o in all) {
    if (o == d) continue;
    final v = d.vectorToDancer(o);   // +y is on d's left
    final p0 = o.location;
    o.animate(beat + _step);
    final moving = (o.location - p0).length / _step > 0.1;
    o.animate(beat);
    final reach = moving ? _reachMoving : _reachStanding;
    if (v.x.abs() < 0.8 && v.y.abs() > 0.3 && v.y.abs() < reach) {
      if (v.y > 0) left = min(left, v.y); else right = min(right, -v.y);
    }
  }
  if (left == 99 && right == 99) return 0;
  if ((left - right).abs() < 0.2) return 0;
  return left < right ? Hands.LEFT : Hands.RIGHT;
}

//  A tight turn round a point another dancer is also circling: the hand on the center's side
int _turningHand(List<Dancer> all, Dancer d, double beat) {
  final p0 = d.location, a0 = d.angleFacing, frame = d.tx;
  final others = [for (final o in all) if (o != d) o.location];
  d.animate(beat + _step);
  final vel = (d.location - p0) / _step;
  final w = d.angleFacing.angleDiff(a0) / _step;
  d.animate(beat);
  if (w.abs() < 0.2 || vel.length < 0.05) return 0;
  final radius = vel.length / w.abs();
  if (radius >= _tightTurn) return 0;
  final center = p0 + (vel / vel.length).rotate(w > 0 ? pi/2 : -pi/2) * radius;
  if (!others.any((o) => (o - center).length < radius + 0.3)) return 0;
  return (frame.inverse() * center).y > 0 ? Hands.LEFT : Hands.RIGHT;
}

//  Hands in use at each sample from [from] to [to]
List<int> _handsInUse(List<Dancer> all, Dancer d, double from, double to) {
  final out = <int>[];
  for (var b = from; b <= to - _step + 0.001; b += _step) {
    for (final o in all) o.animate(b);
    final turn = _turningHand(all, d, b);
    out.add(turn != 0 ? turn : _abeamHand(all, d, b));
  }
  return out;
}

//  The hand a dancer is still holding as their path ends, if any
int handHeldAtEnd(List<Dancer> all, Dancer d) {
  final used = _handsInUse(all, d, max(0.0, d.beats - 0.5), d.beats);
  for (final o in all) o.animateToEnd();
  return used.isEmpty ? 0 : used.last;
}

//  The last hand a dancer had in close use over their whole path
int lastHandUsed(List<Dancer> all, Dancer d) {
  final used = _handsInUse(all, d, 0.0, d.beats);
  for (final o in all) o.animateToEnd();
  return used.lastWhere((h) => h != 0, orElse: () => 0);
}

//  The first hand a dancer takes in the first two beats of their path
int firstHandUsed(List<Dancer> all, Dancer d) {
  final used = _handsInUse(all, d, 0.0, min(2.0, d.beats));
  for (final o in all) o.animateToEnd();
  return used.firstWhere((h) => h != 0, orElse: () => 0);
}

//  For checking against what the animation draws: the last hand drawn on the path
int lastHandDrawn(Dancer d) {
  final m = d.path.movelist.lastWhere((m) => m.hands & 3 != 0,
      orElse: () => d.path.movelist.first);
  return m.hands & 3;
}

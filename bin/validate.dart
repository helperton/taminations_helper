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

//  Headless (pure-Dart, no Flutter) sequence validator. Runs the SAME call engine the
//  GUI uses, but with no animation/rendering — so it's fast and parallelizable. Emits
//  the SAME JSON shape as the GUI's POST /validate, so the SquareCraft client parses it
//  identically. The per-call pipeline mirrors the proven headless test harness
//  (test/sequencer_unit_test.dart `testOneSequence`).
//
//  Usage:
//    one-shot:    dart run bin/validate.dart '{"formation":"Squared Set","calls":["..."]}'
//    long-lived:  dart run bin/validate.dart    (then one JSON request per stdin line)

import 'dart:convert';
import 'dart:io';

import 'package:taminations/formation.dart';
import 'package:taminations/sequencer/call_context.dart';
import 'package:taminations/sequencer/calls/coded_call.dart';
import 'package:taminations/sequencer/calls/xml_call.dart';
import 'package:taminations/sequencer/call_error.dart';
import 'package:taminations/sequencer/words.dart';
import 'package:taminations/extensions.dart';   // for `.ri` (regex)

final _skipAdjust = '(move in|step|gnat|back\\s*(up|away))'.ri;

Map<String, dynamic> _validate(String formation, List<String> calls) {
  CallContext ctx;
  try {
    ctx = CallContext.fromFormation(Formation(formation.isEmpty ? 'Squared Set' : formation));
  } catch (e) {
    return {
      'ok': false, 'failingIndex': null, 'failingCall': null,
      'error': 'Formation error: $e', 'perCall': <Map<String, dynamic>>[],
    };
  }

  final perCall = <Map<String, dynamic>>[];
  var prevBeats = 0.0;

  for (var i = 0; i < calls.length; i++) {
    try {
      //  Mirror of test/sequencer_unit_test.dart testOneSequence — the proven
      //  headless per-call pipeline. cctx accumulates back into ctx via appendToSource().
      final cctx = CallContext.fromContext(ctx);
      cctx.allActive();
      cctx.interpretCall(calls[i]);
      cctx.performCall(tryDoYourPart: true);
      if (!cctx.callname.contains(_skipAdjust)) {
        cctx.adjustForSquaredSetConvention();
      }
      cctx.checkCenters();
      final firstCall = cctx.callstack.first;
      cctx.animateToEnd();
      if (cctx.callstack.length > 1 ||
          firstCall is CodedCall ||
          (firstCall is XMLCall && !firstCall.found)) {
        cctx.matchStandardFormation();
      }
      cctx.appendToSource();
    } on CallError catch (e) {
      return {
        'ok': false, 'failingIndex': i, 'failingCall': calls[i],
        'error': e.toString(), 'perCall': perCall,
      };
    } catch (e) {
      return {
        'ok': false, 'failingIndex': i, 'failingCall': calls[i],
        'error': '$e', 'perCall': perCall,
      };
    }

    //  Detected formation after this call — same ordered cascade as the GUI /validate.
    ctx.analyze();
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

    //  Per-call beats = the increment in the cumulative path length.
    final total = ctx.maxBeats();
    final callBeats = total - prevBeats;
    prevBeats = total;

    perCall.add({
      'call': calls[i],
      'detectedFormation': detectedFormation,
      'beats': (callBeats * 10).round() / 10.0,
    });
  }

  return {'ok': true, 'callCount': calls.length, 'perCall': perCall};
}

Map<String, dynamic> _handle(String jsonLine) {
  try {
    final req = jsonDecode(jsonLine) as Map<String, dynamic>;
    final formation = (req['formation'] as String?) ?? 'Squared Set';
    final calls = (req['calls'] as List).cast<String>();
    return _validate(formation, calls);
  } catch (e) {
    return {
      'ok': false, 'failingIndex': null, 'failingCall': null,
      'error': 'bad request: $e', 'perCall': <Map<String, dynamic>>[],
    };
  }
}

Future<void> main(List<String> args) async {
  Words.init();   // builds the call index (synchronous body; no assets, no Flutter)

  //  One-shot mode for quick testing: pass the JSON request as the first arg.
  if (args.isNotEmpty) {
    stdout.writeln(jsonEncode(_handle(args.first)));
    return;
  }

  //  Long-lived worker: one JSON request per stdin line → one JSON response line.
  await for (final line in stdin.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.trim().isEmpty) continue;
    stdout.writeln(jsonEncode(_handle(line)));
  }
}

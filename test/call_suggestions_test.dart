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

//  When a call fails, the sequencer can suggest what was meant ("Did you mean") or what
//  dances from here ("From here, try"). The Call Suggestions setting turns this on; it is
//  off unless someone turns it on.

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stack_trace/stack_trace.dart' as stack_trace;
import 'package:taminations/sequencer/sequencer_model.dart';
import 'package:taminations/settings.dart';

void main() async {

  //  This is necessary else the 1st test crashes
  FlutterError.demangleStackTrace = (StackTrace stack) {
    if (stack is stack_trace.Trace) return stack.vmTrace;
    if (stack is stack_trace.Chain) return stack.toTrace().vmTrace;
    return stack;
  };

  Future<SequencerModel> danced(String calls, {bool? suggestions}) async {
    Settings.mockInit();
    if (suggestions != null)
      Settings.callSuggestions = suggestions;
    final model = SequencerModel();
    model.setStartingFormation('Static Square');
    await model.paste(calls);
    model.animation.doPause();
    return model;
  }

  testWidgets('call suggestions are off unless turned on', (tester) async {
    await tester.runAsync(() async {
      await danced('');
      expect(Settings.callSuggestions, isFalse);
    });
  });

  testWidgets('with suggestions off, a misspelled call only says it was not found',
      (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Alamand Left');
      expect(model.errorString, 'Call Alamand Left not found');
    });
  });

  testWidgets('with suggestions on, a misspelled call suggests what was meant', (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Alamand Left', suggestions: true);
      expect(model.errorString, 'Call Alamand Left not found. Did you mean Allemande Left?');
    });
  });

  testWidgets('with suggestions off, a call that cannot be danced suggests nothing',
      (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Allemande Left\nRight Pull By\nLeft Pull By');
      expect(model.errorString, isNot(contains('From here')));
    });
  });

  testWidgets('with suggestions on, a call that cannot be danced suggests what can',
      (tester) async {
    await tester.runAsync(() async {
      final model = await danced('Allemande Left\nRight Pull By\nLeft Pull By',
          suggestions: true);
      expect(model.errorString, contains('From here, try'));
    });
  });

}

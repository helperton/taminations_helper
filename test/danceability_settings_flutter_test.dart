import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/settings_flutter.dart';

void main() {
  // Guards against drift between the two Settings classes. settings.dart
  // conditionally exports the headless settings_dart.dart by default, but the
  // GUI build (dart.library.ui) gets THIS file, settings_flutter.dart. Both
  // must expose the same danceability accessors with the same SC-matching
  // defaults, or the resolver controls compile in test/analyze but break the
  // macOS build (which is exactly what happened the first time around).
  test('GUI Settings exposes danceability accessors with SC defaults', () {
    Settings.mockInit();
    expect(Settings.danceabilityOverride, isFalse);
    expect(Settings.danceabilityLaneWeight, 70);
    expect(Settings.danceabilityOverlapWeight, 25);
    expect(Settings.danceabilityDistWeight, 5);
    expect(Settings.danceabilityThreshold, 60);
    expect(Settings.danceabilityBlockWidth, 1.0);
  });
}

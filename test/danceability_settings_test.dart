import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/settings_dart.dart';

void main() {
  test('danceability settings default to SC defaults (mock proxy)', () {
    Settings.mockInit();
    expect(Settings.danceabilityLaneWeight, 70);
    expect(Settings.danceabilityOverlapWeight, 25);
    expect(Settings.danceabilityDistWeight, 5);
    expect(Settings.danceabilityThreshold, 60);
    expect(Settings.danceabilityBlockWidth, 1.0);
  });
}

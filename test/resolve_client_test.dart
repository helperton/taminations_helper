import 'package:flutter_test/flutter_test.dart';
import 'package:taminations/resolve_client.dart';

void main() {
  test('parse: resolved=true returns the resolution calls', () {
    final r = ResolveResult.parse(200,
        '{"state":"[0L]1p","resolved":true,"resolution":["RIGHT AND LEFT GRAND","PROMENADE HOME"]}');
    expect(r.resolved, isTrue);
    expect(r.error, ResolveError.none);
    expect(r.state, '[0L]1p');
    expect(r.resolution, ['RIGHT AND LEFT GRAND', 'PROMENADE HOME']);
  });

  test('parse: resolved=false carries the note', () {
    final r = ResolveResult.parse(200,
        '{"state":"[0T-Bone]1p","resolved":false,"note":"unresolved within the bounded hybrid search"}');
    expect(r.resolved, isFalse);
    expect(r.error, ResolveError.none);
    expect(r.state, '[0T-Bone]1p');
    expect(r.note, contains('unresolved'));
  });

  test('parse: HTTP 401 maps to unauthorized', () {
    expect(ResolveResult.parse(401, 'Unauthorized').error, ResolveError.unauthorized);
  });

  test('parse: non-200 maps to badResponse', () {
    expect(ResolveResult.parse(404, '{"error":"x"}').error, ResolveError.badResponse);
  });

  test('parse: malformed body maps to badResponse', () {
    expect(ResolveResult.parse(200, 'not json').error, ResolveError.badResponse);
  });
}

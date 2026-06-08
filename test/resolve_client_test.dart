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

  test('parse: captures the resolver method (sight / hybrid-fallback)', () {
    final s = ResolveResult.parse(200,
        '{"state":"[0Q]2p","resolved":true,"method":"sight","resolution":["EXTEND"]}');
    expect(s.method, 'sight');
    final h = ResolveResult.parse(200,
        '{"state":"[0?]2o","resolved":true,"method":"hybrid-fallback","resolution":["X"]}');
    expect(h.method, 'hybrid-fallback');
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

  test('parse: valid JSON that is not an object maps to badResponse', () {
    expect(ResolveResult.parse(200, '[1,2,3]').error, ResolveError.badResponse);
  });

  test('parse: wrong-typed scalar field maps to badResponse', () {
    expect(ResolveResult.parse(200, '{"state":42,"resolved":false}').error,
        ResolveError.badResponse);
  });

  test('parse: non-string element in resolution maps to badResponse', () {
    expect(
        ResolveResult.parse(
            200, '{"state":"x","resolved":true,"resolution":["OK",42]}').error,
        ResolveError.badResponse);
  });

  test('buildResolveUri: calls only when no overrides', () {
    final u = ResolveClient.buildResolveUri(['Heads Lead Right', 'Veer Left'], const {});
    expect(u.path, '/patter/fasr/resolve-sight');
    expect(u.queryParameters['calls'], 'Heads Lead Right,Veer Left');
    expect(u.queryParameters.containsKey('lane'), isFalse);
    expect(u.queryParameters.containsKey('threshold'), isFalse);
  });

  test('buildResolveUri: overrides appended to the query', () {
    final u = ResolveClient.buildResolveUri(['Heads Square Thru 4'],
        const {'lane': '70', 'threshold': '55'});
    expect(u.queryParameters['calls'], 'Heads Square Thru 4');
    expect(u.queryParameters['lane'], '70');
    expect(u.queryParameters['threshold'], '55');
  });

  test('danceabilityOverrides: returns the five params (whole numbers un-suffixed)', () {
    final m = danceabilityOverrides(lane: 70, overlap: 25, dist: 5,
        threshold: 55, blockWidth: 1.5);
    expect(m, {'lane': '70', 'overlap': '25', 'dist': '5', 'threshold': '55', 'blockWidth': '1.5'});
  });
}

import 'dart:async';
import 'dart:io';
import 'dart:convert';

/// Categories for a resolve attempt that did not return a usable resolution.
enum ResolveError { none, unreachable, unauthorized, timeout, badResponse }

/// Parsed result of a call to SC's /patter/fasr/resolve-hybrid.
/// [parse] does no I/O, so it is unit-testable on its own.
class ResolveResult {
  final String state;
  final bool resolved;
  final List<String> resolution;
  final String note;
  final ResolveError error;

  const ResolveResult({
    this.state = '?',
    this.resolved = false,
    this.resolution = const [],
    this.note = '',
    this.error = ResolveError.none,
  });

  static ResolveResult parse(int statusCode, String body) {
    if (statusCode == 401) {
      return const ResolveResult(error: ResolveError.unauthorized);
    }
    if (statusCode != 200) {
      return const ResolveResult(error: ResolveError.badResponse);
    }
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic>) {
        return const ResolveResult(error: ResolveError.badResponse);
      }
      final state = decoded['state'] as String? ?? '?';
      if (decoded['resolved'] == true) {
        final raw = decoded['resolution'];
        final resolution = raw is List ? raw.cast<String>().toList() : <String>[];
        return ResolveResult(state: state, resolved: true, resolution: resolution);
      }
      return ResolveResult(
          state: state, resolved: false, note: decoded['note'] as String? ?? '');
    } catch (_) {
      return const ResolveResult(error: ResolveError.badResponse);
    }
  }
}

/// Client for SquareCraft's resolver debug API (localhost:7233, DEBUG builds only).
class ResolveClient {
  /// Bearer token, set at startup from the --sc-token launch arg (see main.dart).
  static String? scAuthToken;

  static const _host = 'localhost';
  static const _port = 7233;

  /// GET the call history to /resolve-hybrid and return the parsed result.
  /// Never throws: any connection, timeout, or transport failure maps to a ResolveResult error.
  /// Builds the /resolve-hybrid request URL: the comma-joined calls plus any per-call overrides
  /// (danceability weights/threshold). Pure — no I/O — so it is unit-testable.
  static Uri buildResolveUri(List<String> calls, Map<String, String> overrides) {
    final params = <String, String>{'calls': calls.join(',')};
    params.addAll(overrides);
    return Uri(scheme: 'http', host: _host, port: _port,
        path: '/patter/fasr/resolve-hybrid', queryParameters: params);
  }

  static Future<ResolveResult> resolve(List<String> calls,
      {Map<String, String> overrides = const {}}) async {
    if (calls.isEmpty) {
      return const ResolveResult(note: 'no calls to resolve');
    }
    final uri = buildResolveUri(calls, overrides);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final req = await client.getUrl(uri);
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${scAuthToken ?? ''}');
      final resp = await req.close().timeout(const Duration(seconds: 30));
      final respBody = await resp.transform(utf8.decoder).join();
      return ResolveResult.parse(resp.statusCode, respBody);
    } on TimeoutException {
      return const ResolveResult(error: ResolveError.timeout);
    } on SocketException {
      return const ResolveResult(error: ResolveError.unreachable);
    } catch (_) {
      return const ResolveResult(error: ResolveError.badResponse);
    } finally {
      client.close(force: true);
    }
  }
}

/// Builds the per-call danceability override query params from TH's settings values, or an empty
/// map when the override toggle is off (→ SquareCraft uses its own stored settings). Pure: the
/// values are passed in (the caller reads Settings), so it is unit-testable. Whole numbers are
/// emitted without a trailing ".0" for clean URLs; SC parses either form.
Map<String, String> danceabilityOverrides({
  required bool enabled,
  required double lane,
  required double overlap,
  required double dist,
  required double threshold,
  required double blockWidth,
}) {
  if (!enabled) return const {};
  String n(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  return {
    'lane': n(lane),
    'overlap': n(overlap),
    'dist': n(dist),
    'threshold': n(threshold),
    'blockWidth': n(blockWidth),
  };
}

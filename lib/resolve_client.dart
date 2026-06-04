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

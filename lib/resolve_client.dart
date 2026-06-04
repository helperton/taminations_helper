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
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return const ResolveResult(error: ResolveError.badResponse);
    }
    final state = (map['state'] as String?) ?? '?';
    if (map['resolved'] == true) {
      final raw = map['resolution'];
      return ResolveResult(
          state: state,
          resolved: true,
          resolution: raw is List ? raw.cast<String>() : const []);
    }
    return ResolveResult(state: state, resolved: false, note: (map['note'] as String?) ?? '');
  }
}

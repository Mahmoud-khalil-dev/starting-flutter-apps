/// Build-time configuration from `--dart-define-from-file=env/<name>.json`.
/// The keys are in env/dev.example.json. There are no defaults: a build that
/// misses a key fails at start instead of reaching a host nobody chose.
class Env {
  const Env._();

  /// API root.
  static const baseUrl = String.fromEnvironment('BASE_URL');

  /// The build flavor, such as `dev` or `prod`.
  static const flavor = String.fromEnvironment('FLAVOR');

  /// Validates the values compiled into this build.
  static void validateCurrent({required bool isRelease}) =>
      validate(baseUrl: baseUrl, flavor: flavor, isRelease: isRelease);

  /// Throws [StateError] when this configuration must not run.
  static void validate({
    required String baseUrl,
    required String flavor,
    required bool isRelease,
  }) {
    const hint = 'Run with --dart-define-from-file=env/dev.json.';
    final missing = [
      if (baseUrl.isEmpty) 'BASE_URL',
      if (flavor.isEmpty) 'FLAVOR',
    ];
    if (missing.isNotEmpty) {
      throw StateError('${missing.join(', ')} empty. $hint');
    }
    if (!isRelease) return;
    final uri = Uri.parse(baseUrl);
    if (uri.scheme != 'https') {
      throw StateError('A release build must use https: $baseUrl');
    }
    if (uri.host.startsWith('dev-') || uri.host.startsWith('dev.')) {
      throw StateError('A release build must not use a dev host: $baseUrl');
    }
  }
}

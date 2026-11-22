import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';

enum LogLevel { debug, info, warn, error }

/// What [AppLog.error] hands the crash reporter: the message, redacted, and
/// the type of the original error. Never the original's own text, which may
/// carry a server's reply or a user's input.
class LoggedError implements Exception {
  const LoggedError(this.message, this.type);

  final String message;
  final String type;

  @override
  String toString() => 'LoggedError($type): $message';
}

/// The app's one logger. A release build prints nothing at any level; an
/// error goes to [reporter] by type only. In other builds every line is
/// redacted first: bearer and other credentials after `Authorization`,
/// cookies, JWTs, values named like a password, token, key, secret, session
/// or code (quoted values to their end), key-shaped and long opaque strings,
/// email addresses and phone numbers (seven or more digits, Western or
/// Arabic-Indic). Dates, UUIDs and ordinary prose stay readable.
abstract final class AppLog {
  /// Where lines go. Tests swap it.
  static void Function(String line) sink = _defaultSink;

  /// Debug lines print only when this is true (debug builds by default).
  static bool verbose = kDebugMode;

  /// True in a release build: nothing is printed. Tests set it.
  static bool release = kReleaseMode;

  /// Where an [error] is reported. Register the project's crash reporter.
  static CrashReporter reporter = const NoopCrashReporter();

  static void _defaultSink(String line) => debugPrint(line);

  /// Western, Arabic-Indic and Persian digits, for use inside a class.
  static const _digits = '0-9٠-٩۰-۹';

  static const _redacted = '[redacted]';

  /// Whole words that make a name sensitive.
  static const _sensitive = {
    'password',
    'passwd',
    'pwd',
    'passcode',
    'token',
    'secret',
    'credential',
    'credentials',
    'session',
    'sid',
    'cookie',
    'key',
    'apikey',
    'otp',
    'auth',
    'authorization',
  };

  /// Words that are sensitive as a name but plain prose after these.
  static const _weak = {'code', 'pin'};
  static final _proseCode = RegExp(
    r'\b(?:status|http|error|exit|return|response|result|country|zip|postal|'
    r'post|area|dial)\s+$',
    caseSensitive: false,
  );

  static final _camel = RegExp('([a-z0-9])([A-Z])');
  static final _uuid = RegExp(
    '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-'
    r'[0-9a-fA-F]{12}$',
  );
  static final _isoDate = RegExp(r'^\d{4}-\d{2}-\d{2}');
  static final _digit = RegExp('[$_digits]');

  static final _named = RegExp(
    r'''([\w-]+)(["']?\s*[:=]\s*)'''
    r'''("(?:[^"\\]|\\.)*"|'(?:[^'\\]|\\.)*'|[^\s",{}&;'\[\]]+)''',
  );

  /// A query parameter inside a URL: `?token=…` or `&email=…`.
  static final _query = RegExp(r'([?&])([\w-]+)=([^&\s#"]*)');

  /// An `@` written as `%40`, as a query string carries an email address.
  static final _encodedAt = RegExp('%40', caseSensitive: false);
  static String _decoded(String value) => value.replaceAll(_encodedAt, '@');

  static bool _sensitiveName(String name, String before) {
    final words = name
        .replaceAllMapped(_camel, (m) => '${m[1]} ${m[2]}')
        .toLowerCase()
        .split(RegExp(r'[\s_-]+'));
    if (words.any(_sensitive.contains)) return true;
    if (words.length == 1 && _weak.contains(words.single)) {
      return !_proseCode.hasMatch(before);
    }
    return words.any(_weak.contains);
  }

  static final _rules = <(RegExp, String Function(Match))>[
    (RegExp(r'Bearer\s+\S+', caseSensitive: false), (_) => 'Bearer $_redacted'),
    (RegExp(r'eyJ[\w-]+\.[\w-]+\.[\w-]+'), (_) => _redacted),
    (
      RegExp(r'\b(set-)?cookie\b(\s*:\s*)[^\r\n]*', caseSensitive: false),
      (m) => '${m[0]!.split(RegExp(r'\s*:')).first}: $_redacted',
    ),
    (
      RegExp(
        r'''\bauthorization\b(["']?\s*[:=]\s*)["']?'''
        r'(?:(?:basic|bearer|digest|negotiate|token)\s+)?'
        r'''[^\s",}&;']+''',
        caseSensitive: false,
      ),
      (m) => 'authorization${m[1]}$_redacted',
    ),
    (RegExp(r'\b(?:sk|pk|rk)_(?:live|test)_\w{8,}'), (_) => _redacted),
    (RegExp(r'\bAIza[\w-]{30,}'), (_) => _redacted),
  ];

  static final _opaque = RegExp(
    r'\b(?=[A-Za-z0-9_-]*[A-Za-z])(?=[A-Za-z0-9_-]*\d)[A-Za-z0-9_-]{32,}\b',
  );
  static final _email = RegExp(r'[^\s@"]+@[^\s@"]+\.[^\s@"]+');
  static final _phone = RegExp(
    '(?<!\\w|[A-Za-z0-9]-)\\+?[$_digits][$_digits\\s-]{5,}[$_digits]',
  );

  /// Masks the value of every sensitive `name=value` or `name: value`. A
  /// value whose own name is plain is read again from its start, so the pair
  /// in `error: token=abc` is found inside the value of `error`.
  static String _maskNamed(String text) {
    final out = StringBuffer();
    var at = 0;
    for (;;) {
      final m = _named.allMatches(text, at).firstOrNull;
      if (m == null) break;
      final valueAt = m.start + m[1]!.length + m[2]!.length;
      out.write(text.substring(at, valueAt));
      if (_sensitiveName(m[1]!, text.substring(0, m.start))) {
        out.write(_redacted);
        at = m.end;
      } else {
        at = valueAt;
      }
    }
    return (out..write(text.substring(at))).toString();
  }

  static String redact(String text) {
    var out = text;
    for (final (pattern, replace) in _rules) {
      out = out.replaceAllMapped(pattern, replace);
    }
    // Before the named values: a URL is one value to them, so a parameter
    // inside its query would pass unread.
    out = out.replaceAllMapped(
      _query,
      (m) => _sensitiveName(m[2]!, '') || _email.hasMatch(_decoded(m[3]!))
          ? '${m[1]}${m[2]}=$_redacted'
          : m[0]!,
    );
    out = _maskNamed(out);
    out = out
        .replaceAllMapped(
          _opaque,
          (m) => _uuid.hasMatch(m[0]!) ? m[0]! : _redacted,
        )
        .replaceAll(_email, _redacted)
        .replaceAllMapped(_phone, (m) {
          final run = m[0]!;
          if (_isoDate.hasMatch(run)) return run;
          return _digit.allMatches(run).length >= 7 ? _redacted : run;
        });
    return out;
  }

  static void _write(LogLevel level, String message) {
    if (release) return;
    if (level == LogLevel.debug && !verbose) return;
    sink('[${level.name}] ${redact(message)}');
  }

  static void debug(String message) => _write(LogLevel.debug, message);

  static void info(String message) => _write(LogLevel.info, message);

  static void warn(String message) => _write(LogLevel.warn, message);

  /// Logs the message and the error's type, and reports both to [reporter].
  /// The error's own text is never used.
  static void error(String message, Object error) {
    _write(LogLevel.error, '$message: ${error.runtimeType}');
    final reported = LoggedError(redact(message), '${error.runtimeType}');
    try {
      unawaited(reporter.recordError(reported, null).catchError((_) {}));
    } on Object {
      // A broken reporter must not break the caller.
    }
  }

  /// Back to the defaults; tests call it in tearDown.
  @visibleForTesting
  static void reset() {
    sink = _defaultSink;
    verbose = kDebugMode;
    release = kReleaseMode;
    reporter = const NoopCrashReporter();
  }
}

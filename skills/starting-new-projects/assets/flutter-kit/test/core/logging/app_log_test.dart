import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/crash/crash_reporter.dart';
import 'package:kit_app/core/logging/app_log.dart';

void main() {
  final lines = <String>[];

  setUp(() {
    lines.clear();
    AppLog.sink = lines.add;
    AppLog.verbose = true;
  });
  tearDown(AppLog.reset);

  test('KIT-T15: a bearer token never reaches the log', () {
    AppLog.info('Authorization: Bearer abc.def-123');
    expect(lines.single, isNot(contains('abc.def-123')));
    expect(lines.single, contains('[redacted]'));
  });

  test('KIT-T15: tokens, passwords, codes and emails are redacted', () {
    const jwt = 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJl';
    AppLog.info(
      'jwt $jwt password=hunter2 "otp": "123456" mail sara@example.com '
      'phone 0501234567',
    );
    final line = lines.single;
    for (final secret in [
      jwt,
      'hunter2',
      '123456',
      'sara@example.com',
      '0501234567',
    ]) {
      expect(line, isNot(contains(secret)), reason: secret);
    }
  });

  test('KIT-T15: each secret shape is redacted on its own', () {
    final cases = <String, String>{
      'jwt': 'eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.c2lnbmF0dXJl',
      'password': 'password=hunter2',
      'json password': '{"password":"hunter2"}',
      'token': 'token: abc123xyz',
      'api key': 'api_key=zzTopSecret99',
      'apiKey json': '{"apiKey": "zzTopSecret99"}',
      'secret': 'client_secret=zzTopSecret99',
      'otp': 'otp=482913',
      'email': 'write to sara.k+x@mail.example.com now',
      'phone': 'call +966 50 123 4567 now',
      'prefixed key':
          'sk_'
          'test_ab12cd34',
      'long key':
          'sk_'
          'live_4eC39HqLyjWDarjtT1zdp7dc',
      'google key':
          'AIza'
          'SyA1234567890abcdefghijklmnopqrstuv',
      'long opaque':
          'a1b2c3d4e5f60718293a'
          '4b5c6d7e8f90a1b2c3d4e5',
      'arabic digits': 'رقم ٠٥٠١٢٣٤٥٦٧',
    };
    for (final entry in cases.entries) {
      final out = AppLog.redact(entry.value);
      expect(out, contains('[redacted]'), reason: entry.key);
    }
    expect(AppLog.redact('password=hunter2'), isNot(contains('hunter2')));
    expect(
      AppLog.redact('{"apiKey": "zzTopSecret99"}'),
      isNot(contains('zzTop')),
    );
    expect(AppLog.redact('call +966 50 123 4567 now'), isNot(contains('4567')));
    expect(AppLog.redact('رقم ٠٥٠١٢٣٤٥٦٧'), isNot(contains('٠٥٠١٢٣٤٥٦٧')));
    expect(AppLog.redact('sara@example.com'), isNot(contains('sara')));
  });

  test('KIT-T15: ordinary text and short numbers pass untouched', () {
    expect(
      AppLog.redact('opened order 42 in 3 steps'),
      'opened order 42 in 3 steps',
    );
    expect(AppLog.redact('screen: home'), 'screen: home');
  });

  /// The secret must be gone, not just a marker added.
  void gone(String input, List<String> secrets, {String? reason}) {
    final out = AppLog.redact(input);
    for (final secret in secrets) {
      expect(out, isNot(contains(secret)), reason: '${reason ?? input}: $out');
    }
  }

  test('KIT-T15: a quoted value with spaces is redacted to its end', () {
    gone('{"password":"my secret pass"}', ['my', 'secret pass']);
    gone('client_secret="x y z"', ['x y', 'y z']);
    gone("password: 'two words'", ['two', 'words']);
    gone(r'{"token":"a \"quoted\" b c"}', ['quoted', ' b c']);
  });

  test('KIT-T15: any Authorization scheme loses its credential', () {
    gone('Authorization: Basic dXNlcjpwYXNz', ['dXNlcjpwYXNz']);
    gone('authorization: Digest realm=x', ['realm=x']);
    gone('Authorization: Bearer abcDEF123', ['abcDEF123']);
    gone('{"Authorization": "Token zzz999"}', ['zzz999']);
  });

  test('KIT-T15: cookies, sessions, keys and credentials are redacted', () {
    gone('Cookie: session=abc123; sid=zz9', ['abc123', 'zz9']);
    gone('Set-Cookie: id=qq77; Path=/; HttpOnly', ['qq77']);
    gone('Cookie: theme=dark; lang=en; uid=u8891', ['dark', 'u8891']);
    gone('sid=zz9', ['zz9']);
    gone('sessionId: s-4455', ['s-4455']);
    gone('key=abcd1234', ['abcd1234']);
    gone('credential=abc', ['abc']);
    gone('refreshToken=rt-99', ['rt-99']);
  });

  test('KIT-T15: names match on word boundaries, so prose stays readable', () {
    for (final text in [
      'status code: 404',
      'decode: failed',
      'http error code 500',
      'inside: yes',
      'keyboard=open',
    ]) {
      expect(AppLog.redact(text), text);
    }
    gone('code=482913', ['482913']);
    gone('{"code": "482913"}', ['482913']);
    gone('verification_code: 482913', ['482913']);
  });

  test('KIT-T15: a secret pair inside a sentence is redacted', () {
    gone('error: token=abc', ['abc']);
    gone('Bad state: secret=1', ['=1']);
    gone('reason: password=hunter2x', ['hunter2x']);
    gone('Sign-in failed: TOKEN: abc', ['abc']);
    gone('failed (Password: hunter2x)', ['hunter2x']);
    gone('lookup: api_key=zz9', ['zz9']);
    expect(AppLog.redact('error: token=abc'), 'error: token=[redacted]');
  });

  test('KIT-T15: opaque strings need a letter and a digit; ids stay', () {
    const mixed = 'a1b2c3d4e5f60718293a4b5c6d7e8f90';
    gone('id $mixed', [mixed]);
    const word = 'internationalizationandlocalizationwork';
    expect(AppLog.redact(word), word);
    const uuid = '123e4567-e89b-42d3-a456-426614174000';
    expect(AppLog.redact('request $uuid'), 'request $uuid');
  });

  test('KIT-T15: a key shape is caught by its own rule', () {
    // No digit, so only the key-shaped rule can match.
    const google =
        'AIza'
        'SyABCDEFGHIJKLMNOPQRSTUVWXYZabcdefg';
    gone('k $google', [google]);
    const stripe =
        'sk_'
        'live_ABCDEFGHIJKLMNOP';
    gone('k $stripe', [stripe]);
  });

  test('KIT-T15: phones need seven digits and dates stay readable', () {
    expect(AppLog.redact('on 2026-11-21 at 09:05'), 'on 2026-11-21 at 09:05');
    expect(AppLog.redact('at 2026-11-21 09:05:10'), 'at 2026-11-21 09:05:10');
    expect(AppLog.redact('page 123456 of 9'), 'page 123456 of 9');
    expect(AppLog.redact('ref 12 34 56'), 'ref 12 34 56');
    gone('call 1234567', ['1234567']);
    gone('call ١٢٣٤٥٦٧', ['١٢٣٤٥٦٧']);
    gone('call +966 50 123 4567', ['4567', '966']);
  });

  test('KIT-T15: nothing is printed in a release build, at any level', () {
    AppLog.release = true;
    AppLog.debug('a');
    AppLog.info('b');
    AppLog.warn('c');
    AppLog.error('d', StateError('x'));
    expect(lines, isEmpty);
  });

  test('KIT-T15: an error reaches the crash reporter as a type only', () {
    final reporter = _RecordingReporter();
    AppLog.reporter = reporter;
    AppLog.release = true;
    AppLog.error('sign in sara@example.com', StateError('token abc'));
    expect(reporter.errors, hasLength(1));
    final text = reporter.errors.single.toString();
    expect(text, contains('StateError'));
    expect(text, contains('sign in'));
    expect(text, isNot(contains('token abc')));
    expect(text, isNot(contains('sara@example.com')));
    expect(reporter.fatal, [false]);
  });

  test('KIT-T15: an error logs its type, never its message', () {
    AppLog.error('sign in', StateError('token abc'));
    expect(lines.single, contains('StateError'));
    expect(lines.single, isNot(contains('token abc')));
  });

  test('KIT-T15: debug lines need verbose', () {
    AppLog.verbose = false;
    AppLog.debug('quiet');
    AppLog.warn('loud');
    expect(lines, hasLength(1));
    expect(lines.single, contains('loud'));
  });

  test('KIT-T15: reset restores the default sink and verbosity', () {
    AppLog.reset();
    expect(AppLog.verbose, isTrue); // kDebugMode in tests
    lines.clear();
    AppLog.info('goes to debugPrint, not the old sink');
    expect(lines, isEmpty);
  });
}

class _RecordingReporter implements CrashReporter {
  final errors = <Object>[];
  final fatal = <bool>[];

  @override
  Future<void> recordError(
    Object error,
    StackTrace? stack, {
    bool fatal = false,
  }) async {
    errors.add(error);
    this.fatal.add(fatal);
  }

  @override
  Future<void> recordFlutterError(FlutterErrorDetails details) async {}
}

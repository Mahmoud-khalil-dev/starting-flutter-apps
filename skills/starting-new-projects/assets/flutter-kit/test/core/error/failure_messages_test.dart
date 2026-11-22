import 'package:flutter_test/flutter_test.dart';
import 'package:kit_app/core/error/failure_messages.dart';
import 'package:kit_app/core/error/failures.dart';

import '../../helpers/l10n.dart';

const _shown = <Failure>[
  NoConnection(),
  TimeoutFailure(outcomeKnown: true),
  TimeoutFailure(outcomeKnown: false),
  ServerFailure(500),
  Unauthorized(),
  Forbidden(),
  NotFound(),
  Conflict(),
  ValidationFailure([]),
  UnknownFailure(),
];

void main() {
  for (final language in ['en', 'ar']) {
    test('KIT-T9: every failure has $language text except Cancelled', () {
      final l10n = l10nFor(language);
      for (final failure in _shown) {
        final text = failureMessage(l10n, failure);
        expect(text, isNotEmpty, reason: '$failure');
        expect(text, isNot(contains('!')), reason: 'quiet copy, $failure');
      }
      expect(failureMessage(l10n, const Cancelled()), isNull);
    });
  }

  test('KIT-T9: validation and conflict prefer the backend text', () {
    final l10n = l10nFor('en');
    expect(
      failureMessage(
        l10n,
        const ValidationFailure(['Name is required', 'Phone']),
      ),
      'Name is required\nPhone',
    );
    expect(
      failureMessage(l10n, const Conflict('Email in use')),
      'Email in use',
    );
    expect(failureMessage(l10n, const Conflict()), l10n.errorConflict);
  });

  test('KIT-T16: rate limit and expiry have quiet text in both languages', () {
    for (final language in ['en', 'ar']) {
      final l10n = l10nFor(language);
      for (final failure in const <Failure>[
        TooManyRequests(),
        TooManyRequests(retryAfter: Duration(seconds: 75)),
        CodeExpired(),
      ]) {
        final text = failureMessage(l10n, failure);
        expect(text, isNotEmpty, reason: '$language $failure');
        expect(text, isNot(contains('!')), reason: '$language $failure');
      }
    }
    expect(
      failureMessage(
        l10nFor('en'),
        const TooManyRequests(retryAfter: Duration(seconds: 75)),
      ),
      contains('01:15'),
    );
    expect(
      failureMessage(
        l10nFor('ar'),
        const TooManyRequests(retryAfter: Duration(seconds: 75)),
      ),
      contains('٠١:١٥'),
    );
    expect(
      failureMessage(l10nFor('en'), const TooManyRequests()),
      isNot(contains(':')),
    );
  });

  test('KIT-T9: an unknown outcome asks the user to check, and promises no '
      'check the app does not make', () {
    expect(
      l10nFor('en').errorOutcomeUnknown,
      'We could not confirm whether your request went through. '
      'Please check before you try again.',
    );
    expect(
      l10nFor('ar').errorOutcomeUnknown,
      'لم نتمكن من التأكد من إتمام طلبك. يرجى التحقق قبل المحاولة مرة أخرى.',
    );
  });
}
